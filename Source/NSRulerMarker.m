/** <title>NSRulerMarker</title>

   <abstract>Displays a symbol in a NSRulerView.</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Sept 2001
   
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

#include <Foundation/NSException.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>

@implementation NSRulerMarker

- (id)initWithRulerView:(NSRulerView *)aRulerView
         markerLocation:(float)location
		  image:(NSImage *)anImage
	    imageOrigin:(NSPoint)imageOrigin
{
  if (aRulerView == nil || anImage == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"No view or image for ruler marker"];

  _isMovable = YES;
  _isRemovable = NO;
  _location = location;
  _imageOrigin = imageOrigin;
  _rulerView = aRulerView;
  ASSIGN(_image, anImage);

  return self;
}

- (void) dealloc
{
  RELEASE(_image);
  
  [super dealloc];
}

- (NSRulerView *)ruler
{
  return _rulerView;
}

- (void)setImage:(NSImage *)anImage
{
  ASSIGN(_image, anImage);
}

- (NSImage *)image
{
  return _image;
}

- (void)setImageOrigin:(NSPoint)aPoint
{
  _imageOrigin = aPoint;
}

- (NSPoint)imageOrigin
{
  return _imageOrigin;
}

- (NSRect)imageRectInRuler
{
    //BOOL flipped = [_rulerView isFlipped];
  NSSize size = [_image size];

  // FIXME
  if ([_rulerView orientation] == NSHorizontalRuler)
    {
      return NSMakeRect(_location - _imageOrigin.x, -_imageOrigin.y,
			size.width, size.height);
    }
  else
    {
    }

  return NSZeroRect;
}

- (float)thicknessRequiredInRuler
{
  NSSize size = [_image size];

  //FIXME
  if ([_rulerView orientation] == NSHorizontalRuler)
    {
      return size.height;
    }
  else
    {
      return size.width;
    }
}

- (void)setMovable:(BOOL)flag
{
  _isMovable = flag; 
}

- (BOOL)isMovable
{
  return _isMovable;
}

- (void)setRemovable:(BOOL)flag
{
  _isRemovable = flag;
}

- (BOOL)isRemovable
{
  return _isRemovable;
}

- (void)setMarkerLocation:(float)location
{
  _location = location;
}
 
- (float)makerLocation
{
  return _location;
}

- (void)setRepresentedObject:(id <NSCopying>)anObject
{
  _representedObject = anObject;
}

- (id <NSCopying>)representedObject
{
  return _representedObject;
}

- (void)drawRect:(NSRect)aRect
{
  NSPoint aPoint;
  NSRect rect = [self imageRectInRuler];

  aPoint = rect.origin;
  if ([_rulerView isFlipped])
    {
      aPoint.y += rect.size.height;
    }
  rect = NSIntersectionRect(aRect, rect);
  if (NSIsEmptyRect(rect))
    return;

  [_rulerView lockFocus];
  [_image compositeToPoint: aPoint
	  operation: NSCompositeSourceOver];
  [_rulerView unlockFocus];
}

- (BOOL)isDragging
{
  return _isDragging;
}

- (BOOL)trackMouse:(NSEvent *)theEvent adding:(BOOL)flag
{
  NSView *client = [_rulerView clientView];

  if (flag)
    {
      if ([client respondsToSelector: @selector(rulerView:shouldAddMarker:)] &&
	  [client rulerView: _rulerView shouldAddMarker: self] == NO)
	return NO;
    }
  else if (!_isMovable && !_isRemovable)
    {
      return NO;
    }
  else if ([client respondsToSelector: @selector(rulerView:shouldMoveMarker:)] &&
	  [client rulerView: _rulerView shouldMoveMarker: self] == NO)
    {
      return NO;
    }

  _isDragging = YES;
  // FIXME

  _isDragging = NO;

  return YES;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone*)zone
{
  NSRulerMarker *new = (NSRulerMarker*)NSCopyObject (self, 0, zone);

  new->_image = [_image copyWithZone: zone];
  new->_isDragging = NO;
  return new;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _rulerView];
  [aCoder encodeObject: _image];
  [aCoder encodeConditionalObject: _representedObject];
  [aCoder encodePoint: _imageOrigin];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_location];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isMovable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isRemovable];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  _rulerView = [aDecoder decodeObject];
  _image = [aDecoder decodeObject];
  _representedObject = [aDecoder decodeObject];
  _imageOrigin = [aDecoder decodePoint];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_location];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isMovable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isRemovable];

  return self;
}

// NSObject protocol

@end





