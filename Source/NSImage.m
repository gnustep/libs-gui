/*
   NSImage.m

   Load, manipulate and display images

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
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
    FIXME:  
        [1] Filter services not implemented.
	[2] Should there be a place to look for system bitmaps? 
	(findImageNamed: ).
	[3] bestRepresentation is not complete.
*/
#include <gnustep/gui/config.h>
#include <string.h>

#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSString.h>

#include <AppKit/NSImage.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSColor.h>

BOOL	doesCaching = NO;

// Resource directories
static NSString* gnustep_libdir = @GNUSTEP_INSTALL_LIBDIR;
static NSString* NSImage_PATH = @"Images";

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NSImageBackend
- (void) compositeToPoint: (NSPoint)point
		 fromRect: (NSRect)rect
		operation: (NSCompositingOperation)op;
- (void) dissolveToPoint: (NSPoint)point
		fromRect: (NSRect)rect
		fraction: (float)aFloat;
@end

@interface	GSRepData : NSObject
{
@public
  NSString	*fileName;
  NSImageRep	*rep;
  NSImageRep	*original;
  NSColor	*bg;
}
@end

@implementation	GSRepData
- (id) copyWithZone: (NSZone*)z
{
  GSRepData	*c = (GSRepData*)NSCopyObject(self, 0, z);

  if (c->fileName)
    c->fileName = [c->fileName copy];
  if (c->rep)
    c->rep = [c->rep copy];
  if (c->bg)
    c->bg = [c->bg copy];
  return c;
}

- (void) dealloc
{
  if (fileName)
    [fileName release];
  if (rep)
    [rep release];
  if (bg)
    [bg release];
  NSDeallocateObject(self);
}
@end

NSArray *iterate_reps_for_types(NSArray *imageReps, SEL method);

/* Find the GSRepData object holding a representation */
GSRepData*
repd_for_rep(NSArray *_reps, NSImageRep *rep)
{
  unsigned	i, count;
  GSRepData	*repd;

  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      repd = [_reps objectAtIndex: i];
      if (repd->rep == rep)
        return repd;
    }
  [NSException raise: NSInternalInconsistencyException
  	format: @"Cannot find stored representation"];
  /* NOT REACHED */
  return nil;
}

@interface NSImage (Backend) <NSImageBackend>
@end

@interface NSImage (Private)
- (BOOL) useFromFile: (NSString *)fileName;
- (BOOL) loadFromData: (NSData *)data;
- (BOOL) loadFromFile: (NSString *)fileName;
- (NSImageRep *) lastRepresentation;
@end

@implementation NSImage

/* Class variables and functions for class methods */
static NSMutableDictionary* nameDict = nil;
static NSDictionary* nsmapping = nil;

+ (void)initialize
{
  if (self == [NSImage class])
    {
      NSBundle	*system = [NSBundle bundleWithPath: gnustep_libdir];
      NSString	*path = [system pathForResource: @"nsmapping"
					 ofType: @"strings"
				    inDirectory: NSImage_PATH];
      // Initial version
      [self setVersion: 1];

      // initialize the class variables
      nameDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
      if (path)
	nsmapping = [[[NSString stringWithContentsOfFile: path]
				propertyListFromStringsFileFormat]
				retain];
    }
}

