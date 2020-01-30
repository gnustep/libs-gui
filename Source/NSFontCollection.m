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

#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <AppKit/NSFontCollection.h>
#import <GNUstepGUI/GSFontInfo.h>

// NOTE: Some of this cannot be implemented currently since the backend does not support physically
// moving fonts on the filesystem...  this is here for compatilibility for now.
@interface NSMutableFontCollection (Private)

- (void) _setFonts: (NSArray *)fonts;
- (void) _setQueryAttributes: (NSArray *)queryAttributes;

@end

@implementation NSMutableFontCollection (Private)

- (void) _setFonts: (NSArray *)fonts
{
  [_fonts addObjectsFromArray: fonts];
}

- (void) _setQueryAttributes: (NSArray *)queryAttributes
{
  ASSIGN(_queryAttributes, [queryAttributes mutableCopy]);
}

@end

@interface NSCTFontCollection : NSObject
@end

@implementation NSCTFontCollection
@end

@implementation NSFontCollection 

static NSMutableDictionary *__sharedFontCollections;
static NSMutableDictionary *__sharedFontCollectionsVisibility;
static NSMutableSet *__sharedFontCollectionsHidden;

+ (void) initialize
{
  if (self == [NSFontCollection class])
    {
      __sharedFontCollections = [[NSMutableDictionary alloc] initWithCapacity: 100];
      __sharedFontCollectionsVisibility = [[NSMutableDictionary alloc] initWithCapacity: 100];
      __sharedFontCollectionsHidden = [[NSMutableSet alloc] initWithCapacity: 100];

      [__sharedFontCollections setObject: [NSFontCollection fontCollectionWithAllAvailableDescriptors]
                                  forKey: NSFontCollectionAllFonts];
    }
}

// Initializers...
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _fonts = [[NSMutableArray alloc] initWithCapacity: 50];
      _queryDescriptors = [[NSMutableArray alloc] initWithCapacity: 10];
      _exclusionDescriptors = [[NSMutableArray alloc] initWithCapacity: 10];
      _queryAttributes = [[NSMutableArray alloc] initWithCapacity: 10];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_fonts);
  RELEASE(_queryDescriptors);
  RELEASE(_exclusionDescriptors);
  RELEASE(_queryAttributes);
  [super dealloc];
}

// This method will get the actual list of fonts
- (void) _runQueryWithDescriptors: (NSArray *)queryDescriptors
{
  NSEnumerator *en = [queryDescriptors objectEnumerator];
  GSFontEnumerator *fen = [GSFontEnumerator sharedEnumerator];
  id d = nil;

  ASSIGNCOPY(_queryDescriptors, queryDescriptors);
  while ((d = [en nextObject]) != nil)
    {
      NSArray *names = [fen availableFontNamesMatchingFontDescriptor: d];
      id name = nil;

      en = [names objectEnumerator];
      while ((name = [en nextObject]) != nil)
        {
          NSFont *font = [NSFont fontWithName: name size: 0.0]; // get default size
          [_fonts addObject: font];
        }
    }
}

+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSFontCollection *fc = [[NSFontCollection alloc] init];
  ASSIGNCOPY(fc->_queryDescriptors, queryDescriptors);
  return fc;
}

