/* Implementation of class NSDataAsset
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Fri Jan 17 10:25:34 EST 2020

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
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSJSONSerialization.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <AppKit/NSDataAsset.h>

@interface NSDataAsset (Private)
- (BOOL) _loadData;
@end

/* A best-effort type identifier from a file extension.  Only the common,
   standard uniform type identifiers are mapped; an unknown extension gives
   nil. */
static NSString *
typeIdentifierForExtension(NSString *ext)
{
  static NSDictionary *map = nil;

  if (ext == nil || [ext length] == 0)
    {
      return nil;
    }
  if (map == nil)
    {
      map = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"public.json", @"json",
        @"public.xml", @"xml",
        @"public.plain-text", @"txt",
        @"public.html", @"html",
        @"public.comma-separated-values-text", @"csv",
        @"com.apple.property-list", @"plist",
        @"public.png", @"png",
        @"public.jpeg", @"jpeg",
        @"public.jpeg", @"jpg",
        @"com.compuserve.gif", @"gif",
        @"com.adobe.pdf", @"pdf",
        @"public.data", @"data",
        nil];
    }
  return [map objectForKey: [ext lowercaseString]];
}

@implementation NSDataAsset

// Initializing the Data Asset
- (instancetype) initWithName: (NSDataAssetName)name
{
  return [self initWithName: name bundle: [NSBundle mainBundle]];
}

- (instancetype) initWithName: (NSDataAssetName)name bundle: (NSBundle *)bundle
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  if (name == nil)
    {
      DESTROY(self);
      return nil;
    }
  if (bundle == nil)
    {
      bundle = [NSBundle mainBundle];
    }

  ASSIGNCOPY(_name, name);
  ASSIGN(_bundle, bundle);
  _data = nil;
  _typeIdentifier = nil;

  if (![self _loadData])
    {
      DESTROY(self);
      return nil;
    }

  return self;
}

- (BOOL) _loadData
{
  NSString *datasetPath;
  NSString *resourcePath;

  // An Apple .dataset directory: read Contents.json for the data file.
  datasetPath = [_bundle pathForResource: _name ofType: @"dataset"];
  if (datasetPath != nil)
    {
      NSString *contentsPath;
      NSData *contentsData;
      id contents;

      contentsPath = [datasetPath
        stringByAppendingPathComponent: @"Contents.json"];
      contentsData = [NSData dataWithContentsOfFile: contentsPath];
      contents = (contentsData != nil)
        ? [NSJSONSerialization JSONObjectWithData: contentsData
                                          options: 0
                                            error: NULL]
        : nil;
      if ([contents isKindOfClass: [NSDictionary class]])
        {
          NSArray *entries = [(NSDictionary *)contents objectForKey: @"data"];

          if ([entries isKindOfClass: [NSArray class]])
            {
              NSEnumerator *en = [entries objectEnumerator];
              NSDictionary *entry;
              NSString *filename = nil;

              while ((entry = [en nextObject]) != nil)
                {
                  NSString *entryFile;

                  if (![entry isKindOfClass: [NSDictionary class]])
                    continue;
                  entryFile = [entry objectForKey: @"filename"];
                  if (entryFile == nil)
                    continue;
                  if (filename == nil)
                    filename = entryFile;
                  if ([[entry objectForKey: @"idiom"]
                        isEqualToString: @"universal"])
                    {
                      filename = entryFile;
                      break;
                    }
                }

              if (filename != nil)
                {
                  NSString *dataPath;
                  NSData *data;

                  dataPath = [datasetPath
                    stringByAppendingPathComponent: filename];
                  data = [NSData dataWithContentsOfFile: dataPath];
                  if (data != nil)
                    {
                      ASSIGN(_data, data);
                      ASSIGN(_typeIdentifier,
                        typeIdentifierForExtension([filename pathExtension]));
                      return YES;
                    }
                }
            }
        }
    }

  // A plain named resource in the bundle.
  resourcePath = [_bundle pathForResource: _name ofType: nil];
  if (resourcePath == nil)
    {
      NSArray *types = [NSArray arrayWithObjects:
        @"data", @"json", @"plist", @"xml", @"txt", nil];
      NSEnumerator *en = [types objectEnumerator];
      NSString *type;

      while ((type = [en nextObject]) != nil)
        {
          resourcePath = [_bundle pathForResource: _name ofType: type];
          if (resourcePath != nil)
            break;
        }
    }
  if (resourcePath != nil)
    {
      NSData *data = [NSData dataWithContentsOfFile: resourcePath];

      if (data != nil)
        {
          ASSIGN(_data, data);
          ASSIGN(_typeIdentifier,
            typeIdentifierForExtension([resourcePath pathExtension]));
          return YES;
        }
    }

  return NO;
}

- (void) dealloc
{
  RELEASE(_name);
  RELEASE(_bundle);
  RELEASE(_data);
  RELEASE(_typeIdentifier);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  NSDataAsset *copy = [[NSDataAsset allocWithZone: zone] initWithName: _name bundle: _bundle];
  ASSIGNCOPY(copy->_data, _data);
  ASSIGNCOPY(copy->_typeIdentifier, _typeIdentifier);
  return copy;
}

// Accessing data...
- (NSData *) data
{
  return _data;
}

// Getting data asset information
- (NSDataAssetName) name
{
  return _name;
}

- (NSString *) typeIdentifier
{
  return _typeIdentifier;
}
@end

