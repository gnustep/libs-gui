/* 
   NSPrintPanel.m

   Creates a Print panel for the user to select various print options.

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: 2001
   
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

#include <gnustep/gui/config.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPrinter.h>
#include <AppKit/NSPrintPanel.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintOperation.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSView.h>

#define GSPANELNAME @"GSPrintPanel"

@implementation NSPrintPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintPanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSPrintPanel 
//
/* It seems like this should be a singleton, but the docs say this
   returns a newly created panel object
*/
+ (NSPrintPanel *)printPanel
{
  int style =  NSTitledWindowMask | NSClosableWindowMask;
  NSRect frame = NSMakeRect(300, 300, 420, 350);
  return [[NSPrintPanel alloc] initWithContentRect: frame
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: YES];
}

//
// Instance methods
//
/* Designated initializer */
- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
		    screen: (NSScreen*)aScreen
{
  int i;
  NSArray *subviews;
  NSString *panel;
  NSDictionary *table;

  self = [super initWithContentRect: contentRect
		 styleMask: aStyle
		   backing: bufferingType
		     defer: flag
		    screen: aScreen];
  if (self == nil)
    return nil;

  panel = [NSBundle pathForGNUstepResource: GSPANELNAME ofType: @"gorm"
		    inDirectory: nil];
  if (panel == nil)
    {
      NSRunAlertPanel(@"Error", @"Could not find print panel resource", 
		      @"OK", NULL, NULL);
      return nil;
    }
  table = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
  if ([NSBundle loadNibFile: panel 
	  externalNameTable: table
		withZone: [self zone]] == NO)
    {
      NSRunAlertPanel(@"Error", @"Could not load print panel resource", 
		      @"OK", NULL, NULL);
      return nil;
    }

  /* Transfer the objects to us. FIXME: There must be a way to 
     instantiate the panel directly */
  subviews = [[_panelWindow contentView] subviews];
  for (i = 0; i < [subviews count]; i++)
    {
      [_contentView addSubview: [subviews objectAtIndex: i]];
    }
  DESTROY(_panelWindow);
  /* FIXME: Can't do this in Gorm yet: */
  [_printForm setBezeled: NO];
  [_printForm setBordered: NO];
  [[_printForm cellAtIndex: 0] setEditable: NO];
  [[_printForm cellAtIndex: 1] setEditable: NO];
  [[_printForm cellAtIndex: 2] setEditable: NO];
  [[_printForm cellAtIndex: 0] setSelectable: NO];
  [[_printForm cellAtIndex: 1] setSelectable: NO];
  [[_printForm cellAtIndex: 2] setSelectable: NO];
  return self;
}

//
// Customizing the Panel 
//
- (void)setAccessoryView:(NSView *)aView
{
  ASSIGN(_accessoryView, aView);
}

- (NSView *)accessoryView
{
  return _accessoryView;
}

//
// Running the Panel 
//
- (int)runModal
{
  _picked = NSCancelButton;
  [NSApp runModalForWindow: self];
  [self orderOut: self];
  return (_picked == NSCancelButton) ? NSCancelButton :  NSOKButton;
}

- (BOOL) _getSavePath
{
  int result;
  NSSavePanel *sp;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"ps"];
  result = [sp runModal];
  if (result == NSOKButton)
    {
      NSFileManager     *mgr = [NSFileManager defaultManager];
      NSString          *path = [sp filename];

      if ([path isEqual: _savePath] == NO
        && [mgr fileExistsAtPath: path] == YES)
        {
          if (NSRunAlertPanel(NULL, @"A document with that name exists",
            @"Replace", @"Cancel", NULL) != NSAlertDefaultReturn)
            {
              return NO;
            }
        }
      _savePath = RETAIN(path);
    }
  return (result == NSOKButton);
}

/* Private communication with our panel objects */
- (void) _pickedButton: (id)sender
{
  if (sender == _saveButton)
    {
      _picked = NSPPSaveButton;
      if ([self _getSavePath] == NO)
	{
	  /* User pressed save, then changed his mind, so go back to
	     the print panel (don't stop the modal session) */
	  return;
	}
    }
  else if (sender == _previewButton)
    {
      _picked = NSPPPreviewButton;
    }
  else if (sender == _faxButton)
    {
      _picked = NSFaxButton;
      NSRunAlertPanel(@"Warning", @"Fax of print file not implemented", 
		      @"OK", NULL, NULL);
      /* Don't stop the modal session */
      return;
    }
  else if (sender == _cancelButton)
    {
      _picked = NSCancelButton;
    }
  else if (sender == _printButton)
    {
      _picked = NSOKButton;
    }
  else
    {
      NSLog(@"Print panel buttonAction: from unknown sender - x%x\n",
	(unsigned)sender);
    }
  [NSApp stopModalWithCode: _picked];
}

