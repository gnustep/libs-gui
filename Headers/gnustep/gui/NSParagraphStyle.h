/* 
   NSParagraphStyle.h

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
#import "NSText.h"

typedef enum _NSTextTabType {
    NSLeftTabStopType = 0,
    NSRightTabStopType,
    NSCenterTabStopType,
    NSDecimalTabStopType
} NSTextTabType;

typedef enum _NSLineBreakMode {		/* What to do with long lines */
    NSLineBreakByWordWrapping = 0,     	/* Wrap at word boundaries, default */
    NSLineBreakByCharWrapping,		/* Wrap at character boundaries */
    NSLineBreakByClipping,		/* Simply clip */
    NSLineBreakByTruncatingHead,	/* Truncate at head of line: "...wxyz" */
    NSLineBreakByTruncatingTail,	/* Truncate at tail of line: "abcd..." */
    NSLineBreakByTruncatingMiddle	/* Truncate middle of line:  "ab...yz" */
} NSLineBreakMode;

@interface NSTextTab : NSObject <NSCopying, NSCoding>
{	NSTextTabType	tabStopType;
	float			location;
}
- initWithType:(NSTextTabType)type location:(float)loc;
-(float) location;
-(NSTextTabType) tabStopType;
@end

@interface NSParagraphStyle : NSObject <NSCopying, NSMutableCopying, NSCoding>
{	float lineSpacing;
	float paragraphSpacing;
	float headIndent;
	float tailIndent;
	float firstLineHeadIndent;
	float minimumLineHeight,maximumLineHeight;
    NSArray *tabStops;
	NSTextAlignment alignment;
	NSLineBreakMode lineBreakMode;
	unsigned int refCount;
}

+ (NSParagraphStyle *)defaultParagraphStyle;

- (float)lineSpacing;		/* "Leading": distance between the bottom of one line fragment and top of next (applied between lines in the same container). Can't be negative. This value is included in the line fragment heights in layout manager. */
- (float)paragraphSpacing; 	/* Distance between the bottom of this paragraph and top of next. */
- (NSTextAlignment)alignment;

/* The following values are relative to the appropriate margin (depending on the paragraph direction) */
   
- (float)headIndent;		/* Distance from margin to front edge of paragraph */
- (float)tailIndent;		/* Distance from margin to back edge of paragraph; if negative or 0, from other margin */
- (float)firstLineHeadIndent;	/* Distance from margin to edge appropriate for text direction */
- (NSArray *)tabStops;		/* Distance from margin to tab stops */

- (float)minimumLineHeight;	/* Line height is the distance from bottom of descenders to top of ascenders; basically the line fragment height. Does not include lineSpacing (which is added after this computation). */
- (float)maximumLineHeight;	/* 0 implies no maximum. */ 

- (NSLineBreakMode)lineBreakMode;

@end

@interface NSMutableParagraphStyle : NSParagraphStyle

- (void)setLineSpacing:(float)aFloat;
- (void)setParagraphSpacing:(float)aFloat;
- (void)setAlignment:(NSTextAlignment)alignment;
- (void)setFirstLineHeadIndent:(float)aFloat;
- (void)setHeadIndent:(float)aFloat;
- (void)setTailIndent:(float)aFloat;
- (void)setLineBreakMode:(NSLineBreakMode)mode;
- (void)setMinimumLineHeight:(float)aFloat;
- (void)setMaximumLineHeight:(float)aFloat;
- (void)addTabStop:(NSTextTab *)anObject;
- (void)removeTabStop:(NSTextTab *)anObject;
- (void)setTabStops:(NSArray *)array;
- (void)setParagraphStyle:(NSParagraphStyle *)obj;

@end