+ imageNamed: (NSString *)aName
{
  NSString	*realName = [nsmapping objectForKey: aName];

  if (realName)
    aName = realName;

  /* If there is no image with that name, search in the main bundle */
  if (!nameDict || ![nameDict objectForKey: aName]) 
    {
      NSString* ext;
      NSString* path = nil;
      NSBundle* main_bundle;
      NSArray *array;
      NSString *the_name = aName;
      main_bundle = [NSBundle mainBundle];
      ext  = [aName pathExtension];

      /* Check if extension is one of the image types */
      array = [self imageFileTypes];
      if ([array indexOfObject: ext] != NSNotFound)
	{
	  /* Extension is one of the image types
	     So remove from the name */
	  the_name = [aName stringByDeletingPathExtension];
	}
      else
	{
	  /* Otherwise extension is not an image type
	     So leave it alone */
	  the_name = aName;
	  ext = nil;
	}

      /* First search locally */
      if (ext)
	path = [main_bundle pathForResource: the_name ofType: ext];
      else 
	{
	  id o, e;

	  e = [array objectEnumerator];
	  while ((o = [e nextObject]))
	    {
	      NSDebugLog(@"extension %s\n", [o cString]);
	      path = [main_bundle pathForResource: the_name 
		        ofType: o];
	      if (path != nil && [path length] != 0)
		break;
	    }
	}

      /* If not found then search in system */
      if (!path)
	{
	  NSBundle *system = [NSBundle bundleWithPath: gnustep_libdir];

	  if (ext)
	    path = [system pathForResource: the_name
				    ofType: ext
			       inDirectory: NSImage_PATH];
	  else 
	    {
	      id o, e;
	      NSArray* array;

	      array = [self imageFileTypes];
	      if (!array)
		NSDebugLog(@"array is nil\n");
	      e = [array objectEnumerator];
	      while ((o = [e nextObject]))
		{
		  path = [system pathForResource: the_name
					  ofType: o
				     inDirectory: NSImage_PATH];
		  if (path != nil && [path length] != 0)
		    break;
		}
	    }
	}

      if ([path length] != 0) 
	{
	  NSImage	*image;

	  image = [[self allocWithZone: NSDefaultMallocZone()]
		initByReferencingFile: path];
	  if (image)
	    {
	      [image setName: aName];
	      [image release];		// Retained in dictionary.
	    }
	  return image;
	}
    }
  
  return [nameDict objectForKey: aName];
}

// Designated initializer for nearly everything.
- initWithSize: (NSSize)aSize
{
  [super init];
  _reps = [[NSMutableArray arrayWithCapacity: 2] retain];
  if (aSize.width && aSize.height) 
    {
      _size = aSize;
      _flags.sizeWasExplicitlySet = YES;
    }
  _flags.colorMatchPreferred = YES;
  _flags.multipleResolutionMatching = YES;
  
  return self;
}

- (id) init
{
  self = [self initWithSize: NSMakeSize(0, 0)];
  return self;
}

- (id) initByReferencingFile: (NSString *)fileName
{
  id	o = self;

  if ((self = [self init]) == o)
    {
      _flags.dataRetained = NO;
      if (![self useFromFile: fileName])
	{
	  [self release];
	  return nil;
	}
    }
  return self;
}

- (id) initWithContentsOfFile: (NSString *)fileName
{
  id	o = self;

  if ((self = [self init]) == o)
    {
      _flags.dataRetained = YES;
      if (![self useFromFile: fileName])
	{
	  [self release];
	  return nil;
	}
    }
  return self;
}

- (id) initWithData: (NSData *)data;
{
  id	o = self;

  if ((self = [self init]) == o)
    {
      if (![self loadFromData: data])
	{
	  [self release];
	  return nil;
	}
    }
  return self;
}

- initWithPasteboard: (NSPasteboard *)pasteboard
{
  [self notImplemented: _cmd];
  return nil;
}

- (void) setSize: (NSSize)aSize
{
  _size = aSize;
  _flags.sizeWasExplicitlySet = YES;
}

- (NSSize) size
{
  if (_size.width == 0) 
    {
      NSImageRep* rep = [self bestRepresentationForDevice: nil];
      _size = [rep size];
    }
  return _size;
}

- (void) dealloc
{
  [self representations];
  [_repList release];
  [_reps release];
  /* Make sure we don't remove name from the nameDict if we are just a copy
     of the named image, not the original image */
  if (name && self == [nameDict objectForKey: name]) 
    [nameDict removeObjectForKey: name];
  [name release];
  [super dealloc];
}

- copyWithZone: (NSZone *)zone
{
  NSImage* copy;

  // FIXME: maybe we should retain if _flags.dataRetained = NO
  copy = (NSImage*)NSCopyObject (self, 0, zone);

  [name retain];
  copy->_reps = [NSMutableArray new];
  copy->_repList = [NSMutableArray new];
  [_color retain];
  _lockedView = nil;
  [copy addRepresentations: [[[self representations] copyWithZone: zone]
				autorelease]];
  
  return copy;
}

- (BOOL)setName: (NSString *)string
{
  if (!nameDict)
    nameDict = [[NSMutableDictionary dictionaryWithCapacity: 2] retain];

  if (!string || [nameDict objectForKey: string])
    return NO;

  [string retain];
  if (name)
    [name release];
  name = string;

  [nameDict setObject: self forKey: name];
  return YES;
}

- (NSString *)name
{
  return name;
}

