/*
   NSSavePanel.m

   Standard save panel for saving files

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

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
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>

#define _SAVE_PANEL_X_PAD	5
#define _SAVE_PANEL_Y_PAD	4

// After loading the save panel, we store in these 
// variables its size (used when restoring the panel
// after removing an accessory view)
static NSSize _savePanelSize;
static float _savePanelTopViewOriginY;

static NSSavePanel *gnustep_gui_save_panel = nil;

//
// NSFileManager extensions
//
@interface NSFileManager (SavePanelExtensions)

- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag;
- (NSArray *) hiddenFilesAtPath: (NSString *)path;
- (BOOL) fileExistsAtPath: (NSString *)path
	      isDirectory: (BOOL *)flag1
		isPackage: (BOOL *)flag2;

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

- (BOOL) fileExistsAtPath: (NSString *)path
	      isDirectory: (BOOL *)isDir
		isPackage: (BOOL *)isPackage
{
  NSArray *extArray;

  extArray = [NSArray arrayWithObjects:
    @"app", @"bundle", @"debug", @"profile", nil];

  if ([extArray indexOfObject: [path pathExtension]] == NSNotFound)
    *isPackage = NO;
  else
    *isPackage = YES;
  return [self fileExistsAtPath: path isDirectory: isDir];
}

@end /* NSFileManager (SavePanelExtensions) */

//
// NSSavePanel browser delegate methods
//
@implementation NSSavePanel (BrowserDelegate)

