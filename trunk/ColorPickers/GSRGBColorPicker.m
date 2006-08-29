/* GSRGBColorPicker.m

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: December 2000
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

#include "GSRGBColorPicker.h"

@implementation GSRGBColorPicker

- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel
{
  if (aMask & NSColorPanelRGBModeMask)
    {
      NSBundle *b;
      self = [super initWithPickerMask: aMask
		colorPanel: colorPanel];
      if (!self)
	return nil;

      b = [NSBundle bundleForClass: [self class]];

      numFields = 3;
      currentMode = NSColorPanelRGBModeMask;
      maxValue = 255;

      r_names[0] = NSLocalizedStringFromTableInBundle(@"Red",@"StandardPicker",b,@"");
      r_names[1] = NSLocalizedStringFromTableInBundle(@"Green",@"StandardPicker",b,@"");
      r_names[2] = NSLocalizedStringFromTableInBundle(@"Blue",@"StandardPicker",b,@"");
      names = r_names;

      sliders = r_sliders;
      fields = r_fields;
      values = r_values;
      return self;
    }
  RELEASE(self);
  return nil;
}

- (void)setColor:(NSColor *)color
{
  float red, green, blue, alpha;
  NSColor *c;

  if (updating)
    return;
  updating = YES;

  c = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  [c getRed: &red green: &green blue: &blue alpha: &alpha];

  values[0] = red * 255;
  values[1] = green * 255;
  values[2] = blue * 255;
  [self _valuesChanged];

  updating = NO;
}

-(void) _setColorFromValues
{
  float red = values[0] / 255;
  float green = values[1] / 255;
  float blue  = values[2] / 255;
  float alpha = [_colorPanel alpha];
  NSColor *c = [NSColor colorWithCalibratedRed: red
			green: green
			blue: blue
			alpha: alpha];
  [_colorPanel setColor: c];
}


- (void) loadViews
{
  [super loadViews];
  [sliders[0] setMaxValue: 255];
  [sliders[1] setMaxValue: 255];
  [sliders[2] setMaxValue: 255];
  [(GSColorSliderCell *)[sliders[0] cell] _setColorSliderCellMode: 1];
  [(GSColorSliderCell *)[sliders[1] cell] _setColorSliderCellMode: 2];
  [(GSColorSliderCell *)[sliders[2] cell] _setColorSliderCellMode: 3];
}

@end