- (void) _pickedPage: (id)sender
{
  if ([_pageMatrix selectedColumn] == 0)
    {
      [[_fromRangeForm cellAtIndex: 0] setStringValue: @"" ];
      [[_toRangeForm cellAtIndex: 0] setStringValue: @"" ];
    }
  else
    {
      NSString *str;
      str = [NSString stringWithFormat: @"%d", _pages.location];
      [[_fromRangeForm cellAtIndex: 0] setStringValue: str];
      str = [NSString stringWithFormat: @"%d", NSMaxRange(_pages)];
      [[_toRangeForm cellAtIndex: 0] setStringValue: str];
    }
}

- (void) _pickedPrintOp: (id)sender
{
  NSLog(@"pick print op from sender %@, title %@", sender, [sender title]);
}

/* Depreciated communication methods */
- (void)pickedButton:(id)sender
{
  NSLog(@"[NSPrintPanel -pickedButton:] method depreciated");
  [self pickedButton: sender];
}

- (void)pickedAllPages:(id)sender
{
  NSLog(@"[NSPrintPanel -pickedAllPages:] method depreciated");
  [self _pickedPage: sender];
}

- (void)pickedLayoutList:(id)sender
{
  NSLog(@"[NSPrintPanel -pickedLayoutList:] method depreciated");
}

//
// Communicating with the NSPrintInfo Object 
//
- (void)updateFromPrintInfo
{
  NSString *str;
  NSPrinter *printer;
  NSDictionary *dict;
  NSPrintInfo* info = [[NSPrintOperation currentOperation] printInfo];

  printer = [info printer];
  [[_printForm cellAtIndex: 0] setStringValue: [printer name] ];
  [[_printForm cellAtIndex: 1] setStringValue: [printer note] ];
  [[_printForm cellAtIndex: 2] setStringValue: @"" ];

  [_copiesField setIntValue: 1];
  [[_fromRangeForm cellAtIndex: 0] setStringValue: @"" ];
  [[_toRangeForm cellAtIndex: 0] setStringValue: @"" ];
  [_pageMatrix selectCellAtRow: 0 column: 0];

  dict = [info dictionary];
  NSDebugLLog(@"NSPrintPanel", 
	      @"Update PrintInfo dictionary\n %@ \n --------------", dict);
  _pages = NSMakeRange([[dict objectForKey: NSPrintFirstPage] intValue],
		       [[dict objectForKey: NSPrintLastPage] intValue]);
  if (NSMaxRange(_pages) == 0)
    _pages = NSMakeRange(1, 0);

  /* Setup the resolution popup */
  [_resButton removeAllItems];
  str = [printer stringForKey:@"DefaultResolution" inTable: @"PPD"];
  if (str)
    {
      NSArray *resList;
      resList = [printer stringListForKey:@"Resolution" inTable: @"PPD"];
      if ([resList count])
	{
	  int i;
	  NSString *displayRes, *listRes;
	  for (i = 0; i < [resList count]; i++)
	    {
	      NSString *res = [resList objectAtIndex: i];
	      listRes = [@"Resolution/" stringByAppendingString: res];
	      displayRes = [printer stringForKey: listRes
				        inTable: @"PPDOptionTranslation"];

	      if (displayRes == nil)
		displayRes = res;
	      [_resButton addItemWithTitle: displayRes];
	    }
	  listRes = [@"Resolution/" stringByAppendingString: str];
	  displayRes = [printer stringForKey: listRes
				inTable: @"PPDOptionTranslation"];
	  
	  if (displayRes == nil)
	    displayRes = str;
	  [_resButton selectItemWithTitle: displayRes];
	}
      else
	{
	  [_resButton addItemWithTitle: str];
	}
    }
  else
    [_resButton addItemWithTitle: @"Unknown"];

  /* Setup the paper feed popup */
  [_paperButton removeAllItems];
  str = [printer stringForKey:@"DefaultInputSlot" inTable: @"PPD"];
  if (str)
    {
      NSString *manual;
      NSArray *inputList;
      manual = [printer stringForKey:@"DefaultManualFeed" inTable: @"PPD"];
      if (manual)
	[_paperButton addItemWithTitle: @"Manual"];
      inputList = [printer stringListForKey:@"InputSlot" inTable: @"PPD"];
      if ([inputList count])
	{
	  int i;
	  NSString *displayPaper, *listPaper;
	  for (i = 0; i < [inputList count]; i++)
	    {
	      NSString *paper = [inputList objectAtIndex: i];
	      listPaper = [@"InputSlot/" stringByAppendingString: paper];
	      displayPaper = [printer stringForKey: listPaper
				        inTable: @"PPDOptionTranslation"];

	      if (displayPaper == nil)
		displayPaper = paper;
	      [_paperButton addItemWithTitle: displayPaper];
	    }
	  /* FIXME: What if manual is default ? */
	  listPaper = [@"InputSlot/" stringByAppendingString: str];
	  displayPaper = [printer stringForKey: listPaper
				  inTable: @"PPDOptionTranslation"];
	  
	  if (displayPaper == nil)
	    displayPaper = str;
	  [_paperButton selectItemWithTitle: displayPaper];
	}
      else
	{
	  [_paperButton addItemWithTitle: str];
	}
    }
  else
    [_paperButton addItemWithTitle: @"Unknown"];

}

