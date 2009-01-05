/** <title>GSTheme</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004-2006 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date: Jan 2004
   
   This file is part of the GNU Objective C User interface library.

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

  <chapter>
    <heading>The theme management system</heading>
    <p>
      The theme management system for the GNUstep GUI is based around the
      [GSTheme] class, which provides support for loading of theme bundles
      and methods for drawing common user interface elements.<br />
      The theme system works in conjunction with a variety of other GUI
      classes and is intended to eventually allow for very major changes
      in GUI appearance and behavior.
    </p>
    <p>
      Various design imperatives apply to the theme system, but probably
      the key ones are:
    </p>
    <list>
      <item>It should allow designers and other non-technical users to
        easily develop new and interesting GUI styles likely to attract
	new users to GNUstep.
      </item>
      <item>Using and switching between themes should be an easy and
        pleasant experience ... so that people are not put off when they
        try using themes.
      </item>
      <item>It should eventually permit a GNUstep application to
        appear as a native application on ms-windows and other systems.
      </item>
    </list>
    <p>
      To attain these aims implies the recognition of some more specific
      objectives and some possible technical solutions:
    </p>
    <list>
      <item>We must have as simple as possible an API for the
        functions handling the way GUI elements work and the way they
	draw themselves.<br />
	The standard OpenStep/MacOS-X API provides mechanisms for
	controlling the colors used to draw controls (via [NSColor] and
	[NSColorList]) and controlling the way controls behave
	(NSInterfaceStyleForKey() and [NSResponder-interfaceStyle]),
	but we need to extend that with methods to draw controls entirely
	differently if required.
      </item>
      <item>We must have a GUI application for theme development.
        It is not sufficient to provide an API if we want good graphic
	designers and user interface specialists to develop themes
	for us.
      </item>
      <item>It must be possible for an application to dynamically change
        the theme in use while it is running and it should be easy for a
	user to select between available themes.<br />
	This implies that themes must be loadable bundles and that it
	must always be possible to unload a theme as well as loading one.<br />
	It suggests that the theme selection mechanism should be in every
	application, perhaps as an extension to an existing panel such
	as the info panel.
      </item>
    </list>
    <section>
      <heading>Types of theming</heading>
      <p>
        There are various aspects of theming which can be treated pretty
	much separately, so there is no reason why a theme might not be
	created which just employs one of these mechanisms.
      </p>
      <deflist>
	<term>System images</term>
	<desc>
	  Possibly the simples theme change ... a theme might supply a
	  new set of system images used for arrows and other icons that
	  the GUI decorates controls with.
	</desc>
        <term>System colors</term>
	<desc>
	  A theme might simply define a new system color list, so that
	  controls are drawn in a new color range, though they would
	  still function the same way.  Even specifying new colors can
	  make the GUI look quite different though.
	</desc>
	<term>Image tiling</term>
	<desc>
	  Controls might be given sets of images used as tiling to draw
	  themselves rather than using the standard line drawing and
	  color fill mechanisms.
	</desc>
	<term>Interface style</term>
	<desc>
	  A theme might supply a set of interface style keys for various
	  controls, defining how those controls should behave subject to
	  the limitation of the range of behaviors coded into the GUI
	  library.
	</desc>
	<term>Method override</term>
	<desc>
	  A theme might actually provide code, in the form of a subclass
	  of [GSTheme] such that drawing methods have completely custom
	  behavior.
	</desc>
      </deflist>

    </section>
  </chapter>

 */

#ifndef _GNUstep_H_GSTheme
#define _GNUstep_H_GSTheme

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSCell.h>
// For gradient types
#include <AppKit/NSButtonCell.h>
// For image frame style
#include <AppKit/NSImageCell.h>
// For scroller constants
#include <AppKit/NSScroller.h>

#if	OS_API_VERSION(GS_API_NONE,GS_API_NONE)
@class NSArray;
@class NSBundle;
@class NSButton;
@class NSColor;
@class NSColorList;
@class NSDictionary;
@class NSImage;
@class NSMenuItemCell;
@class NSMenuView;
@class GSDrawTiles;

/**
 * This defines how the values in a tile array should be used when
 * drawing a rectangle.  Mostly this just effects the center, middle
 * image of the rectangle.<br />
 * FillStyleMatrix is provided for the use of theme editors wishing
 * to display the tile.
 */
typedef enum {
  GSThemeFillStyleNone,		/** CM image is not drawn */
  GSThemeFillStyleScale,	/** CM image is scaled to fit */
  GSThemeFillStyleRepeat,	/** CM image is tiled from bottom left */
  GSThemeFillStyleCenter,	/** CM image is tiled from the center */
  GSThemeFillStyleMatrix	/** a matrix of nine separated images */
} GSThemeFillStyle;


/**
 * This enumeration provides constants for informing drawing methods
 * what state a control is in (and consequently how the display element
 * being drawn should be presented).
 */
