/** <title>GSTheme</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004-2006 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date: Jan 2004
   
   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
   */

#ifndef _GNUstep_H_GSTheme
#define _GNUstep_H_GSTheme

#include <Foundation/NSGeometry.h>
// For gradient types
#include "AppKit/NSButtonCell.h"

@class NSBundle;
@class NSColor;
@class GSDrawTiles;

/**
 * This defines how the center middle image in a tile array should be
 * used when drawing a rectangle.
 */
typedef enum {
  FillStyleNone,	/** The image is not drawn */
  FillStyleScale,	/** The image is scaled to fit */
  FillStyleRepeat,	/** The image is tiled from bottom left */
  FillStyleCenter	/** The image is tiled from the center */
} GSThemeFillStyle;


/** Notification sent when a theme has just become active.
 */
APPKIT_EXPORT	NSString	*GSThemeDidActivateNotification;

/** Notification sent when a theme has become inactive.
 */
APPKIT_EXPORT	NSString	*GSThemeDidDeactivateNotification;


/**
  <p><em>This interface is <strong>HIGHLY</strong> unstable
  and incomplete at present.</em>
  </p>
  <p>
  This is a class used for 'theming', which is mostly a matter of
  encapsulating common drawing behaviors so that GUI appearance can
  be easily modified, but also includes mechanisms for altering
  some GUI behavior (such mas orientation and position of menus).
  </p>
  <p>
  Methods in this class standardize drawing of buttons, borders
  and other common GUI elements, so that all other classes within
  the GUI will provide a consistent appearance by using these
  methods.
  </p>
  <p>
  The default implementation uses the standard configurable colors
  defined in NSColor, such as <code>controlLightHighlightColor</code>,
  <code>controlShadowColor</code> and <code>controlDarkShadowColor</code>.<br />
  Themes are expected to override the default system color list with their
  own versions, and this class cooperates with [NSColor] and [NSColorList]
  to establish the correct system color list when a theme is activated.
  </p>
  <p>
  The class provides a mechanism for automatic loading of theme bundles
  consisting of resources used to define how drawing is done, plus an
  optional binary subclass of this class (to replace/extend the drawing
  methods this class provides).
  </p>
  <p>
  In future this class should provide mechanisms to draw controls by
  tiling of images, and provide control over GUI behavior by controlling
  the values returned by NSInterfaceStyleForKey() so that controls
  use the appropriate behavior.
  </p>
*/ 
@interface GSTheme : NSObject
{
@private
  NSBundle		*_bundle;
  NSMutableArray	*_images;
  NSMutableDictionary	*_tiles;
}

/**
 * Set the currently active theme to be the instance specified.<br />
 * You do not normally need to call this method as it is called
 * automatically when the user default which specifies the current
 * theme (GSTheme) is updated.
 */
+ (void) setTheme: (GSTheme*)theme;

/**
 * Returns the currently active theme instance.  This is the value most
 * recently set using +setTheme: or (if none has been set) is a default
 * instance of the base class.
 */
+ (GSTheme*) theme;

/**
 * <p>This method is called automatically when the receiver is made into
 * the currently active theme by the +setTheme: method. Subclasses may
 * override it to perform startup operations, but should call the super
 * class implementation before doing their own thing.
 * </p>
 * <p>The base implementation handles setup and caching of certain image
 * information and then sends a GSThemeDidActivateNotification to allow
 * other parts of the GUI library to update themselves from the new theme.<br />
 * If the theme sets an alternative system color list, the notification
 * userInfo dictionary will contain that list keyed on <em>Colors</em>.
 * </p>
 */
- (void) activate;

/**
 * Return the bundle containing the resources used by the current theme.
 */
- (NSBundle*) bundle;

/**
 * <p>This method is called automatically when the receiver is stopped from
 * being the currently active theme by the use of the +setTheme: method
 * to make another theme active. Subclasses may override it to perform
 * shutdown operations, but should call the super class implementation
 * after their own.
 * </p>
 * <p>The base implementation handles some cleanup and then sends a
 * GSThemeDidDeactivateNotification to allow other parts of the GUI library
 * to update themselves.
 * </p>
 */
- (void) deactivate;

