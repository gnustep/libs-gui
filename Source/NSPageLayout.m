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
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPageLayout.h>

NSPageLayout *shared_instance;

@interface NSPageLayout (Private)
- (id) _initWithoutGModel;
- (NSArray*) _units;
- (float) factorForIndex: (int)sel;
- (NSArray*) _paperSizes;
- (NSArray*) _layouts;
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
  int result;
  
  // store the print Info
  _printInfo = pInfo;

  // read the values of the print info
  [self readPrintInfo];

  result = [NSApp runModalForWindow: self];
  [self orderOut: self];

  return result;
}

- (void)beginSheetWithPrintInfo:(NSPrintInfo *)printInfo
		 modalForWindow:(NSWindow *)docWindow
		       delegate:(id)delegate
		 didEndSelector:(SEL)didEndSelector
		    contextInfo:(void *)contextInfo
{
  // store the print Info
  _printInfo = printInfo;

  // read the values of the print info
  [self readPrintInfo];

  [NSApp beginSheet: self
	 modalForWindow: docWindow
	 modalDelegate: delegate
	 didEndSelector: didEndSelector
	 contextInfo: contextInfo];

  [self orderOut: self];
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
  NSPopUpButton *pop;
  int sel;

  if (old)
    *old = _old;

  pop = [[self contentView] viewWithTag: NSPLUnitsButton];
  if (pop != nil)
    {
      sel = [pop indexOfSelectedItem];
      
      if (new)
	*new = [self factorForIndex: sel];
    }
  else if (new)
    *new = _old;
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

      [NSApp stopModalWithCode: NSOKButton];
    }
  if ([sender tag] == NSPLCancelButton)
    {
      [NSApp stopModalWithCode: NSCancelButton];
    }
}

- (void)pickedOrientation:(id)sender
{
  NSLog(@"pickedOrientation %@", sender);
}

- (void)pickedPaperSize:(id)sender
{
  NSLog(@"pickedPaperSize %@", sender);
}

- (void)pickedLayout:(id)sender
{
  NSLog(@"pickedLayout %@", sender);
}

