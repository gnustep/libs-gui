/* -*-objc-*-
   NSOpenPanel.m

   Standard open panel for opening files

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998

   Source by Daniel Bðhringer integrated into Scott Christley's preliminary
   implementation by Felipe A. Rodriguez <far@ix.netcom.com>

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: October 1999 Completely Rewritten.

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

#include <gnustep/gui/config.h>
#include <string.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <AppKit/GMArchiver.h>
#include <AppKit/IMLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSOpenPanel.h>

/*
 * TODO: Test Everything More, debug, make sure all delegate's methods 
 * are used; simplify, arrange so no code is repeated between NSOpenPanel 
 * and NSSavePanel; check better prompts, titles, textfield stuff.
 *
 */

// Pacify the compiler
@interface NSFileManager (SavePanelExtensions)
- (NSArray *) directoryContentsAtPath: (NSString *)path showHidden: (BOOL)flag;
@end 

@interface NSSavePanel (PrivateMethods)
- (void) _setDirectory: (NSString *)path updateBrowser: (BOOL)flag;
@end
//

static NSOpenPanel *_gs_gui_open_panel = nil;

@interface NSOpenPanel (PrivateMethods)
- (void) _enableOKButton;
@end

@implementation NSOpenPanel (PrivateMethods)
- (void) _enableOKButton
{
  [_okButton setEnabled: YES];
}
@end

@implementation NSOpenPanel

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSOpenPanel class])
  {
    [self setVersion: 1];
  }
}

/*
 * Accessing the NSOpenPanel shared instance
 */
+ (NSOpenPanel *) openPanel
{
  if (!_gs_gui_open_panel)
    _gs_gui_open_panel = [[NSOpenPanel alloc] init];

  [_gs_gui_open_panel setDirectory: [[NSFileManager defaultManager] 
				    currentDirectoryPath]];
  [_gs_gui_open_panel setPrompt: @"Name:"];
  [_gs_gui_open_panel setTitle: @"Open"];
  [_gs_gui_open_panel setRequiredFileType: @""];
  [_gs_gui_open_panel setTreatsFilePackagesAsDirectories: NO];
  [_gs_gui_open_panel setDelegate: nil];
  [_gs_gui_open_panel setAccessoryView: nil];
  [_gs_gui_open_panel setCanChooseFiles: YES];
  [_gs_gui_open_panel setCanChooseDirectories: YES];
  [_gs_gui_open_panel setAllowsMultipleSelection: NO];
  [_gs_gui_open_panel _enableOKButton];
  
  return _gs_gui_open_panel;
}

- (id) init
{
  [super init];
  _canChooseDirectories = YES;
  _canChooseFiles = YES;
  return self;
}

/*
 * Filtering Files
 */
- (void) setAllowsMultipleSelection: (BOOL)flag
{
  [_browser setAllowsMultipleSelection: flag];
}

- (BOOL) allowsMultipleSelection
{
  return [_browser allowsMultipleSelection];
}

- (void) setCanChooseDirectories: (BOOL)flag
{
  _canChooseDirectories = flag;
  [_browser setAllowsBranchSelection: flag];
}

- (BOOL) canChooseDirectories
{
  return _canChooseDirectories;
}

- (void) setCanChooseFiles: (BOOL)flag
{
  _canChooseFiles = flag;
}

- (BOOL) canChooseFiles
{
  return _canChooseFiles;
}

- (NSString*) filename
{
  NSArray *ret;

  ret = [self filenames];

  if ([ret count] == 1)
    return [ret objectAtIndex: 0];
  else 
    return nil;
}

/*
 * Querying the Chosen Files
 */
- (NSArray *) filenames
{
  if ([_browser allowsMultipleSelection])
    {
      NSArray         *cells = [_browser selectedCells];
      NSEnumerator    *cellEnum = [cells objectEnumerator];
      NSBrowserCell   *currCell;
      NSMutableArray  *ret = [NSMutableArray array];
      NSString        *dir = [self directory];
      
      if ([_browser selectedColumn] != [_browser lastColumn])
	{
	  /*
	   * The last column doesn't have anything selected - so we must
	   * have selected a directory.
	   */
	  if (_canChooseDirectories == YES)
	    {
	      [ret addObject: dir];
	    }
	}
      else
	{
	  while ((currCell = [cellEnum nextObject]))
	    {
	      [ret addObject: [NSString stringWithFormat: @"%@/%@", dir, 
					[currCell stringValue]]];
	    }
	}
      return ret;
    }
  else 
    return [NSArray arrayWithObject: [super filename]];
}

