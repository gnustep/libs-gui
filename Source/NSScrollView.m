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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <Foundation/NSException.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSClipView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSTableHeaderView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

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
      NSDebugLog(@"Initialize NSScrollView class\n");
      [self setRulerViewClass: [NSRulerView class]];
      scrollerWidth = [NSScroller scrollerWidth];
      [self setVersion: 1];
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
  _borderType = NSBezelBorder;
  _scrollsDynamically = YES;
  [self tile];

  return self;
}

- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (void) dealloc
{
  TEST_RELEASE(_horizScroller);
  TEST_RELEASE(_vertScroller);
  TEST_RELEASE(_horizRuler);
  TEST_RELEASE(_vertRuler);

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
	[self setDocumentView: docView];
    }
  [_contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [self tile];
}

- (void) removeSubview: (NSView *)aView
{
  if (aView == _contentView)
    {
      _contentView = nil;
      [super removeSubview: aView];
      [self tile];
    }
  else
    {
      [super removeSubview: aView];
    }
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
  // FIXME
}

- (void) _doScroll: (NSScroller*)scroller
{
  float		floatValue = [scroller floatValue];
  NSRect	clipViewBounds = [_contentView bounds];
  NSScrollerPart hitPart = [scroller hitPart];
  NSRect	documentRect = [_contentView documentRect];
  float		amount = 0;
  NSPoint	point = clipViewBounds.origin;

  NSDebugLog (@"_doScroll: float value = %f", floatValue);

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
	  if (!_contentView->_rFlags.flipped_view)
	    {
	      /* If view is flipped reverse the scroll direction */
	      amount = -amount;
	    }
	  NSDebugLog (@"increment/decrement: amount = %f, flipped = %d",
			   amount, _contentView->_rFlags.flipped_view);
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
	  if (!_contentView->_rFlags.flipped_view)
	    floatValue = 1 - floatValue;
	  point.y = floatValue * (documentRect.size.height
		     			- clipViewBounds.size.height);
	  point.y += documentRect.origin.y;
	}
    }

  if (_hasHeaderView)
    {
      NSPoint scrollTo;

      scrollTo = [_headerClipView bounds].origin;
      scrollTo.x += point.x - clipViewBounds.origin.x;
      [_headerClipView scrollToPoint: scrollTo];
    }
  [_contentView scrollToPoint: point];

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

  NSDebugLog (@"reflectScrolledClipView:");

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

      // If needed, scroll the headerview too
      if (headerClipViewOrigin.x != clipViewBounds.origin.x)
	{
	  headerClipViewOrigin.x = clipViewBounds.origin.x;
	  headerClipViewOrigin = [_headerClipView constrainScrollPoint: 
						    headerClipViewOrigin];
	  [_headerClipView scrollToPoint: headerClipViewOrigin];
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
  NSView *cornerView = nil;

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
  
  /* First, allocate vertical space for the headerView / cornerView
     (but - NB - the headerView needs to be placed above the clipview
     later on, we can't place it now).  */
  if (_hasHeaderView == YES)
    {
      headerViewHeight = [[_headerClipView documentView] frame].size.height;
    }

  if (_hasCornerView == YES)
    {
      cornerView = [(NSTableView *)[_contentView documentView] cornerView];
      if (headerViewHeight == 0)
	{
	  headerViewHeight = [cornerView frame].size.height;
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
      [cornerView setFrameOrigin: headerRect.origin];
    }

  // FIXME: The Rulers should be positioned too
  [_contentView setFrame: contentRect];
}

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  float horizLinePosition, horizLineLength = _bounds.size.width;
  NSSize border = _sizeForBorderType(_borderType);
  float headerViewHeight = 0;

  if (_hasHeaderView == YES)
    {
      headerViewHeight = [[_headerClipView documentView] frame].size.height;
    }
  if ((_hasCornerView == YES) && (_hasHorizScroller == YES) 
      && (headerViewHeight == 0))
    {
      headerViewHeight = [[(NSTableView *)[_contentView documentView] 
					  cornerView] frame].size.height;
    }
  
  DPSgsave(ctxt);
  switch (_borderType)
    {
      case NSNoBorder:
	break;

      case NSLineBorder:
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(_bounds);
	break;

      case NSBezelBorder:
	NSDrawGrayBezel(_bounds, rect);
	break;

      case NSGrooveBorder:
	NSDrawGroove(_bounds, rect);
	break;
    }

  horizLinePosition = border.width;

  DPSsetlinewidth(ctxt, 1);
  DPSsetgray(ctxt, 0);
  if (_hasVertScroller)
    {
      horizLinePosition = scrollerWidth + border.width;
      horizLineLength -= scrollerWidth + 2 * border.width;
      DPSmoveto(ctxt, horizLinePosition, border.height);
      if (_rFlags.flipped_view)
	{
	  DPSrmoveto(ctxt, 0, headerViewHeight);
	}
      DPSrlineto(ctxt, 0, _bounds.size.height - headerViewHeight 
		 - 2 * border.height - 1);
      DPSstroke(ctxt);
      if ((_hasHeaderView == YES) && (_hasCornerView == NO)) 
	{
	  float yStart = border.height + headerViewHeight - 1;

	  if (_rFlags.flipped_view == NO)
	    yStart = _bounds.size.height - yStart;
	  DPSmoveto(ctxt, horizLinePosition, yStart); 
	  DPSlineto(ctxt, border.width, yStart);
	  DPSstroke(ctxt);
	}
    }

  if (_hasHorizScroller)
    {
      float ypos = scrollerWidth + border.height + 1;

      if (_rFlags.flipped_view)
	ypos = _bounds.size.height - ypos;
      DPSmoveto(ctxt, horizLinePosition, ypos);
      DPSrlineto(ctxt, horizLineLength - 1, 0);
      DPSstroke(ctxt);
    }

  DPSgrestore(ctxt);
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
}

