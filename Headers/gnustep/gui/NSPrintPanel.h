/* 
   NSPrintPanel.h

   Standard panel to query users for info on a print job

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSPrintPanel
#define _GNUstep_H_NSPrintPanel

#include <AppKit/NSPanel.h>

@class NSView;
@class NSPrintInfo;

enum {
  NSPPSaveButton 	= 3,
  NSPPPreviewButton	= 4,
  NSFaxButton		= 5,
  NSPPTitleField	= 20,
  NSPPImageButton	= 21,
  NSPPNameTitle		= 22,
  NSPPNameField		= 23,
  NSPPNoteTitle		= 24,
  NSPPNoteField		= 25,
  NSPPStatusTitle	= 26,
  NSPPStatusField	= 27,
  NSPPCopiesField	= 28,
  NSPPPageChoiceMatrix	= 29,
  NSPPPageRangeFrom	= 30,
  NSPPPageRangeTo	= 31,
  NSPPScaleField	= 32,
  NSPPOptionsButton	= 33,
  NSPPPaperFeedButton	= 34,
  NSPPLayoutButton	= 35,
  NSPPResolutionButton	= 36
};

@interface NSPrintPanel : NSPanel
{
  id _panel;
  id _accessoryView;
  id _savePath;
  int _picked;
  NSRange _pages;
}

//
// Creating an NSPrintPanel 
//
+ (NSPrintPanel *)printPanel;

//
// Customizing the Panel 
//
- (void)setAccessoryView:(NSView *)aView;
- (NSView *)accessoryView;

//
// Running the Panel 
//
- (int) runModal;
#ifndef STRICT_OPENSTEP
- (void) beginSheetWithPrintInfo: (NSPrintInfo *)printInfo 
		  modalForWindow: (NSWindow *)docWindow 
			delegate: (id)delegate 
		  didEndSelector: (SEL)didEndSelector 
		     contextInfo: (void *)contextInfo;
#endif

//
// Updating the Panel's Display 
//
- (void)pickedButton:(id)sender;
- (void)pickedAllPages:(id)sender;
- (void)pickedLayoutList:(id)sender;

//
// Communicating with the NSPrintInfo Object 
//
- (void)updateFromPrintInfo;
- (void)finalWritePrintInfo;

@end

#endif // _GNUstep_H_NSPrintPanel
