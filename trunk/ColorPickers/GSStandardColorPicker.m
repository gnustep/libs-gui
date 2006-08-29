/* GSStandardColorPicker.m

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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSVbox.h>
#include <GNUstepGUI/GSHbox.h>
#include "GSRGBColorPicker.h"
#include "GSHSBColorPicker.h"
#include "GSCMYKColorPicker.h"
#include "GSGrayColorPicker.h"

@interface GSStandardColorPicker: NSColorPicker <NSColorPickingCustom>
{
  GSTable *baseView;
  NSBox *pickerBox;
  NSButtonCell *imageCell;
  NSMatrix *pickerMatrix;
  NSMutableArray *pickers;
  id<NSColorPickingCustom, NSColorPickingDefault> currentPicker; 
}

- (void) loadViews;
- (void) _showNewPicker: (id) sender;

@end

@implementation GSStandardColorPicker

- (void) dealloc
{
  RELEASE(pickers);
  RELEASE(pickerBox);
  RELEASE(pickerMatrix);
  RELEASE(baseView);
  [super dealloc]; 
}

- (id)initWithPickerMask:(int)aMask
	      colorPanel:(NSColorPanel *)colorPanel
{
  if (aMask & (NSColorPanelRGBModeMask | NSColorPanelHSBModeMask | 
	       NSColorPanelCMYKModeMask | NSColorPanelGrayModeMask))
  {
    NSColorPicker *picker;

    pickers = [[NSMutableArray alloc] init];
    picker = [[GSGrayColorPicker alloc] initWithPickerMask: aMask
					colorPanel: colorPanel];
    if (picker != nil)
      {
	[pickers addObject: picker];
	RELEASE(picker);
      }
    picker = [[GSRGBColorPicker alloc] initWithPickerMask: aMask
				       colorPanel: colorPanel];
    if (picker != nil)
      {
	[pickers addObject: picker];
	RELEASE(picker);
      }
    picker = [[GSCMYKColorPicker alloc] initWithPickerMask: aMask
					colorPanel: colorPanel];
    if (picker != nil)
      {
	[pickers addObject: picker];
	RELEASE(picker);
      }
    picker = [[GSHSBColorPicker alloc] initWithPickerMask: aMask
				       colorPanel: colorPanel];
    if (picker != nil)
      {
	[pickers addObject: picker];
	RELEASE(picker);
      }

    currentPicker = [pickers lastObject];
    return [super initWithPickerMask: aMask
		  colorPanel: colorPanel];
  }
  RELEASE(self);
  return nil;
}

- (int)currentMode
{
  return [currentPicker currentMode];
}

- (void)setMode:(int)mode
{
  int i, count;

  if (mode == [self currentMode])
    return;

  count = [pickers count];
  for (i = 0; i < count; i++)
    {
      if ([[pickers objectAtIndex: i] supportsMode: mode])
        {
	  [pickerMatrix selectCellWithTag: i];
	  [self _showNewPicker: pickerMatrix];
	  [currentPicker setMode: mode];
	  break;
	}
    }
}

- (BOOL)supportsMode:(int)mode
{
  return ((mode == NSGrayModeColorPanel) ||
	  (mode == NSRGBModeColorPanel)  ||
	  (mode == NSCMYKModeColorPanel) ||
	  (mode == NSHSBModeColorPanel));
}

- (void)insertNewButtonImage:(NSImage *)newImage
			  in:(NSButtonCell *)newButtonCell
{
  // Store the image button cell
  imageCell = newButtonCell;
  [super insertNewButtonImage: newImage
	 in: newButtonCell];
}

- (NSView *)provideNewView:(BOOL)initialRequest
{
  if (initialRequest)
    {
      [self loadViews];
    }
  return baseView;
}

- (NSImage *)provideNewButtonImage
{
  return [currentPicker provideNewButtonImage];
}

- (void)setColor:(NSColor *)color
{
  [currentPicker setColor: color];
}

- (void) loadViews
{
  NSEnumerator *enumerator;
  id<NSColorPickingCustom, NSColorPickingDefault> picker;
  NSButtonCell *cell;
  NSMutableArray *cells = [NSMutableArray new];
  int i, count;

  // Initaliase all the sub pickers
  enumerator = [pickers objectEnumerator];

  while ((picker = [enumerator nextObject]) != nil)
    [picker provideNewView: YES];

  baseView = [[GSTable alloc] initWithNumberOfRows: 3 numberOfColumns: 1];
  [baseView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [baseView setYResizingEnabled: NO forRow: 1];
  [baseView setYResizingEnabled: NO forRow: 2];

  // Prototype cell for the matrix
  cell = [[NSButtonCell alloc] initImageCell: nil];
  [cell setButtonType: NSOnOffButton];
  [cell setBordered: YES];

  pickerMatrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0,0,0,0)
				   mode: NSRadioModeMatrix
				   prototype: cell
				   numberOfRows: 0
				   numberOfColumns: 0];
  RELEASE(cell);
  [pickerMatrix setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [pickerMatrix setIntercellSpacing: NSMakeSize(1, 0)];
  [pickerMatrix setAutosizesCells: YES];

  count = [pickers count];
  for (i = 0; i < count; i++)
    {
      cell = [[pickerMatrix prototype] copy];
      [cell setTag: i];
      picker = [pickers objectAtIndex: i];
      [picker insertNewButtonImage: [picker provideNewButtonImage] in: cell];
      [cells addObject: cell];
      RELEASE(cell);
    }

  [pickerMatrix addRowWithCells: cells];
  RELEASE(cells);
  [pickerMatrix setCellSize: NSMakeSize(1, 36)];
  [pickerMatrix setTarget: self];
  [pickerMatrix setAction: @selector(_showNewPicker:)];

  pickerBox = [[NSBox alloc] init];
  [pickerBox setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [baseView putView: pickerBox
	atRow: 0
	column: 0
	withMargins: 0];
  [pickerBox setTitlePosition: NSNoTitle];
  [pickerBox setBorderType: NSNoBorder];
  [pickerBox setContentView: [currentPicker provideNewView: NO]];

  [baseView putView: pickerMatrix
	atRow: 1
	column: 0
	withMargins: 0];

  {
    NSBox *b = [[NSBox alloc] initWithFrame: NSMakeRect(0,0,0,2)];
    [b setAutoresizingMask: NSViewWidthSizable];
    [b setTitlePosition: NSNoTitle];
    [b setBorderType: NSGrooveBorder];
    [baseView putView: b
	atRow: 2
	column: 0
	withMinXMargin: 0
	maxXMargin: 0
	minYMargin: 4
	maxYMargin: 0];
    DESTROY(b);
  }
}

- (void) _showNewPicker: (id) sender
{
  NSView *currentView = [currentPicker provideNewView: NO];

  //NSLog(@"Old View size %@", NSStringFromRect([currentView frame]));
  currentPicker = [pickers objectAtIndex: [sender selectedColumn]];
  [currentPicker setColor: [_colorPanel color]];
  //NSLog(@"Base View size %@", NSStringFromRect([baseView frame]));
/*  [baseView putView: [currentPicker provideNewView: NO]
	atRow: 0
	column: 0
	withMargins: 0];*/
  [pickerBox setContentView: [currentPicker provideNewView: NO]];
  currentView = [currentPicker provideNewView: NO];

  //NSLog(@"New View size %@", NSStringFromRect([currentView frame]));
  // Show the new image
  [imageCell setImage: [[sender selectedCell] image]];
}

