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
#include <Foundation/NSDebug.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSView.h>
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

// GNUstep extension
- _initFromTIFFImage: (TIFF *)image number: (int)imageNumber;
@end

@implementation NSBitmapImageRep 

+ (BOOL) canInitWithData: (NSData *)data
{
  TIFF	*image = NULL;
  image = NSTiffOpenDataRead ((char *)[data bytes], [data length]);

  if (image != NULL)
    {
      NSTiffClose (image);
      return YES;
    }
  else
    {
      return NO;
    }
}

+ (NSArray *) imageUnfilteredFileTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      NSArray *wtypes = [self _wrasterFileTypes];

      if (wtypes != nil)
        {
	  types = [wtypes mutableCopy];
	  [(NSMutableArray *)types addObject: @"tiff"];
	  [(NSMutableArray *)types addObject: @"tif"];
	}
      else
	{
	  types = [[NSArray alloc] initWithObjects: @"tiff", @"tif", nil];
	}
    }

  return types;
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      types = [[NSArray alloc] initWithObjects: NSTIFFPboardType, nil];
    }
  
  return types;
}

+ (id) imageRepWithData: (NSData *)tiffData
{
  NSArray* array;

  array = [self imageRepsWithData: tiffData];
  if ([array count])
    {
      return [array objectAtIndex: 0];
    }
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
      imageRep = [[self alloc] _initFromTIFFImage: image number: i];
      if (imageRep)
	{
	  [array addObject: AUTORELEASE(imageRep)];
	}
    }
  NSTiffClose(image);

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
  // TODO
  [self notImplemented: _cmd];

  RELEASE(self);
  return nil;
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
  _size.width  = width;
  _size.height = height;
  _bitsPerSample = bps;
  _numColors     = spp;
  _hasAlpha   = alpha;  
  _isPlanar   = isPlanar;
  _colorSpace = RETAIN(colorSpaceName);
  if (!pixelBits)
    pixelBits = bps * ((_isPlanar) ? 1 : spp);
  _bitsPerPixel            = pixelBits;
  if (!rowBytes) 
    rowBytes = ceil((float)width * _bitsPerPixel / 8);
  _bytesPerRow            = rowBytes;

  _imagePlanes = NSZoneMalloc([self zone], sizeof(unsigned char*) * MAX_PLANES);
  if (planes) 
    {
      int i;

      for (i = 0; i < MAX_PLANES; i++)
 	_imagePlanes[i] = NULL;
      for (i = 0; i < ((_isPlanar) ? _numColors : 1); i++)
 	_imagePlanes[i] = planes[i];
    }
  else
    {
      unsigned char* bits;
      long length;
      int i;

      // No image data was given, allocate it.
      length = (long)((_isPlanar) ? _numColors : 1) * _bytesPerRow * 
	  _pixelsHigh * sizeof(unsigned char);
      _imageData = [[NSMutableData alloc] initWithLength: length];
      bits = [_imageData mutableBytes];
      _imagePlanes[0] = bits;
      if (_isPlanar) 
	{
	  for (i=1; i < _numColors; i++) 
	    _imagePlanes[i] = bits + i*_bytesPerRow * _pixelsHigh;
	  for (i= _numColors; i < MAX_PLANES; i++) 
	    _imagePlanes[i] = NULL;
	}
      else
	{
	  for (i= 1; i < MAX_PLANES; i++) 
	    _imagePlanes[i] = NULL;
	}      
    }

  if (alpha)
    {
      unsigned char	*bData = (unsigned char*)[self bitmapData];
      BOOL		allOpaque = YES;
      unsigned		offset = _numColors - 1;
      unsigned		limit = _size.height * _size.width;
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

- (void)colorizeByMappingGray:(float)midPoint 
		      toColor:(NSColor *)midPointColor 
		 blackMapping:(NSColor *)shadowColor
		 whiteMapping:(NSColor *)lightColor
{
  // TODO
}

- (id)initWithBitmapHandle:(void *)bitmap
{
  // TODO Only needed on MS Windows
  RELEASE(self);
  return nil;
}

- (id)initWithIconHandle:(void *)icon
{
  // TODO Only needed on MS Windows
  RELEASE(self);
  return nil;
}

- (void) dealloc
{
  NSZoneFree([self zone],_imagePlanes);
  RELEASE(_imageData);
  [super dealloc];
}

//
// Getting Information about the Image 
//
- (int) bitsPerPixel
{
  return _bitsPerPixel;
}

- (int) samplesPerPixel
{
  return _numColors;
}

- (BOOL) isPlanar
{
  return _isPlanar;
}

- (int) numberOfPlanes
{
  return (_isPlanar) ? _numColors : 1;
}

- (int) bytesPerPlane
{
  return _bytesPerRow*_pixelsHigh;
}

- (int) bytesPerRow
{
  return _bytesPerRow;
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

  if (data)
    {
      for (i = 0; i < _numColors; i++)
	{
	  data[i] = _imagePlanes[i];
	}
    }
}

- (BOOL) draw
{
  NSRect irect = NSMakeRect(0, 0, _size.width, _size.height);

  NSDrawBitmap(irect,
	       _pixelsWide,
	       _pixelsHigh,
	       _bitsPerSample,
	       _numColors,
	       _bitsPerPixel,
	       _bytesPerRow,
	       _isPlanar,
	       _hasAlpha,
	       _colorSpace,
	       _imagePlanes);
  return YES;
}

//
// Producing a TIFF Representation of the Image 
//
+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
{
  //FIXME: This only outputs one of the ImageReps
  NSEnumerator *enumerator = [anArray objectEnumerator];
  NSImageRep *rep;

  while ((rep = [enumerator nextObject]) != nil)
    {
      if ([rep isKindOfClass: self])
        {
	  return [(NSBitmapImageRep*)rep TIFFRepresentation];
	}
    }

  return nil;
}

+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray *)anArray
				usingCompression: (NSTIFFCompression)type
					  factor: (float)factor
{
  //FIXME: This only outputs one of the ImageReps
  NSEnumerator *enumerator = [anArray objectEnumerator];
  NSImageRep *rep;

  while ((rep = [enumerator nextObject]) != nil)
    {
      if ([rep isKindOfClass: self])
        {
	  return [(NSBitmapImageRep*)rep TIFFRepresentationUsingCompression: type
		     factor: factor];
	}
    }

  return nil;
}