// Choosing Which Image Representation to Use 
- (void) setUsesEPSOnResolutionMismatch: (BOOL)flag
{
  _flags.useEPSOnResolutionMismatch = flag;
}

- (BOOL)usesEPSOnResolutionMismatch
{
  return _flags.useEPSOnResolutionMismatch;
}

- (void) setPrefersColorMatch: (BOOL)flag
{
  _flags.colorMatchPreferred = flag;
}

- (BOOL)prefersColorMatch
{
  return _flags.colorMatchPreferred;
}

- (void) setMatchesOnMultipleResolution: (BOOL)flag
{
  _flags.multipleResolutionMatching = flag;
}

- (BOOL)matchesOnMultipleResolution
{
  return _flags.multipleResolutionMatching;
}

// Determining How the Image is Stored 
- (void) setCachedSeparately: (BOOL)flag
{
  _flags.cacheSeparately = flag;
}

- (BOOL) isCachedSeparately
{
  return _flags.cacheSeparately;
}

- (void) setDataRetained: (BOOL)flag
{
  _flags.dataRetained = flag;
}

- (BOOL) isDataRetained
{
  return _flags.dataRetained;
}

- (void) setCacheDepthMatchesImageDepth: (BOOL)flag
{
  _flags.unboundedCacheDepth = flag;
}

- (BOOL) cacheDepthMatchesImageDepth
{
  return _flags.unboundedCacheDepth;
}

// Determining How the Image is Drawn 
- (BOOL) isValid
{
  BOOL		valid = NO;
  unsigned	i, count;

  /* Go through all our representations and determine if at least one
     is a valid cache */
  // FIXME: Not sure if this is correct
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      GSRepData	 *repd = (GSRepData*)[_reps objectAtIndex: i];

      if (repd->bg != nil
	|| [repd->rep isKindOfClass: [NSCachedImageRep class]] == NO)
	valid = YES;
    }
  return valid;
}

- (void) recache
{
  int i, count;

  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      GSRepData	*repd;

      repd = (GSRepData*)[_reps objectAtIndex: i];
      if (repd->bg != nil)
	{
	  [repd->bg release];
	  repd->bg = nil;
	}
    }
}

- (void) setScalesWhenResized: (BOOL)flag
{
  _flags.scalable = flag;
}

- (BOOL) scalesWhenResized
{
  return _flags.scalable;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  if (_color != aColor)
    {
      if (_color)
	[_color release];
      _color = [aColor retain];
    }
}

- (NSColor *) backgroundColor
{
  if (_color == nil)
    _color = [[NSColor clearColor] retain];
  return _color;
}

/* Make sure any images that were added with useFromFile: are loaded
   in and added to the representation list. */
- _loadImageFilenames
{
  unsigned	i, count;
  GSRepData	*repd;

  _syncLoad = NO;
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      repd = (GSRepData*)[_reps objectAtIndex: i];
      if (repd->fileName)
	[self loadFromFile: repd->fileName];
    }
  // Now get rid of them since they are already loaded
  count = [_reps count];
  while (count--) 
    {
      repd = (GSRepData*)[_reps objectAtIndex: count];
      if (repd->fileName) 
	{
	  [_reps removeObjectAtIndex: count];
	}
    }
  return self;
}
    
// Cache the bestRepresentation.  If the bestRepresentation is not itself
// a cache and no cache exists, create one and draw the representation in it
// If a cache exists, but is not valid, redraw the cache from the original
// image (if there is one).
- (NSImageRep *)_doImageCache
{
  NSImageRep	*rep = nil;
  GSRepData	*repd;

  repd = repd_for_rep(_reps, [self bestRepresentationForDevice: nil]);
  rep = repd->rep;

  if (doesCaching)
    {
      /*
       * If this is not a cached image rep - create a cache to be used to
       * render the image rep into, and switch to the cached rep.
       */
      if ([rep isKindOfClass: [NSCachedImageRep class]] == NO) 
	{
	  NSScreen		*cur = [NSScreen mainScreen];
	  NSCachedImageRep	*cachedRep;
	  NSSize		imageSize;
  
	  imageSize = [self size];
	  if (imageSize.width == 0 || imageSize.height == 0)
	    return nil;

	  cachedRep = [[NSCachedImageRep alloc] initWithSize: _size
						       depth: [cur depth]
						    separate: NO
						       alpha: NO];
	  [self addRepresentation: cachedRep];
	  [cachedRep release];		/* Retained in _reps array.	*/
	  repd = repd_for_rep(_reps, cachedRep);
	  repd->original = rep;
	  rep = repd->rep;
	} 

      /*
       * if the cache is not valid, it's background color will not exist
       * and we must draw the background then render from the original
       * image rep into the cache.
       */
      if (repd->bg == nil) 
	{
	  NSRect	bounds;

	  [self lockFocusOnRepresentation: rep];
	  /*
	   * If this is not a cache - the lockFocus will have created a
	   * cache that we can use instead.
	   */
	  if (repd->original == nil)
	    {
	      repd = repd_for_rep(_reps, [self lastRepresentation]);
	    }
	  bounds = [_lockedView bounds];
	  [_color set];
	  NSEraseRect(bounds);
	  [self drawRepresentation: repd->original 
	    inRect: NSMakeRect(0, 0, _size.width, _size.height)];
	  [self unlockFocus];
	  repd->bg = [_color copy];
	}
    }
  
  return rep;
}

// Using the Image 
- (void) compositeToPoint: (NSPoint)aPoint 
		operation: (NSCompositingOperation)op;
{
  NSRect rect;

  [self size];
  rect = NSMakeRect(0, 0, _size.width, _size.height);
  [self compositeToPoint: aPoint fromRect: rect operation: op];
}

- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)aRect
		operation: (NSCompositingOperation)op;
{
  NSImageRep *rep;
  NSRect rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);

  // xxx If fromRect specifies something other than full image
  // then we need to construct a subimage to draw

  rep = [self _doImageCache];
  [self drawRepresentation: rep inRect: rect];
}

- (void) dissolveToPoint: (NSPoint)aPoint fraction: (float)aFloat;
{
  NSRect rect;
  [self size];
  rect = NSMakeRect(0, 0, _size.width, _size.height);
  [self dissolveToPoint: aPoint fromRect: rect fraction: aFloat];
}

- (void) dissolveToPoint: (NSPoint)aPoint
		fromRect: (NSRect)aRect 
		fraction: (float)aFloat;
{
  NSImageRep *rep;
  NSRect rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);

  // xxx If fromRect specifies something other than full image
  // then we need to construct a subimage to draw

  rep = [self _doImageCache];
  [self drawRepresentation: rep inRect: rect];
}

- (BOOL)drawRepresentation: (NSImageRep *)imageRep inRect: (NSRect)rect
{
  if (!_flags.scalable) 
    return [imageRep drawAtPoint: rect.origin];
  return [imageRep drawInRect: rect];
}

- (BOOL)loadFromData: (NSData *)data
{
  BOOL ok;
  Class rep;

  ok = NO;
  rep = [NSImageRep imageRepClassForData: data];
  if (rep && [rep respondsToSelector: @selector(imageRepsWithData:)])
    {
      NSArray* array;
      array = [rep imageRepsWithData: data];
      if (array)
	ok = YES;
      [self addRepresentations: array];
    }
  else if (rep)
    {
      NSImageRep* image;
      image = [rep imageRepWithData: data];
      if (image)
	ok = YES;
      [self addRepresentation: image];
    }
  return ok;
}

- (BOOL) loadFromFile: (NSString *)fileName
{
  NSArray* array;

  array = [NSImageRep imageRepsWithContentsOfFile: fileName];
  if (array)
    [self addRepresentations: array];

  return (array) ? YES : NO;
}

- (BOOL) useFromFile: (NSString *)fileName
{
  NSArray	*array;
  NSString	*ext;
  GSRepData	*repd;
  NSFileManager *manager = [NSFileManager defaultManager];

  if ([manager fileExistsAtPath: fileName] == NO)
    {
      return NO;
    }

  ext = [fileName pathExtension];
  if (!ext)
    return NO;
  array = [[self class] imageFileTypes];
  if ([array indexOfObject: ext] == NSNotFound)
    return NO;
  repd = [GSRepData new];
  repd->fileName = [fileName retain];
  [_reps addObject: repd];
  [repd release];
  _syncLoad = YES;
  return YES;
}

- (void) addRepresentation: (NSImageRep *)imageRep
{
  [self addRepresentations: [NSArray arrayWithObject: imageRep]];
}

- (void) addRepresentations: (NSArray *)imageRepArray
{
  unsigned	i, count;
  GSRepData	*repd;

  if (!imageRepArray)
    return;

  if (_syncLoad)
    [self _loadImageFilenames];
  count = [imageRepArray count];
  for (i = 0; i < count; i++)
    {
      repd = [GSRepData new];
      repd->rep = [[imageRepArray objectAtIndex: i] retain];
      [_reps addObject: repd]; 
      [repd release];
    }
}

- (BOOL) useCacheWithDepth: (int)depth
{
  NSSize imageSize;
  NSCachedImageRep* rep;
  
  imageSize = [self size];
  if (!imageSize.width || !imageSize.height)
    return NO;


  // FIXME: determine alpha? separate?
  rep = [[NSCachedImageRep alloc] initWithSize: _size
       depth: depth
       separate: NO
       alpha: NO];
  [self addRepresentation: rep];
  return YES;
}

- (void) removeRepresentation: (NSImageRep *)imageRep
{
  unsigned	i;
  GSRepData	*repd;

  i = [_reps count];
  while (i-- > 0)
    {
      repd = (GSRepData*)[_reps objectAtIndex: i];
      if (repd->rep == imageRep)
	{
	  [_reps removeObjectAtIndex: i];
	}
      else if (repd->original == imageRep)
	{
	  repd->original = nil;
	}
    }
}

- (void) lockFocus
{
  NSScreen	*cur = [NSScreen mainScreen];
  NSImageRep	*rep;

  if (!(rep = [self bestRepresentationForDevice: nil])) 
    {
      [self useCacheWithDepth: [cur depth]];
      rep = [self lastRepresentation];
    }
  [self lockFocusOnRepresentation: rep];
}

- (void) lockFocusOnRepresentation: (NSImageRep *)imageRep
{
  NSScreen	*cur = [NSScreen mainScreen];
  NSWindow	*window;

  if (!imageRep)
    [NSException raise: NSInvalidArgumentException
      format: @"Cannot lock focus on nil rep"];

  if (doesCaching)
    {
      if (![imageRep isKindOfClass: [NSCachedImageRep class]]) 
	{
	  GSRepData	*repd, *cached;
	  int		depth;

	  if (_flags.unboundedCacheDepth)
	    depth = [cur depth];      // FIXME: get depth correctly
	  else
	    depth = [cur depth];
	  if (![self useCacheWithDepth: depth]) 
	    {
	      [NSException raise: NSImageCacheException
		format: @"Unable to create cache"];
	    }
	  cached = repd_for_rep(_reps, [self lastRepresentation]);
	  cached->original = imageRep;
	  imageRep = cached->rep;
	}
	window = [(NSCachedImageRep *)imageRep window];
	_lockedView = [window contentView];
	[_lockedView lockFocus];
    }
}

- (void) unlockFocus
{
  if (_lockedView)
    [_lockedView unlockFocus];
  _lockedView = nil;
}

- (NSImageRep *) lastRepresentation
{
  // Reconstruct the rep list if it has changed
  [self representations];
  return [_repList lastObject];
}

- (NSImageRep*) bestRepresentationForDevice: (NSDictionary*)deviceDescription
{
  NSImageRep	*rep = nil;
  unsigned	count;

  /* Make sure we have the images loaded in. */
  if (_syncLoad)
    [self _loadImageFilenames];

  count = [_reps count];

  if (count > 0)
    {
      GSRepData		*reps[count];
      unsigned		i;

      /*
       *	What's the best representation? FIXME
       */
      [_reps getObjects: reps];
      for (i = 0; i < count; i++)
	{
	  GSRepData	*repd = reps[i];
    
	  if ([repd->rep isKindOfClass: [NSBitmapImageRep class]])
	    {
	      rep = repd->rep;
	    }
	}

      /*
       * If we got a representation - see if we already have it cached.
       */
      if (doesCaching)
	{
	  if (rep != nil)
	    {
	      GSRepData	*invalidCache = nil;
	      GSRepData	*validCache = nil;

	      /*
	       * Search the cached image reps for any whose original is our
	       * 'best' image rep.  See if we can notice any invalidated
	       * cache as we go - if we don't find a valid cache, we want to
	       * re-use an invalidated one rather than createing a new one.
	       */
	      for (i = 0; i < count; i++)
		{
		  GSRepData	*repd = reps[i];
    
		  if (repd->original == rep)
		    {
		      if (repd->bg == nil)
			{
			  invalidCache = repd;
			}
		      else if ([repd->bg isEqual: _color] == YES)
			{
			  validCache = repd;
			  break;
			}
		    }
		}

	      if (validCache)
		{
		  /*
		   * If the image rep has transparencey and we are drawing
		   * without a background (background is clear) then the
		   * cache can't really be valid 'cos we might be drawing
		   * transparency on top of anything.  So we invalidate
		   * the cache by removing the background color information.
		   */
		  if ([rep hasAlpha]
		    && [validCache->bg isEqual: [NSColor clearColor]])
		    {
		      [validCache->bg release];
		      validCache->bg = nil;
		    }
		  rep = validCache->rep;
		}
	      else if (invalidCache)
		{
		  rep = invalidCache->rep;
		}
	    }
	}
    }
  return rep;
}

- (NSArray *) representations
{
  unsigned	i, count;

  if (!_repList)
    _repList = [[NSMutableArray alloc] init];
  if (_syncLoad)
    [self _loadImageFilenames];
  [_repList removeAllObjects];
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      GSRepData	*repd = [_reps objectAtIndex: i];

      [_repList addObject: repd->rep];
    }
  return _repList;
}

- (void) setDelegate: anObject
{
  delegate = anObject;
}

- (id) delegate
{
  return delegate;
}

// Producing TIFF Data for the Image 
- (NSData *) TIFFRepresentation;
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSData *) TIFFRepresentationUsingCompression: (NSTIFFCompression)comp
	factor: (float)aFloat
{
  [self notImplemented: _cmd];
  return nil;
}

// Methods Implemented by the Delegate 
- (NSImage *)imageDidNotDraw: (id)sender
		      inRect: (NSRect)aRect
{
  if ([delegate respondsToSelector: @selector(imageDidNotDraw:inRect:)])
    return [delegate imageDidNotDraw: sender inRect: aRect];
  else
    return self;
}

// NSCoding
- (void) encodeWithCoder: (NSCoder*)coder
{
}

- (id) initWithCoder: (NSCoder*)coder
{
  return self;
}

- (id) awakeAfterUsingCoder: (NSCoder*)aDecoder
{
  if (name && [nameDict objectForKey: name]) 
    {
      return [nameDict objectForKey: name];
    }
    
  return self;
}

// FIXME: Implement
+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  int i, count;
  NSArray* array = [NSImageRep registeredImageRepClasses];

  count = [array count];
  for (i = 0; i < count; i++)
    if ([[array objectAtIndex: i] canInitWithPasteboard: pasteboard])
      return YES;
  
  return NO;
}

+ (NSArray *) imageUnfilteredFileTypes
{
  return iterate_reps_for_types([NSImageRep registeredImageRepClasses],
				@selector(imageUnfilteredFileTypes));
}

+ (NSArray *) imageFileTypes
{
  return iterate_reps_for_types([NSImageRep registeredImageRepClasses],
				@selector(imageFileTypes));
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  return iterate_reps_for_types([NSImageRep registeredImageRepClasses],
				@selector(imageUnfilteredPasteboardTypes));
}

+ (NSArray *) imagePasteboardTypes
{
  return iterate_reps_for_types([NSImageRep registeredImageRepClasses],
				@selector(imagePasteboardTypes));
}

@end

/* For every image rep, call the specified method to obtain an
   array of objects.  Add these together, with duplicates
   weeded out.  Used by imageUnfilteredPasteboardTypes,
   imageUnfilteredFileTypes, etc. */
NSArray *
iterate_reps_for_types(NSArray* imageReps, SEL method)
{
  NSImageRep	*rep;
  NSEnumerator	*e;
  NSMutableArray	*types;

  types = [NSMutableArray arrayWithCapacity: 2];

  // Iterate through all the image reps
  e = [imageReps objectEnumerator];
  rep = [e nextObject];
  while (rep)
    {
      id e1;
      id obj;
      NSArray* pb_list;

      // Have the image rep perform the operation
      pb_list = [rep performSelector: method];

      // Iterate through the returned array
      // and add elements to types list, duplicates weeded.
      e1 = [pb_list objectEnumerator];
      obj = [e1 nextObject];
      while (obj)
	{
	  if ([types indexOfObject: obj] == NSNotFound)
	    [types addObject: obj];
	  obj = [e1 nextObject];
	}

      rep = [e nextObject];
    }
    
  return (NSArray *)types;
}
