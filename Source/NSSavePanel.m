/*
   NSSavePanel.m

   Standard save panel for saving files

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: October 1999

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

#include <AppKit/IMLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWorkspace.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>

#define _SAVE_PANEL_X_PAD	5
#define _SAVE_PANEL_Y_PAD	4

static NSSavePanel *_gs_gui_save_panel = nil;

//
// NSFileManager extensions
//
@interface NSFileManager (SavePanelExtensions)

- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag;
- (NSArray *) hiddenFilesAtPath: (NSString *)path;

@end

@implementation NSFileManager (SavePanelExtensions)

- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag
{
  NSArray *rawFiles = [self directoryContentsAtPath: path];
  NSArray *hiddenFiles = [self hiddenFilesAtPath: path];
  NSMutableArray *files = [NSMutableArray new];
  NSEnumerator *enumerator = [rawFiles objectEnumerator];
  NSString *filename;

  if (flag || !hiddenFiles)
    return rawFiles;

  while ((filename = (NSString *)[enumerator nextObject]))
    {
      if ([hiddenFiles indexOfObject: filename] == NSNotFound)
	[files addObject: filename];
    }
  return files;
}

- (NSArray *) hiddenFilesAtPath: (NSString *)path
{
  NSString *hiddenList = [path stringByAppendingPathComponent: @".hidden"];
  NSString *hiddenFilesString = [NSString stringWithContentsOfFile: hiddenList];
  return [hiddenFilesString componentsSeparatedByString: @"\n"];
}

@end /* NSFileManager (SavePanelExtensions) */

//
// NSSavePanel private methods
//
@interface NSSavePanel (PrivateMethods)

- (id) _initWithoutGModel;
- (void) _getOriginalSize;
- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag;
- (void) _setHomeDirectory;
- (void) _mountMedia;
- (void) _unmountMedia;

@end /* NSSavePanel (PrivateMethods) */

