/* 
   NSSelection.m

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

#include <gnustep/gui/config.h>
#include <AppKit/NSSelection.h>

@implementation NSSelection

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSelection class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Returning Special Selection Shared Instances
//
+ (NSSelection *)allSelection
{
  return nil;
}

+ (NSSelection *)currentSelection
{
  return nil;
}

+ (NSSelection *)emptySelection
{
  return nil;
}

//
// Creating and Initializing a Selection
//
+ (NSSelection *)selectionWithDescriptionData:(NSData *)data
{
  return nil;
}

//
// Instance methods
//

//
// Creating and Initializing a Selection
//
- (id)initWithDescriptionData:(NSData *)newData
{
  return nil;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  return nil;
}

//
// Describing a Selection
//
- (NSData *)descriptionData
{
  return nil;
}

- (BOOL)isWellKnownSelection
{
  return NO;
}

//
// Writing a Selection to the Pasteboard
//
- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{}

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