- (void) browser: (id)sender
    createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString	*path = [sender pathToColumn: column], *file;
  NSArray	*files = [fm directoryContentsAtPath: path showHidden: NO];
  unsigned	i, count;
  BOOL		exists, isDir, isPackage;

  NSDebugLLog(@"NSSavePanel",
    @"NSSavePanel -browser: createRowsForColumn: %d inMatrix:", column);

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
  for (i = 0; i < count; i++)
    {
      NSBrowserCell *cell;

      //if (i != 0)
	[matrix insertRow: i];

      cell = [matrix cellAtRow: i column: 0];
      [cell setStringValue: [files objectAtIndex: i]];

      file = [path stringByAppendingPathComponent: [files objectAtIndex: i]];
      exists = [fm fileExistsAtPath: file
			isDirectory: &isDir
			  isPackage: &isPackage];

      if (isPackage == YES && _treatsFilePackagesAsDirectories == NO)
	isDir = NO;

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
  
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -browser: isColumnValid:");

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
       selectRow: (int)row
	inColumn: (int)column
{
  NSDebugLLog(@"NSSavePanel",
    @"NSSavePanel -browser: selectRow:%d inColumn:%d", row, column);
  return YES;
}

- (void) browser: (id)sender
 willDisplayCell: (id)cell
	   atRow: (int)row
	  column: (int)column
{
  NSDebugLLog(@"NSSavePanel",
    @"NSSavePanel -browser: willDisplayCell: atRow: column:");
}

@end /* NSSavePanel (BrowserDelegate) */

//
// NSSavePanel private methods
//
@interface NSSavePanel (PrivateMethods)

- (id) _initWithoutGModel;
- (void) _getOriginalSize;
- (void) _setDefaults;
- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag;

@end /* NSSavePanel (PrivateMethods) */

@implementation NSSavePanel (PrivateMethods)
-(id) _initWithoutGModel
{
  [super initWithContentRect: NSMakeRect (100, 100, 280, 350)
	 styleMask: (NSTitledWindowMask | NSResizableWindowMask) 
	 backing: 2 defer: YES];
  [self setMinSize: NSMakeSize (280, 350)];
  // The horizontal resize increment has to be divided between 
  // the two columns of the browser.  If it is odd, we would get 
  // a non integer pixel origin of the second column, and the back-end 
  // could have problems in drawing it.
  [self setResizeIncrements: NSMakeSize (2, 1)];
  [[self contentView] setBounds: NSMakeRect (0, 0, 280, 350)];
  
  _topView = [[NSView alloc] initWithFrame: NSMakeRect (0, 60, 280, 290)];
  [_topView setBounds:  NSMakeRect (0, 0, 280, 290)];
  [_topView setAutoresizingMask: 18];
  [_topView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _topView];
  [_topView release];
  
  _bottomView = [[NSView alloc] initWithFrame: NSMakeRect (0, 0, 280, 60)];
  [_bottomView setBounds:  NSMakeRect (0, 0, 280, 60)];
  [_bottomView setAutoresizingMask: 2];
  [_bottomView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _bottomView];
  [_bottomView release];

  _browser = [[NSBrowser alloc] initWithFrame: NSMakeRect (10, 10, 260, 196)];
  [_browser setDelegate: self];
  [_browser setMaxVisibleColumns: 2]; 
  [_browser setHasHorizontalScroller: YES];
  [_browser setAllowsMultipleSelection: NO];
  [_browser setTarget: self];
  [_browser setAction: @selector(_processCellSelection)];
  [_browser setAutoresizingMask: 18];
  [_topView addSubview: _browser];
  [_browser release];

  //  { 
  //  NSForm *_formControl;
  //  
  //  _formControl = [NSForm new];
  //  [_formControl addEntry: @"Name:"];
  //  [_formControl setFrame: NSMakeRect (5, 38, 264, 22)];
  //  [_formControl setEntryWidth: 264];
  //  [_bottomView addSubview: _formControl];
  //  _form = [_formControl cellAtIndex: 0];
  //}
  _prompt = [[NSTextField alloc] initWithFrame: NSMakeRect (5, 38, 38, 18)];
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
  _form = [[NSTextField alloc] initWithFrame: NSMakeRect (44, 38, 226, 22)];
  [_form setEditable: YES];
  [_form setBordered: NO];
  [_form setBezeled: YES];
  [_form setDrawsBackground: YES];
  [_form setContinuous: NO];
  [_form setAutoresizingMask: 2];
  [_bottomView addSubview: _form];
  [_form release];

  {
    NSButton *button;

    button = [[NSButton alloc] initWithFrame: NSMakeRect (18, 5, 28, 28)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Home"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_setHomeDirectory)];
    //    [_form setNextView: button];
    [button setAutoresizingMask: 1];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (52, 5, 28, 28)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Mount"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_mountMedia)];
    [button setAutoresizingMask: 1];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (86, 5, 28, 28)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setImage:  [NSImage imageNamed: @"common_Unmount"]]; 
    [button setImagePosition: NSImageOnly]; 
    [button setTarget: self];
    [button setAction: @selector(_unmountMedia)];
    [button setAutoresizingMask: 1];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (122, 5, 70, 28)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setTitle:  @"Cancel"];
    [button setImagePosition: NSNoImage]; 
    [button setTarget: self];
    [button setAction: @selector(cancel:)];
    [button setAutoresizingMask: 1];
    [_bottomView addSubview: button];
    [button release];

    button = [[NSButton alloc] initWithFrame: NSMakeRect (200, 5, 70, 28)];
    [button setBordered: YES];
    [button setButtonType: NSMomentaryPushButton];
    [button setTitle:  @"OK"];
    [button setImagePosition: NSNoImage]; 
    [button setTarget: self];
    [button setAction: @selector(ok:)];
    //    [button setNextView: _form];
    [button setAutoresizingMask: 1];
    [_bottomView addSubview: button];
    [button release];
  }
  {
    NSImageView *imageView;

    imageView
      = [[NSImageView alloc] initWithFrame: NSMakeRect (8, 218, 64, 64)];
    [imageView setImageFrameStyle: NSImageFrameNone];
    [imageView setImage:
      [[NSApplication sharedApplication] applicationIconImage]];
    [imageView setAutoresizingMask: 8];
    [_topView addSubview: imageView];
    [imageView release];
  }
  _titleField
    = [[NSTextField alloc] initWithFrame: NSMakeRect (80, 240, 224, 21)];
  [_titleField setSelectable: NO];
  [_titleField setEditable: NO];
  [_titleField setDrawsBackground: NO];
  [_titleField setBezeled: NO];
  [_titleField setBordered: NO];
  [_titleField setFont: [NSFont messageFontOfSize: 18]];
  [_titleField setAutoresizingMask: 8];
  [_topView addSubview: _titleField];
  [_titleField release];
  { 
    NSBox *bar;
    bar = [[NSBox alloc] initWithFrame: NSMakeRect (0, 210, 310, 2)];
    [bar setBorderType: NSGrooveBorder];
    [bar setTitlePosition: NSNoTitle];
    [bar setAutoresizingMask: 10];
    [_topView addSubview: bar];
    [bar release];
  }
  return self;
}

- (void) _getOriginalSize
{
  _savePanelSize = [self frame].size;
  _savePanelTopViewOriginY = [_topView frame].origin.y;
}

- (void) _setDefaults
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_setDefaults");
  [self setDirectory: [[NSFileManager defaultManager] currentDirectoryPath]];
  [self setPrompt: @"Name:"];
  [self setTitle: @"Save"];
  [self setRequiredFileType: @""];
  [self setTreatsFilePackagesAsDirectories: NO];
  [self setDelegate: nil];
  [self setAccessoryView: nil];
}

- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag
{
  NSString	*standardizedPath = [path stringByStandardizingPath];
  BOOL		isDir;

  NSDebugLLog(@"NSSavePanel",
    @"NSSavePanel -_setDirectory: %@ updateBrowser:", path);

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

- (void) _processCellSelection
{
  id	selectedCell = [_browser selectedCell];

  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_processCellSelection");

  [self _setDirectory:
    [_browser pathToColumn: [_browser lastColumn]] updateBrowser: NO];

  if ([selectedCell isLeaf])
    [_form setStringValue: [selectedCell stringValue]];
}

- (void) _setHomeDirectory
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_setHomeDirectory");
  [self setDirectory: NSHomeDirectory()];
}

