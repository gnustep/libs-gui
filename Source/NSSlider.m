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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <Foundation/NSRunLoop.h>
#include "gnustep/gui/config.h"
#include <AppKit/NSEvent.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>

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
  NSSliderCell* theCell = [[[isa cellClass] new] autorelease];

  [super initWithFrame: frameRect];

  // set our cell
  [self setCell: theCell];
  [theCell setState: 1];
  return self;
}

- (NSImage *) image
{
  return [[self cell] image];
}

- (int) isVertical
{
  return [[self cell] isVertical];
}

- (float) knobThickness
{
  return [[self cell] knobThickness];
}

- (void) setImage: (NSImage *)backgroundImage
{
  [[self cell] setImage: backgroundImage];
}

- (void) setKnobThickness: (float)aFloat
{
  [[self cell] setKnobThickness: aFloat];
}

- (void) setTitle: (NSString *)aString
{
  [[self cell] setTitle: aString];
}

- (void) setTitleCell: (NSCell *)aCell
{
  [[self cell] setTitleCell: aCell];
}

- (void) setTitleColor: (NSColor *)aColor
{
  [[self cell] setTitleColor: aColor];
}

- (void) setTitleFont: (NSFont *)fontObject
{
  [[self cell] setTitleFont: fontObject];
}

- (NSString *) title
{
  return [[self cell] title];
}

- (id) titleCell
{
  return [[self cell] titleCell];
}

- (NSColor *) titleColor
{
  return [[self cell] titleColor];
}

- (NSFont *) titleFont
{
  return [[self cell] titleFont];
}

- (double) maxValue
{
  return [[self cell] maxValue];
}

- (double) minValue
{
  return [[self cell] minValue];
}

- (void) setMaxValue: (double)aDouble
{
  [[self cell] setMaxValue: aDouble];
}

- (void) setMinValue: (double)aDouble
{
  [[self cell] setMinValue: aDouble];
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  [[self cell] drawWithFrame: rect inView: self];
}

- (float)_floatValueForMousePoint: (NSPoint)point knobRect: (NSRect)knobRect
{
  NSSliderCell* theCell = [self cell];
  NSRect slotRect = [theCell trackRect];
  BOOL isVertical = [theCell isVertical];
  float minValue = [theCell minValue];
  float maxValue = [theCell maxValue];
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
      if ([self isFlipped])
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

- (void) trackKnob: (NSEvent*)theEvent knobRect: (NSRect)knobRect
{
  NSApplication *app = [NSApplication sharedApplication];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			  | NSLeftMouseDraggedMask | NSMouseMovedMask
			  | NSPeriodicMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  NSEventType eventType = [theEvent type];
  BOOL isContinuous = [self isContinuous];
  NSSliderCell* theCell = [self cell];
  float oldFloatValue = [theCell floatValue];
  id target = [theCell target];
  SEL action = [theCell action];

  [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  while (eventType != NSLeftMouseUp)
    {
      theEvent = [app nextEventMatchingMask: eventMask
				  untilDate: [NSDate distantFuture]
				     inMode: NSEventTrackingRunLoopMode
				    dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic)
	point = [self convertPoint: [theEvent locationInWindow]
			  fromView: nil];
      else
	{
	  if (point.x != knobRect.origin.x || point.y != knobRect.origin.y)
	    {
	      float floatValue = [self _floatValueForMousePoint: point
						       knobRect: knobRect];

	      if (floatValue != oldFloatValue)
		{
		  [theCell setFloatValue: floatValue];
		  [theCell drawWithFrame: [self bounds] inView: self];
		  [window flushWindow];
		  if (isContinuous)
		    [target performSelector: action withObject: self];
		  oldFloatValue = floatValue;
		}
	      knobRect.origin = point;
	    }
	}
    }
  // If the control is not continuous send the action at the end of the drag
  if (!isContinuous)
    [target performSelector: action withObject: self];
  [NSEvent stopPeriodicEvents];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [self convertPoint: [theEvent locationInWindow]fromView: nil];
  NSSliderCell* theCell = [self cell];
  NSRect rect;

  [self lockFocus];

  rect = [theCell knobRectFlipped: [self isFlipped]];
  if (![self mouse: location inRect: rect])
    {
      // Mouse is not on the knob, move the knob to the mouse position
      float floatValue = [self _floatValueForMousePoint: location
					       knobRect: rect];

      [theCell setFloatValue: floatValue];
      if ([self isContinuous])
	[[theCell target] performSelector: [theCell action]
			       withObject: self];
      [theCell drawWithFrame: [self bounds] inView: self];
      [window flushWindow];
    }

  [self trackKnob: theEvent knobRect: rect];
}

@end
