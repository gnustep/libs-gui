/* 
   NSAttributedString.h

   Category which defines appkit extensions to NSAttributedString and 
   NSMutableAttributedString.

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

#ifndef _GNUstep_H_NSAttributedString
#define _GNUstep_H_NSAttributedString

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSGeometry.h>
#include <gnustep/base/preface.h>

						// global NSString attribute names used in ascessing  
						// the respective property in a text attributes 
						// dictionary.  if the key is not in the dictionary the 	
						// default value is assumed  											
extern NSString *NSFontAttributeName;    	// NSFont, defaults to Helvetica 12
        				// NSParagraphStyle, default is defaultParagraphStyle
extern NSString *NSParagraphStyleAttributeName;	 
											// NSColor, default is blackColor 
extern NSString *NSForegroundColorAttributeName; 
											// int, default 0 = no	underline
extern NSString *NSUnderlineStyleAttributeName;   	 	 
extern NSString *NSSuperscriptAttributeName;      			// int, default 0 
								// NSColor, default nil = no background color
extern NSString *NSBackgroundColorAttributeName;		
extern NSString *NSAttachmentAttributeName;    // NSTextAttachment, default nil     	 
						// int, default 1, 0 = no ligatures, 2 = all ligatures
extern NSString *NSLigatureAttributeName;			 
extern NSString *NSBaselineOffsetAttributeName;  // float, default 0 in points; 
											// float, offset from baseline, 
extern NSString *NSKernAttributeName;		// amount to modify default
											// kerning, if 0 kerning is off 



@interface NSAttributedString (NSAttributedStringKitAdditions)

@end


@interface NSMutableAttributedString (NSMutableAttributedStringKitAdditions)

@end

#endif	/* _GNUstep_H_NSAttributedString */
