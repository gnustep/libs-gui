/* 
   NSStringDrawing.h

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

#ifndef _GNUstep_H_NSStringDrawing
#define _GNUstep_H_NSStringDrawing

#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>
#include <gnustep/base/preface.h>

						// global NSString attribute names used in ascessing  
						// the respective property in a text attributes 
						// dictionary.  if the key is not in the dictionary the 	
						// default value is assumed  											
NSString *NSFontAttributeName;    			// NSFont, defaults to Helvetica 12        
NSString *NSParagraphStyleAttributeName;	// NSParagraphStyle, default to 
											// defaultParagraphStyle
NSString *NSForegroundColorAttributeName;  	// NSColor, default is blackColor
NSString *NSUnderlineStyleAttributeName;   	// int, default 0 = no underline 
NSString *NSSuperscriptAttributeName;      	// int, default 0 
NSString *NSBackgroundColorAttributeName;	// NSColor,default nil =no back col 
NSString *NSAttachmentAttributeName;       	// NSTextAttachment, default nil 
NSString *NSLigatureAttributeName;         	// int, default 1 
											// 1 = default ligatures, 
											// 0 = no ligatures, 
											// 2 = all ligatures 
NSString *NSBaselineOffsetAttributeName;   	// float, default 0 in points; 
											// offset from baseline, 
NSString *NSKernAttributeName;             	// float, amount to modify default 
											// kerning, if 0 kerning is off 
enum 									
{											// Currently supported values for
    NSSingleUnderlineStyle = 1				// NSUnderlineStyleAttributeName
};

@interface NSString(NSStringDrawing)

- (NSSize)sizeWithAttributes:(NSDictionary *)attrs;

@end

#ifdef OS_4_2
@interface NSAttributedString(NSStringDrawing)

- (NSSize)size;

@end
#endif /* OS_4_2 */

#endif /* _GNUstep_H_NSStringDrawing */
