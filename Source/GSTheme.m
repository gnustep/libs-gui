/** <title>GSTheme</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
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
*/

#include "Foundation/NSBundle.h"
#include "Foundation/NSDictionary.h"
#include "Foundation/NSFileManager.h"
#include "Foundation/NSNotification.h"
#include "Foundation/NSNull.h"
#include "Foundation/NSPathUtilities.h"
#include "Foundation/NSSet.h"
#include "Foundation/NSUserDefaults.h"
#include "GNUstepGUI/GSTheme.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSColorList.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSImageView.h"
#include "AppKit/NSMatrix.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSTextField.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/PSOperators.h"

#include <math.h>
#include <float.h>


NSString	*GSThemeDidActivateNotification
  = @"GSThemeDidActivateNotification";
NSString	*GSThemeDidDeactivateNotification
  = @"GSThemeDidDeactivateNotification";

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
- (id) initWithImage: (NSImage*)image;
- (id) initWithImage: (NSImage*)image horizontal: (float)x vertical: (float)y;
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
- (void) drawCircularBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor;
- (void) drawRoundBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor;
@end



@implementation GSTheme

static GSTheme			*defaultTheme = nil;
static NSString			*currentThemeName = nil;
static GSTheme			*theTheme = nil;
static NSMutableDictionary	*themes = nil;
static NSNull			*null = nil;

+ (void) defaultsDidChange: (NSNotification*)n
{
  NSUserDefaults	*defs;
  NSString		*name;

  defs = [NSUserDefaults standardUserDefaults];
  name = [defs stringForKey: @"GSTheme"];
  if (name != currentThemeName && [name isEqual: currentThemeName] == NO)
    {
      [self setTheme: [self loadThemeNamed: name]];
      ASSIGN(currentThemeName, name);	// Don't try to load again.
    }
}

+ (void) initialize
{
  if (themes == nil)
    {
      themes = [NSMutableDictionary new];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(defaultsDidChange:)
	name: NSUserDefaultsDidChangeNotification
	object: nil];
    }
  if (null == nil)
    {
      null = RETAIN([NSNull null]);
    }
  if (defaultTheme == nil)
    {
      NSBundle		*aBundle = [NSBundle bundleForClass: self];

      defaultTheme = [[self alloc] initWithBundle: aBundle];
      ASSIGN(theTheme, defaultTheme);
    }
  /* Establish the theme specified by the user defaults (if any);
   */
  [self defaultsDidChange: nil];
}

+ (GSTheme*) loadThemeNamed: (NSString*)aName
{
  NSBundle	*bundle;
  Class		cls;
  GSTheme	*instance;
  NSString	*theme;

  if ([aName length] == 0)
    {
      return defaultTheme;
    }

  if ([aName isAbsolutePath] == YES)
    {
      theme = aName;
    }
  else
    {
      aName = [aName lastPathComponent];

      /* Ensure that the theme name has the 'theme' extension.
       */
      if ([[aName pathExtension] isEqualToString: @"theme"] == YES)
	{
	  theme = aName;
	}
      else
	{
	  theme = [aName stringByAppendingPathExtension: @"theme"];
	}
      if ([theme isEqualToString: @"GNUstep.theme"] == YES)
	{
	  return defaultTheme;
	}
    }

  bundle = [themes objectForKey: theme];
  if (bundle == nil)
    {
      NSString		*path;
      NSFileManager	*mgr = [NSFileManager defaultManager];
      BOOL 		isDir;

      /* A theme may be either an absolute path or a filename to be located
       * in the Themes subdirectory of one of the standard Library directories.
       */
      if ([theme isAbsolutePath] == YES)
        {
	  if ([mgr fileExistsAtPath: theme isDirectory: &isDir] == YES
	    && isDir == YES)
	    {
	      path = theme;
	    }
	}
      else
        {
	  NSEnumerator	*enumerator;

	  enumerator = [NSSearchPathForDirectoriesInDomains
	    (NSAllLibrariesDirectory, NSAllDomainsMask, YES) objectEnumerator];
	  while ((path = [enumerator nextObject]) != nil)
	    {
	      path = [path stringByAppendingPathComponent: @"Themes"];
	      path = [path stringByAppendingPathComponent: theme];
	      if ([mgr fileExistsAtPath: path isDirectory: &isDir])
		{
		  break;
		}
	    }
	}

      if (path == nil)
	{
	  NSLog (@"No theme named '%@' found", aName);
	  return nil;
	}
      else
        {
	  bundle = [NSBundle bundleWithPath: path];
	  [themes setObject: bundle forKey: theme];
	  [bundle load];	// Ensure code is loaded.
	}
    }

  cls = [bundle principalClass];
  if (cls == 0)
    {
      cls = self;
    }
  instance = [[cls alloc] initWithBundle: bundle];
  return AUTORELEASE(instance);
}

+ (void) orderFrontSharedThemePanel: (id)sender
{
  GSThemePanel *panel;

  panel = [GSThemePanel sharedThemePanel];
  [panel update: self];
  [panel center];
  [panel orderFront: self];
}

+ (void) setTheme: (GSTheme*)theme
{
  if (theme == nil)
    {
      theme = defaultTheme;
    }
  if (theme != theTheme)
    {
      [theTheme deactivate];
      ASSIGN (theTheme, theme);
      [theTheme activate];
    }
  ASSIGN(currentThemeName, [theTheme name]);
}

+ (GSTheme*) theme 
{
  return theTheme;
}

