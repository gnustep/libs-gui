/* 
   NSBitmapImageRep.m

   Bitmap image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@colorado.edu>
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
   
   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdlib.h>
#include <math.h>
#include <Foundation/NSException.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/nsimage-tiff.h>

/* Maximum number of planes */
#define MAX_PLANES 5

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NXBitmapImageRepBackend
- (BOOL) draw;
@end

@implementation NSBitmapImageRep 

/* Given a TIFF image (from the libtiff library), load the image information
   into our data structure.  Reads the specified image. */
- _initFromImage: (TIFF *)image number: (int)imageNumber
{
  NSString* space;
  NSTiffInfo* info;

  info = NSTiffGetInfo(imageNumber, image);
  if (!info) 
    {
      [NSException raise:NSTIFFException format: @"Read invalid TIFF info"];
    }

  /* 8-bit RGB will be converted to 24-bit by the tiff routines, so account
     for this. */
  space = nil;
#ifdef HAVE_LIBTIFF
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
#endif

  [self initWithBitmapDataPlanes: NULL
		pixelsWide: info->width
		pixelsHigh: info->height
		bitsPerSample: info->bitsPerSample
		samplesPerPixel: info->samplesPerPixel
		hasAlpha: (info->samplesPerPixel > 3)
		isPlanar: (info->planarConfig == PLANARCONFIG_SEPARATE)
		colorSpaceName: space
		bytesPerRow: 0
		bitsPerPixel: 0];
  compression = info->compression;

  if (NSTiffRead(imageNumber, image, NULL, [self bitmapData]))
    {
      [NSException raise:NSTIFFException format: @"Read invalid TIFF image"];
    }

  return self;
}

+ (id) imageRepWithData: (NSData *)tiffData
{
  NSArray* array;

  array = [self imageRepsWithData: tiffData];
  if ([array count])
    return [array objectAtIndex: 0];
  return nil;
}

+ (NSArray *) imageRepsWithData: (NSData *)tiffData
{
  int images;
  TIFF*       image;
  NSTiffInfo* info;
  NSMutableArray* array;

  image = NSTiffOpenData((char *)[tiffData bytes], [tiffData length], 
			 "r", NULL);
  if (!image)
    {
      [NSException raise:NSTIFFException format: @"Read invalid TIFF data"];
    }

  array = [NSMutableArray arrayWithCapacity:1];
  images = 0;
  while ((info = NSTiffGetInfo(images, image))) 
    {
      NSBitmapImageRep* imageRep;

      OBJC_FREE(info);
      imageRep = [[[[self class] alloc]
		   _initFromImage: image number: images] autorelease];
      [array addObject: imageRep];
      images++;
    }
  NSTiffClose(image);

  return array;
}

/* Loads only the default (first) image from the TIFF image contained in
   data. */
- (id) initWithData: (NSData *)tiffData
{
  TIFF 	*image;

  image = NSTiffOpenData((char *)[tiffData bytes], [tiffData length], 
			 "r", NULL);
  if (!image)
    {
      [NSException raise:NSTIFFException format: @"Read invalid TIFF data"];
    }

  [self _initFromImage:image number: -1];
  NSTiffClose(image);
  return self;
}

- (id) initWithFocusedViewRect: (NSRect)rect
{
  return [self notImplemented: _cmd];
}

/* This is the designated initializer */
/* Note: It's unclear whether or not we own the data that is passed
   to us here. Since the data is not of type "const", one could assume
   that we do own it and that it should not be copied. I'm also assuming
   we own the data that "planes" points to.  This is all a very hazardous
   assumption. It's also harder to deal with. */
- (id) initWithBitmapDataPlanes: (unsigned char **)planes
		pixelsWide: (int)width
		pixelsHigh: (int)height
		bitsPerSample: (int)bps
		samplesPerPixel: (int)spp
		hasAlpha: (BOOL)alpha
		isPlanar: (BOOL)config
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
  isPlanar   = isPlanar;
  colorSpace = [colorSpaceName retain];
  if (!pixelBits)
    pixelBits = bps * ((isPlanar) ? 1 : spp);
  bitsPerPixel            = pixelBits;
  if (!rowBytes) 
    rowBytes = ceil((float)width * bitsPerPixel / 8);
  bytesPerRow            = rowBytes;

  if (planes) 
    {
      freePlanes = YES;
      imagePlanes = planes;
    }
  return self;
}

- (void) dealloc
{
  if (imagePlanes && freePlanes)
    {
      int i;
      for (i = 0; i < MAX_PLANES; i++)
	if (imagePlanes[i])
	  OBJC_FREE(imagePlanes[i]);
    }
  OBJC_FREE(imagePlanes);
  [imageData release];
  [super dealloc];
}

+ (BOOL) canInitWithData: (NSData *)data
{
  TIFF *image = NULL;
  image = NSTiffOpenData((char *)[data bytes], [data length], "r", NULL);
  NSTiffClose(image);

  return (image) ? YES : NO;
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  [self notImplemented: _cmd];
  return NO;
}

+ (NSArray *) imageFileTypes
{
  return [self imageUnfilteredFileTypes];
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

// Getting Information about the Image 
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
  return isPlanar;
}

- (int) numberOfPlanes
{
  return (isPlanar) ? numColors : 1;
}

- (int) bytesPerPlane
{
  return bytesPerRow*_pixelsHigh;
}

- (int) bytesPerRow
{
  return bytesPerRow;
}

// Getting Image Data 
- (unsigned char *) bitmapData
{
  unsigned char *planes[MAX_PLANES];
  [self getBitmapDataPlanes: planes];
  return (unsigned char *)[imageData mutableBytes];
  //  return planes[0];
}

- (void) getBitmapDataPlanes: (unsigned char **)data
{
  int i;

  if (!imagePlanes)
    {
      long length;
      unsigned char* bits;
      
      length = numColors * bytesPerRow * _pixelsHigh * sizeof(unsigned char);
      imageData = [NSMutableData dataWithCapacity: length];
      OBJC_MALLOC(imagePlanes, unsigned char*, MAX_PLANES);
      bits = [imageData mutableBytes];
      if (isPlanar) 
	{
	  for (i=1; i < numColors; i++) 
	    imagePlanes[i] = bits + i*bytesPerRow * _pixelsHigh;
	  for (i= numColors; i < MAX_PLANES; i++) 
	    imagePlanes[i] = NULL;
	}
      else
	{
	  imagePlanes[1] = bits;
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
  [self bitmapData];
  return NO;
}

// Producing a TIFF Representation of the Image 
+ (NSData *) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
{
  [self notImplemented: _cmd];
  return nil;
}

+ (NSData *) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
		usingCompression: (NSTIFFCompression)compressionType
		factor: (float)factor
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSData *) TIFFRepresentation
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSData *) TIFFRepresentationUsingCompression: (NSTIFFCompression)compressionType
		factor: (float)factor
{
  [self notImplemented: _cmd];
  return nil;
}


// Setting and Checking Compression Types 
+ (void) getTIFFCompressionTypes: (const NSTIFFCompression **)list
		count: (int *)numTypes
{
  [self notImplemented: _cmd];
}

+ (NSString *) localizedNameForTIFFCompressionType: (NSTIFFCompression)compression
{
  [self notImplemented: _cmd];
  return nil;
}

- (BOOL) canBeCompressedUsing: (NSTIFFCompression)compression
{
  [self notImplemented: _cmd];
  return NO;
}

- (void) getCompression: (NSTIFFCompression *)compression
		factor: (float *)factor
{
  [self notImplemented: _cmd];
}

- (void) setCompression: (NSTIFFCompression)compression
		factor: (float)factor
{
  [self notImplemented: _cmd];
}


// NSCoding protocol
- (void) encodeWithCoder: aCoder
{
  [self notImplemented: _cmd];
}

- initWithCoder: aDecoder
{
  [self notImplemented: _cmd];
  return nil;
}

@end
