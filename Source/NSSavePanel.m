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
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSWorkspace.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>

#define X_PAD	5
#define Y_PAD	4

static NSSavePanel *gnustep_gui_save_panel = nil;

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
  if ( ![files lastObject] )
    return;

  // sort list of files to display
  if ( _delegateHasCompareFilter )
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
  for ( i = 0; i < count; i++ )
    {
      NSBrowserCell *cell;

      //if ( i != 0 )
	[matrix insertRow:i];

      cell = [matrix cellAtRow: i column: 0];
      [cell setStringValue: [files objectAtIndex: i]];

      file = [path stringByAppendingPathComponent: [files objectAtIndex: i]];
      exists = [fm fileExistsAtPath: file
			isDirectory: &isDir
			  isPackage: &isPackage];

      if ( isPackage && !_treatsFilePackagesAsDirectories )
	isDir = NO;

      if ( exists && isDir )
	[cell setLeaf: NO];
      else
	[cell setLeaf: YES];
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
  if ( _delegateHasFilenameFilter )
    for ( i = 0; i < count; i++ )
      {
	if ( ![_delegate panel: self shouldShowFilename:
	  [[cells objectAtIndex: i] stringValue]] )
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

- (void) _setDefaults;
- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag;

@end /* NSSavePanel (PrivateMethods) */

@implementation NSSavePanel (PrivateMethods)

- (void) _setDefaults
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_setDefaults");
  [self setDirectory: [[NSFileManager defaultManager] currentDirectoryPath]];
  [self setPrompt: @"Name:"];
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
  if ( standardizedPath
    && [[NSFileManager defaultManager]
	 fileExistsAtPath: path isDirectory: &isDir] && isDir )
    {
      if ( _lastValidPath )
	[_lastValidPath autorelease];
      _lastValidPath = [standardizedPath retain];
    }
  // set the path in the browser
  if ( _browser && flag )
    [_browser setPath: _lastValidPath];
}

- (void) _processCellSelection
{
  id	selectedCell = [_browser selectedCell];

  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -_processCellSelection");

  [self _setDirectory:
    [_browser pathToColumn: [_browser lastColumn]] updateBrowser: NO];

  if ( [selectedCell isLeaf] )
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
  if ( !gnustep_gui_save_panel )
    {
      if ( ![GMModel loadIMFile:@"SavePanel" owner:NSApp] )
	{
	  NSRunAlertPanel(@"SavePanel Error",
			  @"Cannot open the save panel model file",
			  @"Ok",
			  nil,
			  nil);
	}
    }
  if ( gnustep_gui_save_panel )
    [gnustep_gui_save_panel _setDefaults];

  return gnustep_gui_save_panel;
}

+ (id) allocWithZone:(NSZone *)z
{
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel +allocWithZone");

  if ( !gnustep_gui_save_panel )
    gnustep_gui_save_panel = (NSSavePanel *)NSAllocateObject(self, 0, z);

  return gnustep_gui_save_panel;
}

- (void) setAccessoryView: (NSView *)aView
{
  NSView *contentView = [self contentView];
  NSRect addedFrame, contentFrame, bottomFrame, topFrame;
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -setAccessoryView");

  if ( _accessoryView )
    {
      [_accessoryView removeFromSuperview];
      [self setContentSize: _oldContentFrame.size];
      [_topView setFrame: _oldTopViewFrame];
      [_topView setNeedsDisplay: YES];
    }

  _accessoryView = aView;

  if ( _accessoryView )
    {
      // save old values
      _oldContentFrame = [contentView frame];
      _oldTopViewFrame = [_topView frame];

      // pad out the new view
      addedFrame = [_accessoryView frame];
      addedFrame.size.width += X_PAD * 2;
      addedFrame.size.height += Y_PAD * 2;
      
      // re-size the content frame to cover existing views and the new view
      // (it grows vertically always; horizontally only if needed)
      contentFrame = _oldContentFrame;
      contentFrame.size.height += NSHeight(addedFrame);
      contentFrame.size.width = MAX(NSWidth(contentFrame), NSWidth(addedFrame));
      [self setContentSize: contentFrame.size];

      /*
       * now shrink and move the top view to make room for the new view
       * (it needs to shrink because it re-sized itself to fit the content
       * frame)
       */
      topFrame = [_topView frame];
      topFrame.size.height -= NSHeight(addedFrame);
      topFrame.origin.y += NSHeight(addedFrame);
      [_topView setFrame: topFrame];
      
      // set origin for new view above bottom view
      bottomFrame = [_bottomView frame];
      [_accessoryView setFrameOrigin:
	  NSMakePoint(NSMidX(contentFrame) - NSMidX(addedFrame) + X_PAD,
			  NSHeight(bottomFrame) + Y_PAD)];

      // finally add the new view
      [contentView addSubview: _accessoryView];
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
  NSRect panelFrame = [self frame];
  NSRect screenFrame = [[NSScreen mainScreen] frame];
  NSDebugLLog(@"NSSavePanel", @"NSSavePanel -runModalForDirectory: filename:");

  if ( !path || !filename )
    [NSException raise: NSInvalidArgumentException
		 format: @"NSSavePanel runModalForDirectory: file: does not accept nil arguments."];

  // must display here so that...
  [self display];
  // ...this statement works (need browser to start displaying)
  [self setDirectory: path];
  [_form setStringValue: filename];

  [self setFrameOrigin:
      NSMakePoint(NSMidX(screenFrame) - NSWidth(panelFrame)/2.0,
		  NSMidY(screenFrame) - NSHeight(panelFrame)/2.0)]; 
  [self makeKeyAndOrderFront: self];
  return [NSApp runModalForWindow: self];
}

- (NSString *) directory
{
  if ( _browser )
    return [_browser pathToColumn:[_browser lastColumn]];
  else
    return _lastValidPath;
}

- (NSString *) filename
{
  NSString *filename = [_form stringValue];

  if ( [_requiredFileType isEqual: @""] )
    return filename;

  // add filetype extension only if the filename does not include it already
  if ( [[filename pathExtension] isEqual: _requiredFileType] )
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
  if ( _delegateHasValidNameFilter )
    if ( ![_delegate panel:self isValidFilename: [self filename]] )
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
  if ( aDelegate == nil )
    {
      _delegate = nil;
      _delegateHasCompareFilter = NO;
      _delegateHasFilenameFilter = NO;
      _delegateHasValidNameFilter = NO;
      return;
    }

  _delegateHasCompareFilter = [aDelegate respondsToSelector: @selector(panel:compareFilename:with:caseSensitive:)] ? YES : NO;
  _delegateHasFilenameFilter = [aDelegate respondsToSelector: @selector(panel:shouldShowFilename:)] ? YES : NO;
  _delegateHasValidNameFilter = [aDelegate respondsToSelector: @selector(panel:isValidFilename:)] ? YES : NO;

  if ( !_delegateHasCompareFilter && !_delegateHasFilenameFilter
    && !_delegateHasValidNameFilter )
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

//
// NSFileManager extensions
//
@interface NSFileManager (SavePanelExtensions)

- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag;
- (NSArray *) hiddenFilesAtPath: (NSString *)path;
- (BOOL) fileExistsAtPath: (NSString *)path isDirectory: (BOOL *)flag1 isPackage: (BOOL *)flag2;

@end

@implementation NSFileManager (SavePanelExtensions)

- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag
{
  NSArray *rawFiles = [self directoryContentsAtPath: path];
  NSArray *hiddenFiles = [self hiddenFilesAtPath: path];
  NSMutableArray *files = [NSMutableArray new];
  NSEnumerator *enumerator = [rawFiles objectEnumerator];
  NSString *filename;

  if ( flag || !hiddenFiles )
    return rawFiles;

  while ( (filename = (NSString *)[enumerator nextObject]) )
    {
      if ( [hiddenFiles indexOfObject: filename] == NSNotFound )
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
  NSArray *extArray = [NSArray arrayWithObjects: @"app", @"bundle", @"debug", @"profile", nil];

  if ( [extArray indexOfObject: [path pathExtension]] == NSNotFound )
    *isPackage = NO;
  else
    *isPackage = YES;
  return [self fileExistsAtPath: path isDirectory: isDir];
}

@end /* NSFileManager (SavePanelExtensions) */

