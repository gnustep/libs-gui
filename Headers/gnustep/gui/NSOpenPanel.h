/* 
   NSOpenPanel.h

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSOpenPanel
#define _GNUstep_H_NSOpenPanel

#include <AppKit/stdappkit.h>
#include <AppKit/NSSavePanel.h>
#include <Foundation/NSCoder.h>

@interface NSOpenPanel : NSSavePanel <NSCoding>

{
  // Attributes
  NSMutableArray *the_filenames;
  BOOL multiple_select;
  BOOL choose_dir;
  BOOL choose_file;
}

//
// Accessing the NSOpenPanel 
//
+ (NSOpenPanel *)openPanel;

//
// Filtering Files 
//
- (BOOL)allowsMultipleSelection;
- (BOOL)canChooseDirectories;
- (BOOL)canChooseFiles;
- (void)setAllowsMultipleSelection:(BOOL)flag;
- (void)setCanChooseDirectories:(BOOL)flag;
- (void)setCanChooseFiles:(BOOL)flag;

//
// Querying the Chosen Files 
//
- (NSArray *)filenames;

//
// Running the NSOpenPanel 
//
- (int)runModalForTypes:(NSArray *)fileTypes;
- (int)runModalForDirectory:(NSString *)path
		       file:(NSString *)filename
types:(NSArray *)fileTypes;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSOpenPanel
