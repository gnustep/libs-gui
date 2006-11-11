/** <title>NSSliderCell</title>

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
  
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

#include <math.h>                  // (float)rintf(float x)
#include "config.h"
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSControl.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSSliderCell.h"
#include "AppKit/NSTextFieldCell.h"
#include "AppKit/NSWindow.h"

DEFINE_RINT_IF_MISSING

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

  <p>
  An NSSliderCell controls the behaviour and appearance of an
  associated NSSlider, or a single slider in an NSMatrix.  Tick marks
  are defined in the official standard, but are not implemented in
  GNUstep.
  </p>
  <p> 
  An NSSliderCell can be customized through its
  <code>set...</code> methods.  If these do not provide enough
  customization, a subclass can be created, which overrides any of the
  follwing methods: <code>knobRectFlipped:</code>,
  <code>drawBarInside:flipped:</code>, <code>drawKnob:</code>, or
  <code>prefersTrackingUntilMouseUp</code>.
  </p>
  </unit> 
*/
@implementation NSSliderCell

+ (void) initialize
{
  if (self == [NSSliderCell class])
    {
      /* Set the class version to 2, as tick information is now 
	 stored in the encoding */
      [self setVersion: 2];
    }
}

- (id) init
{
  self = [self initImageCell: nil];
  _altIncrementValue = -1;
  _isVertical = -1;
  _minValue = 0;
  _maxValue = 1;
  _cell.is_bordered = YES;
  _cell.is_bezeled = YES;

  _knobCell = [NSCell new];
  _titleCell = [NSTextFieldCell new];
  [_titleCell setTextColor: [NSColor controlTextColor]];
  [_titleCell setStringValue: @""];
  [_titleCell setAlignment: NSCenterTextAlignment];

  return self;
}

