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

#include <gnustep/gui/config.h>
#include <string.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSEPSImageRep.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSView.h>
#include <AppKit/DPSOperators.h>

static NSMutableArray*	imageReps = NULL;

@implementation NSImageRep

+ (void) initialize
{
  /* While there are four imageRep subclasses, in practice, only two of
     them can load in data from an external source. */
  if (self == [NSImageRep class])
    {
      id obj;
      imageReps = [[NSMutableArray alloc] initWithCapacity: 2];
      obj = [[NSUserDefaults standardUserDefaults] 
      		stringForKey: @"ImageCompositing"];
      if (!obj || [obj boolValue] == YES)
        [imageReps addObject: [NSBitmapImageRep class]];
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

  ext = [filename pathExtension];
  // FIXME: Should this be an exception? Should we even check this?
  if (!ext)
    {
      NSLog(@"Extension missing from filename - '%@'", filename);
      return nil;
    }

  array = nil;
  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      Class rep = [imageReps objectAtIndex: i];
      if ([[rep imageFileTypes] indexOfObject: ext] != NSNotFound)
	{
	  NSData* data;


	  if ([rep respondsToSelector: @selector(imageRepsWithFile:)])
	    array = [rep imageRepsWithFile: filename];
	  if ([array count] > 0)
	    break;

	  data = [NSData dataWithContentsOfFile: filename];
	  if ([rep respondsToSelector: @selector(imageRepsWithData:)])
	    array = [rep imageRepsWithData: data];
	  else if ([rep respondsToSelector: @selector(imageRepWithData:)])
	    array = [rep imageRepWithData: data];
	  if ([array count] > 0)
	    break;
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

  array = [NSMutableArray arrayWithCapacity: 1];

  count = [imageReps count];
  for (i = 0; i < count; i++)
    {
      NSString* ptype;
      Class rep = [imageReps objectAtIndex: i];

      ptype = [pasteboard availableTypeFromArray: [rep imagePasteboardTypes]];
      if (ptype != nil)
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

- (id) copyWithZone: (NSZone *)zone
{
  NSImageRep	*copy;

  copy = (NSImageRep*)NSCopyObject(self, 0, zone);

  copy->size = size;
  copy->hasAlpha = hasAlpha;
  copy->isOpaque = isOpaque;
  copy->bitsPerSample = bitsPerSample;
  copy->_pixelsWide = _pixelsWide;
  copy->_pixelsHigh = _pixelsHigh;
  copy->_colorSpace = RETAIN(_colorSpace);

  return copy;
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
  return YES;		/* Subclass should implement this.	*/
}

- (BOOL) drawAtPoint: (NSPoint)aPoint
{
  BOOL ok, reset;
  NSGraphicsContext *ctxt;

  if (size.width == 0 && size.height == 0)
    return NO;

  NSDebugLLog(@"NSImage", @"Drawing at point %f %f\n", aPoint.x, aPoint.y);
  reset = 0;
  ctxt = GSCurrentContext();
  if (aPoint.x != 0 || aPoint.y != 0)
    {
      if ([[ctxt focusView] isFlipped])
	aPoint.y -= size.height;
      DPSmatrix(ctxt); DPScurrentmatrix(ctxt);
      DPStranslate(ctxt, aPoint.x, aPoint.y);
      reset = 1;
    }
  ok = [self draw];
  if (reset)
    DPSsetmatrix(ctxt);
  return ok;
}

- (BOOL) drawInRect: (NSRect)aRect
{
  NSSize scale;
  BOOL ok;
  NSGraphicsContext *ctxt;

  NSDebugLLog(@"NSImage", @"Drawing in rect (%f %f %f %f)\n", 
	      NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), NSHeight(aRect));
  if (size.width == 0 && size.height == 0)
    return NO;

  ctxt = GSCurrentContext();
  scale = NSMakeSize(NSWidth(aRect) / size.width, 
		     NSHeight(aRect) / size.height);
  if ([[ctxt focusView] isFlipped])
    aRect.origin.y -= NSHeight(aRect);
  DPSmatrix(ctxt); DPScurrentmatrix(ctxt);
  DPStranslate(ctxt, NSMinX(aRect), NSMinY(aRect));
  DPSscale(ctxt, scale.width, scale.height);
  ok = [self draw];
  DPSsetmatrix(ctxt);
  return ok;
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
      if ([[rep imageFileTypes] indexOfObject: type] != NSNotFound)
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

      if ([[rep imagePasteboardTypes] indexOfObject: type] != NSNotFound)
	{
	  return rep;
	}
    }
  return Nil;
}

+ (void) registerImageRepClass: (Class)imageRepClass
{
  if ([imageReps containsObject: imageRepClass] == NO)
    {
      Class		c = imageRepClass;

      while (c != nil && c != [NSObject class] && c != [NSImageRep class])
	{
	  c = [c superclass];
	}
      if (c != [NSImageRep class])
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"Attempt to register non-imagerep class"];
	}
      [imageReps addObject: imageRepClass];
    }
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSImageRepRegistryChangedNotification
		  object: self];
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
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _colorSpace];
  [aCoder encodeSize: size];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &hasAlpha];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &isOpaque];
  [aCoder encodeValueOfObjCType: @encode(int) at: &bitsPerSample];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_colorSpace];
  size = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &hasAlpha];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &isOpaque];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &bitsPerSample];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
  return self;
}

@end

