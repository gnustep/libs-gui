/* -*-objc-*-
   NSOpenPanel.m

   Standard open panel for opening files

   Copyright (C) 1996, 1998, 1999, 2000 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998

   Source by Daniel Bðhringer integrated into Scott Christley's preliminary
   implementation by Felipe A. Rodriguez <far@ix.netcom.com>

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: October 1999 Completely Rewritten.

   Author:  Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: September 2000

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
- (void) _selectCellName: (NSString *)title;
@end
//

@interface NSOpenPanel (_PrivateMethods)
- (void) _resetDefaults;
- (BOOL) _shouldShowExtension: (NSString *)extension isDir: (BOOL *)isDir;
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

- (BOOL) _shouldShowExtension: (NSString *)extension
			isDir: (BOOL *)isDir;
{
  BOOL found = YES;

  if (_fileTypes)
    {
      if ([_fileTypes containsObject: extension] == YES)
	{
	  if ([self treatsFilePackagesAsDirectories] == NO)
	    *isDir = NO;
	}
      else
	found = NO;
    }

  if (*isDir == YES || (found == YES && _canChooseFiles == YES))
    return YES;

  return NO;
}

- (void) _selectTextInColumn: (int)column
{
  NSMatrix *matrix;

  if(column == -1)
    return;

  matrix = [_browser matrixInColumn:column];

  if ([_browser allowsMultipleSelection])
    {
      NSArray  *selectedCells;

      selectedCells = [matrix selectedCells];

      if([selectedCells count] <= 1)
	{
	  if(_canChooseDirectories == NO ||
	     [[matrix selectedCell] isLeaf] == YES)
	    [super _selectTextInColumn:column];
	  else
	    {
	      [self _selectCellName:[[_form cellAtIndex: 0] stringValue]];
	      //	      [_form selectTextAtIndex:0];
	      [_okButton setEnabled:YES];
	    }
	}
      else
	{
	  [_form abortEditing];
	  [[_form cellAtIndex: 0] setStringValue:nil];
	  //	  [_form selectTextAtIndex:0];
	  [_form setNeedsDisplay:YES];
	  [_okButton setEnabled:YES];
	}
    }
  else
    {
      if(_canChooseDirectories == NO || [[matrix selectedCell] isLeaf] == YES)
	[super _selectTextInColumn:column];
      else
	{
	  if([[[_form cellAtIndex: 0] stringValue] length] > 0)
	    {
	      [self _selectCellName:[[_form cellAtIndex: 0] stringValue]];
	      //	      [_form selectTextAtIndex:0];
	      [_form setNeedsDisplay:YES];
	    }

	  [_okButton setEnabled:YES];
	}
    }
}

- (void) _selectCellName: (NSString *)title
{
  NSString           *cellString;
  NSArray            *cells;
  NSMatrix           *matrix;
  NSComparisonResult  result;
  NSRange             range;
  int                 i, titleLength, cellLength, numberOfCells;

  matrix = [_browser matrixInColumn:[_browser lastColumn]];
  if([matrix selectedCell])
    return;

  titleLength = [title length];
  if(!titleLength)
    {
      [_okButton setEnabled:NO];
      return;
    }

  range.location = 0;
  range.length = titleLength;

  cells = [matrix cells];
  numberOfCells = [cells count];

  for(i = 0; i < numberOfCells; i++)
    {
      cellString = [[matrix cellAtRow:i column:0] stringValue];

      cellLength = [cellString length];
      if(cellLength < titleLength)
	continue;

      result = [cellString compare:title options:0 range:range];

      if(result == NSOrderedSame)
	{
	  [matrix selectCellAtRow:i column:0];
	  [matrix scrollCellToVisibleAtRow:i column:0];
	  [_okButton setEnabled:YES];
	  return;
	}
      else if(result == NSOrderedDescending)
	break;
    }
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
    {
      if (_canChooseDirectories == YES)
	{
	  if ([_browser selectedColumn] != [_browser lastColumn])
	    return [NSArray arrayWithObject: [self directory]];
	}

      return [NSArray arrayWithObject: [super filename]];
    }
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

      if([_browser allowsMultipleSelection] == YES)
	[_browser setAllowsBranchSelection:NO];
    }
  
  return [self runModalForDirectory: path 
	       file: name];  
}

- (void) ok: (id)sender
{
  NSMatrix      *matrix = nil;
  NSBrowserCell *selectedCell = nil;
  NSArray       *selectedCells = nil;
  int            selectedColumn, lastColumn;

  selectedColumn = [_browser selectedColumn];
  lastColumn = [_browser lastColumn];
  if (selectedColumn >= 0)
    {
      matrix = [_browser matrixInColumn: selectedColumn];

      if ([_browser allowsMultipleSelection] == YES)
	{
	  selectedCells = [matrix selectedCells];

	  if (selectedColumn == lastColumn &&
	      [selectedCells count] == 1)
	    selectedCell = [selectedCells objectAtIndex: 0];
	}
      else
	{
	  if (_canChooseDirectories == NO)
	    {
	      if (selectedColumn == lastColumn)
		selectedCell = [matrix selectedCell];
	    }
	  else if (selectedColumn == lastColumn)
	    selectedCell = [matrix selectedCell];
	}
    }

  if (selectedCell)
    {
      if ([selectedCell isLeaf] == NO)
	{
	  [[_form cellAtIndex: 0] setStringValue: @""];
	  [_browser doClick: matrix];
	  [_form selectTextAtIndex: 0];
	  [_form setNeedsDisplay: YES];

	  return;
	}
    }
  else if (_canChooseDirectories == NO
	   && (![_browser allowsMultipleSelection] || !selectedCells
	       || selectedColumn != lastColumn || ![selectedCells count]))
    {
      [_form selectTextAtIndex: 0];
      [_form setNeedsDisplay: YES];
      return;
    }

  ASSIGN (_directory, [_browser pathToColumn:[_browser lastColumn]]);
  if (selectedCell)
    ASSIGN (_fullFileName, [_directory stringByAppendingPathComponent:
					 [selectedCell stringValue]]);
  else
    ASSIGN (_fullFileName, [_directory stringByAppendingPathComponent:
					 [[_form cellAtIndex: 0] stringValue]]);

  if (_delegateHasValidNameFilter)
    {
      NSEnumerator *enumerator;
      NSArray      *filenames = [self filenames];
      NSString     *filename;

      enumerator = [filenames objectEnumerator];
      while ((filename = [enumerator nextObject]))
	{
	  if ([_delegate panel: self isValidFilename: filename] == NO)
	    return;
	}
    }

  _OKButtonPressed = YES;
  [NSApp stopModal];
  [self close];
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
  BOOL isLeaf;

  m = [_browser matrixInColumn: column];
  c = [m selectedCells];
  
  if ([c count] == 1)
    {
      isLeaf = [[c objectAtIndex: 0] isLeaf];

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

//
// NSForm delegate methods
//
@interface NSOpenPanel (FormDelegate)
- (void) controlTextDidChange: (NSNotification *)aNotification;
@end
@implementation NSOpenPanel (FormDelegate)

- (void) controlTextDidChange: (NSNotification *)aNotification;
{
  NSString           *s, *selectedString;
  NSArray            *cells;
  NSMatrix           *matrix;
  NSCell             *selectedCell;
  int                 i, sLength, cellLength, selectedRow;
  NSComparisonResult  result;
  NSRange             range;

  matrix = [_browser matrixInColumn: [_browser lastColumn]];
  s = [[[aNotification userInfo] objectForKey: @"NSFieldEditor"] string];

  sLength = [s length];
  range.location = 0;
  range.length = sLength;

  if(sLength == 0)
    {
      [matrix deselectAllCells];
      if(_canChooseDirectories == NO)
	[_okButton setEnabled: NO];
      return;
    }

  selectedCell = [matrix selectedCell];
  selectedString = [selectedCell stringValue];
  selectedRow = [matrix selectedRow];
  cells = [matrix cells];

  if(selectedString)
    {
      cellLength = [selectedString length];

      if(cellLength < sLength)
	range.length = cellLength;

      result = [selectedString compare: s options: 0 range: range];

      if(result == NSOrderedSame)
	return;
      else if(result == NSOrderedAscending)
	result = NSOrderedDescending;
      else if(result == NSOrderedDescending)
	result = NSOrderedAscending;

      range.length = sLength;
    }
  else
    result = NSOrderedDescending;

  if(result == NSOrderedDescending)
    {
      int numberOfCells = [cells count];

      for(i = selectedRow+1; i < numberOfCells; i++)
	{
	  selectedString = [[matrix cellAtRow: i column: 0] stringValue];

	  cellLength = [selectedString length];
	  if(cellLength < sLength)
	    continue;

	  result = [selectedString compare: s options: 0 range: range];

	  if(result == NSOrderedSame)
	    {
	      [matrix deselectAllCells];
	      [matrix selectCellAtRow: i column: 0];
	      [matrix scrollCellToVisibleAtRow: i column: 0];
	      [_okButton setEnabled: YES];
	      return;
	    }
	}
    }
  else
    {
      for(i = selectedRow; i >= 0; --i)
	{
	  selectedString = [[matrix cellAtRow: i column: 0] stringValue];

	  cellLength = [selectedString length];
	  if(cellLength < sLength)
	    continue;

	  result = [selectedString compare: s options: 0 range: range];

	  if(result == NSOrderedSame)
	    {
	      [matrix deselectAllCells];
	      [matrix selectCellAtRow: i column: 0];
	      [matrix scrollCellToVisibleAtRow: i column: 0];
	      [_okButton setEnabled: YES];
	      return;
	    }
	}
    }

  [matrix deselectAllCells];
  [_okButton setEnabled: YES];
}

@end /* NSOpenPanel */
