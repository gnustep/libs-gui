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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSSelection.h>

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
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
