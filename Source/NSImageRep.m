/* 
   NSImageRep.m

   Description...

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

#include <gnustep/gui/NSImageRep.h>

// NSImageRep notifications
NSString *NSImageRepRegistryChangedNotification;

@implementation NSImageRep

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSImageRep class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSImageRep
//
+ (id)imageRepWithContentsOfFile:(NSString *)filename
{
  return nil;
}

+ (NSArray *)imageRepsWithContentsOfFile:(NSString *)filename
{
  return nil;
}

+ (id)imageRepWithPasteboard:(NSPasteboard *)pasteboard
{
  return nil;
}

+ (NSArray *)imageRepsWithPasteboard:(NSPasteboard *)pasteboard
{
  return nil;
}

//
// Checking Data Types 
//
+ (BOOL)canInitWithData:(NSData *)data
{
  return NO;
}

+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard
{
  return NO;
}

+ (NSArray *)imageFileTypes
{
  return nil;
}

+ (NSArray *)imagePasteboardTypes
{
  return nil;
}

+ (NSArray *)imageUnfilteredFileTypes
{
  return nil;
}

+ (NSArray *)imageUnfilteredPasteboardTypes
{
  return nil;
}

//
// Managing NSImageRep Subclasses 
//
+ (Class)imageRepClassForData:(NSData *)data
{
  return NULL;
}

+ (Class)imageRepClassForFileType:(NSString *)type
{
  return NULL;
}

+ (Class)imageRepClassForPasteboardType:(NSString *)type
{
  return NULL;
}

+ (void)registerImageRepClass:(Class)imageRepClass
{}

+ (NSArray *)registeredImageRepClasses
{
  return nil;
}

+ (void)unregisterImageRepClass:(Class)imageRepClass
{}

//
// Instance methods
//
//
// Setting the Size of the Image 
//
- (void)setSize:(NSSize)aSize
{}

- (NSSize)size
{
  return NSZeroSize;
}

//
// Specifying Information about the Representation 
//
- (int)bitsPerSample
{
  return 0;
}

- (NSString *)colorSpaceName
{
  return nil;
}

- (BOOL)hasAlpha
{
  return NO;
}

- (BOOL)isOpaque
{
  return NO;
}

- (int)pixelsHigh
{
  return 0;
}

- (int)pixelsWide
{
  return 0;
}

- (void)setAlpha:(BOOL)flag
{}

- (void)setBitsPerSample:(int)anInt
{}

- (void)setColorSpaceName:(NSString *)aString
{}

- (void)setOpaque:(BOOL)flag
{}

- (void)setPixelsHigh:(int)anInt
{}

- (void)setPixelsWide:(int)anInt
{}

//
// Drawing the Image 
//
- (BOOL)draw
{
  return NO;
}

- (BOOL)drawAtPoint:(NSPoint)aPoint
{
  return NO;
}

- (BOOL)drawInRect:(NSRect)aRect
{
  return NO;
}

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
