/** <title>NSPageLayout</title>

   <abstract>Standard panel for querying user about page layout.</abstract>

   Copyright <copy>(C) 2001 Free Software Foundation, Inc.</copy>

   Written By: <author name="Adam Fedor"><email>fedor@gnu.org</email></author>
   Date: Oct 2001
   
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
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPageLayout.h>
#include <AppKit/NSPrinter.h>

static NSPageLayout *shared_instance;

#define GSPANELNAME @"GSPageLayout"

#define CONTROL(panel, name) [[panel contentView] viewWithTag: name]

/**
<unit>
  <heading>NSPageLayout</heading>
  <p>
  NSPageLayout provides a panel that allows the user to specify certain
  information about the printer and how data is formatted for printing.
  This includes information about the paper size and orientation.

  Typically you would create a page layout panel with the 
  <ref id="pageLayout">pageLayout</ref> class method. However, the best
  way to use the panel is to have the application
  call the runPageLayout: method in the NSApplication object
  which would both create a standard NSPageLayout panel and display it
  in a modal loop. This method would be sent up the responder chain if
  the user clicked on a Page Layout menu item.
  </p>
</unit>
*/
@implementation NSPageLayout

//
// Class methods
//
/** Creates and returns a shared instance of the NSPageLayout panel.
 */
+ (NSPageLayout *)pageLayout
{
  if (shared_instance == nil)
    {
      shared_instance = [[NSPageLayout alloc] init];
    }
  return shared_instance;
}

//
// Instance methods
//
- (NSArray*) _units
{
  return [NSArray arrayWithObjects: @"pts", @"mm", @"cm", @"in", nil]; 
}

- (id) init
{
  int style =  NSTitledWindowMask;
  NSRect frame = NSMakeRect(300, 300, 350, 320);
  return [self initWithContentRect: frame
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: YES];
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
		    screen: (NSScreen*)aScreen
{
  int i;
  id control;
  NSForm *sizeForm;
  NSArray *subviews, *list;
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
      NSRunAlertPanel(@"Error", @"Could not find page layout resource", 
		      @"OK", NULL, NULL);
      return nil;
    }
  table = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
  if ([NSBundle loadNibFile: panel 
	  externalNameTable: table
		withZone: [self zone]] == NO)
    {
      NSRunAlertPanel(@"Error", @"Could not load page layout resource", 
		      @"OK", NULL, NULL);
      return nil;
    }

  /* Transfer the objects to us. FIXME: There must be a way to 
     instantiate the panel directly */
  subviews = [[_panel contentView] subviews];
  for (i = 0; i < [subviews count]; i++)
    {
      [_contentView addSubview: [subviews objectAtIndex: i]];
    }
  DESTROY(_panel);
  /* FIXME: Can't do this in Gorm yet: */
  sizeForm = CONTROL(self, NSPLWidthForm);
  [[sizeForm cellAtIndex: 0] setEditable: NO];
  [[sizeForm cellAtIndex: 1] setEditable: NO];
  [[sizeForm cellAtIndex: 0] setSelectable: NO];
  [[sizeForm cellAtIndex: 1] setSelectable: NO];
  control = CONTROL(self, NSPLOKButton);
  [self setDefaultButtonCell: [control cell]];

  /* Set up units popup */
  control =  CONTROL(self, NSPLUnitsButton);
  list = [self _units];
  [control removeAllItems];
  for (i = 0; i < [list count]; i++)
    {
      [control addItemWithTitle: [list objectAtIndex: i]];
    }
  [control selectItemAtIndex: 0];
  return self;
}

//
// Running the Panel 
//
/** Display the Page Layout panel in a modal loop. Saves any aquired 
   information in the shared NSPrintInfo object. Returns NSCancelButton 
   if the user clicks the Cancel button or NSOKButton otherwise.
*/
- (int)runModal
{
  return [self runModalWithPrintInfo: [NSPrintInfo sharedPrintInfo]];
}