- (void) dealloc
{
  RELEASE(_titleCell);
  RELEASE(_knobCell);
  [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
  NSSliderCell *cpy = [super copyWithZone:zone];

  /* since NSCells -copyWithZone calls NSCopyObject */
  RETAIN(_titleCell);
  RETAIN(_knobCell);
  return cpy;
}

- (BOOL) isFlipped
{
  return YES;
}

/** <p>Draws the slider's track, not including the bezel, in <var>aRect</var>
  <var>flipped</var> indicates whether the control view has a flipped 
   coordinate system.</p>

  <p>Do not call this method directly, it is provided for subclassing
  only.</p> */
- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped
{
  [[NSColor scrollBarColor] set];
  NSRectFill(rect);
}

/**<p>Returns the rect in which to draw the knob, based on the
  coordinate system of the NSSlider or NSMatrix this NSSliderCell is
  associated with.  <var>flipped</var> indicates whether or not that
  coordinate system is flipped, which can be determined by sending the
  <code>isFlipped</code> message to the associated NSSlider or
  NSMatrix.</p>

  <p>Do not call this method directly.  It is included for subclassing
  only.</p> */
- (NSRect) knobRectFlipped: (BOOL)flipped
{
  NSImage	*image = [_knobCell image];
  NSSize	size;
  NSPoint	origin;
  float		floatValue = [self floatValue];

  if (_isVertical && flipped)
    {
      floatValue = _maxValue + _minValue - floatValue;
    }

  floatValue = (floatValue - _minValue) / (_maxValue - _minValue);

  if (image != nil)
    {
      size = [image size];
    }
  else
    {
      size = NSZeroSize;
    }

  if (_isVertical == YES)
    {
      origin = _trackRect.origin;
      origin.y += (_trackRect.size.height - size.height) * floatValue;
    }
  else
    {
      origin = _trackRect.origin;
      origin.x += (_trackRect.size.width - size.width) * floatValue;
    }

  return NSMakeRect (origin.x, origin.y, size.width, size.height); 
}

/** <p>Calculates the rect in which to draw the knob, then calls
  <code>drawKnob:</code> Before calling this method, a
  <code>lockFocus</code> message must be sent to the cell's control
  view.</p>

  <p>When subclassing NSSliderCell, do not override this method.
  Override <code>drawKnob:</code> instead.</p> <p>See Also: -drawKnob:</p>
*/
- (void) drawKnob
{
  [self drawKnob: [self knobRectFlipped: [_control_view isFlipped]]];
}

/**<p>Draws the knob in <var>knobRect</var>.  Before calling this
  method, a <code>lockFocus</code> message must be sent to the cell's
  control view.</p>

  <p>Do not call this method directly.  It is included for subclassing
  only.</p> <p>See Also: -drawKnob</p>
*/
- (void) drawKnob: (NSRect)knobRect
{
  NSColor* knobBackgroundColor = [NSColor controlBackgroundColor];
  [knobBackgroundColor set];
  NSRectFill (knobRect);
  
  [_knobCell drawInteriorWithFrame: knobRect inView: _control_view];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL		vertical = (cellFrame.size.height > cellFrame.size.width);
  NSImage	*image;
  NSSize	size;

  cellFrame = [self drawingRectForBounds: cellFrame];

  if (vertical != _isVertical)
    {
      if (vertical == YES)
	{
	  image = [NSImage imageNamed: @"common_SliderVert"];
	  if (image != nil)
	    {
	      size = [image size];
	      [image setScalesWhenResized: YES];
	      [image setSize: NSMakeSize(cellFrame.size.width, size.height)];
	    }
	}
      else
	{
	  image = [NSImage imageNamed: @"common_SliderHoriz"];
	  if (image != nil)
	    {
	      size = [image size];
	      [image setScalesWhenResized: YES];
	      [image setSize: NSMakeSize(size.width, cellFrame.size.height)];
	    }
	}
      [_knobCell setImage: image];
    }
  _isVertical = vertical;

  _trackRect = cellFrame;

  [self drawBarInside: cellFrame flipped: [controlView isFlipped]];

  /* Draw title - Uhmmm - shouldn't this better go into
     drawBarInside:flipped: ? */
  if (_isVertical == NO)
    {
      [_titleCell drawInteriorWithFrame: cellFrame inView: controlView];
    }

  [self drawKnob];
}

- (BOOL) isOpaque
{
  return YES;
}

/**<p> Returns the thickness of the slider's knob.  This value is in
  pixels, and is the size of the knob along the slider's track.</p>
  <p>See Also: -setKnobThickness:</p>
*/
- (float) knobThickness
{
  NSImage *image = [_knobCell image];
  NSSize size;

  if (image != nil)
    {
      size = [image size];
    }
  else 
    {
	return 0;
    }

  return _isVertical ? size.height : size.width;
}

/**<p>Sets the thickness of the knob to <var>thickness</var>, in pixels.
  This value sets the amount of space which the knob takes up in the
  slider's track.</p><p>See Also: -knobThickness</p> 
 */
- (void) setKnobThickness: (float)thickness
{
  NSImage *image = [_knobCell image];
  NSSize size;

  if (image != nil)
    {
      size = [image size];
    }
  else 
    {
      return;
    }

  if (_isVertical == YES)
    size.height = thickness;
  else
    size.width = thickness;

  [image setSize: size];

  if ((_control_view != nil) &&  
      ([_control_view isKindOfClass: [NSControl class]]))
    {
      [(NSControl*)_control_view updateCell: self];
    }
}

/**<p> Sets the value by which the slider will be be incremented when with the
    ALT key down to <var>increment</var>.</p>
    <p>See Also: -altIncrementValue</p> 
*/
- (void) setAltIncrementValue: (double)increment
{
  _altIncrementValue = increment;
}

/**<p> Sets the minimum value that the sliders represents to
   <var>maxValue</var>.</p><p>See Also: -minValue</p>
*/
- (void) setMinValue: (double)aDouble
{
  _minValue = aDouble;
}

/** <p>Sets the maximum value that the sliders represents to 
    <var>maxValue</var>.</p><p>See Also: -maxValue</p>
*/
- (void) setMaxValue: (double)aDouble
{
  _maxValue = aDouble;
}

/**<p>Returns the cell used to draw the title.</p>
   <p>See Also: -setTitleCell:</p> */
- (id) titleCell
{
  return _titleCell;
}

/**<p>Returns the colour used to draw the title.</p>
   <p>See Also: -setTitleColor:</p> 
*/
- (NSColor*) titleColor
{
  return [_titleCell textColor];
}

/**<p>Returns the font used to draw the title.</p>
   <p>See Also: -setTitleFont:</p>
*/
- (NSFont*) titleFont
{
  return [_titleCell font];
}

/**<p>Sets the title of the slider to <var>barTitle</var>.  This title is
  displayed on the slider's track, behind the knob.</p>
  <p>See Also: -title</p>*/
- (void) setTitle: (NSString*)title
{
  [_titleCell setStringValue: title];
}

/**<p>Returns the title of the slider. This title is
  displayed on the slider's track, behind the knob.</p>
  <p>See Also: -setTitle:</p>
*/
- (NSString*) title
{
  return [_titleCell stringValue];
}

/**<p>Sets the cell used to draw the title to <var>titleCell</var>.</p>
   <p>See Also: -titleCell</p>*/
- (void) setTitleCell: (NSCell*)aCell
{
  ASSIGN(_titleCell, aCell);
}

/**<p>Sets the colour with which the title will be drawn to <var>color</var>.
   </p><p>See Also: -titleColor</p>
*/
- (void) setTitleColor: (NSColor*)color
{
  [_titleCell setTextColor: color];
}

/**<p> Sets the font with which the title will be drawm to <var>font</var>.
 </p><p>See Also: -titleFont</p>
*/
- (void) setTitleFont: (NSFont*)font
{
  [_titleCell setFont: font];
}

/**Returns whether or not the slider is vertical.  If, for some
  reason, this cannot be determined, for such reasons as the slider is
  not yet displayed, this method returns -1.  Generally, a slider is
  considered vertical if its height is greater than its width. 
*/
- (int) isVertical
{
  return _isVertical;
}

/**<p>Returns the value by which the slider is incremented when the user
    holds down the ALT key.</p><p>See Also: -setAltIncrementValue:</p>  
*/
- (double) altIncrementValue
{
  return _altIncrementValue;
}

/** 
  <p>The default implementation returns <code>YES</code>, so that the
  slider continues to track the user's movement even if the cursor
  leaves the slider's track.</p>

  <p>Do not call this method directly.  Override it in subclasses
  where the tracking behaviour needs to be different.</p>
 */
+ (BOOL) prefersTrackingUntilMouseUp
{
  return YES;
}

/** Returns the rect of the track, minus the bezel. */
- (NSRect) trackRect
{
  return _trackRect;
}

/** <p>Returns the minimum value that the slider represents.</p>
    <p>See Also: -setMinValue:</p>
*/
- (double) minValue
{
  return _minValue;
}

/**<p>Returns the maximum value that the slider represents.</p>
   <p>See Also: -setMaxValue:</p>
*/
- (double) maxValue
{
  return _maxValue;
}

- (float) floatValue
{
  float	aFloat = [super floatValue];

  if (aFloat < _minValue)
    return _minValue;
  else if (aFloat > _maxValue)
    return _maxValue;
  return aFloat;
}

// ticks
- (BOOL) allowsTickMarkValuesOnly
{
  return _allowsTickMarkValuesOnly;
}

- (double) closestTickMarkValueToValue: (double)aValue
{
  double f;

  if (_numberOfTickMarks == 0)
    return aValue;

  if (aValue < _minValue)
    {
      aValue = _minValue;
    }
  else if (aValue > _maxValue)
    {
      aValue = _maxValue; 
    }

  f = ((aValue - _minValue)  * _numberOfTickMarks) / (_maxValue - _minValue);
  f = ((rint(f) * (_maxValue - _minValue)) / _numberOfTickMarks) + _minValue;

  return f;
}

- (int) indexOfTickMarkAtPoint: (NSPoint)point
{
  int i;

  for (i = 0; i < _numberOfTickMarks; i++)
    {
      if (NSPointInRect(point, [self rectOfTickMarkAtIndex: i])) 
        {
	  return i;
	}
    }

  return NSNotFound;
}

- (int) numberOfTickMarks
{
  return _numberOfTickMarks;
}

- (NSRect) rectOfTickMarkAtIndex: (int)index
{
  NSRect rect = _trackRect;
  float d;

  if ((index < 0) || (index >= _numberOfTickMarks))
    {
      [NSException raise: NSRangeException
		   format: @"Index of tick mark out of bound."];
    }

  if (_isVertical)
    {
      d = NSHeight(rect) / _numberOfTickMarks;
      rect.size.height = d;
      rect.origin.y += d * index;
    }
  else
    {
      d = NSWidth(rect) / _numberOfTickMarks;
      rect.size.width = d;
      rect.origin.x += d * index;
    }

  return rect;
}

- (void) setAllowsTickMarkValuesOnly: (BOOL)flag
{
  _allowsTickMarkValuesOnly = flag;
}

- (void) setNumberOfTickMarks: (int)numberOfTickMarks
{
  _numberOfTickMarks = numberOfTickMarks;
  if ((_control_view != nil) &&  
      ([_control_view isKindOfClass: [NSControl class]]))
    {
      [(NSControl*)_control_view updateCell: self];
    }
}

- (void) setTickMarkPosition: (NSTickMarkPosition)position
{
  _tickMarkPosition = position;
  if ((_control_view != nil) &&  
      ([_control_view isKindOfClass: [NSControl class]]))
    {
      [(NSControl*)_control_view updateCell: self];
    }
}

- (NSTickMarkPosition) tickMarkPosition
{
  return _tickMarkPosition;
}

- (double) tickMarkValueAtIndex: (int)index
{
  if (index >= _numberOfTickMarks)
    return _maxValue;
  if (index <= 0)
    return _minValue;

  return _minValue + index * (_maxValue - _minValue) / _numberOfTickMarks;
}

- (BOOL) trackMouse: (NSEvent*)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView*)controlView
       untilMouseUp: (BOOL)flag
{
  float delay;
  float interval;
  id target = [self target];
  SEL action = [self action];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
                           | NSLeftMouseDraggedMask | NSMouseMovedMask;
  NSEventType eventType = [theEvent type];
  BOOL isContinuous = [self isContinuous];
  float oldFloatValue = [self floatValue];
  NSRect slotRect = [self trackRect];
  BOOL isVertical = [self isVertical];
  float minValue = [self minValue];
  float maxValue = [self maxValue];
  BOOL isFlipped = [controlView isFlipped];
  NSPoint location = [theEvent locationInWindow];
  NSPoint point = [controlView convertPoint: location fromView: nil];
  NSRect knobRect = [self knobRectFlipped: isFlipped];

  _mouse_down_flags = [theEvent modifierFlags];
  if (![self isEnabled])
    {
      return NO;
    }

  if (![controlView mouse: point inRect: knobRect])
    {
      // Mouse is not on the knob, move the knob to the mouse position
      float floatValue;

      floatValue = _floatValueForMousePoint(point, knobRect, 
					    slotRect, isVertical, 
					    minValue, maxValue,
					    self, isFlipped); 
      [self setFloatValue: floatValue];
      if (isContinuous)
        {
	  [(NSControl*)controlView sendAction: action to: target];
	}
    }
      
  if (isContinuous)
    {
      [self getPeriodicDelay: &delay interval: &interval];
      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod: interval];
      eventMask |= NSPeriodicMask;
    }

  while (eventType != NSLeftMouseUp)
    {
      theEvent = [NSApp nextEventMatchingMask: eventMask
			untilDate: nil
			inMode: NSEventTrackingRunLoopMode
			dequeue: YES];
      eventType = [theEvent type];

      if (eventType == NSPeriodic)
        {
	  NSWindow *w = [controlView window];

	  location = [w mouseLocationOutsideOfEventStream];
	}
      else
        {
	  location = [theEvent locationInWindow];
	}
      point = [controlView convertPoint: location fromView: nil];

      if (point.x != knobRect.origin.x || point.y != knobRect.origin.y)
        {
	  float floatValue;

	  floatValue = _floatValueForMousePoint(point, knobRect,
						slotRect, isVertical, 
						minValue, maxValue, 
						self, isFlipped); 
	  if (floatValue != oldFloatValue)
	    {
	      if (_allowsTickMarkValuesOnly)
		{
		  floatValue = [self closestTickMarkValueToValue:floatValue]; 
		}

	      [self setFloatValue: floatValue];
	      if (isContinuous)
	        {
		  [(NSControl*)controlView sendAction: action to: target];
		}
	      oldFloatValue = floatValue;
	    }
	  knobRect.origin = point;
	}
    }

  // If the cell is not continuous send the action at the end of the drag
  if (!isContinuous)
    {
      [(NSControl*)controlView sendAction: action to: target];
    }
  else
    {
      [NSEvent stopPeriodicEvents];
    }

  return YES;
}

