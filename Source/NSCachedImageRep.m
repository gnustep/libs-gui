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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

static BOOL NSImageCompositing = YES;

@interface GSCacheW : NSWindow
@end

@implementation GSCacheW

- (void) initDefaults
{
  [super initDefaults];
  [self setExcludedFromWindowsMenu: YES];
  [self setAutodisplay: NO];
}
- (void) display
{
}
- (void) displayIfNeeded
{
}
- (void) setViewsNeedDisplay: (BOOL)f
{
}
@end

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NXCachedImageRepBackend
- (BOOL) draw;
@end

@implementation NSCachedImageRep

- (void) initialize
{
  id obj = [[NSUserDefaults standardUserDefaults]
  	stringForKey: @"ImageCompositing"];
  if (obj)
    NSImageCompositing = [obj boolValue];
}

// Initializing an NSCachedImageRep 
- (id) initWithSize: (NSSize)aSize
	      depth: (NSWindowDepth)aDepth
	   separate: (BOOL)separate
	      alpha: (BOOL)alpha
{
  NSWindow	*win;
  NSRect	frame;

  frame.origin = NSMakePoint(0,0);
  frame.size = aSize;
  win = [[GSCacheW alloc] initWithContentRect: frame
				    styleMask: NSBorderlessWindowMask
				      backing: NSBackingStoreRetained
					defer: NO];
  self = [self initWithWindow: win rect: frame];
  [win release];
  return self;
}

- (id) initWithWindow: (NSWindow *)win rect: (NSRect)rect
{
  [super init];

  _window = [win retain];
  _rect   = rect;

  /* Either win or rect must be non-NULL. If rect is empty, we get the
     frame info from the window. If win is nil we create it from the
     rect information. */
  if (NSIsEmptyRect(_rect))
    {
      if (!_window) 
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"Must specify either window or rect when "
			      @"creating NSCachedImageRep"];
	}

      _rect = [_window frame];
    }
  if (!_window)
    _window = [[GSCacheW alloc] initWithContentRect: _rect
					  styleMask: NSBorderlessWindowMask
					    backing: NSBackingStoreRetained
					      defer: NO];
  [self setSize: _rect.size];
  [self setAlpha: NO];		/* FIXME - when we have alpha in windows */
  [self setOpaque: YES];
  [self setPixelsHigh: _rect.size.height];
  [self setPixelsWide: _rect.size.width];
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
  if (NSImageCompositing)
    PScomposite(NSMinX(_rect), NSMinY(_rect), NSWidth(_rect), NSHeight(_rect),
	      [_window gState], NSMinX(_rect), NSMinY(_rect),
	      NSCompositeSourceOver);
  else
    NSCopyBits([_window gState], _rect, _rect.origin);
  return YES;
}

- (BOOL) drawAtPoint: (NSPoint)aPoint
{
  NSGraphicsContext *ctxt;

  if (size.width == 0 && size.height == 0)
    return NO;

  NSDebugLLog(@"NSImage", @"Drawing at point %f %f\n", aPoint.x, aPoint.y);
  ctxt = GSCurrentContext();
  if (aPoint.x != 0 || aPoint.y != 0)
    {
      if ([[ctxt focusView] isFlipped])
	aPoint.y -= size.height;
    }
  if (NSImageCompositing)
    PScomposite(NSMinX(_rect), NSMinY(_rect), NSWidth(_rect), NSHeight(_rect),
	      [_window gState], aPoint.x, aPoint.y,
	      NSCompositeSourceOver);
  else
    NSCopyBits([_window gState], _rect, aPoint);
  return NO;
}

- (BOOL) drawInRect: (NSRect)aRect
{
  NSGraphicsContext *ctxt;

  NSDebugLLog(@"NSImage", @"Drawing in rect (%f %f %f %f)\n", 
	      NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), NSHeight(aRect));
  if (size.width == 0 && size.height == 0)
    return NO;

  ctxt = GSCurrentContext();
  if ([[ctxt focusView] isFlipped])
    aRect.origin.y -= NSHeight(aRect);
  if (NSImageCompositing)
    PScomposite(NSMinX(_rect), NSMinY(_rect), NSWidth(_rect), NSHeight(_rect),
	      [_window gState], NSMinX(aRect), NSMinY(aRect),
	      NSCompositeSourceOver);
  else
    NSCopyBits([_window gState], _rect, aRect.origin);
  return YES;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

@end

