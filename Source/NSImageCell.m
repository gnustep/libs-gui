/*
   NSImageCell.m

   The image cell class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen   <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

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

#include <gnustep/gui/config.h>
#include <Foundation/NSDebug.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImage.h>

@implementation NSImageCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSImageCell class])
    [self setVersion: 1];
}

//
// Instance methods
//
- (id) init
{
  [self initImageCell: nil];

  return self;
}

- (id) initImageCell: (NSImage *)anImage
{
  NSDebugLLog(@"NSImageCell", @"NSImageCell -initImageCell");
  [super initImageCell: anImage];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void)setImage:(NSImage *)anImage
{
  [super setImage:anImage];
  _original_image_size = [anImage size];
}

//
// Aligning and scaling the image
//
- (NSImageAlignment)imageAlignment
{
  return _imageAlignment;
}

- (void)setImageAlignment: (NSImageAlignment)anAlignment
{
  NSDebugLLog(@"NSImageCell", @"NSImageCell -setImageAlignment");
  _imageAlignment = anAlignment;
}

- (NSImageScaling)imageScaling
{
  return _imageScaling;
}

- (void)setImageScaling: (NSImageScaling)scaling
{
  _imageScaling = scaling;
}

//
// Choosing the frame
//
- (NSImageFrameStyle)imageFrameStyle
{
  return _frameStyle;
}

- (void)setImageFrameStyle: (NSImageFrameStyle)aFrameStyle
{
  _frameStyle = aFrameStyle;
}

//
// Displaying
//
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSDebugLLog(@"NSImageCell", @"NSImageCell -drawWithFrame");
  // Save last view drawn to
  [self setControlView: controlView];

  // do nothing if cell's frame rect is zero
  if( NSIsEmptyRect(cellFrame) )
    return;
  
  [controlView lockFocus];
  // draw the border if needed
  switch( [self imageFrameStyle] )
  {
    case NSImageFrameNone:
      // nada
      break;
    case NSImageFramePhoto:
      // what does this one look like? TODO (in sync with the rest of the code)
      break;
    case NSImageFrameGrayBezel:
      NSDrawGrayBezel(cellFrame, NSZeroRect);
      break;
    case NSImageFrameGroove:
      NSDrawGroove(cellFrame, NSZeroRect);
      break;
    case NSImageFrameButton:
      NSDrawButton(cellFrame, NSZeroRect);
      break;
  }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
  [controlView unlockFocus];
}

static inline float xLeftInRect(NSSize innerSize, NSRect outerRect)
{
  return NSMinX(outerRect);
}

static inline float xCenterInRect(NSSize innerSize, NSRect outerRect)
{
  return MAX(NSMidX(outerRect) - (innerSize.width/2.0), 0.0);
}

static inline float xRightInRect(NSSize innerSize, NSRect outerRect)
{
  return MAX(NSMaxX(outerRect) - innerSize.width, 0.0);
}

static inline float yTopInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  if( flipped )
    return NSMinY(outerRect);
  else
    return MAX(NSMaxY(outerRect) - innerSize.height, 0.0);
}

static inline float yCenterInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  return MAX(NSMidY(outerRect) - innerSize.height/2.0, 0.0);
}

static inline float yBottomInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  if( flipped )
    return MAX(NSMaxY(outerRect) - innerSize.height, 0.0);
  else
    return NSMinY(outerRect);
}

static inline NSSize scaleProportionally(NSSize imageSize, NSRect canvasRect)
{
  float ratio;

  // get the smaller ratio and scale the image size by it
  ratio = MIN(NSWidth(canvasRect) / imageSize.width,
                NSHeight(canvasRect) / imageSize.height);

  imageSize.width *= ratio;
  imageSize.height *= ratio;

  return imageSize;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSImage *image;
  NSPoint position;
  BOOL is_flipped = [controlView isFlipped];

  NSDebugLLog(@"NSImageCell", @"NSImageCell drawInteriorWithFrame called");

  image = [self image];
  if( !image )
    return;

  // leave room for the frame
  cellFrame = [self drawingRectForBounds: cellFrame];
  [controlView lockFocus];

  switch( [self imageScaling] )
  {
    case NSScaleProportionally:
    {
      NSDebugLLog(@"NSImageCell", @"NSScaleProportionally");
      [image setScalesWhenResized:YES];
      [image setSize: scaleProportionally(_original_image_size, cellFrame)];
      break;
    }
    case NSScaleToFit:
    {
      NSDebugLLog(@"NSImageCell", @"NSScaleToFit");
      [image setScalesWhenResized:YES];
      [image setSize: cellFrame.size];
      break;
    }
    case NSScaleNone:
    {
      NSDebugLLog(@"NSImageCell", @"NSScaleNone");
      [image setScalesWhenResized:NO];
      // don't let the image size overrun the space available
      if( _original_image_size.width > cellFrame.size.width ||
             _original_image_size.height > cellFrame.size.height )
        [image setSize: cellFrame.size];
      else
        [image setSize: _original_image_size];
      break;
    }
  }

  switch( [self imageAlignment] )
  {
    case NSImageAlignLeft:
      position.x = xLeftInRect([image size], cellFrame);
      position.y = yCenterInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignRight:
      position.x = xRightInRect([image size], cellFrame);
      position.y = yCenterInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignCenter:
      position.x = xCenterInRect([image size], cellFrame);
      position.y = yCenterInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignTop:
      position.x = xCenterInRect([image size], cellFrame);
      position.y = yTopInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignBottom:
      position.x = xCenterInRect([image size], cellFrame);
      position.y = yBottomInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignTopLeft:
      position.x = xLeftInRect([image size], cellFrame);
      position.y = yTopInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignTopRight:
      position.x = xRightInRect([image size], cellFrame);
      position.y = yTopInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignBottomLeft:
      position.x = xLeftInRect([image size], cellFrame);
      position.y = yBottomInRect([image size], cellFrame, is_flipped);
      break;
    case NSImageAlignBottomRight:
      position.x = xRightInRect([image size], cellFrame);
      position.y = yBottomInRect([image size], cellFrame, is_flipped);
      break;
  }

  // account for flipped views
  if( is_flipped )
    position.y += [image size].height;

  // draw!
  [image compositeToPoint: position operation: NSCompositeCopy];
  [controlView unlockFocus];
}

- (NSSize) cellSize
{
  NSSize borderSize, s;
  
  // Get border size
  switch (_frameStyle)
    {
    case NSImageFrameNone:
      borderSize = [NSCell sizeForBorderType: NSNoBorder];
      break;
    case NSImageFramePhoto:
      // what does this one look like? TODO (in sync with the rest of the code)
      borderSize = [NSCell sizeForBorderType: NSNoBorder];
      break;
    case NSImageFrameGrayBezel:
    case NSImageFrameGroove:
    case NSImageFrameButton:
      borderSize = [NSCell sizeForBorderType: NSBezelBorder]; 
      break;
    }
  
  // Get Content Size
  s = _original_image_size;
  
  // Add in border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;
  
  return s;
}

- (NSSize) cellSizeForBounds: (NSRect)aRect
{
  // TODO
  return NSZeroSize;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // Get border size
  switch (_frameStyle)
    {
    case NSImageFrameNone:
      borderSize = [NSCell sizeForBorderType: NSNoBorder];
      break;
    case NSImageFramePhoto:
      // what does this one look like? TODO (in sync with the rest of the code)
      borderSize = [NSCell sizeForBorderType: NSNoBorder];
      break;
    case NSImageFrameGrayBezel:
    case NSImageFrameGroove:
    case NSImageFrameButton:
      borderSize = [NSCell sizeForBorderType: NSBezelBorder]; 
      break;
    }

  return NSInsetRect (theRect, borderSize.width, borderSize.height);
}

- (id) copyWithZone: (NSZone *)zone
{
  NSImageCell *c = [super copyWithZone: zone];

  c->_imageAlignment = _imageAlignment;
  c->_frameStyle = _frameStyle;
  c->_imageScaling = _imageScaling;
  c->_original_image_size = _original_image_size;

  return c;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];

  NSDebugLog(@"NSImageCell: start encoding");
  [aCoder encodeValueOfObjCType: @encode(NSImageAlignment) at: &_imageAlignment];
  [aCoder encodeValueOfObjCType: @encode(NSImageFrameStyle) at: &_frameStyle];
  [aCoder encodeValueOfObjCType: @encode(NSImageScaling) at: &_imageScaling];
  [aCoder encodeSize: _original_image_size];
  NSDebugLog(@"NSImageCell: finish encoding");
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  [super initWithCoder: aDecoder];

  NSDebugLog(@"NSImageCell: start decoding");
  [aDecoder decodeValueOfObjCType: @encode(NSImageAlignment) at: &_imageAlignment];
  [aDecoder decodeValueOfObjCType: @encode(NSImageFrameStyle) at: &_frameStyle];
  [aDecoder decodeValueOfObjCType: @encode(NSImageScaling) at: &_imageScaling];
  _original_image_size = [aDecoder decodeSize];
  NSDebugLog(@"NSImageCell: finish decoding");

  return self;
}

@end
