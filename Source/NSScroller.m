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
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <math.h>

#include <Foundation/NSDate.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSDebug.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSScroller.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSWindow.h"

#include "GNUstepGUI/GSTheme.h"

/**<p>TODO Description</p>
 */
@implementation NSScroller

/*
 * Class variables
 */

/* button cells used by scroller instances to draw scroller buttons and knob. */
static NSButtonCell	*upCell = nil;
static NSButtonCell	*downCell = nil;
static NSButtonCell	*leftCell = nil;
static NSButtonCell	*rightCell = nil;
static NSCell	*horizontalKnobCell = nil;
static NSCell	*verticalKnobCell = nil;
static NSCell	*horizontalKnobSlotCell = nil;
static NSCell	*verticalKnobSlotCell = nil;
static float	scrollerWidth = 18.0;

static const float buttonsOffset = 2; // buttonsWidth = sw - buttonsOffset

+ (void) _themeWillActivate: (NSNotification*)n
{
  /* Clear cached information from the old theme ... will get info from
   * the new theme as required.
   */
  scrollerWidth = 0.0;
  DESTROY(upCell);
}

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSScroller class])
    {
      [self setVersion: 1];
      [[NSNotificationCenter defaultCenter] addObserver: self
	selector: @selector(_themeWillActivate:)
	name: GSThemeWillActivateNotification
	object: nil];
    }
}

/**<p>Returns the NSScroller's width. By default 18.</p>
   <p>Subclasses can override this to provide different scrollbar width.  But
   you may need to also override -drawParts .</p>
 */
+ (float) scrollerWidth
{
  if (scrollerWidth == 0.0)
    {
      scrollerWidth = [[GSTheme theme] defaultScrollerWidth];  
    }
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

- (BOOL) acceptsFirstResponder
{
  return NO;
}

/** <p>Returns the position of the NSScroller's arrows used for scrolling 
    By default the arrow position is set to <ref type="type" 
    id="NSScrollArrowPosition">NSScrollerArrowsMinEnd</ref> if the 
    scrolletr is a horizontal scroller and <ref type="type" 
    id="NSScrollArrowPosition">NSScrollerArrowsMaxEnd</ref> if the scroller
    is a vertical scroller. See <ref type="type" id="NSScrollArrowPosition">
    NSScrollArrowPosition</ref> for more informations.</p>
    <p>See Also: -arrowsPosition</p>
 */
- (NSScrollArrowPosition) arrowsPosition
{
  return _arrowsPosition;
}

- (NSUsableScrollerParts) usableParts
{
  return _usableParts;
}

/**<p>Returns a float value ( between 0.0 and 1.0 ) indicating the ratio
   between the NSScroller length and the knob length</p>
 */
- (float) knobProportion
{
  return _knobProportion;
}

/**<p>Returns the part of the NSScroller that have been hit ( mouse down )
   See <ref type="type" id="NSScrollerPart">NSScrollerPart</ref> for more 
   information </p><p>See Also: -highlight: [NSResponder-mouseDown:]</p>
 */
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

  if ([aDecoder allowsKeyedCoding])
    {
      NSString *action = [aDecoder decodeObjectForKey: @"NSAction"];
      id target = [aDecoder decodeObjectForKey: @"NSTarget"];
      float value = 0.0;
      float percent = 0.0;
      int flags;

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

      if (action != nil)
        {
	  [self setAction: NSSelectorFromString(action)];
	}
      [self setTarget: target];
      
      if ([aDecoder containsValueForKey: @"NSCurValue"])
        {
	  value = [aDecoder decodeFloatForKey: @"NSCurValue"];
	}
      if ([aDecoder containsValueForKey: @"NSPercent"])
        {
	  percent = [aDecoder decodeFloatForKey: @"NSPercent"];
	}
      [self setFloatValue: value knobProportion: percent];

      if ([aDecoder containsValueForKey: @"NSsFlags"])
        {
	  flags = [aDecoder decodeIntForKey: @"NSsFlags"];
	  // is horiz is set above...
	  
	}

      // setup...
      _hitPart = NSScrollerNoPart;

      [self drawParts];
      [self checkSpaceForParts];
    }
  else
    {
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
      
      [aDecoder decodeValueOfObjCType: @encode(unsigned int)
				   at: &_arrowsPosition];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isEnabled];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_target];
      // Undo RETAIN by decoder
      TEST_RELEASE(_target);
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];

      [self drawParts];
      [self checkSpaceForParts];
    }

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