/** <init />
 * Initialise an instance of a theme with the specified resource bundle.<br />
 * You don't need to call this method directly, but if you are subclassing
 * you may need to override this to provide additional initialisation.
 */
- (id) initWithBundle: (NSBundle*)bundle;

/**
 * Returns the tile image information for a particular image name,
 * or nil if there is no such information.<br />
 * The GUI library uses this internally to handling tiling of image
 * information to draw user interface elements.  The tile information
 * returned by this method can be passed to the
 * -fillRect:withTiles:background:fillStyle: method.
 */
- (GSDrawTiles*) tilesNamed: (NSString*)aName; 
@end

/**
 * Theme drawing methods
 */
@interface	GSTheme (Drawing)

/**
 * Draws a button frame and background (not its content) for the specified
 * cell and view.<br />
 * Returns the rectangle into which the cell contents should be drawn.
 */
- (NSRect) drawButton: (NSRect)frame
		   in: (NSButtonCell*)cell
		 view: (NSView*)view
		style: (int)style
		state: (int)state;

/** Draws the indicator (normally a dotted rectangle) to show that
 * the view currently has keyboard focus.
 */
- (void) drawFocusFrame: (NSRect)frame view: (NSView*)view;

/**
 * Draws the background of a window ... normally a simple fill with the
 * the window's background color.
 */
- (void) drawWindowBackground: (NSRect)frame view: (NSView*)view;

@end

/**
 * Helper functions for drawing standard items.
 */
@interface	GSTheme (MidLevelDrawing)
/** Draw a standard button */
- (NSRect) drawButton: (NSRect)border withClip: (NSRect)clip;

/** Draw a dark bezel border */ 
- (NSRect) drawDarkBezel: (NSRect)border withClip: (NSRect)clip;

/** Draw a "dark" button border (used in tableviews) */
- (NSRect) drawDarkButton: (NSRect)border withClip: (NSRect)clip;

/** Draw a frame photo border.  Used in NSImageView.   */
- (NSRect) drawFramePhoto: (NSRect)border withClip: (NSRect)clip;

/** Draw a gradient border. */
- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
		       inRect: (NSRect)border 
		     withClip: (NSRect)clip;

/** Draw a grey bezel border */
- (NSRect) drawGrayBezel: (NSRect)border withClip: (NSRect)clip;

/** Draw a groove border */
- (NSRect) drawGroove: (NSRect)border withClip: (NSRect)clip;

/** Draw a light bezel border */
- (NSRect) drawLightBezel: (NSRect)border withClip: (NSRect)clip;

/** Draw a white bezel border */
- (NSRect) drawWhiteBezel: (NSRect)border withClip: (NSRect)clip;

@end

/**
 * Low level drawiong methods ... themes may use these for drawing,
 * but should not normally override them.
 */
@interface	GSTheme (LowLevelDrawing)
/**
 * Method to tile the supplied image to fill the horizontal rectangle.
 */
- (void) fillHorizontalRect: (NSRect)rect
		  withImage: (NSImage*)image
		   fromRect: (NSRect)source
		    flipped: (BOOL)flipped;

/**
 * Tile rect with image.  The tiling starts with the origin of the
 * first copy of the image at the bottom left corner of the rect
 * unless center is YES, in which case the image is centered in rect
 * and tiled outwards from that.
 */
- (void) fillRect: (NSRect)rect
withRepeatedImage: (NSImage*)image
	 fromRect: (NSRect)source
	   center: (BOOL)center;

/**
 * Method to tile a rectangle given an array of nine tile images.<br />
 * This draws the left, right, top and bottom borders by tiling the
 * images at TileCL, TileCR, TileTM and TileBM respectively.  It then
 * draws the four corner images and finally deals with the remaining
 * space in the middle according to the specified style.<br />
 * The background color specified is used where style is FillStyleNone.
 */
- (void) fillRect: (NSRect)rect
	withTiles: (GSDrawTiles*)tiles
       background: (NSColor*)color
	fillStyle: (GSThemeFillStyle)style;

/**
 * Method to tile the supplied image to fill the vertical rectangle.
 */
- (void) fillVerticalRect: (NSRect)rect
		withImage: (NSImage*)image
		 fromRect: (NSRect)source
		  flipped: (BOOL)flipped;
@end

#endif /* _GNUstep_H_GSTheme */
