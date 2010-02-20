/* GSWheelColorPicker.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: Febuary 2001
   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: May 2002
   
   This file is part of GNUstep.
   
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

#ifndef PI
#define PI 3.141592653589793
#endif

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSHbox.h>
#include "GSStandardColorPicker.h"


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

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (BOOL) acceptsFirstResponder
{
  return NO;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			  | NSLeftMouseDraggedMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow] 
			fromView: nil];
  NSEventType eventType = [theEvent type];
  NSEvent *presentEvent;

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

  new_hue = hue;
  new_saturation = saturation;

  do
    {
       /* Inner loop that gets and (quickly) handles all events that have
          already arrived. */
       while (theEvent && eventType != NSLeftMouseUp)
         {
           /* Note the event here. Don't do any expensive handling. */
	   presentEvent = theEvent;

           theEvent = [NSApp nextEventMatchingMask: eventMask
                         untilDate: [NSDate distantPast] /* Only get events that have arrived */
                         inMode: NSEventTrackingRunLoopMode
                         dequeue: YES];
           eventType = [theEvent type];
         }
                           
       /* No more events right now. Do expensive handling, like drawing, 
        * here. 
	*/
       point = [self convertPoint: [presentEvent locationInWindow]
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

  [(GSColorSliderCell *)[brightnessSlider cell]
    _setColorSliderCellValues: hue : saturation : brightness];
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
  [s setCell: [[GSColorSliderCell alloc] init]];
  [(GSColorSliderCell *)[s cell] _setColorSliderCellMode: 10];
  [s setContinuous: YES];
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

  [(GSColorSliderCell *)[brightnessSlider cell]
    _setColorSliderCellValues: hue : saturation : brightness];
  [brightnessSlider setNeedsDisplay: YES];

  c = [NSColor colorWithCalibratedHue: hue
			saturation: saturation
			brightness: brightness
			alpha: alpha];
  [_colorPanel setColor: c];
}

@end

