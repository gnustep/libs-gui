/** <title>NSScrollView</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: October 1998
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: February 1999
   Table View Support: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2000

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include "AppKit/NSScroller.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSCell.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSRulerView.h"
#include "AppKit/NSTableHeaderView.h"
#include "AppKit/NSTableView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSDrawFunctions.h"

//
// For nib compatibility, this is used to properly
// initialize the object from a OS X nib file in initWithCoder:.
//
typedef struct _scrollViewFlags 
{
#ifdef WORDS_BIGENDIAN
  unsigned int __unused4:26;
  unsigned int hasHScroller:1; // 16
  unsigned int hasVScroller:1; // 32
  unsigned int __unused0:2;
  NSBorderType border:2;
#else
  NSBorderType border:2;
  unsigned int __unused0:2;
  unsigned int hasVScroller:1; // 32
  unsigned int hasHScroller:1; // 16
  unsigned int __unused4:26;
#endif  
} GSScrollViewFlags;

@implementation NSScrollView

/*
 * Class variables
 */
static Class rulerViewClass = nil;
static float scrollerWidth;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSScrollView class])
    {
      [self setRulerViewClass: [NSRulerView class]];
      scrollerWidth = [NSScroller scrollerWidth];
      [self setVersion: 2];
    }
}

+ (void) setRulerViewClass: (Class)aClass
{
  rulerViewClass = aClass;
}

+ (Class) rulerViewClass
{
  return rulerViewClass;
}

+ (NSSize) contentSizeForFrameSize: (NSSize)frameSize
	     hasHorizontalScroller: (BOOL)hFlag
	       hasVerticalScroller: (BOOL)vFlag
			borderType: (NSBorderType)borderType
{
  NSSize size = frameSize;
  NSSize border = _sizeForBorderType(borderType);

  /*
   * Substract 1 from the width and height of
   * the line that separates the horizontal
   * and vertical scroller from the clip view
   */
  if (hFlag)
    {
      size.height -= scrollerWidth + 1;
    }
  if (vFlag)
    {
      size.width -= scrollerWidth + 1;
    }

  size.width -= 2 * border.width;
  size.height -= 2 * border.height;

  return size;
}

+ (NSSize) frameSizeForContentSize: (NSSize)contentSize
	     hasHorizontalScroller: (BOOL)hFlag
	       hasVerticalScroller: (BOOL)vFlag
			borderType: (NSBorderType)borderType
{
  NSSize size = contentSize;
  NSSize border = _sizeForBorderType(borderType);

  /*
   * Add 1 to the width and height for the line that separates the
   * horizontal and vertical scroller from the clip view.
   */
  if (hFlag)
    {
      size.height += scrollerWidth + 1;
    }
  if (vFlag)
    {
      size.width += scrollerWidth + 1;
    }

  size.width += 2 * border.width;
  size.height += 2 * border.height;

  return size;
}

/*
 * Instance methods
 */
- (id) initWithFrame: (NSRect)rect
{
  NSClipView *clipView = [NSClipView new];

  self = [super initWithFrame: rect];
  [self setContentView: clipView];
  RELEASE(clipView);
  _hLineScroll = 10;
  _hPageScroll = 10;
  _vLineScroll = 10;
  _vPageScroll = 10;
  _borderType = NSNoBorder;
  _scrollsDynamically = YES;
  // For compatibility the ruler should be present but not visible.
  [self setHasHorizontalRuler: YES];
  [self tile];

  return self;
}

- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (void) dealloc
{
  DESTROY(_horizScroller);
  DESTROY(_vertScroller);
  DESTROY(_horizRuler);
  DESTROY(_vertRuler);

  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

- (void) setContentView: (NSClipView *)aView
{
  if (aView == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"Attempt to set nil content view"];
  if ([aView isKindOfClass: [NSView class]] == NO)
    [NSException raise: NSInvalidArgumentException
		format: @"Attempt to set non-view object as content view"];

  if (aView != _contentView)
    {
      NSView *docView = [aView documentView];

      [_contentView removeFromSuperview];
      _contentView = aView;
      [self addSubview: _contentView];

      if (docView != nil)
	{
	  [self setDocumentView: docView];
	}
    }
  [_contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [self tile];
}

- (void) removeSubview: (NSView *)aView
{
  if (aView == _contentView)
    {
      _contentView = nil;
    }
  [super removeSubview: aView];
}

- (void) setHorizontalScroller: (NSScroller*)aScroller
{
  [_horizScroller removeFromSuperview];

  /*
   * Do not add the scroller view to the subviews array yet;
   * -setHasHorizontalScroller must be invoked first
   */
  ASSIGN(_horizScroller, aScroller);
  if (_horizScroller)
    {
      [_horizScroller setAutoresizingMask: NSViewWidthSizable];
      [_horizScroller setTarget: self];
      [_horizScroller setAction: @selector(_doScroll:)];
    }
}

- (void) setHasHorizontalScroller: (BOOL)flag
{
  if (_hasHorizScroller == flag)
    return;

  _hasHorizScroller = flag;

  if (_hasHorizScroller)
    {
      if (!_horizScroller)
        {
	  NSScroller *scroller = [NSScroller new];

	  [self setHorizontalScroller: scroller];
	  RELEASE(scroller);
	}
      [self addSubview: _horizScroller];
    }
  else
    [_horizScroller removeFromSuperview];

  [self tile];
}

- (void) setVerticalScroller: (NSScroller*)aScroller
{
  [_vertScroller removeFromSuperview];

  /*
   * Do not add the scroller view to the subviews array yet;
   * -setHasVerticalScroller must be invoked first
   */
  ASSIGN(_vertScroller, aScroller);
  if (_vertScroller)
    {
      [_vertScroller setAutoresizingMask: NSViewHeightSizable];
      [_vertScroller setTarget: self];
      [_vertScroller setAction: @selector(_doScroll:)];
    }
}

- (void) setHasVerticalScroller: (BOOL)flag
{
  if (_hasVertScroller == flag)
    return;

  _hasVertScroller = flag;

  if (_hasVertScroller)
    {
      if (!_vertScroller)
	{
	  NSScroller *scroller = [NSScroller new];

	  [self setVerticalScroller: scroller];
	  RELEASE(scroller);
	  if (_contentView && !_contentView->_rFlags.flipped_view)
	    [_vertScroller setFloatValue: 1];
	}
      [self addSubview: _vertScroller];
    }
  else
    [_vertScroller removeFromSuperview];

  [self tile];
}

- (void) scrollWheel: (NSEvent *)theEvent
{
  NSRect	clipViewBounds;
  float		delta = [theEvent deltaY];
  float 	amount;
  NSPoint	point;

  if (_contentView == nil)
    {
      clipViewBounds = NSZeroRect;
    }
  else
    {
      clipViewBounds = [_contentView bounds];
    }
  point = clipViewBounds.origin;


  if (_hasHorizScroller == YES
    && ([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask)
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  amount = - (clipViewBounds.size.width - _hPageScroll) * delta;
	}
      else
	{
	  amount = - _hLineScroll * delta;
	}
      NSDebugLLog (@"NSScrollView", 
	@"increment/decrement: amount = %f, horizontal", amount);

      point.x = clipViewBounds.origin.x + amount;
    }
  else
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  amount = - (clipViewBounds.size.height - _vPageScroll) * delta;
	}
      else
	{
	  amount = - _vLineScroll * delta;
	}

      if (_contentView != nil && !_contentView->_rFlags.flipped_view)
	{
	  /* If view is flipped reverse the scroll direction */
	  amount = -amount;
	}
      NSDebugLLog (@"NSScrollView", 
	@"increment/decrement: amount = %f, flipped = %d",
	amount, _contentView ? _contentView->_rFlags.flipped_view : 0);

      point.y = clipViewBounds.origin.y + amount;
    }

  /* scrollToPoint: will call reflectScrolledClipView:, which will
   * update rules, headers, and scrollers.  */
  [_contentView scrollToPoint: point];
}

/**
 * Scrolls the receiver by simply invoking scrollPageUp:
 */
- (void) pageUp: (id)sender
{
  [self scrollPageUp: sender];
}

/*
 * This code is based on _doScroll: and still may need some tuning. 
 */
- (void) scrollPageUp: (id)sender
{
  NSRect  clipViewBounds;
  NSPoint point;
  float   amount;

  if (_contentView == nil)
    {
      clipViewBounds = NSZeroRect;
    }
  else
    {
      clipViewBounds = [_contentView bounds];
    }
  point = clipViewBounds.origin;
  /*
   * Take verticalPageScroll into accout, but try to make sure
   * that amount is never negative (ie do not scroll backwards.)
   *
   * FIXME: It seems _doScroll and scrollWheel: should also take
   * care not to do negative scrolling.
   */
  amount = clipViewBounds.size.height - _vPageScroll;
  amount = (amount < 0) ? 0 : amount;

  if (_contentView != nil && !_contentView->_rFlags.flipped_view)
    {
      amount = -amount;
    }
  point.y = clipViewBounds.origin.y - amount;
  [_contentView scrollToPoint: point];
}

