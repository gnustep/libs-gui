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
#include <AppKit/NSPasteboard.h>
#include <AppKit/PSOperators.h>

BOOL	NSImageDoesCaching = YES;	/* enable caching	*/
BOOL	NSImageForceCaching = NO;	/* use on missmatch	*/

// Resource directories
static NSString* gnustep_libdir = @GNUSTEP_INSTALL_LIBDIR;
static NSString* NSImage_PATH = @"Images";

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
}
@end

/* Class variables and functions for class methods */
static NSMutableDictionary	*nameDict = nil;
static NSDictionary		*nsmapping = nil;
static NSColor			*clearColor = nil;
static Class			cachedClass = 0;
static Class			bitmapClass = 0;

NSArray *iterate_reps_for_types(NSArray *imageReps, SEL method);

/* Find the GSRepData object holding a representation */
GSRepData*
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
      NSBundle	*system = [NSBundle bundleWithPath: gnustep_libdir];
      NSString	*path = [system pathForResource: @"nsmapping"
					 ofType: @"strings"
				    inDirectory: NSImage_PATH];
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

- (BOOL) isFlipped
{
  return _flags.flipDraw;
}

- (void) setFlipped: (BOOL)flag
{
  _flags.flipDraw = flag;
}

- (id) init
{
  return [self initWithSize: NSMakeSize(0, 0)];
}

// Designated initializer for nearly everything.
- (id) initWithSize: (NSSize)aSize
{
  [super init];
  _reps = [[NSMutableArray alloc] initWithCapacity: 2];
  if (aSize.width && aSize.height) 
    {
      _size = aSize;
      _flags.sizeWasExplicitlySet = YES;
    }
  _flags.colorMatchPreferred = YES;
  _flags.multipleResolutionMatching = YES;
  //_flags.usesEPSOnResolutionMismatch = NO;
  //_flags.flipDraw = NO;
  _color = RETAIN(clearColor);
  
  return self;
}

