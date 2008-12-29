/** <title>GSThemePrivate</title>

   <abstract>Private utilities for GSTheme</abstract>

   Copyright (C) 2007,2008 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date:  2007,2008
   
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
*/

#import	"AppKit/NSPanel.h"
#import "GNUstepGUI/GSTheme.h"

@class	NSImage, NSMatrix, NSScrollView, NSView;

/** These are the nine types of tile used to draw a rectangular object.
 */
typedef enum {
  TileTL = 0,	/** Top left corner */
  TileTM = 1,	/** Top middle section */
  TileTR = 2,	/** Top right corner */
  TileCL = 3,	/** Centerj left corner */
  TileCM = 4,	/** Centerj middle section */
  TileCR = 5,	/** Centerj right corner */
  TileBL = 6,	/** Bottom left corner */
  TileBM = 7,	/** Bottom middle section */
  TileBR = 8	/** Bottom right corner */
} GSThemeTileOffset;

/** This is a trivial class to hold the nine tiles needed to draw a rectangle
 */
@interface	GSDrawTiles : NSObject
{
@public
  NSImage	*images[9];	/** The tile images */
  NSRect	rects[9];	/** The rectangles to use when drawing */
}
- (id) copyWithZone: (NSZone*)zone;

/* Initialise with a single image assuming division into nine equally
 * sized sections.
 */
- (id) initWithImage: (NSImage*)image;

/* Initialise with a single image divided x pixels in from either end on
 * the horizontal, and y pixels in from either end on the vertical.
 */
- (id) initWithImage: (NSImage*)image horizontal: (float)x vertical: (float)y;

/* Scale the images up by the specified factor.
 */
- (void) scaleUp: (int)multiple;
@end

/** This is the panel used to select and inspect themes.
 */
@interface	GSThemePanel : NSPanel
{
  NSMatrix	*matrix;	// Not retained.
  NSScrollView	*sideView;	// Not retained.
  NSView	*bottomView;	// Not retained.
}

/** Return the shared panel.
 */
+ (GSThemePanel*) sharedThemePanel;

/** Update current theme to the one clicked on in the matrix.
 */
- (void) changeSelection: (id)sender;

/** Handle notifications
 */
- (void) notified: (NSNotification*)n;

/** Toggle whether the current theme is the default theme.
 */
- (void) setDefault: (id)sender;

/** Update list of available themes.
 */
- (void) update: (id)sender;

@end



/** This is the window used to inspect themes.
 */
@interface	GSThemeInspector : NSWindow
{
}

/** Return the shared panel.
 */
+ (GSThemeInspector*) sharedThemeInspector;

/** Update to show current theme.
 */
- (void) update: (id)sender;

@end



/** This category defines private methods for internal use by GSTheme
 */
@interface	GSTheme (internal)
/**
 * Called whenever user defaults are changed ... this checks for the
 * GSTheme user default and ensures that the specified theme is the
 * current active theme.
 */
+ (void) defaultsDidChange: (NSNotification*)n;

/**
 * Called to load specified theme.<br />
 * If aName is nil or an empty string or 'GNUstep',
 * this returns the default theme.<br />
 * If the named is a full path specification, this uses that path.<br />
 * Otherwise this method searches the standard locations.<br />
 * Returns nil on failure.
 */
+ (GSTheme*) loadThemeNamed: (NSString*)aName;

// These two drawing method may be made public later on
- (void) drawCircularBezel: (NSRect)cellFrame
		 withColor: (NSColor*)backgroundColor;
- (void) drawRoundBezel: (NSRect)cellFrame
	      withColor: (NSColor*)backgroundColor;
@end

