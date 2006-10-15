/** <title>NSBitmapImageRep.m</title>

   <abstract>Bitmap image representation.</abstract>

   Copyright (C) 1996, 2003, 2004 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@gnu.org>
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include <stdlib.h>
#include <math.h>
#include <tiff.h>

#include "AppKit/NSBitmapImageRep.h"

#include "NSBitmapImageRep+GIF.h"
#include "NSBitmapImageRep+JPEG.h"
#include "NSBitmapImageRep+PNG.h"
#include "NSBitmapImageRep+PNM.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSValue.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSView.h"
#include "GSGuiPrivate.h"

#include "nsimage-tiff.h"

/* Maximum number of planes */
#define MAX_PLANES 5

/* FIXME: By default the libtiff library (v3.5.7 and less at least) do
   not support LZW compression, but it's not possible to find out if it
   does or not until after we've already written an image :-(.  */
static BOOL supports_lzw_compression = NO;

/* Backend methods (optional) */
@interface NSBitmapImageRep (GSPrivate)
// GNUstep extension
- _initFromTIFFImage: (TIFF *)image number: (int)imageNumber;

// Internal
- (int) _localFromCompressionType: (NSTIFFCompression)type;
- (NSTIFFCompression) _compressionTypeFromLocal: (int)type;
@end

/**
  <unit>
  <heading>Class Description</heading>
  <p>
  NSBitmapImageRep is an image representation for handling images composed
  of pixels. The standard image format for NSBitmapImageRep is the TIFF
  format. However, through the use of image filters and other methods, many
  other standard image formats can be handled by NSBitmapImageRep.

  Images are typically handled through the NSImage class and there is often
  no need to use the NSBitmapImageRep class directly. However there may
  be cases where you want to manipulate the image bitmap data directly.
  </p>
  </unit>
*/ 
@implementation NSBitmapImageRep 

/** Returns YES if the image stored in data can be read and decoded */
+ (BOOL) canInitWithData: (NSData *)data
{
  TIFF	*image = NULL;

  if (data == nil)
    {
      return NO;
    }

  if ([self _bitmapIsPNG: data])
    return YES;

  if ([self _bitmapIsPNM: data])
    return YES;

  if ([self _bitmapIsJPEG: data])
    return YES;

  if ([self _bitmapIsGIF: data])
    return YES;

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

/** Returns a list of image filename extensions that are understood by
    NSBitmapImageRep.  */
+ (NSArray *) imageUnfilteredFileTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      types = [[NSArray alloc] initWithObjects:
	@"tiff", @"tif",
	@"pnm", @"ppm",
#if HAVE_LIBUNGIF || HAVE_LIBGIF
	@"gif",
#endif
#if HAVE_LIBJPEG
	@"jpeg", @"jpg",
#endif
#if HAVE_LIBPNG
	@"png",
#endif
	nil];
    }

  return types;
}

/** Returns a list of image pasteboard types that are understood by
    NSBitmapImageRep.  */
+ (NSArray *) imageUnfilteredPasteboardTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      types = [[NSArray alloc] initWithObjects: NSTIFFPboardType, nil];
    }
  
  return types;
}

/** <p>Returns a newly allocated NSBitmapImageRep object representing the
    image stored in imageData. If the image data contains more than one
    image, the first one is choosen.</p><p>See Also: +imageRepWithData:</p>  
*/
+ (id) imageRepWithData: (NSData *)imageData
{
  NSArray* array;

  array = [self imageRepsWithData: imageData];
  if ([array count])
    {
      return [array objectAtIndex: 0];
    }
  return nil;
}

