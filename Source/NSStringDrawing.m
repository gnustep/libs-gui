/* 
   NSStringDrawing.m

   Category which adds measure capabilities to NSString.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Aug 1998
   
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

#include <AppKit/NSStringDrawing.h>
#include <AppKit/AppKit.h>


@implementation NSString(NSStringDrawing)

- (NSSize)sizeWithAttributes:(NSDictionary *)attrs
{
NSFont *font;
															// if font is not
	if(!(font = [attrs objectForKey:NSFontAttributeName]))	// specified, use
		font = [NSFont userFontOfSize:12];					// the default

	return NSMakeSize([font widthOfString:self], [font pointSize]);
}

@end
