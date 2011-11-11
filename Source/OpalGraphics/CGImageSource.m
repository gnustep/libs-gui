/** <title>CGImageSource</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.
   Author: Eric Wasylishen <ewasylishen@gmail.com>
    
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include "CoreGraphics/CGImageSource.h"

#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

#include "CGImageSource-private.h"

/* Constants */

const CFStringRef kCGImageSourceTypeIdentifierHint = @"kCGImageSourceTypeIdentifierHint";
const CFStringRef kCGImageSourceShouldAllowFloat = @"kCGImageSourceShouldAllowFloat";
const CFStringRef kCGImageSourceShouldCache = @"kCGImageSourceShouldCache";
const CFStringRef kCGImageSourceCreateThumbnailFromImageIfAbsent = @"kCGImageSourceCreateThumbnailFromImageIfAbsent";
const CFStringRef kCGImageSourceCreateThumbnailFromImageAlways = @"kCGImageSourceCreateThumbnailFromImageAlways";
const CFStringRef kCGImageSourceThumbnailMaxPixelSize = @"kCGImageSourceThumbnailMaxPixelSize";
const CFStringRef kCGImageSourceCreateThumbnailWithTransform = @"kCGImageSourceCreateThumbnailWithTransform";


static NSMutableArray *sourceClasses = nil;

@implementation CGImageSource

+ (void) registerSourceClass: (Class)cls
{
  if (nil == sourceClasses)
  {
    sourceClasses = [[NSMutableArray alloc] init];
  }
  if ([cls isSubclassOfClass: [CGImageSource class]])
  {
    [sourceClasses addObject: cls];
  }
  else
  {
    [NSException raise: NSInvalidArgumentException format: @"+[CGImageSource registerSourceClass:] called with invalid class"];
  }  
}
+ (NSArray*) sourceClasses
{
  return sourceClasses;
}

+ (NSArray *)typeIdentifiers
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
+ (BOOL)canDecodeData: (CGDataProviderRef)provider
{
  [self doesNotRecognizeSelector: _cmd];
  return NO;
}
- (id)initWithProvider: (CGDataProviderRef)provider
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)options
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)options atIndex: (size_t)index
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (size_t)count
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)options
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)options
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (CGImageSourceStatus)status
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  [self doesNotRecognizeSelector: _cmd];
  return 0;
}
- (NSString*)type
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}
- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  [self doesNotRecognizeSelector: _cmd];
}

@end

/** 
 * Proxy class used to implement CGImageSourceCreateIncremental.
 * It simply waits for enough data from CGImageSourceUpdateData[Provider] calls
 * to create a real CGImageSource, then forwards messages to the real 
 * image source.
 */
@interface CGImageSourceIncremental : CGImageSource
{
  CGImageSource *real;
  CFDictionaryRef opts;
}

@end

@implementation CGImageSourceIncremental

- (id)initWithIncrementalOptions: (CFDictionaryRef)o
{
  self = [super init];
  opts = [o retain];
  return self;
}
- (void)dealloc
{
  [real release];
  [opts release];
  [super dealloc];
}
- (CGImageSource*)realSource
{
  return real;
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)options
{
  return [[self realSource] propertiesWithOptions: options];
}
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)options atIndex: (size_t)index
{
  return [[self realSource] propertiesWithOptions: options atIndex: index];
}
- (size_t)count
{
  return [[self realSource] count];
}
- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)options
{
  return [[self realSource] createImageAtIndex: index options: options];
}
- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)options
{
  return [[self realSource] createThumbnailAtIndex: index options: options];
}
- (CGImageSourceStatus)status
{
  if (![self realSource])
  {
     return kCGImageStatusReadingHeader; // FIXME ??
  }
  return [[self realSource] status];
}
- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  if (![self realSource])
  {
     return kCGImageStatusReadingHeader; // FIXME ??
  }
  return [[self realSource] statusAtIndex: index];
}
- (NSString*)type
{
  return [[self realSource] type];
}
- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  if (![self realSource])
  {
    // See if there is enough data to create a real image source
    real = CGImageSourceCreateWithDataProvider(provider, opts);
  }
  else
  {
    [[self realSource] updateDataProvider: provider finalUpdate: finalUpdate];
  }
}

