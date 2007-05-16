/* 
   NSFontDescriptor.h

   Holds an image to use as a cursor

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: 2006
   
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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/ 


#ifndef _GNUstep_H_NSFontDescriptor
#define _GNUstep_H_NSFontDescriptor

#import "Foundation/NSSet.h"
#import "AppKit/NSController.h"
#import "AppKit/NSAffineTransform.h"

@class NSString;
@class NSCoder;

typedef uint32_t NSFontSymbolicTraits;

typedef enum _NSFontFamilyClass
{
	NSFontUnknownClass = 0 << 28,
	NSFontOldStyleSerifsClass = 1 << 28,
	NSFontTransitionalSerifsClass = 2 << 28,
	NSFontModernSerifsClass = 3 << 28,
	NSFontClarendonSerifsClass = 4 << 28,
	NSFontSlabSerifsClass = 5 << 28,
	NSFontFreeformSerifsClass = 7 << 28,
	NSFontSansSerifClass = 8 << 28,
	NSFontOrnamentalsClass = 9 << 28,
	NSFontScriptsClass = 10 << 28,
	NSFontSymbolicClass = 12 << 28
} NSFontFamilyClass;

enum _NSFontTrait
{
	NSFontItalicTrait = 0x0001,
	NSFontBoldTrait = 0x0002,
	NSFontExpandedTrait = 0x0020,
	NSFontCondensedTrait = 0x0040,
	NSFontMonoSpaceTrait = 0x0400,
	NSFontVerticalTrait = 0x0800,
	NSFontUIOptimizedTrait = 0x1000
};

extern NSString *NSFontFamilyAttribute;
extern NSString *NSFontNameAttribute;
extern NSString *NSFontFaceAttribute;
extern NSString *NSFontSizeAttribute; 
extern NSString *NSFontVisibleNameAttribute; 
extern NSString *NSFontColorAttribute;
extern NSString *NSFontMatrixAttribute;
extern NSString *NSFontVariationAttribute;
extern NSString *NSFontCharacterSetAttribute;
extern NSString *NSFontCascadeListAttribute;
extern NSString *NSFontTraitsAttribute;
extern NSString *NSFontFixedAdvanceAttribute;

extern NSString *NSFontSymbolicTrait;
extern NSString *NSFontWeightTrait;
extern NSString *NSFontWidthTrait;
extern NSString *NSFontSlantTrait;

extern NSString *NSFontVariationAxisIdentifierKey;
extern NSString *NSFontVariationAxisMinimumValueKey;
extern NSString *NSFontVariationAxisMaximumValueKey;
extern NSString *NSFontVariationAxisDefaultValueKey;
extern NSString *NSFontVariationAxisNameKey;

@interface NSFontDescriptor : NSObject <NSCoding>
{
	NSDictionary *_attributes;
	void *_backendPrivate;		// caches an FT_Face
}

+ (id) fontDescriptorWithFontAttributes:(NSDictionary *) attributes;
+ (id) fontDescriptorWithName:(NSString *) name matrix:(NSAffineTransform *) matrix;
+ (id) fontDescriptorWithName:(NSString *) name size:(float) size;

- (NSDictionary *) fontAttributes;
- (NSFontDescriptor *) fontDescriptorByAddingAttributes:(NSDictionary *) attributes;
- (NSFontDescriptor *) fontDescriptorWithFace:(NSString *) face;
- (NSFontDescriptor *) fontDescriptorWithFamily:(NSString *) family;
- (NSFontDescriptor *) fontDescriptorWithMatrix:(NSAffineTransform *) matrix;
- (NSFontDescriptor *) fontDescriptorWithSize:(float) size;
- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:(NSFontSymbolicTraits) traits;
- (id) initWithFontAttributes:(NSDictionary *) attributes;
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys:(NSSet *) keys;
- (NSAffineTransform *) matrix;
- (id) objectForKey:(NSString *) attribute;
- (float) pointSize;
- (NSString *) postscriptName;
- (NSFontSymbolicTraits) symbolicTraits;

@end

#endif /* _GNUstep_H_NSFontDescriptor */
