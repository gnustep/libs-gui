/* 
   NSBitmapImageRep.m

   Bitmap image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <gnustep/gui/config.h>
#include <stdlib.h>
#include <math.h>
#include <tiff.h>

#include <Foundation/NSException.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/AppKitExceptions.h>

#include <gnustep/gui/config.h>
#include <gnustep/gui/nsimage-tiff.h>

/* Maximum number of planes */
#define MAX_PLANES 5

/* Backend methods (optional) */
@interface NSBitmapImageRep (Backend)
+ (NSArray *) _wrasterFileTypes;
- _initFromWrasterFile: (NSString *)filename number: (int)imageNumber;
@end

@implementation NSBitmapImageRep 

/* Given a TIFF image (from the libtiff library), load the image information
   into our data structure.  Reads the specified image. */
- _initFromTIFFImage: (TIFF *)image number: (int)imageNumber
{
  NSString* space;
  NSTiffInfo* info;

  /* Seek to the correct image and get the dictionary information */
  info = NSTiffGetInfo(imageNumber, image);
  if (!info) 
    {
      RELEASE(self);
      NSLog(@"Tiff read invalid TIFF info in directory %d", imageNumber);
      return nil;
    }

  /* 8-bit RGB will be converted to 24-bit by the tiff routines, so account
     for this. */
  space = nil;
  switch(info->photoInterp) 
    {
    case PHOTOMETRIC_MINISBLACK: space = NSDeviceWhiteColorSpace; break;
    case PHOTOMETRIC_MINISWHITE: space = NSDeviceBlackColorSpace; break;
    case PHOTOMETRIC_RGB: space = NSDeviceRGBColorSpace; break;
    case PHOTOMETRIC_PALETTE: 
      space = NSDeviceRGBColorSpace; 
      info->samplesPerPixel = 3;
      break;
    default:
      break;
    }

  [self initWithBitmapDataPlanes: NULL
		pixelsWide: info->width
		pixelsHigh: info->height
		bitsPerSample: info->bitsPerSample
		samplesPerPixel: info->samplesPerPixel
		hasAlpha: (info->extraSamples > 0)
		isPlanar: (info->planarConfig == PLANARCONFIG_SEPARATE)
		colorSpaceName: space
		bytesPerRow: 0
		bitsPerPixel: 0];
  compression = info->compression;
  comp_factor = 255 * (1 - ((float)info->quality)/100.0);

  if (NSTiffRead(image, info, [self bitmapData]))
    {
      RELEASE(self);
      NSLog(@"Tiff read invalid TIFF image data in directory %d", imageNumber);
      return nil;
    }

  return self;
}

- _initFromWrasterFile: (NSString *)filename number: (int)imageNumber
{
  return nil;
}

+ (id) imageRepWithData: (NSData *)tiffData
{
  NSArray* array;

  array = [self imageRepsWithData: tiffData];
  if ([array count])
    return [array objectAtIndex: 0];
  return nil;
}

+ (NSArray*) imageRepsWithData: (NSData *)tiffData
{
  int		 i, images;
  TIFF		 *image;
  NSMutableArray *array;

  image = NSTiffOpenDataRead((char *)[tiffData bytes], [tiffData length]);
  if (image == NULL)
    {
      NSLog(@"Tiff unable to open/parse TIFF data");
      return nil;
    }

  images = NSTiffGetImageCount(image);
  NSDebugLLog(@"NSImage", @"Image contains %d directories", images);
  array = [NSMutableArray arrayWithCapacity: images];
  for (i = 0; i < images; i++)
    {
      NSBitmapImageRep* imageRep;
      imageRep = [[[self class] alloc] _initFromTIFFImage: image number: i];
      if (imageRep)
	[array addObject: AUTORELEASE(imageRep)];
    }
  NSTiffClose(image);

  return array;
}

/* A special method used mostly when we have the wraster library in the
   backend, which can read several more image formats */
