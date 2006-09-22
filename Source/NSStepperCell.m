/** <title>NSStepperCell</title>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: August 2006
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include "config.h"

#include "AppKit/NSApplication.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSControl.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSStepperCell.h"
#include "AppKit/NSWindow.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSTheme.h"

// Hard coded values for button sizes
#define STEPPER_WIDTH 15
#define STEPPER_HEIGHT 11

@interface NSStepperCell (Private)
- (void) _increment;
- (void) _decrement;
- (void) setHighlighted: (BOOL)highlight
	       upButton: (BOOL)upButton
	      withFrame: (NSRect)frame
		 inView: (NSView*)controlView;
- (NSRect) upButtonRectWithFrame: (NSRect)frame;
- (NSRect) downButtonRectWithFrame: (NSRect)frame;
@end

@implementation NSStepperCell

+ (void) initialize
{
  if (self == [NSStepperCell class])
    {
      [self setVersion: 1];
    }
}

+ (BOOL) prefersTrackingUntilMouseUp
{
  return YES;
}

//
// Initialization
//
- (id) init
{
  self = [super init];

  [self setIntValue: 0];
  [self setAlignment: NSRightTextAlignment];
  [self setWraps: NO];
  _autorepeat = YES;
  _valueWraps = YES;
  _maxValue = 59;
  _minValue = 0;
  _increment = 1;

  highlightUp = NO;
  highlightDown = NO;

  return self;
}

- (double) maxValue
{
  return _maxValue;
}

- (void) setMaxValue: (double)maxValue
{
  _maxValue = maxValue;
}

- (double) minValue
{
  return _minValue;
}

- (void) setMinValue: (double)minValue
{
  _minValue = minValue;
}

- (double) increment
{
  return _increment;
}

- (void) setIncrement: (double)increment
{
  _increment = increment;
}

- (BOOL)autorepeat
{
  return _autorepeat;
}

- (void)setAutorepeat: (BOOL)autorepeat
{
  _autorepeat = autorepeat;
}

- (BOOL)valueWraps
{
  return _valueWraps;
}

- (void)setValueWraps: (BOOL)valueWraps
{
  _valueWraps = valueWraps;
}

static inline NSRect DrawLightButton(NSRect border, NSRect clip)
{
/*
  NSRect highlightRect = NSInsetRect(border, 1., 1.);
  [[GSTheme theme] drawButton: border : clip];
  return highlightRect;
*/
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge}; 
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge}; 
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, dark, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

