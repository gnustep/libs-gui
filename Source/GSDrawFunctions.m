/** <title>GSDrawFunctions</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
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

#include "Foundation/NSBundle.h"
#include "Foundation/NSDictionary.h"
#include "Foundation/NSFileManager.h"
#include "Foundation/NSNotification.h"
#include "Foundation/NSNull.h"
#include "Foundation/NSPathUtilities.h"
#include "Foundation/NSUserDefaults.h"
#include "GNUstepGUI/GSDrawFunctions.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSColorList.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSView.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/PSOperators.h"

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
} GSDrawFunctionsTileOffset;

/** This is a trivial class to hold the nine tiles needed to draw a rectangle
 */
@interface	GSDrawTiles : NSObject
{
@public
  NSImage	*images[9];	/** The tile images */
  NSRect	rects[9];	/** The rectangles to use when drawing */
}
- (id) initWithImage: (NSImage*)image;
@end

@implementation	GSDrawTiles
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
  unsigned	i;
  unsigned	j;
  NSSize	s = [image size];

  for (i = 0; i < 9; i++)
    {
      images[i] = RETAIN(image);
    }  
  i = s.width / 3;
  j = s.height / 3;
  rects[TileTL] = NSMakeRect(0.0, s.height - j, i, j);
  rects[TileTM] = NSMakeRect(i, s.height - j, s.width - 2 * i, j);
  rects[TileTR] = NSMakeRect(s.width - i, s.height - j, i, j);
  rects[TileCL] = NSMakeRect(0.0, j, i, s.height - 2 * j);
  rects[TileCM] = NSMakeRect(i, j, s.width - 2 * i, s.height - 2 * j);
  rects[TileCR] = NSMakeRect(s.width - i, j, i, s.height - 2 * j);
  rects[TileBL] = NSMakeRect(0.0, 0.0, i, j);
  rects[TileBM] = NSMakeRect(i, 0.0, s.width - 2 * i, j);
  rects[TileBR] = NSMakeRect(s.width - i, 0.0, i, j);
  return self;
}
@end

@interface	GSDrawFunctions (internal)
/**
 * Called whenever user defaults are changed ... this checks for the
 * GSTheme user default and ensures that the specified theme is the
 * current active theme.
 */
+ (void) defaultsDidChange: (NSNotification*)n;

/**
 * Called to load and make active the specified theme.<br />
 * If aName is nil or an empty string, this reverts to the default theme.<br />
 * If the named theme is already active, this has no effect.<br />
 * Returns YES on success, NO if the theme could not be loaded.
 */
+ (BOOL) loadThemeNamed: (NSString*)aName;
@end


@implementation GSDrawFunctions

static GSDrawFunctions		*defaultTheme = nil;
static GSDrawFunctions		*theTheme = nil;
static NSString			*theThemeName = nil;
static NSMutableDictionary	*themes = nil;
static NSNull			*null = nil;

+ (void) defaultsDidChange: (NSNotification*)n
{
  NSUserDefaults	*defs;
  NSString		*name;

  defs = [NSUserDefaults standardUserDefaults];
  name = [defs stringForKey: @"GSTheme"];
  if (name != theThemeName && [name isEqual: theThemeName] == NO)
    {
      [self loadThemeNamed: name];
    }
}