/**
 * Scrolls the receiver by simply invoking scrollPageUp:
 */
- (void) pageDown: (id)sender
{
  [self scrollPageDown: sender];
}

/*
 * This code is based on _doScroll:. and still may need some tuning.
 */
- (void) scrollPageDown: (id)sender
{
  NSRect  clipViewBounds;
  NSPoint point;
  float   amount;

  if (_contentView == nil)
    {
      clipViewBounds = NSZeroRect;
    }
  else
    {
      clipViewBounds = [_contentView bounds];
    }
  point = clipViewBounds.origin;
  /*
   * Take verticalPageScroll into accout, but try to make sure
   * that amount is never negativ (ie do not scroll backwards.)
   *
   * FIXME: It seems _doScroll and scrollWheel: should also take
   * care not to do negative scrolling.
   */
  amount = clipViewBounds.size.height - _vPageScroll;
  amount = (amount < 0) ? 0 : amount;
  if (_contentView != nil && !_contentView->_rFlags.flipped_view)
    {
      amount = -amount;
    }
  point.y = clipViewBounds.origin.y + amount;
  [_contentView scrollToPoint: point];
}

- (void) _doScroll: (NSScroller*)scroller
{
  float		floatValue = [scroller floatValue];
  NSScrollerPart hitPart = [scroller hitPart];
  NSRect	clipViewBounds;
  NSRect	documentRect;
  float		amount = 0;
  NSPoint	point;

  if (_contentView == nil)
    {
      clipViewBounds = NSZeroRect;
      documentRect = NSZeroRect;
    }
  else
    {
      clipViewBounds = [_contentView bounds];
      documentRect = [_contentView documentRect];
    }
  point = clipViewBounds.origin;

  NSDebugLLog (@"NSScrollView", @"_doScroll: float value = %f", floatValue);

  /* do nothing if scroller is unknown */
  if (scroller != _horizScroller && scroller != _vertScroller)
    return;

  _knobMoved = NO;

  if (hitPart == NSScrollerKnob || hitPart == NSScrollerKnobSlot)
    _knobMoved = YES;
  else
    {
      if (hitPart == NSScrollerIncrementLine)
	{
	  if (scroller == _horizScroller)
	    amount = _hLineScroll;
	  else
	    amount = _vLineScroll;
	}
      else if (hitPart == NSScrollerDecrementLine)
	{
	  if (scroller == _horizScroller)
	    amount = -_hLineScroll;
	  else
	    amount = -_vLineScroll;
	}
      else if (hitPart == NSScrollerIncrementPage)
	{
	  if (scroller == _horizScroller)
	    amount = clipViewBounds.size.width - _hPageScroll;
	  else
	    amount = clipViewBounds.size.height - _vPageScroll;
	}
      else if (hitPart == NSScrollerDecrementPage)
	{
	  if (scroller == _horizScroller)
	    amount = _hPageScroll - clipViewBounds.size.width;
	  else
	    amount = _vPageScroll - clipViewBounds.size.height;
	}
      else
	{
	  return;
	}
    }

  if (!_knobMoved)	/* button scrolling */
    {
      if (scroller == _horizScroller)
	{
	  point.x = clipViewBounds.origin.x + amount;
	}
      else
	{
	  if (_contentView != nil && !_contentView->_rFlags.flipped_view)
	    {
	      /* If view is flipped reverse the scroll direction */
	      amount = -amount;
	    }
	  NSDebugLLog (@"NSScrollView", 
		       @"increment/decrement: amount = %f, flipped = %d",
	    amount, _contentView ? _contentView->_rFlags.flipped_view : 0);
	  point.y = clipViewBounds.origin.y + amount;
	}
    }
  else 	/* knob scolling */
    {
      if (scroller == _horizScroller)
	{
	  point.x = floatValue * (documentRect.size.width
			      		- clipViewBounds.size.width);
	  point.x += documentRect.origin.x;
	}
      else
	{
	  if (_contentView != nil && !_contentView->_rFlags.flipped_view)
	    floatValue = 1 - floatValue;
	  point.y = floatValue * (documentRect.size.height
	    - clipViewBounds.size.height);
	  point.y += documentRect.origin.y;
	}
    }

  /* scrollToPoint will call reflectScrollerClipView, and that will
   * update scrollers, rulers and headers */
  [_contentView scrollToPoint: point];
}