- (void) _mountMedia
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_mountMedia");
  [[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
}

- (void) _unmountMedia
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_unmountMedia");
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self directory]];
}

@end /* NSSavePanel (PrivateMethods) */

//
// NSSavePanel methods
//
@implementation NSSavePanel

+ (id) savePanel
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel +savePanel");
  if (!gnustep_gui_save_panel)
    {
      // if (![GMModel loadIMFile:@"SavePanel" owner:NSApp])
	[[NSSavePanel alloc] _initWithoutGModel];
	[gnustep_gui_save_panel _getOriginalSize];
    }
  if (gnustep_gui_save_panel)
    [gnustep_gui_save_panel _setDefaults];

  return gnustep_gui_save_panel;
}

+ (id) allocWithZone:(NSZone *)z
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel +allocWithZone");

  if (!gnustep_gui_save_panel)
    gnustep_gui_save_panel = (NSSavePanel *)NSAllocateObject(self, 0, z);

  return gnustep_gui_save_panel;
}

- (void) setAccessoryView: (NSView *)aView
{
  NSView *contentView = [self contentView];
  NSRect addedFrame, bottomFrame, topFrame;
  NSSize contentSize;
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setAccessoryView");
  
  if (aView == _accessoryView)
    return;
  
  if (_accessoryView)
    [_accessoryView removeFromSuperview];
  
  _accessoryView = aView;
  
  if (_accessoryView == nil)
    {
      // Restore original size
      [self setMinSize: _savePanelSize];
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: _savePanelSize];
      [_topView setAutoresizingMask: 18];
      [_bottomView setAutoresizingMask: 2];
      // 
      [_topView setFrameOrigin: NSMakePoint (0, _savePanelTopViewOriginY)];
      [_topView setNeedsDisplay: YES];
    }
  else // we have an _accessoryView
    {
      //
      // Resize ourselves to make room for the accessory view
      //
      addedFrame = [_accessoryView frame];
      contentSize = _savePanelSize;
      contentSize.height += (addedFrame.size.height + (_SAVE_PANEL_Y_PAD * 2));
      if ((addedFrame.size.width + (_SAVE_PANEL_X_PAD * 2)) > contentSize.width)
	contentSize.width = (addedFrame.size.width + (_SAVE_PANEL_X_PAD * 2));  

      // Our views should resize horizontally, but not vertically
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: contentSize];
      // Restore the original autoresizing masks
      [_topView setAutoresizingMask: 18];
      [_bottomView setAutoresizingMask: 2];

      // Set new min size
      [self setMinSize: contentSize];

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
      [contentView setNeedsDisplay: YES];
    }
}

- (void) setTitle: (NSString *)title
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setTitle: %@", title);
  [super setTitle:@""];
  [_titleField setStringValue: title];
}

- (NSString *) title
{
  return [_titleField stringValue];
}

- (void) setPrompt: (NSString *)prompt
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setPrompt: %@", prompt);
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
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setDirectory: %@", path);
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
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -validateVisibleColumns");
  [_browser validateVisibleColumns];
}

- (int) runModal
{
  return [self runModalForDirectory: @"" file: @""];
}

- (int) runModalForDirectory:(NSString *) path file:(NSString *) filename
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -runModalForDirectory: filename:");

  if (path == nil || filename == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"NSSavePanel runModalForDirectory:file: "
		 @"does not accept nil arguments."];

  // must display here so that...
  [self display];
  // ...this statement works (need browser to start displaying)
  [self setDirectory: path];
  [_form setStringValue: filename];

  return [NSApp runModalForWindow: self];
}

- (NSString *) directory
{
  if (_browser != nil)
    return [_browser pathToColumn:[_browser lastColumn]];
  else
    return _lastValidPath;
}

- (NSString *) filename
{
  NSString *filename = [_form stringValue];

  if ([_requiredFileType isEqual: @""] == YES)
    return filename;

  // add filetype extension only if the filename does not include it already
  if ([[filename pathExtension] isEqual: _requiredFileType] == YES)
    return filename;
  else
    return [filename stringByAppendingPathExtension:_requiredFileType];
}

- (void) cancel: (id)sender
{
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
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setDelegate");
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

  if (!_delegateHasCompareFilter && !_delegateHasFilenameFilter
    && !_delegateHasValidNameFilter)
    [NSException raise:NSInvalidArgumentException
		format: @"Delegate supports no save panel delegete methods."];

  _delegate = aDelegate;
  [super setDelegate: aDelegate];
}

//
// NSCoding protocol
//
- (id) initWithCoder: (NSCoder *)aCoder
{
  [NSException raise:NSInvalidArgumentException
	       format:@"The save panel does not get decoded."];

  return nil;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [NSException raise:NSInvalidArgumentException
	       format:@"The save panel does not get encoded."];
}

@end /* NSSavePanel */

