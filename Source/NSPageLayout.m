/* 
   NSPageLayout.m

   Page setup panel

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: November 2000
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPageLayout.h>

NSPageLayout *shared_instance;

@interface NSPageLayout (Private)
- (id) _initWithoutGModel;

@end

@implementation NSPageLayout

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPageLayout class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSPageLayout Instance 
//
+ (NSPageLayout *)pageLayout
{
  if (shared_instance == nil)
    {
      shared_instance = [[NSPageLayout alloc] init];
    }
  else
    {
      [shared_instance _initDefaults];
    }
  return shared_instance;
}

//
// Instance methods
//
- (id) init
{
    self = [self _initWithoutGModel];
    [self _initDefaults];

    return self;
}

- (void) _initDefaults
{
  // use points as the default
  _old = 1.0;
  _new = 1.0;  
  [super _initDefaults];
}

//
// Running the Panel 
//
- (int)runModal
{
  return [self runModalWithPrintInfo: [NSPrintInfo sharedPrintInfo]];
}

- (int)runModalWithPrintInfo:(NSPrintInfo *)pInfo
{
  // store the print Info
  _printInfo = pInfo;

  // read the values of the print info
  [self readPrintInfo];

  [NSApp runModalForWindow: self];
  [self orderOut: self];

  return _result;
}

//
// Customizing the Panel 
//
- (NSView *)accessoryView
{
  return nil;
}

- (void)setAccessoryView:(NSView *)aView
{
}

//
// Updating the Panel's Display 
//
- (void)convertOldFactor:(float *)old
	       newFactor:(float *)new
{
  if (old)
    *old = _old;
  if (new)
    *new = _new;
}

- (void)pickedButton:(id)sender
{
  if ([sender tag] == NSPLOKButton)
    {
      // check the items if the values are positive,
      // if not select that item and keep on running.
      NSTextField *field;

      field = [[self contentView] viewWithTag: NSPLWidthForm];
      if ((field != nil) && ([field floatValue] <= 0.0))
        {
	  [field selectText: sender];  
	  return;
	}
      field = [[self contentView] viewWithTag: NSPLHeightForm];
      if ((field != nil) && ([field floatValue] <= 0.0))
        {
	  [field selectText: sender];  
	  return;
	}

      // store the values in the print info
      [self writePrintInfo];

      _result = NSOKButton;
    }
  if ([sender tag] == NSPLCancelButton)
    {
      _result = NSOKButton;
    }

  [NSApp stopModal];
}

- (void)pickedOrientation:(id)sender
{
    NSLog(@"pickedOrientation %@", sender);
}

- (void)pickedPaperSize:(id)sender
{
    NSLog(@"pickedPaperSize %@", sender);
}

- (void)pickedUnits:(id)sender
{
  NSTextField *field;
  float new, old;
  
  // At this point the units have been selected but not set.
  [self convertOldFactor:&old newFactor:&new];
   
  field = [[self contentView] viewWithTag: NSPLWidthForm];
  if (field != nil)
    {
      // Update field based on the conversion factors.
      [field setFloatValue:([field floatValue]*new/old)];
    }

  field = [[self contentView] viewWithTag: NSPLHeightForm];
  if (field != nil)
    {
      // Update field based on the conversion factors.
      [field setFloatValue:([field floatValue]*new/old)];
    }

  // Set the selected units.
  _old = _new;
}

//
// Communicating with the NSPrintInfo Object 
//
- (NSPrintInfo *)printInfo
{
  return _printInfo;
}

- (void)readPrintInfo
{
    
}

- (void)writePrintInfo
{
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end

@implementation NSPageLayout (Private)

- (id) _initWithoutGModel
{
  NSRect rect = {{100,100}, {300,300}};    
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask;

  self = [super initWithContentRect: rect
			  styleMask: style
			    backing: NSBackingStoreRetained
			      defer: NO
			     screen: nil];
  if (self != nil)
    {
      NSImageView *imageView;
      NSImage *paper;
      NSComboBox *combo;
      NSBox *box;
      NSForm *f;
      NSFormCell *fc;
      NSMatrix *o;
      NSButtonCell *oc;
      NSButton *okButton;
      NSButton *cancelButton;
      NSRect pi = {{60,170}, {100,100}};
      NSRect wf = {{5,120}, {75,30}};
      NSRect hf = {{90,120}, {75,30}};
      NSRect pb = {{190,240}, {95,30}};
      NSRect pc = {{5,5}, {85,20}};
      NSRect lb = {{190,180}, {95,30}};
      NSRect lc = {{5,5}, {85,20}};
      NSRect ub = {{190,120}, {95,30}};
      NSRect uc = {{5,5}, {85,20}};
      NSRect sb = {{190,60}, {95,35}};
      NSRect mo = {{60,60}, {90,40}};
      NSRect rb = {{126,8}, {72,24}};
      NSRect db = {{217,8}, {72,24}};
      NSView *content;

      [self setTitle: @"Page Layout"];

      content = [self contentView];

      // image of the paper size
      paper = nil;
      imageView = [[NSImageView alloc] initWithFrame: pi]; 
      [imageView setImage: paper];
      [imageView setImageScaling: NSScaleNone];
      [imageView setEditable: NO];
      [imageView setTag: NSPLImageButton];
      [content addSubview: imageView];
      RELEASE(imageView);

      // Width
      f = [[NSForm alloc] initWithFrame: wf];
      fc = [f addEntry: @"Width:"];
      [fc setEditable: YES];
      [fc setSelectable: YES];
      [f setBordered: NO];
      [f setBezeled: YES];
      [f setTitleAlignment: NSRightTextAlignment];
      [f setTextAlignment: NSLeftTextAlignment];
      [f setAutosizesCells: YES];
      [f sizeToFit];
      [f setEntryWidth: 80.0];
      [f setTag: NSPLWidthForm];
      [content addSubview: f];
      RELEASE(f);

      // Height
      f = [[NSForm alloc] initWithFrame: hf];
      fc = [f addEntry: @"Height:"];
      [fc setEditable: YES];
      [fc setSelectable: YES];
      [f setBordered: NO];
      [f setBezeled: YES];
      [f setTitleAlignment: NSRightTextAlignment];
      [f setTextAlignment: NSLeftTextAlignment];
      [f setAutosizesCells: YES];
      [f sizeToFit];
      [f setEntryWidth: 80.0];
      [f setTag: NSPLHeightForm];
      [content addSubview: f];
      RELEASE(f);

      // Paper Size
      box = [[NSBox alloc] initWithFrame: pb];
      [box setTitle: @"Paper Size"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      combo = [[NSComboBox alloc] initWithFrame: pc];
      [combo setEditable: NO];
      [combo setSelectable: NO];
      [combo setBordered: NO];
      [combo setBezeled: YES];
      [combo setDrawsBackground: NO];
      [combo setAlignment: NSLeftTextAlignment];
      [combo addItemWithObjectValue: @"A2"];
      [combo addItemWithObjectValue: @"A3"];
      [combo addItemWithObjectValue: @"A4"];
      [combo addItemWithObjectValue: @"A5"];
      [combo addItemWithObjectValue: @"A6"];
      [combo setNumberOfVisibleItems: 5];
      [combo selectItemAtIndex: 0];
      [combo setObjectValue:[combo objectValueOfSelectedItem]];
      [combo setAction: @selector(pickedPaperSize:)];
      [combo setTarget: self];
      [combo setTag: NSPLPaperNameButton];
      [box addSubview: combo];
      RELEASE(combo);
      [box sizeToFit];

      [content addSubview: box];
      RELEASE(box);

      // Layout
      box = [[NSBox alloc] initWithFrame: lb];
      [box setTitle: @"Layout"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      combo = [[NSComboBox alloc] initWithFrame: lc];
      [combo setEditable: NO];
      [combo setSelectable: NO];
      [combo setBordered: NO];
      [combo setBezeled: YES];
      [combo setDrawsBackground: NO];
      [combo setAlignment: NSLeftTextAlignment];
      [combo addItemWithObjectValue: @"1 Up"];
      [combo setNumberOfVisibleItems: 5];
      [combo selectItemAtIndex: 0];
      [combo setObjectValue:[combo objectValueOfSelectedItem]];
      [box addSubview: combo];
      RELEASE(combo);
      [box sizeToFit];

      [content addSubview: box];
      RELEASE(box);

      // Units
      box = [[NSBox alloc] initWithFrame: ub];
      [box setTitle: @"Units"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      combo = [[NSComboBox alloc] initWithFrame: uc];
      [combo setEditable: NO];
      [combo setSelectable: NO];
      [combo setBordered: NO];
      [combo setBezeled: YES];
      [combo setDrawsBackground: NO];
      [combo setAlignment: NSLeftTextAlignment];
      [combo addItemWithObjectValue: @"Points"];
      [combo addItemWithObjectValue: @"Millimeter"];
      [combo addItemWithObjectValue: @"Centimeter"];
      [combo addItemWithObjectValue: @"Inches"];
      [combo setNumberOfVisibleItems: 5];
      [combo selectItemAtIndex: 2];
      [combo setObjectValue:[combo objectValueOfSelectedItem]];
      [combo setAction: @selector(pickedUnits:)];
      [combo setTarget: self];
      [combo setTag: NSPLUnitsButton];
      [box addSubview: combo];
      RELEASE(combo);
      [box sizeToFit];

      [content addSubview: box];
      RELEASE(box);

      // Sacle
      box = [[NSBox alloc] initWithFrame: sb];
      [box setTitle: @"Scale"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];


      [content addSubview: box];
      RELEASE(box);

      // orientation
      o = [[NSMatrix alloc] initWithFrame: mo 
			    mode: NSRadioModeMatrix 
			    cellClass: [NSButtonCell class]
			    numberOfRows: 1
			    numberOfColumns: 2];
      [o setCellSize: NSMakeSize(60, 50)];
      [o setIntercellSpacing: NSMakeSize(5, 5)];
      oc = (NSButtonCell*)[o cellAtRow: 0 column: 0];
      [oc setFont: [NSFont systemFontOfSize: 10]];
      [oc setButtonType: NSOnOffButton];
      [oc setBordered: YES];
      [oc setTitle: @"Portrait"];
      [oc setImagePosition: NSImageAbove];
      oc = (NSButtonCell*)[o cellAtRow: 0 column: 1];
      [oc setFont: [NSFont systemFontOfSize: 10]];
      [oc setButtonType: NSOnOffButton];
      [oc setBordered: YES];
      [oc setTitle: @"Landscape"];
      [oc setImagePosition: NSImageAbove];
      [o selectCellAtRow: 0 column: 0];
      [o setAllowsEmptySelection: NO];
      [o setTag: NSPLOrientationMatrix];
      [o setAction: @selector(pickedOrientation:)];
      [o setTarget: self];
      [content addSubview: o];
      RELEASE(o);

      // cancle button
      cancelButton = [[NSButton alloc] initWithFrame: rb];
      [cancelButton setStringValue: @"Cancel"];
      [cancelButton setAction: @selector(pickedButton:)];
      [cancelButton setTarget: self];
      [cancelButton setTag: NSPLCancelButton];
      [content addSubview: cancelButton];
      RELEASE(cancelButton);

      // OK button
      okButton = [[NSButton alloc] initWithFrame: db];
      [okButton setStringValue: @"OK"];
      [okButton setAction: @selector(pickedButton:)];
      [okButton setTarget: self];
      [okButton setTag: NSPLOKButton];
      [content addSubview: okButton];
      // make it the default button
      [self setDefaultButtonCell: [okButton cell]];
      RELEASE(okButton);
    }

  return self;
}

@end