//
// This method is here purely for nib compatibility.  This is the action
// connected to by NSScrollers in IB when building a scrollview.
//
- (void) _doScroller: (NSScroller *)scroller
{
  [self _doScroll: scroller];
}

- (void) reflectScrolledClipView: (NSClipView *)aClipView
{
  NSRect documentFrame = NSZeroRect;
  NSRect clipViewBounds = NSZeroRect;
  float floatValue;
  float knobProportion;
  id documentView;

  if (aClipView != _contentView)
    {
      return;
    }

  NSDebugLLog (@"NSScrollView", @"reflectScrolledClipView:");

  if (_contentView)
    {
      clipViewBounds = [_contentView bounds];
    }
  if ((documentView = [_contentView documentView]))
    {
      documentFrame = [documentView frame];
    }

  if (_hasVertScroller)
    {
      if (documentFrame.size.height <= clipViewBounds.size.height)
	{
	  [_vertScroller setEnabled: NO];
	}
      else
	{
	  [_vertScroller setEnabled: YES];

	  knobProportion = clipViewBounds.size.height
	    / documentFrame.size.height;

	  floatValue = (clipViewBounds.origin.y - documentFrame.origin.y)
	    / (documentFrame.size.height - clipViewBounds.size.height);

	  if (!_contentView->_rFlags.flipped_view)
	    {
	      floatValue = 1 - floatValue;
	    }
	  [_vertScroller setFloatValue: floatValue 
			 knobProportion: knobProportion];
	}
    }

  if (_hasHorizScroller)
    {
      if (documentFrame.size.width <= clipViewBounds.size.width)
	{
	  [_horizScroller setEnabled: NO];
	}
      else
	{
	  [_horizScroller setEnabled: YES];

	  knobProportion = clipViewBounds.size.width
	    / documentFrame.size.width;

	  floatValue = (clipViewBounds.origin.x - documentFrame.origin.x)
	    / (documentFrame.size.width - clipViewBounds.size.width);

	  [_horizScroller setFloatValue: floatValue
			 knobProportion: knobProportion];
	}
    }

  if (_hasHeaderView)
    {
      NSPoint headerClipViewOrigin;
      
      headerClipViewOrigin = [_headerClipView bounds].origin;

      /* If needed, scroll the headerview too.  */
      if (headerClipViewOrigin.x != clipViewBounds.origin.x)
	{
	  headerClipViewOrigin.x = clipViewBounds.origin.x;
	  [_headerClipView scrollToPoint: headerClipViewOrigin];
	}
    }

  if (_rulersVisible == YES)
    {
      if (_hasHorizRuler)
	{
	  [_horizRuler setNeedsDisplay: YES];
	}
      if (_hasVertRuler)
	{
	  [_vertRuler setNeedsDisplay: YES];
       }
    }
}

- (void) setHorizontalRulerView: (NSRulerView *)aRulerView
{
  if (_rulersVisible && _horizRuler != nil)
    {
      [_horizRuler removeFromSuperview];
    }
  
  ASSIGN(_horizRuler, aRulerView);
  
  if (_horizRuler == nil)
    {
      _hasHorizRuler = NO;
    }
  else if (_rulersVisible)
    {
      [self addSubview:_horizRuler];
    }

  if (_rulersVisible)
    {
      [self tile];
    }
}

- (void) setHasHorizontalRuler: (BOOL)flag
{
  if (_hasHorizRuler == flag)
    return;

  _hasHorizRuler = flag;
  if (_hasHorizRuler && _horizRuler == nil)
    {
      _horizRuler = [[isa rulerViewClass] alloc];
      _horizRuler = [_horizRuler initWithScrollView: self 
				 orientation: NSHorizontalRuler];
    }

  if (_rulersVisible)
    {
      if (_hasHorizRuler)
	{
	  [self addSubview: _horizRuler];
	}
      else
	{
	  [_horizRuler removeFromSuperview];
	}
      [self tile];
    }
}

- (void) setVerticalRulerView: (NSRulerView *)aRulerView
{
  if (_rulersVisible && _vertRuler != nil)
    {
      [_vertRuler removeFromSuperview];
    }
  
  ASSIGN(_vertRuler, aRulerView);
  
  if (_vertRuler == nil)
    {
      _hasVertRuler = NO;
    }
  else if (_rulersVisible)
    {
      [self addSubview:_vertRuler];
    }

  if (_rulersVisible)
    {
      [self tile];
    }
}

- (void) setHasVerticalRuler: (BOOL)flag
{
  if (_hasVertRuler == flag)
    return;

  _hasVertRuler = flag;
  if (_hasVertRuler && _vertRuler == nil)
    {
      _vertRuler = [[isa rulerViewClass] alloc];
      _vertRuler = [_vertRuler initWithScrollView: self 
			       orientation: NSVerticalRuler];
    }

  if (_rulersVisible)
    {
      if (_hasVertRuler)
	{
	  [self addSubview: _vertRuler];
	}
      else
	{
	  [_vertRuler removeFromSuperview];
	}
      [self tile];
    }
}

- (void) setRulersVisible: (BOOL)flag
{
  if (_rulersVisible == flag)
    return;

  _rulersVisible = flag;
  if (flag)
    {
      if (_hasVertRuler)
	[self addSubview: _vertRuler];
      if (_hasHorizRuler)
	[self addSubview: _horizRuler];
    }
  else 
    {
      if (_hasVertRuler)
	[_vertRuler removeFromSuperview];
      if (_hasHorizRuler)
	[_horizRuler removeFromSuperview];
    }
  [self tile];
}

- (void) setFrame: (NSRect)rect
{
  [super setFrame: rect];
  [self tile];
}

- (void) setFrameSize: (NSSize)size
{
  [super setFrameSize: size];
  [self tile];
}

- (void) tile
{
  NSRect headerRect, contentRect;
  NSSize border = _sizeForBorderType(_borderType);
  NSRectEdge bottomEdge, topEdge;
  float headerViewHeight = 0;

  /* Determine edge positions.  */
  if (_rFlags.flipped_view)
    {
      topEdge = NSMinYEdge;
      bottomEdge = NSMaxYEdge;
    }
  else
    {
      topEdge = NSMaxYEdge;
      bottomEdge = NSMinYEdge;
    }

  /* Prepare the contentRect by the insetting the borders.  */
  contentRect = NSInsetRect (_bounds, border.width, border.height);
  
  [self _synchronizeHeaderAndCornerView];
  
  /* First, allocate vertical space for the headerView / cornerView
     (but - NB - the headerView needs to be placed above the clipview
     later on, we can't place it now).  */

  if (_hasHeaderView == YES)
    {
      headerViewHeight = [[_headerClipView documentView] frame].size.height;
    }

  if (_hasCornerView == YES)
    {
      if (headerViewHeight == 0)
	{
	  headerViewHeight = [_cornerView frame].size.height;
	}
    }

  /* Remove the vertical slice used by the header/corner view.  Save
     the height and y position of headerRect for later reuse.  */
  NSDivideRect (contentRect, &headerRect, &contentRect, headerViewHeight, 
		topEdge);

  /* Ok - now go on with drawing the actual scrollview in the
     remaining space.  Just consider contentRect to be the area in
     which we draw, ignoring header/corner view.  */

  /* Prepare the vertical scroller.  */
  if (_hasVertScroller)
    {
      NSRect vertScrollerRect;

      NSDivideRect (contentRect, &vertScrollerRect, &contentRect, 
		    scrollerWidth, NSMinXEdge);

      [_vertScroller setFrame: vertScrollerRect];

      /* Substract 1 for the line that separates the vertical scroller
       * from the clip view (and eventually the horizontal scroller).  */
      NSDivideRect (contentRect, NULL, &contentRect, 1, NSMinXEdge);
    }

  /* Prepare the horizontal scroller.  */
  if (_hasHorizScroller)
    {
      NSRect horizScrollerRect;
      
      NSDivideRect (contentRect, &horizScrollerRect, &contentRect, 
		    scrollerWidth, bottomEdge);

      [_horizScroller setFrame: horizScrollerRect];

      /* Substract 1 for the width for the line that separates the
       * horizontal scroller from the clip view.  */
      NSDivideRect (contentRect, NULL, &contentRect, 1, bottomEdge);
    }

  /* Now place and size the header view to be exactly above the
     resulting clipview.  */
  if (_hasHeaderView)
    {
      NSRect rect = headerRect;

      rect.origin.x = contentRect.origin.x;
      rect.size.width = contentRect.size.width;

      [_headerClipView setFrame: rect];
    }

  /* Now place the corner view.  */
  if (_hasCornerView)
    {
      [_cornerView setFrameOrigin: headerRect.origin];
    }

  /* Now place the rulers.  */
  if (_rulersVisible)
    {
      if (_hasHorizRuler)
	{
	  NSRect horizRulerRect;
	  
	  NSDivideRect (contentRect, &horizRulerRect, &contentRect,
			[_horizRuler requiredThickness], topEdge);
	  [_horizRuler setFrame: horizRulerRect];
	}

      if (_hasVertRuler)
	{
	  NSRect vertRulerRect;
	  
	  NSDivideRect (contentRect, &vertRulerRect, &contentRect,
			[_vertRuler requiredThickness], NSMinXEdge);
	  [_vertRuler setFrame: vertRulerRect];
	}
    }

  [_contentView setFrame: contentRect];
  [self setNeedsDisplay: YES];
}

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  
  switch (_borderType)
    {
      case NSNoBorder:
	break;

      case NSLineBorder:
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(_bounds);
	break;

      case NSBezelBorder:
	[GSDrawFunctions drawGrayBezel: _bounds : rect];
	break;

      case NSGrooveBorder:
	[GSDrawFunctions drawGroove: _bounds : rect];
	break;
    }

  [[NSColor controlDarkShadowColor] set];
  DPSsetlinewidth(ctxt, 1);

  if (_hasVertScroller)
    {
      DPSmoveto(ctxt, [_vertScroller frame].origin.x + scrollerWidth, 
		[_vertScroller frame].origin.y - 1);
      DPSrlineto(ctxt, 0, [_vertScroller frame].size.height + 1);
      DPSstroke(ctxt);
    }

  if (_hasHorizScroller)
    {
      float ypos;
      float scrollerY = [_horizScroller frame].origin.y;

      if (_rFlags.flipped_view)
	{
	  ypos = scrollerY - 1;
	}
      else
	{
	  ypos = scrollerY + scrollerWidth + 1;
	}

      DPSmoveto(ctxt, [_horizScroller frame].origin.x - 1, ypos);
      DPSrlineto(ctxt, [_horizScroller frame].size.width + 1, 0);
      DPSstroke(ctxt);
    }
}

