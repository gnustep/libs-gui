/*
   NSCachedImageRep.h

   Cached image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSCachedImageRep
#define _GNUstep_H_NSCachedImageRep
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSImageRep.h>
#import <AppKit/NSGraphics.h>

@class NSWindow;

/**
 * NSCachedImageRep is a specialized image representation that stores
 * cached bitmap data for efficient drawing operations. It provides a
 * way to capture and cache the visual content of windows or specific
 * rectangular areas as bitmap images, enabling fast redrawing and
 * composition operations without regenerating complex graphics content.
 *
 * This class is particularly useful for performance optimization in
 * scenarios where the same graphical content needs to be drawn repeatedly,
 * such as during window dragging, animation sequences, or when implementing
 * custom drawing caches. The cached representation can be created from
 * existing window content or initialized as an empty bitmap with specific
 * characteristics.
 *
 * NSCachedImageRep supports various pixel formats and color depths,
 * allowing for optimization based on the specific requirements of the
 * cached content. It can handle both separate and planar pixel formats,
 * with optional alpha channel support for transparency effects.
 */
APPKIT_EXPORT_CLASS
@interface NSCachedImageRep : NSImageRep
{
  // Attributes
  NSRect      _rect;
  NSWindow*   _window;
}

//
// Initializing an NSCachedImageRep
//

/**
 * GNUstep extension
 *
 * Initializes a new cached image representation with the specified
 * dimensions and pixel characteristics. This extended initializer
 * provides additional control over the pixel format by allowing
 * specification of both logical size and actual pixel dimensions,
 * enabling support for high-resolution displays and custom pixel
 * densities. The depth parameter controls color depth and pixel
 * format, while separate and alpha flags determine memory layout
 * and transparency support respectively.
 */
- (id) initWithSize: (NSSize)aSize
	 pixelsWide: (NSInteger)pixelsWide
	 pixelsHigh: (NSInteger)pixelsHigh
	      depth: (NSWindowDepth)aDepth
	   separate: (BOOL)separate
	      alpha: (BOOL)alpha;

/**
 * Initializes a new cached image representation with the specified
 * size and pixel characteristics. This creates an empty bitmap cache
 * with the given logical size and pixel format properties. The depth
 * parameter determines the color depth and pixel format, while the
 * separate flag controls whether pixels are stored in separate planes
 * or interleaved format. The alpha flag enables transparency support
 * by including an alpha channel in the pixel format.
 */
- (id)initWithSize:(NSSize)aSize
	     depth:(NSWindowDepth)aDepth
	  separate:(BOOL)separate
	     alpha:(BOOL)alpha;
/**
 * Initializes a cached image representation by capturing the contents
 * of a specific rectangular area within the given window. This method
 * creates a bitmap cache by copying the current visual content of the
 * specified rectangle from the window's backing store. The cached
 * representation can then be used for efficient redrawing operations
 * without requiring regeneration of the original content.
 */
- (id)initWithWindow:(NSWindow *)aWindow
		rect:(NSRect)aRect;

//
// Getting the Representation
//
/**
 * Returns the rectangular area that was cached from the original window.
 * This rectangle represents the bounds of the content that was captured
 * when the cached image representation was created using the window-based
 * initializer. The rectangle is specified in the coordinate system of
 * the original window from which the content was cached.
 */
- (NSRect)rect;
/**
 * Returns the window from which this cached image representation was
 * created. This provides access to the original source window that
 * was used to capture the cached content. Returns nil if the cached
 * image representation was created using size-based initialization
 * rather than window content capture.
 */
- (NSWindow *)window;

@end

#endif // _GNUstep_H_NSCachedImageRep