@end


#include "GSStandardColorPicker.h"


#include <GNUstepGUI/GSVbox.h>
#include <GNUstepGUI/GSHbox.h>


#define KNOB_WIDTH 6

@implementation GSColorSliderCell : NSSliderCell

-(void) _setColorSliderCellMode: (int)m
{
  mode = m;
  switch (mode)
    {
      case 0:
      case 1:
      case 2:
      case 3:
      case 10:
	[_titleCell setTextColor: [NSColor whiteColor]];
	break;
      case 4:
      case 5:
      case 6:
      case 7:
	[_titleCell setTextColor: [NSColor blackColor]];
	break;
    }
  [_titleCell setAlignment: NSLeftTextAlignment];
}

-(void) _setColorSliderCellValues: (float)a : (float)b : (float)c
{
  values[0] = a;
  values[1] = b;
  values[2] = c;
  if (mode == 8 || mode == 9)
    {
      if (c>0.7)
	[_titleCell setTextColor: [NSColor blackColor]];
      else
	[_titleCell setTextColor: [NSColor whiteColor]];
    }
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
  for (i = r.origin.x; i < r.origin.x + r.size.width; i += 1)
    {
      f = (0.5 + i) / r.size.width;
      switch (mode)
	{
	case 0: PSsetgray(f); break;

	case 1: PSsetrgbcolor(f, 0, 0); break;
	case 2: PSsetrgbcolor(0, f, 0); break;
	case 3: PSsetrgbcolor(0, 0, f); break;

	case 4: PSsetcmykcolor(f, 0, 0, 0); break;
	case 5: PSsetcmykcolor(0, f, 0, 0); break;
	case 6: PSsetcmykcolor(0, 0, f, 0); break;
	case 7: PSsetcmykcolor(0, 0, 0, f); break;

	case  8: PSsethsbcolor(f, values[1], values[2]); break;
	case  9: PSsethsbcolor(values[0], f, values[2]); break;
	case 10: PSsethsbcolor(values[0], values[1], f); break;
	}
      if (i + 1 < r.origin.x + r.size.width)
	PSrectfill(i, r.origin.y, 1, r.size.height);
      else
	PSrectfill(i, r.origin.y, r.size.width - i, r.size.height);
    }

  if (_isVertical == NO)
    {
      [_titleCell drawInteriorWithFrame: r inView: _control_view];
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


@implementation GSStandardCSColorPicker

- (void) dealloc
{
  int i;
  for (i = 0; i < numFields; i++)
    {
      RELEASE(sliders[i]);
      RELEASE(fields[i]);
    }
  RELEASE(baseView);
  [super dealloc];
}

- (int)currentMode
{
  return currentMode;
}

- (BOOL)supportsMode:(int)mode
{
  return currentMode == NSRGBModeColorPanel;
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
  [self subclassResponsibility: _cmd];
}

- (void) loadViews
{
  int i;

  baseView = [[GSTable alloc] initWithNumberOfRows: numFields + 2 numberOfColumns: 2];
  /* keep a single resizable but empty row at the bottom so it sucks up any
  extra space in the box that contains us */
  for (i = 1; i < numFields + 2; i++)
    [baseView setYResizingEnabled: NO forRow: i];
  [baseView setXResizingEnabled: YES forColumn: 0];
  [baseView setXResizingEnabled: NO forColumn: 1];
  [baseView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  for (i = 0; i < numFields; i++)
    {
      NSSlider *s;
      s = sliders[i] = [[NSSlider alloc] initWithFrame: NSMakeRect(0, 0, 0, 16)];
      [s setCell: [[GSColorSliderCell alloc] init]];
      [s setContinuous: YES];
      [s setMinValue: 0.0];
      [s setTitle: names[i]];
      [s setTarget: self];
      [s setAction: @selector(sliderChanged:)];

      [[s cell] setBezeled: YES];
      [s setAutoresizingMask: NSViewWidthSizable];

      [baseView putView: s
	atRow: numFields - i
	column: 0
	withMinXMargin: 0
	maxXMargin: 0
	minYMargin: 0
	maxYMargin: i?6:2];
    }

  if (maxValue)
    {
      NSTextField *tv;
      GSHbox *hb=[[GSHbox alloc] init];

      tv=[[NSTextField alloc] init];
      [tv setStringValue: @"0"];
      [tv setEditable: 0];
      [tv setFont: [NSFont userFontOfSize: 10.0]];
      [tv setTextColor: [NSColor darkGrayColor]];
      [tv setDrawsBackground: NO];
      [tv setBordered: NO];
      [tv setSelectable: NO];
      [tv setBezeled: NO];
      [tv sizeToFit];
      [tv setAutoresizingMask: NSViewMaxXMargin];
      [hb addView: tv];
      DESTROY(tv);

      tv=[[NSTextField alloc] init];
      [tv setIntValue: maxValue];
      [tv setEditable: 0];
      [tv setFont: [NSFont userFontOfSize: 10.0]];
      [tv setTextColor: [NSColor darkGrayColor]];
      [tv setDrawsBackground: NO];
      [tv setBordered: NO];
      [tv setSelectable: NO];
      [tv setBezeled: NO];
      [tv sizeToFit];
      [tv setAutoresizingMask: NSViewMinXMargin];
      [hb addView: tv];
      DESTROY(tv);

      [hb setAutoresizingMask: NSViewWidthSizable];
      [baseView putView: hb
	atRow: numFields + 1
	column: 0
	withMargins: 0];
      DESTROY(hb);
    }
  else
    {
      NSTextField *tv;
      NSView *v;
      NSRect frame;

      tv=[[NSTextField alloc] init];
      [tv setStringValue: @"0"];
      [tv setEditable: 0];
      [tv setFont: [NSFont userFontOfSize: 10.0]];
      [tv setTextColor: [NSColor darkGrayColor]];
      [tv setDrawsBackground: NO];
      [tv setBordered: NO];
      [tv setSelectable: NO];
      [tv setBezeled: NO];
      [tv sizeToFit];
      frame=[tv frame];
      DESTROY(tv);
      v = [[NSView alloc] initWithFrame: frame];
      [baseView putView: v
	atRow: numFields + 1
	column: 0
	withMargins: 0];
      DESTROY(v);
    }

  for (i = 0; i < numFields; i++)
    {
      NSTextField *f;
      f = fields[i] = [[NSTextField alloc] init];
      [f setStringValue: @"255"]; /* just to get a good size */
      [f setFont: [NSFont userFontOfSize: 10.0]];
      [f sizeToFit];
      [f setFrameSize: NSMakeSize([f frame].size.width * 1.5, [f frame].size.height)];
      [f setDelegate: self];
      [baseView putView: f
	atRow: numFields - i
	column: 1
	withMinXMargin: 3
	maxXMargin: 0
	minYMargin: 0
	maxYMargin: 0];
    }
}

- (void) sliderChanged: (id) sender
{
  int i;

  if (updating)
    return;
  updating = YES;

  for (i = 0; i <numFields; i++)
    {
      values[i] = [sliders[i] floatValue];
      [fields[i] setIntValue: (int)values[i]];
    }

  [self _setColorFromValues];

  updating = NO;
}

-(void) controlTextDidChange: (NSNotification *)n
{
  int i;

  if (updating)
    return;
  updating = YES;

  for (i = 0; i <numFields; i++)
    {
      values[i] = [fields[i] floatValue];
      [sliders[i] setIntValue: (int)values[i]];
    }

  [self _setColorFromValues];

  updating = NO;
}

-(void) _valuesChanged
{
  int i;

  for (i = 0; i <numFields; i++)
    {
      [fields[i] setIntValue: (int)values[i]];
      [sliders[i] setIntValue: (int)values[i]];
    }
}

-(void) _setColorFromValues
{
  [self subclassResponsibility: _cmd];
}

@end