+ (NSArray*) imageRepsWithFile: (NSString *)filename
{
  NSString *ext;
  int	   images;
  NSMutableArray *array;
  NSBitmapImageRep* imageRep;

  /* Don't use this for TIFF images, use the regular ...Data methods */
  ext = [filename pathExtension];
  if (!ext)
    {
      NSLog(@"Extension missing from filename - '%@'", filename);
      return nil;
    }
  if ([[self imageUnfilteredFileTypes] indexOfObject: ext] != NSNotFound)
    {
      NSData* data = [NSData dataWithContentsOfFile: filename];
      return [self imageRepsWithData: data];
    }

  array = [NSMutableArray arrayWithCapacity: 2];
  images = 0;
  do
    {
      imageRep = [[[self class] alloc] _initFromWrasterFile: filename 
				                     number: images];
      if (imageRep)
	[array addObject: AUTORELEASE(imageRep)];
      images++;
    }
  while (imageRep);

  return array;
}

/* Loads only the default (first) image from the TIFF image contained in
   data. */
- (id) initWithData: (NSData *)tiffData
{
  TIFF 	*image;

  image = NSTiffOpenDataRead((char *)[tiffData bytes], [tiffData length]);
  if (image == 0)
    {
      RELEASE(self);
      NSLog(@"Tiff read invalid TIFF info from data");
      return nil;
    }

  [self _initFromTIFFImage:image number: -1];
  NSTiffClose(image);
  return self;
}

- (id) initWithFocusedViewRect: (NSRect)rect
{
  return [self notImplemented: _cmd];
}

/* This is the designated initializer */
/* Note: If data is actaully passed to us in planes, we DO NOT own this
   data and we DO NOT copy it. Just assume that it will always be available.
*/
- (id) initWithBitmapDataPlanes: (unsigned char **)planes
		pixelsWide: (int)width
		pixelsHigh: (int)height
		bitsPerSample: (int)bps
		samplesPerPixel: (int)spp
		hasAlpha: (BOOL)alpha
		isPlanar: (BOOL)isPlanar
		colorSpaceName: (NSString *)colorSpaceName
		bytesPerRow: (int)rowBytes
		bitsPerPixel: (int)pixelBits;
{
  if (!bps || !spp || !width || !height) 
    {
      [NSException raise: NSInvalidArgumentException
        format: @"Required arguments not specified creating NSBitmapImageRep"];
    }

  _pixelsWide = width;
  _pixelsHigh = height;
  size.width  = width;
  size.height = height;
  bitsPerSample = bps;
  numColors     = spp;
  hasAlpha   = alpha;  
  _isPlanar   = isPlanar;
  _colorSpace = RETAIN(colorSpaceName);
  if (!pixelBits)
    pixelBits = bps * ((_isPlanar) ? 1 : spp);
  bitsPerPixel            = pixelBits;
  if (!rowBytes) 
    rowBytes = ceil((float)width * bitsPerPixel / 8);
  bytesPerRow            = rowBytes;

  if (planes) 
    {
      int i;
      OBJC_MALLOC(imagePlanes, unsigned char*, MAX_PLANES);
      for (i = 0; i < MAX_PLANES; i++)
 	imagePlanes[i] = NULL;
      for (i = 0; i < ((_isPlanar) ? numColors : 1); i++)
 	imagePlanes[i] = planes[i];
    }
  if (alpha)
    {
      unsigned char	*bData = (unsigned char*)[self bitmapData];
      BOOL		allOpaque = YES;
      unsigned		offset = numColors - 1;
      unsigned		limit = size.height * size.width;
      unsigned		i;

      for (i = 0; i < limit; i++)
	{
	  unsigned	a;

	  bData += offset;
	  a = *bData++;
	  if (a != 255)
	    {
	      allOpaque = NO;
	      break;
	    }
	}
      [self setOpaque: allOpaque];
    }
  else
    {
      [self setOpaque: YES];
    }
  return self;
}

- (void) dealloc
{
  OBJC_FREE(imagePlanes);
  RELEASE(imageData);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  NSBitmapImageRep	*copy;

  copy = (NSBitmapImageRep*)[super copyWithZone: zone];

  copy->bytesPerRow = bytesPerRow;
  copy->numColors = numColors;
  copy->bitsPerPixel = bitsPerPixel;
  copy->compression = compression;
  copy->comp_factor = comp_factor;
  copy->_isPlanar = _isPlanar;
  copy->imagePlanes = 0;
  copy->imageData = [imageData copy];

  return copy;
}

