/* 
   NSBrowserCell.m

   Cell class for the NSBrowser

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

#include <gnustep/gui/NSBrowserCell.h>

@implementation NSBrowserCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBrowserCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Accessing Graphic Attributes 
//
+ (NSImage *)branchImage
{
  return nil;
}

+ (NSImage *)highlightedBranchImage
{
  return nil;
}

//
// Instance methods
//

//
// Accessing Graphic Attributes 
//
- (NSImage *)alternateImage
{
  return nil;
}

- (void)setAlternateImage:(NSImage *)anImage
{}

//
// Placing in the Browser Hierarchy 
//
- (BOOL)isLeaf
{
  return NO;
}

- (void)setLeaf:(BOOL)flag
{}

//
// Determining Loaded Status 
//
- (BOOL)isLoaded
{
  return NO;
}

- (void)setLoaded:(BOOL)flag
{}

//
// Setting State 
//
- (void)reset
{}

- (void)set
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