/**<p>Returns an array containing newly allocated NSBitmapImageRep
    objects representing the images stored in imageData.</p>
    <p>See Also: +imageRepWithData:</p>
*/
+ (NSArray*) imageRepsWithData: (NSData *)imageData
{
  int		 i, images;
  TIFF		 *image;
  NSMutableArray *array;

  if (imageData == nil)
    {
      NSLog(@"NSBitmapImageRep: nil image data");
      return [NSArray array];
    }

  if ([self _bitmapIsPNG: imageData])
    {
      NSBitmapImageRep *rep;
      NSArray *a;

      rep=[[self alloc] _initBitmapFromPNG: imageData];
      if (!rep)
        return [NSArray array];
      a = [NSArray arrayWithObject: rep];
      DESTROY(rep);
      return a;
    }

  if ([self _bitmapIsPNM: imageData])
    {
      NSBitmapImageRep *rep;
      NSArray *a;

      rep=[[self alloc] _initBitmapFromPNM: imageData
			      errorMessage: NULL];
      if (!rep)
        return [NSArray array];
      a = [NSArray arrayWithObject: rep];
      DESTROY(rep);
      return a;
    }

  if ([self _bitmapIsJPEG: imageData])
    {
      NSBitmapImageRep *rep;
      NSArray *a;

      rep=[[self alloc] _initBitmapFromJPEG: imageData
			       errorMessage: NULL];
      if (!rep)
        return [NSArray array];
      a = [NSArray arrayWithObject: rep];
      DESTROY(rep);
      return a;
    }

  if ([self _bitmapIsGIF: imageData])
    {
      NSBitmapImageRep *rep;
      NSArray *a;

      rep=[[self alloc] _initBitmapFromGIF: imageData
			      errorMessage: NULL];
      if (!rep)
        return [NSArray array];
      a = [NSArray arrayWithObject: rep];
      DESTROY(rep);
      return a;
    }

  image = NSTiffOpenDataRead((char *)[imageData bytes], [imageData length]);
  if (image == NULL)
    {
      NSLog(@"NSBitmapImageRep: unable to parse TIFF data");
      return [NSArray array];
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

/** Loads only the default (first) image from the TIFF image contained in
   data. */
- (id) initWithData: (NSData *)imageData
{
  TIFF 	*image;

  if (imageData == nil)
    {
      RELEASE(self);
      return nil;
    }

  if ([isa _bitmapIsPNG: imageData])
    return [self _initBitmapFromPNG: imageData];

  if ([isa _bitmapIsPNM: imageData])
    return [self _initBitmapFromPNM: imageData
		       errorMessage: NULL];

  if ([isa _bitmapIsJPEG: imageData])
    return [self _initBitmapFromJPEG: imageData
			errorMessage: NULL];

  if ([isa _bitmapIsGIF: imageData])
    return [self _initBitmapFromGIF: imageData
		       errorMessage: NULL];


  image = NSTiffOpenDataRead((char *)[imageData bytes], [imageData length]);
  if (image == NULL)
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
  int bps, spp, alpha;
  NSSize size;
  NSString *space;
  unsigned char *planes[4];
  NSDictionary *dict;

  dict = [GSCurrentContext() GSReadRect: rect];
  if (dict == nil)
    {
      NSLog(@"NSBitmapImageRep initWithFocusedViewRect: failed");
      RELEASE(self);
      return nil;
    }
  _imageData = RETAIN([dict objectForKey: @"Data"]);
  if (_imageData == nil)
    {
      NSLog(@"NSBitmapImageRep initWithFocusedViewRect: failed");
      RELEASE(self);
      return nil;
    }
  bps = [[dict objectForKey: @"BitsPerSample"] intValue];
  if (bps == 0)
    bps = 8;
  spp = [[dict objectForKey: @"SamplesPerPixel"] intValue];
  alpha = [[dict objectForKey: @"HasAlpha"] intValue];
  size = [[dict objectForKey: @"Size"] sizeValue];
  space = [dict objectForKey: @"ColorSpace"];
  planes[0] = (unsigned char *)[_imageData bytes];
  self = [self initWithBitmapDataPlanes: planes
		pixelsWide: size.width
		pixelsHigh: size.height
		bitsPerSample: bps
		samplesPerPixel: spp
	        hasAlpha: (alpha) ? YES : NO
		isPlanar: NO
		colorSpaceName: space
		bytesPerRow: 0
		bitsPerPixel: 0];
  return self;
}

/** 
    <init />
    <p>
    Initializes a newly created NSBitmapImageRep object to hold image data
    specified in the planes buffer and organized according to the
    additional arguments passed into the method.
    </p>
    <p>
    The planes argument is an array of char pointers where each array
    holds a single component or plane of data. Note that if data is
    passed into the method via planes, the data is NOT copied and not
    freed when the object is deallocated. It is assumed that the data
    will always be available. If planes is NULL, then a suitable amount
    of memory will be allocated to store the information needed. One can
    then obtain a pointer to the planes data using the -bitmapData or
    -getBitmapDataPlanes: method.
    </p>
    <p>
    Each component of the data is in "standard" order, such as red, green,
    blue for RGB color images. The transparency component, if these is one, should
    always be last.
    </p>
    <p>
    The other arguments to the method consist of:
    </p>
    <deflist>
      <term>width and height</term>
      <desc>The width and height of the image in pixels</desc>
      <term>bps</term>
      <desc>
      The bits per sample or the number of bits used to store a number in
      one component of one pixel of the image. Typically this is 8 (bits)
      but can be 2 or 4, although not all values are supported.
      </desc>
      <term>spp</term>
      <desc>
      Samples per pixel, or the number of components of color in the pixel.
      For instance this would be 4 for an RGB image with transparency.
      </desc>
      <term>alpha</term>
      <desc>
      Set to YES if the image has a transparency component.
      </desc>
      <term>isPlanar</term>
      <desc>
      Set to YES if the data is arranged in planes, i.e. one component
      per buffer as stored in the planes array. If NO, then the image data
      is mixed in one buffer. For instance, for RGB data, the first sample
      would contain red, then next green, then blue, followed by red for the
      next pixel.
      </desc>
      <term>colorSpaceName</term>
      <desc>
      This argument specifies how the data values are to be interpreted.
      Possible values include the typical colorspace names (although
      not all values are currently supported)
      </desc>
      <term>rowBytes</term>
      <desc>
      Specifies the number of bytes contained in a single scan line of the
      data. Normally this can be computed from the width of the image,
      the samples per pixel and the bits per sample. However, if the data
      is aligned along word boundaries, this value may differ from this.
      If rowBytes is 0, the method will calculate the value assuming there
      are no extra bytes at the end of the scan line.
      </desc>
      <term>pixelBits</term>
      <desc>
      This is normally bps for planar data and bps times spp for non-planar
      data, but sometimes images have extra bits. If pixelBits is 0 it
      will be calculated as described above.
      </desc>
      </deflist>
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
		bitsPerPixel: (int)pixelBits
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
      unsigned int i;

      for (i = 0; i < MAX_PLANES; i++)
 	_imagePlanes[i] = NULL;
      for (i = 0; i < ((_isPlanar) ? _numColors : 1); i++)
 	_imagePlanes[i] = planes[i];
    }
  else
    {
      unsigned char* bits;
      long length;
      unsigned int i;

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
/** Returns the number of bits need to contain one pixels worth of data.
    This is normally the number of samples per pixel times the number of
    bits in one sample. */
- (int) bitsPerPixel
{
  return _bitsPerPixel;
}

/** Returns the number of samples in a pixel. For instance, a normal RGB
    image with transparency would have a samplesPerPixel of 4.  */
- (int) samplesPerPixel
{
  return _numColors;
}

/** Returns YES if the image components are stored separately. Returns
    NO if the components are meshed (i.e. all the samples for one pixel
    come before the next pixel).  */
- (BOOL) isPlanar
{
  return _isPlanar;
}

/** Returns the number of planes in an image.  Typically this is
    equal to the number of samples in a planar image or 1 for a non-planar
    image.  */
- (int) numberOfPlanes
{
  return (_isPlanar) ? _numColors : 1;
}

/** Returns the number of bytes in a plane. This is the number of bytes
    in a row times tne height of the image.  */
- (int) bytesPerPlane
{
  return _bytesPerRow*_pixelsHigh;
}

/** Returns the number of bytes in a row. This is typically based on the
    width of the image and the bits per sample and samples per pixel (if
    in medhed configuration). However it may differ from this if set
    explicitly in -initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:.
*/
- (int) bytesPerRow
{
  return _bytesPerRow;
}

//
// Getting Image Data 
//
/** Returns the first plane of data representing the image.  */
- (unsigned char *) bitmapData
{
  unsigned char *planes[MAX_PLANES];
  [self getBitmapDataPlanes: planes];
  return planes[0];
}

/** Files the array data with pointers to each of the data planes
    representing the image. The data array must be allocated to contain
    at least -samplesPerPixel pointers.  */
- (void) getBitmapDataPlanes: (unsigned char **)data
{
  unsigned int i;

  if (data)
    {
      for (i = 0; i < _numColors; i++)
	{
	  data[i] = _imagePlanes[i];
	}
    }
}

/** Draws the image in the current window according the information
    from the current gState, including information about the current
    point, scaling, etc.  */
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
	       (const unsigned char **)_imagePlanes);
  return YES;
}

