/** <title>NSImageRep</title>

   <abstract>Abstract representation of an image.</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@colorado.edu>
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

#include "config.h"
#include <string.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDebug.h>
#include "AppKit/NSImageRep.h"
#include "AppKit/NSBitmapImageRep.h"
#include "AppKit/NSEPSImageRep.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSView.h"
#include "AppKit/NSColor.h"
#include "AppKit/DPSOperators.h"

static NSMutableArray *imageReps = nil;
static Class NSImageRep_class = NULL;

@implementation NSImageRep

+ (void) initialize
{
  /* While there are four imageRep subclasses, in practice, only two of
     them can load in data from an external source. */
  if (self == [NSImageRep class])
    {
      NSImageRep_class = self;
      imageReps = [[NSMutableArray alloc] initWithCapacity: 2];
      [imageReps addObject: [NSBitmapImageRep class]];
      //[imageReps addObject: [NSEPSImageRep class]];
    }
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
      Class c = imageRepClass;

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
  NSString *ext;
  Class rep;

  // Is the file extension already the file type?
  ext = [filename pathExtension];
  if (!ext)
    {
      // FIXME: Should this be an exception?
      NSLog(@"Extension missing from image filename - '%@'", filename);
      return nil;
    }
  ext = [ext lowercaseString];

  if (self == NSImageRep_class)
    {
      rep = [self imageRepClassForFileType: ext];
    }
  else if ([[self imageFileTypes] containsObject: ext])
    {
      rep = self;
    }
  else
    return nil;

  {
    NSData* data;

    data = [NSData dataWithContentsOfFile: filename];
    if ([rep respondsToSelector: @selector(imageRepsWithData:)])
      return [rep imageRepsWithData: data];
    else if ([rep respondsToSelector: @selector(imageRepWithData:)])
      {
	NSImageRep *imageRep = [rep imageRepWithData: data];

	if (imageRep != nil)
	  return [NSArray arrayWithObject: imageRep];
      }
  }

  return nil;
}

+ (id)imageRepWithContentsOfURL:(NSURL *)anURL
{
  NSArray* array;

  array = [self imageRepsWithContentsOfURL: anURL];
  if ([array count])
    return [array objectAtIndex: 0];
  return nil;
}

+ (NSArray *)imageRepsWithContentsOfURL:(NSURL *)anURL
{
  Class rep;
  NSData* data;

  // FIXME: Should we use the file type for URLs or only check the data?
  data = [anURL resourceDataUsingCache: YES];

  if (self == NSImageRep_class)
    {
      rep = [self imageRepClassForData: data];
    }
  else if ([self canInitWithData: data])
    {
      rep = self;
    }
  else
    return nil;

  if ([rep respondsToSelector: @selector(imageRepsWithData:)])
    return [rep imageRepsWithData: data];
  else if ([rep respondsToSelector: @selector(imageRepWithData:)])
    {
      NSImageRep *imageRep = [rep imageRepWithData: data];

      if (imageRep != nil)
	return [NSArray arrayWithObject: imageRep];
    }

  return nil;
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
  NSArray *reps;

  if (self == NSImageRep_class)
    {
      reps = imageReps;
    }
  else
    {
      reps = [NSArray arrayWithObject: self];
    }

  array = [NSMutableArray arrayWithCapacity: 1];

  count = [reps count];
  for (i = 0; i < count; i++)
    {
      NSString* ptype;
      Class rep = [reps objectAtIndex: i];

      ptype = [pasteboard availableTypeFromArray: [rep imagePasteboardTypes]];
      if (ptype != nil)
	{
	  NSData* data = [pasteboard dataForType: ptype];

	  if ([rep respondsToSelector: @selector(imageRepsWithData:)])
	    [array addObjectsFromArray: [rep imageRepsWithData: data]];
	  else if ([rep respondsToSelector: @selector(imageRepWithData:)])
	    {
	      NSImageRep *imageRep = [rep imageRepWithData: data];

	      if (rep != nil)
		[array addObject: imageRep];
	    }
	}
    }

  if ([array count] == 0)
    return nil;

  return (NSArray *)array;
}


