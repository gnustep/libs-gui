/** <title>NSCustomImageRep</title>

   <abstract>Custom image representation.</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Mar 1996
   
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
#include <Foundation/NSCoder.h>
#include <Foundation/NSDebug.h>
#include "AppKit/NSCustomImageRep.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSView.h"
#include "AppKit/NSColor.h"
#include "AppKit/DPSOperators.h"

@implementation NSCustomImageRep

- (id) initWithDrawSelector: (SEL)aSelector
		   delegate: (id)anObject
{
  [super init];

  /* WARNING: Retaining the delegate may or may not create a cyclic graph */
  _delegate = RETAIN(anObject);
  _selector = aSelector;
  return self;
}

- (void) dealloc
{
  RELEASE(_delegate);
  [super dealloc];
}

// Identifying the Object 
- (id) delegate
{
  return _delegate;
}

- (SEL) drawSelector
{
  return _selector;
}

- (BOOL) draw
{
  [_delegate performSelector: _selector withObject: self];
  return YES;
}

//
// TODO: For both of the following methods we can extract the 
// logic in the superclass to another method and call it here 
// if the delegate is set from both places.
//
- (BOOL) drawAtPoint: (NSPoint)aPoint
{
  BOOL ok, reset;
  NSGraphicsContext *ctxt;
  NSAffineTransform *ctm = nil;

  // if both are zero and the delegate isn't set, return no.
  if (_size.width == 0 && _size.height == 0 && _delegate == nil)
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

  // if both are zero and the delegate isn't set.
  if (_size.width == 0 && _size.height == 0 && _delegate == nil)
    return NO;

  ctxt = GSCurrentContext();
  
  // if either is zero, don't scale at all.
  if(_size.width == 0 || _size.height == 0)
    {
      scale = NSMakeSize(NSWidth(aRect), 
			 NSHeight(aRect));
    }
  else
    {
      scale = NSMakeSize(NSWidth(aRect) / _size.width, 
			 NSHeight(aRect) / _size.height);
    }

  if ([[ctxt focusView] isFlipped])
    aRect.origin.y -= NSHeight(aRect);
  ctm = GSCurrentCTM(ctxt);
  DPStranslate(ctxt, NSMinX(aRect), NSMinY(aRect));
  DPSscale(ctxt, scale.width, scale.height);
  ok = [self draw];
  GSSetCTM(ctxt, ctm);
  return ok;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  
  [aCoder encodeObject: _delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_selector];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_delegate];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_selector];
  return self;
}

@end