+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return [self fontCollectionWithDescriptors:
                 [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
}

+ (NSFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return [self fontCollectionWithAllAvailableDescriptors];
}

+ (BOOL) showFontCollection: (NSFontCollection *)collection
                   withName: (NSFontCollectionName)name
                 visibility: (NSFontCollectionVisibility)visibility
                      error: (NSError **)error
{
  NSNumber *v = [NSNumber numberWithInt: visibility];
  [__sharedFontCollections setObject: collection
                             forKey: name];
  [__sharedFontCollectionsVisibility setObject: v
                                        forKey: name];
  return YES;
}

+ (BOOL) hideFontCollectionWithName: (NSFontCollectionName)name
                         visibility: (NSFontCollectionVisibility)visibility
                              error: (NSError **)error
{
  
  [__sharedFontCollectionsHidden addObject: name];
  return YES;
}

+ (BOOL) renameFontCollectionWithName: (NSFontCollectionName)aname
                           visibility: (NSFontCollectionVisibility)visibility
                               toName: (NSFontCollectionName)name
                                error: (NSError **)error
{
  NSFontCollection *fc = [__sharedFontCollections objectForKey: aname];
  [__sharedFontCollections setObject: fc forKey: name];
  return YES;
}

+ (NSArray *) allFontCollectionNames
{
  return [__sharedFontCollections allKeys];
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return [__sharedFontCollections objectForKey: name];
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                   visibility: (NSFontCollectionVisibility)visibility
{
  return [__sharedFontCollections objectForKey: name];
}

// Descriptors
- (NSArray *) queryDescriptors  // copy
{
  return [_queryDescriptors copy];
}

- (NSArray *) exclusionDescriptors
{
  return [_exclusionDescriptors copy];
}

- (NSArray *) matchingDescriptors
{
  return [self matchingDescriptorsWithOptions: nil];
}

- (NSArray *) matchingDescriptorsWithOptions: (NSDictionary *)options
{
  GSFontEnumerator *fen = [GSFontEnumerator sharedEnumerator];
  return [fen matchingFontDescriptorsFor: options];
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family
{
  return [self matchingDescriptorsForFamily: family options: nil];
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family options: (NSDictionary *)options
{
  NSMutableArray *r = [NSMutableArray arrayWithCapacity: 50];
  NSArray *a = [self matchingDescriptorsWithOptions: options];
  NSEnumerator *en = [a objectEnumerator];
  id o = nil;

  while((o = [en nextObject]) != nil)
    {
      if ([[o familyName] isEqualToString: family])
        {
          [r addObject: o];
        }    
    }
  
  return [a copy];
}

- (instancetype) copyWithZone: (NSZone *)zone
{
  NSFontCollection *fc = [[NSFontCollection allocWithZone: zone] init];

  ASSIGNCOPY(fc->_fonts, _fonts);
  ASSIGNCOPY(fc->_queryDescriptors, _queryDescriptors);
  ASSIGNCOPY(fc->_exclusionDescriptors, _exclusionDescriptors);
  ASSIGNCOPY(fc->_queryAttributes, _queryAttributes);

  return fc;
}

- (instancetype) mutableCopyWithZone: (NSZone *)zone
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection allocWithZone: zone] init];

  [fc _setFonts: _fonts];
  [fc setQueryDescriptors: _queryDescriptors];
  [fc setExclusionDescriptors: _exclusionDescriptors];
  [fc _setQueryAttributes: _queryAttributes];

  return fc;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}
  
@end
 

@implementation NSMutableFontCollection 

+ (NSMutableFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection alloc] init];
  ASSIGNCOPY(fc->_queryDescriptors, queryDescriptors);
  return fc;
}

+ (NSMutableFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return [self fontCollectionWithDescriptors:
                 [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
}

+ (NSMutableFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return [self fontCollectionWithAllAvailableDescriptors];
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return [__sharedFontCollections objectForKey: name];
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                          visibility: (NSFontCollectionVisibility)visibility
{
  return [__sharedFontCollections objectForKey: name];
}

- (NSArray *) queryDescriptors
{
  return _queryDescriptors;
}

- (void) setQueryDescriptors: (NSArray *)queryDescriptors
{
  ASSIGN(_queryDescriptors, [queryDescriptors mutableCopy]);
}

- (NSArray *) exclusionDescriptors
{
  return _exclusionDescriptors;
}

- (void) setExclusionDescriptors: (NSArray *)exclusionDescriptors
{
  ASSIGN(_exclusionDescriptors, [exclusionDescriptors mutableCopy]);
}

- (void)addQueryForDescriptors: (NSArray *)descriptors
{
  [_queryDescriptors addObjectsFromArray: descriptors];
}

- (void)removeQueryForDescriptors: (NSArray *)descriptors
{
  [_queryDescriptors removeObjectsInArray: descriptors];
}

@end