#define NSNUMBER(a) [NSNumber numberWithInt: (a)]

- (void)finalWritePrintInfo
{
  NSString *sel;
  NSArray  *list;
  NSPrinter *printer;
  NSMutableDictionary *dict;
  NSMutableDictionary *features;
  NSPrintInfo* info = [[NSPrintOperation currentOperation] printInfo];
  dict = [info dictionary];
  printer = [info printer];
  features = [dict objectForKey: NSPrintJobFeatures];

  /* Copies */
  if ([_copiesField intValue] > 1)
    {
      [dict setObject: NSNUMBER([_copiesField intValue]) 
	       forKey: NSPrintCopies];
    }

  /* Pages */
  if ([_pageMatrix selectedColumn] != 0)
    {
      [dict setObject: NSNUMBER([[_fromRangeForm cellAtIndex: 0] intValue])
	    forKey: NSPrintFirstPage];
      [dict setObject: NSNUMBER([[_toRangeForm cellAtIndex: 0] intValue])
	    forKey: NSPrintLastPage];
      [dict setObject: NSNUMBER(NO) forKey: NSPrintAllPages];
    }
  else
      [dict setObject: NSNUMBER(YES) forKey: NSPrintAllPages];

  /* Resolution */
  /* Here we take advantage of the fact the names in the popup list
     are in the same order as the PPD file, so we don't actually compare
     the values */
  list = [printer stringListForKey: @"Resolution" inTable: @"PPD"];
  if (list)
    {
      NSString *def;
      sel = [list objectAtIndex: [_resButton indexOfSelectedItem]];
      def = [printer stringForKey:@"DefaultResolution" inTable: @"PPD"];
      if ([sel isEqual: def] == NO)
	{
	  if (features == nil)
	    {
	      features = [NSMutableDictionary dictionary];
	      [dict setObject: features forKey: NSPrintJobFeatures];
	    }
	  sel = [@"Resolution/" stringByAppendingString: sel];
	  [features setObject: sel forKey: @"Resolution"];
	}
    }
  
  /* Input Slot */
  list = [printer stringListForKey:@"InputSlot" inTable: @"PPD"];
  if (list)
    {
      int selected;
      NSString *def, *manual;
      sel = nil;
      selected = [_paperButton indexOfSelectedItem];
      manual = [printer stringForKey:@"DefaultManualFeed" inTable: @"PPD"];
      
      if (manual)
	{
	  if (selected == 0)
	    sel = @"Manual";
	  else
	    selected--;
	}
      if (sel == nil)
	sel = [list objectAtIndex: selected];
      def = [printer stringForKey:@"DefaultInputSlot" inTable: @"PPD"];
      if ([sel isEqual: @"Manual"] == YES)
	{
	  [dict setObject: NSPrintManualFeed forKey: NSPrintPaperFeed];
	  /* FIXME: This needs to be more robust. I'm just assuming
	     that all Manual Feed keys can be True or False (which is
	     the case for all the ppd files that I know of). */
	  [dict setObject: @"ManualFeed/True" forKey: NSPrintManualFeed];
	  [features setObject: @"ManualFeed/True" forKey: NSPrintPaperFeed];
	}
      else if ([sel isEqual: def] == NO)
	{
	  if (features == nil)
	    {
	      features = [NSMutableDictionary dictionary];
	      [dict setObject: features forKey: NSPrintJobFeatures];
	    }
	  sel = [@"InputSlot/" stringByAppendingString: sel];
	  [features setObject: sel forKey: @"InputSlot"];
	  [dict setObject: sel forKey: NSPrintPaperFeed];
	}
    }

  /* Job Resolution */
  switch (_picked)
    {
    case NSPPSaveButton:
      sel = NSPrintSaveJob;
      [dict setObject: _savePath forKey: NSPrintSavePath];
      break;
    case NSPPPreviewButton:
      sel = NSPrintPreviewJob;
      break;
    case NSFaxButton:
      sel = NSPrintFaxJob;
      break;
    case NSOKButton:
      sel = NSPrintSpoolJob;
      break;
    case NSCancelButton:
    default:
      sel = NSPrintCancelJob;
    }
  [info setJobDisposition: sel];

  NSDebugLLog(@"NSPrintPanel", 
	      @"Final info dictionary ----\n %@ \n --------------", dict);

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