- (id) initByReferencingFile: (NSString *)fileName
{
  self = [self init];
  // FIXME: The documentation says to archive only the file name,
  // this has to be stored somewhere!
  _flags.dataRetained = YES;
  if (![self _useFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

- (id) initWithContentsOfFile: (NSString *)fileName
{
  self = [self init];
  //_flags.dataRetained = YES;
  if (![self _loadFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

- (id) initWithData: (NSData *)data;
{
  self = [self init];
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
  [self addRepresentations: array];
  return self;
}

- (id) initWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray *reps = [NSImageRep imageRepsWithPasteboard: pasteboard];
  self = [self init];

  if (reps != nil)
    [self addRepresentations: reps]; 
  else
    {
      NSString* file = [pasteboard propertyListForType: NSFilenamesPboardType];
      
      if (file != nil || ![self _loadFromFile: file])
        {
	  RELEASE(self);
	  return nil;
	} 
    }
  
  return self;
}

- (void) setSize: (NSSize)aSize
{
  _size = aSize;
  _flags.sizeWasExplicitlySet = YES;
  // TODO: This invalidates any cached data
}

- (NSSize) size
{
  if (_size.width == 0) 
    {
      NSImageRep *rep = [self bestRepresentationForDevice: nil];

      _size = [rep size];
    }
  return _size;
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

  // FIXME: maybe we should retain if _flags.dataRetained = NO
  copy = (NSImage*)NSCopyObject (self, 0, zone);

  RETAIN(_name);
  RETAIN(_fileName);
  RETAIN(_color);
  copy->_lockedView = nil;
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

- (BOOL) setName: (NSString *)string
{
  if (!string || [nameDict objectForKey: string])
    return NO;

  ASSIGN(_name, string);

  [nameDict setObject: self forKey: _name];
  return YES;
}

- (NSString *) name
{
  return _name;
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
  unsigned i, count;

  // FIXME: Not sure if this is correct
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      GSRepData	*repd;

      repd = (GSRepData*)[_reps objectAtIndex: i];
      if (repd->bg != nil)
	{
	  DESTROY(repd->bg);
	  [repd->rep setOpaque: YES];
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
  if (aColor == nil)
    {
      aColor = clearColor;
    }
  ASSIGN(_color, aColor);
}

- (NSColor *) backgroundColor
{
  return _color;
}


// Using the Image 
- (void) compositeToPoint: (NSPoint)aPoint 
		operation: (NSCompositingOperation)op;
{
  NSRect rect;
  // Might not be computed up to now
  NSSize size = [self size];

  rect = NSMakeRect(0, 0, size.width, size.height);
  [self compositeToPoint: aPoint fromRect: rect operation: op];
}

- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)aRect
		operation: (NSCompositingOperation)op;
{
  NSImageRep *rep;

  NS_DURING
    {
      rep = [self _doImageCache];
      
      if (NSImageDoesCaching == YES && [rep isKindOfClass: cachedClass])
        {
	  NSRect rect = [(NSCachedImageRep *)rep rect];
	  NSGraphicsContext *ctxt = GSCurrentContext();	  
	  float y = aPoint.y;

	  // FIXME: This undos the change done in NSCell, perhaps we can remove both?
	  if ([[ctxt focusView] isFlipped])
	    y -= rect.size.height;
	  
	  rect = NSIntersectionRect(aRect, rect);
	  PScomposite(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect),
	    [[(NSCachedImageRep *)rep window] gState], aPoint.x, y, op);
	}
      else	
        {
	  NSRect rect;

	  rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);
	  [self drawRepresentation: rep inRect: rect];
	}
    }
  NS_HANDLER
    {
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
}

- (void) dissolveToPoint: (NSPoint)aPoint fraction: (float)aFloat;
{
  NSRect rect;
  NSSize size = [self size];

  rect = NSMakeRect(0, 0, size.width, size.height);
  [self dissolveToPoint: aPoint fromRect: rect fraction: aFloat];
}

- (void) dissolveToPoint: (NSPoint)aPoint
		fromRect: (NSRect)aRect 
		fraction: (float)aFloat;
{
  NSImageRep *rep;

  NS_DURING
    {
      rep = [self _doImageCache];

      if (NSImageDoesCaching == YES && [rep isKindOfClass: cachedClass])
        {
	  NSRect rect = [(NSCachedImageRep *)rep rect];
	  NSGraphicsContext *ctxt = GSCurrentContext();	  
	  float y = aPoint.y;

	  if ([[ctxt focusView] isFlipped])
	    y -= rect.size.height;
	  // FIXME This should be able to cut out part of the image
	  PSdissolve(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect),
	    [[(NSCachedImageRep *)rep window] gState], aPoint.x, y, aFloat);
	}
      else
        {
	  NSRect rect;

	  rect = NSMakeRect(aPoint.x, aPoint.y, _size.width, _size.height);
	  [self drawRepresentation: rep inRect: rect];
	}
    }
  NS_HANDLER
    {
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
}

- (BOOL) drawRepresentation: (NSImageRep *)imageRep inRect: (NSRect)aRect
{
  if (!_flags.scalable) 
    return [imageRep drawAtPoint: aRect.origin];
  return [imageRep drawInRect: aRect];
}

- (void) addRepresentation: (NSImageRep *)imageRep
{
  GSRepData	*repd;

  repd = [GSRepData new];
  repd->rep = RETAIN(imageRep);
  [_reps addObject: repd]; 
  RELEASE(repd);
}

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
  [self lockFocusOnRepresentation: nil];
}

- (void) lockFocusOnRepresentation: (NSImageRep *)imageRep
{
  if (NSImageDoesCaching == YES)
    {
      NSWindow	*window;

      imageRep = [self _cacheForRep: imageRep];
      window = [(NSCachedImageRep *)imageRep window];
      _lockedView = [window contentView];
      if (_lockedView == nil)
	[NSException raise: NSImageCacheException
		     format: @"Cannot lock focus on nil rep"];
      [_lockedView lockFocus];
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

- (NSImageRep*) bestRepresentationForDevice: (NSDictionary*)deviceDescription
{
  NSArray *reps = [self representations];
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSImageRep *rep = nil;  
  NSImageRep *best = nil;

  while ((rep = [enumerator nextObject]) != nil)
    {
      /*
       * What's the best representation? 
       * FIXME: At the moment we take the last bitmap we find.
       * If we can't find a bitmap, we take whatever we can.
       * Do no change this without changing the Backend stuff on image dragging!
       */
      if ([rep isKindOfClass: bitmapClass])
	best = rep;
      else if (best == nil)
	best = rep;
    }
  return best;
}

- (NSArray *) representations
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
      unsigned	i;

      [_reps getObjects: repList];
      for (i = 0; i < count; i++) 
	{
	  repList[i] = ((GSRepData*)repList[i])->rep;
	}
      return [NSArray arrayWithObjects: repList count: count];
    }
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
  NSArray *reps = [self representations];
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSImageRep *rep;

  while ((rep = [enumerator nextObject]) != nil)
    {
      if ([rep isKindOfClass: bitmapClass])
        {
	  return [(NSBitmapImageRep*)rep TIFFRepresentation];
	}
    }

  return nil;
}

- (NSData *) TIFFRepresentationUsingCompression: (NSTIFFCompression)comp
	factor: (float)aFloat
{
  NSArray *reps = [self representations];
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSImageRep *rep;

  while ((rep = [enumerator nextObject]) != nil)
    {
      if ([rep isKindOfClass: bitmapClass])
        {
	  return [(NSBitmapImageRep*)rep TIFFRepresentationUsingCompression: comp
		      factor: aFloat];
	}
    }

  return nil;
}

// NSCoding
- (void) encodeWithCoder: (NSCoder*)coder
{
  BOOL	flag;

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

- (id) initWithCoder: (NSCoder*)coder
{
  BOOL	flag;

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
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.scalable = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.dataRetained = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.flipDraw = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.sizeWasExplicitlySet = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.useEPSOnResolutionMismatch = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.colorMatchPreferred = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.multipleResolutionMatching = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.cacheSeparately = flag;
      [coder encodeValueOfObjCType: @encode(BOOL) at: &flag];
      _flags.unboundedCacheDepth = flag;

      /*
       * get the image reps and add them.
       */
      a = [coder decodeObject];
      [self addRepresentations: a];
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
  _fileName = RETAIN(fileName);
  _flags.syncLoad = YES;
  return YES;
}

// Cache the bestRepresentation.  If the bestRepresentation is not itself
// a cache and no cache exists, create one and draw the representation in it
// If a cache exists, but is not valid, redraw the cache from the original
// image (if there is one).
- (NSImageRep *)_doImageCache
{
  NSImageRep *rep = [self _cacheForRep: nil];

  if (NSImageDoesCaching == YES)
    {
      GSRepData *repd = repd_for_rep(_reps, rep);

      NSDebugLLog(@"NSImage", @"Cached image rep is %d", (int)rep);
      /*
       * if the cache is not valid, it's background color will not exist
       * and we must draw the background then render from the original
       * image rep into the cache.
       */
      if (repd->bg == nil) 
	{
	  NSRect drawRect = NSMakeRect(0, 0, _size.width, _size.height);

	  [self lockFocusOnRepresentation: rep];
	  if (_color != nil && [_color alphaComponent] != 0.0)
	    {
	      [_color set];
	      NSRectFill(drawRect);
	      repd->bg = [_color copy];
	    }
	  else
	    {
	      repd->bg = [clearColor copy];
	    }

	  [self drawRepresentation: repd->original inRect: drawRect];
	  [self unlockFocus];
	  if ([repd->bg alphaComponent] == 1.0)
	    {
	      [rep setOpaque: YES];
	    }
	  else
	    {
	      [rep setOpaque: [repd->original isOpaque]];
	    }
	  NSDebugLLog(@"NSImage", @"Rendered rep %d on background %@",
	    (int)rep, repd->bg);
	}
    }
  
  return rep;
}

- (NSImageRep*) _cacheForRep: (NSImageRep*)rep
{
  if (rep == nil)
    rep = [self bestRepresentationForDevice: nil];

  /*
   * If this is not a cached image rep - create a cache to be used to
   * render the image rep into, and switch to the cached rep.
   */
  if (NSImageDoesCaching == YES && [rep isKindOfClass: cachedClass] == NO)
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
