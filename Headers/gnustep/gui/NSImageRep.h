/* 
   NSImageRep.h

   Abstract representation of an image.

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

#ifndef _GNUstep_H_NSImageRep
#define _GNUstep_H_NSImageRep

#include <AppKit/stdappkit.h>
#include <AppKit/NSPasteboard.h>
#include <Foundation/NSCoder.h>

@interface NSImageRep : NSObject <NSCoding>

{
  // Attributes
  NSString* colorSpace;
  NSSize size;
  BOOL   hasAlpha;
  BOOL   isOpaque;
  int    bitsPerSample;
  int    _pixelsWide;
  int    _pixelsHigh;
}

//
// Creating an NSImageRep
//
+ (id)imageRepWithContentsOfFile:(NSString *)filename;
+ (NSArray *)imageRepsWithContentsOfFile:(NSString *)filename;
+ (id)imageRepWithPasteboard:(NSPasteboard *)pasteboard;
+ (NSArray *)imageRepsWithPasteboard:(NSPasteboard *)pasteboard;

//
// Checking Data Types 
//
+ (BOOL)canInitWithData:(NSData *)data;
+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard;
+ (NSArray *)imageFileTypes;
+ (NSArray *)imagePasteboardTypes;
+ (NSArray *)imageUnfilteredFileTypes;
+ (NSArray *)imageUnfilteredPasteboardTypes;

//
// Setting the Size of the Image 
//
- (void)setSize:(NSSize)aSize;
- (NSSize)size;

//
// Specifying Information about the Representation 
//
- (int)bitsPerSample;
- (NSString *)colorSpaceName;
- (BOOL)hasAlpha;
- (BOOL)isOpaque;
- (int)pixelsHigh;
- (int)pixelsWide;
- (void)setAlpha:(BOOL)flag;
- (void)setBitsPerSample:(int)anInt;
- (void)setColorSpaceName:(NSString *)aString;
- (void)setOpaque:(BOOL)flag;
- (void)setPixelsHigh:(int)anInt;
- (void)setPixelsWide:(int)anInt;

//
// Drawing the Image 
//
- (BOOL)draw;
- (BOOL)drawAtPoint:(NSPoint)aPoint;
- (BOOL)drawInRect:(NSRect)aRect;

//
// Managing NSImageRep Subclasses 
//
+ (Class)imageRepClassForData:(NSData *)data;
+ (Class)imageRepClassForFileType:(NSString *)type;
+ (Class)imageRepClassForPasteboardType:(NSString *)type;
+ (void)registerImageRepClass:(Class)imageRepClass;
+ (NSArray *)registeredImageRepClasses;
+ (void)unregisterImageRepClass:(Class)imageRepClass;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSImageRep
