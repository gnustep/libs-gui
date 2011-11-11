/** <title>OPImageCodecTIFF</title>

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

#include <tiff.h>
#include <tiffio.h>

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#import "CGImageSource-private.h"
#import "CGImageDestination-private.h"
#import "CGDataProvider-private.h"
#import "CGDataConsumer-private.h"

extern void DumpPixel(const void *data, NSString *msg);

@interface OPTIFFHandle : NSObject
{
	NSData *data;
  off_t pos;
  BOOL mutable;
  CGDataConsumerRef consumer;
}
- (id)initWithDataProvider: (CGDataProviderRef)provider;
- (id)initWithDataConsumer: (CGDataConsumerRef)consumer;
- (size_t) read: (unsigned char *)buf count: (size_t)count;
- (size_t) write: (const unsigned char *)buf count: (size_t)count;
- (off_t) seek: (off_t)off mode: (int)model;
@end

@implementation OPTIFFHandle

- (id)initWithDataProvider: (CGDataProviderRef)provider
{
  self = [super init];
  data = CGDataProviderCopyData(provider);
  mutable = NO;
  return self;
}
- (id)initWithDataConsumer: (CGDataConsumerRef)dc
{
  self = [super init];
  data = [[NSMutableData alloc] initWithLength: 0];
  ASSIGN(consumer, dc);
  mutable = YES;
  return self;
}
- (void)dealloc
{
  // FIXME: this is ugly
  if (mutable)
  {
    OPDataConsumerPutBytes(consumer, [data bytes], [data length]);
  }
  [data release];
  [consumer release];
  [super dealloc];
}
- (size_t) read: (unsigned char *)buf count: (size_t)count
{
  [data getBytes: buf range: NSMakeRange(pos, count)];
  pos += count;
  return count;
}
- (size_t) write: (const unsigned char *)buf count: (size_t)count
{
  [(NSMutableData*)data replaceBytesInRange: NSMakeRange(pos, MAX(0, (off_t)[data length] - pos))
                                  withBytes: buf
                                     length: count];
  pos += count;
  return count;
}
- (off_t) seek: (off_t)off mode: (int)mode
{
  switch(mode) 
  {
    case SEEK_SET:
      pos = off;
      break;
    case SEEK_CUR:
      pos += off;
      break;
    case SEEK_END: 
      pos = ([data length] - 1) + off;
      break;
		default:
      break;
  }
  if (pos < 0)
  {
    pos = 0;
  }
  else if (pos > [data length] && !mutable)
  {
    pos = [data length];
  }
  return pos;
}
- (size_t)size
{
  return [data length];
}
- (void)map: (tdata_t*)bytes size: (toff_t*)size
{
  if (mutable)
  {
    *bytes = [(NSMutableData*)data mutableBytes];
  }
  else
  {
    *bytes = (tdata_t*)[data bytes];
  }
  *size = [data length];
}

static tsize_t OPTIFFReadProc(thandle_t handle, tdata_t buf, tsize_t count)
{
  return [(OPTIFFHandle*)handle read: buf count: count];
}
static tsize_t OPTIFFWriteProc(thandle_t handle, tdata_t buf, tsize_t count)
{
  return [(OPTIFFHandle*)handle write: buf count: count];
}
static toff_t OPTIFFSeekProc(thandle_t handle, toff_t offset, int mode)
{
  return [(OPTIFFHandle*)handle seek: offset mode: mode];
}
static int OPTIFFCloseProc(thandle_t handle)
{
  [(OPTIFFHandle*)handle release];
  return 0;
}
static toff_t OPTIFFSizeProc(thandle_t handle)
{
  return [(OPTIFFHandle*)handle size];
}
static int OPTIFFMapProc(thandle_t handle, tdata_t* data, toff_t* size)
{
  [(OPTIFFHandle*)handle map: (tdata_t*)data size: (toff_t*)size];
  return 1;
}
static void OPTIFFUnmapProc(thandle_t handle, tdata_t data, toff_t size)
{
}

@end





@interface CGImageSourceTIFF : CGImageSource
{
  TIFF *tiff;
}
@end

@implementation CGImageSourceTIFF

+ (void)load
{
  [CGImageSource registerSourceClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.tiff"];
}

- (id)initWithProvider: (CGDataProviderRef)provider;
{
  self = [super init];

  // Will be released by libtiff via OPTIFFCloseProc
  OPTIFFHandle *handle = [[OPTIFFHandle alloc] initWithDataProvider: provider];

  tiff = TIFFClientOpen("OPTIFFWithDataProvider", "r", handle, 
    OPTIFFReadProc, OPTIFFWriteProc, OPTIFFSeekProc,
    OPTIFFCloseProc, OPTIFFSizeProc, OPTIFFMapProc,
    OPTIFFUnmapProc);

  return self;
}

- (void)dealloc
{
  TIFFClose(tiff);
  [super dealloc];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts
{
  return [NSDictionary dictionary];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index
{
  return [NSDictionary dictionary];  
}

- (size_t)count
{
  size_t dirs = 0;
  if (1 == TIFFSetDirectory(tiff, 0))
  {
    do
    {
      dirs++;
    }
    while (1 == TIFFReadDirectory(tiff));
  }
  return dirs;
}

- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts
{
  CGImageRef img = NULL;

  TIFFSetDirectory(tiff, index);    
  
  uint32_t width;
  uint32_t height;
	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);

  NSMutableData *imgData = [[NSMutableData alloc] initWithLength: height * width * 4];
	
  if (1 == TIFFReadRGBAImageOriented(tiff, width, height, [imgData mutableBytes], 
           ORIENTATION_TOPLEFT, 0))
  { 
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(imgData);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    img = CGImageCreate(width, height, 8, 32, 4 * width, cs,
      kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, imgDataProvider,
      NULL, true, kCGRenderingIntentDefault);

		DumpPixel([imgData bytes], @"read from TIFF: (expecting R G B A)");

    CGColorSpaceRelease(cs);
    CGDataProviderRelease(imgDataProvider);
	}

  [imgData release];  

  return img;
}

- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts
{
  return nil;
}

- (CGImageSourceStatus)status
{
  return kCGImageStatusComplete;
}

- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  return kCGImageStatusComplete;
}

- (NSString*)type
{
  return @"public.tiff";
}

- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  ;
}

@end



@interface CGImageDestinationTIFF : CGImageDestination
{
  TIFF *tiff;
  CFDictionaryRef props;
  CGImageRef img;
}
@end

@implementation CGImageDestinationTIFF

+ (void)load
{
  [CGImageDestination registerDestinationClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.tiff"];
}
- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)opts
{
  self = [super init];
  
  if ([type isEqualToString: @"public.tiff"] || count != 1)
  {
    [self release];
    return nil;
  }
  
  // Will be released by libtiff via OPTIFFCloseProc
  OPTIFFHandle *handle = [[OPTIFFHandle alloc] initWithDataConsumer: consumer];

  tiff = TIFFClientOpen("OPTIFFWithDataConsumer", "w", handle, 
    OPTIFFReadProc, OPTIFFWriteProc, OPTIFFSeekProc,
    OPTIFFCloseProc, OPTIFFSizeProc, OPTIFFMapProc,
    OPTIFFUnmapProc);
  
  return self;
}

- (void)dealloc
{
  // FIXME: close in -finalize
  TIFFClose(tiff);
  [props release];
  CGImageRelease(img);
  [super dealloc];    
}

- (void) setProperties: (CFDictionaryRef)properties
{
  ASSIGN(props, properties);
}

- (void) addImage: (CGImageRef)image properties: (CFDictionaryRef)properties
{
  ASSIGN(img, image);
  ASSIGN(props, properties);
}

- (bool) finalize
{
  return false;
}

@end
