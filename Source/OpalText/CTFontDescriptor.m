/** <title>CTFontDescriptor</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

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

#include <CoreText/CTFontDescriptor.h>
#include <CoreText/CTFont.h>

#import <Foundation/NSLocale.h>
#import "NSFontDescriptor.h"

/* Constants */

// FIXME: Some of these have to have NS... values

const CFStringRef kCTFontURLAttribute = @"kCTFontURLAttribute";
const CFStringRef kCTFontNameAttribute = @"kCTFontNameAttribute";
const CFStringRef kCTFontDisplayNameAttribute = @"kCTFontDisplayNameAttribute";
const CFStringRef kCTFontFamilyNameAttribute = @"kCTFontFamilyNameAttribute";
const CFStringRef kCTFontStyleNameAttribute = @"kCTFontStyleNameAttribute";
const CFStringRef kCTFontTraitsAttribute = @"kCTFontTraitsAttribute";
const CFStringRef kCTFontVariationAttribute = @"kCTFontVariationAttribute";
const CFStringRef kCTFontSizeAttribute = @"kCTFontSizeAttribute";
const CFStringRef kCTFontMatrixAttribute = @"kCTFontMatrixAttribute";
const CFStringRef kCTFontCascadeListAttribute = @"kCTFontCascadeListAttribute";
const CFStringRef kCTFontCharacterSetAttribute = @"kCTFontCharacterSetAttribute";
const CFStringRef kCTFontLanguagesAttribute = @"kCTFontLanguagesAttribute";
const CFStringRef kCTFontBaselineAdjustAttribute = @"kCTFontBaselineAdjustAttribute";
const CFStringRef kCTFontMacintoshEncodingsAttribute = @"kCTFontMacintoshEncodingsAttribute";
const CFStringRef kCTFontFeaturesAttribute = @"kCTFontFeaturesAttribute";
const CFStringRef kCTFontFeatureSettingsAttribute = @"kCTFontFeatureSettingsAttribute";
const CFStringRef kCTFontFixedAdvanceAttribute = @"kCTFontFixedAdvanceAttribute";
const CFStringRef kCTFontOrientationAttribute = @"kCTFontOrientationAttribute";
const CFStringRef kCTFontEnabledAttribute = @"kCTFontEnabledAttribute";
const CFStringRef kCTFontFormatAttribute = @"kCTFontFormatAttribute";
const CFStringRef kCTFontRegistrationScopeAttribute = @"kCTFontRegistrationScopeAttribute";
const CFStringRef kCTFontPriorityAttribute = @"kCTFontPriorityAttribute";


/* Functions */

CTFontDescriptorRef CTFontDescriptorCreateWithNameAndSize(
  CFStringRef name,
  CGFloat size)
{
  return [[NSFontDescriptor fontDescriptorWithName: name size: size] retain];
}

CTFontDescriptorRef CTFontDescriptorCreateWithAttributes(CFDictionaryRef attributes)
{
  return [[NSFontDescriptor fontDescriptorWithFontAttributes: attributes] retain];
}
  
CTFontDescriptorRef CTFontDescriptorCreateCopyWithAttributes(
  CTFontDescriptorRef original,
  CFDictionaryRef attributes)
{
  return [[original fontDescriptorByAddingAttributes: attributes] retain];
}

CTFontDescriptorRef CTFontDescriptorCreateCopyWithVariation(
  CTFontDescriptorRef original,
  CFNumberRef variationIdentifier,
  CGFloat variationValue)
{
  NSMutableDictionary *newVariation = [[original objectForKey: kCTFontVariationAttribute] mutableCopy];
  if (nil == newVariation)
  {
    newVariation = [[NSMutableDictionary alloc] init];
  }
  [newVariation setObject: [NSNumber numberWithDouble: variationValue]
                   forKey: variationIdentifier];

  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    newVariation, kCTFontVariationAttribute,
    nil];

  [newVariation release];

  return CTFontDescriptorCreateCopyWithAttributes(original, attributes);
}

CTFontDescriptorRef CTFontDescriptorCreateCopyWithFeature(
  CTFontDescriptorRef original,
  CFNumberRef featureTypeIdentifier,
  CFNumberRef featureSelectorIdentifier)
{
  NSMutableArray *newFeatureSettings = [[original objectForKey: kCTFontFeatureSettingsAttribute] mutableCopy];
  if (nil == newFeatureSettings)
  {
    newFeatureSettings = [[NSMutableArray alloc] init];
  }
  [newFeatureSettings addObject:
    [NSDictionary dictionaryWithObjectsAndKeys:
      featureTypeIdentifier, kCTFontFeatureTypeIdentifierKey,
      featureSelectorIdentifier, kCTFontFeatureSelectorIdentifierKey,
      nil]];

  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    newFeatureSettings, kCTFontFeatureSettingsAttribute,
    nil];

  [newFeatureSettings release];

  return CTFontDescriptorCreateCopyWithAttributes(original, attributes);
}

CFArrayRef CTFontDescriptorCreateMatchingFontDescriptors(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes)
{
  return [[descriptor matchingFontDescriptorsWithMandatoryKeys: mandatoryAttributes] retain];
}

CTFontDescriptorRef CTFontDescriptorCreateMatchingFontDescriptor(
  CTFontDescriptorRef descriptor,
  CFSetRef mandatoryAttributes)
{
  return [[descriptor matchingFontDescriptorWithMandatoryKeys: mandatoryAttributes] retain];
}

CFDictionaryRef CTFontDescriptorCopyAttributes(CTFontDescriptorRef descriptor)
{
  return [[descriptor fontAttributes] retain];
}

CFTypeRef CTFontDescriptorCopyAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute)
{
  return [[descriptor objectForKey: attribute] retain];
}

CFTypeRef CTFontDescriptorCopyLocalizedAttribute(
  CTFontDescriptorRef descriptor,
  CFStringRef attribute,
  CFStringRef *language)
{
  NSArray *preferredLanguages = [NSLocale preferredLanguages];
  if ([preferredLanguages count] > 0)
  {
    NSString *preferredLanguage = [preferredLanguages objectAtIndex: 0];
    id localizedValue = [descriptor localizedObjectForKey: attribute language: preferredLanguage];
    if (localizedValue)
    {
      if (language)
      {
        *language = preferredLanguage;
      }
      return [localizedValue retain];
    }
  }
  return CTFontDescriptorCopyAttribute(descriptor, attribute);
}

CFTypeID CTFontDescriptorGetTypeID()
{
  return (CFTypeID)[NSFontDescriptor class];
}