@implementation NSSavePanel (PrivateMethods)
-(id) _initWithoutGModel
{
  //
  // WARNING: We create the panel sized (308, 317), which is the 
  // minimum size we want it to have.  Then, we resize it at the 
  // comfortable size of (384, 426).
  //
  [super initWithContentRect: NSMakeRect (100, 100, 308, 317)
	 styleMask: (NSTitledWindowMask | NSResizableWindowMask) 
	 backing: 2 defer: YES];
  [self setMinSize: NSMakeSize (308, 317)];
  // The horizontal resize increment has to be divided between 
  // the two columns of the browser.  Avoid non integer values
  [self setResizeIncrements: NSMakeSize (2, 1)];
  [[self contentView] setBounds: NSMakeRect (0, 0, 308, 317)];
  
  _topView = [[NSView alloc] initWithFrame: NSMakeRect (0, 64, 308, 245)];
  [_topView setBounds:  NSMakeRect (0, 64, 308, 245)];
  [_topView setAutoresizingMask: 18];
  [_topView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _topView];
  [_topView release];
  
  _bottomView = [[NSView alloc] initWithFrame: NSMakeRect (0, 0, 308, 64)];
  [_bottomView setBounds:  NSMakeRect (0, 0, 308, 64)];
  [_bottomView setAutoresizingMask: 2];
  [_bottomView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _bottomView];
  [_bottomView release];

  _browser = [[NSBrowser alloc] initWithFrame: NSMakeRect (8, 68, 292, 177)];
  [_browser setDelegate: self];
  [_browser setMaxVisibleColumns: 2]; 
  [_browser setHasHorizontalScroller: YES];
  [_browser setAllowsMultipleSelection: NO];
  [_browser setAutoresizingMask: 18];
  [_browser setTag: NSFileHandlingPanelBrowser];
  [_topView addSubview: _browser];
  [_browser release];

  // NB: We must use NSForm, because in the tag list 
  // there is the tag NSFileHandlingPanelForm

  //  { 
  //  NSForm *_formControl;
  //  
  //  _formControl = [NSForm new];
  //  [_formControl addEntry: @"Name:"];
  //  [_formControl setFrame: NSMakeRect (5, 38, 264, 22)];
  //  [_formControl setEntryWidth: 264];
  // [_formControl setTag: NSFileHandlingPanelForm];
  //  [_bottomView addSubview: _formControl];
  //  _form = [_formControl cellAtIndex: 0];
  //}
  _prompt = [[NSTextField alloc] initWithFrame: NSMakeRect (8, 45, 36, 11)];
  [_prompt setSelectable: NO];
  [_prompt setEditable: NO];
  [_prompt setEnabled: NO];
  [_prompt setBordered: NO];
  [_prompt setBezeled: NO];
  [_prompt setDrawsBackground: NO];
  [_prompt setAutoresizingMask: 0];
  [_bottomView addSubview: _prompt];
  [_prompt release];

  // The gmodel says (44, 40, 226, 22), but that makes the upper border 
  // clipped. 
  _form = [[NSTextField alloc] initWithFrame: NSMakeRect (48, 39, 251, 21)];
  [_form setEditable: YES];
  [_form setBordered: NO];
  [_form setBezeled: YES];
  [_form setDrawsBackground: YES];
  [_form setContinuous: NO];
  [_form setAutoresizingMask: 2];
  // I think the following is not correct, we should have a NSForm instead.
  [_form setTag: NSFileHandlingPanelForm];
  [_bottomView addSubview: _form];
  [_form release];

  {
    NSButton *button;

    button = [[NSButton alloc] initWithFrame: NSMakeRect (43, 6, 26, 26)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Home"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_setHomeDirectory)];
    //    [_form setNextView: button];
    [button setAutoresizingMask: 1];
    [button setTag: NSFileHandlingPanelHomeButton];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (78, 6, 26, 26)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Mount"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_mountMedia)];
    [button setAutoresizingMask: 1];
    [button setTag: NSFileHandlingPanelDiskButton];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (112, 6, 26, 26)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Unmount"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_unmountMedia)];
    [button setAutoresizingMask: 1];
    [button setTag: NSFileHandlingPanelDiskEjectButton];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (148, 6, 71, 26)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setTitle:  @"Cancel"];
    [button setImagePosition: NSNoImage]; 
    [button setTarget: self];
    [button setAction: @selector(cancel:)];
    [button setAutoresizingMask: 1];
    [button setTag: NSFileHandlingPanelCancelButton];
    [_bottomView addSubview: button];
    [button release];
  }
  
  _okButton = [[NSButton alloc] initWithFrame: NSMakeRect (228, 6, 71, 26)];
  [_okButton setBordered: YES];
  [_okButton setButtonType: NSMomentaryPushButton];
  [_okButton setTitle:  @"OK"];
  [_okButton setImagePosition: NSNoImage]; 
  [_okButton setTarget: self];
  [_okButton setAction: @selector(ok:)];
  //    [_okButton setNextView: _form];
  [_okButton setAutoresizingMask: 1];
  [_okButton setTag: NSFileHandlingPanelOKButton];
  [_bottomView addSubview: _okButton];
  [_okButton release];
  
  {
    NSImageView *imageView;
    
    imageView
      = [[NSImageView alloc] initWithFrame: NSMakeRect (8, 261, 48, 48)];
    [imageView setImageFrameStyle: NSImageFrameNone];
    [imageView setImage:
      [[NSApplication sharedApplication] applicationIconImage]];
    [imageView setAutoresizingMask: 8];
    [imageView setTag: NSFileHandlingPanelImageButton];
    [_topView addSubview: imageView];
    [imageView release];
  }
  _titleField
    = [[NSTextField alloc] initWithFrame: NSMakeRect (67, 281, 200, 14)];
  [_titleField setSelectable: NO];
  [_titleField setEditable: NO];
  [_titleField setDrawsBackground: NO];
  [_titleField setBezeled: NO];
  [_titleField setBordered: NO];
  [_titleField setFont: [NSFont messageFontOfSize: 18]];
  [_titleField setAutoresizingMask: 8];
  [_titleField setTag: NSFileHandlingPanelTitleField];
  [_topView addSubview: _titleField];
  [_titleField release];
  { 
    NSBox *bar;
    bar = [[NSBox alloc] initWithFrame: NSMakeRect (0, 252, 308, 2)];
    [bar setBorderType: NSGrooveBorder];
    [bar setTitlePosition: NSNoTitle];
    [bar setAutoresizingMask: 10];
    [_topView addSubview: bar];
    [bar release];
  }
  [self setMinSize: NSMakeSize (308, 317)];
  [self setContentSize: NSMakeSize (384, 426)];
  return self;
}