- (NSRect) documentVisibleRect
{
  return [_contentView documentVisibleRect];
}

- (void) setBackgroundColor: (NSColor*)aColor
{
  [_contentView setBackgroundColor: aColor];
}

- (NSColor*) backgroundColor
{
  return [_contentView backgroundColor];
}

- (void)setDrawsBackground:(BOOL)flag
{
  [_contentView setDrawsBackground: flag];
}

- (BOOL)drawsBackground
{
  return [_contentView drawsBackground];
}

- (void) setBorderType: (NSBorderType)borderType
{
  _borderType = borderType;
  [self tile];
}

- (void) setDocumentView: (NSView *)aView
{
  [_contentView setDocumentView: aView];

  if (_contentView && !_contentView->_rFlags.flipped_view)
    {
      [_vertScroller setFloatValue: 1];
    }
  [self tile];
}

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  [super resizeSubviewsWithOldSize: oldSize];
  [self tile];
}

- (id) documentView
{
  return [_contentView documentView];
}

- (NSCursor*) documentCursor
{
  return [_contentView documentCursor];
}

- (void) setDocumentCursor: (NSCursor*)aCursor
{
  [_contentView setDocumentCursor: aCursor];
}

- (BOOL) isOpaque
{
  return YES;
}

- (NSBorderType) borderType
{
  return _borderType;
}

/** <p>Returns whether the NSScrollView has a horizontal ruler</p>
    <p>See Also: -setHasHorizontalRuler:</p>
 */
- (BOOL) hasHorizontalRuler
{
  return _hasHorizRuler;
}

/** <p>Returns whether the NSScrollView has a horizontal scroller</p>
    <p>See Also: -setHasHorizontalScroller:</p>
 */
- (BOOL) hasHorizontalScroller
{
  return _hasHorizScroller;
}

/** <p>Returns whether the NSScrollView has a vertical ruler</p>
    <p>See Also: -setHasVerticalRuler:</p>
 */
- (BOOL) hasVerticalRuler
{
  return _hasVertRuler;
}

/** <p>Returns whether the NSScrollView has a vertical scroller</p>
    <p>See Also: -setHasVerticalScroller:</p>
 */
- (BOOL) hasVerticalScroller
{
  return _hasVertScroller;
}

