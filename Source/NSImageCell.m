/** <title>NSImageCell</title>

   <abstract>The image cell class</abstract>

   Copyright (C) 1999, 2005 Free Software Foundation, Inc.

   Author: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

   This file is part of the GNUstep GUI Library.

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
#include <Foundation/NSDebug.h>
#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSCell.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImageCell.h"
#include "AppKit/NSImage.h"
#include "GNUstepGUI/GSTheme.h"
#include "GSGuiPrivate.h"

@implementation NSImageCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSImageCell class])
    {
      [self setVersion: 1];
    }
}

//
// Instance methods
//
- (id) init
{
  return [self initImageCell: nil];
}

- (void) setImage:(NSImage *)anImage
{
  [super setImage:anImage];
  if (anImage)
    _original_image_size = [anImage size];
  else
    _original_image_size = NSMakeSize(1,1);
}

- (void)setObjectValue:(id)object
{
  if ((object == nil) || ([object isKindOfClass:[NSImage class]]))
    {
      [self setImage: object];
    }
  else
    {
      [super setObjectValue: object];
    }
}

//
// Aligning and scaling the image
//
- (NSImageAlignment) imageAlignment
{
  return _imageAlignment;
}

- (void) setImageAlignment: (NSImageAlignment)anAlignment
{
  NSDebugLLog(@"NSImageCell", @"NSImageCell -setImageAlignment");
  _imageAlignment = anAlignment;
}

- (NSImageScaling) imageScaling
{
  return _imageScaling;
}

- (void) setImageScaling: (NSImageScaling)scaling
{
  _imageScaling = scaling;
}

//
// Choosing the frame
//
- (NSImageFrameStyle) imageFrameStyle
{
  return _frameStyle;
}

- (void) setImageFrameStyle: (NSImageFrameStyle)aFrameStyle
{
  // We could set _cell.is_bordered and _cell.is_bezeled here to
  // reflect the border type, but this wont be used.
  _frameStyle = aFrameStyle;
}

//
// Displaying
//
- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame 
                                    inView: (NSView *)controlView
{
  NSDebugLLog(@"NSImageCell", @"NSImageCell -_drawBorderAndBackgroundWithFrame");
  [[GSTheme theme] drawBorderForImageFrameStyle: _frameStyle 
                   frame: cellFrame 
                   view: controlView];
}

static inline float
xLeftInRect(NSSize innerSize, NSRect outerRect)
{
  return NSMinX(outerRect);
}

static inline float
xCenterInRect(NSSize innerSize, NSRect outerRect)
{
  return MAX(NSMidX(outerRect) - (innerSize.width/2.0), 0.0);
}

static inline float
xRightInRect(NSSize innerSize, NSRect outerRect)
{
  return MAX(NSMaxX(outerRect) - innerSize.width, 0.0);
}

static inline float
yTopInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  if (flipped)
    return NSMinY(outerRect);
  else
    return MAX(NSMaxY(outerRect) - innerSize.height, 0.0);
}

static inline float
yCenterInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  return MAX(NSMidY(outerRect) - innerSize.height/2.0, 0.0);
}

static inline float
yBottomInRect(NSSize innerSize, NSRect outerRect, BOOL flipped)
{
  if (flipped)
    return MAX(NSMaxY(outerRect) - innerSize.height, 0.0);
  else
    return NSMinY(outerRect);
}

static inline NSSize
scaleProportionally(NSSize imageSize, NSRect canvasRect)
{
  float ratio;

  /* Get the smaller ratio and scale the image size by it.  */
  ratio = MIN(NSWidth(canvasRect) / imageSize.width,
	      NSHeight(canvasRect) / imageSize.height);
  
  /* According to the API (see NSScaleProportionally), we should never
   * scale images up; we only scale them down.  If you want your image
   * to scale both up and down, you should use NSScaleToFit.
   */
  if (ratio < 1.0)
    {
      imageSize.width *= ratio;
      imageSize.height *= ratio;
    }

  return imageSize;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSPoint	position;
  BOOL		is_flipped = [controlView isFlipped];
  NSSize  imageSize, realImageSize;
  NSAffineTransform *xform = nil;

  NSDebugLLog(@"NSImageCell", @"NSImageCell drawInteriorWithFrame called");

  if (!_cell_image)
    return;

  // leave room for the frame
  cellFrame = [self drawingRectForBounds: cellFrame];

  realImageSize = [_cell_image size];

  switch (_imageScaling)
    {
      case NSScaleProportionally:
        {
          NSDebugLLog(@"NSImageCell", @"NSScaleProportionally");
          imageSize = scaleProportionally (realImageSize, cellFrame);
          break;
        }
      case NSScaleToFit:
        {
          NSDebugLLog(@"NSImageCell", @"NSScaleToFit");
          imageSize = cellFrame.size;
          break;
        }
      default:
      case NSScaleNone:
        {
          NSDebugLLog(@"NSImageCell", @"NSScaleNone");
          imageSize = realImageSize;
          break;
        }
    }

  switch (_imageAlignment)
    {
      default:
      case NSImageAlignLeft:
        position.x = xLeftInRect(imageSize, cellFrame);
        position.y = yCenterInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignRight:
        position.x = xRightInRect(imageSize, cellFrame);
        position.y = yCenterInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignCenter:
        position.x = xCenterInRect(imageSize, cellFrame);
        position.y = yCenterInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignTop:
        position.x = xCenterInRect(imageSize, cellFrame);
        position.y = yTopInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignBottom:
        position.x = xCenterInRect(imageSize, cellFrame);
        position.y = yBottomInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignTopLeft:
        position.x = xLeftInRect(imageSize, cellFrame);
        position.y = yTopInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignTopRight:
        position.x = xRightInRect(imageSize, cellFrame);
        position.y = yTopInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignBottomLeft:
        position.x = xLeftInRect(imageSize, cellFrame);
        position.y = yBottomInRect(imageSize, cellFrame, is_flipped);
        break;
      case NSImageAlignBottomRight:
        position.x = xRightInRect(imageSize, cellFrame);
        position.y = yBottomInRect(imageSize, cellFrame, is_flipped);
        break;
    }

  // account for flipped views
  if (is_flipped && controlView != nil)
    {
      xform = [NSAffineTransform transform];
      [xform translateXBy: 0 yBy: [controlView bounds].size.height];
      [xform scaleXBy: 1 yBy: -1];
      [xform concat];
      position.y = [controlView bounds].size.height - position.y - imageSize.height;
    }

  // draw!
  [_cell_image drawInRect: NSMakeRect(position.x, position.y,
                                      imageSize.width, imageSize.height)
               fromRect: NSMakeRect(0, 0, realImageSize.width,
                                    realImageSize.height)
               operation: NSCompositeSourceOver
               fraction: 1.0];

  if (is_flipped && controlView != nil)
    {
      [xform invert];
      [xform concat];
    }
}

