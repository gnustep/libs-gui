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

#include <AppKit/stdappkit.h>
#include <DPSClient/TypesandConstants.h>
#include <AppKit/NSBundle.h>

@class NSPasteboard;
@class NSMutableArray;
@class NSImageRep;
@class NSColor;
@class NSView;

@interface NSImage : NSObject <NSCoding>

{
  // Attributes
  NSString*	name;
  NSSize	_size;
  struct __imageFlags {
    unsigned int        scalable:1;
    unsigned int        dataRetained:1;
    unsigned int        flipDraw:1;
    unsigned int        uniqueWindow:1;
    unsigned int        uniqueWasExplicitlySet:1;
    unsigned int        sizeWasExplicitlySet:1;
    unsigned int        builtIn:1;
    unsigned int        needsToExpand:1;
    unsigned int        useEPSOnResolutionMismatch:1;
    unsigned int        colorMatchPreferred:1;
    unsigned int        multipleResolutionMatching:1;
    unsigned int        subImage:1;
    unsigned int	    aSynch:1;
    unsigned int	    archiveByName:1;
    unsigned int        cacheSeparately:1;
    unsigned int	    unboundedCacheDepth:1;
  }                   _flags;
  NSMutableArray*     _reps;
  NSMutableArray*	_repList;
  NSColor*	_color;
  BOOL	_syncLoad;
  NSView*	_lockedView;
  id		delegate;
}

//
// Initializing a New NSImage Instance 
//
- (id)initByReferencingFile:(NSString *)filename;
- (id)initWithContentsOfFile:(NSString *)filename;
- (id)initWithData:(NSData *)data;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;
- (id)initWithSize:(NSSize)aSize;

//
// Setting the Size of the Image 
//
- (void)setSize:(NSSize)aSize;
- (NSSize)size;

//
// Referring to Images by Name 
//
+ (id)imageNamed:(NSString *)name;
- (BOOL)setName:(NSString *)name;
- (NSString *)name;

//
// Specifying the Image 
//
- (void)addRepresentation:(NSImageRep *)imageRep;
- (void)addRepresentations:(NSArray *)imageRepArray;
- (void)lockFocus;
- (void)lockFocusOnRepresentation:(NSImageRep *)imageRep;
- (void)unlockFocus;

//
// Using the Image 
//
- (void)compositeToPoint:(NSPoint)aPoint
	       operation:(NSCompositingOperation)op;
- (void)compositeToPoint:(NSPoint)aPoint
		fromRect:(NSRect)aRect
	       operation:(NSCompositingOperation)op;
- (void)dissolveToPoint:(NSPoint)aPoint
	       fraction:(float)aFloat;
- (void)dissolveToPoint:(NSPoint)aPoint
	       fromRect:(NSRect)aRect
	       fraction:(float)aFloat;

//
// Choosing Which Image Representation to Use 
//
- (void)setPrefersColorMatch:(BOOL)flag;
- (BOOL)prefersColorMatch;
- (void)setUsesEPSOnResolutionMismatch:(BOOL)flag;
- (BOOL)usesEPSOnResolutionMismatch;
- (void)setMatchesOnMultipleResolution:(BOOL)flag;
- (BOOL)matchesOnMultipleResolution;

//
// Getting the Representations 
//
- (NSImageRep *)bestRepresentationForDevice:(NSDictionary *)deviceDescription;
- (NSArray *)representations;
- (void)removeRepresentation:(NSImageRep *)imageRep;

//
// Determining How the Image is Stored 
//
- (void)setCachedSeparately:(BOOL)flag;
- (BOOL)isCachedSeparately;
- (void)setDataRetained:(BOOL)flag;
- (BOOL)isDataRetained;
- (void)setCacheDepthMatchesImageDepth:(BOOL)flag;
- (BOOL)cacheDepthMatchesImageDepth;

//
// Determining How the Image is Drawn 
//
- (BOOL)isValid;
- (void)setScalesWhenResized:(BOOL)flag;
- (BOOL)scalesWhenResized;
- (void)setBackgroundColor:(NSColor *)aColor;
- (NSColor *)backgroundColor;
- (BOOL)drawRepresentation:(NSImageRep *)imageRep
		    inRect:(NSRect)aRect;
- (void)recache;

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject;
- (id)delegate;

//
// Producing TIFF Data for the Image 
//
- (NSData *)TIFFRepresentation;
- (NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)comp
					factor:(float)aFloat;

//
// Managing NSImageRep Subclasses 
//
+ (NSArray *)imageUnfilteredFileTypes;
+ (NSArray *)imageUnfilteredPasteboardTypes;

//
// Testing Image Data Sources 
//
+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard;
+ (NSArray *)imageFileTypes;
+ (NSArray *)imagePasteboardTypes;

//
// Methods Implemented by the Delegate 
//
- (NSImage *)imageDidNotDraw:(id)sender
		      inRect:(NSRect)aRect;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSImage
