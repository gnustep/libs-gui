/* 
   NSAttributedString.h

   Categories which add capabilities to NSAttributedString 

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: July 1999
   
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

#import <Foundation/Foundation.h>
#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSText.h>

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
extern NSString *NSLinkAttributeName;

// Currently supported values for NSUnderlineStyleAttributeName
enum 									
{
  GSNoUnderlineStyle = 0,
  NSSingleUnderlineStyle = 1
};

@interface NSAttributedString (AppKit)
- (BOOL) containsAttachments;
- (NSDictionary*) fontAttributesInRange: (NSRange)range;
- (NSDictionary*) rulerAttributesInRange: (NSRange)range;
- (unsigned) lineBreakBeforeIndex: (unsigned)location
		      withinRange: (NSRange)aRange;
- (NSRange) doubleClickAtIndex: (unsigned)location;
- (unsigned) nextWordFromIndex: (unsigned)location forward: (BOOL)isForward;

- (id) initWithRTF: (NSData*)data documentAttributes: (NSDictionary**)dict;
- (id) initWithRTFD: (NSData*)data documentAttributes: (NSDictionary**)dict;
- (id) initWithPath: (NSString*)path documentAttributes: (NSDictionary**)dict;
- (id) initWithURL: (NSURL*)url documentAttributes: (NSDictionary**)dict;
- (id) initWithRTFDFileWrapper: (NSFileWrapper*)wrapper
  documentAttributes: (NSDictionary**)dict;
- (id) initWithHTML: (NSData*)data documentAttributes: (NSDictionary**)dict;
- (id) initWithHTML: (NSData*)data baseURL: (NSURL*)base
  documentAttributes: (NSDictionary**)dict;

- (NSData*) RTFFromRange: (NSRange)range
  documentAttributes: (NSDictionary*)dict;
- (NSData*) RTFDFromRange: (NSRange)range
  documentAttributes: (NSDictionary*)dict;
- (NSFileWrapper*) RTFDFileWrapperFromRange: (NSRange)range
  documentAttributes: (NSDictionary*)dict;
@end

@interface NSMutableAttributedString (AppKit)
- (void) superscriptRange: (NSRange)range;
- (void) subscriptRange: (NSRange)range;
- (void) unscriptRange: (NSRange)range;
- (void) applyFontTraits: (NSFontTraitMask)traitMask range: (NSRange)range;
- (void) setAlignment: (NSTextAlignment)alignment range: (NSRange)range;

- (void) fixAttributesInRange: (NSRange)range;
- (void) fixFontAttributeInRange: (NSRange)range;
- (void) fixParagraphStyleAttributeInRange: (NSRange)range;
- (void) fixAttachmentAttributeInRange: (NSRange)range;
@end

#endif