//
// Producing a TIFF Representation of the Image 
//
/** Produces an NSData object containing a TIFF representation of all
   the images stored in anArray.  BUGS: Currently this only works if the
   images are NSBitmapImageRep objects, and it only creates an TIFF from the
   first image in the array.  */
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

/** Produces an NSData object containing a TIFF representation of all
   the images stored in anArray. The image is compressed according to
   the compression type and factor. BUGS: Currently this only works if
   the images are NSBitmapImageRep objects, and it only creates an
   TIFF from the first image in the array. */
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

/** Returns an NSData object containing a TIFF representation of the
    receiver.  */
- (NSData*) TIFFRepresentation
{
  if ([self canBeCompressedUsing: _compression] == NO)
    {
      [self setCompression: NSTIFFCompressionNone factor: 0];
    }
  return [self TIFFRepresentationUsingCompression: _compression 
	       factor: _comp_factor];
}

/** Returns an NSData object containing a TIFF representation of the
    receiver. The TIFF data is compressed using compresssion type
    and factor.  */
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

  if ([self canBeCompressedUsing: type] == NO)
    {
      type = NSTIFFCompressionNone;
      factor = 0;
    }

  if (_isPlanar)
    info.planarConfig = PLANARCONFIG_SEPARATE;
  else
    info.planarConfig = PLANARCONFIG_CONTIG;

  if ([_colorSpace isEqual: NSDeviceRGBColorSpace]
      || [_colorSpace isEqual: NSCalibratedRGBColorSpace])
    info.photoInterp = PHOTOMETRIC_RGB;
  else if ([_colorSpace isEqual: NSDeviceWhiteColorSpace]
	   || [_colorSpace isEqual: NSCalibratedWhiteColorSpace])
    info.photoInterp = PHOTOMETRIC_MINISBLACK;
  else if ([_colorSpace isEqual: NSDeviceBlackColorSpace]
	   || [_colorSpace isEqual: NSCalibratedBlackColorSpace])
    info.photoInterp = PHOTOMETRIC_MINISWHITE;
  else
    {
      NSWarnMLog(@"Unknown colorspace %@.", _colorSpace);
      info.photoInterp = PHOTOMETRIC_RGB;
    }

  info.extraSamples = (_hasAlpha) ? 1 : 0;
  info.compression = [self _localFromCompressionType: type];
  if (factor < 0)
    factor = 0;
  if (factor > 255)
    factor = 255;
  info.quality = (1 - ((float)factor)/255.0) * 100;
  info.numImages = 1;
  info.error = 0;

  image = NSTiffOpenDataWrite(&bytes, &length);
  if (image == 0)
    {
      [NSException raise: NSTIFFException 
		   format: @"Opening data stream for writting"];
    }
  if (NSTiffWrite(image, &info, [self bitmapData]) != 0)
    {
      [NSException raise: NSTIFFException format: @"Writing data"];
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
    NSTIFFCompressionNEXT,
    NSTIFFCompressionPackBits,
    NSTIFFCompressionOldJPEG
  };

  if (list)
    *list = types;
  if (numTypes)
    *numTypes = sizeof(types)/sizeof(*types);
}

