/* 
   NSSavePanel.m

   Standard save panel for saving files

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

#include <string.h>

#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSSavePanel.h>

//
// Class variables
//
static NSSavePanel *MB_THE_SAVE_PANEL = nil;

@implementation NSSavePanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSavePanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSSavePanel 
//
+ (NSSavePanel *)savePanel
{
  if (!MB_THE_SAVE_PANEL)
    MB_THE_SAVE_PANEL = [[NSSavePanel alloc] init];
  return MB_THE_SAVE_PANEL;
}

//
// Instance methods
//
//
// Initialization
//
- (void)setDefaults
{
  directory = @"\\";
  file_name = @"";
  accessory_view = nil;
  panel_title = @"Save File";
  panel_prompt = @"";
  required_type = nil;
  file_package = YES;
}

- init
{
  [super init];

  [self setDefaults];
  return self;
}

//
// Customizing the NSSavePanel 
//
- (void)setAccessoryView:(NSView *)aView
{
  accessory_view = aView;
}

- (NSView *)accessoryView
{
  return accessory_view;
}

- (void)setTitle:(NSString *)title
{
  panel_title = title;
}

- (NSString *)title
{
  return panel_title;
}

- (void)setPrompt:(NSString *)prompt
{
  panel_prompt = prompt;
}

- (NSString *)prompt
{
  return panel_prompt;
}

//
// Setting Directory and File Type 
//
- (NSString *)requiredFileType
{
  return required_type;
}

- (void)setDirectory:(NSString *)path
{
  directory = path;
}

- (void)setRequiredFileType:(NSString *)type
{
  required_type = type;
}

- (void)setTreatsFilePackagesAsDirectories:(BOOL)flag
{
  file_package = flag;
}

- (BOOL)treatsFilePackagesAsDirectories
{
  return file_package;
}

//
// Running the NSSavePanel 
//
- (int)runModalForDirectory:(NSString *)path
		       file:(NSString *)filename
{
  if (path)
    directory = path;
		
  if (filename)
    file_name = filename;

  return [self runModal];
}

- (int)runModal
{
  return 0;
}

//
// Reading Save Information 
//
- (NSString *)directory
{
  return directory;
}

- (NSString *)filename
{
  return file_name;
}

//
// Target and Action Methods 
//
- (void)ok:(id)sender
{
  char *sp, files[4096];

  strcpy(files, [file_name cString]);
  sp = strrchr(files, '\\');
  if (sp != NULL)
    {
      sp++;
      *sp = '\0';
      directory = [NSString stringWithCString:files];
    }
}

- (void)cancel:(id)sender
{
}

//
// Responding to User Input 
//
- (void)selectText:(id)sender
{}

//
// Setting the Delegate 
//
- (void)setDelegate:(id)anObject
{
  delegate = anObject;
}

//
// Methods Implemented by the Delegate 
//
- (NSComparisonResult)panel:(id)sender
	    compareFilename:(NSString *)filename1
with:(NSString *)filename2
	    caseSensitive:(BOOL)caseSensitive
{
  if ([delegate respondsToSelector:
		  @selector(panel:compareFilename:with:caseSensitive:)])
    return [delegate panel:sender compareFilename:filename1
		     with:filename2 caseSensitive:caseSensitive];
  return NSOrderedSame;
}

- (BOOL)panel:(id)sender
shouldShowFilename:(NSString *)filename
{
  if ([delegate respondsToSelector:@selector(panel:shouldShowFilename:)])
    return [delegate panel:sender shouldShowFilename:filename];
  return NO;
}

- (BOOL)panel:(id)sender
isValidFilename:(NSString*)filename
{
  if ([delegate respondsToSelector:@selector(panel:isValidFilename:)])
    return [delegate panel:sender isValidFilename:filename];
  return NO;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [aCoder encodeObject: accessory_view];
  [aCoder encodeObject: panel_title];
  [aCoder encodeObject: panel_prompt];
  [aCoder encodeObject: directory];
  [aCoder encodeObject: file_name];
  [aCoder encodeObject: required_type];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at:&required_type];
#if 0
  [aCoder encodeObjectReference: delegate withName: @"Delegate"];
#else
  [aCoder encodeConditionalObject:delegate];
#endif
}

- initWithCoder:aDecoder
{
  accessory_view = [aDecoder decodeObject];
  panel_title = [aDecoder decodeObject];
  panel_prompt = [aDecoder decodeObject];
  directory = [aDecoder decodeObject];
  file_name = [aDecoder decodeObject];
  required_type = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&required_type];
#if 0
  [aDecoder decodeObjectAt: &delegate withName: NULL];
#else
  delegate = [aDecoder decodeObject];
#endif

  return self;
}

@end
