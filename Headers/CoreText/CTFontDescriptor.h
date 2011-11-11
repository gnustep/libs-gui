/** <title>CTFontDescriptor</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Jun 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CTFontDescriptor_h
#define OPAL_CTFontDescriptor_h

#include <CoreGraphics/CGBase.h>
#include <CoreText/CTFontTraits.h>

/* Data Types */

#ifdef __OBJC__
@class NSFontDescriptor;
typedef NSFontDescriptor* CTFontDescriptorRef;
#else
typedef struct NSFontDescriptor* CTFontDescriptorRef;
#endif

/* Constants */

extern const CFStringRef kCTFontURLAttribute;
extern const CFStringRef kCTFontNameAttribute;
extern const CFStringRef kCTFontDisplayNameAttribute;
extern const CFStringRef kCTFontFamilyNameAttribute;
extern const CFStringRef kCTFontStyleNameAttribute;
extern const CFStringRef kCTFontTraitsAttribute;
extern const CFStringRef kCTFontVariationAttribute;
extern const CFStringRef kCTFontSizeAttribute;
extern const CFStringRef kCTFontMatrixAttribute;
extern const CFStringRef kCTFontCascadeListAttribute;
extern const CFStringRef kCTFontCharacterSetAttribute;
extern const CFStringRef kCTFontLanguagesAttribute;
extern const CFStringRef kCTFontBaselineAdjustAttribute;
extern const CFStringRef kCTFontMacintoshEncodingsAttribute;
extern const CFStringRef kCTFontFeaturesAttribute;
extern const CFStringRef kCTFontFeatureSettingsAttribute;
extern const CFStringRef kCTFontFixedAdvanceAttribute;
extern const CFStringRef kCTFontOrientationAttribute;
extern const CFStringRef kCTFontEnabledAttribute;
extern const CFStringRef kCTFontFormatAttribute;
extern const CFStringRef kCTFontRegistrationScopeAttribute;
extern const CFStringRef kCTFontPriorityAttribute;

typedef enum {
  kCTFontDefaultOrientation = 0,
  kCTFontHorizontalOrientation = 1,
  kCTFontVerticalOrientation = 2
} CTFontOrientation;

typedef enum {
  kCTFontFormatUnrecognized = 0,
  kCTFontFormatOpenTypePostScript = 1,
  kCTFontFormatOpenTypeTrueType = 2,
  kCTFontFormatTrueType = 3,
  kCTFontFormatPostScript = 4,
  kCTFontFormatBitmap = 5
} CTFontFormat;

typedef enum {
  kCTFontPrioritySystem = 10000,
  kCTFontPriorityNetwork = 20000,
  kCTFontPriorityComputer = 30000,
  kCTFontPriorityUser = 40000,
  kCTFontPriorityDynamic = 50000,
  kCTFontPriorityProcess = 60000
} CTFontPriority;

/* Functions */

CTFontDescriptorRef CTFontDescriptorCreateWithNameAndSize(
  CFStringRef name,
  CGFloat size
);

CTFontDescriptorRef CTFontDescriptorCreateWithAttributes(CFDictionaryRef attributes);
  
CTFontDescriptorRef CTFontDescriptorCreateCopyWithAttributes(
  CTFontDescriptorRef original,
  CFDictionaryRef attributes
);

CTFontDescriptorRef CTFontDescriptorCreateCopyWithVariation(
  CTFontDescriptorRef original,
  CFNumberRef variationIdentifier,
  CGFloat variationValue
);

CTFontDescriptorRef CTFontDescriptorCreateCopyWithFeature(
  CTFontDescriptorRef original,
  CFNumberRef featureTypeIdentifier,
  CFNumberRef featureSelectorIdentifier
);

CFArrayRef CTFontDescriptorCreateMatchingFontDescriptors(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes
);

CTFontDescriptorRef CTFontDescriptorCreateMatchingFontDescriptor(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes
);

CFDictionaryRef CTFontDescriptorCopyAttributes(CTFontDescriptorRef descriptor);

CFTypeRef CTFontDescriptorCopyAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute
);

CFTypeRef CTFontDescriptorCopyLocalizedAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute,
  CFStringRef *language
);

CFTypeID CTFontDescriptorGetTypeID();

#endif