static inline void DrawUpButton(NSRect aRect)
{
  NSRect unHighlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);
      
  PSsetlinewidth(1.0);
  [[NSColor controlShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  [[NSColor controlLightHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

static inline void HighlightUpButton(NSRect aRect)
{
  NSRect highlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetlinewidth(1.0);
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

static inline void DrawDownButton(NSRect aRect)
{
  NSRect unHighlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);

  PSsetlinewidth(1.0);
  [[NSColor controlShadowColor] set];
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  [[NSColor controlLightHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

static inline void HighlightDownButton(NSRect aRect)
{
  NSRect highlightRect = DrawLightButton(aRect, NSZeroRect);
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetlinewidth(1.0);
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)controlView
{
  NSRect upRect;
  NSRect downRect;
  NSRect twoButtons;

  upRect = [self upButtonRectWithFrame: cellFrame];
  downRect = [self downButtonRectWithFrame: cellFrame];
  
  twoButtons = downRect;
  twoButtons.origin.y--;
  twoButtons.size.width++;
  twoButtons.size.height = 2 * STEPPER_HEIGHT + 1;

  if (highlightUp)
    HighlightUpButton(upRect);
  else
    DrawUpButton(upRect);

  if (highlightDown)
    HighlightDownButton(downRect);
  else
    DrawDownButton(downRect);

  {
    NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge};
    NSColor *black = [NSColor controlDarkShadowColor];
    NSColor *grays[] = {black, black}; 
    
    NSDrawColorTiledRects(twoButtons, NSZeroRect,
			  up_sides, grays, 2);
  }
}

- (void) getPeriodicDelay: (float*)delay interval: (float*)interval
{
  *delay = 0.5;
  *interval = 0.025;
}

- (BOOL) trackMouse: (NSEvent*)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView*)controlView
       untilMouseUp: (BOOL)flag
{
  NSPoint location = [theEvent locationInWindow];
  NSPoint point = [controlView convertPoint: location fromView: nil];
  NSRect upRect;
  NSRect downRect;
  NSRect rect;
  float delay;
  float	interval;
  BOOL overButton = YES;
  unsigned int event_mask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  unsigned int periodCount = 0;
  BOOL isDirectionUp;
  BOOL autorepeat = [self autorepeat];
  BOOL done = NO;
  BOOL mouseWentUp = NO;

  _mouse_down_flags = [theEvent modifierFlags];
  if (![self startTrackingAt: point inView: controlView])
    return NO;

  if (![controlView mouse: point inRect: cellFrame])
    return NO;	// point is not in cell

  if ([self isEnabled] == NO)
    return NO;

  if ([theEvent type] != NSLeftMouseDown)
    return NO;

  upRect = [self upButtonRectWithFrame: cellFrame];
  downRect = [self downButtonRectWithFrame: cellFrame];
  
  // Did the mouse go down in the up or in the down part?
  if (NSMouseInRect(point, upRect, NO))
    {
      isDirectionUp = YES;
      rect = upRect;
    }
  else if (NSMouseInRect(point, downRect, NO))
    {
      isDirectionUp = NO;
      rect = downRect;
    }
  else
    {
      return mouseWentUp;
    }

  [self setHighlighted: YES
	upButton: isDirectionUp
	withFrame: cellFrame
	inView: controlView];

  if (autorepeat)
    {
      [self getPeriodicDelay: &delay interval: &interval];
      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod: interval];
      event_mask |= NSPeriodicMask;
    }

  while (!done)
    {
      NSEventType	eventType;

      theEvent = [NSApp nextEventMatchingMask: event_mask
			untilDate: nil
			inMode: NSEventTrackingRunLoopMode
			dequeue: YES];
      eventType = [theEvent type];

      // Did the mouse go up?
      if (eventType == NSLeftMouseUp)
	{
	  mouseWentUp = YES;
	  done = YES;
	}

      if (eventType == NSPeriodic)
        {
	  periodCount++;
	  if (periodCount == 4) 
	    periodCount = 0;
	  if (periodCount == 0)
	    {
	      if (isDirectionUp)
		[self _increment];
	      else
		[self _decrement];
	      [(NSControl*)controlView sendAction: [self action] to: [self target]];
	    }
	  location = [[controlView window] mouseLocationOutsideOfEventStream];
	}
      else
        {
	  location = [theEvent locationInWindow];
	}
      point = [controlView convertPoint: location fromView: nil];

      if (![controlView mouse: point inRect: cellFrame])
	{
	  if (flag == NO) 
	    {
	      done = YES;
	    }
	}

      if (NSMouseInRect(point, rect, NO) != overButton)
        {
	  overButton = !overButton;
	  if (overButton && autorepeat)
	    {
	      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod: interval];
	      periodCount = 0;
	    }
	  else
	    {
	      [NSEvent stopPeriodicEvents];
	    }
	  [self setHighlighted: overButton
		upButton: isDirectionUp
		withFrame: cellFrame
		inView: controlView];
	}
    }

  if (overButton && autorepeat)
    {
      [NSEvent stopPeriodicEvents];
    }

  if (overButton)
    {
      if (isDirectionUp)
	[self _increment];
      else
	[self _decrement];
      [(NSControl*)controlView sendAction: [self action] to: [self target]];
    }
  
  [self setHighlighted: NO
	upButton: isDirectionUp
	withFrame: cellFrame
	inView: controlView];

  return mouseWentUp;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  if([aCoder allowsKeyedCoding])
    {
      [aCoder encodeDouble: [self increment] forKey: @"NSIncrement"];
      [aCoder encodeDouble: [self maxValue] forKey: @"NSMaxValue"];
      [aCoder encodeDouble: [self minValue] forKey: @"NSMinValue"];
      [aCoder encodeBool: [self autorepeat] forKey: @"NSAutorepeat"];
      [aCoder encodeBool: [self valueWraps] forKey: @"NSValueWraps"];
    }
  else
  {
    int tmp1, tmp2;

    tmp1 = (int)_autorepeat;
    tmp2 = (int)_valueWraps;
    
    [aCoder encodeValueOfObjCType: @encode(double)
	    at: &_maxValue];
    [aCoder encodeValueOfObjCType: @encode(double)
	    at: &_minValue];
    [aCoder encodeValueOfObjCType: @encode(double)
	    at: &_increment];
    [aCoder encodeValueOfObjCType: @encode(int)
	    at: &tmp1];
    [aCoder encodeValueOfObjCType: @encode(int)
	    at: &tmp2];
  }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  if([aDecoder allowsKeyedCoding])
    {
      _autorepeat = [aDecoder decodeBoolForKey: @"NSAutorepeat"];
      _valueWraps = [aDecoder decodeBoolForKey: @"NSValueWraps"];
      _increment = [aDecoder decodeDoubleForKey: @"NSIncrement"];
      _maxValue = [aDecoder decodeDoubleForKey: @"NSMaxValue"];
      if([aDecoder containsValueForKey: @"NSMinValue"])
	{
	  _minValue = [aDecoder decodeDoubleForKey: @"NSMinValue"];
	}
    }
  else
    {
      int tmp1, tmp2;

      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_maxValue];
      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_minValue];
      [aDecoder decodeValueOfObjCType: @encode(double)
		at: &_increment];
      [aDecoder decodeValueOfObjCType: @encode(int)
		at: &tmp1];
      [aDecoder decodeValueOfObjCType: @encode(int)
		at: &tmp2];

      _autorepeat = (BOOL)tmp1;
      _valueWraps = (BOOL)tmp2;
    }

  return self;
}

@end

@implementation NSStepperCell (Private)

- (void) _increment
{
  double newValue;
  double maxValue = [self maxValue];
  double minValue = [self minValue];
  double increment = [self increment];

  newValue = [self doubleValue] + increment;
  if ([self valueWraps])
    {
      if (newValue > maxValue)
	newValue = newValue - maxValue + minValue - 1;
      else if (newValue < minValue)
	newValue = newValue + maxValue - minValue + 1;
    }
  else
    {
      if (newValue > maxValue)
	newValue = maxValue;
      else if (newValue < minValue)
	 newValue = minValue;
    }
  [self setDoubleValue: newValue];
}

- (void) _decrement
{
  double newValue;
  double maxValue = [self maxValue];
  double minValue = [self minValue];
  double increment = [self increment];

  newValue = [self doubleValue] - increment;
  if ([self valueWraps])
    {
      if (newValue > maxValue)
	newValue = newValue - maxValue + minValue - 1;
      else if (newValue < minValue)
	newValue = newValue + maxValue - minValue + 1;
    }
  else
    {
      if (newValue > maxValue)
	newValue = maxValue;
      else if (newValue < minValue)
	 newValue = minValue;
    }
  [self setDoubleValue: newValue];
}

- (void) setHighlighted: (BOOL)highlight
	       upButton: (BOOL)upButton
	      withFrame: (NSRect)frame
		 inView: (NSView*)controlView
{
  if (upButton)
    {  
      highlightUp = highlight;
    }
  else
    {
      highlightDown = highlight;
    }

  [controlView setNeedsDisplayInRect: frame];
}

- (NSRect) upButtonRectWithFrame: (NSRect)frame
{
  NSRect upRect;

  upRect.size.width = STEPPER_WIDTH;
  upRect.size.height = STEPPER_HEIGHT;
  upRect.origin.x = NSMaxX(frame) - STEPPER_WIDTH - 1;
  upRect.origin.y = NSMinY(frame) + ((int)frame.size.height / 2) + 1;
  return upRect;
}

- (NSRect) downButtonRectWithFrame: (NSRect)frame
{
  NSRect downRect;

  downRect.size.width = STEPPER_WIDTH;
  downRect.size.height = STEPPER_HEIGHT;
  downRect.origin.x = NSMaxX(frame) - STEPPER_WIDTH - 1;
  downRect.origin.y = NSMinY(frame) + ((int)frame.size.height / 2) - STEPPER_HEIGHT + 1;
  return downRect;
}

@end
