/* 
   NSSavePanel.h

   Standard save panel for saving files

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

#ifndef _GNUstep_H_NSSavePanel
#define _GNUstep_H_NSSavePanel

#include <Foundation/NSCoder.h>

@class NSString;
@class NSView;

enum {
  NSFileHandlingPanelImageButton,
  NSFileHandlingPanelTitleField,
  NSFileHandlingPanelBrowser,
  NSFileHandlingPanelCancelButton,
  NSFileHandlingPanelOKButton,
  NSFileHandlingPanelForm, 
  NSFileHandlingPanelHomeButton, 
  NSFileHandlingPanelDiskButton, 
  NSFileHandlingPanelDiskEjectButton 
};

// Should be subclassed from NSPanel but
//   we are using the WIN32 common dialog
@interface NSSavePanel : NSObject <NSCoding>
{
  // Attributes
  NSView *accessory_view;
  NSString *panel_title;
  NSString *panel_prompt;
  NSString *directory;
  NSString *file_name;
  NSString *required_type;
  BOOL file_package;
  id delegate;

  // Reserved for back-end use
  void *be_save_reserved;
}

//
// Creating an NSSavePanel 
//
+ (NSSavePanel *)savePanel;

//
// Customizing the NSSavePanel 
//
- (void)setDefaults;
- (void)setAccessoryView:(NSView *)aView;
- (NSView *)accessoryView;
- (void)setTitle:(NSString *)title;
- (NSString *)title;
- (void)setPrompt:(NSString *)prompt;
- (NSString *)prompt;

//
// Setting Directory and File Type 
//
- (NSString *)requiredFileType;
- (void)setDirectory:(NSString *)path;
- (void)setRequiredFileType:(NSString *)type;
- (void)setTreatsFilePackagesAsDirectories:(BOOL)flag;
- (BOOL)treatsFilePackagesAsDirectories;

//
// Running the NSSavePanel 
//
- (int)runModalForDirectory:(NSString *)path
		       file:(NSString *)filename;
- (int)runModal;

//
// Reading Save Information 
//
- (NSString *)directory;
- (NSString *)filename;

//
// Target and Action Methods 
//
- (void)ok:(id)sender;
- (void)cancel:(id)sender;

//
// Responding to User Input 
//
- (void)selectText:(id)sender;

//
// Setting the Delegate 
//
- (void)setDelegate:(id)anObject;

//
// Methods Implemented by the Delegate 
//
- (NSComparisonResult)panel:(id)sender
	    compareFilename:(NSString *)filename1
		       with:(NSString *)filename2
	      caseSensitive:(BOOL)caseSensitive;	 
- (BOOL)panel:(id)sender
  shouldShowFilename:(NSString *)filename;
- (BOOL)panel:(id)sender
  isValidFilename:(NSString*)filename;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSSavePanel
