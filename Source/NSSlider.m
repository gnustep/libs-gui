/** <title>NSSlider</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
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

#include "AppKit/NSEvent.h"
#include "AppKit/NSSlider.h"
#include "AppKit/NSSliderCell.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSApplication.h"

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


/**
  <unit>
  <heading>Class Description</heading>
  
  <p>An NSSlider displays, and allows control of, some value in the
  application.  It represents a continuous stream of values of type
  <code>float</code>, which can be retrieved by the method
  <code>floatValue</code> and set by the method
  <code>setFloatValue:</code>.</p>

  <p>This control is a continuous control.  It sends its action
  message as long as the user is manipulating it.  This can be changed
  by passing <code>NO</code> to the <code>setContinuous:</code>
  message of a given NSSlider.</p>

  <p>Although methods for adding and managing a title are provided,
  the slider's knob can cover this title, so it is recommended that a
  label be added near the slider, for identification.</p>

  <p>As with many controls, NSSlider relies on its cell counterpart,
  NSSliderCell.  For more information, please see the specification
  for NSSliderCell.</p>

  <p>Use of an NSSlider to do the role of an NSScroller is not
  recommended.  A scroller is intended to represent the visible
  portion of a view, whereas a slider is intended to represent some
  value.</p>

  </unit>
*/
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

/** 
  Returns the value by which the slider will be incremented if the
  user holds down the ALT key. */
- (double) altIncrementValue
{
  return [_cell altIncrementValue];
}

/**
  Returns the image drawn in the slider's track.  Returns
  <code>nil</code> if this has not been set.  */
- (NSImage *) image
{
  return [_cell image];
}

/**
  Returns whether or not the slider is vertical.  If, for some reason,
  this cannot be determined, for such reasons as the slider is not yet
  displayed, this method returns -1.  Generally, a slider is
  considered vertical if its height is greater than its width.  */
- (int) isVertical
{
  return [_cell isVertical];
}

/**
  Returns the thickness of the slider's knob.  This value is in
  pixels, and is the size of the knob along the slider's track.  */
- (float) knobThickness
{
  return [_cell knobThickness];
}

/**
  Sets the value by which the slider will be incremented, when the
  ALT key is held down, to <var>increment</var>. */
- (void) setAltIncrementValue: (double)increment
{
  [_cell setAltIncrementValue: increment];
}

/** Sets the image to be displayed in the slider's track to <var>barImage</var>.
 */
- (void) setImage: (NSImage *)backgroundImage
{
  [_cell setImage: backgroundImage];
}

/** 
  Sets the thickness of the knob to <var>thickness</var>, in pixels.
  This value sets the amount of space which the knob takes up in the
  slider's track.  */
- (void) setKnobThickness: (float)aFloat
{
  [_cell setKnobThickness: aFloat];
}

/**
  Sets the title of the slider to <var>barTitle</var>.  This title is displayed 
  on the slider's track, behind the knob.
*/
- (void) setTitle: (NSString *)aString
{
  [_cell setTitle: aString];
}

/** Sets the cell used to draw the title to <var>titleCell</var>. */
- (void) setTitleCell: (NSCell *)aCell
{
  [_cell setTitleCell: aCell];
}

/** Sets the colour with which the title will be drawn to <var>color</var>. */
- (void) setTitleColor: (NSColor *)aColor
{
  [_cell setTitleColor: aColor];
}

/** Sets the font with which the title will be drawm to <var>font</var>. */
- (void) setTitleFont: (NSFont *)fontObject
{
  [_cell setTitleFont: fontObject];
}

/** Returns the title of the slider as an <code>NSString</code>. */
- (NSString *) title
{
  return [_cell title];
}

/** Returns the cell used to draw the title. */
- (id) titleCell
{
  return [_cell titleCell];
}

/** Returns the colour used to draw the title. */
- (NSColor *) titleColor
{
  return [_cell titleColor];
}

/** Returns the font used to draw the title. */
- (NSFont *) titleFont
{
  return [_cell titleFont];
}

/** Returns the maximum value that the slider represents. */
- (double) maxValue
{
  return [_cell maxValue];
}

/** Returns the minimum value that the slider represents. */
- (double) minValue
{
  return [_cell minValue];
}

/**
   Sets the maximum value that the sliders represents to <var>maxValue</var>. */
- (void) setMaxValue: (double)aDouble
{
  [_cell setMaxValue: aDouble];
}

/** Sets the minimum value that the slider represents to <var>minValue</var>. */
- (void) setMinValue: (double)aDouble
{
  [_cell setMinValue: aDouble];
}

/** 
  Returns <code>YES</code> by default.  This will allow the first
  click sent to the slider, when in an inactive window, to both bring
  the window into focus and manipulate the slider. */
- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

// ticks
- (BOOL) allowsTickMarkValuesOnly
{
  return [_cell allowsTickMarkValuesOnly];
}

- (double) closestTickMarkValueToValue: (double)aValue
{
  return [_cell closestTickMarkValueToValue: aValue];
}

- (int) indexOfTickMarkAtPoint: (NSPoint)point
{
  return [_cell indexOfTickMarkAtPoint: point];
}

- (int) numberOfTickMarks
{
  return [_cell numberOfTickMarks];
}

- (NSRect) rectOfTickMarkAtIndex: (int)index
{
  return [_cell rectOfTickMarkAtIndex: index];
}

- (void) setAllowsTickMarkValuesOnly: (BOOL)flag
{
  [_cell setAllowsTickMarkValuesOnly: flag];
}

- (void) setNumberOfTickMarks: (int)numberOfTickMarks
{
 [_cell setNumberOfTickMarks: numberOfTickMarks];
}

- (void) setTickMarkPosition: (NSTickMarkPosition)position
{
 [_cell setTickMarkPosition: position];
}

- (NSTickMarkPosition) tickMarkPosition
{
  return [_cell tickMarkPosition];
}

- (double) tickMarkValueAtIndex: (int)index
{
  return [_cell tickMarkValueAtIndex: index];
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

  [self lockFocus];

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
		      [self sendAction: action to: target];
		    }
		  oldFloatValue = floatValue;
		}
	      knobRect.origin = point;
	    }
	}
    }
  [self unlockFocus];
  // If the control is not continuous send the action at the end of the drag
  if (!isContinuous)
    {
      [self sendAction: action to: target];
    }
  [NSEvent stopPeriodicEvents];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  if ([_cell isEnabled])
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
	      [self sendAction: [_cell action] to: [_cell target]];
	    }
	  [self lockFocus];
	  [_cell drawWithFrame: _bounds inView: self];
	  [self unlockFocus];
	  [_window flushWindow];
	}
      
      [self trackKnob: theEvent knobRect: rect];
    }
}
@end
