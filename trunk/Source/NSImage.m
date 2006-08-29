/** <title>NSImage</title>

   <abstract>Load, manipulate and display images</abstract>

   Copyright (C) 1996, 2005 Free Software Foundation, Inc.
   
   Author: Adam Fedor <fedor@colorado.edu>
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   */ 
#include "config.h"
#include <string.h>
#include <math.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSKeyedArchiver.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include "AppKit/NSImage.h"

#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSBitmapImageRep.h"
#include "AppKit/NSCachedImageRep.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSPrintOperation.h"
#include "AppKit/NSScreen.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSDisplayServer.h"


/* Helpers.  Would be nicer to use the C99 fmin/fmax functions, but that
   isn't currently possible.  */
static double gs_min(double x, double y)
{
  if (x > y)
    return y;
  else
    return x;
}
static double gs_max(double x, double y)
{
  if (x < y)
    return y;
  else
    return x;
}


BOOL	NSImageForceCaching = NO;	/* use on missmatch	*/

@implementation NSBundle (NSImageAdditions)

- (NSString*) pathForImageResource: (NSString*)name
{
  NSString	*ext = [name pathExtension];
  NSString	*path = nil;

  if ((ext == nil) || [ext isEqualToString:@""])
    {
      NSArray	*types = [NSImage imageUnfilteredFileTypes];
      unsigned	c = [types count];
      unsigned	i;

      for (i = 0; path == nil && i < c; i++)
	{
	  ext = [types objectAtIndex: i];
	  path = [self pathForResource: name ofType: ext];
	}
    }
  else
    {
      name = [name stringByDeletingPathExtension];
      path = [self pathForResource: name ofType: ext];
    }
  return path;
}

@end

@interface	GSRepData : NSObject
{
@public
  NSImageRep	*rep;
  NSImageRep	*original;
  NSColor	*bg;
}
@end

@implementation	GSRepData
- (id) copyWithZone: (NSZone*)z
{
  GSRepData	*c = (GSRepData*)NSCopyObject(self, 0, z);

  if (c->rep)
    c->rep = [c->rep copyWithZone: z];
  if (c->bg)
    c->bg = [c->bg copyWithZone: z];
  return c;
}

- (void) dealloc
{
  TEST_RELEASE(rep);
  TEST_RELEASE(bg);
  NSDeallocateObject(self);
  GSNOSUPERDEALLOC;
}
@end

/* Class variables and functions for class methods */
static NSMutableDictionary	*nameDict = nil;
static NSDictionary		*nsmapping = nil;
static NSColor			*clearColor = nil;
static Class			cachedClass = 0;
static Class			bitmapClass = 0;

static NSArray *iterate_reps_for_types(NSArray *imageReps, SEL method);

/* Find the GSRepData object holding a representation */
static GSRepData*
repd_for_rep(NSArray *_reps, NSImageRep *rep)
{
  NSEnumerator	*enumerator = [_reps objectEnumerator];
  IMP		nextImp = [enumerator methodForSelector: @selector(nextObject)];
  GSRepData	*repd;

  while ((repd = (*nextImp)(enumerator, @selector(nextObject))) != nil)
    {
      if (repd->rep == rep)
	{
	  return repd;
	}
    }
  [NSException raise: NSInternalInconsistencyException
	      format: @"Cannot find stored representation"];
  /* NOT REACHED */
  return nil;
}

@interface NSImage (Private)
- (BOOL) _useFromFile: (NSString *)fileName;
- (BOOL) _loadFromData: (NSData *)data;
- (BOOL) _loadFromFile: (NSString *)fileName;
- (NSImageRep*) _cacheForRep: (NSImageRep*)rep;
- (NSImageRep*) _doImageCache;
@end

@implementation NSImage

+ (void) initialize
{
  if (self == [NSImage class])
    {
      NSString *path = [NSBundle pathForLibraryResource: @"nsmapping"
				                 ofType: @"strings"
				             inDirectory: @"Images"];

      // Initial version
      [self setVersion: 1];

      // initialize the class variables
      nameDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
      if (path)
	nsmapping = RETAIN([[NSString stringWithContentsOfFile: path]
				propertyListFromStringsFileFormat]);
      clearColor = RETAIN([NSColor clearColor]);
      cachedClass = [NSCachedImageRep class];
      bitmapClass = [NSBitmapImageRep class];
    }
}

/** <p>Returns the NSImage named aName. The search is done in the main bundle
    first and then in the usual images directories</p>
 */
+ (id) imageNamed: (NSString *)aName
{
  NSString	*realName = [nsmapping objectForKey: aName];
  NSImage	*image;

  if (realName)
    aName = realName;

  image = (NSImage*)[nameDict objectForKey: aName];
 
  if (image == nil)
    {
      NSString	*ext;
      NSString	*path = nil;
      NSBundle	*main_bundle;
      NSArray	*array;
      NSString	*the_name = aName;

      // FIXME: This should use [NSBundle pathForImageResource], but this will 
      // only allow imageUnfilteredFileTypes.
      /* If there is no image with that name, search in the main bundle */
      main_bundle = [NSBundle mainBundle];
      ext = [aName pathExtension];
      if (ext != nil && [ext length] == 0)
	{
	  ext = nil;
	}

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
	      path = [main_bundle pathForResource: the_name 
		        ofType: o];
	      if (path != nil && [path length] != 0)
		break;
	    }
	}

      /* If not found then search in system */
      if (!path)
	{
	  if (ext)
	    {
	      path = [NSBundle pathForLibraryResource: the_name
				               ofType: ext
				          inDirectory: @"Images"];
	    }
	  else 
	    {
	      id o, e;

	      e = [array objectEnumerator];
	      while ((o = [e nextObject]))
		{
		  path = [NSBundle pathForLibraryResource: the_name
			       	                   ofType: o
				              inDirectory: @"Images"];
		  if (path != nil && [path length] != 0)
		    break;
		}
	    }
	}

      if ([path length] != 0) 
	{
	  image = [[self allocWithZone: NSDefaultMallocZone()]
		initByReferencingFile: path];
	  if (image != nil)
	    {
	      [image setName: aName];
	      RELEASE(image);		// Retained in dictionary.
	      image->_flags.archiveByName = YES;
	    }
	  return image;
	}
    }
  
  return image;
}

