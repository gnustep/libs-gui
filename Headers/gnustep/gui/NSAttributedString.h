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

#ifndef	STRICT_OPENSTEP

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSRange.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSText.h>
#include <AppKit/AppKitDefines.h>

@class NSTextAttachment;
@class NSFileWrapper;
@class NSString;
@class NSDictionary;
@class NSData;
@class NSArray;
@class NSURL;

/* Global NSString attribute names used in accessing the respective
   property in a text attributes dictionary.  if the key is not in the
   dictionary the default value is assumed.  */
APPKIT_EXPORT NSString *NSFontAttributeName;
APPKIT_EXPORT NSString *NSParagraphStyleAttributeName;
APPKIT_EXPORT NSString *NSForegroundColorAttributeName;
APPKIT_EXPORT NSString *NSUnderlineStyleAttributeName;
APPKIT_EXPORT NSString *NSSuperscriptAttributeName;
APPKIT_EXPORT NSString *NSBackgroundColorAttributeName;
APPKIT_EXPORT NSString *NSAttachmentAttributeName;
APPKIT_EXPORT NSString *NSLigatureAttributeName;
APPKIT_EXPORT NSString *NSBaselineOffsetAttributeName;
APPKIT_EXPORT NSString *NSKernAttributeName;
APPKIT_EXPORT NSString *NSLinkAttributeName;

/* Currently supported values for NSUnderlineStyleAttributeName.  */
enum 									
{
  GSNoUnderlineStyle = 0,
  NSSingleUnderlineStyle = 1
};

@interface NSAttributedString (AppKit)
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

#ifndef STRICT_OPENSTEP
+ (NSArray *) textFileTypes;
+ (NSArray *) textPasteboardTypes;
+ (NSArray *) textUnfilteredFileTypes;
+ (NSArray *) textUnfilteredPasteboardTypes;
#endif
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

- (BOOL) readFromURL: (NSURL *)url
	     options: (NSDictionary *)options
  documentAttributes: (NSDictionary**)documentAttributes;
@end

#endif

#endif