typedef enum {
  GSThemeNormalState,		/** A control in its normal state */
  GSThemeHighlightedState,	/** A control which is highlighted */
  GSThemeSelectedState,		/** A control which is selected */
} GSThemeControlState;

/** Notification sent when a theme has just become active.<br />
 * The notification is posted by the -activate method.<br />
 * This is primarily for internal use by AppKit controls which
 * need to readjust how they are displayed when a new theme is in use.
 */
APPKIT_EXPORT	NSString	*GSThemeDidActivateNotification;

/** Notification sent when a theme has just become inactive.<br />
 * The notification is posted by the -deactivate method.<br />
 * This is primarily for use by subclasses of GSTheme which need to perform
 * additional cleanup when the theme stops being used.
 */
APPKIT_EXPORT	NSString	*GSThemeDidDeactivateNotification;

/** Notification sent when a theme is about to become active.<br />
 * The notification is posted by the -activate method.<br />
 * This is primarily for use by subclasses of GSTheme which need to perform
 * additional setup before the theme starts being used by the AppKit controls.
 */
APPKIT_EXPORT	NSString	*GSThemeWillActivateNotification;

/** Notification sent when a theme is about to become inactive.<br />
 * The notification is posted by the -deactivate method.<br />
 * This allows code to make preparatory changes before the current theme
 * is deactivated.
 */
APPKIT_EXPORT	NSString	*GSThemeWillDeactivateNotification;


/**
  <p><em>This interface is <strong>HIGHLY</strong> unstable
  and incomplete at present.</em>
  </p>
  <p>
  This is a class used for 'theming', which is mostly a matter of
  encapsulating common drawing behaviors so that GUI appearance can
  be easily modified, but also includes mechanisms for altering
  some GUI behavior (such as orientation and position of menus).
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
  void		*_reserved;
}

/**
 * Creates and displays a panel allowing selection of different themes
 * and display of the current theme inspector.
 */
+ (void) orderFrontSharedThemePanel: (id)sender;

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
 * class implementation after doing their own thing.
 * </p>
 * <p>The base implementation handles setup and caching of the system
 * color list, standard image information, tiling information,
 * and user defaults.<br />
 * It then sends a GSThemeWillActivateNotification and a
 * GSThemeDidActivateNotification to allow other
 * parts of the GUI library to update themselves from the new theme.
 * </p>
 * <p>Finally, this method marks all windows in the application as needing
 * update ... so they will draw themselves with the new theme information.
 * </p>
 */
- (void) activate;

/**
 * Returns the names of the theme's authors.
 */
- (NSArray*) authors;

/**
 * Return the bundle containing the resources used by the current theme.
 */
- (NSBundle*) bundle;

/**
 * Returns the system color list defined by the receiver.<br />
 * The default implementation returns the color list provided in the
 * theme bundle (if any) or the default system color list.
 */
- (NSColorList*) colors;

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

/**
 * Returns the theme's icon.
 */
- (NSImage*) icon;

/** <init />
 * Initialise an instance of a theme with the specified resource bundle.<br />
 * You don't need to call this method directly, but if you are subclassing
 * you may need to override this to provide additional initialisation.
 */
- (id) initWithBundle: (NSBundle*)bundle;

/**
 * <p>Returns the info dictionary for this theme.  In the base class
 * implementation this is simply the info dictionary of the theme
 * bundle, but subclasses may override this method to return extra
 * or different information.
 * </p>
 * <p>Keys found in this dictionary include:
 * </p>
 * <deflist>
 *   <term>GSThemeDomain</term>
 *   <desc>A dictionary whose key/value pairs are used to set up new values
 *   in the GSThemeDomain domain of the user defaults system, and hence
 *   define values for these unless overridden by values set explicitly by
 *   the user.
 *   </desc>
 *   <term>GSThemeTiles</term>
 *   <desc>A dictionary keyed on tile names and containing the following:
 *     <deflist>
 *       <term>FileName</term>
 *       <desc>Name of the file (within the GSThemeTiles directory in the
 *       bundle) in which the image for this tile is tored.
 *       </desc>
 *       <term>HorizontalDivision</term>
 *       <desc>The offet along the X-axis used to divide the image into
 *       columns of tiles.
 *       </desc>
 *       <term>VerticalDivision</term>
 *       <desc>The offet along the Y-axis used to divide the image into
 *       rows of tiles.
 *       </desc>
 *     </deflist>
 *   </desc>
 * </deflist>
 */
- (NSDictionary*) infoDictionary;

/**
 * Return the theme's name.
 */
- (NSString*) name;

/** Returns the name used to locate theming resources for a particular gui
 * element.  If no name has been set for the particular object, the name
 * for the class of object is returned.
 */
- (NSString*) nameForElement: (id)anObject;