+ (NSImage *) _standardImageWithName: (NSString *)name
{
  NSImage	*image = nil;

  image = [NSImage imageNamed: name];
  if (image == nil)
    image = [NSImage imageNamed: [@"common_" stringByAppendingString: name]];
  return image;
}

- (id) init
{
  return [self initWithSize: NSMakeSize(0, 0)];
}

/** <p>Initialize and returns a new NSImage with <var>aSize</var> as specified
    size.</p><p>See Also: -setSize: -size </p>
 */
- (id) initWithSize: (NSSize)aSize
{
  [super init];

  //_flags.archiveByName = NO;
  //_flags.scalable = NO;
  //_flags.dataRetained = NO;
  //_flags.flipDraw = NO;
  if (aSize.width && aSize.height) 
    {
      _size = aSize;
      _flags.sizeWasExplicitlySet = YES;
    }
  //_flags.usesEPSOnResolutionMismatch = NO;
  _flags.colorMatchPreferred = YES;
  _flags.multipleResolutionMatching = YES;
  //_flags.cacheSeparately = NO;
  //_flags.unboundedCacheDepth = NO;
  //_flags.syncLoad = NO;
  _reps = [[NSMutableArray alloc] initWithCapacity: 2];
  ASSIGN(_color, clearColor);
  _cacheMode = NSImageCacheDefault;
  
  return self;
}

