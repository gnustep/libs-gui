/** <title>CGImageDestination</title>

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
   
#include "CoreGraphics/CGImageDestination.h"

#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

#include "CGImageDestination-private.h"

/* Constants */

const CFStringRef kCGImageDestinationLossyCompressionQuality = @"kCGImageDestinationLossyCompressionQuality";
const CFStringRef kCGImageDestinationBackgroundColor = @"kCGImageDestinationBackgroundColor";


static NSMutableArray *destinationClasses = nil;

@implementation CGImageDestination

+ (void) registerDestinationClass: (Class)cls
{
  if (nil == destinationClasses)
  {
    destinationClasses = [[NSMutableArray alloc] init];
  }
  if ([cls isSubclassOfClass: [CGImageDestination class]])
  {
    [destinationClasses addObject: cls];
  }
  else
  {
    [NSException raise: NSInvalidArgumentException format: @"+[CGImageDestination registerDestinationClass:] called with invalid class"];
  }  
}
+ (NSArray*) destinationClasses
{
  return destinationClasses;
}
+ (Class) destinationClassForType: (NSString*)type
{
  NSUInteger cnt = [destinationClasses count];
  for (NSUInteger i=0; i<cnt; i++)
  {    
    Class cls = [destinationClasses objectAtIndex: i];
    if ([[cls typeIdentifiers] containsObject: type])
    {
      return cls;
    }
  }
  return Nil;
}

+ (NSArray *)typeIdentifiers
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}

- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)opts
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}

- (void) setProperties: (CFDictionaryRef)properties
{
  [self doesNotRecognizeSelector: _cmd];
}

- (void) addImage: (CGImageRef)img properties: (CFDictionaryRef)properties
{
  [self doesNotRecognizeSelector: _cmd];
}

- (void) addImageFromSource: (CGImageSourceRef)source
                      index: (size_t)index
                 properties: (CFDictionaryRef)properties
{
  [self doesNotRecognizeSelector: _cmd];
}

- (bool) finalize
{
  [self doesNotRecognizeSelector: _cmd];
  return false;
}

@end

/* Functions */

/* Creating */

CGImageDestinationRef CGImageDestinationCreateWithData(
  CFMutableDataRef data,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts)
{
  CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData(data);
  CGImageDestinationRef dest;
  dest = CGImageDestinationCreateWithDataConsumer(consumer, type, count, opts);
  CGDataConsumerRelease(consumer);
  return dest;
}

CGImageDestinationRef CGImageDestinationCreateWithDataConsumer(
  CGDataConsumerRef consumer,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts)
{  
  Class cls = [CGImageDestination destinationClassForType: type];
  return [[cls alloc] initWithDataConsumer: consumer type: type count: count options: opts];
}

CGImageDestinationRef CGImageDestinationCreateWithURL(
  CFURLRef url,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts)
{
  CGDataConsumerRef consumer = CGDataConsumerCreateWithURL(url);
  CGImageDestinationRef dest;
  dest = CGImageDestinationCreateWithDataConsumer(consumer, type, count, opts);
  CGDataConsumerRelease(consumer);
  return dest;
}

/* Getting Supported Image Types */

CFArrayRef CGImageDestinationCopyTypeIdentifiers()
{
  NSMutableSet *set = [NSMutableSet set];
  NSArray *classes = [CGImageDestination destinationClasses];
  NSUInteger cnt = [classes count];
  for (NSUInteger i=0; i<cnt; i++)
  {    
    [set addObjectsFromArray: [[classes objectAtIndex: i] typeIdentifiers]];
  }
  return [[set allObjects] retain];
}

/* Setting Properties */

void CGImageDestinationSetProperties(
  CGImageDestinationRef dest,
  CFDictionaryRef properties)
{
  [dest setProperties: properties];
}

/* Adding Images */

void CGImageDestinationAddImage(
  CGImageDestinationRef dest,
  CGImageRef image,
  CFDictionaryRef properties)
{
  [dest addImage: (CGImageRef)image properties: properties];
}

void CGImageDestinationAddImageFromSource(
  CGImageDestinationRef dest,
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef properties)
{
  // FIXME: We could support short-circuiting in some cases, but it's probably not worth the complexity
  CGImageDestinationAddImage(dest, CGImageSourceCreateImageAtIndex(source, index, nil), properties);
}

bool CGImageDestinationFinalize(CGImageDestinationRef dest)
{
  return [dest finalize];
}

CFTypeID CGImageDestinationGetTypeID()
{
  return (CFTypeID)[CGImageDestination class];
}