- (void) activate
{
  NSUserDefaults	*defs;
  NSMutableDictionary	*userInfo;
  NSMutableArray	*searchList;
  NSArray		*imagePaths;
  NSEnumerator		*enumerator;
  NSString		*imagePath;
  NSArray		*imageTypes;
  NSString		*colorsPath;
  NSDictionary		*infoDict;
  NSWindow		*window;

  userInfo = [NSMutableDictionary dictionary];
  colorsPath = [_bundle pathForResource: @"ThemeColors" ofType: @"clr"]; 
  if (colorsPath != nil)
    {
      NSColorList	*list = nil;

      list = [[NSColorList alloc] initWithName: @"System"
				      fromFile: colorsPath];
      if (list != nil)
	{
	  [userInfo setObject: list forKey: @"Colors"];
	  RELEASE(list);
	}
    }

  /*
   * We step through all the bundle image resources and load them in
   * to memory, setting their names so that they are visible to
   * [NSImage+imageNamed:] and storing them in our local array.
   */
  imageTypes = [NSImage imageFileTypes];
  imagePaths = [_bundle pathsForResourcesOfType: nil
				    inDirectory: @"ThemeImages"];
  enumerator = [imagePaths objectEnumerator];
  while ((imagePath = [enumerator nextObject]) != nil)
    {
      NSString	*ext = [imagePath pathExtension];

      if (ext != nil && [imageTypes containsObject: ext] == YES)
        {
	  NSImage	*image;
	  NSString	*imageName;

	  imageName = [imagePath lastPathComponent];
	  imageName = [imageName stringByDeletingPathExtension];

	  image = [_images objectForKey: imageName];
	  if (image == nil)
	    {
	      image = [[NSImage alloc] initWithContentsOfFile: imagePath];
	      if (image != nil)
		{
		  [_images setObject: image forKey: imageName];
		  RELEASE(image);
		}
	    }

	  /* We try to ensure that our new image can be found by name.
	   */
	  if (image != nil && [[image name] isEqualToString: imageName] == NO)
	    {
	      if ([image setName: imageName] == NO)
	        {
		  NSImage	*old;

		  /* Couldn't set image name ... presumably already
		   * in use ... so we remove the name from the old
		   * image and try again.
		   */
		  old = [NSImage imageNamed: imageName];
		  [old setName: nil];
	          [image setName: imageName];
		}
	    }
	}
    }

  /*
   * We could cache tile info here, but it's probably better for the
   * tilesNamed:cache: method to do it lazily.
   */

  /*
   * Use the GSThemeDomain key in the info dictionary of the theme to
   * set a defaults domain which will establish user defaults values
   * but will not override any defaults set explicitly by the user.
   * NB. For subclasses, the theme info dictionary may not be the same
   * as that of the bundle, so we don't use the bundle method directly.
   */
  infoDict = [self infoDictionary];
  defs = [NSUserDefaults standardUserDefaults];
  searchList = [[defs searchList] mutableCopy];
  if ([[infoDict objectForKey: @"GSThemeDomain"] isKindOfClass:
    [NSDictionary class]] == YES)
    {
      [defs removeVolatileDomainForName: @"GSThemeDomain"];
      [defs setVolatileDomain: [infoDict objectForKey: @"GSThemeDomain"]
		      forName: @"GSThemeDomain"];
      if ([searchList containsObject: @"GSThemeDomain"] == NO)
	{
	  unsigned	index;

	  /*
	   * Higher priority than GSConfigDomain and NSRegistrationDomain,
	   * but lower than NSGlobalDomain, NSArgumentDomain, and others
	   * set by the user to be application specific.
	   */
	  index = [searchList indexOfObject: GSConfigDomain];
	  if (index == NSNotFound)
	    {
	      index = [searchList indexOfObject: NSRegistrationDomain];
	      if (index == NSNotFound)
	        {
		  index = [searchList count];
		}
	    }
	  [searchList insertObject: @"GSThemeDomain" atIndex: index];
	  [defs setSearchList: searchList];
	}
    }
  else
    {
      [searchList removeObject: @"GSThemeDomain"];
      [defs removeVolatileDomainForName: @"GSThemeDomain"];
    }
  RELEASE(searchList);

  /*
   * Tell all other classes that new theme information is present.
   */
  [[NSNotificationCenter defaultCenter]
   postNotificationName: GSThemeDidActivateNotification
   object: self
   userInfo: userInfo];

  /*
   * Reset main menu to change between styles if necessary
   */
  [[NSApp mainMenu] setMain: YES];

  /*
   * Mark all windows as needing redisplaying to thos the new theme.
   */
  enumerator = [[NSApp windows] objectEnumerator];
  while ((window = [enumerator nextObject]) != nil)
    {
      [[[window contentView] superview] setNeedsDisplay: YES];
    }
}

- (NSArray*) authors
{
  return [[self infoDictionary] objectForKey: @"GSThemeAuthors"];
}

- (NSBundle*) bundle
{
  return _bundle;
}

- (void) deactivate
{
  NSEnumerator	*enumerator;
  NSImage	*image;

  /*
   * Remove all cached bundle images from both NSImage's name dictionary
   * and our cache dictionary, so that we can be sure we reload afresh
   * when re-activated (in case the images on disk changed ... eg by a
   * theme editor modifying the theme).
   */
  enumerator = [_images objectEnumerator];
  while ((image = [enumerator nextObject]) != nil)
    {
      [image setName: nil];
    }
  [_images removeAllObjects];

  /* Tell everything that we have become inactive.
   */
  [[NSNotificationCenter defaultCenter]
   postNotificationName: GSThemeDidDeactivateNotification
   object: self
   userInfo: nil];
}

- (void) dealloc
{
  RELEASE(_bundle);
  RELEASE(_images);
  RELEASE(_tiles);
  RELEASE(_icon);
  [super dealloc];
}

- (NSImage*) icon
{
  if (_icon == nil)
    {
      NSString	*path;

      path = [[self infoDictionary] objectForKey: @"GSThemeIcon"];
      if (path != nil)
        {
	  NSString	*ext = [path pathExtension];

	  path = [path stringByDeletingPathExtension];
	  path = [_bundle pathForResource: path ofType: ext];
	  if (path != nil)
	    {
	      _icon = [[NSImage alloc] initWithContentsOfFile: path];
	    }
	}
      if (_icon == nil)
        {
	  _icon = RETAIN([NSImage imageNamed: @"GNUstep"]);
	}
    }
  return _icon;
}

- (id) initWithBundle: (NSBundle*)bundle
{
  ASSIGN(_bundle, bundle);
  _images = [NSMutableDictionary new];
  _tiles = [NSMutableDictionary new];
  return self;
}

- (NSDictionary*) infoDictionary
{
  return [_bundle infoDictionary];
}

- (NSString*) name
{
  if (self == defaultTheme)
    {
      return @"GNUstep";
    }
  return
    [[[_bundle bundlePath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSWindow*) themeInspector
{
  return [GSThemeInspector sharedThemeInspector];
}

- (GSDrawTiles*) tilesNamed: (NSString*)aName cache: (BOOL)useCache
{
  GSDrawTiles	*tiles;

  tiles = (useCache == YES) ? [_tiles objectForKey: aName] : nil;
  if (tiles == nil)
    {
      NSDictionary	*info;
      NSImage		*image;

      /* The GSThemeTiles entry in the info dictionary should be a
       * dictionary containing information about each set of tiles.
       * Keys are:
       * FileName		Name of the file in the ThemeTiles directory
       * HorizontalDivision	Where to divide the image into columns.
       * VerticalDivision	Where to divide the image into rows.
       */
      info = [self infoDictionary];
      info = [[info objectForKey: @"GSThemeTiles"] objectForKey: aName];
      if ([info isKindOfClass: [NSDictionary class]] == YES)
        {
	  float		x;
	  float		y;
	  NSString	*path;
	  NSString	*file;
	  NSString	*ext;

	  x = [[info objectForKey: @"HorizontalDivision"] floatValue];
	  y = [[info objectForKey: @"VerticalDivision"] floatValue];
	  file = [info objectForKey: @"FileName"];
	  ext = [file pathExtension];
	  file = [file stringByDeletingPathExtension];
	  path = [_bundle pathForResource: file
				   ofType: ext
			      inDirectory: @"ThemeTiles"];
	  if (path == nil)
	    {
	      NSLog(@"File %@.%@ not found in ThemeTiles", file, ext);
	    }
	  else
	    {
	      image = [[NSImage alloc] initWithContentsOfFile: path];
	      if (image != nil)
		{
		  tiles = [[GSDrawTiles alloc] initWithImage: image
						  horizontal: x
						    vertical: y];
		  RELEASE(image);
		}
	    }
	}
      else
        {
	  NSArray	*imageTypes;
	  NSString	*imagePath;
	  unsigned	count;

	  imageTypes = [NSImage imageFileTypes];
	  for (count = 0; count < [imageTypes count]; count++)
	    {
	      NSString	*ext = [imageTypes objectAtIndex: count];

	      imagePath = [_bundle pathForResource: aName
					    ofType: ext
				       inDirectory: @"ThemeTiles"];
	      if (imagePath != nil)
		{
		  image = [[NSImage alloc] initWithContentsOfFile: imagePath];
		  if (image != nil)
		    {
		      tiles = [[GSDrawTiles alloc] initWithImage: image];
		      RELEASE(image);
		      break;
		    }
		}
	    }
	}

      if (tiles == nil)
        {
	  [_tiles setObject: null forKey: aName];
	}
      else
        {
	  [_tiles setObject: tiles forKey: aName];
	  RELEASE(tiles);
	}
    }
  if (tiles == (id)null)
    {
      tiles = nil;
    }
  return tiles;
}

@end


@implementation	GSTheme (Drawing)

- (void) drawButton: (NSRect)frame 
                 in: (NSCell*)cell 
               view: (NSView*)view 
              style: (int)style 
              state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;
  NSColor	*color = nil;

  if (state == GSThemeNormalState)
    {
      tiles = [self tilesNamed: @"NSButtonNormal" cache: YES];
      color = [NSColor controlBackgroundColor];
    }
  else if (state == GSThemeHighlightedState)
    {
      tiles = [self tilesNamed: @"NSButtonHighlighted" cache: YES];
      color = [NSColor selectedControlColor];
    }
  else if (state == GSThemeSelectedState)
    {
      tiles = [self tilesNamed: @"NSButtonPushed" cache: YES];
      color = [NSColor selectedControlColor];
    }

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundBezelStyle:
	  case NSRoundedBezelStyle:
	    [self drawRoundBezel: frame withColor: color];
	    break;
	  case NSTexturedSquareBezelStyle:
	    frame = NSInsetRect(frame, 0, 1);
	  case NSSmallSquareBezelStyle:
	  case NSRegularSquareBezelStyle:
	  case NSShadowlessSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 1);
	    break;
	  case NSThickSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 1.5);
	    break;
	  case NSThickerSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 2);
	    break;
	  case NSCircularBezelStyle:
	    frame = NSInsetRect(frame, 3, 3);
	  case NSHelpButtonBezelStyle:
	    [self drawCircularBezel: frame withColor: color]; 
	    break;
	  case NSDisclosureBezelStyle:
	  case NSRoundedDisclosureBezelStyle:
	  case NSRecessedBezelStyle:
	    // FIXME
	    break;
	  default:
	    [color set];
	    NSRectFill(frame);

	    if (state == GSThemeNormalState || state == GSThemeHighlightedState)
	      {
		[self drawButton: frame withClip: NSZeroRect];
	      }
	    else if (state == GSThemeSelectedState)
	      {
		[self drawGrayBezel: frame withClip: NSZeroRect];
	      }
	}
    }
  else
    {
      /* Use tiles to draw button border with central part filled with color
       */
      [self fillRect: frame
	   withTiles: tiles
	  background: color
	   fillStyle: GSThemeFillStyleNone];
    }
}

- (NSSize) buttonBorderForStyle: (int)style 
			  state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;

  if (state == GSThemeNormalState)
    {
      tiles = [self tilesNamed: @"NSButtonNormal" cache: YES];
    }
  else if (state == GSThemeHighlightedState)
    {
      tiles = [self tilesNamed: @"NSButtonHighlighted" cache: YES];
    }
  else if (state == GSThemeSelectedState)
    {
      tiles = [self tilesNamed: @"NSButtonPushed" cache: YES];
    }

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundBezelStyle:
	  case NSRoundedBezelStyle:
	    return NSMakeSize(5, 5);
	  case NSTexturedSquareBezelStyle:
	    return NSMakeSize(3, 3);
	  case NSSmallSquareBezelStyle:
	  case NSRegularSquareBezelStyle:
	  case NSShadowlessSquareBezelStyle:
	    return NSMakeSize(2, 2);
	  case NSThickSquareBezelStyle:
	    return NSMakeSize(3, 3);
	  case NSThickerSquareBezelStyle:
	    return NSMakeSize(4, 4);
	  case NSCircularBezelStyle:
	    return NSMakeSize(5, 5);
	  case NSHelpButtonBezelStyle:
	    return NSMakeSize(2, 2);
	  case NSDisclosureBezelStyle:
	  case NSRoundedDisclosureBezelStyle:
	  case NSRecessedBezelStyle:
	    // FIXME
	    return NSMakeSize(0, 0);
	  default:
	    return NSMakeSize(3, 3);
	}
    }
  else
    {
      NSSize cls = tiles->rects[TileCL].size;
      NSSize bms = tiles->rects[TileBM].size;

      return NSMakeSize(cls.width, bms.height);
    }
}

- (void) drawFocusFrame: (NSRect) frame view: (NSView*) view
{
  NSDottedFrameRect(frame);
}

- (void) drawWindowBackground: (NSRect) frame view: (NSView*) view
{
  NSColor *c;

  c = [[view window] backgroundColor];
  [c set];
  NSRectFill (frame);
}

- (void) drawBorderType: (NSBorderType)aType 
                  frame: (NSRect)frame 
                   view: (NSView*)view
{
  switch (aType)
    {
      case NSLineBorder:
        [[NSColor controlDarkShadowColor] set];
        NSFrameRect(frame);
        break;
      case NSGrooveBorder:
        [self drawGroove: frame withClip: NSZeroRect];
        break;
      case NSBezelBorder:
        [self drawWhiteBezel: frame withClip: NSZeroRect];
        break;
      case NSNoBorder: 
      default:
        break;
    }
}

- (NSSize) sizeForBorderType: (NSBorderType)aType
{
  // Returns the size of a border
  switch (aType)
    {
      case NSLineBorder:
        return NSMakeSize(1, 1);
      case NSGrooveBorder:
      case NSBezelBorder:
        return NSMakeSize(2, 2);
      case NSNoBorder: 
      default:
        return NSZeroSize;
    }
}

- (void) drawBorderForImageFrameStyle: (NSImageFrameStyle)frameStyle
                                frame: (NSRect)frame 
                                 view: (NSView*)view
{
  switch (frameStyle)
    {
      case NSImageFrameNone:
        // do nothing
        break;
      case NSImageFramePhoto:
        [self drawFramePhoto: frame withClip: NSZeroRect];
        break;
      case NSImageFrameGrayBezel:
        [self drawGrayBezel: frame withClip: NSZeroRect];
        break;
      case NSImageFrameGroove:
        [self drawGroove: frame withClip: NSZeroRect];
        break;
      case NSImageFrameButton:
        [self drawButton: frame withClip: NSZeroRect];
        break;
    }
}

- (NSSize) sizeForImageFrameStyle: (NSImageFrameStyle)frameStyle
{
  // Get border size
  switch (frameStyle)
    {
      case NSImageFrameNone:
      default:
        return NSZeroSize;
      case NSImageFramePhoto:
        // FIXME
        return NSMakeSize(2, 2);
      case NSImageFrameGrayBezel:
      case NSImageFrameGroove:
      case NSImageFrameButton:
        return NSMakeSize(2, 2);
    }
}