- (id) initByReferencingFile: (NSString *)fileName
{
  self = [self init];

  if (![self _useFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }
  _flags.archiveByName = YES;

  return self;
}


/** <p>Initializes and returns a new NSImage from the file 
    <var>fileName</var>. <var>fileName</var> should be an absolute path.</p>
    <p>See Also: [NSImageRep+imageRepsWithContentsOfFile:]</p>
 */
- (id) initWithContentsOfFile: (NSString *)fileName
{
  if ( ! ( self = [self init] ) )
    return nil;

  _flags.dataRetained = YES;
  if (![self _loadFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

/**<p>Initializes and returns a new NSImage from the NSData data.</p>
   <p>See Also: [NSImageRep+imageRepWithData:]</p>
 */
- (id) initWithData: (NSData *)data
{
  if (! ( self = [self init] ) )
    return nil;

  _flags.dataRetained = YES;
  if (![self _loadFromData: data])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

- (id)initWithBitmapHandle:(void *)bitmap
{
  NSImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapHandle: bitmap];
  
  if (rep == nil)
    {
      RELEASE(self);
      return nil;
    }
  self = [self init];
  [self addRepresentation: rep];
  RELEASE(rep);
  return self;
}

- (id)initWithIconHandle:(void *)icon
{
  // Only needed on MS Windows
  NSImageRep *rep = [[NSBitmapImageRep alloc] initWithIconHandle: icon];
  
  if (rep == nil)
    {
      RELEASE(self);
      return nil;
    }
  self = [self init];
  [self addRepresentation: rep];
  RELEASE(rep);
  return self;
}

- (id)initWithContentsOfURL:(NSURL *)anURL
{
  NSArray *array = [NSImageRep imageRepsWithContentsOfURL: anURL];

  if (!array)
    {
      RELEASE(self);
      return nil;
    }
  self = [self init];
  _flags.dataRetained = YES;
  [self addRepresentations: array];
  return self;
}

/** <p>Initializes and returns a new NSImage from the data in pasteboard.
    the pasteboard types can be whose defined in  
    [NSImageRep+imagePasteboardTypes] or NSFilenamesPboardType</p>
    <p>See Also: [NSImageRep+imageRepsWithPasteboard:</p>
 */
- (id) initWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray *reps;

  if ( ! ( self = [self init] ) )
    return nil;
  
  reps = [NSImageRep imageRepsWithPasteboard: pasteboard];

  if (reps != nil)
    [self addRepresentations: reps]; 
  else
    {
      NSArray *array = [pasteboard propertyListForType: NSFilenamesPboardType];
      NSString* file; 
      
      if ((array == nil) || ([array count] == 0) ||
	  (file = [array objectAtIndex: 0]) == nil || 
	  ![self _loadFromFile: file])
        {
	  RELEASE(self);
	  return nil;
	} 
    }
  _flags.dataRetained = YES;
  
  return self;
}

- (void) dealloc
{
  RELEASE(_reps);
  /* Make sure we don't remove name from the nameDict if we are just a copy
     of the named image, not the original image */
  if (_name && self == [nameDict objectForKey: _name]) 
    [nameDict removeObjectForKey: _name];
  RELEASE(_name);
  TEST_RELEASE(_fileName);
  RELEASE(_color);

  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  NSImage	*copy;
  NSArray *reps = [self representations];
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSImageRep *rep;

  copy = (NSImage*)NSCopyObject (self, 0, zone);

  RETAIN(_name);
  RETAIN(_fileName);
  RETAIN(_color);
  copy->_lockedView = nil;
  // FIXME: maybe we should retain if _flags.dataRetained = NO
  copy->_reps = [[NSMutableArray alloc] initWithCapacity: [_reps count]];

  //  Only copy non-cached reps.
  while ((rep = [enumerator nextObject]) != nil)
    {
      if (![rep isKindOfClass: cachedClass])
        {
	  [copy addRepresentation: rep];
	}
    }
  
  return copy;
}

- (BOOL) setName: (NSString *)aName
{
  BOOL retained = NO;
  
  if (!aName || [nameDict objectForKey: aName])
    return NO;

  if (_name && self == [nameDict objectForKey: _name])
    {
      /* We retain self in case removing from the dictionary releases
         us */
      RETAIN (self);
      retained = YES;
      [nameDict removeObjectForKey: _name];
    }
  
  ASSIGN(_name, aName);
  
  [nameDict setObject: self forKey: _name];
  if (retained)
    {
      RELEASE (self);
    }
  
  return YES;
}

- (NSString *) name
{
  return _name;
}

/** <p>Sets the NSImage size to aSize. Changing the size recreate
    the cache</p>
    <p>See Also: -size -initWithSize:</p>
 */
- (void) setSize: (NSSize)aSize
{
  // Optimized as this is called very often from NSImageCell
  if (NSEqualSizes(_size, aSize))
    return;

  _size = aSize;
  _flags.sizeWasExplicitlySet = YES;

  [self recache];
}

/**<p> Returns NSImage size if the size have been set. Returns the
   size of the best representation otherwise.</p>
   <p>See Also: -setSize: -initWithSize:</p>
 */
- (NSSize) size
{
  if (_size.width == 0) 
    {
      NSImageRep *rep = [self bestRepresentationForDevice: nil];

      if (rep)
	_size = [rep size];
      else
	_size = NSZeroSize;
    }
  return _size;
}

- (BOOL) isFlipped
{
  return _flags.flipDraw;
}

- (void) setFlipped: (BOOL)flag
{
  _flags.flipDraw = flag;
}

// Choosing Which Image Representation to Use 
- (void) setUsesEPSOnResolutionMismatch: (BOOL)flag
{
  _flags.useEPSOnResolutionMismatch = flag;
}

- (BOOL) usesEPSOnResolutionMismatch
{
  return _flags.useEPSOnResolutionMismatch;
}

- (void) setPrefersColorMatch: (BOOL)flag
{
  _flags.colorMatchPreferred = flag;
}

- (BOOL) prefersColorMatch
{
  return _flags.colorMatchPreferred;
}

- (void) setMatchesOnMultipleResolution: (BOOL)flag
{
  _flags.multipleResolutionMatching = flag;
}

- (BOOL) matchesOnMultipleResolution
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

- (void) setCacheMode: (NSImageCacheMode)mode
{
  _cacheMode = mode;
}

- (NSImageCacheMode) cacheMode
{
  return _cacheMode;
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

      if (repd->bg != nil || [repd->rep isKindOfClass: cachedClass] == NO)
	{
	  valid = YES;
	  break;
	}
    }
  return valid;
}

- (void) recache
{
  unsigned i;

  i = [_reps count];
  while (i--) 
    {
      GSRepData	*repd;

      repd = (GSRepData*)[_reps objectAtIndex: i];
      if (repd->original != nil)
	{
	  [_reps removeObjectAtIndex: i];
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

/**<p>Sets the color of the NSImage's background to <var>aColor</var></p>
   <p>See Also: -backgroundColor</p>
 */
- (void) setBackgroundColor: (NSColor *)aColor
{
  if (aColor == nil)
    {
      aColor = clearColor;
    }
  ASSIGN(_color, aColor);
}

/**<p>Returns the color of the NSImage's background</p>
   <p>See Also: -setBackgroundColor:</p>
 */
- (NSColor *) backgroundColor
{
  return _color;
}


// Using the Image 
- (void) compositeToPoint: (NSPoint)aPoint 
		operation: (NSCompositingOperation)op
{
  NSRect rect;
  // Might not be computed up to now
  NSSize size = [self size];

  rect = NSMakeRect(0, 0, size.width, size.height);
  [self compositeToPoint: aPoint fromRect: rect operation: op];
}

- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)aRect
		operation: (NSCompositingOperation)op
{
#if 0
  [self compositeToPoint: aPoint
	fromRect: aRect
	operation: op
	fraction: 1.0];
#else 
  NSImageRep *rep = nil;

  NS_DURING
    { 
      if ([GSCurrentContext() isDrawingToScreen] == YES)
	  rep = [self _doImageCache];
      if (rep
	  &&_cacheMode != NSImageCacheNever 
	  && [rep isKindOfClass: cachedClass])
        {
	  NSRect rect;
	  float y = aPoint.y;

	  rect = [(NSCachedImageRep *)rep rect];
	  NSDebugLLog(@"NSImage", @"composite rect %@ in %@", 
		      NSStringFromRect(rect), NSStringFromRect(aRect));
	  // Move the drawing rectangle to the origin of the image rep
	  // and intersect the two rects.
	  aRect.origin.x += rect.origin.x;
	  aRect.origin.y += rect.origin.y;
	  rect = NSIntersectionRect(aRect, rect);

	  PScomposite(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect),
	    [[(NSCachedImageRep *)rep window] gState], aPoint.x, y, op);
	}
      else	
        {
	  NSRect rect;
          rep = [self bestRepresentationForDevice: nil];
	  rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);
	  [self drawRepresentation: rep inRect: rect];
	}
    }
  NS_HANDLER
    {
      NSLog(@"NSImage: compositeToPoint:fromRect:operation: failed due to %@: %@", 
	    [localException name], [localException reason]);
      if ([_delegate respondsToSelector: @selector(imageDidNotDraw:inRect:)])
        {
	  NSImage *image = [_delegate imageDidNotDraw: self inRect: aRect];

	  if (image != nil)
	    [image compositeToPoint: aPoint
		   fromRect: aRect 
		   operation: op];
	}
    }
  NS_ENDHANDLER
#endif
}

- (void) compositeToPoint: (NSPoint)aPoint
		operation: (NSCompositingOperation)op
		 fraction: (float)delta
{
  NSRect rect;
  NSSize size = [self size];

  rect = NSMakeRect(0, 0, size.width, size.height);
  [self compositeToPoint: aPoint fromRect: rect 
	operation: op fraction: delta];
}

- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)aRect
		operation: (NSCompositingOperation)op
		 fraction: (float)delta
{
  NSImageRep *rep = nil;

  NS_DURING
    { 
      if ([GSCurrentContext() isDrawingToScreen] == YES)
	  rep = [self _doImageCache];
      if (rep
	  &&_cacheMode != NSImageCacheNever 
	  && [rep isKindOfClass: cachedClass])
        {
	  NSRect rect;

	  rect = [(NSCachedImageRep *)rep rect];
	  NSDebugLLog(@"NSImage", @"composite rect %@ in %@", 
		      NSStringFromRect(rect), NSStringFromRect(aRect));
	  // Move the drawing rectangle to the origin of the image rep
	  // and intersect the two rects.
	  aRect.origin.x += rect.origin.x;
	  aRect.origin.y += rect.origin.y;
	  rect = NSIntersectionRect(aRect, rect);

	  [GSCurrentContext() GScomposite: [[(NSCachedImageRep *)rep window] gState]
			   toPoint: aPoint
			   fromRect: rect
			   operation: op
			   fraction: delta];
	}
      else	
        {
	  NSRect rect;
          rep = [self bestRepresentationForDevice: nil];
	  rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);
	  [self drawRepresentation: rep inRect: rect];
	}
    }
  NS_HANDLER
    {
      NSLog(@"NSImage: compositeToPoint:fromRect:operation:fraction: failed due to %@: %@", 
	    [localException name], [localException reason]);
      if ([_delegate respondsToSelector: @selector(imageDidNotDraw:inRect:)])
        {
	  NSImage *image = [_delegate imageDidNotDraw: self inRect: aRect];

	  if (image != nil)
	    [image compositeToPoint: aPoint
		   fromRect: aRect 
		   operation: op
		   fraction: delta];
	}
    }
  NS_ENDHANDLER
}

