/* GSWheelColorPicker.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: Febuary 2001
   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: May 2002
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <math.h>

#ifndef PI
#define PI 3.141592653589793
#endif

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <AppKit/GSHbox.h>


@interface GSColorWheel : NSView
{
  float hue, saturation, brightness;

  id target;
  SEL action;
}

-(float) hue;
-(float) saturation;

-(void) setHue: (float)h saturation: (float)s brightness: (float)brightness;

-(void) setTarget: (id)t;
-(void) setAction: (SEL)a;

@end

@implementation GSColorWheel

-(void) setTarget: (id)t
{
  target = t;
}
-(void) setAction: (SEL)a
{
  action = a;
}

-(float) hue
{
  return hue;
}
-(float) saturation
{
  return saturation;
}

-(void) setHue: (float)h saturation: (float)s brightness: (float)b
{
  if (hue == h && saturation == s && brightness == b)
    return;
  hue = h;
  saturation = s;
  brightness = b;
  [self setNeedsDisplay: YES];
}

-(BOOL) isOpaque
{
  return YES;
}

-(void) drawRect: (NSRect)rect
{
  NSRect frame = [self bounds];
  float cx, cy, cr;
  float x, y;
  float r, a;
  float dx, dy;

  cx = (frame.origin.x + frame.size.width) / 2;
  cy = (frame.origin.y + frame.size.height) / 2;

  cr = frame.size.width;
  if (cr > frame.size.height)
    cr = frame.size.height;

  cr = cr / 2 - 2;

  rect.origin.x = floor(rect.origin.x);
  rect.origin.y = floor(rect.origin.y);
  rect.size.width = ceil(rect.size.width) + 1;
  rect.size.height = ceil(rect.size.height) + 1;

  [[NSColor windowBackgroundColor] set];
  NSRectFill(rect);

  for (y = rect.origin.y; y < rect.origin.y + rect.size.height; y++)
    {
      for (x = rect.origin.x; x < rect.origin.x + rect.size.width; x++)
	{
	  dx = x - cx;
	  dy = y - cy;

	  r = dx * dx + dy * dy;
	  r = sqrt(r);
	  r /= cr;
	  if (r > 1)
	    continue;

	  a = atan2(dy, dx);
	  a = a / 2.0 / PI;
	  if (a < 0)
	    a += 1;

	  PSsethsbcolor(a, r, brightness);
	  PSrectfill(x,y,1,1);
	}
    }

  a = hue * 2 * PI;
  r = saturation * cr;

  x = cos(a) * r + cx;
  y = sin(a) * r + cy;

  PSsetgray(0);
  PSrectstroke(x - 2, y - 2, 4, 4);
  PSsetgray(1);
  PSrectfill(x - 1, y - 1, 2, 2);
}


- (void) mouseDown: (NSEvent *)theEvent
{
  NSApplication *app = [NSApplication sharedApplication];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			  | NSLeftMouseDraggedMask | NSMouseMovedMask
			  | NSPeriodicMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow] 
			fromView: nil];
  NSEventType eventType = [theEvent type];
  NSDate *distantFuture = [NSDate distantFuture];

  float new_hue, new_saturation;
  float old_x, old_y;

  NSRect frame = [self bounds];
  float cx, cy, cr;
  float dx, dy;
  cx = (frame.origin.x + frame.size.width) / 2;
  cy = (frame.origin.y + frame.size.height) / 2;
  cr = frame.size.width;
  if (cr > frame.size.height)
    cr = frame.size.height;
  cr = cr / 2 - 2;


  [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  new_hue = hue;
  new_saturation = saturation;

  do
    {
      if (eventType != NSPeriodic)
	{
	  point = [self convertPoint: [theEvent locationInWindow]
			fromView: nil];

	  dx = point.x - cx;
	  dy = point.y - cy;

	  new_saturation = dx * dx + dy * dy;
	  new_saturation = sqrt(new_saturation);
	  new_saturation /= cr;
	  if (new_saturation > 1)
	    new_saturation = 1;

	  new_hue = atan2(dy, dx);
	  new_hue = new_hue / 2.0 / PI;
	  if (new_hue < 0)
	    new_hue += 1;
	}
      else
	{
	  if (new_hue != hue || new_saturation != saturation)
	    {
	      old_x = cos(hue * 2 * PI) * saturation * cr + cx;
	      old_y = sin(hue * 2 * PI) * saturation * cr + cy;

	      hue = new_hue;
	      saturation = new_saturation;

	      [self lockFocus];
	      [self drawRect: NSMakeRect(old_x - 3, old_y - 3, 6, 6)];
	      [self drawRect: NSMakeRect(point.x - 3, point.y - 3, 6, 6)];
	      [self unlockFocus];
	      [_window flushWindow];

	      if (target)
		[target performSelector: action withObject: self];
	    }
	}

      theEvent = [app nextEventMatchingMask: eventMask
				  untilDate: distantFuture
				     inMode: NSEventTrackingRunLoopMode
				    dequeue: YES];
      eventType = [theEvent type];
    } while (eventType != NSLeftMouseUp);
  [NSEvent stopPeriodicEvents];
}

@end


#define KNOB_WIDTH 6

@interface GSColorWheelSliderCell : NSSliderCell
{
  float values[2];
}
-(void) _setColorWheelSliderCellValues: (float)a : (float)b;
@end

@implementation GSColorWheelSliderCell : NSSliderCell

-(void) _setColorWheelSliderCellValues: (float)a : (float)b
{
  values[0] = a;
  values[1] = b;
}

- (NSRect) knobRectFlipped: (BOOL)flipped
{
  NSPoint	origin;
  float		floatValue = [self floatValue];

  if (_isVertical && flipped)
    {
      floatValue = _maxValue + _minValue - floatValue;
    }

  floatValue = (floatValue - _minValue) / (_maxValue - _minValue);

  origin = _trackRect.origin;
  if (_isVertical == YES)
    {
      origin.y += (_trackRect.size.height - KNOB_WIDTH) * floatValue;
      return NSMakeRect (origin.x, origin.y, _trackRect.size.width, KNOB_WIDTH);
    }
  else
    {
      origin.x += (_trackRect.size.width - KNOB_WIDTH) * floatValue;
      return NSMakeRect (origin.x, origin.y, KNOB_WIDTH, _trackRect.size.height);
    }
}

- (void) drawKnob: (NSRect)knobRect
{
  [[NSColor blackColor] set];
  NSDrawButton(knobRect, knobRect);
}

-(void) drawBarInside: (NSRect)r  flipped: (BOOL)flipped
{
  float i, f;
  for (i = r.origin.y; i < r.origin.y + r.size.height; i += 1)
    {
      f = (0.5 + i) / r.size.height;
      PSsethsbcolor(values[0], values[1], f);
      if (i + 1 < r.origin.y + r.size.height)
	PSrectfill(r.origin.x, i, r.size.width, 1);
      else
	PSrectfill(r.origin.x, i, r.size.width, r.size.height - i);
    }
}

-(void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  _isVertical = (cellFrame.size.height > cellFrame.size.width);
  cellFrame = [self drawingRectForBounds: cellFrame];

  cellFrame.origin.x -= 1;
  cellFrame.origin.y -= 1;
  cellFrame.size.width += 2;
  cellFrame.size.height += 2;

  [controlView lockFocus];

  _trackRect = cellFrame;

  [self drawBarInside: cellFrame flipped: [controlView isFlipped]];

  [self drawKnob];
  [controlView unlockFocus];
}

- (float) knobThickness
{
  return KNOB_WIDTH;
}

@end


@interface GSWheelColorPicker: NSColorPicker <NSColorPickingCustom>
{
  GSHbox *baseView;
  NSSlider *brightnessSlider;
  GSColorWheel *wheel;
}

- (void) sliderChanged: (id) sender;
- (void) loadViews;

@end

@implementation GSWheelColorPicker

- (void) dealloc
{
  RELEASE(baseView);
  [super dealloc];
}

- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel
{
  if (aMask & NSColorPanelWheelModeMask)
    return [super initWithPickerMask: aMask
		  colorPanel: colorPanel];
  RELEASE(self);
  return nil;
}

- (int)currentMode
{
  return NSWheelModeColorPanel;
}

- (BOOL)supportsMode:(int)mode
{
  return mode == NSWheelModeColorPanel;
}

- (NSView *)provideNewView:(BOOL)initialRequest
{
  if (initialRequest)
    {
      [self loadViews];
    }
  return baseView;
}

- (void)setColor:(NSColor *)color
{
  float hue, saturation, brightness, alpha;
  NSColor *c;

  c = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  [c getHue: &hue saturation: &saturation brightness: &brightness alpha: &alpha];

  [(GSColorWheelSliderCell *)[brightnessSlider cell]
  	_setColorWheelSliderCellValues: hue : saturation];
  [brightnessSlider setNeedsDisplay: YES];
  [brightnessSlider setFloatValue: brightness];
  [wheel setHue: hue saturation: saturation brightness: brightness];
}

- (void) loadViews
{
  NSSlider *s;

  baseView = [[GSHbox alloc] init];
  [baseView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  wheel = [[GSColorWheel alloc] init];
  [wheel setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [wheel setTarget: self];
  [wheel setAction: @selector(sliderChanged:)];
  [baseView addView: wheel];

  s = brightnessSlider = [[NSSlider alloc] initWithFrame: NSMakeRect(0,0,16,0)];
  [s setAutoresizingMask: NSViewHeightSizable];
  [s setCell: [[GSColorWheelSliderCell alloc] init]];
  [s setContinuous: NO];
  [s setMinValue: 0.0];
  [s setMaxValue: 1.0];
  [s setTarget: self];
  [s setAction: @selector(sliderChanged:)];
  [[s cell] setBezeled: YES];

  [baseView addView: brightnessSlider enablingXResizing: NO];
}

- (void) sliderChanged: (id) sender
{
  float brightness = [brightnessSlider floatValue];
  float hue = [wheel hue];
  float saturation = [wheel saturation];
  float alpha = [_colorPanel alpha];
  NSColor *c;

  [(GSColorWheelSliderCell *)[brightnessSlider cell]
  	_setColorWheelSliderCellValues: hue : saturation];
  [brightnessSlider setNeedsDisplay: YES];

  c = [NSColor colorWithCalibratedHue: hue
			saturation: saturation
			brightness: brightness
			alpha: alpha];
  [_colorPanel setColor: c];
}

@end

