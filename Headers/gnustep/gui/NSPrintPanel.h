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
  NSPPSaveButton = 4,
  NSPPPreviewButton,
  NSFaxButton,
  NSPPTitleField,
  NSPPImageButton,
  NSPPNameTitle,
  NSPPNameField,
  NSPPNoteTitle,
  NSPPNoteField,
  NSPPStatusTitle,
  NSPPStatusField,
  NSPPCopiesField,
  NSPPPageChoiceMatrix,
  NSPPPageRangeFrom,
  NSPPPageRangeTo,
  NSPPScaleField,
  NSPPOptionsButton,
  NSPPPaperFeedButton,
  NSPPLayoutButton
};

@interface NSPrintPanel : NSPanel
{
  id _cancelButton;
  id _copiesField;
  id _faxButton;
  id _fromRangeForm;
  id _pageMatrix;
  id _paperButton;
  id _previewButton;
  id _printButton;
  id _printForm;
  id _resButton;
  id _saveButton;
  id _toRangeForm;
  id _panelWindow;

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