@end



@implementation	GSTheme (MidLevelDrawing)

- (NSRect) drawButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {black, black, white, white, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

- (NSRect) drawDarkBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			   NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark, black, black, light, light};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
  
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
  
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawDarkButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge}; 
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge}; 
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *white = [NSColor controlHighlightColor];
  NSColor *colors[] = {black, black, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

- (NSRect) drawFramePhoto: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *colors[] = {dark, dark, dark, dark, 
		       black,black};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

#if 0
- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
                       inRect: (NSRect)border 
                     withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge};
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor **colors;
  NSColor *concaveWeak[] = {dark, dark, light, light};
  NSColor *concaveStrong[] = {black, black, light, light};
  NSColor *convexWeak[] = {light, light, dark, dark};
  NSColor *convexStrong[] = {light, light, black, black};
  NSRect rect;
  
  switch (gradientType)
    {
      case NSGradientConcaveWeak:
	colors = concaveWeak;
	break;
      case NSGradientConcaveStrong:
	colors = concaveStrong;
	break;
      case NSGradientConvexWeak:
	colors = convexWeak;
	break;
      case NSGradientConvexStrong:
	colors = convexStrong;
	break;
      case NSGradientNone:
      default:
	return border;
    }

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
 
  return rect;
}