- (NSData*) TIFFRepresentation
{
  return [self TIFFRepresentationUsingCompression: _compression
	       factor: _comp_factor];
}

- (NSData*) TIFFRepresentationUsingCompression: (NSTIFFCompression)type
					factor: (float)factor
{
  NSTiffInfo	info;
  TIFF		*image;
  char		*bytes = 0;
  long		length = 0;

  info.imageNumber = 0;
  info.subfileType = 255;
  info.width = _pixelsWide;
  info.height = _pixelsHigh;
  info.bitsPerSample = _bitsPerSample;
  info.samplesPerPixel = _numColors;

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

  info.compression = type;
  info.quality = (1 - ((float)factor)/255.0) * 100;
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

+ (NSData *)representationOfImageRepsInArray:(NSArray *)imageReps 
				   usingType:(NSBitmapImageFileType)storageType
				  properties:(NSDictionary *)properties
{
  // TODO
  return nil;
}

- (NSData *)representationUsingType:(NSBitmapImageFileType)storageType 
			 properties:(NSDictionary *)properties
{
  // TODO
  return nil;
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
	if (_numColors == 1 && _bitsPerSample == 1)
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
  *type = _compression;
  *factor = _comp_factor;
}

- (void) setCompression: (NSTIFFCompression)type
		 factor: (float)factor
{
  _compression = type;
  _comp_factor = factor;
}

- (void)setProperty:(NSString *)property withValue:(id)value
{
  // TODO
}

- (id)valueForProperty:(NSString *)property
{
  // TODO
  return nil;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone
{
  NSBitmapImageRep	*copy;

  copy = (NSBitmapImageRep*)[super copyWithZone: zone];

  copy->_imageData = [_imageData copyWithZone: zone];
  copy->_imagePlanes = NSZoneMalloc(zone, sizeof(unsigned char*) * MAX_PLANES);
  if (_imageData == nil)
    {
      memcpy(copy->_imagePlanes, _imagePlanes, sizeof(unsigned char*) * MAX_PLANES);
    }
  else
    {
      unsigned char* bits;
      int i;

      bits = [copy->_imageData mutableBytes];
      copy->_imagePlanes[0] = bits;
      if (_isPlanar) 
	{
	  for (i=1; i < _numColors; i++) 
	    copy->_imagePlanes[i] = bits + i*_bytesPerRow * _pixelsHigh;
	  for (i= _numColors; i < MAX_PLANES; i++) 
	    copy->_imagePlanes[i] = NULL;
	}
      else
	{
	  for (i= 1; i < MAX_PLANES; i++) 
	    copy->_imagePlanes[i] = NULL;
	}
    }

  return copy;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  NSData	*data = [self TIFFRepresentation];

  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: data];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSData	*data;

  self = [super initWithCoder: aDecoder];
  data = [aDecoder decodeObject];
  return [self initWithData: data];
}

@end

@implementation NSBitmapImageRep (GNUstepExtension)

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
  /* This is a quick hack to make it work - if the extension is that
     of a tiff file, we init with data */
  if ([ext isEqualToString: @"tiff"]  ||  [ext isEqualToString: @"tif"])
    {
      NSData* data = [NSData dataWithContentsOfFile: filename];
      return [self imageRepsWithData: data];
    }

  /* Otherwise, we attempt using wraster classes to load the file
     (which could be png, etc) */
  array = [NSMutableArray arrayWithCapacity: 2];
  images = 0;
  do
    {
      imageRep = [[[self class] alloc] _initFromWrasterFile: filename 
				                     number: images];
      if (imageRep)
	{
	  [array addObject: AUTORELEASE(imageRep)];
	}
      images++;
    }
  while (imageRep);

  return array;
}

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
  _compression = info->compression;
  _comp_factor = 255 * (1 - ((float)info->quality)/100.0);

  if (NSTiffRead(image, info, [self bitmapData]))
    {
      RELEASE(self);
      NSLog(@"Tiff read invalid TIFF image data in directory %d", imageNumber);
      return nil;
    }

  return self;
}

// This are just placeholders for the implementation in the backend
- _initFromWrasterFile: (NSString *)filename number: (int)imageNumber
{
  return nil;
}

+ (NSArray *) _wrasterFileTypes
{
  return nil;
}

@end
