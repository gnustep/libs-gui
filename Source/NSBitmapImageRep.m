/* 
   NSBitmapImageRep.m

   Bitmap image representations

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/NSBitmapImageRep.h>

@implementation NSBitmapImageRep

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBitmapImageRep class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Allocating and Initializing a New NSBitmapImageRep Object 
//
+ (id)imageRepWithData:(NSData *)tiffData
{
  return nil;
}

+ (NSArray *)imageRepsWithData:(NSData *)tiffData
{
  return nil;
}

//
// Producing a TIFF Representation of the Image 
//
+ (NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
{
  return nil;
}

+ (NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
				usingCompression:(NSTIFFCompression)compressionType
factor:(float)factor
{
  return nil;
}

//
// Setting and Checking Compression Types 
//
+ (void)getTIFFCompressionTypes:(const NSTIFFCompression **)list
			  count:(int *)numTypes
{}

+ (NSString *)localizedNameForTIFFCompressionType:(NSTIFFCompression)compression
{
  return nil;
}

//
// Instance methods
//
//
// Allocating and Initializing a New NSBitmapImageRep Object 
//
- (id)initWithData:(NSData *)tiffData
{
  return nil;
}

- (id)initWithFocusedViewRect:(NSRect)rect
{
  return nil;
}

- (id)initWithBitmapDataPlanes:(unsigned char **)planes
		    pixelsWide:(int)width
pixelsHigh:(int)height
		    bitsPerSample:(int)bps
samplesPerPixel:(int)spp
		    hasAlpha:(BOOL)alpha
isPlanar:(BOOL)config
		    colorSpaceName:(NSString *)colorSpaceName
bytesPerRow:(int)rowBytes
		    bitsPerPixel:(int)pixelBits
{
  return nil;
}

//
// Getting Information about the Image 
//
- (int)bitsPerPixel
{
  return 0;
}

- (int)samplesPerPixel
{
  return 0;
}

- (BOOL)isPlanar
{
  return NO;
}

- (int)numberOfPlanes
{
  return 0;
}

- (int)bytesPerPlane
{
  return 0;
}

- (int)bytesPerRow
{
  return 0;
}

//
// Getting Image Data 
//
- (unsigned char *)bitmapData
{
  return NULL;
}

- (void)getBitmapDataPlanes:(unsigned char **)data
{}

//
// Producing a TIFF Representation of the Image 
//
- (NSData *)TIFFRepresentation
{
  return nil;
}

- (NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compressionType
					factor:(float)factor
{
  return nil;
}

//
// Setting and Checking Compression Types 
//
- (BOOL)canBeCompressedUsing:(NSTIFFCompression)compression
{
  return NO;
}

- (void)getCompression:(NSTIFFCompression *)compression
		factor:(float *)factor
{}

- (void)setCompression:(NSTIFFCompression)compression
		factor:(float)factor
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