- (void) _getOriginalSize
{
  _originalMinSize = [self minSize];
  _originalSize = [self frame].size;
}

- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag
{
  NSString	*standardizedPath = [path stringByStandardizingPath];
  BOOL		isDir;

  // check that path exists, and if so save it
  if (standardizedPath
    && [[NSFileManager defaultManager]
	 fileExistsAtPath: path isDirectory: &isDir] && isDir)
    {
      if (_lastValidPath)
	[_lastValidPath autorelease];
      _lastValidPath = [standardizedPath retain];
    }
  // set the path in the browser
  if (_browser && flag)
    [_browser setPath: _lastValidPath];
}

- (void) _setHomeDirectory
{
  [self setDirectory: NSHomeDirectory()];
}

- (void) _mountMedia
{
  [[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
}

- (void) _unmountMedia
{
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self directory]];
}

@end /* NSSavePanel (PrivateMethods) */

//
// NSSavePanel methods
//
@implementation NSSavePanel

+ (id) savePanel
{
  if (!_gs_gui_save_panel)
    _gs_gui_save_panel = [[NSSavePanel alloc] init];

  [_gs_gui_save_panel setDirectory: [[NSFileManager defaultManager] 
				      currentDirectoryPath]];
  [_gs_gui_save_panel setPrompt: @"Name:"];
  [_gs_gui_save_panel setTitle: @"Save"];
  [_gs_gui_save_panel setRequiredFileType: @""];
  [_gs_gui_save_panel setTreatsFilePackagesAsDirectories: NO];
  [_gs_gui_save_panel setDelegate: nil];
  [_gs_gui_save_panel setAccessoryView: nil];

  return _gs_gui_save_panel;
}
//

// If you do a simple -init, we initialize the panel with
// the system size/mask/appearance/subviews/etc.  If you do more
// complicated initializations, you get a simple panel from super.
-(id) init
{
  //  if (![GMModel loadIMFile: @"SavePanel" owner: self]);
  [self _initWithoutGModel];
  
  _requiredFileType = nil;
  _lastValidPath = nil;
  _delegate = nil;
  
  _treatsFilePackagesAsDirectories = NO;
  _delegateHasCompareFilter = NO;
  _delegateHasFilenameFilter = NO;
  _delegateHasValidNameFilter = NO;

  _fullFileName = nil;
  [self _getOriginalSize];
  return self;
}

- (void) setAccessoryView: (NSView *)aView
{
  NSView *contentView = [self contentView];
  NSRect addedFrame, bottomFrame, topFrame;
  NSSize contentSize, contentMinSize;
  NSSize accessoryViewSize;

  if (aView == _accessoryView)
    return;
  
  // Remove accessory view
  if (_accessoryView)
    {
      accessoryViewSize = [_accessoryView frame].size;
      [_accessoryView removeFromSuperview];
      contentSize = [[self contentView] frame].size;
      contentSize.height -= (accessoryViewSize.height 
			     + (_SAVE_PANEL_Y_PAD * 2));
      [self setMinSize: _originalMinSize];
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: contentSize];
      [_topView setAutoresizingMask: 18];
      [_bottomView setAutoresizingMask: 2];
      topFrame = [_topView frame];
      topFrame.origin.y -= (accessoryViewSize.height + (_SAVE_PANEL_Y_PAD * 2));
      [_topView setFrameOrigin: topFrame.origin];
      // Restore original size
      [self setMinSize: _originalMinSize];
      [self setContentSize: _originalSize];
    }

  _accessoryView = aView;
  
  if (_accessoryView)
    {
      // The new accessory view must not play tricks in the vertical direction
      [_accessoryView setAutoresizingMask: ([aView autoresizingMask] 
					    & !NSViewHeightSizable 
					    & !NSViewMaxYMargin
					    & !NSViewMinYMargin)];  
      //
      // Resize ourselves to make room for the accessory view
      //
      addedFrame = [_accessoryView frame];
      contentSize = _originalSize;
      contentSize.height += (addedFrame.size.height + (_SAVE_PANEL_Y_PAD * 2));
      if ((addedFrame.size.width + (_SAVE_PANEL_X_PAD * 2)) > contentSize.width)
	contentSize.width = (addedFrame.size.width + (_SAVE_PANEL_X_PAD * 2));  
      contentMinSize = _originalMinSize;
      contentMinSize.height += (addedFrame.size.height 
				+ (_SAVE_PANEL_Y_PAD * 2));
      if ((addedFrame.size.width + (_SAVE_PANEL_X_PAD * 2)) 
	  > contentMinSize.width)
	contentMinSize.width = (addedFrame.size.width 
				+ (_SAVE_PANEL_X_PAD * 2));  

      // Our views should resize horizontally, but not vertically
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: contentSize];
      // Restore the original autoresizing masks
      [_topView setAutoresizingMask: 18];
      [_bottomView setAutoresizingMask: 2];

      // Set new min size
      [self setMinSize: contentMinSize];

      //
      // Pack the Views
      //

      // BottomView is ready
      bottomFrame = [_bottomView frame];

      // AccessoryView
      addedFrame.origin.x = (contentSize.width - addedFrame.size.width)/2;
      addedFrame.origin.y =  bottomFrame.origin.y + bottomFrame.size.height 
                                 + _SAVE_PANEL_Y_PAD;
      [_accessoryView setFrameOrigin: addedFrame.origin];

      // TopView
      topFrame = [_topView frame];
      topFrame.origin.y += (addedFrame.size.height + (_SAVE_PANEL_Y_PAD * 2));
      [_topView setFrameOrigin: topFrame.origin];
      
      // Add the accessory view
      [contentView addSubview:_accessoryView];
    }
}

