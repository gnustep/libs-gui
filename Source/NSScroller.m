/** <title>NSScroller</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   A completely rewritten version of the original source by Scott Christley.
   Date: July 1997
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Mar 1999 - Use flipped views and make conform to spec

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

#include <math.h>

#include <Foundation/NSDate.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSDebug.h>

#include <AppKit/NSScroller.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>


@implementation NSScroller

/*
 * Class variables
 */

/* button cells used by scroller instances to draw scroller buttons and knob. */
static NSButtonCell* upCell = nil;
static NSButtonCell* downCell = nil;
static NSButtonCell* leftCell = nil;
static NSButtonCell* rightCell = nil;
static NSButtonCell* knobCell = nil;

static const float scrollerWidth = 18;
static const float buttonsWidth = 16;

static NSColor *scrollBarColor = nil;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSScroller class])
    {
      [self setVersion: 1];
      ASSIGN (scrollBarColor, [NSColor scrollBarColor]);
    }
}

+ (float) scrollerWidth
{
  return scrollerWidth;
}

- (BOOL) isFlipped
{
  return YES;
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (NSScrollArrowPosition) arrowsPosition
{
  return _arrowsPosition;
}

- (NSUsableScrollerParts) usableParts
{
  return _usableParts;
}

- (float) knobProportion
{
  return _knobProportion;
}

- (NSScrollerPart) hitPart
{
  return _hitPart;
}

- (float) floatValue
{
  return _floatValue;
}

- (void) setAction: (SEL)action
{
  _action = action;
}

- (SEL) action
{
  return _action;
}

- (void) setTarget: (id)target
{
  _target = target;
}

- (id) target
{
  return _target;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_arrowsPosition];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isEnabled];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
  /* We do not save float value, knob proportion. */
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if (_frame.size.width > _frame.size.height)
    {
      _isHorizontal = YES;
    }
  else
    {
      _isHorizontal = NO;
    }

  if (_isHorizontal)
    {
      _floatValue = 0.0;
    }
  else
    {
      _floatValue = 1.0;
    }

  _hitPart = NSScrollerNoPart;

  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &_arrowsPosition];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isEnabled];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_target];
  // Undo RETAIN by decoder
  TEST_RELEASE(_target);
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];

  [self drawParts];
  [self checkSpaceForParts];

  return self;
}

- (BOOL) isOpaque
{
  return YES;
}

- (id) initWithFrame: (NSRect)frameRect
{
  /*
   * determine the orientation of the scroller and adjust it's size accordingly
   */
  if (frameRect.size.width > frameRect.size.height)
    {
      _isHorizontal = YES;
      frameRect.size.height = [isa scrollerWidth];
    }
  else
    {
      _isHorizontal = NO;
      frameRect.size.width = [isa scrollerWidth];
    }

  [super initWithFrame: frameRect];

  if (_isHorizontal)
    {
      _arrowsPosition = NSScrollerArrowsMinEnd;
      _floatValue = 0.0;
    }
  else
    {
      _arrowsPosition = NSScrollerArrowsMaxEnd;
      _floatValue = 1.0;
    }

  _hitPart = NSScrollerNoPart;
  [self drawParts];
  [self setEnabled: NO];
  [self checkSpaceForParts];

  return self;
}

- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (void) drawParts
{
  /*
   * Create the class variable button cells if they do not yet exist.
   */
  if (knobCell)
    return;

  upCell = [NSButtonCell new];
  [upCell setHighlightsBy: NSChangeBackgroundCellMask|NSContentsCellMask];
  [upCell setImage: [NSImage imageNamed: @"common_ArrowUp"]];
  [upCell setAlternateImage: [NSImage imageNamed: @"common_ArrowUpH"]];
  [upCell setImagePosition: NSImageOnly];
  [upCell setContinuous: YES];
  [upCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [upCell setPeriodicDelay: 0.3 interval: 0.03];

  downCell = [NSButtonCell new];
  [downCell setHighlightsBy: NSChangeBackgroundCellMask|NSContentsCellMask];
  [downCell setImage: [NSImage imageNamed: @"common_ArrowDown"]];
  [downCell setAlternateImage: [NSImage imageNamed: @"common_ArrowDownH"]];
  [downCell setImagePosition: NSImageOnly];
  [downCell setContinuous: YES];
  [downCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [downCell setPeriodicDelay: 0.3 interval: 0.03];

  leftCell = [NSButtonCell new];
  [leftCell setHighlightsBy: NSChangeBackgroundCellMask|NSContentsCellMask];
  [leftCell setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
  [leftCell setAlternateImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
  [leftCell setImagePosition: NSImageOnly];
  [leftCell setContinuous: YES];
  [leftCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [leftCell setPeriodicDelay: 0.3 interval: 0.03];

  rightCell = [NSButtonCell new];
  [rightCell setHighlightsBy: NSChangeBackgroundCellMask|NSContentsCellMask];
  [rightCell setImage: [NSImage imageNamed: @"common_ArrowRight"]];
  [rightCell setAlternateImage: [NSImage imageNamed: @"common_ArrowRightH"]];
  [rightCell setImagePosition: NSImageOnly];
  [rightCell setContinuous: YES];
  [rightCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [rightCell setPeriodicDelay: 0.3 interval: 0.03];

  knobCell = [NSButtonCell new];
  [knobCell setButtonType: NSMomentaryChangeButton];
  [knobCell setImage: [NSImage imageNamed: @"common_Dimple"]];
  [knobCell setImagePosition: NSImageOnly];
}

- (void) _setTargetAndActionToCells
{
  [upCell setTarget: _target];
  [upCell setAction: _action];

  [downCell setTarget: _target];
  [downCell setAction: _action];

  [leftCell setTarget: _target];
  [leftCell setAction: _action];

  [rightCell setTarget: _target];
  [rightCell setAction: _action];

  [knobCell setTarget: _target];
  [knobCell setAction: _action];
}

- (void) checkSpaceForParts
{
  NSSize	frameSize = _frame.size;
  float		size = (_isHorizontal ? frameSize.width : frameSize.height);

  if (_arrowsPosition == NSScrollerArrowsNone)
    {
      if (size >= buttonsWidth + 3)
	{
	  _usableParts = NSAllScrollerParts;
	}
      else
	{
	  _usableParts = NSNoScrollerParts;
	}
    }
  else
    {
      if (size >= 4 /* spacing */ + 1 /* min. scroll area */ + buttonsWidth * 3)
	{
	  _usableParts = NSAllScrollerParts;
	}
      else if (size >= 3 /* spacing */ + buttonsWidth * 2)
	{
	  _usableParts = NSOnlyScrollerArrows;
	}
      else
	{
	  _usableParts = NSNoScrollerParts;
	}
    }
}

- (void) setEnabled: (BOOL)flag
{
  if (_isEnabled == flag)
    {
      return;
    }
  
  _isEnabled = flag;
  _cacheValid = NO;
  [self setNeedsDisplay: YES];
}

- (void) setArrowsPosition: (NSScrollArrowPosition)where
{
  if (_arrowsPosition == where)
    {
      return;
    }
  
  _arrowsPosition = where;
  _cacheValid = NO;
  [self setNeedsDisplay: YES];
}

- (void) setFloatValue: (float)aFloat
{
  if (_floatValue == aFloat)
    {
      /* Most likely our trackKnob method initiated this via NSScrollView */
      return;
    }
  if (aFloat < 0)
    {
      _floatValue = 0;
    }
  else if (aFloat > 1)
    {
      _floatValue = 1;
    }
  else
    {
      _floatValue = aFloat;
    }

  [self setNeedsDisplayInRect: [self rectForPart: NSScrollerKnobSlot]];
}

- (void) setFloatValue: (float)aFloat knobProportion: (float)ratio
{
  if (_floatValue == aFloat && _knobProportion == ratio)
    {
      /* Most likely our trackKnob method initiated this via NSScrollView */
      return;
    }
  if (ratio < 0)
    {
      _knobProportion = 0;
    }
  else if (ratio > 1)
    {
      _knobProportion = 1;
    }
  else
    {
      _knobProportion = ratio;
    }

  /* Make sure we mark ourselves as needing redisplay.  */
  _floatValue = -1;
  
  [self setFloatValue: aFloat];
}

- (void) setFrame: (NSRect)frameRect
{
  /*
   * determine the orientation of the scroller and adjust it's size accordingly
   */
  if (frameRect.size.width > frameRect.size.height)
    {
      _isHorizontal = YES;
      frameRect.size.height = [isa scrollerWidth];
    }
  else
    {
      _isHorizontal = NO;
      frameRect.size.width = [isa scrollerWidth];
    }

  [super setFrame: frameRect];

  if (_arrowsPosition != NSScrollerArrowsNone)
    {
      if (_isHorizontal)
	{
	  _arrowsPosition = NSScrollerArrowsMinEnd;
	}
      else
	{
	  _arrowsPosition = NSScrollerArrowsMaxEnd;
	}
    }

  _hitPart = NSScrollerNoPart;
  _cacheValid = NO;
  [self checkSpaceForParts];
}

- (void) setFrameSize: (NSSize)size
{
  [super setFrameSize: size];
  [self checkSpaceForParts];
  _cacheValid = NO;
  [self setNeedsDisplay: YES];
}

- (NSScrollerPart)testPart: (NSPoint)thePoint
{
  /*
   * return what part of the scroller the mouse hit
   */
  NSRect rect;

  /* thePoint is in window's coordinate system; convert it to
   * our own coordinate system.  */
  thePoint = [self convertPoint: thePoint fromView: nil];

  if (thePoint.x <= 0 || thePoint.x >= _frame.size.width
    || thePoint.y <= 0 || thePoint.y >= _frame.size.height)
    return NSScrollerNoPart;

  rect = [self rectForPart: NSScrollerDecrementLine];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerDecrementLine;

  rect = [self rectForPart: NSScrollerIncrementLine];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerIncrementLine;

  rect = [self rectForPart: NSScrollerKnob];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerKnob;

  rect = [self rectForPart: NSScrollerDecrementPage];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerDecrementPage;

  rect = [self rectForPart: NSScrollerIncrementPage];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerIncrementPage;

  rect = [self rectForPart: NSScrollerKnobSlot];
  if ([self mouse: thePoint inRect: rect])
    return NSScrollerKnobSlot;

  return NSScrollerNoPart;
}

- (float) _floatValueForMousePoint: (NSPoint)point
{
  NSRect knobRect = [self rectForPart: NSScrollerKnob];
  NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];
  float position;
  float min_pos;
  float max_pos;

  /*
   * Compute limits and mouse position
   */
  if (_isHorizontal)
    {
      min_pos = NSMinX(slotRect) + NSWidth(knobRect) / 2;
      max_pos = NSMaxX(slotRect) - NSWidth(knobRect) / 2;
      position = point.x;
    }
  else
    {
      min_pos = NSMinY(slotRect) + NSHeight(knobRect) / 2;
      max_pos = NSMaxY(slotRect) - NSHeight(knobRect) / 2;
      position = point.y;
    }

  /*
   * Compute float value
   */

  if (position <= min_pos)
    return 0;
  if (position >= max_pos)
    return 1;
  return (position - min_pos) / (max_pos - min_pos);
}


- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  _hitPart = [self testPart: location];
  [self _setTargetAndActionToCells];

  switch (_hitPart)
    {
      case NSScrollerIncrementLine:
      case NSScrollerDecrementLine:
	/*
	 * A hit on a scroller button should be a page movement
	 * if the alt key is pressed.
	 */
	if ([theEvent modifierFlags] & NSAlternateKeyMask)
	  {
	    if (_hitPart == NSScrollerIncrementLine)
	      {
		_hitPart = NSScrollerIncrementPage;
	      }
	    else
	      {
		_hitPart = NSScrollerDecrementPage;
	      }
	  }
	/* Fall through to next case */

      case NSScrollerIncrementPage:
      case NSScrollerDecrementPage:
	[self trackScrollButtons: theEvent];
	break;

      case NSScrollerKnob:
	[self trackKnob: theEvent];
	break;

      case NSScrollerKnobSlot:
	{
	  float floatValue = [self _floatValueForMousePoint: 
				     [self convertPoint: location
					   fromView: nil]];
	  if (floatValue != _floatValue)
	    {
	      [self setFloatValue: floatValue];
	      [self sendAction: _action to: _target];
	    }
	  [self trackKnob: theEvent];
	  break;
	}

      case NSScrollerNoPart:
	break;
    }

  _hitPart = NSScrollerNoPart;
}

- (void) trackKnob: (NSEvent*)theEvent
{
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			  | NSLeftMouseDraggedMask | NSFlagsChangedMask;
  NSPoint	point;
  float		lastPosition;
  float		newPosition;
  float		floatValue;
  float		offset;
  float		initialOffset;
  NSEvent	*presentEvent;
  NSEventType	eventType = [theEvent type];
  NSRect	knobRect;
  unsigned	flags = [theEvent modifierFlags];

  knobRect = [self rectForPart: NSScrollerKnob];

  point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  if (_isHorizontal)
    {
      lastPosition = NSMidX(knobRect);
      offset = lastPosition - point.x;
    }
  else
    {
      lastPosition = NSMidY(knobRect);
      offset = lastPosition - point.y;
    }

  initialOffset = offset; /* Save the initial offset value */
  _hitPart = NSScrollerKnob;

  do
    {
       /* Inner loop that gets and (quickly) handles all events that have
          already arrived. */
       while (theEvent && eventType != NSLeftMouseUp)
         {
           /* Note the event here. Don't do any expensive handling. */
	   if (eventType == NSFlagsChanged)
             flags = [theEvent modifierFlags];
	   presentEvent = theEvent;

           theEvent = [NSApp nextEventMatchingMask: eventMask
                         untilDate: [NSDate distantPast] /* Only get events that have already arrived. */
                         inMode: NSEventTrackingRunLoopMode
                         dequeue: YES];
	   eventType = [theEvent type];
         }

       /* 
        * No more events right now. Do expensive handling, like drawing, 
	* here. 
	*/
       point = [self convertPoint: [presentEvent locationInWindow] 
			 fromView: nil];

       if (_isHorizontal)
         newPosition = point.x + offset;
       else
	 newPosition = point.y + offset;

       if (newPosition != lastPosition)
         {
           if (flags & NSAlternateKeyMask)
	     {
	       float	diff;

	       diff = newPosition - lastPosition;
	       diff = diff * 3 / 4;
	       offset -= diff;
	       newPosition -= diff;
	     }
	   else /* Ok, we are no longer doing slow scrolling, lets go back 
		   to our original offset. */
	     {
	       offset = initialOffset;
	     }

           // only one coordinate (X or Y) is used to compute floatValue.
           point = NSMakePoint(newPosition, newPosition);
	   floatValue = [self _floatValueForMousePoint: point];

	   if (floatValue != _floatValue)
	     {
	       [self setFloatValue: floatValue];
	       [self sendAction: _action to: _target];
	     }
	      
	     lastPosition = newPosition;
         }

       /* 
	* If our current event is actually the mouse up (perhaps the inner 
	* loop got to this point) we want to update with the last info and 
	* then quit.
	*/
       if (eventType == NSLeftMouseUp)
         break;

       /* Get the next event, blocking if necessary. */
       theEvent = [NSApp nextEventMatchingMask: eventMask
                     untilDate: nil /* No limit, block until we get an event. */
                     inMode: NSEventTrackingRunLoopMode
                     dequeue: YES];
       eventType = [theEvent type];
  } while (eventType != NSLeftMouseUp);
}

- (void) trackScrollButtons: (NSEvent*)theEvent
{
  id		theCell = nil;
  NSRect	rect;

  [self lockFocus];

  NSDebugLog (@"trackScrollButtons");

  _hitPart = [self testPart: [theEvent locationInWindow]];
  rect = [self rectForPart: _hitPart];

  /*
   * A hit on a scroller button should be a page movement
   * if the alt key is pressed.
   */
  switch (_hitPart)
    {
      case NSScrollerIncrementLine:
        if ([theEvent modifierFlags] & NSAlternateKeyMask)
	  {
	    _hitPart = NSScrollerIncrementPage;
	  }
	/* Fall through to next case */
      case NSScrollerIncrementPage:
	theCell = (_isHorizontal ? rightCell : downCell);
	break;

      case NSScrollerDecrementLine:
	if ([theEvent modifierFlags] & NSAlternateKeyMask)
	  {
	    _hitPart = NSScrollerDecrementPage;
	  }
	/* Fall through to next case */
      case NSScrollerDecrementPage:
	theCell = (_isHorizontal ? leftCell : upCell);
	break;

      default:
	theCell = nil;
	break;
    }

  /*
   * If we don't find a cell this has been all for naught, but we 
   * shouldn't ever be in that situation.
   */
  if (theCell)
    {
      [theCell highlight: YES withFrame: rect inView: self];
      [_window flushWindow];

      NSDebugLog (@"tracking cell %x", theCell);

      /*
       * The "tracking" in this method actually takes place within 
       * NSCell's trackMouse: method. 
       */
      [theCell trackMouse: theEvent
		   inRect: rect
		   ofView: self
	     untilMouseUp: YES];

      [theCell highlight: NO withFrame: rect inView: self];
      [_window flushWindow];
    }
  [self unlockFocus];

  NSDebugLog (@"return from trackScrollButtons");
}

/*
 *	draw the scroller
 */
- (void) drawRect: (NSRect)rect
{
  static NSRect rectForPartIncrementLine;
  static NSRect rectForPartDecrementLine;
  static NSRect rectForPartKnobSlot;
  
  if (_cacheValid == NO)
    {
      rectForPartIncrementLine = [self rectForPart: NSScrollerIncrementLine];
      rectForPartDecrementLine = [self rectForPart: NSScrollerDecrementLine];
      rectForPartKnobSlot = [self rectForPart: NSScrollerKnobSlot];
    }

  [[_window backgroundColor] set];
  NSRectFill (rect);

  if (NSIntersectsRect (rect, rectForPartKnobSlot) == YES)
    {
      [self drawKnobSlot];
      [self drawKnob];
    }

  if (NSIntersectsRect (rect, rectForPartDecrementLine) == YES)
    {
      [self drawArrow: NSScrollerDecrementArrow highlight: NO];
    }
  if (NSIntersectsRect (rect, rectForPartIncrementLine) == YES)
    {
      [self drawArrow: NSScrollerIncrementArrow highlight: NO];
    }
}

- (void) drawArrow: (NSScrollerArrow)whichButton highlight: (BOOL)flag
{
  NSRect rect = [self rectForPart: (whichButton == NSScrollerIncrementArrow
		? NSScrollerIncrementLine : NSScrollerDecrementLine)];
  id theCell = nil;

  NSDebugLLog (@"NSScroller", @"position of %s cell is (%f, %f)",
	(whichButton == NSScrollerIncrementArrow ? "increment" : "decrement"),
	rect.origin.x, rect.origin.y);

  switch (whichButton)
    {
      case NSScrollerDecrementArrow:
	theCell = (_isHorizontal ? leftCell : upCell);
	break;
      case NSScrollerIncrementArrow:
	theCell = (_isHorizontal ? rightCell : downCell);
	break;
    }

  [theCell setHighlighted: flag];
  [theCell drawWithFrame: rect  inView: self];
}

- (void) drawKnob
{
  [knobCell drawWithFrame: [self rectForPart: NSScrollerKnob] inView: self];
}

- (void) drawKnobSlot
{
  static NSRect rect;

  if (_cacheValid == NO)
    {
      rect = [self rectForPart: NSScrollerKnobSlot];
    }

  if ((_usableParts == NSOnlyScrollerArrows) || (_usableParts == NSNoScrollerParts))
    [[_window backgroundColor] set];
  else
    [scrollBarColor set];
  NSRectFill (rect);
}

- (void) highlight: (BOOL)flag
{
  switch (_hitPart)
    {
      case NSScrollerIncrementLine:
      case NSScrollerIncrementPage:
	[self drawArrow: NSScrollerIncrementArrow highlight: flag];
	break;

      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
	[self drawArrow: NSScrollerDecrementArrow highlight: flag];
	break;

      default:	/* No button currently hit for highlighting. */
	break;
    }
}

- (NSRect) rectForPart: (NSScrollerPart)partCode
{
  NSRect scrollerFrame = _frame;
  float x = 1, y = 1;
  float width, height;
  float buttonsSize = 2 * buttonsWidth + 2;
  NSUsableScrollerParts usableParts;
  /*
   * If the scroller is disabled then the scroller buttons and the
   * knob are not displayed at all.
   */
  if (!_isEnabled)
    {
      usableParts = NSNoScrollerParts;
    }
  else
    {
      usableParts = _usableParts;
    }

  /*
   * Assign to `width' and `height' values describing
   * the width and height of the scroller regardless
   * of its orientation.
   * but keeps track of the scroller's orientation.
   */
  if (_isHorizontal)
    {
      width = scrollerFrame.size.height - 2;
      height = scrollerFrame.size.width - 2;
    }
  else
    {
      width = scrollerFrame.size.width - 2;
      height = scrollerFrame.size.height - 2;
    }

  /*
   * The x, y, width and height values are computed below for the vertical
   * scroller.  The height of the scroll buttons is assumed to be equal to
   * the width.
   */
  switch (partCode)
    {
      case NSScrollerKnob:
	{
	  float knobHeight, knobPosition, slotHeight;

	  if (usableParts == NSNoScrollerParts
	    || usableParts == NSOnlyScrollerArrows)
	    return NSZeroRect;

	  /* calc the slot Height */
	  slotHeight = height - (_arrowsPosition == NSScrollerArrowsNone
				 ?  0 : buttonsSize);
	  knobHeight = _knobProportion * slotHeight;
	  knobHeight = (float)floor(knobHeight);
	  if (knobHeight < buttonsWidth)
	    knobHeight = buttonsWidth;

	  /* calc knob's position */
	  knobPosition = _floatValue * (slotHeight - knobHeight);
	  knobPosition = (float)floor(knobPosition);

	  /* calc actual position */
	  y += knobPosition + (_arrowsPosition == NSScrollerArrowsMaxEnd
			       || _arrowsPosition == NSScrollerArrowsNone 
			       ?  0 : buttonsSize);
	  height = knobHeight;
	  width = buttonsWidth;
	  break;
	}

      case NSScrollerKnobSlot:
	/*
	 * if the scroller does not have buttons the slot completely
	 * fills the scroller.
	 */
	if (usableParts == NSNoScrollerParts
	  || _arrowsPosition == NSScrollerArrowsNone)
	  {
	    break;
	  }
	height -= buttonsSize;
	if (_arrowsPosition == NSScrollerArrowsMinEnd)
	  {
	    y += buttonsSize;
	  }
	break;

      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
	if (usableParts == NSNoScrollerParts
	  || _arrowsPosition == NSScrollerArrowsNone)
	  {
	    return NSZeroRect;
	  }
	else if (_arrowsPosition == NSScrollerArrowsMaxEnd)
	  {
	    y += (height - buttonsSize + 1);
	  }
	width = buttonsWidth;
	height = buttonsWidth;
	break;

      case NSScrollerIncrementLine:
      case NSScrollerIncrementPage:
	if (usableParts == NSNoScrollerParts
	  || _arrowsPosition == NSScrollerArrowsNone)
	  {
	    return NSZeroRect;
	  }
	else if (_arrowsPosition == NSScrollerArrowsMaxEnd)
	  {
	    y += (height - buttonsWidth);
	  }
	else if (_arrowsPosition == NSScrollerArrowsMinEnd)
	  {
	    y += (buttonsWidth + 1);
	  }
	height = buttonsWidth;
	width = buttonsWidth;
	break;

      case NSScrollerNoPart:
	return NSZeroRect;
    }

  if (_isHorizontal)
    {
      return NSMakeRect (y, x, height, width);
    }
  else
    {
      return NSMakeRect (x, y, width, height);
    }
}

+ (float) scrollerWidthForControlSize: (NSControlSize)controlSize
{
  // FIXME
  return scrollerWidth;
}

- (void) setControlSize: (NSControlSize)controlSize
{
  // FIXME
}

- (NSControlSize) controlSize
{
  // FIXME
  return NSRegularControlSize;
}

- (void) setControlTint: (NSControlTint)controlTint
{
  // FIXME 
}

- (NSControlTint) controlTint
{
  // FIXME
  return NSDefaultControlTint;
}

@end