- (void)pickedUnits:(id)sender
{
  NSTextField *field;
  float new, old;
  
  // At this point the units have been selected but not set.
  [self convertOldFactor: &old newFactor: &new];

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
  _old = new;
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
  NSTextField *field;
  NSSize size = [_printInfo paperSize];
  float new, old;
  
  // Both values should be the same
  [self convertOldFactor: &old newFactor: &new];

  field = [[self contentView] viewWithTag: NSPLWidthForm];
  if (field != nil)
    {
      // Update field based on the conversion factors.
      [field setFloatValue:(size.width/old)];
    }

  field = [[self contentView] viewWithTag: NSPLHeightForm];
  if (field != nil)
    {
      // Update field based on the conversion factors.
      [field setFloatValue:(size.height/old)];
    }

  //[_printInfo paperName];
  //[_printInfo orientation];  
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
      NSBox *box;
      NSForm *f;
      NSFormCell *fc;
      NSMatrix *o;
      NSButtonCell *oc;
      NSButton *okButton;
      NSButton *cancelButton;
      NSRect uv = {{0,50}, {300,250}};
      NSRect lv = {{0,0}, {300,50}};  
      NSRect ulv = {{0,0}, {190,250}};
      NSRect urv = {{190,0}, {110,250}};
      NSRect pi = {{60,120}, {100,100}};
      NSRect wf = {{5,70}, {75,30}};
      NSRect hf = {{90,70}, {75,30}};
      NSRect pb = {{0,190}, {95,30}};
      NSRect pc = {{5,5}, {85,20}};
      NSRect lb = {{0,130}, {95,30}};
      NSRect lc = {{5,5}, {85,20}};
      NSRect ub = {{0,70}, {95,30}};
      NSRect uc = {{5,5}, {85,20}};
      NSRect sb = {{0,10}, {95,35}};
      NSRect tf = {{5,5}, {75,20}};
      NSRect mo = {{60,10}, {90,40}};
      NSRect rb = {{126,8}, {72,24}};
      NSRect db = {{217,8}, {72,24}};
      NSView *content;
      NSView *upper;
      NSView *lower;
      NSView *left;
      NSView *right;
      NSPopUpButton *pop;
      NSTextField *text;

      [self setTitle: @"Page Layout"];

      content = [self contentView];
      // Spilt up in upper and lower
      upper = [[NSView alloc] initWithFrame: uv];
      [content addSubview: upper];
      RELEASE(upper);
      lower = [[NSView alloc] initWithFrame: lv];
      [content addSubview: lower];
      RELEASE(lower);
      // Solit upper in left and right
      left = [[NSView alloc] initWithFrame: ulv];
      [upper addSubview: left];
      RELEASE(left);
      right = [[NSView alloc] initWithFrame: urv];
      [upper addSubview: right];
      RELEASE(right);

      // FIXME: image of the paper size
      paper = nil;
      imageView = [[NSImageView alloc] initWithFrame: pi]; 
      [imageView setImage: paper];
      [imageView setImageScaling: NSScaleNone];
      [imageView setEditable: NO];
      [imageView setTag: NSPLImageButton];
      [left addSubview: imageView];
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
      [left addSubview: f];
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
      [left addSubview: f];
      RELEASE(f);

      // Paper Size
      box = [[NSBox alloc] initWithFrame: pb];
      [box setTitle: @"Paper Size"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      pop = [[NSPopUpButton alloc] initWithFrame: pc pullsDown: NO];
      [pop setAction: @selector(pickedPaperSize:)];
      [pop setTarget: self];
      [pop addItemsWithTitles: [self _paperSizes]];
      [pop selectItemAtIndex: 0];
      [pop setTag: NSPLPaperNameButton];
      [box addSubview: pop];
      RELEASE(pop);
      [box sizeToFit];

      [right addSubview: box];
      RELEASE(box);

      // Layout
      box = [[NSBox alloc] initWithFrame: lb];
      [box setTitle: @"Layout"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      pop = [[NSPopUpButton alloc] initWithFrame: lc pullsDown: NO];
      [pop setAction: @selector(pickedLayout:)];
      [pop setTarget: self];
      [pop addItemsWithTitles: [self _layouts]];
      [pop selectItemAtIndex: 0];
      //[pop setTag: NSPLPaperNameButton];
      [box addSubview: pop];
      RELEASE(pop);
      [box sizeToFit];

      [right addSubview: box];
      RELEASE(box);

      // Units
      box = [[NSBox alloc] initWithFrame: ub];
      [box setTitle: @"Units"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      pop = [[NSPopUpButton alloc] initWithFrame: uc pullsDown: NO];
      [pop setAction: @selector(pickedUnits:)];
      [pop setTarget: self];
      [pop addItemsWithTitles: [self _units]];
      [pop selectItemAtIndex: 0];
      [pop setTag: NSPLUnitsButton];
      [box addSubview: pop];
      RELEASE(pop);

      [box sizeToFit];

      [right addSubview: box];
      RELEASE(box);

      // Scale
      box = [[NSBox alloc] initWithFrame: sb];
      [box setTitle: @"Scale"];
      [box setTitlePosition: NSAtTop];
      [box setBorderType: NSGrooveBorder];
      [box setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

      text = [[NSTextField alloc] initWithFrame: tf];
      [box addSubview: text];
      RELEASE(text);

      [box sizeToFit];

      [right addSubview: box];
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
      [left addSubview: o];
      RELEASE(o);

      // cancle button
      cancelButton = [[NSButton alloc] initWithFrame: rb];
      [cancelButton setStringValue: @"Cancel"];
      [cancelButton setAction: @selector(pickedButton:)];
      [cancelButton setTarget: self];
      [cancelButton setTag: NSPLCancelButton];
      [lower addSubview: cancelButton];
      RELEASE(cancelButton);

      // OK button
      okButton = [[NSButton alloc] initWithFrame: db];
      [okButton setStringValue: @"OK"];
      [okButton setAction: @selector(pickedButton:)];
      [okButton setTarget: self];
      [okButton setTag: NSPLOKButton];
      [lower addSubview: okButton];
      // make it the default button
      [self setDefaultButtonCell: [okButton cell]];
      RELEASE(okButton);
    }

  return self;
}

- (NSArray*) _units
{
  return [NSArray arrayWithObjects: @"Points", @"Millimeter", 
		  @"Centimeter", @"Inches", nil]; 
}

- (float) factorForIndex: (int)sel
{
  switch (sel)
    {
      default:
      case 0: return 1.0;
      case 1: return 25.4/72;
      case 2: return 2.54/72;
      case 3: return 1.0/72;	    
    }    
}

- (NSArray*) _paperSizes
{
  return [NSArray arrayWithObjects: @"A2", @"A3", @"A4", 
		  @"A5", @"A6", nil]; 
}

- (NSArray*) _layouts
{
  return [NSArray arrayWithObjects: @"1 Up", nil]; 
}

@end