+ (NSString*) localizedNameForTIFFCompressionType: (NSTIFFCompression)type
{
  switch (type)
    {
      case NSTIFFCompressionNone: return _(@"No Compression");
      case NSTIFFCompressionCCITTFAX3: return _(@"CCITTFAX3 Compression");
      case NSTIFFCompressionCCITTFAX4: return _(@"CCITTFAX4 Compression");
      case NSTIFFCompressionLZW: return _(@"LZW Compression");
      case NSTIFFCompressionJPEG: return _(@"JPEG Compression");
      case NSTIFFCompressionNEXT: return _(@"NEXT Compression");
      case NSTIFFCompressionPackBits: return _(@"PackBits Compression");
      case NSTIFFCompressionOldJPEG: return _(@"Old JPEG Compression");
      default: return nil;
    }
}

/** Returns YES if the receiver can be stored in a representation
    compressed using the compression type.  */
- (BOOL) canBeCompressedUsing: (NSTIFFCompression)compression
{
  BOOL does;
  switch (compression)
    {
      case NSTIFFCompressionCCITTFAX3:
      case NSTIFFCompressionCCITTFAX4:
	if (_numColors == 1 && _bitsPerSample == 1)
	  does = YES;
	else
	  does = NO;
	break;

      case NSTIFFCompressionLZW: 
	does = supports_lzw_compression;
	break;
	
      case NSTIFFCompressionNone:
      case NSTIFFCompressionJPEG:
      case NSTIFFCompressionPackBits:
      case NSTIFFCompressionOldJPEG:
	does = YES;
	break;

      case NSTIFFCompressionNEXT:
      default:
	does = NO;
    }
  return does;
}