- (void) dissolveToPoint: (NSPoint)aPoint fraction: (float)aFloat
{
  NSRect rect;
  NSSize size = [self size];

  rect = NSMakeRect(0, 0, size.width, size.height);
  [self dissolveToPoint: aPoint fromRect: rect fraction: aFloat];
}

- (void) dissolveToPoint: (NSPoint)aPoint
		fromRect: (NSRect)aRect 
		fraction: (float)aFloat
{
#if 0
  [self compositeToPoint: aPoint
	fromRect: aRect
	operation: NSCompositeSourceOver
	fraction: aFloat];
#else 
  NSImageRep *rep = nil;

  NS_DURING
    {
      if ([GSCurrentContext() isDrawingToScreen] == YES)
	  rep = [self _doImageCache];
      if (rep
	  &&_cacheMode != NSImageCacheNever 
	  && [rep isKindOfClass: cachedClass])
        {
	  NSRect rect;
	  float y = aPoint.y;

	  rect = [(NSCachedImageRep *)rep rect];
	  // Move the drawing rectangle to the origin of the image rep
	  // and intersect the two rects.
	  aRect.origin.x += rect.origin.x;
	  aRect.origin.y += rect.origin.y;
	  rect = NSIntersectionRect(aRect, rect);
	  PSdissolve(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect),
	    [[(NSCachedImageRep *)rep window] gState], aPoint.x, y, aFloat);
	}
      else
        {
	  NSRect rect;

	  /* FIXME: Here we are supposed to composite directly from the source
	     but how do you do that? */
          rep = [self bestRepresentationForDevice: nil];
	  rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);
	  [self drawRepresentation: rep inRect: rect];
	}
    }
  NS_HANDLER
    {
      NSLog(@"NSImage: dissolve failed due to %@: %@", 
	    [localException name], [localException reason]);
      if ([_delegate respondsToSelector: @selector(imageDidNotDraw:inRect:)])
        {
	  NSImage *image = [_delegate imageDidNotDraw: self inRect: aRect];

	  if (image != nil)
	    [image dissolveToPoint: aPoint
		   fromRect: aRect 
		   fraction: aFloat];
	}
    }
  NS_ENDHANDLER
#endif
}

- (BOOL) drawRepresentation: (NSImageRep *)imageRep inRect: (NSRect)aRect
{
  BOOL r;

  PSgsave();

  if (_color != nil)
    {
      NSRect fillrect = aRect;
      [_color set];
      if ([[NSView focusView] isFlipped])
	fillrect.origin.y -= _size.height;
      NSRectFill(fillrect);
      if ([GSCurrentContext() isDrawingToScreen] == NO)
	{
	  /* Reset alpha for image drawing. */
	  [[NSColor whiteColor] set];
	}
    }

  if (!_flags.scalable)
    r = [imageRep drawAtPoint: aRect.origin];
  else
    r = [imageRep drawInRect: aRect];

  PSgrestore();

  return r;
}

- (void) drawAtPoint: (NSPoint)point
	    fromRect: (NSRect)srcRect
	   operation: (NSCompositingOperation)op
	    fraction: (float)delta
{
  [self drawInRect: NSMakeRect(point.x, point.y, srcRect.size.width,
			       srcRect.size.height)
	  fromRect: srcRect
	 operation: op
	  fraction: delta];
}

