/* 
   NSImage.h

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

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

#ifndef _GNUstep_H_NSImage
#define _GNUstep_H_NSImage

#include <AppKit/stdappkit.h>
#include <DPSClient/TypesandConstants.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSImageRep.h>
#include <Foundation/NSCoder.h>

@interface NSImage : NSObject <NSCoding>

{
  // Attributes
  NSSize image_size;
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
