/* 
   NSBitmapImageRep.h

   Bitmap image representations

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSBitmapImageRep
#define _GNUstep_H_NSBitmapImageRep

#include <AppKit/NSImageRep.h>

@class NSArray;
@class NSString;
@class NSData;
@class NSMutableData;
@class NSColor;

typedef enum _NSTIFFCompression {
  NSTIFFCompressionNone  = 1,
  NSTIFFCompressionCCITTFAX3  = 3,
  NSTIFFCompressionCCITTFAX4  = 4,
  NSTIFFCompressionLZW  = 5,
  NSTIFFCompressionJPEG  = 6,
  NSTIFFCompressionNEXT  = 32766,
  NSTIFFCompressionPackBits  = 32773,
  NSTIFFCompressionOldJPEG  = 32865
} NSTIFFCompression;

#ifndef STRICT_OPENSTEP
// FIXME: This is probably wrong
typedef enum _NSBitmapImageFileType {
    NSTIFFFileType = 0,
    NSBMPFileType = 1,
    NSGIFFileType = 2,
    NSJPEGFileType = 3,
    NSPNGFileType = 4
} NSBitmapImageFileType;
#endif

@interface NSBitmapImageRep : NSImageRep
{
  // Attributes
  unsigned int		_bytesPerRow;
  unsigned int		_numColors;
  unsigned int		_bitsPerPixel;   
  unsigned short	_compression;
  float			_comp_factor;
  BOOL			_isPlanar;
  unsigned char		**_imagePlanes;
  NSMutableData		*_imageData;
}

//
// Allocating and Initializing a New NSBitmapImageRep Object 
//
+ (id) imageRepWithData: (NSData*)tiffData;
+ (NSArray*) imageRepsWithData: (NSData*)tiffData;
- (id) initWithData: (NSData*)tiffData;
- (id) initWithFocusedViewRect: (NSRect)rect;
- (id) initWithBitmapDataPlanes: (unsigned char**)planes
		     pixelsWide: (int)width
		     pixelsHigh: (int)height
		  bitsPerSample: (int)bps
		samplesPerPixel: (int)spp
		       hasAlpha: (BOOL)alpha
		       isPlanar: (BOOL)config
		 colorSpaceName: (NSString*)colorSpaceName
		    bytesPerRow: (int)rowBytes
		   bitsPerPixel: (int)pixelBits;

#ifndef STRICT_OPENSTEP
- (void)colorizeByMappingGray:(float)midPoint 
		      toColor:(NSColor *)midPointColor 
		 blackMapping:(NSColor *)shadowColor
		 whiteMapping:(NSColor *)lightColor;
- (id)initWithBitmapHandle:(void *)bitmap;
- (id)initWithIconHandle:(void *)icon;
#endif

//
// Getting Information about the Image 
//
- (int) bitsPerPixel;
- (int) samplesPerPixel;
- (BOOL) isPlanar;
- (int) numberOfPlanes;
- (int) bytesPerPlane;
- (int) bytesPerRow;

//
// Getting Image Data 
//
- (unsigned char*) bitmapData;
- (void) getBitmapDataPlanes: (unsigned char**)data;

//
// Producing a TIFF Representation of the Image 
//
+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray*)anArray;
+ (NSData*) TIFFRepresentationOfImageRepsInArray: (NSArray*)anArray
				usingCompression: (NSTIFFCompression)type
					  factor: (float)factor;
- (NSData*) TIFFRepresentation;
- (NSData*) TIFFRepresentationUsingCompression: (NSTIFFCompression)type
					factor: (float)factor;

#ifndef STRICT_OPENSTEP
+ (NSData *)representationOfImageRepsInArray:(NSArray *)imageReps 
				   usingType:(NSBitmapImageFileType)storageType
				  properties:(NSDictionary *)properties;
- (NSData *)representationUsingType:(NSBitmapImageFileType)storageType 
			 properties:(NSDictionary *)properties;
#endif

//
// Setting and Checking Compression Types 
//
+ (void) getTIFFCompressionTypes: (const NSTIFFCompression**)list
			   count: (int*)numTypes;
+ (NSString*) localizedNameForTIFFCompressionType: (NSTIFFCompression)type;
- (BOOL) canBeCompressedUsing: (NSTIFFCompression)compression;
- (void) getCompression: (NSTIFFCompression*)compression
		 factor: (float*)factor;
- (void) setCompression: (NSTIFFCompression)compression
		 factor: (float)factor;

#ifndef STRICT_OPENSTEP
- (void)setProperty:(NSString *)property withValue:(id)value;
- (id)valueForProperty:(NSString *)property;
#endif

@end

@interface NSBitmapImageRep (GNUstepExtension)
+ (NSArray*) imageRepsWithFile: (NSString *)filename;
@end

#endif // _GNUstep_H_NSBitmapImageRep