- (void) drawInRect: (NSRect)dstRect
	   fromRect: (NSRect)srcRect
	  operation: (NSCompositingOperation)op
	   fraction: (float)fraction
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSAffineTransform *transform;

  if (!dstRect.size.width || !dstRect.size.height
      || !srcRect.size.width || !srcRect.size.height)
    return;

  if (![ctxt isDrawingToScreen])
    {
      /* We can't composite or dissolve if we aren't drawing to a screen,
	 so we'll just draw the right part of the image in the right
	 place. */
      NSSize s;
      NSPoint p;
      double fx, fy;

      s = [self size];

      fx = dstRect.size.width / srcRect.size.width;
      fy = dstRect.size.height / srcRect.size.height;

      p.x = dstRect.origin.x / fx - srcRect.origin.x;
      p.y = dstRect.origin.y / fy - srcRect.origin.y;

      DPSgsave(ctxt);
      DPSrectclip(ctxt, dstRect.origin.x, dstRect.origin.y,
		  dstRect.size.width, dstRect.size.height);
      DPSscale(ctxt, fx, fy);
      [self drawRepresentation: [self bestRepresentationForDevice: nil]
			inRect: NSMakeRect(p.x, p.y, s.width, s.height)];
      DPSgrestore(ctxt);

      return;
    }

  /* Figure out what the effective transform from image space to
     'window space' is.  */
  transform = [ctxt GSCurrentCTM];

  [transform scaleXBy: dstRect.size.width / srcRect.size.width
		  yBy: dstRect.size.height / srcRect.size.height];


  /* If the effective transform is the identity transform and there's
     no dissolve, we can composite from our cache.  */
  if (fraction == 1.0
      && fabs(transform->matrix.m11 - 1.0) < 0.01
      && fabs(transform->matrix.m12) < 0.01
      && fabs(transform->matrix.m21) < 0.01
      && fabs(transform->matrix.m22 - 1.0) < 0.01)
    {
      [self compositeToPoint: dstRect.origin
		    fromRect: srcRect
		   operation: op];
      return;
    }

  /* We can't composite or dissolve directly from the image reps, so we
     create a temporary off-screen window large enough to hold the
     transformed image, draw the image rep there, and composite from there
     to the destination.

     Optimization: Since we do the entire image at once, we might need a
     huge buffer.  If this starts hurting too much, there are a couple of
     things we could do to:

     1. Take srcRect into account and only process the parts of the image
	we really need.
     2. Take the clipping path into account.  Desirable, especially if we're
	being drawn as lots of small strips in a scrollview.  We don't have
	the clipping path here, though.
     3. Allocate a permanent but small buffer and process the image
	piecewise.

     */
  {
    NSCachedImageRep *cache;
    NSSize s;
    NSPoint p;
    double x0, y0, x1, y1, w, h;
    int gState;

    s = [self size];

    /* Figure out how big we need to make the window that'll hold the
       transformed image.  */
    p = [transform transformPoint: NSMakePoint(0, s.height)];
    x0 = x1 = p.x;
    y0 = y1 = p.y;

    p = [transform transformPoint: NSMakePoint(s.width, 0)];
    x0 = gs_min(x0, p.x);
    y0 = gs_min(y0, p.y);
    x1 = gs_max(x1, p.x);
    y1 = gs_max(y1, p.y);

    p = [transform transformPoint: NSMakePoint(s.width, s.height)];
    x0 = gs_min(x0, p.x);
    y0 = gs_min(y0, p.y);
    x1 = gs_max(x1, p.x);
    y1 = gs_max(y1, p.y);

    p = [transform transformPoint: NSMakePoint(0, 0)];
    x0 = gs_min(x0, p.x);
    y0 = gs_min(y0, p.y);
    x1 = gs_max(x1, p.x);
    y1 = gs_max(y1, p.y);

    x0 = floor(x0);
    y0 = floor(y0);
    x1 = ceil(x1);
    y1 = ceil(y1);

    w = x1 - x0;
    h = y1 - y0;

    /* This is where we want the origin of image space to be in our
       window.  */
    p.x -= x0;
    p.y -= y0;

    cache = [[NSCachedImageRep alloc]
		initWithSize: NSMakeSize(w, h)
		       depth: [[NSScreen mainScreen] depth]
		    separate: YES
		       alpha: YES];

    [[[cache window] contentView] lockFocus];

    DPScompositerect(ctxt, 0, 0, w, h, NSCompositeClear);

    /* Set up the effective transform.  We also save a gState with this
       transform to make it easier to do the final composite.  */
    transform->matrix.tX = p.x;
    transform->matrix.tY = p.y;
    [ctxt GSSetCTM: transform];

    gState = [ctxt GSDefineGState];

    [self drawRepresentation: [self bestRepresentationForDevice: nil]
		      inRect: NSMakeRect(0, 0, s.width, s.height)];

    /* If we're doing a dissolve, use a DestinationIn composite to lower
       the alpha of the pixels.  */
    if (fraction != 1.0)
      {
	DPSsetalpha(ctxt, fraction);
	DPScompositerect(ctxt, 0, 0, s.width, s.height,
			 NSCompositeDestinationIn);
      }

    [[[cache window] contentView] unlockFocus];


    DPScomposite(ctxt, srcRect.origin.x, srcRect.origin.y,
		 srcRect.size.width, srcRect.size.height, gState,
		 dstRect.origin.x, dstRect.origin.y, op);

    [ctxt GSUndefineGState: gState];

    DESTROY(cache);
  }
}

/** <p>Adds the NSImageRep imageRep to the NSImage's representations array.
    </p><p>See Also: -addRepresentations: removeRepresentation:</p>
 */

- (void) addRepresentation: (NSImageRep *)imageRep
{
  GSRepData	*repd;

  repd = [GSRepData new];
  repd->rep = RETAIN(imageRep);
  [_reps addObject: repd]; 
  RELEASE(repd);
}

/** <p>Adds the NSImageRep array imageRepArray to the NSImage's
    representations array.</p>
    <p>See Also: -addRepresentation: -removeRepresentation:</p>
 */
- (void) addRepresentations: (NSArray *)imageRepArray
{
  unsigned	i, count;
  GSRepData	*repd;

  count = [imageRepArray count];
  for (i = 0; i < count; i++)
    {
      repd = [GSRepData new];
      repd->rep = RETAIN([imageRepArray objectAtIndex: i]);
      [_reps addObject: repd]; 
      RELEASE(repd);
    }
}

/** <p>Remove the NSImageRep imageRep from the NSImage's representations 
    array</p><p>See Also: -addRepresentations: -addRepresentation:</p>
 */
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

/** <p>Locks the focus on the best representation</p>
    <p>See Also: -lockFocusOnRepresentation:</p>
 */
- (void) lockFocus
{
  [self lockFocusOnRepresentation: nil];
}

/**<p>Locks the focus in the imageRep. if imageRep is nil this method
   locks the focus on the best representation</p>
 */