/** Set the name of this theme ... used for testing by Thematic.app
 */
- (void) setName: (NSString*)aString;

/** Set the name that is used to identify theming resources for a particular
 * control or other gui element.  The name set for a specific element will
 * override the default (the name of the class of the element), and this is
 * used so that where an element is part of a control, it can be displayed
 * differently from the same class of element used outside that control.<br />
 * Supplying a nil value for aString simply removes any name setting for
 * anObject.
 */
- (void) setName: (NSString*)aString forElement: (id)anObject;

/**
 * <p>Provides a standard inspector window used to display information about
 * the receiver.  The default implementation displays the icon, the name,
 * and the authors of the theme.
 * </p>
 * <p>The code managing this object (if any) must be prepared to have the
 * content view of the window reparented into another window for display
 * on screen.
 * </p>
 */
- (NSWindow*) themeInspector;

/**
 * Returns the tile image information for a particular image name,
 * or nil if there is no such information.<br />
 * The GUI library uses this internally to handling tiling of image
 * information to draw user interface elements.  The tile information
 * returned by this method can be passed to the
 * -fillRect:withTiles:background:fillStyle: method.<br />
 * The useCache argument controls whether the information is retrieved
 * from cache or regenerated from information in the theme bundle.
 */
- (GSDrawTiles*) tilesNamed: (NSString*)aName cache: (BOOL)useCache; 
@end

/**
 * Theme drawing methods
 */
@interface	GSTheme (Drawing)

/**
 * Draws a button frame and background (not its content) for the specified
 * cell and view.
 */
- (void) drawButton: (NSRect)frame
	         in: (NSCell*)cell
	       view: (NSView*)view
	      style: (int)style
	      state: (GSThemeControlState)state;

/**
 * Amount by which the button is inset by the border.
 */
- (NSSize) buttonBorderForStyle: (int)style 
                          state: (GSThemeControlState)state;

/** 
 * Draws the indicator (normally a dotted rectangle) to show that
 * the view currently has keyboard focus.
 */
- (void) drawFocusFrame: (NSRect)frame view: (NSView*)view;

/**
 * Draws the background of a window ... normally a simple fill with the
 * the window's background color.
 */
- (void) drawWindowBackground: (NSRect)frame view: (NSView*)view;

/**
 * Draw a border of the specified border type.
 */
- (void) drawBorderType: (NSBorderType)aType 
                  frame: (NSRect)frame 
                   view: (NSView*)view;

/**
 * Determine the size for the specified border type .
 */
- (NSSize) sizeForBorderType: (NSBorderType)aType;

/**
 * Draw a border of the specified frame style.
 */
- (void) drawBorderForImageFrameStyle: (NSImageFrameStyle)frameStyle
                                frame: (NSRect)frame 
                                 view: (NSView*)view;

/**
 * Determine the size for the specified frame style.
 */
- (NSSize) sizeForImageFrameStyle: (NSImageFrameStyle)frameStyle;


/** Methods for scroller theming.
 */
- (NSButtonCell*) cellForScrollerArrow: (NSScrollerArrow)part
			    horizontal: (BOOL)horizontal;
- (NSCell*) cellForScrollerKnob: (BOOL)horizontal;
- (NSCell*) cellForScrollerKnobSlot: (BOOL)horizontal;
- (float) defaultScrollerWidth;
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
 * Method to tile the supplied image to fill the horizontal rectangle.<br />
 * The rect argument is the rectangle to be filled.<br />
 * The image argument is the data to fill with.<br />
 * The source argument is the rectangle within the image which is used.<br />
 * The flipped argument specifies what sort of coordinate system is in
 * use in the view where we are drawing.
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
 * Method to tile a rectangle given a group of up to nine tile images.<br />
 * The GSDrawTiles object encapsulates the tile images and information
 * about what parts of each image are used for tiling.<br />
 * This draws the left, right, top and bottom borders by tiling the
 * images at left, right, top and bottom.  It then draws the four corner
 * images and finally deals with the remaining space in the middle according
 * to the specified style.<br />
 * The background color specified is used to fill the center where
 * style is FillStyleNone.<br />
 * The return value is the central rectangle (inside the border images).
 */
- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
	 background: (NSColor*)color
	  fillStyle: (GSThemeFillStyle)style;

/**
 * Method to tile the supplied image to fill the vertical rectangle.<br />
 * The rect argument is the rectangle to be filled.<br />
 * The image argument is the data to fill with.<br />
 * The source argument is the rectangle within the image which is used.<br />
 * The flipped argument specifies what sort of coordinate system is in
 * use in the view where we are drawing.
 */
- (void) fillVerticalRect: (NSRect)rect
		withImage: (NSImage*)image
		 fromRect: (NSRect)source
		  flipped: (BOOL)flipped;
@end

#endif /* OS_API_VERSION */
#endif /* _GNUstep_H_GSTheme */
