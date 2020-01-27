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

// NOTE: Some of this cannot be implemented currently since the backend does not support physically
// moving fonts on the filesystem...  this is here for compatilibility for now.
@interface NSMutableFontCollection (Private)

- (void) _setFonts: (NSArray *)fonts;

@end

@implementation NSMutableFontCollection (Private)

- (void) _setFonts: (NSArray *)fonts
{
  [_fonts addObjectsFromArray: fonts];
}

@end

@implementation NSFontCollection 

static NSMutableDictionary *__sharedFontCollections;
static NSMutableDictionary *__sharedFontCollectionsVisibility;

+ (void) initialize
{
  if (self == [NSFontCollection class])
    {
      __sharedFontCollections = [[NSMutableDictionary alloc] initWithCapacity: 100];
      __sharedFontCollectionsVisibility = [[NSMutableDictionary alloc] initWithCapacity: 100];
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
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_fonts);
  RELEASE(_queryDescriptors);
  RELEASE(_exclusionDescriptors);
  [super dealloc];
}

+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSFontCollection *fc = [[NSFontCollection alloc] init];
  NSEnumerator *en = [queryDescriptors objectEnumerator];
  GSFontEnumerator *fen = [GSFontEnumerator sharedEnumerator];
  id d = nil;

  ASSIGNCOPY(fc->_queryDescriptors, queryDescriptors);
  while ((d = [en nextObject]) != nil)
    {
      NSArray *names = [fen availableFontNamesMatchingFontDescriptor: d];
      id name = nil;

      en = [names objectEnumerator];
      while ((name = [en nextObject]) != nil)
        {
          NSFont *font = [NSFont fontWithName: name size: 0.0]; // get default size
          [fc->_fonts addObject: font];
        }
    }
  
   return fc;
}

+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return [self fontCollectionWithDescriptors:
                 [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
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
  /*
  if ([__sharedFontCollection objectForKey: name] == nil)
    {
      NSNumber *v = [NSNumber numberWithInt: visibility];
      [__sharedFontCollection setObject: collection forKey: name];
      [__sharedFontCollectionVisibility setObject: visibility forKey: name];
      return YES;
    }
  else
    {
      error = [NSError errorWithDomain: NSCocoaErrorDomain code: 0 userInfo: nil];
    }
  */
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
  return _queryDescriptors;
}

- (NSArray *) exclusionDescriptors
{
  return _exclusionDescriptors;
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
  ASSIGNCOPY(fc->_fonts, _exclusionDescriptors);

  return fc;
}

- (instancetype) mutableCopyWithZone: (NSZone *)zone
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection allocWithZone: zone] init];

  [fc _setFonts: _fonts];
  [fc setQueryDescriptors: _queryDescriptors];
  [fc setExclusionDescriptors: _exclusionDescriptors];

  return fc;
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
