/* 
   TrackingRectangle.m

   Tracking rectangle class

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
#include <gnustep/gui/TrackingRectangle.h>

@implementation TrackingRectangle

//
// Class methods
//
+ (void)initialize
{
	if (self == [TrackingRectangle class])
	{
		// Initial version
		[self setVersion:1];
	}
}

//
// Instance methods
//
//
// Initialization
//
- initWithRect:(NSRect)aRect
 tag:(NSTrackingRectTag)aTag
 owner:anObject
 userData:(void *)theData
 inside:(BOOL)flag
{
	rectangle = aRect;
	tag = aTag;
	owner = anObject;
	[owner retain];
	user_data = theData;
	inside = flag;
	return self;
}

- (void)dealloc
{
	[owner release];
	[super dealloc];
}

- (NSRect)rectangle
{
	return rectangle;
}

- (NSTrackingRectTag)tag
{
	return tag;
}

- owner
{
	return owner;
}

- (void *)userData
{
	return user_data;
}

- (BOOL)inside
{
	return inside;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
	[aCoder encodeRect:rectangle];
	[aCoder encodeValueOfObjCType:@encode(NSTrackingRectTag) at:&tag];
	[aCoder encodeObject:owner];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at:&inside];
}

- initWithCoder:aDecoder
{
	rectangle = [aDecoder decodeRect];
	[aDecoder decodeValueOfObjCType:@encode(NSTrackingRectTag) at:&tag];
	[aDecoder decodeValueOfObjCType:@encode(BOOL) at:&inside];
	owner = [aDecoder decodeObject];
	return self;
}

@end
