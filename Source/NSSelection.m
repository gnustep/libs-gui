/** <title>NSSelection</title>

   <abstract>NSSelection is used by NSDataLink to refer to a 
                selection within a document.</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Gregory John Casamento <borgheron@yahoo.com>
   Date: 2001

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

#include "gnustep/gui/config.h"
#include <Foundation/NSCoder.h>
#include <Foundation/NSData.h>
#include "AppKit/NSSelection.h"
#include "AppKit/NSPasteboard.h"

//
// Global instances of these selections
//
static NSSelection *_sharedAllSelection = nil;
static NSSelection *_sharedCurrentSelection = nil;
static NSSelection *_sharedEmptySelection = nil;

// Private methods and variables for NSSelection
typedef enum 
{
  GSCustomSelection,
  GSAllSelection,
  GSCurrentSelection,
  GSEmptySelection
} GSSelectionType;

@interface NSSelection (PrivateMethods)
- (void)_setIsWellKnownSelection: (BOOL)wellknown;
- (GSSelectionType)_selectionType;
- (void)_setSelectionType: (GSSelectionType)type;
+ (NSSelection *)_wellKnownSelection: (char *)description;
@end

@implementation NSSelection (PrivateMethods)
- (void)_setIsWellKnownSelection: (BOOL)wellknown
{
  _isWellKnownSelection = wellknown;
}

- (void)_setSelectionType: (GSSelectionType)type
{
  _selectionType = type;
}

- (GSSelectionType)_selectionType
{
  return _selectionType;
}

+ (NSSelection *)_wellKnownSelection: (char *)description
{
  NSData *selectionData = [NSData dataWithBytes: description
				  length: strlen(description)];
  NSSelection *selection = 
    [NSSelection selectionWithDescriptionData: selectionData];

  [selection _setIsWellKnownSelection: YES];

  return selection;
}
@end

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
//
// NOTE: The description returned for each of these is similar to the one
//       returned under OPENSTEP.
//
+ (NSSelection *)allSelection
{
  if(!_sharedAllSelection)
    {
      _sharedAllSelection =
	[NSSelection _wellKnownSelection: "GNUstep All selection marker"];
      [_sharedEmptySelection _setSelectionType: GSAllSelection];
    }
  return _sharedAllSelection;
}

+ (NSSelection *)currentSelection
{
  if(!_sharedCurrentSelection)
    {
      _sharedCurrentSelection =
	[NSSelection _wellKnownSelection: "GNUstep Current selection marker"];
      [_sharedCurrentSelection _setSelectionType: GSCurrentSelection];
    }
  return _sharedCurrentSelection;
}

+ (NSSelection *)emptySelection
{
  if(!_sharedEmptySelection)
    {
      _sharedEmptySelection =
	[NSSelection _wellKnownSelection: "GNUstep Empty selection marker"];
      [_sharedEmptySelection _setSelectionType: GSEmptySelection];
    }
  return _sharedEmptySelection;
}

//
// Creating and Initializing a Selection
//
+ (NSSelection *)selectionWithDescriptionData:(NSData *)data
{
  NSSelection *selection = 
    AUTORELEASE([[NSSelection alloc] initWithDescriptionData: data]);
  return selection;
}

//
// Instance methods
//

//
// Creating and Initializing a Selection
//
- (id)initWithDescriptionData:(NSData *)newData
{
  [super init];
  ASSIGN(_descriptionData, newData);
  _isWellKnownSelection = NO;
  _selectionType = GSCustomSelection;

  return self;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  [super init];
  ASSIGN(_descriptionData, [pasteboard dataForType: NSGeneralPboardType]);
  _isWellKnownSelection = NO;

  return self;
}

//
// Describing a Selection
//
- (NSData *)descriptionData
{
  return _descriptionData;
}

- (BOOL)isWellKnownSelection
{
  return _isWellKnownSelection;
}

//
// Writing a Selection to the Pasteboard
//
- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{
  [pasteboard setData: _descriptionData
	      forType: NSGeneralPboardType];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(BOOL)
	  at: &_isWellKnownSelection];
  [aCoder encodeValueOfObjCType: @encode(int)
	  at: &_selectionType];
  [aCoder encodeValueOfObjCType: @encode(id)
	  at: _descriptionData];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super init];
  [aDecoder decodeValueOfObjCType: @encode(BOOL)
	    at: &_isWellKnownSelection];
  [aDecoder decodeValueOfObjCType: @encode(int)
	    at: &_selectionType];

  // if it's a well known selection then determine which one it is.
  if(_isWellKnownSelection)
    {
      switch(_selectionType)
	{
	case GSAllSelection:
	  RELEASE(self);
	  self = RETAIN([NSSelection allSelection]);
	  break;
	case GSCurrentSelection:
	  RELEASE(self);
	  self = RETAIN([NSSelection currentSelection]);
	  break;
	case GSEmptySelection:
	  RELEASE(self);
	  self = RETAIN([NSSelection emptySelection]);
	  break;
	default:
	  // Shouldn't get here.
	  break;
	}
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(id)
		at: _descriptionData];
    }

  return self;
}

@end