- (NSSize) cellSize
{
  NSSize borderSize, s;
  
  // Get border size
  borderSize = [[GSTheme theme] sizeForImageFrameStyle: _frameStyle];
  
  // Get Content Size
  s = _original_image_size;
  
  // Add in border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;
  
  return s;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // Get border size
  borderSize = [[GSTheme theme] sizeForImageFrameStyle: _frameStyle];
  return NSInsetRect (theRect, borderSize.width, borderSize.height);
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeInt: _imageAlignment forKey: @"NSAlign"];
      [aCoder encodeInt: _imageScaling forKey: @"NSScale"];
      [aCoder encodeInt: _frameStyle forKey: @"NSStyle"];
      [aCoder encodeBool: NO forKey: @"NSAnimates"];
    }
  else
    {
      [aCoder encodeValueOfObjCType: @encode(int) at: &_imageAlignment];
      [aCoder encodeValueOfObjCType: @encode(int) at: &_frameStyle];
      [aCoder encodeValueOfObjCType: @encode(int) at: &_imageScaling];
      [aCoder encodeSize: _original_image_size];
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    {
      if ([aDecoder allowsKeyedCoding])
	{
	  if ([aDecoder containsValueForKey: @"NSAlign"])
	    {
	      [self setImageAlignment: [aDecoder decodeIntForKey: @"NSAlign"]];
	    }
	  if ([aDecoder containsValueForKey: @"NSScale"])
	    {
	      [self setImageScaling: [aDecoder decodeIntForKey: @"NSScale"]];
	    }
	  if ([aDecoder containsValueForKey: @"NSStyle"])
	    {
	      [self setImageFrameStyle: [aDecoder decodeIntForKey: @"NSStyle"]];
	    }
	  if ([aDecoder containsValueForKey: @"NSAnimates"])
	    {
	      //BOOL animates = [aDecoder decodeBoolForKey: @"NSAnimates"];
	    }
	}
      else
	{
	  [aDecoder decodeValueOfObjCType: @encode(int) at: &_imageAlignment];
	  [aDecoder decodeValueOfObjCType: @encode(int) at: &_frameStyle];
	  [aDecoder decodeValueOfObjCType: @encode(int) at: &_imageScaling];
	  _original_image_size = [aDecoder decodeSize];
	}
    }
  return self;
}

@end
