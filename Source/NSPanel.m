/* 
   NSPanel.m

   Panel window class

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
#include <AppKit/NSPanel.h>



@implementation NSPanel

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSPanel class])
		[self setVersion:1];
}

//
// Instance methods
//
- init
{
int style = NSTitledWindowMask | NSClosableWindowMask;

	return [self initWithContentRect:NSZeroRect 
				 styleMask:style
				 backing:NSBackingStoreBuffered 
				 defer:NO];
}

//
// Determining the Panel's Behavior 
//
- (BOOL)isFloatingPanel					{ return _isFloatingPanel; }
- (void)setFloatingPanel:(BOOL)flag		{ _isFloatingPanel = flag; }
- (BOOL)worksWhenModal					{  return _worksWhenModal; }
- (void)setWorksWhenModal:(BOOL)flag	{ _worksWhenModal = flag; }
- (BOOL)becomesKeyOnlyIfNeeded			{ return _becomesKeyOnlyIfNeeded; }

- (void)setBecomesKeyOnlyIfNeeded:(BOOL)flag
{
	_becomesKeyOnlyIfNeeded = flag;
}

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
