/*
   NSImage.m

   Load, manipulate and display images

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */ 
/*
    FIXME:  
        [1] Filter services not implemented.
	[2] Should there be a place to look for system bitmaps? 
	(findImageNamed:).
	[3] bestRepresentation is not complete.
*/
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSScreen.h>
#include <Foundation/NSException.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSBundle.h>
#include <string.h>

/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NSImageBackend
- (void) _displayEraseRect: (NSRect)bounds view: (NSView *)view
        color: (NSColor *)color;
	  // Info: This Backend function needs to erase the "view" area
          // defined by "rect" to the color "color".
- (void) compositeToPoint: (NSPoint)point fromRect: (NSRect)rect
	operation: (NSCompositingOperation)op;
- (void) dissolveToPoint: (NSPoint)point fromRect: (NSRect)rect
        fraction: (float)aFloat;
@end

typedef struct _rep_data_t 
{
  NSString*     fileName;
  id		rep;
  id		cache;
  id		original;
  BOOL	        validCache;
} rep_data_t;

/* Class variables and functions for class methods */
static NSMutableDictionary*	nameDict;

NSArray *iterate_reps_for_types(NSArray *imageReps, SEL method);

/* (NSString doesn't do these yet) */
/* Strip the extension from a name */
#define BASENAME(str)   ((strrchr(str, '/')) ? strrchr(str, '/')+1 : str)
static NSString *
_base_name(NSString *name)
{
  return [NSString stringWithCString: BASENAME([name cString])];
} 

/* Get the extension from a name  */
static NSString *
extension(NSString *name)
{
  char *s;
    
  s = strrchr([name cString], '.');
  if (s > strrchr([name cString], '/'))
    return [NSString stringWithCString:s+1];
  else
    return nil;
} 

/* Find the rep_data_t holding a representation */
rep_data_t
repd_for_rep(NSArray *_reps, NSImageRep *rep)
{
  int i, count;
  rep_data_t repd;

  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      [[_reps objectAtIndex: i] getValue: &repd];
      if (repd.rep == rep)
        return repd;
    }
  [NSException raise: NSInternalInconsistencyException
  	format: @"Cannot find stored representation"];
  /* NOT REACHED */
  return repd;
}

void
set_repd_for_rep(NSMutableArray *_reps, NSImageRep *rep, rep_data_t *new_repd)
{
  int i, count;
  rep_data_t repd;
  BOOL found = NO;

  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      [[_reps objectAtIndex: i] getValue: &repd];
      if (repd.rep == rep && !found)
	{
	  [_reps replaceObjectAtIndex: i withObject:
	    [NSValue value: new_repd withObjCType: @encode(rep_data_t)]];
	  found = YES;
	}
    }
  if (!found)
    [_reps addObject: 
      [NSValue value: new_repd withObjCType: @encode(rep_data_t)]];
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