#else
// FIXME: I think this method is wrong.
- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
                       inRect: (NSRect)cellFrame 
                     withClip: (NSRect)clip
{
  float   start_white = 0.0;
  float   end_white = 0.0;
  float   white = 0.0;
  float   white_step = 0.0;
  float   h, s, v, a;
  NSPoint p1, p2;
  NSColor *gray = nil;
  NSColor *darkGray = nil;
  NSColor *lightGray = nil;

  lightGray = [NSColor colorWithDeviceRed: NSLightGray 
                       green: NSLightGray 
                       blue: NSLightGray 
                       alpha:1.0];
  gray = [NSColor colorWithDeviceRed: NSGray 
                  green: NSGray 
                  blue: NSGray 
                  alpha:1.0];
  darkGray = [NSColor colorWithDeviceRed: NSDarkGray 
                      green: NSDarkGray 
                      blue: NSDarkGray 
                      alpha:1.0];

  switch (gradientType)
    {
      case NSGradientNone:
        return NSZeroRect;
        break;

      case NSGradientConcaveWeak:
        [gray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [gray brightnessComponent];
        break;
        
      case NSGradientConvexWeak:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [gray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;
        
      case NSGradientConcaveStrong:
        [lightGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [darkGray brightnessComponent];
        break;
        
      case NSGradientConvexStrong:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [darkGray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;

      default:
        break;
    }

  white = start_white;
  white_step = fabs(start_white - end_white)
    / (cellFrame.size.width + cellFrame.size.height);

  // Start from top left
  p1 = NSMakePoint(cellFrame.origin.x,
    cellFrame.size.height + cellFrame.origin.y);
  p2 = NSMakePoint(cellFrame.origin.x, 
    cellFrame.size.height + cellFrame.origin.y);

  // Move by Y
  while (p1.y > cellFrame.origin.y)
    {
      [[NSColor 
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
      
      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.y -= 1.0;
      if (p2.x < (cellFrame.size.width + cellFrame.origin.x))
        p2.x += 1.0;
      else
        p2.y -= 1.0;
    }
      
  // Move by X
  while (p1.x < (cellFrame.size.width + cellFrame.origin.x))
    {
      [[NSColor 
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
      
      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.x += 1.0;
      if (p2.x >= (cellFrame.size.width + cellFrame.origin.x))
        p2.y -= 1.0;
      else
        p2.x += 1.0;
    }

  return NSZeroRect;
}

#endif

- (NSRect) drawGrayBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			     NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, black, black};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMaxY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMinY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawGroove: (NSRect)border withClip: (NSRect)clip
{
  // go clockwise from the top twice -- makes the groove come out right
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
			   NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       white, dark, dark, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawLightBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge, 
  			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawWhiteBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
  			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, 
  			     NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       dark, light, light, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (void) drawRoundBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor
{
  NSBezierPath *p = [NSBezierPath bezierPath];
  NSPoint point;
  float radius;

  // make smaller than enclosing frame
  cellFrame = NSInsetRect(cellFrame, 4, floor(cellFrame.size.height * 0.1875));
  radius = cellFrame.size.height / 2.0;
  point = cellFrame.origin;
  point.x += radius;
  point.y += radius;
  // left half-circle
  [p appendBezierPathWithArcWithCenter: point radius: radius startAngle: 90.0 endAngle: 270.0];

  // line to first point and right halfcircle
  point.x += cellFrame.size.width - cellFrame.size.height;
  [p appendBezierPathWithArcWithCenter: point radius: radius startAngle: 270.0 endAngle: 90.0];
  [p closePath];

  // fill with background color
  [backgroundColor set];
  [p fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [p stroke];
}

- (void) drawCircularBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor
{
  // make smaller so that it does not touch frame
  NSBezierPath *oval = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(cellFrame, 1, 1)];

  // fill oval with background color
  [backgroundColor set];
  [oval fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [oval stroke];
}

@end



@implementation	GSTheme (LowLevelDrawing)

- (void) fillHorizontalRect: (NSRect)rect
		  withImage: (NSImage*)image
		   fromRect: (NSRect)source
		    flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSBezierPath		*path;
  unsigned		repetitions;
  unsigned		count;
  float			y;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = (rect.size.width / source.size.width) + 1;
  y = rect.origin.y;

  if (flipped) y = rect.origin.y + rect.size.height;
  
  for (count = 0; count < repetitions; count++)
    {
      NSPoint p = NSMakePoint (rect.origin.x + count * source.size.width, y);

      [image compositeToPoint: p
		     fromRect: source
		    operation: NSCompositeSourceOver];
    }
  DPSgrestore (ctxt);	
}

- (void) fillRect: (NSRect)rect
withRepeatedImage: (NSImage*)image
	 fromRect: (NSRect)source
	   center: (BOOL)center
{
  NSGraphicsContext	*ctxt = GSCurrentContext ();
  NSBezierPath		*path;
  NSSize		size;
  unsigned		xrepetitions;
  unsigned		yrepetitions;
  unsigned		x;
  unsigned		y;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  size = [image size];
  xrepetitions = (rect.size.width / size.width) + 1;
  yrepetitions = (rect.size.height / size.height) + 1;

  for (x = 0; x < xrepetitions; x++)
    {
      for (y = 0; y < yrepetitions; y++)
	{
	  NSPoint p;

	  p = NSMakePoint (rect.origin.x + x * size.width,
	    rect.origin.y + y * size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
      }
  }
  DPSgrestore (ctxt);	
}

- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
	 background: (NSColor*)color
	  fillStyle: (GSThemeFillStyle)style
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSSize		tls = tiles->rects[TileTL].size;
  NSSize		tms = tiles->rects[TileTM].size;
  NSSize		trs = tiles->rects[TileTR].size;
  NSSize		cls = tiles->rects[TileCL].size;
  NSSize		crs = tiles->rects[TileCR].size;
  NSSize		bls = tiles->rects[TileBL].size;
  NSSize		bms = tiles->rects[TileBM].size;
  NSSize		brs = tiles->rects[TileBR].size;
  NSRect		inFill;
  BOOL			flipped = [[ctxt focusView] isFlipped];

  if (color == nil)
    {
      [[NSColor redColor] set];
    }
  else
    {
      [color set];
    }
  NSRectFill(rect);

  if (style == GSThemeFillStyleMatrix)
    {
      NSRect	grid;
      float	x;
      float	y;
      float	space = 3.0;
      float	scale;

      inFill = NSZeroRect;
      if (tiles->images[TileTM] == nil)
        {
	  grid.size.width = (tiles->rects[TileTL].size.width
	    + tiles->rects[TileTR].size.width
	    + space * 3.0);
	}
      else
        {
	  grid.size.width = (tiles->rects[TileTL].size.width
	    + tiles->rects[TileTM].size.width
	    + tiles->rects[TileTR].size.width
	    + space * 4.0);
	}
      scale = floor(rect.size.width / grid.size.width);

      if (tiles->images[TileCL] == nil)
        {
	  grid.size.height = (tiles->rects[TileTL].size.height
	    + tiles->rects[TileBL].size.height
	    + space * 3.0);
	}
      else
        {
	  grid.size.height = (tiles->rects[TileTL].size.height
	    + tiles->rects[TileCL].size.height
	    + tiles->rects[TileBL].size.height
	    + space * 4.0);
	}
      if ((rect.size.height / grid.size.height) < scale)
        {
	  scale = floor(rect.size.height / grid.size.height);
	}

      if (scale > 1)
        {
	  /* We can scale up by an integer number of pixels and still
	   * fit in the rectangle.
	   */
	  grid.size.width *= scale;
	  grid.size.height *= scale;
	  space *= scale;
	  tiles = AUTORELEASE([tiles copy]);
	  [tiles scaleUp: (int)scale];
	}

      grid.origin.x = rect.origin.x + (rect.size.width - grid.size.width) / 2;
      x = grid.origin.x;
      if (flipped)
        {
	  grid.origin.y
	    = NSMaxY(rect) - (rect.size.height - grid.size.height) / 2;
	  y = NSMaxY(grid);
	}
      else
        {
	  grid.origin.y
	    = rect.origin.y + (rect.size.height - grid.size.height) / 2;
	  y = grid.origin.y;
	}

      /* Draw bottom row
       */
      if (flipped)
        {
          y -= (tiles->rects[TileBL].size.height + space);
	}
      else
        {
	  y += space;
	}
      [tiles->images[TileBL] compositeToPoint: NSMakePoint(x, y)
        fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      x += tiles->rects[TileBL].size.width + space;
      if (tiles->images[TileBM] != nil)
        {
	  [tiles->images[TileBM] compositeToPoint: NSMakePoint(x, y)
            fromRect: tiles->rects[TileBM]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileBM].size.width + space;
	}
      [tiles->images[TileBR] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];
      if (!flipped)
        {
          y += tiles->rects[TileBL].size.height;
	}

      if (tiles->images[TileCL] != nil)
	{
	  /* Draw middle row
	   */
	  x = grid.origin.x;
	  if (flipped)
	    {
	      y -= (tiles->rects[TileCL].size.height + space);
	    }
	  else
	    {
	      y += space;
	    }
	  [tiles->images[TileCL] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileCL]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileCL].size.width + space;
	  if (tiles->images[TileCM] != nil)
	    {
	      [tiles->images[TileCM] compositeToPoint: NSMakePoint(x, y)
		fromRect: tiles->rects[TileCM]
		operation: NSCompositeSourceOver];
	      x += tiles->rects[TileCM].size.width + space;
	    }
	  [tiles->images[TileCR] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileCR]
	    operation: NSCompositeSourceOver];
	  if (!flipped)
	    {
	      y += tiles->rects[TileCL].size.height;
	    }
	}

      /* Draw top row
       */
      x = grid.origin.x;
      if (flipped)
	{
	  y -= (tiles->rects[TileTL].size.height + space);
	}
      else
	{
	  y += space;
	}
      [tiles->images[TileTL] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      x += tiles->rects[TileTL].size.width + space;
      if (tiles->images[TileTM] != nil)
	{
	  [tiles->images[TileTM] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileTM]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileTM].size.width + space;
	}
      [tiles->images[TileTR] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
    }
  else if (flipped)
    {
      [self fillHorizontalRect:
	NSMakeRect (rect.origin.x + bls.width,
	  rect.origin.y + rect.size.height - bms.height,
	  rect.size.width - bls.width - brs.width,
	  bms.height)
	withImage: tiles->images[TileBM]
	fromRect: tiles->rects[TileBM]
	flipped: YES];
      [self fillHorizontalRect:
	NSMakeRect (rect.origin.x + tls.width,
	  rect.origin.y,
	  rect.size.width - tls.width - trs.width,
	  tms.height)
	withImage: tiles->images[TileTM]
	fromRect: tiles->rects[TileTM]
	flipped: YES];
      [self fillVerticalRect:
	NSMakeRect (rect.origin.x,
	  rect.origin.y + bls.height,
	  cls.width,
	  rect.size.height - bls.height - tls.height)
	withImage: tiles->images[TileCL]
	fromRect: tiles->rects[TileCL]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect (rect.origin.x + rect.size.width - crs.width,
	  rect.origin.y + brs.height,
	  crs.width,
	  rect.size.height - brs.height - trs.height)
	withImage: tiles->images[TileCR]
	fromRect: tiles->rects[TileCR]
	flipped: NO];

      [tiles->images[TileTL] compositeToPoint:
	NSMakePoint (rect.origin.x,
	  rect.origin.y)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileTR] compositeToPoint:
	NSMakePoint (rect.origin.x + rect.size.width - tls.width,
	rect.origin.y)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBL] compositeToPoint:
	NSMakePoint (rect.origin.x,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBR] compositeToPoint:
	NSMakePoint (rect.origin.x + rect.size.width - brs.width,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];

      inFill = NSMakeRect (rect.origin.x + cls.width,
	rect.origin.y + bms.height,
	rect.size.width - cls.width - crs.width,
	rect.size.height - bms.height - tms.height);
      if (style == GSThemeFillStyleCenter)
	{
	  NSRect	r = tiles->rects[TileCM];

	  r.origin.x
	    = inFill.origin.x + (inFill.size.width - r.size.width) / 2;
	  r.origin.y
	    = inFill.origin.y + (inFill.size.height - r.size.height) / 2;
	  r.origin.y += r.size.height;	// Allow for flip of image rectangle
	  [tiles->images[TileCM] compositeToPoint: r.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
	}
      else if (style == GSThemeFillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: NO];
	}
      else if (style == GSThemeFillStyleScale)
	{
	  NSImage	*im = [tiles->images[TileCM] copy];
	  NSRect	r =  tiles->rects[TileCM];
	  NSSize	s = [tiles->images[TileCM] size];
	  NSPoint	p = inFill.origin;
	  float		sx = inFill.size.width / r.size.width;
	  float		sy = inFill.size.height / r.size.height;

	  r.size.width = inFill.size.width;
	  r.size.height = inFill.size.height;
	  r.origin.x *= sx;
	  r.origin.y *= sy;
	  s.width *= sx;
	  s.height *= sy;
	  p.y += inFill.size.height;	// In flipped view
	  
	  [im setScalesWhenResized: YES];
	  [im setSize: s];
	  [im compositeToPoint: p
		      fromRect: r
		     operation: NSCompositeSourceOver];
	  RELEASE(im);
	}
    }
  else
    {
      [self fillHorizontalRect:
	NSMakeRect(
	  rect.origin.x + tls.width,
	  rect.origin.y + rect.size.height - tms.height,
	  rect.size.width - bls.width - brs.width,
	  tms.height)
	withImage: tiles->images[TileTM]
	fromRect: tiles->rects[TileTM]
	flipped: NO];
      [self fillHorizontalRect:
	NSMakeRect(
	  rect.origin.x + bls.width,
	  rect.origin.y,
	  rect.size.width - bls.width - brs.width,
	  bms.height)
	withImage: tiles->images[TileBM]
	fromRect: tiles->rects[TileBM]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect(
	  rect.origin.x,
	  rect.origin.y + bls.height,
	  cls.width,
	  rect.size.height - tls.height - bls.height)
	withImage: tiles->images[TileCL]
	fromRect: tiles->rects[TileCL]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect(
	  rect.origin.x + rect.size.width - crs.width,
	  rect.origin.y + brs.height,
	  crs.width,
	  rect.size.height - trs.height - brs.height)
	withImage: tiles->images[TileCR]
	fromRect: tiles->rects[TileCR]
	flipped: NO];

      [tiles->images[TileTL] compositeToPoint:
	NSMakePoint (
	  rect.origin.x,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileTR] compositeToPoint:
	NSMakePoint(
	  rect.origin.x + rect.size.width - trs.width,
	  rect.origin.y + rect.size.height - trs.height)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBL] compositeToPoint:
	NSMakePoint(
	  rect.origin.x,
	  rect.origin.y)
	fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBR] compositeToPoint:
	NSMakePoint(
	  rect.origin.x + rect.size.width - brs.width,
	  rect.origin.y)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];

      inFill = NSMakeRect (rect.origin.x +cls.width,
	rect.origin.y + bms.height,
	rect.size.width - cls.width - crs.width,
	rect.size.height - bms.height - tms.height);

      if (style == GSThemeFillStyleCenter)
	{
	  NSRect	r = tiles->rects[TileCM];

	  r.origin.x
	    = inFill.origin.x + (inFill.size.width - r.size.width) / 2;
	  r.origin.y
	    = inFill.origin.y + (inFill.size.height - r.size.height) / 2;
	  [tiles->images[TileCM] compositeToPoint: r.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
	}
      else if (style == GSThemeFillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: YES];
	}
      else if (style == GSThemeFillStyleScale)
	{
	  NSImage	*im = [tiles->images[TileCM] copy];
	  NSRect	r =  tiles->rects[TileCM];
	  NSSize	s = [tiles->images[TileCM] size];
	  NSPoint	p = inFill.origin;
	  float		sx = inFill.size.width / r.size.width;
	  float		sy = inFill.size.height / r.size.height;

	  r.size.width = inFill.size.width;
	  r.size.height = inFill.size.height;
	  r.origin.x *= sx;
	  r.origin.y *= sy;
	  s.width *= sx;
	  s.height *= sy;
	  

	  [im setScalesWhenResized: YES];
	  [im setSize: s];
	  [im compositeToPoint: p
		      fromRect: r
		     operation: NSCompositeSourceOver];
	  RELEASE(im);
	}
    }
  return inFill;
}

- (void) fillVerticalRect: (NSRect)rect
		withImage: (NSImage*)image
		 fromRect: (NSRect)source
		  flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSBezierPath		*path;
  unsigned		repetitions;
  unsigned		count;
  NSPoint		p;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = (rect.size.height / source.size.height) + 1;

  if (flipped)
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + rect.size.height - count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  else
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  DPSgrestore (ctxt);	
}

@end



@implementation	GSDrawTiles
- (id) copyWithZone: (NSZone*)zone
{
  GSDrawTiles	*c = (GSDrawTiles*)NSCopyObject(self, 0, zone);
  unsigned	i;

  c->images[0] = [images[0] copy];
  for (i = 1; i < 9; i++)
    {
      unsigned	j;

      for (j = 0; j < i; j++)
        {
	  if (images[i] == images[j])
	    {
	      break;
	    }
	}
      if (j < i)
        {
	  c->images[i] = RETAIN(c->images[j]);
	}
      else
        {
	  c->images[i] = [images[i] copy];
	}
    }
  return c;
}

- (void) dealloc
{
  unsigned	i;

  for (i = 0; i < 9; i++)
    {
      RELEASE(images[i]);
    }
  [super dealloc];
}

/**
 * Simple initialiser, assume the single image is split into nine equal tiles.
 * If the image size is not divisible by three, the corners are made equal
 * in size and the central parts slightly smaller.
 */
- (id) initWithImage: (NSImage*)image
{
  NSSize	s = [image size];

  return [self initWithImage: image
		  horizontal: s.width / 3.0
		    vertical: s.height / 3.0];
}

- (id) initWithImage: (NSImage*)image horizontal: (float)x vertical: (float)y
{
  unsigned	i;
  NSSize	s = [image size];

  x = floor(x);
  y = floor(y);

  rects[TileTL] = NSMakeRect(0.0, s.height - y, x, y);
  rects[TileTM] = NSMakeRect(x, s.height - y, s.width - 2.0 * x, y);
  rects[TileTR] = NSMakeRect(s.width - x, s.height - y, x, y);
  rects[TileCL] = NSMakeRect(0.0, y, x, s.height - 2.0 * y);
  rects[TileCM] = NSMakeRect(x, y, s.width - 2.0 * x, s.height - 2.0 * y);
  rects[TileCR] = NSMakeRect(s.width - x, y, x, s.height - 2.0 * y);
  rects[TileBL] = NSMakeRect(0.0, 0.0, x, y);
  rects[TileBM] = NSMakeRect(x, 0.0, s.width - 2.0 * x, y);
  rects[TileBR] = NSMakeRect(s.width - x, 0.0, x, y);

  for (i = 0; i < 9; i++)
    {
      if (rects[i].origin.x < 0.0 || rects[i].origin.y < 0.0
	|| rects[i].size.width <= 0.0 || rects[i].size.height <= 0.0)
        {
	  images[i] = nil;
	  rects[i] = NSZeroRect;
	}
      else
        {
	  images[i] = RETAIN(image);
	}
    }  

  return self;
}

- (void) scaleUp: (int)multiple
{
  if (multiple > 1)
    {
      unsigned	i;
      NSSize	s;

      [images[0] setScalesWhenResized: YES];
      s = [images[0] size];
      s.width *= multiple;
      s.height *= multiple;
      [images[0] setSize: s];
      rects[0].size.height *= multiple;
      rects[0].size.width *= multiple;
      rects[0].origin.x *= multiple;
      rects[0].origin.y *= multiple;
      for (i = 1; i < 9; i++)
        {
	  unsigned	j;

	  for (j = 0; j < i; j++)
	    {
	      if (images[i] == images[j])
		{
		  break;
		}
	    }
	  if (j == i)
	    {
	      [images[i] setScalesWhenResized: YES];
	      s = [images[i] size];
	      s.width *= multiple;
	      s.height *= multiple;
	      [images[i] setSize: s];
	    }
	  rects[i].size.height *= multiple;
	  rects[i].size.width *= multiple;
	  rects[i].origin.x *= multiple;
	  rects[i].origin.y *= multiple;
	}
    }
}
@end



@implementation	GSThemePanel

static GSThemePanel	*sharedPanel = nil;

+ (GSThemePanel*) sharedThemePanel
{
  if (sharedPanel == nil)
    {
      sharedPanel = [self new];
    }
  return sharedPanel;
}

- (id) init
{
  NSRect	winFrame;
  NSRect	sideFrame;
  NSRect	bottomFrame;
  NSRect	frame;
  NSView	*container;
  NSButtonCell	*proto;

  winFrame = NSMakeRect(0, 0, 367, 420);
  sideFrame = NSMakeRect(0, 0, 95, 420);
  bottomFrame = NSMakeRect(95, 0, 272, 32);
  
  self = [super initWithContentRect: winFrame
    styleMask: (NSTitledWindowMask | NSClosableWindowMask
      | NSMiniaturizableWindowMask | NSResizableWindowMask)
    backing: NSBackingStoreBuffered
    defer: NO];
  
  [self setReleasedWhenClosed: NO];
  container = [self contentView];
  sideView = [[NSScrollView alloc] initWithFrame: sideFrame];
  [sideView setHasHorizontalScroller: NO];
  [sideView setHasVerticalScroller: YES];
  [sideView setBorderType: NSBezelBorder];
  [sideView setAutoresizingMask: (NSViewHeightSizable | NSViewMaxXMargin)];
  [container addSubview: sideView];
  RELEASE(sideView);

  proto = [[NSButtonCell alloc] init];
  [proto setBordered: NO];
  [proto setAlignment: NSCenterTextAlignment];
  [proto setImagePosition: NSImageAbove];
  [proto setSelectable: NO];
  [proto setEditable: NO];
  [matrix setPrototype: proto];

  frame = [sideView frame];
  frame.origin = NSZeroPoint;
  matrix = [[NSMatrix alloc] initWithFrame: frame
				      mode: NSRadioModeMatrix
				 prototype: proto
			      numberOfRows: 1
			   numberOfColumns: 1];
  RELEASE(proto);
  [matrix setAutosizesCells: NO];
  [matrix setCellSize: NSMakeSize(72,72)];
  [matrix setIntercellSpacing: NSMakeSize(8,8)];
  [matrix setAutoresizingMask: NSViewNotSizable];
  [matrix setMode: NSRadioModeMatrix];
  [matrix setAction: @selector(changeSelection:)];
  [matrix setTarget: self];

  [sideView setDocumentView: matrix];
  RELEASE(matrix);

  bottomView = [[NSView alloc] initWithFrame: bottomFrame];
  [bottomView setAutoresizingMask: (NSViewWidthSizable | NSViewMaxYMargin)];
  [container addSubview: bottomView];
  RELEASE(bottomView);

  [self setTitle: @"Themes"];
  
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(notified:)
    name: GSThemeDidActivateNotification
    object: nil];
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(notified:)
    name: GSThemeDidDeactivateNotification
    object: nil];

  /* Fake a notification to set the initial value for the inspector.
   */
  [self notified:
    [NSNotification notificationWithName: GSThemeDidActivateNotification
				  object: [GSTheme theme]
				userInfo: nil]];
  return self;
}

- (void) changeSelection: (id)sender
{
  NSButtonCell	*cell = [sender selectedCell];
  NSString	*name = [cell title];

  [GSTheme setTheme: [GSTheme loadThemeNamed: name]];
}

- (void) notified: (NSNotification*)n
{
  NSView		*cView;
  GSThemeInspector	*inspector;

  inspector = (GSThemeInspector*)[[n object] themeInspector];
  cView = [self contentView];

  if ([[n name] isEqualToString: GSThemeDidActivateNotification] == YES)
    {
      NSView	*iView;
      NSRect	frame;
      NSButton	*button;
      NSString	*dName;

      /* Ask the inspector to ensure that it is up to date.
       */
      [inspector update: self];

      /* Move the inspector view into our window.
       */
      iView = RETAIN([inspector contentView]);
      [inspector setContentView: nil];
      [cView addSubview: iView];
      RELEASE(iView);

      /* Set inspector view to fill the frame to the right of our
       * scrollview and above the bottom view
       */
      frame.origin.x = [sideView frame].size.width;
      frame.origin.y = [bottomView frame].size.height;
      frame.size = [cView frame].size;
      frame.size.width -= [sideView frame].size.width;
      frame.size.height -= [bottomView frame].size.height;
      [iView setFrame: frame];

      button = [[bottomView subviews] lastObject];
      if (button == nil)
        {
	  button = [NSButton new];
	  [button setTarget: self];
	  [button setAction: @selector(setDefault:)];
	  [bottomView addSubview: button];
	  RELEASE(button);
	}
      dName = [[NSUserDefaults standardUserDefaults] stringForKey: @"GSTheme"];
      if ([[[n object] name] isEqual: dName] == YES)
        {
	  [button setTitle: @"Revert default theme"];
	}
      else
	{
	  [button setTitle: @"Make this the default theme"];
	}
      [button sizeToFit];
      frame = [button frame];
      frame.origin.x = ([bottomView frame].size.width - frame.size.width) / 2;
      frame.origin.y = ([bottomView frame].size.height - frame.size.height) / 2;
      [button setFrame: frame];
    }
  else
    {
      /* Restore the inspector content view.
       */
      [inspector setContentView: [[cView subviews] lastObject]];
    }
  [cView setNeedsDisplay: YES];
}

- (void) setDefault: (id)sender
{
  NSButton		*button = (NSButton*)sender;
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSString		*cName;
  NSString		*dName;
  NSRect		frame;

  dName = [defs stringForKey: @"GSTheme"];
  cName = [[GSTheme theme] name];

  if ([cName isEqual: dName] == YES)
    {
      [defs removeObjectForKey: @"GSTheme"];
      [button setTitle: @"Make this the default theme"];
    }
  else
    {
      [defs setObject: cName forKey: @"GSTheme"];
      [button setTitle: @"Revert default theme"];
    }
  [defs synchronize];
  [button sizeToFit];
  frame = [button frame];
  frame.origin.x = ([bottomView frame].size.width - frame.size.width) / 2;
  frame.origin.y = ([bottomView frame].size.height - frame.size.height) / 2;
  [button setFrame: frame];
  [bottomView setNeedsDisplay: YES];
}

- (void) update: (id)sender
{
  NSArray		*array;

  /* Avoid [NSMutableSet set] that confuses GCC 3.3.3.  It seems to confuse
   * this static +(id)set method with the instance -(void)set, so it would
   * refuse to compile saying
   * GSTheme.m:1565: error: void value not ignored as it ought to be
   */
  NSMutableSet		*set = AUTORELEASE([NSMutableSet new]);

  NSString		*selected = RETAIN([[matrix selectedCell] title]);
  unsigned		existing = [[matrix cells] count];
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSEnumerator		*enumerator;
  NSString		*path;
  NSString		*name;
  NSButtonCell		*cell;
  unsigned		count = 0;

  /* Ensure the first cell contains the default theme.
   */
  cell = [matrix cellAtRow: count++ column: 0];
  [cell setImage: [defaultTheme icon]];
  [cell setTitle: [defaultTheme name]];

  /* Go through all the themes in the standard locations and find their names.
   */
  enumerator = [NSSearchPathForDirectoriesInDomains
    (NSAllLibrariesDirectory, NSAllDomainsMask, YES) objectEnumerator];
  while ((path = [enumerator nextObject]) != nil)
    {
      NSEnumerator	*files;
      NSString		*file;

      path = [path stringByAppendingPathComponent: @"Themes"];
      files = [[mgr directoryContentsAtPath: path] objectEnumerator];
      while ((file = [files nextObject]) != nil)
        {
	  NSString	*ext = [file pathExtension];

	  name = [file stringByDeletingPathExtension];
	  if ([ext isEqualToString: @"theme"] == YES
	    && [name isEqualToString: @"GNUstep"] == NO)
	    {
	      [set addObject: name];
	    }
	}
    }

  /* Sort theme names alphabetically, and add each theme to the matrix.
   */
  array = [[set allObjects] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)];
  enumerator = [array objectEnumerator];
  while ((name = [enumerator nextObject]) != nil)
    {
      GSTheme	*loaded;

      loaded = [GSTheme loadThemeNamed: name];
      if (loaded != nil)
	{
	  if (count >= existing)
	    {
	      [matrix addRow];
	      existing++;
	    }
	  cell = [matrix cellAtRow: count column: 0];
	  [cell setImage: [loaded icon]];
	  [cell setTitle: [loaded name]];
	  count++;
	}
    }

  /* Empty any unused cells.
   */
  while (count < existing)
    {
      cell = [matrix cellAtRow: count column: 0];
      [cell setImage: nil];
      [cell setTitle: @""];
      count++;
    }

  /* Restore the selected cell.
   */
  array = [matrix cells];
  count = [array count];
  while (count-- > 0)
    {
      cell = [matrix cellAtRow: count column: 0];
      if ([[cell title] isEqual: selected])
        {
	  [matrix selectCellAtRow: count column: 0];
	  break;
	}
    }
  RELEASE(selected);
  [matrix sizeToCells];
  [matrix setNeedsDisplay: YES];
}

@end



static NSTextField *
new_label (NSString *value)
{
  NSTextField *t;

  t = AUTORELEASE([NSTextField new]);
  [t setStringValue: value];
  [t setDrawsBackground: NO];
  [t setEditable: NO];
  [t setSelectable: NO];
  [t setBezeled: NO];
  [t setBordered: NO];
  [t setAlignment: NSLeftTextAlignment];
  return t;
}

/* Implemented in GSInfoPanel.m
 * An object that displays a list of left-aligned strings (used for the authors)
 */
@interface _GSLabelListView: NSView
{
}
/* After initialization, its size is the size it needs, just move it
   where we want it to show */
- (id) initWithStringArray: (NSArray *)array
		      font: (NSFont *)font;
@end


@implementation	GSThemeInspector

static GSThemeInspector	*sharedInspector = nil;

+ (GSThemeInspector*) sharedThemeInspector
{
  if (sharedInspector == nil)
    {
      sharedInspector = [self new];
    }
  return sharedInspector;
}

- (id) init
{
  NSRect	frame;
  NSView	*content;

  frame.size = NSMakeSize(272,388);
  frame.origin = NSZeroPoint;
  self = [super initWithContentRect: frame
    styleMask: (NSTitledWindowMask | NSClosableWindowMask
      | NSMiniaturizableWindowMask | NSResizableWindowMask)
    backing: NSBackingStoreBuffered
    defer: NO];
  
  [self setReleasedWhenClosed: NO];
  content = [self contentView];
  return self;
}

- (void) update: (id)sender
{
  GSTheme	*theme = [GSTheme theme];
  NSString	*details;
  NSArray	*authors;
  NSView	*content = [self contentView];
  NSRect	cFrame = [content frame];
  NSView	*view;
  NSImageView	*iv;
  NSTextField	*tf;
  NSRect	nameFrame;
  NSRect	frame;

  while ((view = [[content subviews] lastObject]) != nil)
    {
      [view removeFromSuperview];
    }
  frame = NSMakeRect(cFrame.size.width - 58, cFrame.size.height - 58, 48, 48);
  iv = [[NSImageView alloc] initWithFrame: frame];
  [iv setImage: [[GSTheme theme] icon]];
  [content addSubview: iv];

  tf = new_label([theme name]);
  [tf setFont: [NSFont boldSystemFontOfSize: 32]];
  [tf sizeToFit];
  nameFrame = [tf frame];
  nameFrame.origin.x
    = (cFrame.size.width - frame.size.width - nameFrame.size.width) / 2;
  nameFrame.origin.y = cFrame.size.height - nameFrame.size.height - 25;
  [tf setFrame: nameFrame];
  [content addSubview: tf];

  authors = [[theme infoDictionary] objectForKey: @"GSThemeAuthors"];
  if ([authors count] > 0)
    {
      view = [[_GSLabelListView alloc] initWithStringArray: authors
        font: [NSFont systemFontOfSize: 14]];
      frame = [view frame];
      frame.origin.x = (cFrame.size.width - frame.size.width) / 2;
      frame.origin.y = nameFrame.origin.y - frame.size.height - 25;
      [view setFrame: frame];
      [content addSubview: view];
    }

  details = [[theme infoDictionary] objectForKey: @"GSThemeDetails"];
  if ([details length] > 0)
    {
      NSScrollView	*s;
      NSTextView	*v;
      NSRect		r;

      r = NSMakeRect(10, 10, cFrame.size.width - 20, frame.origin.y - 20);
      s = [[NSScrollView alloc] initWithFrame: r];
      [s setHasHorizontalScroller: NO];
      [s setHasVerticalScroller: YES];
      [s setBorderType: NSBezelBorder];
      [s setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
      [content addSubview: s];
      RELEASE(s);

      r = [[s documentView] frame];
      v = [[NSTextView alloc] initWithFrame: r];
      [v setBackgroundColor: [self backgroundColor]];
      [v setHorizontallyResizable: YES];
      [v setVerticallyResizable: YES];
      [v setEditable: NO];
      [v setRichText: YES];
      [v setMinSize: NSMakeSize (0, 0)];
      [v setMaxSize: NSMakeSize (1E7, 1E7)];
      [v setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
      [[v textContainer] setContainerSize:
	NSMakeSize (r.size.width, 1e7)];
      [[v textContainer] setWidthTracksTextView: YES];
      [v setString: details];
      [s setDocumentView: v];
      RELEASE(v);
    }

  [content setNeedsDisplay: YES];
}

@end

