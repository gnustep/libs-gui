/* 
   NSImageRep.m

   Abstract representation of an image.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This file is part of the GNUstep Application Kit Library.

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

#include <string.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSNotification.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSEPSImageRep.h>

// NSImageRep notifications
NSString *NSImageRepRegistryChangedNotification;

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NXImageRepBackend
- (BOOL) drawAtPoint: (NSPoint)aPoint;
- (BOOL) drawInRect: (NSRect)aRect;
@end

static NSMutableArray*	imageReps = NULL;

/* Get the extension from a name  */
static NSString *
extension(NSString *name)
{
/* Waiting for NSString to be complete */
#if 0
  return [name pathExtension];
#else
  const char* cname;
  char *s;

  cname = [name cString];
  s = strrchr(cname, '.');
  if (s > strrchr(cname, '/'))
    return [NSString stringWithCString:s+1];
  else
    return nil;
#endif
} 

@implementation NSImageRep

+ (void) initialize
{
  /* While there are four imageRep subclasses, in practice, only two of
     them can load in data from an external source. */
  if (self == [NSImageRep class])
    {
      imageReps = [[NSMutableArray alloc] initWithCapacity: 2];
      //      [imageReps addObject: [NSBitmapImageRep class]];
      //      [imageReps addObject: [NSEPSImageRep class]];
    }
}

// Creating an NSImageRep
+ (id) imageRepWithContentsOfFile: (NSString *)filename
{
  NSArray* array;

  array = [self imageRepsWithContentsOfFile: filename];
  if ([array count])
    return [array objectAtIndex: 0];
  return nil;
}

+ (NSArray *) imageRepsWithContentsOfFile: (NSString *)filename
{
  int i, count;
  NSString* ext;
  NSMutableArray* array;

  ext = extension(filename);
  // FIXME: Should this be an exception? Should we even check this?
  if (!ext)
    return nil;
  array = [NSMutableArray arrayWithCapacity:1];

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      Class rep = [imageReps objectAtIndex: i];
#if 0
      if ([[rep imageFileTypes] indexOfObject: ext] != NSNotFound)
#else
	/* xxxFIXME: not implemented  in gcc-2.7.2 runtime. */
        if ([rep respondsToSelector: @selector(imageFileTypes)]
	    && [[rep imageFileTypes] indexOfObject: ext] != NSNotFound)
#endif
	  {
	    NSData* data = [NSData dataWithContentsOfFile: filename];
#if 1
	    if ([rep respondsToSelector: @selector(imageRepsWithData:)])
#endif
	      [array addObjectsFromArray: [rep imageRepsWithData: data]];
#if 1
	    else if ([rep respondsToSelector: @selector(imageRepWithData:)])
	      [array addObject: [rep imageRepWithData: data]];
#endif
	  }
    }
  return (NSArray *)array;
}

+ (id) imageRepWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray* array;

  array = [self imageRepsWithPasteboard: pasteboard];
  if ([array count])
    return [array objectAtIndex: 0];
  return nil;
}

+ (NSArray *) imageRepsWithPasteboard: (NSPasteboard *)pasteboard
{
  int i, count;
  NSMutableArray* array;

  array = [NSMutableArray arrayWithCapacity:1];

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      NSString* ptype;
      Class rep = [imageReps objectAtIndex: i];
      if ([rep respondsToSelector: @selector(imagePasteboardTypes)]
	  && (ptype = 
	      [pasteboard availableTypeFromArray:[rep imagePasteboardTypes]]))
	{
	  NSData* data = [pasteboard dataForType: ptype];
	  if ([rep respondsToSelector: @selector(imageRepsWithData:)])
	    [array addObjectsFromArray: [rep imageRepsWithData: data]];
	  else if ([rep respondsToSelector: @selector(imageRepWithData:)])
	    [array addObject: [rep imageRepWithData: data]];
	}
    }
  return (NSArray *)array;
}

- (void) dealloc
{
  [_colorSpace release];
  [super dealloc];
}