+ imageNamed: (NSString *)aName
{
  /* If there is no image with that name, search in the main bundle */
  if (!nameDict || ![nameDict objectForKey:aName]) 
    {
      NSString* ext;
      NSString* path;
      NSBundle* main;
      main = [NSBundle mainBundle];
      ext  = extension(aName);
      if (ext)
	path = [main pathForResource: aName ofType: ext];
      else 
	{
	  int i, count;
	  NSArray* array;

	  array = [self imageFileTypes];
	  count = [array count];
	  for (i = 0; i < count; i++)
	    {
	      path = [main pathForResource:aName 
		        ofType: [array objectAtIndex: i]];
	      if ([path length] != 0)
		break;
	    }
	}
      if ([path length] != 0) 
	{
	  NSImage* image = [[NSImage alloc] initByReferencingFile:path];
	  if (image)
	    [image setName:_base_name(path)];
	  return image;
	}
    }
  
  return [nameDict objectForKey:aName];
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

- init
{
  [self initWithSize: NSMakeSize(0, 0)];
  return self;
}

- initByReferencingFile: (NSString *)fileName
{
  [self init];
  _flags.dataRetained = NO;
  // FIXME: Should this be an exception? What else should happen?
  if (![self useFromFile:fileName])
    [NSException raise: NSGenericException
      format: @"Cannot find image representation for image %s", 
      [fileName cString]];
  return self;
}

- initWithContentsOfFile: (NSString *)fileName
{
  [self init];
  _flags.dataRetained = YES;
  // FIXME: Should this be an exception? What else should happen ?
  if (![self useFromFile:fileName])
    [NSException raise: NSGenericException
      format: @"Cannot find image representation for image %s", 
      [fileName cString]];
  return self;
}

- initWithData: (NSData *)data;
{
  [self init];
  // FIXME: Should this be an exception? What else should happen ?
  if (![self loadFromData: data])
    [NSException raise: NSGenericException
      format: @"Cannot find image representation for data"]; 
  return self;
}

- initWithPasteboard: (NSPasteboard *)pasteboard
{
  [self notImplemented:_cmd];
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
    [nameDict removeObjectForKey:name];
  [name release];
  [super dealloc];
}

- copyWithZone: (NSZone *)zone
{
  NSImage* copy;

  // FIXME: maybe we should retain if _flags.dataRetained = NO
  copy = [super copyWithZone: zone];

  [name retain];
  [_color retain];
  _lockedView = nil;
  [copy addRepresentations: [[self representations] copyWithZone: zone]];
  
  return copy;
}

- (BOOL)setName: (NSString *)string
{
  if (!nameDict)
    nameDict = [[NSMutableDictionary dictionaryWithCapacity: 2] retain];

  if (!string || [nameDict objectForKey: string])
    return NO;
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
  BOOL valid;
  int i, count;

  /* Go through all our representations and determine if at least one
     is a valid cache */
  // FIXME: Not sure if this is correct
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      rep_data_t repd;
      [[_reps objectAtIndex: i] getValue: &repd];
      valid |= repd.validCache;
    }
  return valid;
}

- (void) recache
{
  int i, count;

  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      rep_data_t repd;
      [[_reps objectAtIndex: i] getValue: &repd];
      repd.validCache = NO;
      [_reps replaceObjectAtIndex: i withObject: 
        [NSValue value: &repd withObjCType: @encode(rep_data_t)]];
    }
}

- (void) setScalesWhenResized: (BOOL)flag
{
  _flags.scalable = flag;
}

- (BOOL)scalesWhenResized
{
  return _flags.scalable;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  [_color autorelease];
  _color = [aColor retain];
}

- (NSColor *)backgroundColor
{
  return _color;
}

/* Make sure any images that were added with useFromFile: are loaded
   in and added to the representation list. */
- _loadImageFilenames
{
  unsigned i, count;
  rep_data_t repd;

  _syncLoad = NO;
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      [[_reps objectAtIndex: i] getValue: &repd];
      if (repd.fileName)
	[self loadFromFile: repd.fileName];
    }
  // Now get rid of them since they are already loaded
  count = [_reps count];
  while (count--) 
    {
      [[_reps objectAtIndex: count] getValue: &repd];
      if (repd.fileName) 
	{
	  [repd.fileName release];
	  [_reps removeObjectAtIndex: count];
	}
    }
  return self;
}
    
// Cache the bestRepresentation.  If the bestRepresentation is not itself
// a cache and no cache exists, create one and draw the representation in it
// If a cache exists, but is not valid, redraw the cache from the original
// image (if there is one).
- _doImageCache
{
  NSImageRep *rep;
  rep_data_t repd;
  repd = repd_for_rep(_reps, [self bestRepresentationForDevice: nil]);
  rep = repd.rep;
  if (repd.cache)
    rep = repd.cache;
  if (![rep isKindOfClass: [NSCachedImageRep class]]) 
    {
      [self lockFocus];
	{
	  rep_data_t cached;
	  NSRect bounds;
	  _lockedView = [NSView focusView];
	  bounds = [_lockedView bounds];
	  [self _displayEraseRect: bounds view: _lockedView color: _color];
	  [self drawRepresentation: rep
	    inRect: NSMakeRect(0, 0, _size.width, _size.height)];
	  [self unlockFocus];
#if 0
	  [[_reps lastObject] getValue: &cached];
	  cached.original = rep;
	  cached.validCache = YES;
	  [_reps removeLastObject];
	  [_reps addObject:
	    [NSValue value: &cached withObjCType: @encode(rep_data_t)]];
#endif
	}
    } 
  else if (!repd.validCache) 
    {
      [self lockFocusOnRepresentation: rep];
	{
	  NSRect bounds;
	  bounds = [_lockedView bounds];
	  [self _displayEraseRect: bounds view: _lockedView color: _color];
	  repd = repd_for_rep(_reps, rep);
	  [self drawRepresentation: repd.original 
	    inRect: NSMakeRect(0, 0, _size.width, _size.height)];
	  [self unlockFocus];
	  repd.validCache = YES;
	  set_repd_for_rep(_reps, repd.rep, &repd);
	}
    }
  
  return self;
}