+ (void) initialize
{
  if (themes == nil)
    {
      themes = [NSMutableDictionary new];
      [self theme];	// Initialise/create the default theme
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
}

+ (BOOL) loadThemeNamed: (NSString*)aName
{
  NSBundle		*bundle;
  Class			cls;
  GSDrawFunctions	*instance;
  NSString		*theme;

  if ([aName length] == 0)
    {
      [self setTheme: nil];
      [self theme];
      return YES;
    }

  /* Ensure that the theme name does not contain path components
   * and has the 'theme' extension.
   */
  aName = [aName lastPathComponent];
  if ([[aName pathExtension] isEqualToString: @"theme"] == YES)
    {
      theme = aName;
    }
  else
    {
      theme = [aName stringByAppendingPathExtension: @"theme"];
    }

  bundle = [themes objectForKey: theme];
  if (bundle == nil)
    {
      NSString		*path;
      NSEnumerator	*enumerator;
      NSFileManager	*mgr = [NSFileManager defaultManager];

      enumerator = [NSSearchPathForDirectoriesInDomains
        (NSAllLibrariesDirectory, NSAllDomainsMask, YES) objectEnumerator];
      while ((path = [enumerator nextObject]) != nil)
	{
	  BOOL isDir;
	  
	  path = [path stringByAppendingPathComponent: @"Themes"];
	  path = [path stringByAppendingPathComponent: theme];
	  if ([mgr fileExistsAtPath: path isDirectory:	&isDir])
	    {
	      break;
	    }
	}

      if (path == nil)
	{
	  NSLog (@"No theme named '%@' found", aName);
	  return NO;
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
  [self setTheme: instance];
  RELEASE(instance);
  return YES;
}

+ (void) setTheme: (GSDrawFunctions*)theme
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
}

+ (GSDrawFunctions*) theme 
{
  return theTheme;
}


- (void) activate
{
  NSMutableDictionary	*userInfo = [NSMutableDictionary dictionary];
  NSArray		*imagePaths;
  NSEnumerator		*enumerator;
  NSString		*imagePath;
  NSString		*colorsPath;

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
  imagePaths = [_bundle pathsForResourcesOfType: nil
				    inDirectory: @"ThemeImages"];
  enumerator = [imagePaths objectEnumerator];
  while ((imagePath = [enumerator nextObject]) != nil)
    {
      NSImage	*image;

      image = [[NSImage alloc] initWithContentsOfFile: imagePath];
      if (image != nil)
	{
	  NSString	*imageName;

	  imageName = [imagePath lastPathComponent];
	  imageName = [imageName stringByDeletingPathExtension];
	  [_images addObject: image];
	  [image setName: imageName];
	  RELEASE(image);
	}
    }

  [[NSNotificationCenter defaultCenter]
   postNotificationName: GSThemeDidActivateNotification
   object: self
   userInfo: userInfo];
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
   * and our cache array.
   */
  enumerator = [_images objectEnumerator];
  while ((image = [enumerator nextObject]) != nil)
    {
      [image setName: nil];
    }
  [_images removeAllObjects];

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
  [super dealloc];
}

- (id) initWithBundle: (NSBundle*)bundle
{
  ASSIGN(_bundle, bundle);
  _images = [NSMutableArray new];
  _tiles = [NSMutableDictionary new];
  return self;
}

- (GSDrawTiles*) tilesNamed: (NSString*)aName
{
  GSDrawTiles	*tiles = [_tiles objectForKey: aName];

  if (tiles == nil)
    {
      NSImage		*image = [NSImage imageNamed: aName];

      if (image != nil)
        {
	  tiles = [[GSDrawTiles alloc] initWithImage: image];
	}
      else
        {
	  tiles = RETAIN(null);
	}
      [_tiles setObject: tiles forKey: aName];
      RELEASE(_tiles);
    }
  if (tiles == (id)null)
    {
      tiles = nil;
    }
  return tiles;
}

@end


@implementation	GSDrawFunctions (Drawing)

- (NSRect) drawButton: (NSRect) frame 
                   in: (NSButtonCell*) cell 
                 view: (NSView*) view 
                style: (int) style 
                state: (int) state
{
  /* computes the interior frame rect */

  NSRect interiorFrame = [cell drawingRectForBounds: frame];

  /* Draw the button background */

  if (state == 0) /* default state, unpressed */
    {
      [[NSColor controlBackgroundColor] set];
      NSRectFill(frame);
      [GSDrawFunctions drawButton: frame : NSZeroRect];
    }
  else if (state == 1) /* highlighted state */
    {
      [[NSColor selectedControlColor] set];
      NSRectFill(frame);
      [GSDrawFunctions drawGrayBezel: frame : NSZeroRect];
    }
  else if (state == 2) /* pushed state */
    {
      [[NSColor selectedControlColor] set];
      NSRectFill(frame);
      [GSDrawFunctions drawGrayBezel: frame : NSZeroRect];
      interiorFrame
	= NSOffsetRect(interiorFrame, 1.0, [view isFlipped] ? 1.0 : -1.0);
    }

  /* returns the interior frame rect */

  return interiorFrame;
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

@end



@implementation	GSDrawFunctions (MidLevelDrawing)

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

@end



@implementation	GSDrawFunctions (LowLevelDrawing)

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

- (void) fillRect: (NSRect)rect
	withTiles: (GSDrawTiles*)tiles
       background: (NSColor*)color
	fillStyle: (GSDrawFunctionsFillStyle)style
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

  if (flipped)
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

      inFill = NSMakeRect (rect.origin.x +cls.width,
        rect.origin.y + bms.height,
	rect.size.width - cls.width - crs.width,
	rect.size.height - bms.height - tms.height);
      if (style == FillStyleCenter)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: NO];
	}
      else if (style == FillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: NO];
	}
      else if (style == FillStyleScale)
        {
	  [tiles->images[TileCM] setScalesWhenResized: YES];
	  [tiles->images[TileCM] setSize: inFill.size];
	  [tiles->images[TileCM] compositeToPoint: inFill.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
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

      if (style == FillStyleCenter)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: NO];
	}
      else if (style == FillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: YES];
	}
      else if (style == FillStyleScale)
	{
	  [tiles->images[TileCM] setScalesWhenResized: YES];
	  [tiles->images[TileCM] setSize: inFill.size];
	  [tiles->images[TileCM] compositeToPoint: inFill.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
	}
    }
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



