/* 
   NSPageLayout.m

   Page setup panel

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: 2000
   
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
#include <AppKit/NSTextField.h>
#include <AppKit/NSButton.h>
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
/*
  NSRunAlertPanel (NULL, @"Page Layout Panel not implemented yet",
		   @"OK", NULL, NULL);
*/
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
{}

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
}

- (void)pickedPaperSize:(id)sender
{
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
      NSButton *okButton;
      NSButton *cancelButton;
      NSRect rb = {{56,8}, {72,24}};
      NSRect db = {{217,8}, {72,24}};
      NSView *content = [self contentView];

      [self setTitle: @"Page Layout"];

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