- (void) lockFocusOnRepresentation: (NSImageRep *)imageRep
{
  if (_cacheMode != NSImageCacheNever)
    {
      NSWindow	*window;
      GSRepData *repd;

      if (imageRep == nil)
	imageRep = [self bestRepresentationForDevice: nil];

      imageRep = [self _cacheForRep: imageRep];
      repd = repd_for_rep(_reps, imageRep);

      window = [(NSCachedImageRep *)imageRep window];
      _lockedView = [window contentView];
      if (_lockedView == nil)
	[NSException raise: NSImageCacheException
		     format: @"Cannot lock focus on nil rep"];
      [_lockedView lockFocus];

      /* Validate cached image */
      if (repd->bg == nil)
	{
	  repd->bg = [_color copy];
	  [_color set];
	  
	  if ([_color alphaComponent] < 1)
	    {
	      /* With a Quartz-like alpha model, alpha can't be cleared
	         with a rectfill, so we need to clear the alpha channel
		 explictly. (A compositerect with NSCompositeCopy would
		 be more efficient, but it doesn't seem like it's 
		 implemented correctly in all backends yet (as of 
		 2002-08-23). Also, this will work with both the Quartz-
		 and DPS-model.) */
	      PScompositerect(0, 0, _size.width, _size.height,
			      NSCompositeClear);
	    }
	  NSRectFill(NSMakeRect(0, 0, _size.width, _size.height));
	}
    }
}

- (void) unlockFocus
{
  if (_lockedView != nil)
    {
      [_lockedView unlockFocus];
      _lockedView = nil;
    }
}

/* Determine if the device is color or gray scale and find the reps of
   the same type
*/
- (NSMutableArray *) _bestRep: (NSArray *)reps 
	       withColorMatch: (NSDictionary*)deviceDescription
{
  int colors = 3;
  NSImageRep* rep;
  NSMutableArray *breps;
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSString *colorSpace = [deviceDescription objectForKey: NSDeviceColorSpaceName];
  
  if (colorSpace != nil)
    colors = NSNumberOfColorComponents(colorSpace);
  
  breps = [NSMutableArray array];
  while ((rep = [enumerator nextObject]) != nil)
    {
      if ([rep colorSpaceName] || abs(NSNumberOfColorComponents([rep colorSpaceName]) - colors) <= 1)
        [breps addObject: rep];
    }
  
  /* If there are no matches, pass all the reps */
  if ([breps count] == 0)
    return (NSMutableArray *)reps;
  return breps;
}

/* Find reps that match the resolution of the device or return the rep
   that has the highest resolution */
- (NSMutableArray *) _bestRep: (NSArray *)reps 
	  withResolutionMatch: (NSDictionary*)deviceDescription
{
  NSImageRep* rep;
  NSMutableArray *breps;
  NSSize dres;
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSValue *resolution = [deviceDescription objectForKey: NSDeviceResolution];

  if (resolution)
    dres = [resolution sizeValue];
  else
    dres = NSMakeSize(0, 0);

  breps = [NSMutableArray array];
  while ((rep = [enumerator nextObject]) != nil)
    {
      /* FIXME: Not sure about checking resolution */
      [breps addObject: rep];
    }
  
  /* If there are no matches, pass all the reps */
  if ([breps count] == 0)
    return (NSMutableArray *)reps;
  return breps;
}

/* Find reps that match the bps of the device or return the rep that
   has the highest bps */
- (NSMutableArray *) _bestRep: (NSArray *)reps 
		 withBpsMatch: (NSDictionary*)deviceDescription
{
  NSImageRep* rep, *max_rep;
  NSMutableArray *breps;
  NSEnumerator *enumerator = [reps objectEnumerator];
  int bps = [[deviceDescription objectForKey: NSDeviceBitsPerSample] intValue];
  int max_bps;

  breps = [NSMutableArray array];
  max_bps = 0;
  max_rep = nil;
  while ((rep = [enumerator nextObject]) != nil)
    {
      int rep_bps = 0;
      if ([rep respondsToSelector: @selector(bitsPerPixel)])
        rep_bps = [(NSBitmapImageRep *)rep bitsPerPixel];
      if (rep_bps > max_bps)
        {
          max_bps = rep_bps;
          max_rep = rep;
        }
      if (rep_bps == bps)
        [breps addObject: rep];
    }
  

  if ([breps count] == 0 && max_rep != nil)
    [breps addObject: max_rep];

  /* If there are no matches, pass all the reps */
  if ([breps count] == 0)
    return (NSMutableArray *)reps;
  return breps;
}

- (NSMutableArray *) _representationsWithCachedImages: (BOOL)flag
{
  unsigned	count;

  if (_flags.syncLoad)
    {
      /* Make sure any images that were added with _useFromFile: are loaded
	 in and added to the representation list. */
      [self _loadFromFile: _fileName];
      _flags.syncLoad = NO;
    }

  count = [_reps count];
  if (count == 0)
    {
      return [NSArray array];
    }
  else
    {
      id	repList[count];
      unsigned	i, j;

      [_reps getObjects: repList];
      j = 0;
      for (i = 0; i < count; i++) 
	{
          if (flag || ((GSRepData*)repList[i])->original == nil)
            {
              repList[j] = ((GSRepData*)repList[i])->rep;
              j++;
            }
	}
      return [NSArray arrayWithObjects: repList count: j];
    }
}

- (NSImageRep*) bestRepresentationForDevice: (NSDictionary*)deviceDescription
{
  NSMutableArray *reps = [self _representationsWithCachedImages: NO];
  
  if (deviceDescription == nil)
    {
      if ([GSCurrentContext() isDrawingToScreen] == YES)
        {
	    // Take the device description from the current context.
	    deviceDescription = [GSCurrentContext() attributes];
        }
      else if ([NSPrintOperation currentOperation])
        {
          /* FIXME: We could try to use the current printer, 
	     but there are many cases where might
             not be printing (EPS, PDF, etc) to a specific device */
        }
    }

  if (_flags.colorMatchPreferred == YES)
    {
      reps = [self _bestRep: reps withColorMatch: deviceDescription];
      reps = [self _bestRep: reps withResolutionMatch: deviceDescription];
    }
  else
    {
      reps = [self _bestRep: reps withResolutionMatch: deviceDescription];
      reps = [self _bestRep: reps withColorMatch: deviceDescription];
    }
  reps = [self _bestRep: reps withBpsMatch: deviceDescription];
  /* Pick an arbitrary representation if there is more than one */
  return [reps lastObject];
}

