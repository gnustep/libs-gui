/* 
   NSSelection.h

   Class describing a selection in a document

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

#ifndef _GNUstep_H_NSSelection
#define _GNUstep_H_NSSelection

#include <gnustep/gui/config.h>
#include <Foundation/NSCoder.h>

@class NSData;
@class NSPasteboard;

@interface NSSelection : NSObject <NSCoding>
{
  // Attributes
}

//
// Returning Special Selection Shared Instances
//
+ (NSSelection *)allSelection;
+ (NSSelection *)currentSelection;
+ (NSSelection *)emptySelection;

//
// Creating and Initializing a Selection
//
+ (NSSelection *)selectionWithDescriptionData:(NSData *)data;
- (id)initWithDescriptionData:(NSData *)newData;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;

//
// Describing a Selection
//
- (NSData *)descriptionData;
- (BOOL)isWellKnownSelection;

//
// Writing a Selection to the Pasteboard
//
- (void)writeToPasteboard:(NSPasteboard *)pasteboard;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSSelection
