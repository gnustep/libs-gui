/*
   NSCachedImageRep.m

   Cached image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
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
/*
    Keeps a representation of an image in an off-screen window.  If the
    message initFromWindow:rect: is sent with a nil window, one is created
    using the rect information.
*/
#include <Foundation/NSException.h>
#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSWindow.h>

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NXCachedImageRepBackend
- (BOOL) draw;
@end

@implementation NSCachedImageRep

// Initializing an NSCachedImageRep 
- (id) initWithSize: (NSSize)aSize
		depth: (NSWindowDepth)aDepth
		separate: (BOOL)separate
		alpha: (BOOL)alpha
{
  return nil;
}

- initWithWindow: (NSWindow *)win rect: (NSRect)rect
{
  int style = NSClosableWindowMask;

  [super init];

  _window = win;
  _rect   = rect;

  /* Either win or rect must be non-NULL. If rect is empty, we get the
     frame info from the window. If win is nil we create it from the
     rect information. */
  if (NSIsEmptyRect(_rect))
    {
      if (!_window) 
	{
	  [NSException raise: NSInvalidArgumentException
	    format: @"Must specify either window or rect when creating NSCachedImageRep"];
	}

      _rect = [_window frame];
    }
  if (!_window)
    _window = [[NSWindow alloc] initWithContentRect: _rect
			styleMask: style
			backing: NSBackingStoreRetained
			defer: NO];
  return self;
}

- (void) dealloc
{
  [_window release];
  [super dealloc];
}

// Getting the Representation 
- (NSRect) rect
{
  return _rect;
}

- (NSWindow *) window
{
  return _window;
}

- (BOOL)draw
{
  return NO;
}

// NSCoding protocol
- (void) encodeWithCoder: aCoder
{
}

- initWithCoder: aDecoder
{
  return self;
}

@end