- (void) setTitle: (NSString *)title
{
  [super setTitle:@""];
  [_titleField setStringValue: title];
  // TODO: Improve on the following.
  [_titleField sizeToFit];
}

- (NSString *) title
{
  return [_titleField stringValue];
}

- (void) setPrompt: (NSString *)prompt
{
  // [_form setTitle: prompt];
  [_prompt setStringValue: prompt];
}

- (NSString *) prompt
{
  // return [_form title];
  return [_prompt stringValue];
}

- (NSView *) accessoryView
{
  return _accessoryView;
}

- (void) setDirectory: (NSString *)path
{
  [self _setDirectory: path updateBrowser: YES];
}

- (void) setRequiredFileType: (NSString *)fileType
{
  ASSIGN(_requiredFileType, fileType);
}

- (NSString *) requiredFileType
{
  return _requiredFileType;
}

- (BOOL) treatsFilePackagesAsDirectories
{
  return _treatsFilePackagesAsDirectories;
}

- (void) setTreatsFilePackagesAsDirectories:(BOOL) flag
{
  _treatsFilePackagesAsDirectories = flag;
}

- (void) validateVisibleColumns
{
  [_browser validateVisibleColumns];
}

- (int) runModal
{
  return [self runModalForDirectory: @"" file: @""];
}

- (int) runModalForDirectory:(NSString *) path file:(NSString *) filename
{
  if (path == nil || filename == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"NSSavePanel runModalForDirectory:file: "
		 @"does not accept nil arguments."];

  [self setDirectory: path];
  // TODO: Should set it in the browser, if it's there! 
  [_form setStringValue: filename];

  return [NSApp runModalForWindow: self];
}

- (NSString *) directory
{
  if (_browser != nil)
    return [_browser pathToColumn: [_browser lastColumn]];
  else
    return _lastValidPath;
}

- (NSString *) filename
{
  if (_fullFileName == nil)
   return @"";

  if (_requiredFileType == nil)
    return _fullFileName;

  if ([_requiredFileType isEqual: @""] == YES)
    return _fullFileName;
					    
  // add filetype extension only if the filename does not include it already
  if ([[_fullFileName pathExtension] isEqual: _requiredFileType] == YES)
    return _fullFileName;
  else
    return [_fullFileName stringByAppendingPathExtension: _requiredFileType];
}

- (void) cancel: (id)sender
{
  _fullFileName = nil;
  [NSApp stopModalWithCode: NSCancelButton];
  [self orderOut: self];
}

- (void) ok: (id)sender
{
  if (_delegateHasValidNameFilter)
    if (![_delegate panel:self isValidFilename: [self filename]])
      return;

  [NSApp stopModalWithCode: NSOKButton];
  [self orderOut: self];
}

- (void) selectText: (id)sender
{
}

