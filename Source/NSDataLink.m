/** <title>NSDataLink</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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

#include "config.h"
#include "AppKit/NSDataLink.h"
#include "AppKit/NSDataLinkManager.h"

@implementation NSDataLink

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLink class])
    {
      // Initial version
      [self setVersion: 1];
    }
}

//
//
// Instance methods
//
// Initializing a Link
//
- (id)initLinkedToFile:(NSString *)filename
{
  return nil;
}

- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes
{
  if((self = [self init]) != nil)
    {
      ASSIGN(sourceSelection,selection);
      ASSIGN(manager,linkManager);
      ASSIGN(types,newTypes);
    }
  return self;
}

- (id)initWithContentsOfFile:(NSString *)filename
{
  return nil;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  return nil;
}

//
// Exporting a Link
//
- (BOOL)saveLinkIn:(NSString *)directoryName
{
  return NO;
}

- (BOOL)writeToFile:(NSString *)filename
{
  return NO;
}

- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{
}

//
// Information about the Link
//
- (NSDataLinkDisposition)disposition
{
  return disposition;
}

- (NSDataLinkNumber)linkNumber
{
  return linkNumber;
}

- (NSDataLinkManager *)manager
{
  return manager;
}

//
// Information about the Link's Source
//
- (NSDate *)lastUpdateTime
{
  return lastUpdateTime;
}

- (BOOL)openSource
{
  return NO;
}

- (NSString *)sourceApplicationName
{
  return sourceApplicationName;
}

- (NSString *)sourceFilename
{
  return sourceFilename;
}

- (NSSelection *)sourceSelection
{
  return sourceSelection;
}

- (NSArray *)types
{
  return types;
}

//
// Information about the Link's Destination
//
- (NSString *)destinationApplicationName
{
  return destinationApplicationName;
}

- (NSString *)destinationFilename
{
  return destinationFilename;
}

- (NSSelection *)destinationSelection
{
  return destinationSelection;
}

//
// Changing the Link
//
- (BOOL)break
{
  return NO;
}

- (void)noteSourceEdited
{
}

- (void)setUpdateMode:(NSDataLinkUpdateMode)mode
{
  updateMode = mode;
}

- (BOOL)updateDestination
{
  return NO;
}

- (NSDataLinkUpdateMode)updateMode
{
  return updateMode;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(int) at: &linkNumber];
  [aCoder encodeValueOfObjCType: @encode(int) at: &disposition];
  [aCoder encodeValueOfObjCType: @encode(int) at: &updateMode];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &manager];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &lastUpdateTime];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceApplicationName];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceFilename];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceSelection];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &types];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationApplicationName];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationFilename];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationSelection];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: @"NSDataLink"];

  if(version == 1)
    {
      [aCoder decodeValueOfObjCType: @encode(int) at: &linkNumber];
      [aCoder decodeValueOfObjCType: @encode(int) at: &disposition];
      [aCoder decodeValueOfObjCType: @encode(int) at: &updateMode];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &manager];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &lastUpdateTime];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceApplicationName];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceFilename];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceSelection];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &types];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationApplicationName];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationFilename];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationSelection];
    }
  else
    {
      NSLog(@"No decoder for NSDataLink version #%d",version);
    }

  return self;
}

@end
