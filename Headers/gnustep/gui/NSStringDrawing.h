/* 
   NSStringDrawing.h

   Categories which add measure capabilities to NSAttributedString 
   and NSString.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Aug 1998
   Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Mar 1999
   
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

// global NSString attribute names used in accessing  
// the respective property in a text attributes 
// dictionary.  if the key is not in the dictionary 	
// the default value is assumed  											
extern NSString *NSFontAttributeName;
extern NSString *NSParagraphStyleAttributeName;
extern NSString *NSForegroundColorAttributeName;
extern NSString *NSUnderlineStyleAttributeName;
extern NSString *NSSuperscriptAttributeName;
extern NSString *NSBackgroundColorAttributeName;
extern NSString *NSAttachmentAttributeName;
extern NSString *NSLigatureAttributeName;
extern NSString *NSBaselineOffsetAttributeName;
extern NSString *NSKernAttributeName;

// Currently supported values for NSUnderlineStyleAttributeName
enum 									
{
  GSNoUnderlineStyle = 0,
  NSSingleUnderlineStyle = 1
};


@interface NSString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point withAttributes: (NSDictionary*)attrs;
- (void) drawInRect: (NSRect)rect withAttributes: (NSDictionary*)attrs;
- (NSSize) sizeWithAttributes: (NSDictionary*)attrs;

@end

@interface NSAttributedString (NSStringDrawing)

- (NSSize) size;
- (void) drawAtPoint: (NSPoint)point;
- (void) drawInRect: (NSRect)rect;

@end

#endif /* _GNUstep_H_NSStringDrawing */