/**<p>Returns the size of the NSScrollView's content view</p>
 */
- (NSSize) contentSize
{
  return [_contentView bounds].size;
}

- (NSClipView *) contentView
{
  return _contentView;
}

- (NSRulerView *) horizontalRulerView
{
  return _horizRuler;
}

- (NSRulerView *) verticalRulerView
{
  return _vertRuler;
}

- (BOOL) rulersVisible
{
  return _rulersVisible;
}

- (void) setLineScroll: (float)aFloat
{
  _hLineScroll = aFloat;
  _vLineScroll = aFloat;
}

- (void) setHorizontalLineScroll: (float)aFloat
{
  _hLineScroll = aFloat;
}

- (void) setVerticalLineScroll: (float)aFloat
{
  _vLineScroll = aFloat;
}

- (float) lineScroll
{
  if (_hLineScroll != _vLineScroll)
    [NSException raise: NSInternalInconsistencyException
		format: @"horizontal and vertical values not same"];
  return _vLineScroll;
}

- (float) horizontalLineScroll
{
  return _hLineScroll;
}

- (float) verticalLineScroll
{
  return _vLineScroll;
}

- (void) setPageScroll: (float)aFloat
{
  _hPageScroll = aFloat;
  _vPageScroll = aFloat;
}

- (void) setHorizontalPageScroll: (float)aFloat
{
  _hPageScroll = aFloat;
}

- (void) setVerticalPageScroll: (float)aFloat
{
  _vPageScroll = aFloat;
}

- (float) pageScroll
{
  if (_hPageScroll != _vPageScroll)
    [NSException raise: NSInternalInconsistencyException
		format: @"horizontal and vertical values not same"];
  return _vPageScroll;
}

- (float) horizontalPageScroll
{
  return _hPageScroll;
}

- (float) verticalPageScroll
{
  return _vPageScroll;
}

- (void) setScrollsDynamically: (BOOL)flag
{
  // FIX ME: This should change the behaviour of the scrollers
  _scrollsDynamically = flag;
}

- (BOOL) scrollsDynamically
{
  return _scrollsDynamically;
}

- (NSScroller*) horizontalScroller
{
  return _horizScroller;
}

