/*
   NSSavePanel.h

   Standard save panel for saving files

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Daniel B?hringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel B?hringer integrated into Scott Christley's preliminary
   implementation by Felipe A. Rodriguez <far@ix.netcom.com> 

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef _GNUstep_H_NSSavePanel
#define _GNUstep_H_NSSavePanel

#include <Foundation/NSCoder.h>
#include <Foundation/NSSet.h>

#include <AppKit/NSBrowser.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSTextField.h>

@class NSString;
@class NSURL;

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

@interface NSSavePanel : NSPanel <NSCoding>
{
  NSView *_accessoryView;
  NSView *_bottomView;
  NSBrowser *_browser;
  NSForm *_form;
  NSButton *_okButton;
  NSTextField *_titleField;
  NSView *_topView;

  NSSize _originalMinSize;
  NSSize _originalSize;

  NSString *_requiredFileType;
  NSString *_directory;
  NSString *_fullFileName;

  BOOL _treatsFilePackagesAsDirectories;
  BOOL _delegateHasCompareFilter;
  BOOL _delegateHasShowFilenameFilter;
  BOOL _delegateHasValidNameFilter;
  BOOL _delegateHasUserEnteredFilename;

  // YES when we stopped because the user pressed 'OK'
  BOOL _OKButtonPressed;
}

/*
 * Getting the NSSavePanel shared instance
 */
+ (NSSavePanel *) savePanel;

/*
 * Customizing the NSSavePanel
 */
- (void) setAccessoryView: (NSView *)aView;
- (NSView *) accessoryView;

/*
 * Sets the title of the NSSavePanel to title. By default, 
 * 'Save' is the title string. If you adapt the NSSavePanel 
 * for other uses, its title should reflect the user action 
 * that brings it to the screen.
 */
- (void) setTitle: (NSString *)title;
- (NSString *) title;
- (void) setPrompt: (NSString *)prompt;

/*
 * Returns the prompt of the Save panel field that holds 
 * the current pathname or file name. By default this 
 * prompt is 'Name: '. *Note - currently no prompt is shown.
 */
- (NSString *) prompt;

/*
 * Setting Directory and File Type
 */
- (NSString *) requiredFileType;

/*
 * Sets the current path name in the Save panel's browser. 
 * The path argument must be an absolute path name.
 */
- (void) setDirectory: (NSString *)path;

/*
 * Specifies the type, a file name extension to be appended to 
 * any selected files that don't already have that extension;
 * The argument type should not include the period that begins 
 * the extension.  Invoke this method each time the Save panel 
 * is used for another file type within the application.
 */
- (void) setRequiredFileType: (NSString *)fileType;

/*
 * Sets the NSSavePanel's behavior for displaying file packages 
 * (for example, MyApp.app) to the user.  If flag is YES, the 
 * user is shown files and subdirectories within a file 
 * package.  If NO, the NSSavePanel shows each file package as 
 * a file, thereby giving no indication that it is a directory.
 */
- (void) setTreatsFilePackagesAsDirectories: (BOOL)flag;
- (BOOL) treatsFilePackagesAsDirectories;

/*
 * Validates and possibly reloads the browser columns visible 
 * in the Save panel by causing the delegate method 
 * panel: shouldShowFilename: to be invoked. One situation in 
 * which this method would find use is whey you want the 
 * browser show only files with certain extensions based on the 
 * selection made in an accessory-view pop-up list.  When the 
 * user changes the selection, you would invoke this method to
 * revalidate the visible columns. 
 */
- (void) validateVisibleColumns;

/*
 * Running the NSSavePanel
 */

/*
 * Initializes the panel to the directory specified by path 
 * and, optionally, the file specified by filename, then 
 * displays it and begins its modal event loop; path and 
 * filename can be empty strings, but cannot be nil.  The 
 * method invokes Application's runModalForWindow: method with 
 * self as the argument.  Returns NSOKButton (if the user 
 * clicks the OK button) or NSCancelButton (if the user clicks 
 * the Cancel button).	Do not invoke filename or directory 
 * within a modal loop because the information that these 
 * methods fetch is updated only upon return.
 */
- (int) runModalForDirectory: (NSString *)path file: (NSString *)filename;
- (int) runModal;

#ifndef	STRICT_OPENSTEP
- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)filename
	    relativeToWindow: (NSWindow*)window;
- (void) beginSheetForDirectory: (NSString *)path
			   file: (NSString *)filename
		 modalForWindow: (NSWindow *)docWindow
		  modalDelegate: (id)delegate
		 didEndSelector: (SEL)didEndSelector
		    contextInfo: (void *)contextInfo;

- (NSURL *) URL;
#endif

/*
 * Reading Save Information
 */

/*
 * Returns the absolute pathname of the directory currently 
 * shown in the panel.	Do not invoke this method within a 
 * modal session (runModal or runModalForDirectory: file: )
 * because the directory information is only updated just 
 * before the modal session ends.
 */
- (NSString *) directory;
- (NSString *) filename;

/*
 * Target and Action Methods
 */
- (void) ok: (id)sender;	// target/action of panel's OK button.
- (void) cancel: (id)sender;	// target/action of panel's cancel button 

/*
 * Responding to User Input
 */
- (void) selectText: (id)sender;
@end

/*
 * Methods Implemented by the Delegate 
 */
@interface NSObject (NSSavePanelDelegate)
/*
 * The NSSavePanel sends this message just before the end of a 
 * modal session for each file name displayed or selected 
 * (including file names in multiple selections).  The delegate 
 * determines whether it wants the file identified by filename; 
 * it returns YES if the file name is valid, or NO if the 
 * NSSavePanel should stay in its modal loop and wait for the 
 * user to type in or select a different file name or names. If 
 * the delegate refuses a file name in a multiple selection, 
 * none of the file names in the selection are accepted.
 */
- (BOOL) panel: (id)sender isValidFilename: (NSString*)filename;
- (NSComparisonResult) panel: (id)sender
	     compareFilename: (NSString *)filename1
			with: (NSString *)filename2
	       caseSensitive: (BOOL)caseSensitive;	 
- (BOOL) panel: (id)sender shouldShowFilename: (NSString *)filename;
- (NSString *)panel: (id)sender
userEnteredFilename: (NSString *)fileName
          confirmed: (BOOL)okFlag;
@end

#endif /* _GNUstep_H_NSSavePanel */
