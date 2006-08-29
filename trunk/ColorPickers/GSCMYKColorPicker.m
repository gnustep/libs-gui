/* GSCMYKColorPicker.m

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

#include "GSCMYKColorPicker.h"

@implementation GSCMYKColorPicker

- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel
{
  if (aMask & NSColorPanelCMYKModeMask)
    {
      NSBundle *b;

      self = [super initWithPickerMask: aMask
		colorPanel: colorPanel];
      if (!self)
	return nil;

      numFields = 4;
      currentMode = NSColorPanelCMYKModeMask;

      b = [NSBundle bundleForClass: [self class]];
      r_names[0] = NSLocalizedStringFromTableInBundle(@"Cyan",@"StandardPicker",b,@"");
      r_names[1] = NSLocalizedStringFromTableInBundle(@"Magenta",@"StandardPicker",b,@"");
      r_names[2] = NSLocalizedStringFromTableInBundle(@"Yellow",@"StandardPicker",b,@"");
      r_names[3] = NSLocalizedStringFromTableInBundle(@"Black",@"StandardPicker",b,@"");
      names = r_names;

      sliders = r_sliders;
      fields = r_fields;
      values = r_values;
      maxValue = 100;
      return self;
    }
  RELEASE(self);
  return nil;
}

- (void)setColor:(NSColor *)color
{
  float cyan, magenta, yellow, black, alpha;
  NSColor *c;

  if (updating)
    return;
  updating = YES;

  c = [color colorUsingColorSpaceName: NSDeviceCMYKColorSpace];
  [c getCyan: &cyan magenta: &magenta yellow: &yellow
	   black: &black alpha: &alpha];

  values[0] = cyan * 100;
  values[1] = magenta * 100;
  values[2] = yellow * 100;
  values[3] = black * 100;
  [self _valuesChanged];

  updating = NO;
}

-(void) _setColorFromValues
{
  float cyan = values[0] / 100;
  float magenta = values[1] / 100;
  float yellow  = values[2] / 100;
  float black  = values[3] / 100;
  float alpha = [_colorPanel alpha];
  NSColor *c = [NSColor colorWithDeviceCyan: cyan
			magenta: magenta
			yellow: yellow
			black: black
			alpha: alpha];
  [_colorPanel setColor: c];
}


- (void) loadViews
{
  [super loadViews];
  [sliders[0] setMaxValue: 100];
  [sliders[1] setMaxValue: 100];
  [sliders[2] setMaxValue: 100];
  [sliders[3] setMaxValue: 100];
  [(GSColorSliderCell *)[sliders[0] cell] _setColorSliderCellMode: 4];
  [(GSColorSliderCell *)[sliders[1] cell] _setColorSliderCellMode: 5];
  [(GSColorSliderCell *)[sliders[2] cell] _setColorSliderCellMode: 6];
  [(GSColorSliderCell *)[sliders[3] cell] _setColorSliderCellMode: 7];
}

@end

