/* 
   NSStringDrawing.m

   Categories which add measure capabilities to NSAttributedString 
   and NSString.

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
										// by default tabs are measured as one
#define TABWIDTH 3						// char so this value is set to one 
										// minus the default tab width of 4

@implementation NSString (NSStringDrawing)

- (NSSize)sizeWithAttributes:(NSDictionary *)attrs
{
NSFont *font;
const char *str = [self cString];
int i = 0, j = TABWIDTH;
static float tabSize;
static float pointSize;
static NSFont *lastFont = nil;

	while(*str != '\0')								// calc the additional size 
		{											// to be added for tabs.  
		if(*str++ == '\t')			
			{										// j is initialized to the 
			i += j;									// max number of spaces					  
			j = TABWIDTH;							// needed per tab.  it then 
			}										// varies in order to align 
		else										// tabs to even multiples   
			j = j-- > 0 ? j : TABWIDTH;				// of TABWIDTH + 1.
		};							
															// if font is not
	if(!(font = [attrs objectForKey:NSFontAttributeName]))	// specified, use
		font = [NSFont userFontOfSize:12];					// the default

	if(font != lastFont)									// update font info 
		{													// if font changes 
		tabSize = (float)i * [font widthOfString:@"\t"];
		lastFont = font;
		pointSize = [font pointSize];
		}
	
	return NSMakeSize(([font widthOfString:self] + tabSize), pointSize);
}

@end

@implementation NSAttributedString (NSStringDrawing)

- (NSSize)size												// this method is 
{															// untested FIX ME	
NSFont *font;
unsigned int length;
NSRange effectiveRange;
NSString *subString;
float pointSize;
float sumOfCharacterRange = 0;

	length = [self length];
	effectiveRange = NSMakeRange(0, 0);

	while (NSMaxRange(effectiveRange) < length) 
		{
		font = (NSFont*)[self attribute:NSFontAttributeName
        			 		  atIndex:NSMaxRange(effectiveRange) 
					 		  effectiveRange:&effectiveRange];
		subString = [self substringFromRange:effectiveRange];
		sumOfCharacterRange += [font widthOfString:subString];
		pointSize = MAX([font pointSize], pointSize);
		}
	
	return NSMakeSize(sumOfCharacterRange, pointSize);
}

@end
