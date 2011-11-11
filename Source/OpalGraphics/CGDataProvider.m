/** <title>CGDataProvider</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010
   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

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

#include "CoreGraphics/CGDataProvider.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
/**
 * CGDataProvider abstract base class
 */
@interface CGDataProvider : NSObject
{

}

/* Opal internal access - Sequential */

- (size_t) getBytes: (void *)buffer count: (size_t)count;
- (off_t) skipForward: (off_t)count;
- (void) rewind;

/* Opal internal access - Direct */

- (size_t) size;
- (const void *)bytePointer;
- (void)releaseBytePointer: (const void *)pointer;
- (size_t) getBytes: (void *)buffer atPosition: (off_t)position count: (size_t)count;

- (CFDataRef) copyData;

@end

@implementation CGDataProvider

- (size_t)getBytes: (void *)buffer count: (size_t)count
{
  [self doesNotRecognizeSelector: _cmd];
  return (size_t)0;
}
- (off_t)skipForward: (off_t)count
{
  [self doesNotRecognizeSelector: _cmd];
  return (off_t)0;
}
- (void)rewind
{
  [self doesNotRecognizeSelector: _cmd];
}
- (size_t)size
{
  [self doesNotRecognizeSelector: _cmd];
  return (size_t)0;
}
- (const void *)bytePointer
{
  [self doesNotRecognizeSelector: _cmd];
  return (const void *)NULL;
}
- (void)releaseBytePointer: (const void *)pointer
{
  [self doesNotRecognizeSelector: _cmd];
}
- (size_t) getBytes: (void *)buffer atPosition: (off_t)position count: (size_t)count
{
  [self doesNotRecognizeSelector: _cmd];
  return (size_t)0;
}

- (CFDataRef)copyData
{
  return [[NSData alloc] initWithBytes: [self bytePointer] length: [self size]];
}

@end


/**
 * CGDataProvider subclass for direct data providers
 */
@interface CGDataProviderDirect : CGDataProvider
{
@public
  size_t size;
  off_t pos;
  void *info;
  CGDataProviderGetBytePointerCallback getBytePointerCallback;
  CGDataProviderReleaseBytePointerCallback releaseBytePointerCallback;
  CGDataProviderGetBytesAtOffsetCallback getBytesAtOffsetCallback;
  CGDataProviderGetBytesAtPositionCallback getBytesAtPositionCallback;
  CGDataProviderReleaseInfoCallback releaseInfoCallback;
}

@end

@implementation CGDataProviderDirect

- (void) dealloc
{
  if (releaseInfoCallback)
  {
    releaseInfoCallback(info);
  }
  [super dealloc];
}
  
  
/* Opal internal access - Sequential */

- (size_t)getBytes: (void *)buffer count: (size_t)count
{
  size_t bytesToCopy = MIN(count, (size - pos));
  const void *bytePointer = [self bytePointer];
  memcpy(buffer, bytePointer + pos, bytesToCopy);
  [self releaseBytePointer: bytePointer];
  
  pos += bytesToCopy;
  
  return bytesToCopy;
}
- (off_t)skipForward: (off_t)count
{
  pos += count;
  return count;
}
- (void)rewind
{
  pos = 0;
}

/* Opal internal access - Direct */

- (size_t)size
{
  return size;
}
- (const void *)bytePointer
{
  if (getBytePointerCallback)
  {
    return getBytePointerCallback(info);
  }
  return NULL;
}
- (void)releaseBytePointer: (const void *)pointer
{
  if (releaseBytePointerCallback)
  {
    releaseBytePointerCallback(info, pointer);
  }
}
- (size_t) getBytes: (void *)buffer atPosition: (off_t)position count: (size_t)count
{
  if (getBytesAtOffsetCallback)
  {
    return getBytesAtOffsetCallback(info, buffer, position, count);
  }
  else if (getBytesAtPositionCallback)
  {
    return getBytesAtPositionCallback(info, buffer, (int)position, count);
  }
  return 0;
}

@end

/**
 * CGDataProvider subclass for sequential data providers
 */
@interface CGDataProviderSequential : CGDataProvider
{
@public
  void *info;
  NSData *directBuffer;
  CGDataProviderGetBytesCallback getBytesCallback;
  CGDataProviderSkipBytesCallback skipBytesCallback;
  CGDataProviderSkipForwardCallback skipForwardCallback;
  CGDataProviderRewindCallback rewindCallback;
  CGDataProviderReleaseInfoCallback releaseInfoCallback;
}

- (NSData *)directBuffer;

@end

@implementation CGDataProviderSequential

- (void) dealloc
{
  if (releaseInfoCallback)
  {
    releaseInfoCallback(info);
  }
  [directBuffer release];
  [super dealloc];
}

/* Opal internal access - Sequential */

- (size_t)getBytes: (void *)buffer count: (size_t)count
{
  if (getBytesCallback)
  {
    return getBytesCallback(info, buffer, count);
  }
  return 0;
}
- (off_t)skipForward: (off_t)count
{
  if (skipBytesCallback)
  {
    skipBytesCallback(info, count);
    return count;
  }
  else if (skipForwardCallback)
  {
    return skipForwardCallback(info, count);
  }
  return 0;
}
- (void)rewind
{
  if (rewindCallback)
  {
    rewindCallback(info);
  }
}

/* Opal internal access - Direct */

- (NSData *)directBuffer
{
  if (NULL == directBuffer)
  {
    NSMutableData *buf = [[NSMutableData alloc] initWithLength: 65536];
    [self rewind];
    size_t got;
    off_t total = 0;
    while ((got = [self getBytes: ([buf mutableBytes] + total) count: 65536]) > 0)
    {
      total += got;
      [buf setLength: total + 65536];
    }
    [buf setLength: total];
    
    directBuffer = buf;
  } 
  return directBuffer;
}
- (size_t)size
{
  return [[self directBuffer] length];
}
- (const void *)bytePointer
{
  return [[self directBuffer] bytes];
}
- (void)releaseBytePointer: (const void *)pointer
{
  ;
}
- (size_t) getBytes: (void *)buffer atPosition: (off_t)position count: (size_t)count
{
  size_t bytesToCopy = MIN(count, ([[self directBuffer] length] - position));
  [[self directBuffer] getBytes:buffer range: NSMakeRange(position, bytesToCopy)];
  return bytesToCopy;
}

@end





/* Opal internal access - Sequential */

size_t OPDataProviderGetBytes(CGDataProviderRef dp, void *buffer, size_t count)
{
  return [dp getBytes: buffer count: count];
}

off_t OPDataProviderSkipForward(CGDataProviderRef dp, off_t count)
{
  return [dp skipForward: count];
}

void OPDataProviderRewind(CGDataProviderRef dp)
{
  [dp rewind];
}


/* Opal internal access - Direct */

size_t OPDataProviderGetSize(CGDataProviderRef dp)
{
  return [dp size];
}

const void *OPDataProviderGetBytePointer(CGDataProviderRef dp)
{
  return [dp bytePointer];
}

void OPDataProviderReleaseBytePointer(CGDataProviderRef dp, const void *pointer)
{
  [dp releaseBytePointer: pointer];
}

size_t OPDataProviderGetBytesAtPositionCallback(
  CGDataProviderRef dp, 
  void *buffer,
  off_t position,
  size_t count)
{
  return [dp getBytes: buffer atPosition: position count: count];
}




/* Callbacks for ready-made CGDataProviders */

/* Data callbacks */

typedef struct DataInfo {
  size_t size;
  const void *data;
  CGDataProviderReleaseDataCallback releaseData;
} DataInfo;

static const void *opal_DataGetBytePointer(void *info)
{
  return ((DataInfo*)info)->data;
}

static void opal_DataReleaseBytePointer(void *info, const void *pointer)
{
  ;
}  

static size_t opal_DataGetBytesAtPosition(
  void *info,
  void *buffer,
  off_t position,
  size_t count)
{
  size_t bytesToCopy = MIN(count, (((DataInfo*)info)->size - position));
  memcpy(buffer, ((DataInfo*)info)->data + position, bytesToCopy);
  return bytesToCopy;
}

static void opal_DataReleaseInfo(void *info)
{
  free((DataInfo*)info);
}

static const CGDataProviderDirectCallbacks opal_DataCallbacks = {
   0,
   opal_DataGetBytePointer,
   opal_DataReleaseBytePointer,
   opal_DataGetBytesAtPosition,
   opal_DataReleaseInfo
};

/* CFData callbacks */

static const void *opal_CFDataGetBytePointer(void *info)
{
  return [(NSData*)info bytes];
}

static void opal_CFDataReleaseBytePointer(void *info, const void *pointer)
{
  ;
}  

static size_t opal_CFDataGetBytesAtPosition(
  void *info,
  void *buffer,
  off_t position,
  size_t count)
{
  size_t bytesToCopy = MIN(count, ([(NSData*)info length] - position));
  [(NSData*)info getBytes:buffer range: NSMakeRange(position, bytesToCopy)];
  return bytesToCopy;
}

static void opal_CFDataReleaseInfo(void *info)
{
  [(NSData*)info release];
}

