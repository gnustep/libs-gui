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

#import "Foundation/NSBundle.h"
#import "Foundation/NSDictionary.h"
#import "Foundation/NSFileManager.h"
#import "Foundation/NSNotification.h"
#import "Foundation/NSNull.h"
#import "Foundation/NSPathUtilities.h"
#import "Foundation/NSSet.h"
#import "Foundation/NSUserDefaults.h"
#import "GNUstepGUI/GSTheme.h"
#import "AppKit/NSApplication.h"
#import "AppKit/NSButton.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSColorList.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageView.h"
#import "AppKit/NSMatrix.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSPanel.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSTextContainer.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSTextView.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSView.h"
#import "AppKit/NSWindow.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/PSOperators.h"
#import "GSThemePrivate.h"


NSString	*GSThemeDidActivateNotification
  = @"GSThemeDidActivateNotification";
NSString	*GSThemeDidDeactivateNotification
  = @"GSThemeDidDeactivateNotification";
NSString	*GSThemeWillActivateNotification
  = @"GSThemeWillActivateNotification";
NSString	*GSThemeWillDeactivateNotification
  = @"GSThemeWillDeactivateNotification";

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
  NSMutableArray	*searchList;
  NSArray		*imagePaths;
  NSEnumerator		*enumerator;
  NSString		*imagePath;
  NSArray		*imageTypes;
  NSDictionary		*infoDict;
  NSWindow		*window;

  /* Get rid of any cached colors list so that we regenerate it when needed
   */
  [_colors release];
  _colors = nil;

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
   * Tell all other classes that new theme information is about to be present.
   */
  [[NSNotificationCenter defaultCenter]
    postNotificationName: GSThemeWillActivateNotification
    object: self
    userInfo: nil];

  /*
   * Tell all other classes that new theme information is present.
   */
  [[NSNotificationCenter defaultCenter]
    postNotificationName: GSThemeDidActivateNotification
    object: self
    userInfo: nil];

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

- (NSColorList*) colors
{
  if (_colors == nil)
    {
      NSString	*colorsPath;

      colorsPath = [_bundle pathForResource: @"ThemeColors" ofType: @"clr"]; 
      if (colorsPath == nil)
	{
	  _colors = [null retain];
	}
      else
	{
	  _colors = [[NSColorList alloc] initWithName: @"System"
					     fromFile: colorsPath];
	}
    }
  if ((id)_colors == (id)null)
    {
      return nil;
    }
  return _colors;
}

- (void) deactivate
{
  NSEnumerator	*enumerator;
  NSImage	*image;

  /* Tell everything that we will become inactive.
   */
  [[NSNotificationCenter defaultCenter]
    postNotificationName: GSThemeWillDeactivateNotification
    object: self
    userInfo: nil];

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
  RELEASE(_colors);
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