- (NSArray *) representations
{
  return [self _representationsWithCachedImages: YES];
}

- (void) setDelegate: anObject
{
  _delegate = anObject;
}

- (id) delegate
{
  return _delegate;
}

// Producing TIFF Data for the Image 
- (NSData *) TIFFRepresentation
{
  return [bitmapClass TIFFRepresentationOfImageRepsInArray: [self representations]];
}

- (NSData *) TIFFRepresentationUsingCompression: (NSTIFFCompression)comp
	factor: (float)aFloat
{
  return [bitmapClass TIFFRepresentationOfImageRepsInArray: [self representations]
		      usingCompression: comp
		      factor: aFloat];
}

// NSCoding
- (void) encodeWithCoder: (NSCoder*)coder
{
  BOOL	flag;

  if([coder allowsKeyedCoding])
    {
      // FIXME: Not sure this is the way it goes...
      /*
      if(_flags.archiveByName == NO)
	{
	  NSMutableArray *container = [NSMutableArray array];
	  NSMutableArray *reps = [NSMutableArray array];
	  NSEnumerator *en = [_reps objectEnumerator];
	  GSRepData *rd = nil;

	  // add the reps to the container...
	  [container addObject: reps];
	  while((rd = [en nextObject]) != nil)
	    {
	      [reps addObject: rd->rep];
	    }
	  [coder encodeObject: container forKey: @"NSReps"];
	}
      else
	{
	  [coder encodeObject: _name forKey: @"NSImageName"];
	}
      */

      // encode the rest...
      [coder encodeObject: _color forKey: @"NSColor"];
      [coder encodeInt: 0 forKey: @"NSImageFlags"]; // zero...
      [coder encodeSize: _size forKey: @"NSSize"];
    }
  else
    {
      flag = _flags.archiveByName;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag == YES)
	{
	  /*
	   * System image - just encode the name.
	   */
	  [coder encodeValueOfObjCType: @encode(id) at: &_name];
	}
      else
	{
	  NSMutableArray	*a;
	  NSEnumerator	*e;
	  NSImageRep	*r;
	  
	  /*
	   * Normal image - encode the ivars
	   */
	  [coder encodeValueOfObjCType: @encode(NSSize) at: &_size];
	  [coder encodeValueOfObjCType: @encode(id) at: &_color];
	  flag = _flags.scalable;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.dataRetained;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.flipDraw;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.sizeWasExplicitlySet;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.useEPSOnResolutionMismatch;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.colorMatchPreferred;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.multipleResolutionMatching;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.cacheSeparately;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  flag = _flags.unboundedCacheDepth;
	  [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
	  
	  // FIXME: The documentation says to archive only the file name,
	  // if not data retained!
	  /*
	   * Now encode an array of all the image reps (excluding cache)
	   */
	  a = [NSMutableArray arrayWithCapacity: 2];
	  e = [[self representations] objectEnumerator];
	  while ((r = [e nextObject]) != nil)
	    {
	      if ([r isKindOfClass: cachedClass] == NO)
		{
		  [a addObject: r];
		}
	    }
	  [coder encodeValueOfObjCType: @encode(id) at: &a];
	}
    }
}
- (id) initWithCoder: (NSCoder*)coder
{
  BOOL	flag;

  _reps = [[NSMutableArray alloc] initWithCapacity: 2];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSColor"])
        {
	  [self setBackgroundColor: [coder decodeObjectForKey: @"NSColor"]];
	}
      if ([coder containsValueForKey: @"NSImageFlags"])
        {
	  int flags;
	  
          //FIXME
	  flags = [coder decodeIntForKey: @"NSImageFlags"];
	}
      if ([coder containsValueForKey: @"NSReps"])
        {
	  NSArray *reps;

	  // FIXME: NSReps is in a strange format. It is a mutable array with one 
          // element which is an array with a first element 0 and than the image rep.  
	  reps = [coder decodeObjectForKey: @"NSReps"];
	  reps = [reps objectAtIndex: 0];
	  [self addRepresentation: [reps objectAtIndex: 1]];
	}
      if ([coder containsValueForKey: @"NSSize"])
        {
	  [self setSize: [coder decodeSizeForKey: @"NSSize"]];
	}
    }
  else
    {
      [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag == YES)
        {
	  NSString	*theName = [coder decodeObject];

	  RELEASE(self);
	  self = RETAIN([NSImage imageNamed: theName]);
	}
      else
        {
	  NSArray	*a;

	  [coder decodeValueOfObjCType: @encode(NSSize) at: &_size];
	  [coder decodeValueOfObjCType: @encode(id) at: &_color];
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.scalable = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.dataRetained = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.flipDraw = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.sizeWasExplicitlySet = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.useEPSOnResolutionMismatch = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.colorMatchPreferred = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.multipleResolutionMatching = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.cacheSeparately = flag;
	  [coder decodeValueOfObjCType: @encode(BOOL) at: &flag];
	  _flags.unboundedCacheDepth = flag;
	  
	  /*
	   * get the image reps and add them.
	   */
	  a = [coder decodeObject];
	  [self addRepresentations: a];
	}
    }
  return self;
}

- (id) awakeAfterUsingCoder: (NSCoder*)aDecoder
{
  if (_name && [nameDict objectForKey: _name]) 
    {
      return [nameDict objectForKey: _name];
    }
    
  return self;
}

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
static NSArray *
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

@implementation NSImage (Private)
    
- (BOOL)_loadFromData: (NSData *)data
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

- (BOOL) _loadFromFile: (NSString *)fileName
{
  NSArray* array;

  array = [NSImageRep imageRepsWithContentsOfFile: fileName];
  if (array)
    [self addRepresentations: array];

  return (array) ? YES : NO;
}

