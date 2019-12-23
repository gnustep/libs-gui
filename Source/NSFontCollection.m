/* Implementation of class NSFontCollection
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Tue Dec 10 11:51:33 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <AppKit/NSFontCollection.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
#import <GNUstepGUI/GSFontInfo.h>

// Values for NSFontCollectionAction
NSFontCollectionActionTypeKey const NSFontCollectionWasShown = @"NSFontCollectionWasShown";
NSFontCollectionActionTypeKey const NSFontCollectionWasHidden = @"NSFontCollectionWasHidden";
NSFontCollectionActionTypeKey const NSFontCollectionWasRenamed = @"NSFontCollectionWasRenamed";

// Standard named collections
NSFontCollectionName const NSFontCollectionAllFonts = @"NSFontCollectionAllFonts";
NSFontCollectionName const NSFontCollectionUser = @"NSFontCollectionUser";
NSFontCollectionName const NSFontCollectionFavorites = @"NSFontCollectionFavorites";
NSFontCollectionName const NSFontCollectionRecentlyUsed = @"NSFontCollectionRecentlyUsed";

// Collections
NSFontCollectionMatchingOptionKey const NSFontCollectionIncludeDisabledFontsOption = @"NSFontCollectionIncludeDisabledFontsOption";
NSFontCollectionMatchingOptionKey const NSFontCollectionRemoveDuplicatesOption = @"NSFontCollectionRemoveDuplicatesOption";
NSFontCollectionMatchingOptionKey const NSFontCollectionDisallowAutoActivationOption = @"NSFontCollectionDisallowAutoActivationOption";

@implementation NSFontCollection 

// Initializers...
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _fontEnumerator = [[GSFontEnumerator alloc] init];
      _collectionDictionary = [[NSMutableDictionary alloc] init];
      _queryDescriptors = [[NSMutableArray alloc] init];
      _exclusionDescriptors = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_fontEnumerator);
  RELEASE(_collectionDictionary);
  RELEASE(_queryDescriptors);
  RELEASE(_exclusionDescriptors);
  [super dealloc];
}

+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  return nil;
}

+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return nil;
}

+ (NSFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return nil;
}

+ (BOOL) showFontCollection: (NSFontCollection *)collection
                   withName: (NSFontCollectionName)name
                 visibility: (NSFontCollectionVisibility)visibility
                      error: (NSError **)error
{
  return NO;
}

+ (BOOL) hideFontCollectionWithName: (NSFontCollectionName)name
                         visibility: (NSFontCollectionVisibility)visibility
                              error: (NSError **)error
{
  return NO;
}

+ (BOOL) renameFontCollectionWithName: (NSFontCollectionName)aname
                           visibility: (NSFontCollectionVisibility)visibility
                               toName: (NSFontCollectionName)name
                                error: (NSError **)error
{
  return NO;
}

+ (NSArray *) allFontCollectionNames
{
  NSArray *array = [NSArray arrayWithObjects: NSFontCollectionAllFonts,
                            NSFontCollectionUser,
                            NSFontCollectionFavorites,
                            NSFontCollectionRecentlyUsed, nil];
  return array;
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return nil;
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                   visibility: (NSFontCollectionVisibility)visibility
{
  return nil;
}


// Descriptors
- (NSArray *) queryDescriptors  // copy
{
  return nil;
}

- (NSArray *) exclusionDescriptors
{
  return nil;
}

- (NSArray *) matchingDescriptors
{
  return nil;  
}

- (NSArray *) matchingDescriptorsWithOptions: (NSDictionary *)options
{
  return nil;
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family
{
  return nil;
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family options: (NSDictionary *)options
{
  return nil;
}

- (instancetype) copyWithZone: (NSZone *)zone
{
  return nil;
}

- (instancetype) mutableCopyWithZone: (NSZone *)zone
{
  return nil;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  return nil;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}
  
@end
 

@implementation NSMutableFontCollection 

+ (NSMutableFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  return nil;
}

+ (NSMutableFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return nil;
}

+ (NSMutableFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return nil;
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return nil;
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                          visibility: (NSFontCollectionVisibility)visibility
{
  return nil;
}

- (NSArray *) queryDescriptors
{
  return nil;
}

- (void) setQueryDescriptors: (NSArray *)queryDescriptors
{
}

- (NSArray *) exclusionDescriptors
{
  return nil;
}

- (void) setExclusionDescriptors: (NSArray *)exclusionDescriptors
{
}

- (void)addQueryForDescriptors: (NSArray *)descriptors
{
}

- (void)removeQueryForDescriptors: (NSArray *)descriptors
{
}

@end