static const CGDataProviderDirectCallbacks opal_CFDataCallbacks = {
   0,
   opal_CFDataGetBytePointer,
   opal_CFDataReleaseBytePointer,
   opal_CFDataGetBytesAtPosition,
   opal_CFDataReleaseInfo
};

/* File callbacks */

static size_t opal_fileGetBytes(void *info, void *buffer, size_t count)
{
  return fread(buffer, 1, count, (FILE*)info);
}

static off_t opal_fileSkipForward(void *info, off_t count)
{
  fseek((FILE*)info, count, SEEK_CUR);
  return count;
}  

static void opal_fileRewind(void *info)
{
  rewind((FILE*)info);
}

static void opal_fileReleaseInfo(void *info)
{
  fclose((FILE*)info);
}

static const CGDataProviderSequentialCallbacks opal_fileCallbacks = {
   0,
   opal_fileGetBytes,
   opal_fileSkipForward,
   opal_fileRewind,
   opal_fileReleaseInfo
};







/* Functions */

CFDataRef CGDataProviderCopyData(CGDataProviderRef provider)
{
  return [(CGDataProvider*)provider copyData];  
}

CGDataProviderRef CGDataProviderCreateDirect(
  void *info,
  off_t size,
  const CGDataProviderDirectCallbacks *callbacks) 
{
  CGDataProviderDirect *provider = [[CGDataProviderDirect alloc] init];
  provider->info = info;
  provider->size = size;
  provider->getBytePointerCallback = callbacks->getBytePointer;
  provider->releaseBytePointerCallback = callbacks->releaseBytePointer;
  provider->getBytesAtPositionCallback = callbacks->getBytesAtPosition;
  provider->releaseInfoCallback = callbacks->releaseInfo;
    
  return provider;
}

/**
 * Deprecated
 */
CGDataProviderRef CGDataProviderCreateDirectAccess(
  void *info,
  size_t size,
  const CGDataProviderDirectAccessCallbacks *callbacks)
{
  CGDataProviderDirect *provider = [[CGDataProviderDirect alloc] init];
  provider->info = info;
  provider->size = size;
  provider->getBytePointerCallback = callbacks->getBytePointer;
  provider->releaseBytePointerCallback = callbacks->releaseBytePointer;
  provider->getBytesAtOffsetCallback = callbacks->getBytes;
  provider->releaseInfoCallback = callbacks->releaseProvider;
    
  return provider;
}

CGDataProviderRef CGDataProviderCreateSequential(
  void *info,
  const CGDataProviderSequentialCallbacks *callbacks)
{
  CGDataProviderSequential *provider = [[CGDataProviderSequential alloc] init];
  provider->info = info;
  provider->getBytesCallback = callbacks->getBytes;
  provider->skipForwardCallback = callbacks->skipForward;
  provider->rewindCallback = callbacks->rewind;
  provider->releaseInfoCallback = callbacks->releaseInfo;
    
  return provider;
}


/**
 * Deprecated
 */
CGDataProviderRef CGDataProviderCreate(
  void *info,
  const CGDataProviderCallbacks *callbacks)
{
  CGDataProviderSequential *provider = [[CGDataProviderSequential alloc] init];
  provider->info = info;
  provider->getBytesCallback = callbacks->getBytes;
  provider->skipBytesCallback = callbacks->skipBytes;
  provider->rewindCallback = callbacks->rewind;
  provider->releaseInfoCallback = callbacks->releaseProvider;
    
  return provider;
}

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  void (*releaseData)(void *info, const void *data, size_t size))
{
  DataInfo *i = malloc(sizeof(DataInfo));
  i->size = size;
  i->data = data;
  i->releaseData = releaseData;
  
  return CGDataProviderCreateDirect(i, size, &opal_DataCallbacks);
}

CGDataProviderRef CGDataProviderCreateWithCFData(CFDataRef data)
{
  return CGDataProviderCreateDirect([(NSData*)data retain], [(NSData*)data length], &opal_CFDataCallbacks);
}

CGDataProviderRef CGDataProviderCreateWithURL(CFURLRef url)
{
  return CGDataProviderCreateWithFilename([[(NSURL*)url path] UTF8String]);
}

CGDataProviderRef CGDataProviderCreateWithFilename(const char *filename)
{
  FILE *info = fopen(filename, "rb");
  if (NULL == info)
  {
    return nil;
  }
  return CGDataProviderCreateSequential(info, &opal_fileCallbacks);
}

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider)
{
  return [provider retain];
}

void CGDataProviderRelease(CGDataProviderRef provider)
{
  [provider release];
}

CFTypeID CGDataProviderGetTypeID()
{
  return (CFTypeID)[CGDataProvider class];
}
