/** <title>NSImage</title>

   <abstract>Load, manipulate and display images</abstract>

   Copyright (C) 1996, 2005 Free Software Foundation, Inc.
   
   Author: Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
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

#include "config.h"
#include <string.h>
#include <math.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSImage.h"

#import "AppKit/AppKitExceptions.h"
#import "AppKit/NSAffineTransform.h"
#import "AppKit/NSBitmapImageRep.h"
#import "AppKit/NSCachedImageRep.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSPrintOperation.h"
#import "AppKit/NSScreen.h"
#import "AppKit/NSView.h"
#import "AppKit/NSWindow.h"
#import "AppKit/PSOperators.h"
#import "GNUstepGUI/GSDisplayServer.h"
#import "GSThemePrivate.h"


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

BOOL NSImageForceCaching = NO; /* use on missmatch */

@implementation NSBundle (NSImageAdditions)

- (NSString*) pathForImageResource: (NSString*)name
{
  NSString *ext = [name pathExtension];
  NSString *path = nil;

  if ((ext == nil) || [ext isEqualToString:@""])
    {
      NSArray *types = [NSImage imageUnfilteredFileTypes];
      unsigned c = [types count];
      unsigned i;

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

@interface GSRepData : NSObject
{
@public
  NSImageRep *rep;
  NSImageRep *original;
  NSColor *bg;
}
@end

@implementation GSRepData
- (id) copyWithZone: (NSZone*)z
{
  GSRepData *c = (GSRepData*)NSCopyObject(self, 0, z);

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
  [super dealloc];
}
@end

/* Class variables and functions for class methods */
static NSRecursiveLock		*imageLock = nil;
static NSMutableDictionary	*nameDict = nil;
static NSDictionary		*nsmapping = nil;
static NSColor			*clearColor = nil;
static Class cachedClass = 0;
static Class bitmapClass = 0;

static NSArray *iterate_reps_for_types(NSArray *imageReps, SEL method);

/* Find the GSRepData object holding a representation */
static GSRepData*
repd_for_rep(NSArray *_reps, NSImageRep *rep)
{
  NSEnumerator *enumerator = [_reps objectEnumerator];
  IMP nextImp = [enumerator methodForSelector: @selector(nextObject)];
  GSRepData *repd;

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
- (GSRepData*) _cacheForRep: (NSImageRep*)rep;
- (NSCachedImageRep*) _doImageCache: (NSImageRep *)rep;
@end

@implementation NSImage

+ (void) initialize
{
  if (imageLock == nil)
    {
      NSString *path;

      imageLock = [NSRecursiveLock new];
      [imageLock lock];

      // Initial version
      [self setVersion: 1];

      // initialize the class variables
      nameDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
      path = [NSBundle pathForLibraryResource: @"nsmapping"
				       ofType: @"strings"
				  inDirectory: @"Images"];
      if (path)
        nsmapping = RETAIN([[NSString stringWithContentsOfFile: path]
                               propertyListFromStringsFileFormat]);
      clearColor = RETAIN([NSColor clearColor]);
      cachedClass = [NSCachedImageRep class];
      bitmapClass = [NSBitmapImageRep class];
      [imageLock unlock];
    }
}

+ (id) imageNamed: (NSString *)aName
{
  NSImage	*image;
 
  /* 2009-09-10 changed operation of nsmapping so that the loaded
   * image is stored under the key 'aName', not under the mapped
   * name.  That way the image is created with the correct name and
   * a later call to -setName: will work properly.
   */
  [imageLock lock];
  image = (NSImage*)[nameDict objectForKey: aName];
  if (image == nil || [(id)image _resource] == nil)
    {
      NSString	*realName = [nsmapping objectForKey: aName];
      NSString	*ext;
      NSString	*path = nil;
      NSBundle	*main_bundle;
      NSArray	*array;

      if (realName == nil)
	{
          realName = aName;
	}
 
      // FIXME: This should use [NSBundle pathForImageResource], but this will 
      // only allow imageUnfilteredFileTypes.
      /* If there is no image with that name, search in the main bundle */
      main_bundle = [NSBundle mainBundle];
      ext = [realName pathExtension];
      if (ext != nil && [ext length] == 0)
        {
          ext = nil;
        }

      /* Check if extension is one of the image types */
      array = [self imageFileTypes];
      if (ext != nil && [array indexOfObject: ext] != NSNotFound)
        {
          /* Extension is one of the image types
             So remove from the name */
          realName = [realName stringByDeletingPathExtension];
        }
      else
        {
          /* Otherwise extension is not an image type
             So leave it alone */
          ext = nil;
        }

      /* First search locally */
      if (ext)
        path = [main_bundle pathForResource: realName ofType: ext];
      else 
        {
          id o, e;

          e = [array objectEnumerator];
          while ((o = [e nextObject]))
            {
              path = [main_bundle pathForResource: realName 
					   ofType: o];
              if (path != nil && [path length] != 0)
                break;
            }
        }

      /* Second search on theme bundle */
      if (!path)
	{
	  if (ext)
	    path = [[[GSTheme theme] bundle] pathForResource: realName ofType: ext];
	  else 
	    {
	      id o, e;
	      
	      e = [array objectEnumerator];
	      while ((o = [e nextObject]))
		{
		  path = [[[GSTheme theme] bundle] pathForResource: realName 
				                            ofType: o];
		  if (path != nil && [path length] != 0)
		    break;
		}
	    }
	}

      /* If not found then search in system */
      if (!path)
        {
          if (ext)
            {
              path = [NSBundle pathForLibraryResource: realName
                                               ofType: ext
                                          inDirectory: @"Images"];
            }
          else 
            {
              id o, e;

              e = [array objectEnumerator];
              while ((o = [e nextObject]))
                {
                  path = [NSBundle pathForLibraryResource: realName
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
              AUTORELEASE(image);
              image->_flags.archiveByName = YES;
            }
          image = (NSImage*)[nameDict objectForKey: aName];
        }
    }
  IF_NO_GC([[image retain] autorelease]);
  [imageLock unlock];
  return image;
}

+ (NSImage *) _standardImageWithName: (NSString *)name
{
  NSImage *image = nil;

  image = [NSImage imageNamed: name];
  if (image == nil)
    image = [NSImage imageNamed: [@"common_" stringByAppendingString: name]];
  return image;
}

- (id) init
{
  return [self initWithSize: NSMakeSize(0, 0)];
}

- (id) initWithSize: (NSSize)aSize
{
  if (!(self = [super init]))
    return nil;

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
  if (!(self = [self init]))
    return nil;

  if (![self _useFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }
  _flags.archiveByName = YES;

  return self;
}

- (id) initWithContentsOfFile: (NSString *)fileName
{
  if (!(self = [self init]))
    return nil;

  _flags.dataRetained = YES;
  if (![self _loadFromFile: fileName])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

- (id) initWithData: (NSData *)data
{
  if (!(self = [self init]))
    return nil;

  _flags.dataRetained = YES;
  if (![self _loadFromData: data])
    {
      RELEASE(self);
      return nil;
    }

  return self;
}

- (id) initWithBitmapHandle: (void *)bitmap
{
  NSImageRep *rep;
  
  if (!(self = [self init]))
    return nil;

  rep = [[NSBitmapImageRep alloc] initWithBitmapHandle: bitmap];
  if (rep == nil)
    {
      RELEASE(self);
      return nil;
    }

  [self addRepresentation: rep];
  RELEASE(rep);
  return self;
}

- (id)initWithIconHandle:(void *)icon
{
  // Only needed on MS Windows
  NSImageRep *rep;
  
  if (!(self = [self init]))
    return nil;

  rep = [[NSBitmapImageRep alloc] initWithIconHandle: icon];
  if (rep == nil)
    {
      RELEASE(self);
      return nil;
    }

  [self addRepresentation: rep];
  RELEASE(rep);
  return self;
}

- (id) initWithContentsOfURL: (NSURL *)anURL
{
  NSArray *array;

  if (!(self = [self init]))
    return nil;

  array = [NSImageRep imageRepsWithContentsOfURL: anURL];
  if (!array)
    {
      RELEASE(self);
      return nil;
    }

  _flags.dataRetained = YES;
  [self addRepresentations: array];
  return self;
}

- (id) initWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray *reps;
  if (!(self = [self init]))
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
  if (_name == nil)
    {
      RELEASE(_reps);
      TEST_RELEASE(_fileName);
      RELEASE(_color);
      [super dealloc];
    }
  else
    {
      [self retain];
      NSLog(@"Warning ... attempt to deallocate image with name: %@", _name);
    }
}

- (id) copyWithZone: (NSZone *)zone
{
  NSImage *copy;
  NSArray *reps = [self representations];
  NSEnumerator *enumerator = [reps objectEnumerator];
  NSImageRep *rep;

  copy = (NSImage*)NSCopyObject (self, 0, zone);

  copy->_name = nil;
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

/* This methd sets the name of an image, updating the global name dictionary
 * to point to the image (or removing an image from the dictionary if the
 * new name is nil).
 * The images are actually accessed via proxy objects, so that when a
 * new system image is set (using [NSImage+_setImage:name:]), the proxy
 * for that image just starts using the new version.
 */
- (BOOL) setName: (NSString *)aName
{
  GSThemeProxy	*proxy = nil;
  
  [imageLock lock];

  /* The name is already set... nothing to do.
   */
  if (aName == _name || [aName isEqual: _name] == YES)
    {
      [imageLock unlock];
      return YES;
    }

  /* If the new name is already in use by another image,
   * we must do nothing.
   */
  if (aName != nil && [[nameDict objectForKey: aName] _resource] != nil)
    {
      [imageLock unlock];
      return NO;
    }

  /* If this image had another name, we remove it.
   */
  if (_name != nil)
    {
      /* We retain self in case removing from the dictionary releases us */
      IF_NO_GC([[self retain] autorelease]);
      [nameDict removeObjectForKey: _name];
      DESTROY(_name);
    }
  
  /* If the new name is null, there is nothing more to do.
   */
  if (aName == nil)
    {
      [imageLock unlock];
      return NO;
    }

  ASSIGN(_name, aName);
  
  if ((proxy = [nameDict objectForKey: _name]) == nil)
    {
      proxy = [GSThemeProxy alloc];
      [nameDict setObject: proxy forKey: _name];
      [proxy release]; 
    }
  [proxy _setResource: self];
  
  [imageLock unlock];
  return YES;
}

- (NSString *) name
{
  NSString	*name;

  [imageLock lock];
  name = [[_name retain] autorelease];
  [imageLock unlock];
  return name;
}

- (void) setSize: (NSSize)aSize
{
  // Optimized as this is called very often from NSImageCell
  if (NSEqualSizes(_size, aSize))
    return;

  _size = aSize;
  _flags.sizeWasExplicitlySet = YES;

  [self recache];
}

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
  BOOL valid = NO;
  unsigned i, count;

  if (_flags.syncLoad)
    {
      /* Make sure any images that were added with _useFromFile: are loaded
         in and added to the representation list. */
      if (![self _loadFromFile: _fileName])
        return NO;
      _flags.syncLoad = NO;
    }

  /* Go through all our representations and determine if at least one
     is a valid cache */
  // FIXME: Not sure if this is correct
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      GSRepData *repd = (GSRepData*)[_reps objectAtIndex: i];

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
      GSRepData *repd;

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
                operation: (NSCompositingOperation)op
{
  // Might not be computed up to now
  NSSize size = [self size];
  NSRect rect = NSMakeRect(0, 0, size.width, size.height);

  [self compositeToPoint: aPoint fromRect: rect operation: op];
}

- (void) compositeToPoint: (NSPoint)aPoint
                 fromRect: (NSRect)aRect
                operation: (NSCompositingOperation)op
{
  [self compositeToPoint: aPoint 
        fromRect: aRect 
        operation: op
        fraction: 1.0];
}

- (void) compositeToPoint: (NSPoint)aPoint
                operation: (NSCompositingOperation)op
                 fraction: (float)delta
{
  NSSize size = [self size];

  [self compositeToPoint: aPoint 
        fromRect: NSMakeRect(0, 0, size.width, size.height) 
        operation: op 
        fraction: delta];
}

- (void) compositeToPoint: (NSPoint)aPoint
                 fromRect: (NSRect)srcRect
                operation: (NSCompositingOperation)op
                 fraction: (float)delta
{
  NSGraphicsContext *ctxt = GSCurrentContext();

  // Calculate the user space scale factor of the current window
  NSView *focusView = [NSView focusView];
  CGFloat scaleFactor = 1.0;
  if (focusView != nil)
    {
      scaleFactor = [[focusView window] userSpaceScaleFactor];
    }

  // Set the CTM to the identity matrix with the current translation
  // and the user space scale factor
  {
    NSAffineTransform *backup = [ctxt GSCurrentCTM];
    NSAffineTransform *newTransform = [NSAffineTransform transform];
    NSPoint translation = [backup transformPoint: aPoint];
    [newTransform translateXBy: translation.x
			   yBy: translation.y];
    [newTransform scaleBy: scaleFactor];
    
    [ctxt GSSetCTM: newTransform];
    
    [self drawAtPoint: NSMakePoint(0,0)
	     fromRect: srcRect
	    operation: op
	     fraction: delta];
    
    [ctxt GSSetCTM: backup];
  }
}

- (void) dissolveToPoint: (NSPoint)aPoint fraction: (float)aFloat
{
  NSSize size = [self size];

  [self dissolveToPoint: aPoint 
        fromRect: NSMakeRect(0, 0, size.width, size.height)
        fraction: aFloat];
}

- (void) dissolveToPoint: (NSPoint)aPoint
                fromRect: (NSRect)aRect 
                fraction: (float)aFloat
{
  [self compositeToPoint: aPoint
        fromRect: aRect
        operation: NSCompositeSourceOver
        fraction: aFloat];
}

- (BOOL) drawRepresentation: (NSImageRep *)imageRep inRect: (NSRect)aRect
{
  BOOL r;

  PSgsave();

  if (_color != nil)
    {
      NSRect fillrect = aRect;

      [_color set];
      NSRectFill(fillrect);

      if ([GSCurrentContext() isDrawingToScreen] == NO)
        {
          /* Reset alpha for image drawing. */
          [[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] set];
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

/* New code path that delegates as much as possible to the backend and whose 
behavior precisely matches Cocoa. */
- (void) nativeDrawInRect: (NSRect)dstRect
                 fromRect: (NSRect)srcRect
                operation: (NSCompositingOperation)op
                 fraction: (float)delta
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSSize imgSize = [self size];
  float widthScaleFactor;
  float heightScaleFactor;

  if (NSEqualRects(srcRect, NSZeroRect))
    {
      srcRect.size = imgSize;
      /* For -drawAtPoint:fromRect:operation:fraction: used with a zero rect */
      if (NSEqualSizes(dstRect.size, NSZeroSize))
        {
          dstRect.size = imgSize;
        }
    }

  if (!dstRect.size.width || !dstRect.size.height
    || !srcRect.size.width || !srcRect.size.height)
    return;

  // Clip to image bounds
  if (srcRect.origin.x < 0)
    srcRect.origin.x = 0;
  if (srcRect.origin.y < 0)
    srcRect.origin.y = 0;
  if (NSMaxX(srcRect) > imgSize.width)
    srcRect.size.width = imgSize.width - srcRect.origin.x;
  if (NSMaxY(srcRect) > imgSize.height)
    srcRect.size.height = imgSize.height - srcRect.origin.y;

  widthScaleFactor = dstRect.size.width / srcRect.size.width;
  heightScaleFactor = dstRect.size.height / srcRect.size.height;

  if (![ctxt isDrawingToScreen])
    {
      /* We can't composite or dissolve if we aren't drawing to a screen,
         so we'll just draw the right part of the image in the right
         place. */
      NSPoint p;
  
      p.x = dstRect.origin.x / widthScaleFactor - srcRect.origin.x;
      p.y = dstRect.origin.y / heightScaleFactor - srcRect.origin.y;

      DPSgsave(ctxt);
      DPSrectclip(ctxt, dstRect.origin.x, dstRect.origin.y,
                  dstRect.size.width, dstRect.size.height);
      DPSscale(ctxt, widthScaleFactor, heightScaleFactor);
      [self drawRepresentation: [self bestRepresentationForDevice: nil]
            inRect: NSMakeRect(p.x, p.y, imgSize.width, imgSize.height)];
      DPSgrestore(ctxt);

      return;
    }

  /* We cannot ask the backend to draw the image directly when the source rect 
     doesn't cover the whole image.
     Cairo doesn't support to specify a source rect for a surface used as a 
     source, see cairo_set_source_surface()).
     CoreGraphics is similarly limited, see CGContextDrawImage().
     For now, we always use a two step process:
     - draw the image data in a cache to apply the srcRect to inRect scaling
     - draw the cache into the destination context
     It might be worth to move the first step to the backend, so we don't have 
     to create a cache window but just an intermediate surface.
     We create a cache every time but otherwise we are more efficient than the 
     old code path since the cache size is limited to what we actually draw 
     and doesn't involve drawing the whole image. */
  {
    /* An intermediate image used to scale the image to be drawn as needed */
    NSCachedImageRep *cache;
    /* The scaled image graphics state we used as the source from which we 
       draw into the destination (the current graphics context)*/
    int gState;
    /* The context of the cache window */
    NSGraphicsContext *cacheCtxt;
    /* The size of the cache window that will hold the scaled image */
    NSSize cacheSize = [[ctxt GSCurrentCTM] transformSize: dstRect.size];
    CGFloat imgToCacheWidthScaleFactor = cacheSize.width / imgSize.width;
    CGFloat imgToCacheHeightScaleFactor = cacheSize.height / imgSize.height;
    
    NSRect srcRectInCache = NSMakeRect(srcRect.origin.x * imgToCacheWidthScaleFactor, 
                                      srcRect.origin.y * imgToCacheHeightScaleFactor, 
                                     srcRect.size.width * imgToCacheWidthScaleFactor, 
                                   srcRect.size.height * imgToCacheHeightScaleFactor);
    NSAffineTransform *transform;

    cache = [[NSCachedImageRep alloc]
                initWithSize: cacheSize
                       depth: [[NSScreen mainScreen] depth]
                    separate: YES
                       alpha: YES];

    [[[cache window] contentView] lockFocus];
    cacheCtxt = GSCurrentContext();

    /* Clear the cache window surface */
    DPScompositerect(cacheCtxt, 0, 0, cacheSize.width, cacheSize.height, NSCompositeClear);
    gState = [cacheCtxt GSDefineGState];

    //NSLog(@"Draw in cache size %@", NSStringFromSize(cacheSize));

    /* We must not use -drawRepresentation:inRect: because the image must drawn 
       scaled even when -scalesWhenResized is NO */
    [[self bestRepresentationForDevice: nil] 
      drawInRect: NSMakeRect(0, 0, cacheSize.width, cacheSize.height)];
    /* If we're doing a dissolve, use a DestinationIn composite to lower
       the alpha of the pixels.  */
    if (delta != 1.0)
      {
        DPSsetalpha(cacheCtxt, delta);
        DPScompositerect(cacheCtxt, 0, 0, cacheSize.width, cacheSize.height,
                         NSCompositeDestinationIn);
      }

    [[[cache window] contentView] unlockFocus];

    //NSLog(@"Draw in %@ from %@ from cache rect %@", NSStringFromRect(dstRect), 
    //  NSStringFromRect(srcRect), NSStringFromRect(srcRectInCache));

    DPSgsave(ctxt);

    transform = [NSAffineTransform transform];
    [transform translateXBy: dstRect.origin.x yBy: dstRect.origin.y];
    [transform scaleXBy: dstRect.size.width / cacheSize.width
		    yBy: dstRect.size.height / cacheSize.height];
    [transform concat];

    [ctxt GSdraw: gState
         toPoint: NSMakePoint(0,0)
        fromRect: srcRectInCache
       operation: op
        fraction: delta];

    DPSgrestore(ctxt);

    [ctxt GSUndefineGState: gState];
    DESTROY(cache);
  }
}

/* Old code path that can probably partially be merged with the new native implementation.
Fallback for backends other than Cairo. */
- (void) guiDrawInRect: (NSRect)dstRect
              fromRect: (NSRect)srcRect
             operation: (NSCompositingOperation)op
              fraction: (float)delta
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSAffineTransform *transform;
  NSSize s;

  s = [self size];

  if (NSEqualRects(srcRect, NSZeroRect))
    srcRect = NSMakeRect(0, 0, s.width, s.height);

  if (!dstRect.size.width || !dstRect.size.height
    || !srcRect.size.width || !srcRect.size.height)
    return;

  // CLip to image bounds
  if (srcRect.origin.x < 0)
    srcRect.origin.x = 0;
  if (srcRect.origin.y < 0)
    srcRect.origin.y = 0;
  if (NSMaxX(srcRect) > s.width)
    srcRect.size.width = s.width - srcRect.origin.x;
  if (NSMaxY(srcRect) > s.height)
    srcRect.size.height = s.height - srcRect.origin.y;

  if (![ctxt isDrawingToScreen])
    {
      /* We can't composite or dissolve if we aren't drawing to a screen,
         so we'll just draw the right part of the image in the right
         place. */
      NSPoint p;
      double fx, fy;
  
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
    NSAffineTransformStruct ts;
    NSPoint p;
    double x0, y0, x1, y1, w, h;
    int gState;
    NSGraphicsContext *ctxt1;

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
    // The context of the cache window
    ctxt1 = GSCurrentContext();
    DPScompositerect(ctxt1, 0, 0, w, h, NSCompositeClear);

    /* Set up the effective transform.  We also save a gState with this
       transform to make it easier to do the final composite.  */
    ts = [transform transformStruct];
    ts.tX = p.x;
    ts.tY = p.y;
    [transform setTransformStruct: ts];
    [ctxt1 GSSetCTM: transform];
    gState = [ctxt1 GSDefineGState];


    /* We must not use -drawRepresentation:inRect: because the image must drawn 
       scaled even when -scalesWhenResized is NO */

    // FIXME: should the background color be filled here?
    // If I don't I get black backgrounds on images with xlib; maybe an xlib backend bug
    PSgsave();
    if (_color != nil)
      {
	[_color set];
	NSRectFill(NSMakeRect(0, 0, s.width, s.height));
      }
    [[self bestRepresentationForDevice: nil] drawInRect: NSMakeRect(0, 0, s.width, s.height)];
    PSgrestore();

    /* If we're doing a dissolve, use a DestinationIn composite to lower
       the alpha of the pixels.  */
    if (delta != 1.0)
      {
        DPSsetalpha(ctxt1, delta);
        DPScompositerect(ctxt1, 0, 0, s.width, s.height,
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

- (void) drawInRect: (NSRect)dstRect
           fromRect: (NSRect)srcRect
          operation: (NSCompositingOperation)op
           fraction: (float)delta
{
  if ([GSCurrentContext() supportsDrawGState])
  {
    [self nativeDrawInRect: dstRect fromRect: srcRect operation: op fraction: delta];
  }
  else
  {
    [self guiDrawInRect: dstRect fromRect: srcRect operation: op fraction: delta];
  }
}

- (void) addRepresentation: (NSImageRep *)imageRep
{
  GSRepData *repd;

  repd = [GSRepData new];
  repd->rep = RETAIN(imageRep);
  [_reps addObject: repd]; 
  RELEASE(repd);
}

- (void) addRepresentations: (NSArray *)imageRepArray
{
  unsigned i, count;
  GSRepData *repd;

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
  unsigned i;
  GSRepData *repd;

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
          // Remove cached representations for this representation
          // instead of turning them into real ones
          //repd->original = nil;
          [_reps removeObjectAtIndex: i];
        }
    }
}

- (void) lockFocus
{
  [self lockFocusOnRepresentation: nil];
}

- (void) lockFocusOnRepresentation: (NSImageRep *)imageRep
{
  if (_cacheMode != NSImageCacheNever)
    {
      NSWindow *window;
      GSRepData *repd;

      if (imageRep == nil)
        imageRep = [self bestRepresentationForDevice: nil];

      repd = [self _cacheForRep: imageRep];
      imageRep = repd->rep;

      window = [(NSCachedImageRep *)imageRep window];
      _lockedView = [window contentView];
      if (_lockedView == nil)
        [NSException raise: NSImageCacheException
                     format: @"Cannot lock focus on nil rep"];
      [_lockedView lockFocus];
      if (repd->bg == nil) 
        {
          // Clear the background of the cached image, as it is not valid
          if ([_color alphaComponent] < 1.0)
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

          repd->bg = [_color copy];
          if (_color != nil)
            {
              // Won't be needed when drawRepresentation: gets called, 
              // but we never know.
              [_color set];
              NSRectFill(NSMakeRect(0, 0, _size.width, _size.height));
            }
      
          if ([repd->bg alphaComponent] == 1.0)
            {
              [imageRep setOpaque: YES];
            }
          else
            {
              [imageRep setOpaque: [repd->original isOpaque]];
            }

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

/* Find reps that match the resolution of the device or return the
   vector reps or the reps that have the highest resolution */
- (NSMutableArray *) _bestRep: (NSArray *)reps 
          withResolutionMatch: (NSDictionary*)deviceDescription
{
  NSValue *resolution = [deviceDescription objectForKey: NSDeviceResolution];
  NSMutableArray *breps = [NSMutableArray array];

  /* Look for exact resolution matches */

  if (nil != resolution)
    {
      NSSize dres = [resolution sizeValue];

      NSImageRep *rep;
      NSEnumerator *enumerator = [reps objectEnumerator];   
      
      while ((rep = [enumerator nextObject]) != nil)
	{
	  NSSize size = [rep size];
	  NSSize res = NSMakeSize(72.0 * [rep pixelsWide] / size.width,
				  72.0 * [rep pixelsHigh] / size.height);
	  if (NSEqualSizes(res, dres))
	    {
	      [breps addObject: rep];
	    }	    
	}
    }

  /* If no exact matches found, look for vector reps */
  
  if ([breps count] == 0)
    {
      NSImageRep *rep;
      NSEnumerator *enumerator = [reps objectEnumerator];    
      while ((rep = [enumerator nextObject]) != nil)
	{
	  if ([rep pixelsWide] == NSImageRepMatchesDevice && 
	      [rep pixelsHigh] == NSImageRepMatchesDevice)
	  {
	    [breps addObject: rep];
	  }
	}
    }

  /* Otherwise, use the largest bitmaps */
  
  if ([breps count] == 0)
    {
      NSSize maxPixelSize = NSMakeSize(0,0);
      NSImageRep *rep;
      NSEnumerator *enumerator = [reps objectEnumerator];    
      while ((rep = [enumerator nextObject]) != nil)
	{
	  NSSize pixelSize = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
	  if (pixelSize.width > maxPixelSize.width &&
	      pixelSize.height > maxPixelSize.height)
	    {
	      maxPixelSize = pixelSize;
	    }
	}

      enumerator = [reps objectEnumerator];
      while ((rep = [enumerator nextObject]) != nil)
	{
	  NSSize pixelSize = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
	  if (NSEqualSizes(pixelSize, maxPixelSize))
	    {
	      [breps addObject: rep];
	    }
	}      
    }

  if ([breps count] == 0)
    {
      [breps setArray: reps];
    }
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
  unsigned        count;

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
      id repList[count];
      unsigned i, j;

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
          deviceDescription = [[[GSCurrentContext() attributes] objectForKey: 
                NSGraphicsContextDestinationAttributeName] 
                                  deviceDescription];
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
  NSData *data;

  // As a result of using bitmap representations, new drawing wont show on the tiff data.
  data = [bitmapClass TIFFRepresentationOfImageRepsInArray: [self representations]];

  if (!data)
    {
      NSBitmapImageRep *rep;
      NSSize size = [self size];
      
      // If there isn't a bitmap representation to output, create one and store it.
      [self lockFocus];
      rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: 
                       NSMakeRect(0.0, 0.0, size.width, size.height)];
      [self unlockFocus];
      [self addRepresentation: rep];
      data = [rep TIFFRepresentation];
      RELEASE(rep);
    }

  return data;
}

- (NSData *) TIFFRepresentationUsingCompression: (NSTIFFCompression)comp
                                         factor: (float)aFloat
{
  NSData *data;

  // As a result of using bitmap representations, new drawing wont show on the tiff data.
  data = [bitmapClass TIFFRepresentationOfImageRepsInArray: [self representations]
                      usingCompression: comp
                      factor: aFloat];

  if (!data)
    {
      NSBitmapImageRep *rep;
      NSSize size = [self size];
      
      // If there isn't a bitmap representation to output, create one and store it.
      [self lockFocus];
      rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: 
                       NSMakeRect(0.0, 0.0, size.width, size.height)];
      [self unlockFocus];
      [self addRepresentation: rep];
      data = [rep TIFFRepresentationUsingCompression: comp factor: aFloat];
      RELEASE(rep);
    }

  return data;
}

// NSCoding
- (void) encodeWithCoder: (NSCoder*)coder
{
  BOOL        flag;

  if ([coder allowsKeyedCoding])
    {
      // FIXME: Not sure this is the way it goes...
      /*
      if (_flags.archiveByName == NO)
        {
          NSMutableArray *container = [NSMutableArray array];
          NSMutableArray *reps = [NSMutableArray array];
          NSEnumerator *en = [_reps objectEnumerator];
          GSRepData *rd = nil;

          // add the reps to the container...
          [container addObject: reps];
          while ((rd = [en nextObject]) != nil)
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
          NSMutableArray *a;
          NSEnumerator *e;
          NSImageRep *r;
          
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
  BOOL flag;

  _reps = [[NSMutableArray alloc] initWithCapacity: 2];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSColor"])
        {
          [self setBackgroundColor: [coder decodeObjectForKey: @"NSColor"]];
        }
      if ([coder containsValueForKey: @"NSImageFlags"])
        {
          //FIXME
          //int flags = [coder decodeIntForKey: @"NSImageFlags"];
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
          NSString *theName = [coder decodeObject];

          RELEASE(self);
          self = RETAIN([NSImage imageNamed: theName]);
        }
      else
        {
          NSArray *a;

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
  NSImageRep *rep;
  NSEnumerator *e;
  NSMutableArray *types;

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
  NSArray *array;

  array = [NSImageRep imageRepsWithContentsOfFile: fileName];
  if (array)
    [self addRepresentations: array];

  return (array) ? YES : NO;
}

- (BOOL) _useFromFile: (NSString *)fileName
{
  NSArray *array;
  NSString *ext;
  NSFileManager *manager = [NSFileManager defaultManager];

  if ([manager fileExistsAtPath: fileName] == NO)
    {
      return NO;
    }

  ext = [[fileName pathExtension] lowercaseString];
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
- (NSCachedImageRep *) _doImageCache: (NSImageRep *)rep
{
  GSRepData *repd;

  repd = [self _cacheForRep: rep];
  rep = repd->rep;
  if ([rep isKindOfClass: cachedClass] == NO)
    return nil;
  
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
      
      NSDebugLLog(@"NSImage", @"Rendered rep %p on background %@",
                  rep, repd->bg);
    }
  
  return (NSCachedImageRep *)rep;
}

- (GSRepData*) _cacheForRep: (NSImageRep*)rep
{
  if ([rep isKindOfClass: cachedClass] == YES)
    {
      return repd_for_rep(_reps, rep);
    }
  else
    {
      /*
       * If this is not a cached image rep - try to find the cache rep
       * for this image rep. If none is found create a cache to be used to
       * render the image rep into, and switch to the cached rep.
       */
      unsigned count = [_reps count];

      if (count > 0)
        {
          GSRepData *invalidCache = nil;
          GSRepData *partialCache = nil;
          GSRepData *reps[count];
          unsigned partialCount = 0;
          unsigned i;
          BOOL opaque = [rep isOpaque];
          
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
              GSRepData *repd = reps[i];

              if (repd->original == rep && repd->rep != nil)
                {
                  if (repd->bg == nil)
                    {
                      NSDebugLLog(@"NSImage", @"Invalid %@ ... %@ %@", 
                                  repd->bg, _color, repd->rep);
                      invalidCache = repd;
                    }
                  else if (opaque == YES || [repd->bg isEqual: _color] == YES)
                    {
                      NSDebugLLog(@"NSImage", @"Exact %@ ... %@ %@", 
                                  repd->bg, _color, repd->rep);
                      return repd;
                    }
                  else
                    {
                      NSDebugLLog(@"NSImage", @"Partial %@ ... %@ %@", 
                                  repd->bg, _color, repd->rep);
                      partialCache = repd;
                      partialCount++;
                    }
                }
            }

          if (invalidCache != nil)
            {
              /*
               * If there is an unused cache - use it rather than
               * re-using this one, since we might get a request
               * to draw with this color again.
               */
              return invalidCache;
            }
          else if (partialCache != nil && partialCount > 2)
            {
              /*
               * Only re-use partially correct caches if there are already
               * a few partial matches - otherwise we fall default to
               * creating a new cache.
               */
              if (NSImageForceCaching == NO && opaque == NO)
                {
                  DESTROY(partialCache->bg);
                }
              return partialCache;
            }
        }

      // We end here, when no representation are there or no match is found.
        {     
          NSImageRep *cacheRep = nil;
          GSRepData *repd;
          NSSize imageSize = [self size];

          if (imageSize.width == 0 || imageSize.height == 0)
            return nil;

          // Create a new cached image rep without any contents.
          cacheRep = [[cachedClass alloc] 
                         initWithSize: imageSize
                         depth: [[NSScreen mainScreen] depth]
                         separate: _flags.cacheSeparately
                         alpha: [rep hasAlpha]];
          repd = [GSRepData new];
          repd->rep = cacheRep;
          repd->original = rep;
          [_reps addObject: repd]; 
          RELEASE(repd); /* Retained in _reps array. */

          return repd;
        }
    }
}

@end

@implementation	NSImage (GSTheme)

/* This method is used by the theming system to replace a named image
 * without disturbing the proxy ... so that all views and cells using
 * the named image are automatically updated to use the new image.
 * This is the counterpart to the -setName: method, which replaces the
 * proxy (to change a named image without updating the image used by
 * existing views and cells).
 */
+ (NSImage*) _setImage: (NSImage*)image name: (NSString*)name
{
  GSThemeProxy	*proxy = nil;
  
  NSAssert([image isKindOfClass: [NSImage class]], NSInvalidArgumentException);
  NSAssert(![image isProxy], NSInvalidArgumentException);
  NSAssert([name isKindOfClass: [NSString class]], NSInvalidArgumentException);
  NSAssert([name length] > 0, NSInvalidArgumentException);
  NSAssert([image name] == nil, NSInvalidArgumentException);

  [imageLock lock];
  ASSIGNCOPY(image->_name, name);
  if ((proxy = [nameDict objectForKey: image->_name]) == nil)
    {
      proxy = [GSThemeProxy alloc];
      [nameDict setObject: proxy forKey: image->_name];
      [proxy release]; 
    }
  else
    {
      /* Remove the name from the old image.
       */
      DESTROY(((NSImage*)[proxy _resource])->_name);
    }
  [proxy _setResource: image];
  IF_NO_GC([[proxy retain] autorelease]);

  /* Force the image to be archived by name.  This prevents
   * problems such as when/if gorm is being used with a theme
   * active, it will not save the image which was loaded
   * here and will, instead save the name so that the proper
   * image gets loaded in the future.
   */
  image->_flags.archiveByName = YES;

  [imageLock unlock];
  return (NSImage*)proxy;
}
@end