- (void) setDelegate: (id)aDelegate
{
  if (aDelegate == nil)
    {
      _delegate = nil;
      _delegateHasCompareFilter = NO;
      _delegateHasFilenameFilter = NO;
      _delegateHasValidNameFilter = NO;
      return;
    }

  _delegateHasCompareFilter
    = [aDelegate respondsToSelector:
      @selector(panel:compareFilename:with:caseSensitive:)] ? YES : NO;
  _delegateHasFilenameFilter
    = [aDelegate respondsToSelector:
      @selector(panel:shouldShowFilename:)] ? YES : NO;
  _delegateHasValidNameFilter
    = [aDelegate respondsToSelector:
      @selector(panel:isValidFilename:)] ? YES : NO;

  _delegate = aDelegate;
  [super setDelegate: aDelegate];
}

//
// NSCoding protocol
//
- (id) initWithCoder: (NSCoder *)aCoder
{
  // TODO

  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  // TODO
}
@end

//
// NSSavePanel browser delegate methods
//
@interface NSSavePanel (BrowserDelegate)
- (void) browser: (id)sender
createRowsForColumn: (int)column
        inMatrix: (NSMatrix *)matrix;

- (BOOL) browser: (NSBrowser *)sender
   isColumnValid: (int)column;

- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column;

- (void) browser:(NSBrowser *)sender
 willDisplayCell:(id)cell
           atRow:(int)row
          column:(int)column;
@end 

@implementation NSSavePanel (BrowserDelegate)
//
// TODO: Add support for delegate's shouldShowFile: 
// Is it certainly possible to simplify things so that NSOpenPanel 
// does not have to rewrite all the following code, but some 
// inheritance is possible.
//
- (void) browser: (id)sender
    createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString	*path = [sender pathToColumn: column], *file;
  NSArray	*files = [fm directoryContentsAtPath: path showHidden: NO];
  NSArray       *extArray = [NSArray arrayWithObjects: @"app", 
				     @"bundle", @"debug", @"profile", nil];
  unsigned	i, count;
  BOOL		exists, isDir;
  NSBrowserCell *cell;
  NSString      *theFile;
  
  // if array is empty, just return (nothing to display)
  if ([files lastObject] == nil)
    return;

  // sort list of files to display
  if (_delegateHasCompareFilter == YES)
    {
      int compare(id elem1, id elem2, void *context)
      {
	return (int)[_delegate panel: self
		     compareFilename: elem1
				with: elem2
		       caseSensitive: YES];
      }
      files = [files sortedArrayUsingFunction: compare context: nil];
    }
  else
    files = [files sortedArrayUsingSelector: @selector(compare:)];

  count = [files count];
  [matrix renewRows: count columns: 1];
  for (i = 0; i < count; i++)
    {
      theFile = [files objectAtIndex: i];
      
      cell = [matrix cellAtRow: i column: 0];
      [cell setStringValue: theFile];
      
      file = [path stringByAppendingPathComponent: theFile];
      exists = [fm fileExistsAtPath: file
		   isDirectory: &isDir];
      
      if (_treatsFilePackagesAsDirectories == NO && isDir == YES)
	{
	  if ([extArray containsObject: [theFile pathExtension]] == YES)
	    isDir = NO;
	}
      
      if (exists == YES && isDir == NO)
	[cell setLeaf: YES];
      else
	[cell setLeaf: NO];
    }
}

- (BOOL) browser: (NSBrowser *)sender
   isColumnValid: (int)column
{
  NSArray	*cells = [[sender matrixInColumn: column] cells];
  unsigned	count = [cells count], i;
  
  // iterate through the cells asking the delegate if each filename is valid
  // if it says no for any filename, the column is not valid
  if (_delegateHasFilenameFilter == YES)
    for (i = 0; i < count; i++)
      {
	if (![_delegate panel: self shouldShowFilename:
			  [[cells objectAtIndex: i] stringValue]])
	  return NO;
      }

  return YES;
}

- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column
{
  [self _setDirectory: [sender pathToColumn: [_browser lastColumn]] 
	updateBrowser: NO];
  
  if ([[sender selectedCell] isLeaf])
    {
      ASSIGN (_fullFileName, [sender path]);
      [_form setStringValue: title];
    }
  return YES;
}

- (void)browser:(NSBrowser *)sender
  willDisplayCell:(id)cell
  atRow:(int)row
  column:(int)column
{
}
@end /* NSSavePanel */