@end


/* Functions */

/* Creating */

CGImageSourceRef CGImageSourceCreateIncremental(CFDictionaryRef options)
{
  return [[CGImageSourceIncremental alloc] initWithIncrementalOptions: options];
}

CGImageSourceRef CGImageSourceCreateWithData(
  CFDataRef data,
  CFDictionaryRef options)
{
  CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
  CGImageSourceRef source;
  source = CGImageSourceCreateWithDataProvider(provider, options);
  CGDataProviderRelease(provider);
  return source;
}

CGImageSourceRef CGImageSourceCreateWithDataProvider(
  CGDataProviderRef provider,
  CFDictionaryRef options)
{
  const NSUInteger cnt = [sourceClasses count];
  NSString *possibleType = [options valueForKey:
    kCGImageSourceTypeIdentifierHint];
    
  if (possibleType)
  {
    for (NSUInteger i=0; i<cnt; i++)
    {    
      Class cls = [sourceClasses objectAtIndex: i];
      if ([[cls typeIdentifiers] containsObject: possibleType])
      {
        CGImageSource *src = [[cls alloc] initWithProvider: provider];
        if (src)
        {
          return src;
        }
      }
    }
  }
  
  for (NSUInteger i=0; i<cnt; i++)
  {    
    Class cls = [sourceClasses objectAtIndex: i];
    
    CGImageSource *src = [[cls alloc] initWithProvider: provider];
    if (src)
    {
      return src;
    }
  }
  
  return nil;
}

CGImageSourceRef CGImageSourceCreateWithURL(
  CFURLRef url,
  CFDictionaryRef options)
{
  CGDataProviderRef provider = CGDataProviderCreateWithURL(url);
  CGImageSourceRef source;
  source = CGImageSourceCreateWithDataProvider(provider, options);
  CGDataProviderRelease(provider);
  return source;
}


/* Accessing Properties */

CFDictionaryRef CGImageSourceCopyProperties(
  CGImageSourceRef source,
  CFDictionaryRef options)
{
  return [source propertiesWithOptions: options];
}

CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef options)
{
  return [source propertiesWithOptions: options atIndex: index];
}

/* Getting Supported Image Types */

CFArrayRef CGImageSourceCopyTypeIdentifiers()
{
  NSMutableSet *set = [NSMutableSet set];
  NSArray *classes = [CGImageSource sourceClasses];
  NSUInteger cnt = [classes count];
  for (NSUInteger i=0; i<cnt; i++)
  {    
    [set addObjectsFromArray: [[classes objectAtIndex: i] typeIdentifiers]];
  }
  return [[set allObjects] retain];
}

/* Accessing Images */

size_t CGImageSourceGetCount(CGImageSourceRef source)
{
  return [source count];
}

CGImageRef CGImageSourceCreateImageAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef options)
{
  return [source createImageAtIndex: index options: options];
}

CGImageRef CGImageSourceCreateThumbnailAtIndex(
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef options)
{
  return [source createThumbnailAtIndex: index options: options];
}

CGImageSourceStatus CGImageSourceGetStatus(CGImageSourceRef source)
{
  return [source status];  
}

CGImageSourceStatus CGImageSourceGetStatusAtIndex(
  CGImageSourceRef source,
  size_t index)
{
  return [source statusAtIndex: index];
}

CFStringRef CGImageSourceGetType(CGImageSourceRef source)
{
  return [source type];
}

void CGImageSourceUpdateData(
  CGImageSourceRef source,
  CFDataRef data,
  bool finalUpdate)
{
  CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
  CGImageSourceUpdateDataProvider(source, provider, finalUpdate);
  CGDataProviderRelease(provider);
}

void CGImageSourceUpdateDataProvider(
  CGImageSourceRef source,
  CGDataProviderRef provider,
  bool finalUpdate)
{
  [source updateDataProvider: provider finalUpdate: finalUpdate];
}

CFTypeID CGImageSourceGetTypeID()
{
  return (CFTypeID)[CGImageSource class];
}