/** Display the Page Layout panel in a modal loop. Saves any aquired 
   information in the indicated NSPrintInfo object. Returns NSCancelButton 
   if the user clicks the Cancel button or NSOKButton otherwise.
*/
- (int)runModalWithPrintInfo:(NSPrintInfo *)pInfo
{
  int result;
  
  _printInfo = pInfo;
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
  _picked = NSOKButton;
  _printInfo = printInfo;
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
/** Returns the accessory view for the page layout panel 
 */
- (NSView *)accessoryView
{
  return _accessoryView;
}

/** Set the accessory view for the page layout panel 
 */
- (void)setAccessoryView:(NSView *)aView
{
  ASSIGN(_accessoryView, aView);
}

//
// Updating the Panel's Display 
//
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

/** Convert the old value to a new one based on the current units. This
    method has been depreciated. It doesn't do anything useful
*/
- (void)convertOldFactor:(float *)old
	       newFactor:(float *)new
{
  NSPopUpButton *pop;
  int sel;

  if (old == NULL)
    return;
  pop = [[self contentView] viewWithTag: NSPLUnitsButton];
  if (pop == nil)
    return;

  sel = [pop indexOfSelectedItem];
  if (new)
    *new = [self factorForIndex: sel];
}

/* Private communication with our panel objects */
- (void) _pickedButton: (id)sender
{
  int tag = [sender tag];
  if (tag == NSPLOKButton)
    {
      _picked = NSOKButton;
      [self writePrintInfo];
    }
  else if (tag == NSPLCancelButton)
    {
      _picked = NSCancelButton;
    }
  else
    {
      NSLog(@"NSPageLayout button press from unknown sender %@ tag %d", 
	    sender, tag);
      _picked = NSOKButton;
    }
  [NSApp stopModalWithCode: _picked];
}

- (void) _setNewPageSize
{
  NSForm *sizeForm = [[self contentView] viewWithTag: NSPLWidthForm];
  id control = [[self contentView] viewWithTag: NSPLUnitsButton];
  double factor = [self factorForIndex: [control indexOfSelectedItem]];
  [[sizeForm cellAtIndex: 0] setDoubleValue: _size.width * factor];
  [[sizeForm cellAtIndex: 1] setDoubleValue: _size.height * factor];
}

- (void) _pickedPaper: (id)sender
{
  NSPrinter *printer;
  int tag = [sender tag];

  printer = [_printInfo printer];

  if (tag == NSPLPaperNameButton)
    {
      id ocontrol;
      _size = [printer pageSizeForPaper: [sender titleOfSelectedItem]];
      ocontrol = [[self contentView] viewWithTag: NSPLOrientationMatrix];
      if ([ocontrol selectedColumn] > 0)
	{
	  double temp = _size.width;
	  _size.width = _size.height;
	  _size.height = temp;
	}
      [self _setNewPageSize];
    }
  else if (tag == NSPLUnitsButton)
    {
      [self _setNewPageSize];
    }
  else if (tag == NSPLOrientationMatrix)
    {
      if ([sender selectedColumn] > 0)
	{
	  double temp = MIN(_size.width, _size.height);
	  _size.width = MAX(_size.width, _size.height);
	  _size.height = temp;
	}
      else
	{
	  double temp = MAX(_size.width, _size.height);
	  _size.width = MIN(_size.width, _size.height);
	  _size.height = temp;
	}
      [self _setNewPageSize];
    }
  else 
    {
      NSLog(@"NSPageLayout action from unknown sender %@ tag %d", 
	    sender, tag);
    }
}

/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedButton:(id)sender
{
  NSLog(@"[NSPageLayout -pickedButton:] method depreciated");
  [self pickedButton: sender];
}

/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedOrientation:(id)sender
{
  NSLog(@"[NSPageLayout -pickedOrientation:] method depreciated");
}

/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedPaperSize:(id)sender
{
  NSLog(@"[NSPageLayout -pickedPaperSize:] method depreciated");
}

/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedLayout:(id)sender
{
  NSLog(@"[NSPageLayout -pickedLayout:] method depreciated");
}

/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedUnits:(id)sender
{
  NSLog(@"[NSPageLayout -pickedUnits:] method depreciated");
}

//
// Communicating with the NSPrintInfo Object 
//
/** Return the NSPrintInfo object that the receiver stores layout information
    into.
*/
- (NSPrintInfo *)printInfo
{
  return _printInfo;
}

/** Updates the receiver panel with information from its NSPrintInfo object
 */
- (void)readPrintInfo
{
  id control;
  NSString *str;
  NSPrinter *printer;
  NSDictionary *dict;

  printer = [_printInfo printer];
  dict = [_printInfo dictionary];

  /* Setup the paper name popup */
  control = [[self contentView] viewWithTag: NSPLPaperNameButton];
  [control removeAllItems];
  str = [_printInfo paperName];
  if (str)
    {
      NSArray *list;
      list = [printer stringListForKey:@"PageSize" inTable: @"PPD"];
      if ([list count])
	{
	  int i;
	  for (i = 0; i < [list count]; i++)
	    {
	      NSString *key = [list objectAtIndex: i];
	      [control addItemWithTitle: key];
	    }
	  [control selectItemWithTitle: str];
	}
      else
	{
	  [control addItemWithTitle: str];
	}
    }
  else
    [control addItemWithTitle: @"Unknown"];

  /* Set up units */
  control = [[self contentView] viewWithTag: NSPLUnitsButton];
  if ([control numberOfItems] < 2)
    {
      int i;
      NSArray *list = [self _units];
      [control removeAllItems];
      for (i = 0; i < [list count]; i++)
	{
	  [control addItemWithTitle: [list objectAtIndex: i]];
	}
      [control selectItemAtIndex: 0];
    }
  else
    {
      /* We've already been setup */
      [control selectItemAtIndex: 0];
    }
     
  /* Set up size form */
  _size = [_printInfo paperSize];
  control = [[self contentView] viewWithTag: NSPLWidthForm];
  [[control cellAtIndex: 0] setDoubleValue: _size.width];
  [[control cellAtIndex: 1] setDoubleValue: _size.height];
  
  /* Set up the orientation */
  {
    NSPrintingOrientation orient = [_printInfo orientation];
    control = [[self contentView] viewWithTag: NSPLOrientationMatrix];
    [control selectCellAtRow: 0 column: (orient - NSPortraitOrientation)];
  }
}

/** Writes any layout information set by the user to the receiver's
    NSPrintInfo object
*/
- (void)writePrintInfo
{
  id control;
  NSString *str;
  NSPrinter *printer;

  printer = [_printInfo printer];

  /* Write Paper Name */
  control = [[self contentView] viewWithTag: NSPLPaperNameButton];
  str = [control titleOfSelectedItem];
  [_printInfo setPaperName: str];

  /* Write Orientation */
  control = [[self contentView] viewWithTag: NSPLOrientationMatrix];
  [_printInfo setOrientation: [control selectedColumn]+NSPortraitOrientation];

  /* Write Size */
  /* FIXME: Currently don't allow writing custom size. */

}

@end
