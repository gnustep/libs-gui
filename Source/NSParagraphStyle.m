/* 
   NSParagraphStyle.m

     NSParagraphStyle and NSMutableParagraphStyle hold paragraph style 
     information NSTextTab holds information about a single tab stop

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   
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

#import <Foundation/Foundation.h>
#include <AppKit/NSParagraphStyle.h>


@implementation NSTextTab
- initWithType:(NSTextTabType)type location:(float)loc
{	self=[super init];
	tabStopType=type; location=loc;
	return self;
}
-(float) location {return location;}
-(NSTextTabType) tabStopType {return tabStopType;}
@end

@implementation NSParagraphStyle

+ (NSParagraphStyle *)defaultParagraphStyle
{
}

/* "Leading": distance between the bottom of one line fragment and top of next (applied between lines in the same container). Can't be negative. This value is included in the line fragment heights in layout manager. */
-(float)lineSpacing
{
}

/* Distance between the bottom of this paragraph and top of next. */
-(float) paragraphSpacing
{
}
-(NSTextAlignment) alignment
{
}

/* The following values are relative to the appropriate margin (depending on the paragraph direction) */

/* Distance from margin to front edge of paragraph */
-(float) headIndent
{
}

/* Distance from margin to back edge of paragraph; if negative or 0, from other margin */
-(float) tailIndent
{
}

/* Distance from margin to edge appropriate for text direction */
-(float) firstLineHeadIndent
{
}

/* Distance from margin to tab stops */
-(NSArray *) tabStops
{
}

/* Line height is the distance from bottom of descenders to top of ascenders; basically the line fragment height. Does not include lineSpacing (which is added after this computation). */
-(float) minimumLineHeight
{
}

/* 0 implies no maximum. */
-(float) maximumLineHeight
{
} 

-(NSLineBreakMode) lineBreakMode
{
}

//@end

///@implementation NSParagraphStyle 

- (void)setLineSpacing:(float)aFloat
{}
- (void)setParagraphSpacing:(float)aFloat
{}
- (void)setAlignment:(NSTextAlignment)alignment
{}
- (void)setFirstLineHeadIndent:(float)aFloat
{}
- (void)setHeadIndent:(float)aFloat
{}
- (void)setTailIndent:(float)aFloat
{}
- (void)setLineBreakMode:(NSLineBreakMode)mode
{}
- (void)setMinimumLineHeight:(float)aFloat
{}
- (void)setMaximumLineHeight:(float)aFloat
{}
- (void)addTabStop:(NSTextTab *)anObject
{}
- (void)removeTabStop:(NSTextTab *)anObject
{}
- (void)setTabStops:(NSArray *)array
{}
- (void)setParagraphStyle:(NSParagraphStyle *)obj
{}

@end