/**
 *  Cache images for scroll arrows and knob.  If you override +scrollerWidth
 *  you may need to override this as well (to provide images for the new
 *  width).  However, if you do so, you must currently also override
 *  -drawArrow:highlight: and -drawKnob: .
 */
- (void) drawParts
{
  GSTheme *theme = [GSTheme theme] ;

  if (upCell)
    return;

  ASSIGN(upCell ,[theme cellForScrollerArrow:
    NSScrollerDecrementArrow horizontal:NO]);
  ASSIGN(downCell, [theme cellForScrollerArrow:
    NSScrollerIncrementArrow horizontal:NO]);
  ASSIGN(leftCell, [theme cellForScrollerArrow:
    NSScrollerDecrementArrow horizontal:YES]);
  ASSIGN(rightCell, [theme cellForScrollerArrow:
    NSScrollerIncrementArrow horizontal:YES]);
  ASSIGN(verticalKnobCell, [theme cellForScrollerKnob: NO]);
  ASSIGN(horizontalKnobCell, [theme cellForScrollerKnob: YES]);
  ASSIGN(verticalKnobSlotCell, [theme cellForScrollerKnobSlot: NO]);
  ASSIGN(horizontalKnobSlotCell, [theme cellForScrollerKnobSlot: YES]);

  [downCell setContinuous: YES];
  [downCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [downCell setPeriodicDelay: 0.3 interval: 0.03];
           
  [leftCell setContinuous: YES];
  [leftCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [leftCell setPeriodicDelay: 0.3 interval: 0.03];
           
  [rightCell setContinuous: YES];
  [rightCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [rightCell setPeriodicDelay: 0.3 interval: 0.03];
  
  [upCell setContinuous: YES];
  [upCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [upCell setPeriodicDelay: 0.3 interval: 0.03];
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

  [horizontalKnobCell setTarget: _target];
  [horizontalKnobCell setAction: _action];
  
  [verticalKnobCell setTarget:_target];
  [horizontalKnobCell setTarget:_target];
}

- (void) checkSpaceForParts
{
  NSSize	frameSize = _frame.size;
  float		size = (_isHorizontal ? frameSize.width : frameSize.height);
  int		buttonsWidth = [isa scrollerWidth] - buttonsOffset;

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

/** <p>Sets the position of the NSScroller arrows used for scrolling to 
    <var>where</var> and marks self for display. By default the arrow position
    is set to <ref type="type" id="NSScrollArrowPosition">
    NSScrollerArrowsMinEnd</ref> if the scroller is a horizontal scroller
    and <ref type="type" id="NSScrollArrowPosition">NSScrollerArrowsMaxEnd
    </ref> if the scroller is a vertical scroller. See <ref type="type"
    id="NSScrollArrowPosition">NSScrollArrowPosition</ref> for more
    informations.</p><p>See Also: -arrowsPosition</p>
 */
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
      _pendingKnobProportion = 0;
    }
  else if (ratio > 1)
    {
      _pendingKnobProportion = 1;
    }
  else
    {
      _pendingKnobProportion = ratio;
    }
    
  if (_hitPart == NSScrollerNoPart)
    {
      _knobProportion = _pendingKnobProportion;
      _pendingKnobProportion = 0;
    }

  // Handle the case when parts should disappear
  if (_knobProportion == 1)
    {
      [self setEnabled: NO];
    }
  else
    {
      [self setEnabled: YES];
    }
  
  // Don't set float value if knob is being dragged
  if (_hitPart != NSScrollerKnobSlot && _hitPart != NSScrollerKnob)
    {
      /* Make sure we mark ourselves as needing redisplay.  */
      _floatValue = -1;

      [self setFloatValue: aFloat];
    }
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

/**<p>Returns the NSScroller's part under the point <var>thePoint</var>.
   See <ref type="type" id="NSScrollerPart">NSScrollerPart</ref> for more 
   informations</p>   
 */
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
  if (_pendingKnobProportion)
    {
      [self setFloatValue: _floatValue knobProportion: _pendingKnobProportion];
    }
  else
    {
      [self setNeedsDisplay:YES];
    }
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
  NSEvent	*presentEvent = theEvent;
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

/**<p>(Un)Highlight the button specified by <var>whichButton</var>.
   <var>whichButton</var> should be <ref type="type" id="NSScrollerArrow">
   NSScrollerDecrementArrow</ref> or <ref type="type" id="NSScrollerArrow">
   NSScrollerIncrementArrow</ref></p>
   <p>See Also: [NSCell-setHighlighted:] [NSCell-drawWithFrame:inView:]</p>
 */
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

/**<p>Draws the knob</p>
 */
- (void) drawKnob
{
  if (_isHorizontal)
    [horizontalKnobCell drawWithFrame: [self rectForPart: NSScrollerKnob] inView: self];
  else
    [verticalKnobCell drawWithFrame: [self rectForPart: NSScrollerKnob] inView: self];
}

- (void) drawKnobSlot
{
  static NSRect rect;

  if (_cacheValid == NO)
    {
      rect = [self rectForPart: NSScrollerKnobSlot];
    }

  if (_isHorizontal)
    [horizontalKnobSlotCell drawWithFrame:rect inView:self];
  else
    [verticalKnobSlotCell drawWithFrame:rect inView:self];
}

/**<p>Highlights the button whose under the mouse. Does nothing if the mouse
   is not under a button</p><p>See Also: -drawArrow:highlight:</p>
 */
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

/**
 */
- (NSRect) rectForPart: (NSScrollerPart)partCode
{
  NSRect scrollerFrame = _frame;
  float x, y;
  float width, height;
  float buttonsWidth;
  float buttonsSize;  
  NSUsableScrollerParts usableParts;

  NSInterfaceStyle interfaceStyle = NSInterfaceStyleForKey(@"NSScrollerInterfaceStyle",self);

  /* We use the button offset if we in the NeXTstep interface style. */
  if (interfaceStyle == NSNextStepInterfaceStyle
    || interfaceStyle == GSWindowMakerInterfaceStyle)
    { 
      buttonsWidth = ([isa scrollerWidth] - buttonsOffset);
      x = y = 1.0;
      buttonsSize = 2 * buttonsWidth + 2;
    }
  else
    {
      buttonsWidth = [isa scrollerWidth];
      x = y = 1.0;
      buttonsSize = 2 * buttonsWidth;
    }


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
	    {
	      return NSZeroRect;
	    }

	  /* calc the slot Height */
	  slotHeight = height - (_arrowsPosition == NSScrollerArrowsNone
	    ?  0 : buttonsSize);
	  knobHeight = _knobProportion * slotHeight;
	  knobHeight = (float)floor(knobHeight);
	  if (knobHeight < buttonsWidth)
	    knobHeight = buttonsWidth;

	  /* calc knob's position */
	  knobPosition = _floatValue * (slotHeight - knobHeight);
	  knobPosition = floor(knobPosition);


	  /* calc actual position */
          if (interfaceStyle == NSNextStepInterfaceStyle
	    || interfaceStyle == GSWindowMakerInterfaceStyle)
	    {
	      y += knobPosition + ((_arrowsPosition == NSScrollerArrowsMaxEnd
		|| _arrowsPosition == NSScrollerArrowsNone)
		?  0 : buttonsSize);
	      width = buttonsWidth;
	    }
          else
	    {
	      y += knobPosition + ((_arrowsPosition == NSScrollerArrowsNone)
		? 0 : buttonsWidth); 
	      width = buttonsWidth ;
	    }

	  height = knobHeight;
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
	if ( (interfaceStyle == NSNextStepInterfaceStyle || 
              interfaceStyle == GSWindowMakerInterfaceStyle) 
            && _arrowsPosition == NSScrollerArrowsMinEnd)
	  {
	    y += buttonsSize;
	  }
        else if (interfaceStyle != NSNextStepInterfaceStyle
	  && interfaceStyle != GSWindowMakerInterfaceStyle)
          {
            y += buttonsWidth;
            width = buttonsWidth;
          }
        break;

      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
	if (usableParts == NSNoScrollerParts
	  || _arrowsPosition == NSScrollerArrowsNone)
	  {
	    return NSZeroRect;
	  }
	else if ((interfaceStyle == NSNextStepInterfaceStyle
	  || interfaceStyle == GSWindowMakerInterfaceStyle)
	  && _arrowsPosition == NSScrollerArrowsMaxEnd)
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
        else if (interfaceStyle == NSNextStepInterfaceStyle 
	  || interfaceStyle == GSWindowMakerInterfaceStyle)
          {
	    if (_arrowsPosition == NSScrollerArrowsMaxEnd)
	      {
	        y += (height - buttonsWidth);
	      }
	    else if (_arrowsPosition == NSScrollerArrowsMinEnd)
	      {
	        y += (buttonsWidth + 1);
	      }
          }
        else 
          {
            y += (height - buttonsWidth);
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
  return [self scrollerWidth];
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
