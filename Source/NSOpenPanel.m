/* -*- C++ -*-
   NSOpenPanel.m

   Standard open panel for opening files

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into Scott Christley's preliminary
   implementation by Felipe A. Rodriguez <far@ix.netcom.com>

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
#include <AppKit/NSOpenPanel.h>

/*
 * toDo:    - canChooseFiles unimplemented
 *          - allowsMultipleSelection untested
 *          - setCanChooseDirectories untested
 */

static NSOpenPanel *gnustep_gui_open_panel = nil;

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
 * Accessing the NSOpenPanel
 */
+ (NSOpenPanel *) openPanel
{
  if (!gnustep_gui_open_panel)
  {
    [GMUnarchiver decodeClassName:@"NSSavePanel"
                              asClassName:@"NSOpenPanel"];

    if( ![GMModel loadIMFile:@"SavePanel" owner:NSApp] )
    {
      [NSException raise:NSGenericException
                   format:@"Unable to load open panel model file"];
    }
    [gnustep_gui_open_panel setTitle:@"Open"];

    [GMUnarchiver decodeClassName:@"NSSavePanel"
                              asClassName:@"NSSavePanel"];
  }

  return gnustep_gui_open_panel;
}

+ (id)allocWithZone:(NSZone*)z
{
  NSDebugLLog(@"NSOpenPanel", @"NSOpenPanel +allocWithZone");
  if( !gnustep_gui_open_panel)
    gnustep_gui_open_panel = NSAllocateObject(self, 0, z);

  return gnustep_gui_open_panel;
}

/*
 * Instance methods
 */

/*
 * Initialization
 */
- (id) init
{
  self = [super init];
  [self setTitle: @"Open"];
  [self setCanChooseFiles: YES];
  multiple_select = NO;

  return self;
}

/*
 * Filtering Files
 */
- (void) setAllowsMultipleSelection: (BOOL)flag
{
  allowsMultipleSelection=flag;
  [browser setAllowsMultipleSelection: flag];
}

- (BOOL) allowsMultipleSelection
{
  return allowsMultipleSelection;
}

- (void) setCanChooseDirectories: (BOOL)flag
{
  canChooseDirectories = flag;
}

- (BOOL) canChooseDirectories
{
  return canChooseDirectories;
}

- (void) setCanChooseFiles: (BOOL)flag
{
  canChooseFiles = flag;
}

- (BOOL) canChooseFiles
{
  return canChooseFiles;
}

- (NSString*) filename
{
  return [browser path];
}

/*
 * Querying the Chosen Files
 */
- (NSArray *) filenames
{
  if (!allowsMultipleSelection)
    return [NSArray arrayWithObject: [self filename]];
  else
    {
      NSArray         *cells=[browser selectedCells];
      NSEnumerator    *cellEnum;
      id              currCell;
      NSMutableArray  *ret = [NSMutableArray array];
      NSString        *dir=[self directory];

      for(cellEnum=[cells objectEnumerator];currCell=[cellEnum nextObject];)
	{
	  [ret addObject: [NSString
		      stringWithFormat: @"%@/%@",dir,[currCell stringValue]]];
	}

      return ret;
    }
}

/*
 * Running the NSOpenPanel
 */
- (int) runModalForTypes: (NSArray *)fileTypes
{
  return [self runModalForDirectory: [self directory]
			       file: nil
			      types: fileTypes];
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
			types: (NSArray *)fileTypes
{
  if (requiredTypes)
    [requiredTypes autorelease];
  requiredTypes = [fileTypes retain];

  return [self runModalForDirectory: path file: name];
}

/*
 * Target and Action Methods
 */
- (void) ok_ORIGINAL_NOT_USED: (id)sender         // excess? fix me FAR
{
  char *sp, files[4096], *p;
  NSMutableString *m;

  if (the_filenames) [the_filenames release];
  the_filenames = [NSMutableArray array];
  // Search for space
  strcpy(files, [file_name cString]);
  sp = strchr(files, ' ');
  if (sp == NULL)
    {
      // No space then only one file selected
      [the_filenames addObject: file_name];
      sp = strrchr(files, '\\');
      sp++;
      *sp = '\0';
      directory = [NSString stringWithCString: files];
    }
  else
    {
      // Multiple files selected
      *sp = '\0';
      directory = [NSString stringWithCString: files];
      p = sp + 1;
      sp = strchr(p, ' ');
      while (sp != NULL)
    {
      *sp = '\0';
      m = [NSMutableString stringWithCString: files];
      [m appendString: @"\\"];
      [m appendString: [NSString stringWithCString: p]];
      [the_filenames addObject: m];
      p = sp + 1;
      sp = strchr(p, ' ');
    }
      if (strchr(p, '\0'))
    {
      m = [NSMutableString stringWithCString: files];
      [m appendString: @"\\"];
      [m appendString: [NSString stringWithCString: p]];
      [the_filenames addObject: m];
    }
  }
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: the_filenames];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &multiple_select];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &choose_dir];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &choose_file];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &the_filenames];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &multiple_select];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &choose_dir];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &choose_file];

  return self;
}

@end