- (BOOL) _useFromFile: (NSString *)fileName
{
  NSArray	*array;
  NSString	*ext;
  NSFileManager *manager = [NSFileManager defaultManager];

  if ([manager fileExistsAtPath: fileName] == NO)
    {
      return NO;
    }

  ext = [fileName pathExtension];
  if (!ext)
    return NO;
  array = [isa imageFileTypes];
  if ([array indexOfObject: ext] == NSNotFound)
    return NO;

  ASSIGN(_fileName, fileName);
  _flags.syncLoad = YES;
  return YES;
}

// Cache the bestRepresentation.  If the bestRepresentation is not itself
// a cache and no cache exists, create one and draw the representation in it
// If a cache exists, but is not valid, redraw the cache from the original
// image (if there is one).
- (NSImageRep *)_doImageCache
{
  NSImageRep *rep = [self bestRepresentationForDevice: nil];

  if (_cacheMode != NSImageCacheNever)
    {
      GSRepData *repd;

      rep =  [self _cacheForRep: rep];
      repd = repd_for_rep(_reps, rep);

      NSDebugLLog(@"NSImage", @"Cached image rep is %p", rep);
      /*
       * if the cache is not valid, it's background color will not exist
       * and we must draw the background then render from the original
       * image rep into the cache.
       */
      if (repd->bg == nil) 
	{
	  [self lockFocusOnRepresentation: rep];
	  [self drawRepresentation: repd->original 
		inRect: NSMakeRect(0, 0, _size.width, _size.height)];
	  [self unlockFocus];

	  if (_color != nil && [_color alphaComponent] != 0.0)
	    {
	      repd->bg = [_color copy];
	    }
	  else
	    {
	      repd->bg = [clearColor copy];
	    }

	  if ([repd->bg alphaComponent] == 1.0)
	    {
	      [rep setOpaque: YES];
	    }
	  else
	    {
	      [rep setOpaque: [repd->original isOpaque]];
	    }
	  NSDebugLLog(@"NSImage", @"Rendered rep %p on background %@",
	    rep, repd->bg);
	}
    }
  
  return rep;
}

- (NSImageRep*) _cacheForRep: (NSImageRep*)rep
{
  /*
   * If this is not a cached image rep - create a cache to be used to
   * render the image rep into, and switch to the cached rep.
   */
  if ([rep isKindOfClass: cachedClass] == NO)
    {
      NSImageRep	*cacheRep = nil;
      unsigned		count = [_reps count];

      if (count > 0)
	{
	  GSRepData	*invalidCache = nil;
	  GSRepData	*partialCache = nil;
	  GSRepData	*validCache = nil;
	  GSRepData	*reps[count];
          unsigned	partialCount = 0;
	  unsigned	i;
	  BOOL		opaque = [rep isOpaque];

	  [_reps getObjects: reps];

	  /*
	   * Search the cached image reps for any whose original is our
	   * 'best' image rep.  See if we can notice any invalidated
	   * cache as we go - if we don't find a valid cache, we want to
	   * re-use an invalidated one rather than creating a new one.
	   * NB. If the image rep is opaque, then any cached rep is valid
	   * irrespective of the background color it was drawn with.
	   */
	  for (i = 0; i < count; i++)
	    {
	      GSRepData	*repd = reps[i];

	      if (repd->original == rep && repd->rep != rep)
		{
		  if (repd->bg == nil)
		    {
NSDebugLLog(@"NSImage", @"Invalid %@ ... %@ %d", repd->bg, _color, repd->rep);
		      invalidCache = repd;
		    }
		  else if (opaque == YES || [repd->bg isEqual: _color] == YES)
		    {
NSDebugLLog(@"NSImage", @"Exact %@ ... %@ %d", repd->bg, _color, repd->rep);
		      validCache = repd;
		      break;
		    }
		  else
		    {
NSDebugLLog(@"NSImage", @"Partial %@ ... %@ %d", repd->bg, _color, repd->rep);
		      partialCache = repd;
		      partialCount++;
		    }
		}
	    }

	  if (validCache != nil)
	    {
	      if (NSImageForceCaching == NO && [rep isOpaque] == NO)
		{
		  /*
		   * If the image rep is not opaque and we are drawing
		   * without an opaque background then the cache can't
		   * really be valid 'cos we might be drawing transparency
		   * on top of anything.  So we invalidate the cache by
		   * removing the background color information.
		   */
		  if ([validCache->bg alphaComponent] != 1.0)
		    {
		      DESTROY(validCache->bg);
		    }
		}
	      cacheRep = validCache->rep;
	    }
	  else if (partialCache != nil && partialCount > 2)
	    {
	      /*
	       * Only re-use partially correct caches if there are already
	       * a few partial matches - otherwise we fall default to
	       * creating a new cache.
	       */
	      if (NSImageForceCaching == NO && [rep isOpaque] == NO)
		{
		  if (invalidCache != nil)
		    {
		      /*
		       * If there is an unused cache - use it rather than
		       * re-using this one, since we might get a request
		       * to draw with this color again.
		       */
		      partialCache = invalidCache;
		    }
		  else
		    {
		      DESTROY(partialCache->bg);
		    }
		}
	      cacheRep = partialCache->rep;
	    }
	  else if (invalidCache != nil)
	    {
	      cacheRep = invalidCache->rep;
	    }
	}
      if (cacheRep == nil)
	{
	  NSScreen	*cur = [NSScreen mainScreen];
	  NSSize	imageSize;
	  GSRepData	*repd;

	  imageSize = [self size];
	  if (imageSize.width == 0 || imageSize.height == 0)
	    return nil;

	  cacheRep = [[cachedClass alloc] initWithSize: _size
						depth: [cur depth]
					     separate: NO
						alpha: NO];
	  [self addRepresentation: cacheRep];
	  RELEASE(cacheRep);		/* Retained in _reps array.	*/
          repd = repd_for_rep(_reps, cacheRep);
          repd->original = rep;
	}
      return cacheRep;
    }
  else
    {
      return rep;
    }
}

@end