@implementation GSDrawFunctions (deprecated)
+ (NSRect) drawButton: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawButton: border : clip];
}
+ (NSRect) drawDarkButton: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawDarkButton: border : clip];
}
+ (NSRect) drawDarkBezel: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawDarkBezel: border : clip];
}
+ (NSRect) drawLightBezel: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawLightBezel: border : clip];
}
+ (NSRect) drawWhiteBezel: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawWhiteBezel: border : clip];
}
+ (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawGrayBezel: border : clip];
}
+ (NSRect) drawGroove: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawGroove: border : clip];
}
+ (NSRect) drawFramePhoto: (NSRect)border : (NSRect)clip
{
  return [[self theme] drawFramePhoto: border : clip];
}
+ (NSRect) drawGradientBorder: (NSGradientType)gradientType 
		       inRect: (NSRect)border 
		     withClip: (NSRect)clip
{
  return [[self theme] drawGradientBorder: gradientType
				   inRect: border
				 withClip: clip];
}
- (NSRect) drawButton: (NSRect)border : (NSRect)clip
{
  return [self drawButton: border withClip: clip];
}
- (NSRect) drawDarkButton: (NSRect)border : (NSRect)clip
{
  return [self drawDarkButton: border withClip: clip];
}
- (NSRect) drawDarkBezel: (NSRect)border : (NSRect)clip
{
  return [self drawDarkBezel: border withClip: clip];
}
- (NSRect) drawLightBezel: (NSRect)border : (NSRect)clip
{
  return [self drawLightBezel: border withClip: clip];
}
- (NSRect) drawWhiteBezel: (NSRect)border : (NSRect)clip
{
  return [self drawWhiteBezel: border withClip: clip];
}
- (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip
{
  return [self drawGrayBezel: border withClip: clip];
}
- (NSRect) drawGroove: (NSRect)border : (NSRect)clip
{
  return [self drawGroove: border withClip: clip];
}
- (NSRect) drawFramePhoto: (NSRect)border : (NSRect)clip
{
  return [self drawFramePhoto: border withClip: clip];
}
@end

