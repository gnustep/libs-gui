/** <title>CGDataConsumer</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010

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

#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileHandle.h>
#include "CoreGraphics/CGDataConsumer.h"

@interface CGDataConsumer : NSObject
{
@public
  CGDataConsumerCallbacks cb;
  void *info;
}
@end

@implementation CGDataConsumer

- (id) initWithCallbacks: (CGDataConsumerCallbacks)callbacks info: (void*)i
{
  self = [super init];
  cb = callbacks;
  info = i;
  return self;
}

- (void) dealloc
{
  if (cb.releaseConsumer)
  {
    cb.releaseConsumer(info);
  }
  [super dealloc];    
}

@end

/* Opal-internal access */

size_t OPDataConsumerPutBytes(CGDataConsumerRef dc, const void *buffer, size_t count)
{
  if (NULL != dc)
  {
    return dc->cb.putBytes(
      dc->info, 
      buffer,
      count);
  }
  return 0;
}

/* URL consumer */

static size_t opal_URLConsumerPutBytes(
  void *info,
  const void *buffer,
  size_t count)
{
  NSData *data = [[NSData alloc] initWithBytesNoCopy: (void*)buffer
                                              length: count
                                        freeWhenDone: NO];
  // FIXME: catch exceptions?
  [(NSFileHandle*)info writeData: data];  
  
  [data release];
  return count; 
}

static void opal_URLConsumerReleaseInfo(void *info)
{
  [(NSFileHandle*)info release];
}


/* CFData consumer */

static size_t opal_CFDataConsumerPutBytes(
   void *info,
   const void *buffer,
   size_t count)
{
  [(NSMutableData*)info appendBytes: buffer length: count];
  return count;
}

static void opal_CFDataConsumerReleaseInfo(void *info)
{
  [(NSMutableData*)info release];
}


/* Functions */

CGDataConsumerRef CGDataConsumerCreate(
  void *info,
  const CGDataConsumerCallbacks *callbacks)
{
  return [[CGDataConsumer alloc] initWithCallbacks: *callbacks info: info];
}

CGDataConsumerRef CGDataConsumerCreateWithCFData(CFMutableDataRef data)
{
  CGDataConsumerCallbacks opal_CFDataConsumerCallbacks = {
    opal_CFDataConsumerPutBytes, opal_CFDataConsumerReleaseInfo 
  };
  return CGDataConsumerCreate([data retain], &opal_CFDataConsumerCallbacks);
}

CGDataConsumerRef CGDataConsumerCreateWithURL(CFURLRef url)
{
  CGDataConsumerCallbacks opal_URLConsumerCallbacks = {
    opal_URLConsumerPutBytes, opal_URLConsumerReleaseInfo 
  };
  NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath: [(NSURL*)url path]];
  return CGDataConsumerCreate([handle retain], &opal_URLConsumerCallbacks);
}

CFTypeID CGDataConsumerGetTypeID()
{
  return (CFTypeID)[CGDataConsumer class];
}

void CGDataConsumerRelease(CGDataConsumerRef consumer)
{
  [consumer release];
}

CGDataConsumerRef CGDataConsumerRetain(CGDataConsumerRef consumer)
{
  return [consumer retain];
}