// Checking Data Types
+ (BOOL) canInitWithData: (NSData *)data
{
  /* Subclass responsibility */
  return NO;
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray *pbTypes = [pasteboard types];
  NSArray *myTypes = [self imageUnfilteredPasteboardTypes];

  return ([pbTypes firstObjectCommonWithArray: myTypes] != nil);
}

+ (NSArray *) imageFileTypes
{
  // FIXME: We should check what conversions are defined by services.
  return [self imageUnfilteredFileTypes];
}

+ (NSArray *) imagePasteboardTypes
{
  // FIXME: We should check what conversions are defined by services.
  return [self imageUnfilteredPasteboardTypes];
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


// Instance methods
- (void) dealloc
{
  RELEASE(_colorSpace);
  [super dealloc];
}

// Setting the Size of the Image
- (void) setSize: (NSSize)aSize
{
  _size = aSize;
}

- (NSSize) size
{
  return _size;
}

// Specifying Information about the Representation
- (int) bitsPerSample
{
  return _bitsPerSample;
}

- (NSString *) colorSpaceName
{
  return _colorSpace;
}

- (BOOL) hasAlpha
{
  return _hasAlpha;
}

- (BOOL) isOpaque
{
  return _isOpaque;
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
  _hasAlpha = flag;
}

- (void) setBitsPerSample: (int)anInt
{
  _bitsPerSample = anInt;
}

- (void) setColorSpaceName: (NSString *)aString
{
  ASSIGN(_colorSpace, aString);
}

- (void) setOpaque: (BOOL)flag
{
  _isOpaque = flag;
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
  /* Subclass should implement this. */
  return YES;
}

- (BOOL) drawAtPoint: (NSPoint)aPoint
{
  BOOL ok, reset;
  NSGraphicsContext *ctxt;
  NSAffineTransform *ctm = nil;

  if (_size.width == 0 && _size.height == 0)
    return NO;

  NSDebugLLog(@"NSImage", @"Drawing at point %f %f\n", aPoint.x, aPoint.y);
  reset = 0;
  ctxt = GSCurrentContext();
  if (aPoint.x != 0 || aPoint.y != 0)
    {
      if ([[ctxt focusView] isFlipped])
	aPoint.y -= _size.height;
      ctm = GSCurrentCTM(ctxt);
      DPStranslate(ctxt, aPoint.x, aPoint.y);
      reset = 1;
    }
  ok = [self draw];
  if (reset)
    GSSetCTM(ctxt, ctm);
  return ok;
}

- (BOOL) drawInRect: (NSRect)aRect
{
  NSSize scale;
  BOOL ok;
  NSGraphicsContext *ctxt;
  NSAffineTransform *ctm;

  NSDebugLLog(@"NSImage", @"Drawing in rect (%f %f %f %f)\n", 
	      NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), NSHeight(aRect));
  if (_size.width == 0 && _size.height == 0)
    return NO;

  ctxt = GSCurrentContext();
  scale = NSMakeSize(NSWidth(aRect) / _size.width, 
		     NSHeight(aRect) / _size.height);
  if ([[ctxt focusView] isFlipped])
    aRect.origin.y -= NSHeight(aRect);
  ctm = GSCurrentCTM(ctxt);
  DPStranslate(ctxt, NSMinX(aRect), NSMinY(aRect));
  DPSscale(ctxt, scale.width, scale.height);
  ok = [self draw];
  GSSetCTM(ctxt, ctm);
  return ok;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone
{
  NSImageRep	*copy;

  copy = (NSImageRep*)NSCopyObject(self, 0, zone);
  copy->_colorSpace = [_colorSpace copyWithZone: zone];

  return copy;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _colorSpace];
  [aCoder encodeSize: _size];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasAlpha];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isOpaque];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_bitsPerSample];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_colorSpace];
  _size = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasAlpha];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isOpaque];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_bitsPerSample];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsWide];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
  return self;
}

@end

