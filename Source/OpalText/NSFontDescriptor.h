/* 
   NSFontDescriptor.h

   Holds an image to use as a cursor

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: 2006
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 


#ifndef _GNUstep_H_NSFontDescriptor
#define _GNUstep_H_NSFontDescriptor

#import <Foundation/NSObject.h>

@class NSArray;
@class NSCoder;
@class NSDictionary;
@class NSSet;
@class NSString;
@class NSAffineTransform;


typedef uint32_t NSFontSymbolicTraits;

typedef enum _NSFontFamilyClass
{
  NSFontUnknownClass = 0 << 28,
  NSFontOldStyleSerifsClass = 1U << 28,
  NSFontTransitionalSerifsClass = 2U << 28,
  NSFontModernSerifsClass = 3U << 28,
  NSFontClarendonSerifsClass = 4U << 28,
  NSFontSlabSerifsClass = 5U << 28,
  NSFontFreeformSerifsClass = 7U << 28,
  NSFontSansSerifClass = 8U << 28,
  NSFontOrnamentalsClass = 9U << 28,
  NSFontScriptsClass = 10U << 28,
  NSFontSymbolicClass = 12U << 28
} NSFontFamilyClass;

enum _NSFontFamilyClassMask {
    NSFontFamilyClassMask = 0xF0000000
};

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

// FIXME: Document these with the value type

NSString *NSFontFamilyAttribute;
NSString *NSFontNameAttribute;
NSString *NSFontFaceAttribute;
NSString *NSFontSizeAttribute; 
NSString *NSFontVisibleNameAttribute; 
NSString *NSFontColorAttribute;
/**
 * NOTE: NSFontMatrixAttribute is a NSAffineTransform, unlike kCTFontMatrixAttribute which 
 * is an NSData containing a CGAffineTransform struct.
 */
NSString *NSFontMatrixAttribute;
NSString *NSFontVariationAttribute;
NSString *NSFontCharacterSetAttribute;
NSString *NSFontCascadeListAttribute;
NSString *NSFontTraitsAttribute;
NSString *NSFontFixedAdvanceAttribute;

NSString *NSFontSymbolicTrait;
NSString *NSFontWeightTrait;
NSString *NSFontWidthTrait;
NSString *NSFontSlantTrait;

NSString *NSFontVariationAxisIdentifierKey;
NSString *NSFontVariationAxisMinimumValueKey;
NSString *NSFontVariationAxisMaximumValueKey;
NSString *NSFontVariationAxisDefaultValueKey;
NSString *NSFontVariationAxisNameKey;

@interface NSFontDescriptor : NSObject <NSCopying>
{
  NSDictionary *_attributes;
}

+ (id) fontDescriptorWithFontAttributes: (NSDictionary *)attributes;
+ (id) fontDescriptorWithName: (NSString *)name
                         size: (CGFloat)size;
+ (id) fontDescriptorWithName: (NSString *)name
                       matrix: (NSAffineTransform *)matrix;
/**
 * Returns the attribute dictionary for this descriptor.
 * NOTE: This dictionary won't necessairly contain everything -objectForKey:
 * returns a value for (i.e. -objectForKey: may access a system font pattern)
 */
- (NSDictionary *) fontAttributes;
- (id) initWithFontAttributes: (NSDictionary *)attributes;

- (NSFontDescriptor *) fontDescriptorByAddingAttributes:
  (NSDictionary *)attributes;
- (NSFontDescriptor *) fontDescriptorWithFace: (NSString *)face;
- (NSFontDescriptor *) fontDescriptorWithFamily: (NSString *)family;
- (NSFontDescriptor *) fontDescriptorWithMatrix: (NSAffineTransform *)matrix;
- (NSFontDescriptor *) fontDescriptorWithSize: (CGFloat)size;
- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:
  (NSFontSymbolicTraits)traits;
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;

- (id) objectForKey: (NSString *)attribute;
- (NSAffineTransform *) matrix;
- (CGFloat) pointSize;
- (NSString *) postscriptName;
- (NSFontSymbolicTraits) symbolicTraits;
- (NSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys: (NSSet *)keys;

//
// CTFontDescriptor private
//

- (id) localizedObjectForKey: (NSString*)key language: (NSString*)language;

//
// CTFontDescriptor private; to be overridden in subclasses
//

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;
- (id) objectFromPlatformFontPatternForKey: (NSString *)attribute;
- (id) localizedObjectFromPlatformFontPatternForKey: (NSString*)key language: (NSString*)language;

@end

#endif /* _GNUstep_H_NSFontDescriptor */