/** Returns the receivers compression and compression factor, which is
    set either when the image is read in or by -setCompression:factor:.
    Factor is ignored in many compression schemes. For JPEG compression,
    factor can be any value from 0 to 255, with 255 being the maximum
    compression.  */
- (void) getCompression: (NSTIFFCompression*)compression
		 factor: (float*)factor
{
  *compression = _compression;
  *factor = _comp_factor;
}

- (void) setCompression: (NSTIFFCompression)compression
		 factor: (float)factor
{
  _compression = compression;
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
      unsigned int i;

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
  NSData *data = [self TIFFRepresentation];

  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: data forKey: @"NSTIFFRepresentation"];
    }
  else
    {
      [aCoder encodeObject: data];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSData	*data;

  self = [super initWithCoder: aDecoder];
  if ([aDecoder allowsKeyedCoding])
    {
      data = [aDecoder decodeObjectForKey: @"NSTIFFRepresentation"];	
    }
  else
    {
      data = [aDecoder decodeObject];
    }
  return [self initWithData: data];
}

@end

@implementation NSBitmapImageRep (GSPrivate)

- (int) _localFromCompressionType: (NSTIFFCompression)type
{
  switch (type)
    {
    case NSTIFFCompressionNone: return COMPRESSION_NONE;
    case NSTIFFCompressionCCITTFAX3: return COMPRESSION_CCITTFAX3;
    case NSTIFFCompressionCCITTFAX4: return COMPRESSION_CCITTFAX4;
    case NSTIFFCompressionLZW: return COMPRESSION_LZW;
    case NSTIFFCompressionJPEG: return COMPRESSION_JPEG;
    case NSTIFFCompressionNEXT: return COMPRESSION_NEXT;
    case NSTIFFCompressionPackBits: return COMPRESSION_PACKBITS;
    case NSTIFFCompressionOldJPEG: return COMPRESSION_OJPEG;
    default:
      break;
    }
  return COMPRESSION_NONE;
}

- (NSTIFFCompression) _compressionTypeFromLocal: (int)type
{
  switch (type)
    {
    case COMPRESSION_NONE: return NSTIFFCompressionNone;
    case COMPRESSION_CCITTFAX3: return NSTIFFCompressionCCITTFAX3;
    case COMPRESSION_CCITTFAX4: return NSTIFFCompressionCCITTFAX4;
    case COMPRESSION_LZW: return NSTIFFCompressionLZW;
    case COMPRESSION_JPEG: return NSTIFFCompressionJPEG;
    case COMPRESSION_NEXT: return NSTIFFCompressionNEXT;
    case COMPRESSION_PACKBITS: return NSTIFFCompressionPackBits;
    case COMPRESSION_OJPEG: return NSTIFFCompressionOldJPEG;
    default:
      break;
   }
  return NSTIFFCompressionNone;
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
  _compression = [self _compressionTypeFromLocal: info->compression];
  _comp_factor = 255 * (1 - ((float)info->quality)/100.0);

  if (NSTiffRead(image, info, [self bitmapData]))
    {
      OBJC_FREE(info);
      RELEASE(self);
      NSLog(@"Tiff read invalid TIFF image data in directory %d", imageNumber);
      return nil;
    }
  OBJC_FREE(info);

  return self;
}

@end

