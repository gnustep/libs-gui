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

#include <AppKit/NSPanel.h>

@class NSString;
@class NSURL;
@class NSBrowser;
@class NSButton;
@class NSForm;
@class NSTextField;
@class NSView;

enum {
  NSFileHandlingPanelCancelButton = NSCancelButton,
  NSFileHandlingPanelOKButton = NSOKButton,
  NSFileHandlingPanelImageButton,
  NSFileHandlingPanelTitleField,
  NSFileHandlingPanelBrowser,
  NSFileHandlingPanelForm,
  NSFileHandlingPanelHomeButton,
  NSFileHandlingPanelDiskButton,
  NSFileHandlingPanelDiskEjectButton
};

@interface NSSavePanel : NSPanel
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
  BOOL _allowsOtherFileTypes;
  BOOL _canCreateDirectories;
  BOOL _canSelectHiddenExtension;
  BOOL _isExtensionHidden;

  BOOL _delegateHasCompareFilter;
  BOOL _delegateHasShowFilenameFilter;
  BOOL _delegateHasValidNameFilter;
  BOOL _delegateHasUserEnteredFilename;
  BOOL _delegateHasDirectoryDidChange;
  BOOL _delegateHasSelectionDidChange;

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
- (void) setTitle: (NSString *)title;
- (NSString *) title;
- (void) setPrompt: (NSString *)prompt;
- (NSString *) prompt;

#ifndef	STRICT_OPENSTEP
- (void) setNameFieldLabel: (NSString *)label;
- (NSString *) nameFieldLabel;
- (void) setMessage: (NSString *)message;
- (NSString *) message;

/*
 * Hidding extensions
 */
- (void) setCanSelectHiddenExtension: (BOOL) flag;
- (BOOL) canSelectHiddenExtension;
- (BOOL) isExtensionHidden;
- (void) setExtensionHidden: (BOOL) flag;
#endif

/*
 * Setting Directory and File Type
 */
- (NSString *) requiredFileType;
- (void) setDirectory: (NSString *)path;
- (void) setRequiredFileType: (NSString *)fileType;

#ifndef	STRICT_OPENSTEP
- (void) setAllowedFileTypes: (NSArray *)types;
- (void) setAllowsOtherFileTypes: (BOOL)flag;
- (NSArray *) allowedFileTypes;
- (BOOL) allowsOtherFileTypes;
#endif

- (void) setTreatsFilePackagesAsDirectories: (BOOL)flag;
- (BOOL) treatsFilePackagesAsDirectories;

- (void) validateVisibleColumns;

#ifndef	STRICT_OPENSTEP
- (void) setCanCreateDirectories: (BOOL)flag;
- (BOOL) canCreateDirectories;
#endif

/*
 * Running the NSSavePanel
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
#endif

/*
 * Reading Save Information
 */
- (NSString *) directory;
- (NSString *) filename;
#ifndef	STRICT_OPENSTEP
- (NSURL *) URL;
- (BOOL) isExpanded;
#endif

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
/**
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

#ifndef	STRICT_OPENSTEP
- (void) panel: (id)sender willExpand: (BOOL)expanding;
- (void) panelSelectionDidChange: (id)sender;
- (void) panel: (id)sender directoryDidChange: (NSString *)path;
#endif
@end

#endif /* _GNUstep_H_NSSavePanel */