// Checking Data Types 
+ (BOOL) canInitWithData: (NSData *)data
{
  /* Subclass responsibility */
  return NO;
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  /* Subclass responsibility */
  return NO;
}

+ (NSArray *) imageFileTypes
{
  /* Subclass responsibility */
  return nil;
}

+ (NSArray *) imagePasteboardTypes
{
  /* Subclass responsibility */
  return nil;
}

+ (NSArray *) imageUnfilteredFileTypes
{
  /* Subclass responsibility */
  return nil;
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  /* Subclass responsibility */
  return nil;
}

// Setting the Size of the Image 
- (void) setSize: (NSSize)aSize
{
  size = aSize;
}

- (NSSize) size
{
  return size;
}

// Specifying Information about the Representation 
- (int) bitsPerSample
{
    return bitsPerSample;
}

- (NSString *) colorSpaceName
{
  return _colorSpace;
}

- (BOOL) hasAlpha
{
  return hasAlpha;
}

- (BOOL) isOpaque
{
  return isOpaque;
}

- (int) pixelsWide
{
  return _pixelsWide;
}

- (int) pixelsHigh
{
  return _pixelsHigh;
}

- (void) setAlpha: (BOOL)flag
{
  hasAlpha = flag;
}

- (void) setBitsPerSample: (int)anInt
{
  bitsPerSample = anInt;
}

- (void) setColorSpaceName: (NSString *)aString
{
  [_colorSpace autorelease];
  _colorSpace = [aString retain];
}

- (void) setOpaque: (BOOL)flag
{
  isOpaque = flag;
}

- (void) setPixelsWide: (int)anInt
{
  _pixelsWide = anInt;
}

- (void) setPixelsHigh: (int)anInt
{
  _pixelsHigh = anInt;
}

// Drawing the Image 
- (BOOL) draw
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL) drawAtPoint: (NSPoint)aPoint
{
  return NO;
}

- (BOOL) drawInRect: (NSRect)aRect
{
  return NO;
}

// Managing NSImageRep Subclasses 
+ (Class) imageRepClassForData: (NSData *)data
{
  int i, count;

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      Class rep = [imageReps objectAtIndex: i];
      if ([rep canInitWithData: data])
	return rep;
    }
  return Nil;
}

+ (Class) imageRepClassForFileType: (NSString *)type
{
  int i, count;

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      Class rep = [imageReps objectAtIndex: i];
      if ([rep respondsToSelector: @selector(imageFileTypes)]
	  && [[rep imageFileTypes] indexOfObject: type] != NSNotFound)
	{
	  return rep;
	}
    }
  return Nil;
}

+ (Class) imageRepClassForPasteboardType: (NSString *)type
{
  int i, count;

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      Class rep = [imageReps objectAtIndex: i];
      if ([rep respondsToSelector: @selector(imagePasteboardTypes)]
	  && ([[rep imagePasteboardTypes] indexOfObject: type] != NSNotFound))
	{
	  return rep;
	}
    }
  return Nil;
}

+ (void) registerImageRepClass: (Class)imageRepClass
{
  [imageReps addObject: imageRepClass];
  /*
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSImageRepRegistryChangedNotification
    object: self];
    */
} 

+ (NSArray *) registeredImageRepClasses
{
  return (NSArray *)imageReps;
}

+ (void) unregisterImageRepClass: (Class)imageRepClass
{
  [imageReps removeObject: imageRepClass];
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSImageRepRegistryChangedNotification
    object: self];
}

// NSCoding protocol
- (void) encodeWithCoder: aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _colorSpace];
  [aCoder encodeSize: size];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &hasAlpha];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &isOpaque];
  [aCoder encodeValueOfObjCType: @encode(int) at: &bitsPerSample];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
}

- initWithCoder: aDecoder
{
  self = [super initWithCoder: aDecoder];

  _colorSpace = [[aDecoder decodeObject] retain];
  size = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &hasAlpha];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &isOpaque];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &bitsPerSample];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
  return self;
}

@end