+ (BOOL) canInitWithData: (NSData *)data
{
  TIFF	*image = NULL;
  image = NSTiffOpenDataRead((char *)[data bytes], [data length]);
  NSTiffClose(image);

  return (image) ? YES : NO;
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  return [[pasteboard types] containsObject: NSTIFFPboardType]; 
}

+ (NSArray *) _wrasterFileTypes
{
  return nil;
}

+ (NSArray *) imageFileTypes
{
  NSArray *wtypes = [self _wrasterFileTypes];
  if (wtypes)
    {
      wtypes = AUTORELEASE([wtypes mutableCopy]);
      [(NSMutableArray *)wtypes addObjectsFromArray: 
			   [self imageUnfilteredFileTypes]];
    }
  else
    wtypes = [self imageUnfilteredFileTypes];
  return wtypes;
}

+ (NSArray *) imagePasteboardTypes
{
  return [self imageUnfilteredPasteboardTypes];
}

+ (NSArray *) imageUnfilteredFileTypes
{
  return [NSArray arrayWithObjects: @"tiff", @"tif", nil];
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  return [NSArray arrayWithObjects: NSTIFFPboardType, nil];
}

//
// Getting Information about the Image 
//
- (int) bitsPerPixel
{
  return bitsPerPixel;
}

- (int) samplesPerPixel
{
  return numColors;
}

- (BOOL) isPlanar
{
  return _isPlanar;
}

- (int) numberOfPlanes
{
  return (_isPlanar) ? numColors : 1;
}

- (int) bytesPerPlane
{
  return bytesPerRow*_pixelsHigh;
}

- (int) bytesPerRow
{
  return bytesPerRow;
}

//
// Getting Image Data 
//
- (unsigned char *) bitmapData
{
  unsigned char *planes[MAX_PLANES];
  [self getBitmapDataPlanes: planes];
  return planes[0];
}

- (void) getBitmapDataPlanes: (unsigned char **)data
{
  int i;

  if (!imagePlanes || !imagePlanes[0])
    {
      long length;
      unsigned char* bits;
      
      length = (long)numColors * bytesPerRow * _pixelsHigh 
 	* sizeof(unsigned char);
      imageData = RETAIN([NSMutableData dataWithLength: length]);
      if (!imagePlanes)
 	OBJC_MALLOC(imagePlanes, unsigned char*, MAX_PLANES);
      bits = [imageData mutableBytes];
      imagePlanes[0] = bits;
      if (_isPlanar) 
	{
	  for (i=1; i < numColors; i++) 
	    imagePlanes[i] = bits + i*bytesPerRow * _pixelsHigh;
	  for (i= numColors; i < MAX_PLANES; i++) 
	    imagePlanes[i] = NULL;
	}
      else
	{
	  for (i= 1; i < MAX_PLANES; i++) 
	    imagePlanes[i] = NULL;
	}
      
    }
  if (data)
    for (i=0; i < numColors; i++)
      data[i] = imagePlanes[i];
}

- (BOOL) draw
{
  NSRect irect = NSMakeRect(0, 0, size.width, size.height);
  NSDrawBitmap(irect,
	       _pixelsWide,
	       _pixelsHigh,
	       bitsPerSample,
	       numColors,
	       bitsPerPixel,
	       bytesPerRow,
	       _isPlanar,
	       hasAlpha,
	       _colorSpace,
	       imagePlanes);
  return YES;
}

//
// Producing a TIFF Representation of the Image 
//
+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
{
  [self notImplemented: _cmd];
  return nil;
}

