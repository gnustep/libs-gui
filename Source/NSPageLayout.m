/** <title>NSPageLayout</title>

   <abstract>Standard panel for querying user about page layout.</abstract>

   Copyright (C) 2001,2004 Free Software Foundation, Inc.

   Written By: Adam Fedor <fedor@gnu.org>
   Date: Oct 2001
   Modified for Printing Backend Support
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   
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

#include "AppKit/NSApplication.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSTextField.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSImageView.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSBox.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSComboBox.h"
#include "AppKit/NSPopUpButton.h"
#include "AppKit/NSMatrix.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSForm.h"
#include "AppKit/NSFormCell.h"
#include "AppKit/NSPrintInfo.h"
#include "AppKit/NSPageLayout.h"
#include "AppKit/NSPrinter.h"
#include "GSGuiPrivate.h"
#include "GNUstepGUI/GSPrinting.h"

static NSPageLayout *shared_instance;


//#define CONTROL(panel, name) [[panel contentView] viewWithTag: name]

@implementation NSApplication (NSPageLayout)

- (void) runPageLayout: sender
{
  [[NSPageLayout pageLayout] runModal];
}

@end


@interface GSPageLayoutController : NSObject
{
  NSSize _size;
  double _scale;
  id _panel;
  id _orientationMatrix;
  id _widthField;
  id _heightField;
  id _unitsButton;
  id _paperNameButton;
  id _scaleField;
  id _imageButton;
  id _miniPageView;
  NSPrintInfo *_printInfo;
  NSView *_accessoryView;
}
-(NSPageLayout*) panel;

//IBActions
-(void) buttonClicked: (id)sender;
-(void) paperSelected: (id)sender;
-(void) unitsSelected: (id)sender;
-(void) scaleSelected: (id)sender;
-(void) widthSelected: (id)sender;
-(void) heightSelected: (id)sender;
-(void) orientationMatrixClicked: (id)sender;

//internal
-(void)  setNewPageSize;
-(float) factorForIndex: (int)sel;

//access to ivars
-(NSPrintInfo*) printInfo;
-(void) setPrintInfo:(NSPrintInfo*)printInfo;
-(NSView*) accessoryView;
-(void) setAccessoryView:(NSView*)accessoryView;
-(NSSize) pageSize;


//Handling of NSPageLayout implementation
-(void)convertOldFactor:(float *)old
	             newFactor:(float *)new;
-(void)readPrintInfo;
-(void)writePrintInfo;
@end



/**
<unit>
  <heading>NSPageLayout</heading>
  <p>
  NSPageLayout provides a panel that allows the user to specify certain
  information about the printer and how data is formatted for printing.
  This includes information about the paper size and orientation.

  Typically you would create a page layout panel with the 
  +pageLayout class method. However, the best
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
/** Load the appropriate bundle for the PageLayout 
    (eg: GSLPRPageLayout, GSCUPSPageLayout).
*/
+ (id) allocWithZone: (NSZone*) zone
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
	
  return [[principalClass pageLayoutClass] allocWithZone: zone];
}


/** Creates and returns a shared instance of the NSPageLayout panel.
 */
