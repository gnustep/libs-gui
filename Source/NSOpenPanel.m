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

static NSOpenPanel *_gs_gui_open_panel = nil;

// Pacify the compiler
@interface NSSavePanel (_PrivateMethods)
- (void) _resetDefaults;
@end
//

@interface NSOpenPanel (_PrivateMethods)
- (void) _resetDefaults;
- (BOOL) _shouldShowExtension: (NSString *)extension;
@end

@implementation NSOpenPanel (_PrivateMethods)
- (void) _resetDefaults
{
  [super _resetDefaults];
  [self setTitle: @"Open"];
  [self setCanChooseFiles: YES];
  [self setCanChooseDirectories: YES];
  [self setAllowsMultipleSelection: NO];
  [_okButton setEnabled: YES];
}
// NB: Invoked only for files.
- (BOOL) _shouldShowExtension: (NSString *)extension;
{
  if ((_fileTypes) && ([_fileTypes containsObject: extension] == NO))
    return NO;
  
  if (_canChooseFiles == NO)
    return NO;

  return YES;
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

  [_gs_gui_open_panel _resetDefaults];

  return _gs_gui_open_panel;
}

- (id) init
{
  [super init];
  _canChooseDirectories = YES;
  _canChooseFiles = YES;
  return self;
}

// dealloc is the same as NSSavePanel

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
  // TODO: fix the following in NSBrowser
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

  if (path == nil)
    {
      if (_directory)
	path = _directory; 
      else
	path= [[NSFileManager defaultManager] currentDirectoryPath];
    }  

  if (name == nil)
    name = @"";

  if (_canChooseDirectories == NO)
    {
      BOOL isDir;
      NSString *file = [path stringByAppendingPathComponent: name];
      
      if (([[NSFileManager defaultManager] fileExistsAtPath: file
					   isDirectory: &isDir] == NO) 
	  || isDir)
	[_okButton setEnabled: NO];
    }
  
  return [self runModalForDirectory: path 
	       file: name];  
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
@interface NSOpenPanel (_BrowserDelegate)
- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column;
@end

@implementation NSOpenPanel (_BrowserDelegate)
- (BOOL) browser: (NSBrowser *)sender
selectCellWithString: (NSString *)title
	inColumn: (int)column
{
  NSMatrix *m;
  NSArray *c;

  m = [_browser matrixInColumn: column];
  c = [m selectedCells];
  
  if ([c count] == 1)
    {
      BOOL isLeaf = [[c objectAtIndex: 0] isLeaf];

      if (_canChooseDirectories == NO)
	{
	  [_okButton setEnabled: isLeaf];
	  return [super browser: sender
			selectCellWithString: title
			inColumn: column];
	}
      else // _canChooseDirectories
	{
	  BOOL ret;
	  ret = [super browser: sender
		       selectCellWithString: title
		       inColumn: column];
	  if (isLeaf == NO)
	    ASSIGN (_fullFileName, _directory);
	  return ret;
	}
    }
  else // Multiple Selection, and it is not the first item of the selection
    {
      return YES;
    }
}
@end
