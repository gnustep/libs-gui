/* 
   NSImage.m

   Graphical images

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

#include <gnustep/gui/NSImage.h>

@implementation NSImage

//
// Initializing a New NSImage Instance 
//
- (id)initByReferencingFile:(NSString *)filename
{
  return nil;
}

- (id)initWithContentsOfFile:(NSString *)filename
{
  return nil;
}

- (id)initWithData:(NSData *)data
{
  return nil;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  return nil;
}

- (id)initWithSize:(NSSize)aSize
{
  return nil;
}

//
// Setting the Size of the Image 
//
- (void)setSize:(NSSize)aSize
{}

- (NSSize)size
{
  return NSZeroSize;
}

//
// Referring to Images by Name 
//
+ (id)imageNamed:(NSString *)name
{
  return nil;
}

- (BOOL)setName:(NSString *)name
{
  return NO;
}

- (NSString *)name
{
  return nil;
}

//
// Specifying the Image 
//
- (void)addRepresentation:(NSImageRep *)imageRep
{}

- (void)addRepresentations:(NSArray *)imageRepArray
{}

- (void)lockFocus
{}

- (void)lockFocusOnRepresentation:(NSImageRep *)imageRep
{}

- (void)unlockFocus
{}

//
// Using the Image 
//
- (void)compositeToPoint:(NSPoint)aPoint
	       operation:(NSCompositingOperation)op
{}

- (void)compositeToPoint:(NSPoint)aPoint
		fromRect:(NSRect)aRect
operation:(NSCompositingOperation)op
{}

- (void)dissolveToPoint:(NSPoint)aPoint
	       fraction:(float)aFloat
{}

- (void)dissolveToPoint:(NSPoint)aPoint
	       fromRect:(NSRect)aRect
fraction:(float)aFloat
{}

//
// Choosing Which Image Representation to Use 
//
- (void)setPrefersColorMatch:(BOOL)flag
{}

- (BOOL)prefersColorMatch
{
  return NO;
}

- (void)setUsesEPSOnResolutionMismatch:(BOOL)flag
{}

- (BOOL)usesEPSOnResolutionMismatch
{
  return NO;
}

- (void)setMatchesOnMultipleResolution:(BOOL)flag
{}

- (BOOL)matchesOnMultipleResolution
{
  return NO;
}

//
// Getting the Representations 
//
- (NSImageRep *)bestRepresentationForDevice:(NSDictionary *)deviceDescription
{
  return nil;
}

- (NSArray *)representations
{
  return nil;
}

- (void)removeRepresentation:(NSImageRep *)imageRep
{}

//
// Determining How the Image is Stored 
//
- (void)setCachedSeparately:(BOOL)flag
{}

- (BOOL)isCachedSeparately
{
  return NO;
}

- (void)setDataRetained:(BOOL)flag
{}

- (BOOL)isDataRetained
{
  return NO;
}

- (void)setCacheDepthMatchesImageDepth:(BOOL)flag
{}

- (BOOL)cacheDepthMatchesImageDepth
{
  return NO;
}

//
// Determining How the Image is Drawn 
//
- (BOOL)isValid
{
  return NO;
}

- (void)setScalesWhenResized:(BOOL)flag
{}

- (BOOL)scalesWhenResized
{
  return NO;
}

- (void)setBackgroundColor:(NSColor *)aColor
{}

- (NSColor *)backgroundColor
{
  return nil;
}

- (BOOL)drawRepresentation:(NSImageRep *)imageRep
		    inRect:(NSRect)aRect
{
  return NO;
}

- (void)recache
{}

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject
{}

- (id)delegate
{
  return nil;
}

//
// Producing TIFF Data for the Image 
//
- (NSData *)TIFFRepresentation
{
  return nil;
}

- (NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)comp
					factor:(float)aFloat
{
  return nil;
}

//
// Managing NSImageRep Subclasses 
//
+ (NSArray *)imageUnfilteredFileTypes
{
  return nil;
}

+ (NSArray *)imageUnfilteredPasteboardTypes
{
  return nil;
}

//
// Testing Image Data Sources 
//
+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard
{
  return NO;
}

+ (NSArray *)imageFileTypes
{
  return nil;
}

+ (NSArray *)imagePasteboardTypes
{
  return nil;
}

//
// Methods Implemented by the Delegate 
//
- (NSImage *)imageDidNotDraw:(id)sender
		      inRect:(NSRect)aRect
{
  return nil;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end

