/* 
   NSImage.h

   Load, manipulate and display images

   Copyright (C) 1996 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This file is part of the GNUstep GUI Library.

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

#ifndef _GNUstep_H_NSImage
#define _GNUstep_H_NSImage

#include <AppKit/NSGraphicsContext.h>
#include <Foundation/NSBundle.h>
#include <AppKit/NSBitmapImageRep.h>

@class NSString;
@class NSMutableArray;
@class NSData;
@class NSURL;

@class NSPasteboard;
@class NSImageRep;
@class NSColor;
@class NSView;

@interface NSImage : NSObject <NSCoding, NSCopying>
{
  // Attributes
  NSString	*_name;
  NSString	*_fileName;
  NSSize	_size;
  struct __imageFlags {
    unsigned	archiveByName: 1;
    unsigned	scalable: 1;
    unsigned	dataRetained: 1;
    unsigned	flipDraw: 1;
    unsigned	sizeWasExplicitlySet: 1;
    unsigned	useEPSOnResolutionMismatch: 1;
    unsigned	colorMatchPreferred: 1;
    unsigned	multipleResolutionMatching: 1;
    unsigned	cacheSeparately: 1;
    unsigned	unboundedCacheDepth: 1;
    unsigned	syncLoad: 1;
  } _flags;
  NSMutableArray	*_reps;
  NSColor		*_color;
  NSView	*_lockedView;
  id		_delegate;
}

//
// Initializing a New NSImage Instance 
//
- (id) initByReferencingFile: (NSString*)fileName;
- (id) initWithContentsOfFile: (NSString*)fileName;
- (id) initWithData: (NSData*)data;
- (id) initWithPasteboard: (NSPasteboard*)pasteboard;
- (id) initWithSize: (NSSize)aSize;

#ifndef STRICT_OPENSTEP
- (id)initWithBitmapHandle:(void *)bitmap;
- (id)initWithContentsOfURL:(NSURL *)anURL;
- (id)initWithIconHandle:(void *)icon;
#endif

//
// Setting the Size of the Image 
//
- (void) setSize: (NSSize)aSize;
- (NSSize) size;

//
// Referring to Images by Name 
//
+ (id) imageNamed: (NSString*)aName;
- (BOOL) setName: (NSString*)aName;
- (NSString*) name;

//
// Specifying the Image 
//
- (void) addRepresentation: (NSImageRep*)imageRep;
- (void) addRepresentations: (NSArray*)imageRepArray;
- (void) lockFocus;
- (void) lockFocusOnRepresentation: (NSImageRep*)imageRep;
- (void) unlockFocus;

//
// Using the Image 
//
- (void) compositeToPoint: (NSPoint)aPoint
		operation: (NSCompositingOperation)op;
- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)aRect
		operation: (NSCompositingOperation)op;
- (void) dissolveToPoint: (NSPoint)aPoint
		fraction: (float)aFloat;
- (void) dissolveToPoint: (NSPoint)aPoint
		fromRect: (NSRect)aRect
		fraction: (float)aFloat;

#ifndef STRICT_OPENSTEP
- (void) compositeToPoint: (NSPoint)aPoint
		 fromRect: (NSRect)srcRect
		operation: (NSCompositingOperation)op
		 fraction: (float)delta;
- (void) compositeToPoint: (NSPoint)aPoint
		operation: (NSCompositingOperation)op
		 fraction: (float)delta;
#endif 

//
// Choosing Which Image Representation to Use 
//
- (void) setPrefersColorMatch: (BOOL)flag;
- (BOOL) prefersColorMatch;
- (void) setUsesEPSOnResolutionMismatch: (BOOL)flag;
- (BOOL) usesEPSOnResolutionMismatch;
- (void) setMatchesOnMultipleResolution: (BOOL)flag;
- (BOOL) matchesOnMultipleResolution;

//
// Getting the Representations 
//
- (NSImageRep*) bestRepresentationForDevice: (NSDictionary*)deviceDescription;
- (NSArray*) representations;
- (void) removeRepresentation: (NSImageRep*)imageRep;

//
// Determining How the Image is Stored 
//
- (void) setCachedSeparately: (BOOL)flag;
- (BOOL) isCachedSeparately;
- (void) setDataRetained: (BOOL)flag;
- (BOOL) isDataRetained;
- (void) setCacheDepthMatchesImageDepth: (BOOL)flag;
- (BOOL) cacheDepthMatchesImageDepth;

//
// Drawing 
//
- (BOOL) drawRepresentation: (NSImageRep*)imageRep
		     inRect: (NSRect)aRect;
#ifndef STRICT_OPENSTEP
- (void) drawAtPoint: (NSPoint)point
	    fromRect: (NSRect)srcRect
	   operation: (NSCompositingOperation)op
	    fraction: (float)delta;
- (void) drawInRect: (NSRect)dstRect
	   fromRect: (NSRect)srcRect
	  operation: (NSCompositingOperation)op
	   fraction: (float)delta;
#endif 

//
// Determining How the Image is Drawn 
//
- (BOOL) isValid;
- (void) setScalesWhenResized: (BOOL)flag;
- (BOOL) scalesWhenResized;
- (void) setBackgroundColor: (NSColor*)aColor;
- (NSColor*) backgroundColor;
- (void) recache;
- (void) setFlipped: (BOOL)flag;
- (BOOL) isFlipped;

//
// Assigning a Delegate 
//
- (void) setDelegate: (id)anObject;
- (id) delegate;

//
// Producing TIFF Data for the Image 
//
- (NSData*) TIFFRepresentation;
- (NSData*) TIFFRepresentationUsingCompression: (NSTIFFCompression)comp
					factor: (float)aFloat;

//
// Managing NSImageRep Subclasses 
//
+ (NSArray*) imageUnfilteredFileTypes;
+ (NSArray*) imageUnfilteredPasteboardTypes;

//
// Testing Image Data Sources 
//
+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard;
+ (NSArray*) imageFileTypes;
+ (NSArray*) imagePasteboardTypes;

@end


@interface NSBundle (NSImageAdditions)

- (NSString*) pathForImageResource: (NSString*)name;

@end

#ifndef	NO_GNUSTEP
/*
 * A formal protocol that duplicates the informal protocol for delegates.
 */
@protocol GSImageDelegateProtocol

- (NSImage*) imageDidNotDraw: (id)sender
		      inRect: (NSRect)aRect;

@end
#endif

#endif // _GNUstep_H_NSImage