+ (NSPageLayout *)pageLayout
{
  if (shared_instance == nil)
    {
      GSPageLayoutController *controller;
      controller = [[GSPageLayoutController alloc] init];
      shared_instance = [controller panel];
    }
  return shared_instance;
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
- (int)runModalWithPrintInfo:(NSPrintInfo *)printInfo
{
  int result;
  
  [_controller setPrintInfo: printInfo];
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
  [_controller setPrintInfo: printInfo];
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
  return [_controller accessoryView];
}

/** Set the accessory view for the page layout panel 
 */
- (void)setAccessoryView:(NSView *)aView
{
  [_controller setAccessoryView: aView];
}



//
// Updating the Panel's Display 
//
/** Convert the old value to a new one based on the current units. This
    method has been depreciated. It doesn't do anything useful
*/
- (void)convertOldFactor:(float *)old
	             newFactor:(float *)new
{
  [_controller convertOldFactor: old
	                   newFactor: new];
}


/** This method has been depreciated. It doesn't do anything useful.
*/
- (void)pickedButton:(id)sender
{
  NSLog(@"[NSPageLayout -pickedButton:] method depreciated");
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
  return [_controller printInfo];
}

/** Updates the receiver panel with information from its NSPrintInfo object
 */
- (void)readPrintInfo
{
  [_controller readPrintInfo];
}

/** Writes any layout information set by the user to the receiver's
    NSPrintInfo object
*/
- (void)writePrintInfo
{
  [_controller writePrintInfo];
}

@end



//
// Controller for the PageLayout Panel
//
@implementation GSPageLayoutController
- (id) init
{
  NSString *panelPath;
  NSDictionary *table;
  NSImage *image;

  self = [super init];
  panelPath = [GSGuiBundle() pathForResource: @"GSPageLayout" 
			                                ofType: @"gorm"
			                           inDirectory: nil];
                                 
  NSLog(@"Panel path=%@",panelPath);
  table = [NSDictionary dictionaryWithObject: self 
                                      forKey: @"NSOwner"];
                                      
  if ([NSBundle loadNibFile: panelPath 
	        externalNameTable: table
		               withZone: [self zone]] == NO)
    {
      NSRunAlertPanel(@"Error", @"Could not load page layout panel resource", 
		                  @"OK", NULL, NULL);
      return nil;
    }
    
  image = [[NSApplication sharedApplication] applicationIconImage];
  [_imageButton setImage: image];
  
  return self;
}

- (NSPageLayout*) panel
{
  return (NSPageLayout*)_panel;
}


/* Private communication with our panel objects */
- (void) buttonClicked: (id)sender
{
  int picked;
  int tag = [sender tag];

  NSLog(@"buttonClicked:");
  if (tag == NSPLOKButton)
    {
      picked = NSOKButton;
      [self writePrintInfo];
    }
  else if (tag == NSPLCancelButton)
    {
      picked = NSCancelButton;
    }
  else
    {
      NSLog(@"NSPageLayout button press from unknown sender %@ tag %d", 
	            sender, tag);
      picked = NSOKButton;
    }
  [NSApp stopModalWithCode: picked];
}

- (void) setNewPageSize
{
  double factor;
 
  factor = [self factorForIndex: [_unitsButton indexOfSelectedItem]];
  [_widthField setDoubleValue: _size.width * factor];
  [_heightField setDoubleValue: _size.height * factor];
}

//
// Converts between points, millimeters, centimeters, and inches, in that order.
// Dependent upon the order of which the values appear in the Gorm popup.
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



- (void) paperSelected: (id)sender
{
  NSPrinter *printer;
  
  _scale = 100;
  [_scaleField setDoubleValue: _scale];
  
  printer = [_printInfo printer];
  _size = [printer pageSizeForPaper: [sender titleOfSelectedItem]];
  
  //check if the user selected landscape mode, if so, switch out the 
  //width and height
  if ([_orientationMatrix selectedColumn] > 0)
	  {
	    double temp  = _size.width;
	    _size.width  = _size.height;
	    _size.height = temp;
	  }
  [self setNewPageSize];
  [_miniPageView setNeedsDisplay: YES];
}

- (void) unitsSelected: (id)sender
{
  [self setNewPageSize];
  [_miniPageView setNeedsDisplay: YES];
}

-(void) scaleSelected: (id)sender
{
  float scale;
  
  scale = [_scaleField doubleValue];
  
  if( scale == 0.0 )
    {
      [_scaleField setDoubleValue: _scale];
    }
  else
    {
      _scale = scale;
      _size.width  *= (_scale/100);
      _size.height *= (_scale/100); 
    }
  
  [self setNewPageSize];
  [_miniPageView setNeedsDisplay: YES];
}

-(void) widthSelected: (id)sender
{
  double width;
  
  width = [_widthField doubleValue];
  
  if( width == 0.0 )
    {
      [_widthField setDoubleValue: _size.width];
    }
  else
    {
      _size.width = width;
      [_miniPageView setNeedsDisplay: YES];
    }
}

-(void) heightSelected: (id)sender
{
  double height;
  
  height = [_heightField doubleValue];
  
  if( height == 0.0 )
    {
      [_heightField setDoubleValue: _size.height];
    }
  else
    {
      _size.height = height;
      [_miniPageView setNeedsDisplay: YES];
    }
}

- (void) orientationMatrixClicked: (id)sender
{
  double temp;
  
  if ([sender selectedColumn] > 0)
	  {
	    temp = MIN(_size.width, _size.height);
	    _size.width = MAX(_size.width, _size.height);
	  }
  else
	  {
	    temp = MAX(_size.width, _size.height);
	    _size.width = MIN(_size.width, _size.height);
	  }
  _size.height = temp;
  [self setNewPageSize];
  [_miniPageView setNeedsDisplay: YES];
}

-(NSPrintInfo*) printInfo
{
  return _printInfo;
}

-(void) setPrintInfo:(NSPrintInfo*)printInfo
{
  ASSIGN( _printInfo, printInfo);
}

-(NSView*) accessoryView
{
  return _accessoryView;
}

-(void) setAccessoryView:(NSView*)accessoryView
{
  ASSIGN( _accessoryView, accessoryView);
}

-(NSSize) pageSize
{
  return _size;
}

- (void)convertOldFactor:(float *)old
	       newFactor:(float *)new
{
  int sel;

  if (old == NULL)
    return;

  sel = [_unitsButton indexOfSelectedItem];
  if (new)
    *new = [self factorForIndex: sel];
}

- (void)readPrintInfo
{
  NSString *string;
  NSPrinter *printer;
  NSDictionary *dict;

  printer = [_printInfo printer];
  dict = [_printInfo dictionary];

  /* Setup the paper name popup */
  {
    [_paperNameButton removeAllItems];
    string = [_printInfo paperName];
    if (string)
      {
        NSArray *paperNames;
        paperNames = [printer stringListForKey:@"PageSize" 
                                       inTable:@"PPD"];
        if ([paperNames count])
	        {
            NSEnumerator *paperNamesEnum;
            NSString *paperName;
	          paperNamesEnum = [paperNames objectEnumerator];

            while( (paperName = [paperNamesEnum nextObject]) )
              {
                [_paperNameButton addItemWithTitle: paperName];
              }
	          [_paperNameButton selectItemWithTitle: string];
	        }
        else //PPD was empty!
	        {
	          [_paperNameButton addItemWithTitle: string];
	        }
      }
    else //this really should not happen man.
      {
        [_paperNameButton addItemWithTitle: @"Unknown"];
      }
  }
  
  /* Set up units */
  {
    //The loading of the GORM file should ensure this is ok.
    [_unitsButton selectItemAtIndex: 0];
  }
     
  /* Set up size form */
  {
    _size = [_printInfo paperSize];
    [_widthField setDoubleValue: _size.width];
    [_heightField setDoubleValue: _size.height];
  }
  
  /* Set up the orientation */
  {
    NSPrintingOrientation orient = [_printInfo orientation];
    [_orientationMatrix selectCellAtRow: 0 
                                 column: (orient - NSPortraitOrientation)];
  }

  //TODO Scaling 
  {
    float scale = 100;
    NSNumber *scaleNumber; 
    if ((scaleNumber = [dict objectForKey:NSPrintScalingFactor]))
      {
	      scale = [scaleNumber floatValue];
      }

    [_scaleField setFloatValue: scale];
    _scale = scale;
  }

}

- (void)writePrintInfo
{
  NSString *string;
  NSPrinter *printer;
  float scale; 
  NSMutableDictionary *dict = [_printInfo dictionary];

  printer = [_printInfo printer];
  
  /* Write Paper Name */
  {
    string = [_paperNameButton titleOfSelectedItem];
    [_printInfo setPaperName: string];
  }

  /* Write Orientation */
  {
    [_printInfo setOrientation: 
                [_orientationMatrix selectedColumn]+NSPortraitOrientation];
  }

  /* Write Scaling Factor */
  {
    scale = _scale;
    [dict setObject: [NSNumber numberWithFloat:scale] 
             forKey: NSPrintScalingFactor];
  }
  
  
  /* Write Size */
  /* FIXME: Currently don't allow writing custom size. */

}

@end




//
// Show the preview of the page's dimensions
//

@interface GSPageLayoutMiniPageView : NSView
{
  id _pageLayoutController;
}
@end


//
// Show the preview of the page's dimensions
//
@implementation GSPageLayoutMiniPageView

-(int) tag
{
  return NSPLMiniPageView;
}

- (void) drawRect: (NSRect)rect
{
  NSSize pageSize;
  NSRect paper;
  NSRect shadow;
  double ratio;
  double width, height;
  NSColor *shadowColor;
  
  //Draw the background
  NSRect bounds = [self bounds];
	//[[NSColor windowBackgroundColor] set];
	//[NSBezierPath fillRect: bounds];
  
  pageSize = [_pageLayoutController pageSize];
  
  if( pageSize.width >= pageSize.height)
    {
      ratio = pageSize.height/ pageSize.width;
      width  = bounds.size.width;
      height = width * ratio;
    }
  else
    {
      ratio =  pageSize.width / pageSize.height;
      height = bounds.size.height;
      width  = height * ratio;
    }
  
  //make the page a bit smaller
  width  *= 0.75;
  height *= 0.75;
  
  paper.origin.x = (bounds.size.width  - width)  / 2;
  paper.origin.y = (bounds.size.height - height) / 2;
  paper.size.width  = width;
  paper.size.height = height;
  
  shadow = paper;
  if( [self isFlipped] == NO)
      shadow.origin.y -= 2;
  else
      shadow.origin.y += 2;
      
  shadow.origin.x += 2;
  
  
  //first draw the shadow
  shadowColor = [[NSColor windowBackgroundColor] shadowWithLevel: 0.5];
  
  [shadowColor set];
  [NSBezierPath fillRect: shadow];
  
  //now draw the paper
  [[NSColor whiteColor] set];
  [NSBezierPath fillRect: paper];
  [[NSColor blackColor] set];
  [NSBezierPath strokeRect: paper];
}

@end