- (id) initWithCoder: (NSCoder*)decoder
{
  self = [super initWithCoder: decoder];
  if ([decoder allowsKeyedCoding])
    {
      _allowsTickMarkValuesOnly = [decoder decodeBoolForKey: @"NSAllowsTickMarkValuesOnly"];
      _numberOfTickMarks = [decoder decodeIntForKey: @"NSNumberOfTickMarks"];
      _tickMarkPosition = [decoder decodeIntForKey: @"NSTickMarkPosition"];
      _minValue = [decoder decodeFloatForKey: @"NSMinValue"];
      _maxValue = [decoder decodeFloatForKey: @"NSMaxValue"];
      _altIncrementValue = [decoder decodeFloatForKey: @"NSAltIncValue"];

      // do these here, since the Cocoa version of the class does not save these values...
      _knobCell = [NSCell new];
      _titleCell = [NSTextFieldCell new];
      [_titleCell setTextColor: [NSColor controlTextColor]];
      [_titleCell setStringValue: @""];
      [_titleCell setAlignment: NSCenterTextAlignment];

      // if it's from a nib, make it bordered and bezeled so it's more attractive, this
      // information is not in the nib.
      [self setBordered: YES];
      [self setBezeled: NO];

      _isVertical = -1;
    }
  else
    {
      [decoder decodeValuesOfObjCTypes: "fffi",
	       &_minValue, &_maxValue, &_altIncrementValue, &_isVertical];
      [decoder decodeValueOfObjCType: @encode(id) at: &_titleCell];
      [decoder decodeValueOfObjCType: @encode(id) at: &_knobCell];
      if ([decoder versionForClassName: @"NSSliderCell"] >= 2)
	{
	  [decoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsTickMarkValuesOnly];
	  [decoder decodeValueOfObjCType: @encode(int) at: &_numberOfTickMarks];
	  [decoder decodeValueOfObjCType: @encode(int) at: &_tickMarkPosition];
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool: _allowsTickMarkValuesOnly forKey: @"NSAllowsTickMarkValuesOnly"];
      [coder encodeInt: _numberOfTickMarks forKey: @"NSNumberOfTickMarks"];
      [coder encodeInt: _tickMarkPosition forKey: @"NSTickMarkPosition"];
      [coder encodeFloat: _minValue forKey: @"NSMinValue"];
      [coder encodeFloat: _maxValue forKey: @"NSMaxValue"];
      [coder encodeFloat: _altIncrementValue forKey: @"NSAltIncValue"];
      [coder encodeFloat: _minValue forKey: @"NSValue"]; // encoded for compatibility
    }
  else
    {
      [coder encodeValuesOfObjCTypes: "fffi",
	     &_minValue, &_maxValue, &_altIncrementValue, &_isVertical];
      [coder encodeValueOfObjCType: @encode(id) at: &_titleCell];
      [coder encodeValueOfObjCType: @encode(id) at: &_knobCell];
      // New for version 2
      [coder encodeValueOfObjCType: @encode(BOOL) at: &_allowsTickMarkValuesOnly];
      [coder encodeValueOfObjCType: @encode(int) at: &_numberOfTickMarks];
      [coder encodeValueOfObjCType: @encode(int) at: &_tickMarkPosition];
    }
}
  
@end
