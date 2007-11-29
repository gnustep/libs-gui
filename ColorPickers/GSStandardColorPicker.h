/* GSStandardColorPicker.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: Febuary 2001
   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: May 2002

   This file is part of GNUstep.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#ifndef GSStandardColorPicker_h
#define GSStandardColorPicker_h

@class GSTable,NSSlider,NSTextField;

@interface GSStandardCSColorPicker: NSColorPicker <NSColorPickingCustom>
{
  GSTable *baseView;;

  int numFields;
  int currentMode;

  NSString **names;
  NSSlider **sliders;
  NSTextField **fields;
  float *values;
  int maxValue;

  BOOL updating;
}

- (void) sliderChanged: (id) sender;
- (void) loadViews;


-(void) _valuesChanged;

/* subclasses should implement these and -init... */
-(void) _setColorFromValues;
-(void) setColor:(NSColor *)color;

@end

@interface GSColorSliderCell : NSSliderCell
{
  int mode;
  float values[3];
}
-(void) _setColorSliderCellMode: (int)m;
-(void) _setColorSliderCellValues: (float)a : (float)b : (float)c;
@end

#endif

