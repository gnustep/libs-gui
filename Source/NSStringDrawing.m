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
const char *str = [self cString];
int i = 0, j = 4;
float tabSize;

	while(*str++ != '\0')									// count the tabs
		{
		if(*str == '\t')
			{
			i += j;
			j = 4;
			}
		else
			j = j == 0 ? 4 : j--;
		};
															// if font is not
	if(!(font = [attrs objectForKey:NSFontAttributeName]))	// specified, use
		font = [NSFont userFontOfSize:12];					// the default

fprintf(stderr,"string %s  width: %f\n", [self cString], [font widthOfString:self]);	

//	tabSize = 4 * i * [font widthOfString:@" "];
	tabSize = (float)i * [font widthOfString:@" "];
	
	return NSMakeSize(([font widthOfString:self] + tabSize), [font pointSize]);
}

@end
