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

#include <AppKit/stdappkit.h>
#include <AppKit/NSImageRep.h>
#include <Foundation/NSCoder.h>
#include <AppKit/nsimage-tiff.h>

@interface NSBitmapImageRep : NSImageRep <NSCoding>

{
  // Attributes
  unsigned int    bytesPerRow;
  unsigned int    numColors;
  unsigned int    bitsPerPixel;   
  unsigned short  compression;
  BOOL            _isPlanar;
  unsigned char** imagePlanes;
  NSMutableData*  imageData;

  // Reserved for back-end use
  void *back_end_reserved;
}

//
// Allocating and Initializing a New NSBitmapImageRep Object 
//
+ (id)imageRepWithData:(NSData *)tiffData;
+ (NSArray *)imageRepsWithData:(NSData *)tiffData;
- (id)initWithData:(NSData *)tiffData;
- (id)initWithFocusedViewRect:(NSRect)rect;
- (id)initWithBitmapDataPlanes:(unsigned char **)planes
		    pixelsWide:(int)width
		    pixelsHigh:(int)height
		 bitsPerSample:(int)bps
	       samplesPerPixel:(int)spp
		      hasAlpha:(BOOL)alpha
		      isPlanar:(BOOL)config
		colorSpaceName:(NSString *)colorSpaceName
		   bytesPerRow:(int)rowBytes
		  bitsPerPixel:(int)pixelBits;

//
// Getting Information about the Image 
//
- (int)bitsPerPixel;
- (int)samplesPerPixel;
- (BOOL)isPlanar;
- (int)numberOfPlanes;
- (int)bytesPerPlane;
- (int)bytesPerRow;

//
// Getting Image Data 
//
- (unsigned char *)bitmapData;
- (void)getBitmapDataPlanes:(unsigned char **)data;

//
// Producing a TIFF Representation of the Image 
//
+ (NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray;
+ (NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
				usingCompression:(NSTIFFCompression)compressionType
					  factor:(float)factor;
- (NSData *)TIFFRepresentation;
- (NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compressionType
					factor:(float)factor;

//
// Setting and Checking Compression Types 
//
+ (void)getTIFFCompressionTypes:(const NSTIFFCompression **)list
			  count:(int *)numTypes;
+ (NSString *)localizedNameForTIFFCompressionType:(NSTIFFCompression)compression;
- (BOOL)canBeCompressedUsing:(NSTIFFCompression)compression;
- (void)getCompression:(NSTIFFCompression *)compression
		factor:(float *)factor;
- (void)setCompression:(NSTIFFCompression)compression
		factor:(float)factor;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSBitmapImageRep

