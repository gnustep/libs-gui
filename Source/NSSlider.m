/*
   NSSlider.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998

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

#include <Foundation/NSRunLoop.h>
#include "gnustep/gui/config.h"
#include <AppKit/NSEvent.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>

static inline 
float _floatValueForMousePoint (NSPoint point, NSRect knobRect,
				NSRect slotRect, BOOL isVertical, 
				float minValue, float maxValue, 
				NSSliderCell *theCell, BOOL flipped)
{
  float floatValue = 0;
  float position;

  // Adjust the point to lie inside the knob slot. We don't
  // have to worry whether the view is flipped or not.
  if (isVertical)
    {
      if (point.y < slotRect.origin.y + knobRect.size.height / 2)
	{
	  position = slotRect.origin.y + knobRect.size.height / 2;
	}
      else if (point.y > slotRect.origin.y + slotRect.size.height
	- knobRect.size.height / 2)
	{
	  position = slotRect.origin.y + slotRect.size.height
	    - knobRect.size.height / 2;
	}
      else
	position = point.y;
										      // Compute the float value
      floatValue = (position - (slotRect.origin.y + knobRect.size.height/2))
	/ (slotRect.size.height - knobRect.size.height);
      if (flipped)
	floatValue = 1 - floatValue;
    }
  else
    {
      if (point.x < slotRect.origin.x + knobRect.size.width / 2)
	{
	  position = slotRect.origin.x + knobRect.size.width / 2;
	}
      else if (point.x > slotRect.origin.x + slotRect.size.width
	- knobRect.size.width / 2)
	{
	  position = slotRect.origin.x + slotRect.size.width
	    - knobRect.size.width / 2;
	}
      else
	position = point.x;

      // Compute the float value given the knob size
      floatValue = (position - (slotRect.origin.x + knobRect.size.width / 2))
	/ (slotRect.size.width - knobRect.size.width);
    }

  return floatValue * (maxValue - minValue) + minValue;
}


@implementation NSSlider

static Class cellClass;

+ (void) initialize
{
  if (self == [NSSlider class])
    {
      // Initial version
      [self setVersion: 1];

      // Set our cell class to NSSliderCell
      [self setCellClass: [NSSliderCell class]];
    }
}

+ (void) setCellClass: (Class)class
{
  cellClass = class;
}

+ (Class) cellClass
{
  return cellClass;
}

- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];

  [_cell setState: 1];
  [_cell setContinuous: YES];
  return self;
}

- (NSImage *) image
{
  return [_cell image];
}

- (int) isVertical
{
  return [_cell isVertical];
}

- (float) knobThickness
{
  return [_cell knobThickness];
}

- (void) setImage: (NSImage *)backgroundImage
{
  [_cell setImage: backgroundImage];
}

- (void) setKnobThickness: (float)aFloat
{
  [_cell setKnobThickness: aFloat];
}

- (void) setTitle: (NSString *)aString
{
  [_cell setTitle: aString];
}

- (void) setTitleCell: (NSCell *)aCell
{
  [_cell setTitleCell: aCell];
}

- (void) setTitleColor: (NSColor *)aColor
{
  [_cell setTitleColor: aColor];
}

- (void) setTitleFont: (NSFont *)fontObject
{
  [_cell setTitleFont: fontObject];
}

- (NSString *) title
{
  return [_cell title];
}

- (id) titleCell
{
  return [_cell titleCell];
}

- (NSColor *) titleColor
{
  return [_cell titleColor];
}

- (NSFont *) titleFont
{
  return [_cell titleFont];
}

- (double) maxValue
{
  return [_cell maxValue];
}

- (double) minValue
{
  return [_cell minValue];
}

- (void) setMaxValue: (double)aDouble
{
  [_cell setMaxValue: aDouble];
}

- (void) setMinValue: (double)aDouble
{
  [_cell setMinValue: aDouble];
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  /*
   * Give the cell our bounds to draw in, not the rect - if we give it a rect
   * that represents an exposed part of this view, it will try to draw the
   * slider knob positioned in that rectangle ... which is wrong.
   */
  [_cell drawWithFrame: _bounds inView: self];
}

- (void) trackKnob: (NSEvent*)theEvent knobRect: (NSRect)knobRect
{
  NSApplication *app = [NSApplication sharedApplication];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			  | NSLeftMouseDraggedMask | NSMouseMovedMask
			  | NSPeriodicMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow] 
			fromView: nil];
  NSEventType eventType = [theEvent type];
  BOOL isContinuous = [_cell isContinuous];
  float oldFloatValue = [_cell floatValue];
  id target = [_cell target];
  SEL action = [_cell action];
  NSDate *distantFuture = [NSDate distantFuture];
  NSRect slotRect = [_cell trackRect];
  BOOL isVertical = [_cell isVertical];
  float minValue = [_cell minValue];
  float maxValue = [_cell maxValue];

  [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  while (eventType != NSLeftMouseUp)
    {
      theEvent = [app nextEventMatchingMask: eventMask
				  untilDate: distantFuture
				     inMode: NSEventTrackingRunLoopMode
				    dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic)
	{
	  point = [self convertPoint: [theEvent locationInWindow]
			fromView: nil];
	}
      else
	{
	  if (point.x != knobRect.origin.x || point.y != knobRect.origin.y)
	    {
	      float floatValue;
	      floatValue = _floatValueForMousePoint (point, knobRect,
						     slotRect, isVertical, 
						     minValue, maxValue, 
						     _cell, 
						     _rFlags.flipped_view); 
	      if (floatValue != oldFloatValue)
		{
		  [_cell setFloatValue: floatValue];
		  [_cell drawWithFrame: _bounds inView: self];
		  [_window flushWindow];
		  if (isContinuous)
		    {
		      [target performSelector: action withObject: self];
		    }
		  oldFloatValue = floatValue;
		}
	      knobRect.origin = point;
	    }
	}
    }
  // If the control is not continuous send the action at the end of the drag
  if (!isContinuous)
    {
      [target performSelector: action withObject: self];
    }
  [NSEvent stopPeriodicEvents];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [self convertPoint: [theEvent locationInWindow] 
			   fromView: nil];
  NSRect rect;

  rect = [_cell knobRectFlipped: _rFlags.flipped_view];
  if (![self mouse: location inRect: rect])
    {
      // Mouse is not on the knob, move the knob to the mouse position
      float floatValue;
      floatValue = _floatValueForMousePoint (location, rect, 
					     [_cell trackRect], 
					     [_cell isVertical], 
					     [_cell minValue], 
					     [_cell maxValue], _cell, 
					     _rFlags.flipped_view); 
      [_cell setFloatValue: floatValue];
      if ([_cell isContinuous])
	{
	  [[_cell target] performSelector: [_cell action]  withObject: self];
	}
      [_cell drawWithFrame: _bounds inView: self];
      [_window flushWindow];
    }

  [self trackKnob: theEvent knobRect: rect];
}

@end
