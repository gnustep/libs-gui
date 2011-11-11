/** <title>CTFontCollection</title>

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

#include <CoreText/CTFontCollection.h>

/* Constants */

const CFStringRef kCTFontCollectionRemoveDuplicatesOption = @"kCTFontCollectionRemoveDuplicatesOption";

/* Classes */

/**
 * Collection of font descriptors
 */
@interface CTFontCollection : NSObject
{
  NSArray *_descriptors;
}

- (id)initWithAvailableFontsWithOptions: (NSDictionary*)opts;
- (id)initWithFontDescriptors: (NSArray*)descriptors 
                      options: (NSDictionary*)opts;

- (CTFontCollection*)collectionByAddingFontDescriptors: (NSArray*)descriptors
                                               options: (NSDictionary*)opts;
- (NSArray*)fontDescriptors;
- (NSArray*)fontDescriptorsSortedWithCallback: (CTFontCollectionSortDescriptorsCallback)cb
                                         info: (void*)info;

@end

@implementation CTFontCollection

- (id)initWithAvailableFontsWithOptions: (NSDictionary*)opts
{
  // FIXME:
  NSArray *allDescriptors = [NSArray array];
  return [self initWithFontDescriptors: allDescriptors options: opts];
}

- (id)initWithFontDescriptors: (NSArray*)descriptors options: (NSDictionary*)opts
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }

  if ([[opts objectForKey: kCTFontCollectionRemoveDuplicatesOption] boolValue])
  {
    // FIXME: relies on CTFontDescriptors behaving properly in sets (-hash/-isEqual:)
    _descriptors = [[[NSSet setWithArray: descriptors] allObjects] retain];
  }
  else
  {
    _descriptors = [descriptors copy];
  }
  return self;
}

- (CTFontCollection*)collectionByAddingFontDescriptors: (NSArray*)descriptors
                                               options: (NSDictionary*)opts
{
  NSArray *newDescriptors = [_descriptors arrayByAddingObjectsFromArray: descriptors];
  CTFontCollection *collection = [[CTFontCollection alloc] initWithFontDescriptors: newDescriptors
                                                                           options: opts];
  return [collection autorelease];
}

- (NSArray*)fontDescriptors
{
  return _descriptors;
}

- (NSArray*)fontDescriptorsSortedWithCallback: (CTFontCollectionSortDescriptorsCallback)cb
                                         info: (void*)info
{
  return [_descriptors sortedArrayUsingFunction: (NSComparisonResult (*)(id, id, void*))cb 
                                        context: info];
}

@end


/* Functions */

CTFontCollectionRef CTFontCollectionCreateCopyWithFontDescriptors(
  CTFontCollectionRef base,
  CFArrayRef descriptors,
  CFDictionaryRef opts)
{
  return [[base collectionByAddingFontDescriptors: descriptors options: opts] retain];
}

CTFontCollectionRef CTFontCollectionCreateFromAvailableFonts(CFDictionaryRef opts)
{
  return [[CTFontCollection alloc] initWithAvailableFontsWithOptions: opts];
}

CFArrayRef CTFontCollectionCreateMatchingFontDescriptors(CTFontCollectionRef collection)
{
  return [[collection fontDescriptors] retain];
}

CFArrayRef CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(
  CTFontCollectionRef collection,
  CTFontCollectionSortDescriptorsCallback cb,
  void *info)
{
  return [[collection fontDescriptorsSortedWithCallback: cb info: info] retain];
}

CTFontCollectionRef CTFontCollectionCreateWithFontDescriptors(
  CFArrayRef descriptors,
  CFDictionaryRef opts)
{
 return [[CTFontCollection alloc] initWithFontDescriptors: descriptors options: opts];
}

CFTypeID CTFontCollectionGetTypeID()
{
  return (CFTypeID)[CTFontCollection class];
}