// Using the Image 
- (void) compositeToPoint: (NSPoint)aPoint 
	operation: (NSCompositingOperation)op;
{
  NSRect rect;
  [self size];
  rect = NSMakeRect(0, 0, _size.width, _size.height);
  [self compositeToPoint: aPoint fromRect:rect operation: op];
}

- (void) compositeToPoint: (NSPoint)aPoint fromRect: (NSRect)aRect
	operation: (NSCompositingOperation)op;
{
  [self _doImageCache];
}

- (void) dissolveToPoint: (NSPoint)aPoint fraction: (float)aFloat;
{
  NSRect rect;
  [self size];
  rect = NSMakeRect(0, 0, _size.width, _size.height);
  [self dissolveToPoint: aPoint fromRect: rect fraction: aFloat];
}

- (void) dissolveToPoint: (NSPoint)aPoint fromRect: (NSRect)aRect 
	fraction: (float)aFloat;
{
  [self _doImageCache];
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
  if (rep && [rep respondsTo: @selector(imageRepsWithData:)])
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

- (BOOL)loadFromFile: (NSString *)fileName
{
  NSArray* array;

  array = [NSImageRep imageRepsWithContentsOfFile: fileName];
  if (array)
    [self addRepresentations: array];

  return (array) ? YES : NO;
}

- (BOOL)useFromFile: (NSString *)fileName
{
  NSArray*   array;
  NSString*  ext;
  rep_data_t repd;

  ext = extension(fileName);
  if (!ext)
    return NO;
  array = [[self class] imageFileTypes];
  if (![array indexOfObject: ext])
    return NO;
  repd.fileName = [fileName retain];
  [_reps addObject: [NSValue value: &repd withObjCType: @encode(rep_data_t)]];
  _syncLoad = YES;
  return YES;
}

- (void) addRepresentation: (NSImageRep *)imageRep
{
  [self addRepresentations: [NSArray arrayWithObject: imageRep]];
}

- (void) addRepresentations: (NSArray *)imageRepArray
{
  int i, count;
  rep_data_t repd;

  if (!imageRepArray)
    return;

  if (_syncLoad)
    [self _loadImageFilenames];
  count = [imageRepArray count];
  for (i = 0; i < count; i++)
    {
      repd.fileName = NULL;
      repd.rep = [imageRepArray objectAtIndex: i];
      repd.cache = NULL;
      repd.original = NULL;
      repd.validCache = NO;
      [_reps addObject: 
       [NSValue value: &repd withObjCType: @encode(rep_data_t)]];
    }
}

- (BOOL) useCacheWithDepth: (int)depth
{
  NSSize imageSize;
  NSCachedImageRep* rep;
  
  imageSize = [self size];
  if (!imageSize.width || !imageSize.height)
    return NO;

  // FIMXE: determine alpha? separate?
  rep = [[NSCachedImageRep alloc] initWithSize: _size
       depth: depth
       separate: NO
       alpha: NO];
  [self addRepresentation:rep];
  return YES;
}

- (void) removeRepresentation: (NSImageRep *)imageRep
{
  int i, count;
  rep_data_t repd;
  count = [_reps count];
  for (i = 0; i < count; i++) 
    {
      [[_reps objectAtIndex: i] getValue: &repd];
      if (repd.rep == imageRep)
	[_reps removeObjectAtIndex: i];
    }
}

- (void) lockFocus
{
  NSScreen *cur = [NSScreen mainScreen];
  NSImageRep *rep;

  if (!(rep = [self bestRepresentationForDevice: nil])) 
    {
      [self useCacheWithDepth: [cur depth]];
      rep = [self lastRepresentation];
    }
  [self lockFocusOnRepresentation: rep];
}

- (void) lockFocusOnRepresentation: (NSImageRep *)imageRep
{
  NSScreen *cur = [NSScreen mainScreen];
  NSWindow *window;
  if (!imageRep)
    [NSException raise: NSInvalidArgumentException
      format: @"Cannot lock focus on nil rep"];

#if 0
  if (![imageRep isKindOfClass: [NSCachedImageRep class]]) 
    {
      rep_data_t repd, cached;
      int depth;
      if (_flags.unboundedCacheDepth)
	depth = [cur depth];      // FIXME: get depth correctly
      else
	depth = [cur depth];
      if (![self useCacheWithDepth: depth]) 
	{
	  [NSException raise: NSImageCacheException
	    format: @"Unable to create cache"];
	}
      repd = repd_for_rep(_reps, imageRep);
      cached = repd_for_rep(_reps, [self lastRepresentation]);
      repd.cache = cached.rep;
      cached.original = repd.rep;
      set_repd_for_rep(_reps, imageRep, &repd);
      set_repd_for_rep(_reps, cached.rep, &cached);
      imageRep = cached.rep;
    }
    window = [(NSCachedImageRep *)imageRep window];
    _lockedView = [window contentView];
    [_lockedView lockFocus];
#endif
}

- (void) unlockFocus
{
  if (_lockedView)
    [_lockedView unlockFocus];
  _lockedView = nil;
}

- (NSImageRep *) lastRepresentation
{
  // Reconstruct the repList if it has changed
  [self representations];
  return [_repList lastObject];
}

- (NSImageRep *) bestRepresentationForDevice: 
         (NSDictionary *)deviceDescription;
{
  id o, e;
  NSImageRep *rep;
  rep_data_t repd;

  // Make sure we have the images loaded in
  if (_syncLoad)
    [self _loadImageFilenames];

  if ([_reps count] == 0)
    return nil;
    
  // What's the best representation? FIXME
  e = [_reps objectEnumerator];
  o = [e nextObject];
  while (o)
    {
      [o getValue: &repd];
      if ([repd.rep class] == [NSBitmapImageRep class])
	rep = repd.rep;
      o = [e nextObject];
    }
#if 0
  [[_reps lastObject] getValue: &repd];
  if (repd.cache)
    rep = repd.cache;
  else
    rep = repd.rep;
#endif

  return rep;
}

- (NSArray *) representations
{
  int i, count;
  if (!_repList)
    _repList = [[NSMutableArray alloc] init];
  if (_syncLoad)
    [self _loadImageFilenames];
  count = [_reps count];
  [_repList removeAllObjects];
  for (i = 0; i < count; i++) 
    {
      rep_data_t repd;
      [[_reps objectAtIndex: i] getValue: &repd];
      [_repList addObject:repd.rep];
    }
  return _repList;
}

- (void) setDelegate: anObject
{
  delegate = anObject;
}

- delegate
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
- (NSImage *)imageDidNotDraw:(id)sender
		      inRect:(NSRect)aRect
{
  if ([delegate respondsToSelector:@selector(imageDidNotDraw:inRect:)])
    return [delegate imageDidNotDraw: sender inRect: aRect];
  else
    return self;
}

// NSCoding
- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  return self;
}

- (id) awakeAfterUsingCoder: (NSCoder*)aDecoder
{
  if (name && [nameDict objectForKey:name]) 
    {
      return [nameDict objectForKey:name];
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
  NSImageRep *rep;
  id e;
  int i, count;
  NSMutableArray* types;

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
      pb_list = [rep perform: method];

      // Iterate through the returned array
      // and add elements to types list, duplicates weeded.
      e1 = [pb_list objectEnumerator];
      obj = [e1 nextObject];
      while (obj)
	{
	  if (![types indexOfObject: obj])
	    [types addObject: obj];
	  obj = [e1 nextObject];
	}

      rep = [e nextObject];
    }
    
  return (NSArray *)types;
}