/*
 * Running the NSOpenPanel
 */
- (int) runModalForTypes: (NSArray *)fileTypes
{
  return [self runModalForDirectory: nil
			       file: nil
			      types: fileTypes];
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
			types: (NSArray *)fileTypes
{
  ASSIGN (_fileTypes, fileTypes);

  if (name == nil)
    name = @"";

  if (path == nil)
    path = @"";

  if (_canChooseDirectories == NO)
    {
      BOOL isDir;
      NSString *file = [path stringByAppendingPathComponent: name];

      if ((![[NSFileManager defaultManager] fileExistsAtPath: file
					    isDirectory: &isDir]) 
	  || isDir)
	[_okButton setEnabled: NO];
    }

  return [self runModalForDirectory: path file: name];  
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_canChooseDirectories];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_canChooseFiles];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_canChooseDirectories];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_canChooseFiles];

  return self;
}
@end
//
// NSOpenPanel browser delegate methods
//
@interface NSOpenPanel (BrowserDelegate)
- (void) browser: (id)sender 
createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix;

- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column;
@end

@implementation NSOpenPanel (BrowserDelegate)
- (void) browser: (id)sender 
createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString	*path = [sender pathToColumn: column], *file;
  NSArray	*files = [fm directoryContentsAtPath: path showHidden: NO];
  NSArray       *extArray = [NSArray arrayWithObjects: @"app", 
		       @"bundle", @"debug", @"palette", @"profile", nil];
  unsigned	i, count;
  BOOL		exists, isDir;
  NSBrowserCell *cell;
  NSString      *theFile;
  NSString      *theExtension;
  unsigned int  addedRows = 0;
  
  // if array is empty, just return (nothing to display)
  if ([files lastObject] == nil)
    return;

  if ([_fileTypes count] > 0)
    {
      extArray = [extArray arrayByAddingObjectsFromArray: _fileTypes];
    }

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
      theFile = [files objectAtIndex: i];
      theExtension = [theFile pathExtension];

      file = [path stringByAppendingPathComponent: theFile];
      exists = [fm fileExistsAtPath: file
		   isDirectory: &isDir];
      
      if (_treatsFilePackagesAsDirectories == NO && isDir == YES)
	{
	  if ([extArray containsObject: theExtension])
	    isDir = NO;
	}

      if (isDir)
	{
	  [matrix insertRow: addedRows];
	  cell = [matrix cellAtRow: addedRows column: 0];
	  [cell setStringValue: theFile];
	  [cell setLeaf: NO];
	  addedRows++;
	}
      else
	{
	  if (_canChooseFiles == YES)
	    {
	      if (_fileTypes)
		if ([_fileTypes containsObject: theExtension] == NO)
		  continue;
	      
	      [matrix insertRow: addedRows];
	      cell = [matrix cellAtRow: addedRows column: 0];
	      [cell setStringValue: theFile];
	      [cell setLeaf: YES];
	      addedRows++;
	    }
	}
      
    }
}

- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column
{
  if (([_browser allowsMultipleSelection] == NO) 
      || ([[_browser selectedCells] count] == 1))
    {
      [self _setDirectory: [sender pathToColumn: [_browser lastColumn]] 
				   updateBrowser: NO];
      
      ASSIGN (_fullFileName, [sender path]);
      if (_canChooseDirectories)
	{
	  if ([[sender selectedCell] isLeaf])
	    {
	      [[_form cellAtIndex: 0] setStringValue: title];
	      [_form display];
	    }
	}
      else 
	{
	  if ([[sender selectedCell] isLeaf])
	    {
	      [[_form cellAtIndex: 0] setStringValue: title];
	      [_form display];
	      [_okButton setEnabled: YES];
	    }
	  else
	    {
	      [[_form cellAtIndex: 0] setStringValue: nil];
	      [_form display];
	      [_okButton setEnabled: NO];
	    }
	}
    }
  else // Multiple Selection 
    {
      // This will be useless when NSBrowser works.
      // NSBrowser, when we ask not to allow to select 
      // branches on multiple selections, should select only leaves
      // when the user is doing a multiple selection.
      // For now, use the following *unsatisfactory* hack.
      // (unsatisfactory because if the user selects and then 
      // deselects a directory, we don't re-enable the OK button).
      if (_canChooseDirectories)      
	if ([[sender selectedCell] isLeaf] == NO)
	  [_okButton setEnabled: NO];
    }
  return YES;
}
@end
