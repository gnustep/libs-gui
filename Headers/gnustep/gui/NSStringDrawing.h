/* 
   NSStringDrawing.h

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

#ifndef _GNUstep_H_NSStringDrawing
#define _GNUstep_H_NSStringDrawing

#include <Foundation/NSString.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSGeometry.h>
#include <gnustep/base/preface.h>

						// global NSString attribute names used in ascessing  
						// the respective property in a text attributes 
						// dictionary.  if the key is not in the dictionary 	
						// the default value is assumed  											
extern NSString *NSFontAttributeName;    			// NSFont, Helvetica 12
extern NSString *NSParagraphStyleAttributeName;	 	// defaultParagraphStyle
extern NSString *NSForegroundColorAttributeName; 	// NSColor, blackColor
extern NSString *NSUnderlineStyleAttributeName;   	// NSNumber int, 0 no line 	 
extern NSString *NSSuperscriptAttributeName;      	// NSNumber int, 0		 
extern NSString *NSBackgroundColorAttributeName;	// NSColor, nil	
extern NSString *NSAttachmentAttributeName;         // NSTextAttachment, nil	 
extern NSString *NSLigatureAttributeName;			// NSNumber int, 1 
extern NSString *NSBaselineOffsetAttributeName;  	// NSNumber float, 0 points 
extern NSString *NSKernAttributeName;				// NSNumber float, 0
//
//	Extended definitions:
//
//		NSParagraphStyleAttributeName		NSParagraphStyle, default is 
//											defaultParagraphStyle
//
//		NSKernAttributeName					NSNumber float, offset from 
//		 									baseline, amount to modify default 
//											kerning, if 0 kerning is off		 	 

enum 									
{											// Currently supported values for
    NSSingleUnderlineStyle = 1				// NSUnderlineStyleAttributeName
};


@interface NSString (NSStringDrawing)

- (NSSize)sizeWithAttributes:(NSDictionary *)attrs;

@end

@interface NSAttributedString (NSStringDrawing)

- (NSSize)size;

@end

#endif /* _GNUstep_H_NSStringDrawing */
