/* 
   NSDataLink.m

   Description...

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

#include <AppKit/NSDataLink.h>
#include <AppKit/NSDataLinkManager.h>

@implementation NSDataLink

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLink class])
    {
      // Initial version
      [self setVersion:1];
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
  return nil;
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
{}

//
// Information about the Link
//
- (NSDataLinkDisposition)disposition
{
  return 0;
}

- (NSDataLinkNumber)linkNumber
{
  return 0;
}

- (NSDataLinkManager *)manager
{
  return nil;
}

//
// Information about the Link's Source
//
- (NSDate *)lastUpdateTime
{
  return nil;
}

- (BOOL)openSource
{
  return NO;
}

- (NSString *)sourceApplicationName
{
  return nil;
}

- (NSString *)sourceFilename
{
  return nil;
}

- (NSSelection *)sourceSelection
{
  return nil;
}

- (NSArray *)types
{
  return nil;
}

//
// Information about the Link's Destination
//
- (NSString *)destinationApplicationName
{
  return nil;
}

- (NSString *)destinationFilename
{
  return nil;
}

- (NSSelection *)destinationSelection
{
  return nil;
}

//
// Changing the Link
//
- (BOOL)break
{
  return NO;
}

- (void)noteSourceEdited
{}

- (void)setUpdateMode:(NSDataLinkUpdateMode)mode
{}

- (BOOL)updateDestination
{
  return NO;
}

- (NSDataLinkUpdateMode)updateMode
{
  return 0;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
}

- initWithCoder:aDecoder
{
  return self;
}

@end
