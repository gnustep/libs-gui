/* 
   NSOpenPanel.m

   Standard open panel for opening files

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

#include <gnustep/gui/NSOpenPanel.h>

NSOpenPanel *MB_THE_OPEN_PANEL;

@implementation NSOpenPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSOpenPanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Accessing the NSOpenPanel 
//
+ (NSOpenPanel *)openPanel
{
  if (!MB_THE_OPEN_PANEL)
    MB_THE_OPEN_PANEL = [[NSOpenPanel alloc] init];
  return MB_THE_OPEN_PANEL;
}

//
// Instance methods
//
//
// Initialization
//
- (void)setDefaults
{
  [super setDefaults];
  panel_title = @"Open File";
  multiple_select = NO;
  choose_dir = NO;
  choose_file = YES;
}

- init
{
  [super init];
  [self setDefaults];
  return self;
}

//
// Filtering Files 
//
- (BOOL)allowsMultipleSelection
{
  return multiple_select;
}

- (BOOL)canChooseDirectories
{
  return choose_dir;
}

- (BOOL)canChooseFiles
{
  return choose_file;
}

- (void)setAllowsMultipleSelection:(BOOL)flag
{
  multiple_select = flag;
}

- (void)setCanChooseDirectories:(BOOL)flag
{
  choose_dir = flag;
}

- (void)setCanChooseFiles:(BOOL)flag;
{
  choose_file = flag;
}

//
// Querying the Chosen Files 
//
- (NSArray *)filenames
{
  return the_filenames;
}

- (NSString *)filename
{
  if ([the_filenames count] > 0)
    return [the_filenames objectAtIndex:0];
  else
    return nil;
}

//
// Running the NSOpenPanel 
//
- (int)runModalForTypes:(NSArray *)fileTypes
{
}

- (int)runModalForDirectory:(NSString *)path
		       file:(NSString *)filename
{
  NSArray *t = [NSArray arrayWithObject:@"*"];

  if (path) directory = path;
  if (filename) file_name = filename;

  return [self runModalForTypes:t];
}

- (int)runModalForDirectory:(NSString *)path
		       file:(NSString *)filename
types:(NSArray *)fileTypes
{
  if (path) directory = path;
  if (filename) file_name = filename;

  return [self runModalForTypes:fileTypes];
}

//
// Target and Action Methods 
//
- (void)ok:(id)sender
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
      [the_filenames addObject:file_name];
      sp = strrchr(files, '\\');
      sp++;
      *sp = '\0';
      directory = [NSString stringWithCString:files];
    }
  else
    {
      // Multiple files selected
      *sp = '\0';
      directory = [NSString stringWithCString:files];
      p = sp + 1;
      sp = strchr(p, ' ');
      while (sp != NULL)
	{
	  *sp = '\0';
	  m = [NSMutableString stringWithCString:files];
	  [m appendString:@"\\"];
	  [m appendString:[NSString stringWithCString:p]];
	  [the_filenames addObject:m];
	  p = sp + 1;
	  sp = strchr(p, ' ');
	}
      if (strchr(p, '\0'))
	{
	  m = [NSMutableString stringWithCString:files];
	  [m appendString:@"\\"];
	  [m appendString:[NSString stringWithCString:p]];
	  [the_filenames addObject:m];
	}
    }
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: the_filenames];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &multiple_select];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &choose_dir];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &choose_file];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  the_filenames = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &multiple_select];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &choose_dir];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &choose_file];

  return self;
}

@end
