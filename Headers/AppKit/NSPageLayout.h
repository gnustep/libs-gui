/** <title>NSPageLayout</title>

   <abstract>Standard panel for querying user about page layout.</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Written By: Adam Fedor <fedor@gnu.org>
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

#ifndef _GNUstep_H_NSPageLayout
#define _GNUstep_H_NSPageLayout

#include <AppKit/NSApplication.h>
#include <AppKit/NSPanel.h>

@class NSPrintInfo;
@class NSView;

enum {
  NSPLImageButton,
  NSPLTitleField,
  NSPLPaperNameButton,
  NSPLUnitsButton,
  NSPLWidthField,
  NSPLHeightField,
  NSPLOrientationMatrix,
  NSPLCancelButton,
  NSPLOKButton,
  NSPLPageLayout,
  NSPLScaleField
};

@interface NSApplication (NSPageLayout)
- (void) runPageLayout: (id)sender;
@end

@interface NSPageLayout : NSPanel
{
  NSSize _size;
  NSPrintInfo *_printInfo;
  NSView *_accessoryView;
  id _panel;
  int _picked;
}

//
// Creating an NSPageLayout Instance 
//
+ (NSPageLayout *)pageLayout;

//
// Running the Panel 
//
- (int)runModal;
- (int)runModalWithPrintInfo:(NSPrintInfo *)pInfo;
#ifndef	STRICT_OPENSTEP
- (void)beginSheetWithPrintInfo:(NSPrintInfo *)printInfo
		 modalForWindow:(NSWindow *)docWindow
		       delegate:(id)delegate
		 didEndSelector:(SEL)didEndSelector
		    contextInfo:(void *)contextInfo;
#endif

//
// Customizing the Panel 
//
- (NSView *)accessoryView;
- (void)setAccessoryView:(NSView *)aView;

//
// Updating the Panel's Display 
//
- (void)convertOldFactor:(float *)old
	       newFactor:(float *)new;
- (void)pickedButton:(id)sender;
- (void)pickedOrientation:(id)sender;
- (void)pickedPaperSize:(id)sender;
- (void)pickedUnits:(id)sender;

//
// Communicating with the NSPrintInfo Object 
//
- (NSPrintInfo *)printInfo;
- (void)readPrintInfo;
- (void)writePrintInfo;

@end

#endif // _GNUstep_H_NSPageLayout
