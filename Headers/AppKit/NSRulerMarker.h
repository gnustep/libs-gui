/* 
   NSRulerMarker.h

   Displays a symbol in a NSRulerView.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: Feb 1999
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
#ifndef _GNUstep_H_NSRulerMarker
#define _GNUstep_H_NSRulerMarker

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@class NSRulerView;
@class NSImage;
@class NSEvent;

@interface NSRulerMarker : NSObject <NSCopying, NSCoding>
{
  NSRulerView *_rulerView;
  NSImage *_image;
  id <NSCopying> _representedObject;
  NSPoint _imageOrigin;
  float _location;
  BOOL _isMovable;
  BOOL _isRemovable;
  BOOL _isDragging;
}

- (id)initWithRulerView:(NSRulerView *)aRulerView
         markerLocation:(float)location
		  image:(NSImage *)anImage
	    imageOrigin:(NSPoint)imageOrigin; 

- (NSRulerView *)ruler; 

- (void)setImage:(NSImage *)anImage; 
- (NSImage *)image;

- (void)setImageOrigin:(NSPoint)aPoint; 
- (NSPoint)imageOrigin; 
- (NSRect)imageRectInRuler; 
- (float)thicknessRequiredInRuler; 

- (void)setMovable:(BOOL)flag;
- (BOOL)isMovable; 
- (void)setRemovable:(BOOL)flag; 
- (BOOL)isRemovable; 

- (void)setMarkerLocation:(float)location; 
- (float)markerLocation; 

- (void)setRepresentedObject:(id <NSCopying>)anObject; 
- (id <NSCopying>)representedObject;

- (void)drawRect:(NSRect)aRect;
- (BOOL)isDragging; 
- (BOOL)trackMouse:(NSEvent *)theEvent adding:(BOOL)adding; 

@end

#endif /* _GNUstep_H_NSRulerMarker */