+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
				usingCompression: (NSTIFFCompression)type
					  factor: (float)factor
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSData*) TIFFRepresentation
{
  NSTiffInfo	info;
  TIFF		*image;
  char		*bytes = 0;
  long		length = 0;

  info.imageNumber = 0;
  info.subfileType = 255;
  info.width = _pixelsWide;
  info.height = _pixelsHigh;
  info.bitsPerSample = bitsPerSample;
  info.samplesPerPixel = numColors;

  if (_isPlanar)
    info.planarConfig = PLANARCONFIG_SEPARATE;
  else
    info.planarConfig = PLANARCONFIG_CONTIG;

  if (_colorSpace == NSDeviceRGBColorSpace)
    info.photoInterp = PHOTOMETRIC_RGB;
  else if (_colorSpace == NSDeviceWhiteColorSpace)
    info.photoInterp = PHOTOMETRIC_MINISBLACK;
  else if (_colorSpace == NSDeviceBlackColorSpace)
    info.photoInterp = PHOTOMETRIC_MINISWHITE;
  else
    info.photoInterp = PHOTOMETRIC_RGB;

  info.compression = compression;
  info.quality = (1 - ((float)comp_factor)/255.0) * 100;
  info.numImages = 1;
  info.error = 0;

  image = NSTiffOpenDataWrite(&bytes, &length);
  if (image == 0)
    {
      [NSException raise: NSTIFFException format: @"Write TIFF open failed"];
    }
  if (NSTiffWrite(image, &info, [self bitmapData]) != 0)
    {
      [NSException raise: NSTIFFException format: @"Write TIFF data failed"];
    }
  NSTiffClose(image);
  return [NSData dataWithBytesNoCopy: bytes length: length];
}

- (NSData*) TIFFRepresentationUsingCompression: (NSTIFFCompression)type
					factor: (float)factor
{
  NSData		*data;
  NSTIFFCompression	oldType = compression;
  float			oldFact = comp_factor;

  [self setCompression: type factor: factor];
  data = [self TIFFRepresentation];
  [self setCompression: oldType factor: oldFact];
  return data;
}

//
// Setting and Checking Compression Types 
//
+ (void) getTIFFCompressionTypes: (const NSTIFFCompression **)list
			   count: (int *)numTypes
{
  static NSTIFFCompression	types[] = {
    NSTIFFCompressionNone,
    NSTIFFCompressionCCITTFAX3,
    NSTIFFCompressionCCITTFAX4,
    NSTIFFCompressionLZW,
    NSTIFFCompressionJPEG,
    NSTIFFCompressionPackBits
  };

  *list = types;
  *numTypes = sizeof(types)/sizeof(*types);
}

+ (NSString*) localizedNameForTIFFCompressionType: (NSTIFFCompression)type
{
  switch (type)
    {
      case NSTIFFCompressionNone: return @"NSTIFFCompressionNone";
      case NSTIFFCompressionCCITTFAX3: return @"NSTIFFCompressionCCITTFAX3";
      case NSTIFFCompressionCCITTFAX4: return @"NSTIFFCompressionCCITTFAX4";
      case NSTIFFCompressionLZW: return @"NSTIFFCompressionLZW";
      case NSTIFFCompressionJPEG: return @"NSTIFFCompressionJPEG";
      case NSTIFFCompressionNEXT: return @"NSTIFFCompressionNEXT";
      case NSTIFFCompressionPackBits: return @"NSTIFFCompressionPackBits";
      case NSTIFFCompressionOldJPEG: return @"NSTIFFCompressionOldJPEG";
      default: return nil;
    }
}

- (BOOL) canBeCompressedUsing: (NSTIFFCompression)type
{
  switch (type)
    {
      case NSTIFFCompressionCCITTFAX3:
      case NSTIFFCompressionCCITTFAX4:
	if (numColors == 1 && bitsPerSample == 1)
	  return YES;
	else
	  return NO;

      case NSTIFFCompressionNone:
      case NSTIFFCompressionLZW: 
      case NSTIFFCompressionJPEG:
      case NSTIFFCompressionPackBits:
	return YES;

      case NSTIFFCompressionNEXT:
      case NSTIFFCompressionOldJPEG:
      default:
	return NO;
    }
}

- (void) getCompression: (NSTIFFCompression*)type
		 factor: (float*)factor
{
  *type = compression;
  *factor = comp_factor;
}

- (void) setCompression: (NSTIFFCompression)type
		 factor: (float)factor
{
  compression = type;
  comp_factor = factor;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  NSData	*data = [self TIFFRepresentation];

  [super encodeWithCoder: aCoder];
  [data encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSData	*data;

  self = [super initWithCoder: aDecoder];
  data = [aDecoder decodeObject];
  return [self initWithData: data];
}

@end