- (void) setDocumentView: (NSView *)aView
{
  BOOL hadHeaderView = _hasHeaderView;

  if (_hasCornerView == YES)
    {
      [self removeSubview: 
	      [(NSTableView *)[_contentView documentView] cornerView]];
    }
  _hasCornerView = ([aView respondsToSelector: @selector(cornerView)]
		    && ([(NSTableView *)aView cornerView] != nil));
  if (_hasCornerView == YES)
    {
      [self addSubview: [(NSTableView *)aView cornerView]];
    }
  //
  _hasHeaderView = ([aView respondsToSelector: @selector(headerView)]
		    && ([(NSTableView *)aView headerView] != nil));
  if (_hasHeaderView == YES)
    {
      if (hadHeaderView == NO)
	{
	  _headerClipView = [NSClipView new];
	  [self addSubview: _headerClipView];
	  RELEASE (_headerClipView);
	}
      [_headerClipView setDocumentView: 
			 [(NSTableView *)aView headerView]];
    }
  else if (hadHeaderView == YES)
    {
      [self removeSubview: _headerClipView];
    }
  //
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

- (BOOL) hasHorizontalRuler
{
  return _hasHorizRuler;
}

- (BOOL) hasHorizontalScroller
{
  return _hasHorizScroller;
}

- (BOOL) hasVerticalRuler
{
  return _hasVertRuler;
}

- (BOOL) hasVerticalScroller
{
  return _hasVertScroller;
}

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

  NSDebugLLog(@"NSScrollView", @"NSScrollView: start encoding\n");
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

  /* We do not need to encode headerview, cornerview stuff */
  NSDebugLLog(@"NSScrollView", @"NSScrollView: finish encoding\n");
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

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
  
  /* This recreates all the info about headerView, cornerView, etc */
  [self setDocumentView: [_contentView documentView]];
  [self tile];

  NSDebugLLog(@"NSScrollView", @"NSScrollView: finish decoding\n");

  return self;
}

@end