- (NSScroller*) verticalScroller
{
  return _vertScroller;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
      
  if([aCoder allowsKeyedCoding])
    {
    }
  else
    {
      [aCoder encodeObject: _contentView];
      [aCoder encodeValueOfObjCType: @encode(NSBorderType) at: &_borderType];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_scrollsDynamically];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_rulersVisible];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_hLineScroll];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_hPageScroll];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_vLineScroll];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_vPageScroll];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasHorizScroller];
      if (_hasHorizScroller)
	[aCoder encodeObject: _horizScroller];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasVertScroller];
      if (_hasVertScroller)
	[aCoder encodeObject: _vertScroller];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasHorizRuler];
      if (_hasHorizRuler)
	[aCoder encodeObject: _horizRuler];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasVertRuler];
      if (_hasVertRuler)
	[aCoder encodeObject: _vertRuler];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasHeaderView];
      if (_hasHeaderView)
	[aCoder encodeObject: _headerClipView];
      
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasCornerView];
      
      /* We do not need to encode headerview, cornerview stuff */
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      NSScroller *hScroller = [aDecoder decodeObjectForKey: @"NSHScroller"];
      NSScroller *vScroller = [aDecoder decodeObjectForKey: @"NSVScroller"];
      NSClipView *content = [aDecoder decodeObjectForKey: @"NSContentView"]; 

      if ([aDecoder containsValueForKey: @"NSsFlags"])
        {
	  unsigned long flags = [aDecoder decodeIntForKey: @"NSsFlags"];
	  GSScrollViewFlags scrollViewFlags;
	  memcpy((void *)&scrollViewFlags,(void *)&flags,sizeof(struct _scrollViewFlags));

	  _hasVertScroller = scrollViewFlags.hasVScroller;
	  _hasHorizScroller = scrollViewFlags.hasHScroller;
	  // _scrollsDynamically = (!scrollViewFlags.notDynamic);
	  // _rulersVisible = scrollViewFlags.rulersVisible;
	  // _hasHorizRuler = scrollViewFlags.hasHRuler;
	  // _hasVertRuler = scrollViewFlags.hasVRuler;
	  // [self setDrawsBackground: (!scrollViewFlags.doesNotDrawBack)];
	  _borderType = scrollViewFlags.border;
	}

      if (content != nil)
        {
	  NSRect frame = [content frame];
	  float w = [vScroller frame].size.width;

	  if(_hasVertScroller)
	    {
	      //
	      // Slide the content view over, since on Mac OS X the scroller is on the
	      // right, the content view is not properly positioned since our scroller
	      // is on the left.
	      //
	      frame.origin.x += w;
	      [content setFrame: frame];
	    }

	  // retain the view and reset the content view...
	  RETAIN(content);
	  [self setContentView: content];
	  RELEASE(content);
	  _contentView = content;
	}
     
      if (hScroller != nil && _hasHorizScroller)
        {
	  [self setHorizontalScroller: hScroller];
	}

      if (vScroller != nil && _hasVertScroller)
        {
	  [self setVerticalScroller: vScroller];
	}

      if ([aDecoder containsValueForKey: @"NSHeaderClipView"])
	{
	  _hasHeaderView = YES;
	  _hasCornerView = YES;	  
	  ASSIGN(_headerClipView, [aDecoder decodeObjectForKey: @"NSHeaderClipView"]);
	}

      [self tile];
    }
  else
    {
      int version = [aDecoder versionForClassName: @"NSScrollView"];
      NSDebugLLog(@"NSScrollView", @"NSScrollView: start decoding\n");
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_contentView];
      [aDecoder decodeValueOfObjCType: @encode(NSBorderType) at: &_borderType];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_scrollsDynamically];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_rulersVisible];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_hLineScroll];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_hPageScroll];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_vLineScroll];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_vPageScroll];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasHorizScroller];
      if (_hasHorizScroller)
	[aDecoder decodeValueOfObjCType: @encode(id) at: &_horizScroller];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasVertScroller];
      if (_hasVertScroller)
	[aDecoder decodeValueOfObjCType: @encode(id) at: &_vertScroller];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasHorizRuler];
      if (_hasHorizRuler)
	[aDecoder decodeValueOfObjCType: @encode(id) at: &_horizRuler];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasVertRuler];
      if (_hasVertRuler)
	[aDecoder decodeValueOfObjCType: @encode(id) at: &_vertRuler];
      
      if (version == 2)
        {
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasHeaderView];
	  if (_hasHeaderView)
	    [aDecoder decodeValueOfObjCType: @encode(id) at: &_headerClipView];
      
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasCornerView];
	}
      else if (version == 1)
        {
	  /* This recreates all the info about headerView, cornerView, etc */
	  [self setDocumentView: [_contentView documentView]];
	}
      else
        {
	  NSLog(@"unknown NSScrollView version (%d)", version);
	  DESTROY(self);
	}
      [self tile];
      
      NSDebugLLog(@"NSScrollView", @"NSScrollView: finish decoding\n");
    }

  return self;
}

/* GNUstep private method */

/* we update both of these at the same time during -tile
   so there is no reason in seperating them that'd just add
   message passing */
- (void) _synchronizeHeaderAndCornerView
{
  BOOL hadHeaderView = _hasHeaderView;
  BOOL hadCornerView = _hasCornerView;
  NSView *aView = nil;
  _hasHeaderView = ([[self documentView] 
                        respondsToSelector: @selector(headerView)]
                    && (aView=[(NSTableView *)[self documentView] headerView]));
  if (_hasHeaderView == YES)
    {
      if (hadHeaderView == NO)
        {
          _headerClipView = [NSClipView new];
          [self addSubview: _headerClipView];
          RELEASE (_headerClipView);
        }
      [_headerClipView setDocumentView: aView]; 
    }
  else if (hadHeaderView == YES)
    {
      [self removeSubview: _headerClipView];
    }
  if (_hasVertScroller == YES)
    {
      aView = nil; 
      _hasCornerView =
              ([[self documentView] respondsToSelector: @selector(cornerView)]
               && (aView=[(NSTableView *)[self documentView] cornerView]));
      
      if (aView == _cornerView)
        return;
      if (_hasCornerView == YES)
        {
          if (hadCornerView == NO)
            {
 	      [self addSubview:aView];
	    }
          else
            {
              [self replaceSubview: _cornerView with: aView];
	    }
        }
      else if (hadCornerView == YES)
        {
          [self removeSubview: _cornerView];
        }
      _cornerView = aView;
    }
  else if (_cornerView != nil)
    {
      [self removeSubview: _cornerView];
      _cornerView = nil;
      _hasCornerView = NO;
    }
}

@end
