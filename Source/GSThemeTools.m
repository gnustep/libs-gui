/** <title>GSThemeTools</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Jan 2004
   
   This file is part of the GNU Objective C User interface library.

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

#import "AppKit/NSBezierPath.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/PSOperators.h"
#import "GSThemePrivate.h"

#include <math.h>
#include <float.h>


@implementation	GSTheme (MidLevelDrawing)

- (NSRect) drawButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {black, black, white, white, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

- (NSRect) drawDarkBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			   NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark, black, black, light, light};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
  
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
  
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawDarkButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge}; 
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge}; 
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *white = [NSColor controlHighlightColor];
  NSColor *colors[] = {black, black, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

- (NSRect) drawFramePhoto: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *colors[] = {dark, dark, dark, dark, 
		       black,black};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

#if 1
- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
                       inRect: (NSRect)border 
                     withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge};
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor **colors;
  NSColor *concaveWeak[] = {dark, dark, light, light};
  NSColor *concaveStrong[] = {black, black, light, light};
  NSColor *convexWeak[] = {light, light, dark, dark};
  NSColor *convexStrong[] = {light, light, black, black};
  NSRect rect;
  
  switch (gradientType)
    {
      case NSGradientConcaveWeak:
	colors = concaveWeak;
	break;
      case NSGradientConcaveStrong:
	colors = concaveStrong;
	break;
      case NSGradientConvexWeak:
	colors = convexWeak;
	break;
      case NSGradientConvexStrong:
	colors = convexStrong;
	break;
      case NSGradientNone:
      default:
	return border;
    }

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
 
  return rect;
}

#else
// FIXME: I think this method is wrong.
- (NSRect) drawGradientBorder: (NSGradientType)gradientType 
                       inRect: (NSRect)cellFrame 
                     withClip: (NSRect)clip
{
  float   start_white = 0.0;
  float   end_white = 0.0;
  float   white = 0.0;
  float   white_step = 0.0;
  float   h, s, v, a;
  NSPoint p1, p2;
  NSColor *gray = nil;
  NSColor *darkGray = nil;
  NSColor *lightGray = nil;

  lightGray = [NSColor colorWithDeviceRed: NSLightGray 
                       green: NSLightGray 
                       blue: NSLightGray 
                       alpha:1.0];
  gray = [NSColor colorWithDeviceRed: NSGray 
                  green: NSGray 
                  blue: NSGray 
                  alpha:1.0];
  darkGray = [NSColor colorWithDeviceRed: NSDarkGray 
                      green: NSDarkGray 
                      blue: NSDarkGray 
                      alpha:1.0];

  switch (gradientType)
    {
      case NSGradientNone:
        return NSZeroRect;
        break;

      case NSGradientConcaveWeak:
        [gray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [gray brightnessComponent];
        break;
        
      case NSGradientConvexWeak:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [gray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;
        
      case NSGradientConcaveStrong:
        [lightGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [darkGray brightnessComponent];
        break;
        
      case NSGradientConvexStrong:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [darkGray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;

      default:
        break;
    }

  white = start_white;
  white_step = fabs(start_white - end_white)
    / (cellFrame.size.width + cellFrame.size.height);

  // Start from top left
  p1 = NSMakePoint(cellFrame.origin.x,
    cellFrame.size.height + cellFrame.origin.y);
  p2 = NSMakePoint(cellFrame.origin.x, 
    cellFrame.size.height + cellFrame.origin.y);

  // Move by Y
  while (p1.y > cellFrame.origin.y)
    {
      [[NSColor 
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
      
      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.y -= 1.0;
      if (p2.x < (cellFrame.size.width + cellFrame.origin.x))
        p2.x += 1.0;
      else
        p2.y -= 1.0;
    }
      
  // Move by X
  while (p1.x < (cellFrame.size.width + cellFrame.origin.x))
    {
      [[NSColor 
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
      
      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.x += 1.0;
      if (p2.x >= (cellFrame.size.width + cellFrame.origin.x))
        p2.y -= 1.0;
      else
        p2.x += 1.0;
    }

  return NSZeroRect;
}

#endif

- (NSRect) drawGrayBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			     NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, black, black};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMaxY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMinY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawGroove: (NSRect)border withClip: (NSRect)clip
{
  // go clockwise from the top twice -- makes the groove come out right
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
			   NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       white, dark, dark, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawLightBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge, 
  			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawWhiteBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
  			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, 
  			     NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       dark, light, light, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (void) drawRoundBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor
{
  NSBezierPath *p = [NSBezierPath bezierPath];
  NSPoint point;
  float radius;

  // make smaller than enclosing frame
  cellFrame = NSInsetRect(cellFrame, 4, floor(cellFrame.size.height * 0.1875));
  radius = cellFrame.size.height / 2.0;
  point = cellFrame.origin;
  point.x += radius;
  point.y += radius;
  // left half-circle
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 90.0
			      endAngle: 270.0];

  // line to first point and right halfcircle
  point.x += cellFrame.size.width - cellFrame.size.height;
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 270.0
			      endAngle: 90.0];
  [p closePath];

  // fill with background color
  [backgroundColor set];
  [p fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [p stroke];
}

- (void) drawCircularBezel: (NSRect)cellFrame
		 withColor: (NSColor*)backgroundColor
{
  // make smaller so that it does not touch frame
  NSBezierPath *oval;

  oval = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(cellFrame, 1, 1)];

  // fill oval with background color
  [backgroundColor set];
  [oval fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [oval stroke];
}

@end



@implementation	GSTheme (LowLevelDrawing)

- (void) fillHorizontalRect: (NSRect)rect
		  withImage: (NSImage*)image
		   fromRect: (NSRect)source
		    flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSBezierPath		*path;
  unsigned		repetitions;
  unsigned		count;
  float			y;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = (rect.size.width / source.size.width) + 1;
  y = rect.origin.y;

  if (flipped) y = rect.origin.y + rect.size.height;
  
  for (count = 0; count < repetitions; count++)
    {
      NSPoint p = NSMakePoint (rect.origin.x + count * source.size.width, y);

      [image compositeToPoint: p
		     fromRect: source
		    operation: NSCompositeSourceOver];
    }
  DPSgrestore (ctxt);	
}

- (void) fillRect: (NSRect)rect
withRepeatedImage: (NSImage*)image
	 fromRect: (NSRect)source
	   center: (BOOL)center
{
  NSGraphicsContext	*ctxt = GSCurrentContext ();
  NSBezierPath		*path;
  NSSize		size;
  unsigned		xrepetitions;
  unsigned		yrepetitions;
  unsigned		x;
  unsigned		y;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  size = [image size];
  xrepetitions = (rect.size.width / size.width) + 1;
  yrepetitions = (rect.size.height / size.height) + 1;

  for (x = 0; x < xrepetitions; x++)
    {
      for (y = 0; y < yrepetitions; y++)
	{
	  NSPoint p;

	  p = NSMakePoint (rect.origin.x + x * size.width,
	    rect.origin.y + y * size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
      }
  }
  DPSgrestore (ctxt);	
}

- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
	 background: (NSColor*)color
	  fillStyle: (GSThemeFillStyle)style
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSSize		tls = tiles->rects[TileTL].size;
  NSSize		tms = tiles->rects[TileTM].size;
  NSSize		trs = tiles->rects[TileTR].size;
  NSSize		cls = tiles->rects[TileCL].size;
  NSSize		crs = tiles->rects[TileCR].size;
  NSSize		bls = tiles->rects[TileBL].size;
  NSSize		bms = tiles->rects[TileBM].size;
  NSSize		brs = tiles->rects[TileBR].size;
  NSRect		inFill;
  BOOL			flipped = [[ctxt focusView] isFlipped];

  if (color == nil)
    {
      [[NSColor redColor] set];
    }
  else
    {
      [color set];
    }
  NSRectFill(rect);

  if (style == GSThemeFillStyleMatrix)
    {
      NSRect	grid;
      float	x;
      float	y;
      float	space = 3.0;
      float	scale;

      inFill = NSZeroRect;
      if (tiles->images[TileTM] == nil)
        {
	  grid.size.width = (tiles->rects[TileTL].size.width
	    + tiles->rects[TileTR].size.width
	    + space * 3.0);
	}
      else
        {
	  grid.size.width = (tiles->rects[TileTL].size.width
	    + tiles->rects[TileTM].size.width
	    + tiles->rects[TileTR].size.width
	    + space * 4.0);
	}
      scale = floor(rect.size.width / grid.size.width);

      if (tiles->images[TileCL] == nil)
        {
	  grid.size.height = (tiles->rects[TileTL].size.height
	    + tiles->rects[TileBL].size.height
	    + space * 3.0);
	}
      else
        {
	  grid.size.height = (tiles->rects[TileTL].size.height
	    + tiles->rects[TileCL].size.height
	    + tiles->rects[TileBL].size.height
	    + space * 4.0);
	}
      if ((rect.size.height / grid.size.height) < scale)
        {
	  scale = floor(rect.size.height / grid.size.height);
	}

      if (scale > 1)
        {
	  /* We can scale up by an integer number of pixels and still
	   * fit in the rectangle.
	   */
	  grid.size.width *= scale;
	  grid.size.height *= scale;
	  space *= scale;
	  tiles = AUTORELEASE([tiles copy]);
	  [tiles scaleUp: (int)scale];
	}

      grid.origin.x = rect.origin.x + (rect.size.width - grid.size.width) / 2;
      x = grid.origin.x;
      if (flipped)
        {
	  grid.origin.y
	    = NSMaxY(rect) - (rect.size.height - grid.size.height) / 2;
	  y = NSMaxY(grid);
	}
      else
        {
	  grid.origin.y
	    = rect.origin.y + (rect.size.height - grid.size.height) / 2;
	  y = grid.origin.y;
	}

      /* Draw bottom row
       */
      if (flipped)
        {
          y -= (tiles->rects[TileBL].size.height + space);
	}
      else
        {
	  y += space;
	}
      [tiles->images[TileBL] compositeToPoint: NSMakePoint(x, y)
        fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      x += tiles->rects[TileBL].size.width + space;
      if (tiles->images[TileBM] != nil)
        {
	  [tiles->images[TileBM] compositeToPoint: NSMakePoint(x, y)
            fromRect: tiles->rects[TileBM]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileBM].size.width + space;
	}
      [tiles->images[TileBR] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];
      if (!flipped)
        {
          y += tiles->rects[TileBL].size.height;
	}

      if (tiles->images[TileCL] != nil)
	{
	  /* Draw middle row
	   */
	  x = grid.origin.x;
	  if (flipped)
	    {
	      y -= (tiles->rects[TileCL].size.height + space);
	    }
	  else
	    {
	      y += space;
	    }
	  [tiles->images[TileCL] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileCL]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileCL].size.width + space;
	  if (tiles->images[TileCM] != nil)
	    {
	      [tiles->images[TileCM] compositeToPoint: NSMakePoint(x, y)
		fromRect: tiles->rects[TileCM]
		operation: NSCompositeSourceOver];
	      x += tiles->rects[TileCM].size.width + space;
	    }
	  [tiles->images[TileCR] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileCR]
	    operation: NSCompositeSourceOver];
	  if (!flipped)
	    {
	      y += tiles->rects[TileCL].size.height;
	    }
	}

      /* Draw top row
       */
      x = grid.origin.x;
      if (flipped)
	{
	  y -= (tiles->rects[TileTL].size.height + space);
	}
      else
	{
	  y += space;
	}
      [tiles->images[TileTL] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      x += tiles->rects[TileTL].size.width + space;
      if (tiles->images[TileTM] != nil)
	{
	  [tiles->images[TileTM] compositeToPoint: NSMakePoint(x, y)
	    fromRect: tiles->rects[TileTM]
	    operation: NSCompositeSourceOver];
	  x += tiles->rects[TileTM].size.width + space;
	}
      [tiles->images[TileTR] compositeToPoint: NSMakePoint(x, y)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
    }
  else if (flipped)
    {
      [self fillHorizontalRect:
	NSMakeRect (rect.origin.x + bls.width,
	  rect.origin.y + rect.size.height - bms.height,
	  rect.size.width - bls.width - brs.width,
	  bms.height)
	withImage: tiles->images[TileBM]
	fromRect: tiles->rects[TileBM]
	flipped: YES];
      [self fillHorizontalRect:
	NSMakeRect (rect.origin.x + tls.width,
	  rect.origin.y,
	  rect.size.width - tls.width - trs.width,
	  tms.height)
	withImage: tiles->images[TileTM]
	fromRect: tiles->rects[TileTM]
	flipped: YES];
      [self fillVerticalRect:
	NSMakeRect (rect.origin.x,
	  rect.origin.y + bls.height,
	  cls.width,
	  rect.size.height - bls.height - tls.height)
	withImage: tiles->images[TileCL]
	fromRect: tiles->rects[TileCL]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect (rect.origin.x + rect.size.width - crs.width,
	  rect.origin.y + brs.height,
	  crs.width,
	  rect.size.height - brs.height - trs.height)
	withImage: tiles->images[TileCR]
	fromRect: tiles->rects[TileCR]
	flipped: NO];

      [tiles->images[TileTL] compositeToPoint:
	NSMakePoint (rect.origin.x,
	  rect.origin.y)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileTR] compositeToPoint:
	NSMakePoint (rect.origin.x + rect.size.width - tls.width,
	rect.origin.y)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBL] compositeToPoint:
	NSMakePoint (rect.origin.x,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBR] compositeToPoint:
	NSMakePoint (rect.origin.x + rect.size.width - brs.width,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];

      inFill = NSMakeRect (rect.origin.x + cls.width,
	rect.origin.y + bms.height,
	rect.size.width - cls.width - crs.width,
	rect.size.height - bms.height - tms.height);
      if (style == GSThemeFillStyleCenter)
	{
	  NSRect	r = tiles->rects[TileCM];

	  r.origin.x
	    = inFill.origin.x + (inFill.size.width - r.size.width) / 2;
	  r.origin.y
	    = inFill.origin.y + (inFill.size.height - r.size.height) / 2;
	  r.origin.y += r.size.height;	// Allow for flip of image rectangle
	  [tiles->images[TileCM] compositeToPoint: r.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
	}
      else if (style == GSThemeFillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: NO];
	}
      else if (style == GSThemeFillStyleScale)
	{
	  NSImage	*im = [tiles->images[TileCM] copy];
	  NSRect	r =  tiles->rects[TileCM];
	  NSSize	s = [tiles->images[TileCM] size];
	  NSPoint	p = inFill.origin;
	  float		sx = inFill.size.width / r.size.width;
	  float		sy = inFill.size.height / r.size.height;

	  r.size.width = inFill.size.width;
	  r.size.height = inFill.size.height;
	  r.origin.x *= sx;
	  r.origin.y *= sy;
	  s.width *= sx;
	  s.height *= sy;
	  p.y += inFill.size.height;	// In flipped view
	  
	  [im setScalesWhenResized: YES];
	  [im setSize: s];
	  [im compositeToPoint: p
		      fromRect: r
		     operation: NSCompositeSourceOver];
	  RELEASE(im);
	}
    }
  else
    {
      [self fillHorizontalRect:
	NSMakeRect(
	  rect.origin.x + tls.width,
	  rect.origin.y + rect.size.height - tms.height,
	  rect.size.width - bls.width - brs.width,
	  tms.height)
	withImage: tiles->images[TileTM]
	fromRect: tiles->rects[TileTM]
	flipped: NO];
      [self fillHorizontalRect:
	NSMakeRect(
	  rect.origin.x + bls.width,
	  rect.origin.y,
	  rect.size.width - bls.width - brs.width,
	  bms.height)
	withImage: tiles->images[TileBM]
	fromRect: tiles->rects[TileBM]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect(
	  rect.origin.x,
	  rect.origin.y + bls.height,
	  cls.width,
	  rect.size.height - tls.height - bls.height)
	withImage: tiles->images[TileCL]
	fromRect: tiles->rects[TileCL]
	flipped: NO];
      [self fillVerticalRect:
	NSMakeRect(
	  rect.origin.x + rect.size.width - crs.width,
	  rect.origin.y + brs.height,
	  crs.width,
	  rect.size.height - trs.height - brs.height)
	withImage: tiles->images[TileCR]
	fromRect: tiles->rects[TileCR]
	flipped: NO];

      [tiles->images[TileTL] compositeToPoint:
	NSMakePoint (
	  rect.origin.x,
	  rect.origin.y + rect.size.height - tls.height)
	fromRect: tiles->rects[TileTL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileTR] compositeToPoint:
	NSMakePoint(
	  rect.origin.x + rect.size.width - trs.width,
	  rect.origin.y + rect.size.height - trs.height)
	fromRect: tiles->rects[TileTR]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBL] compositeToPoint:
	NSMakePoint(
	  rect.origin.x,
	  rect.origin.y)
	fromRect: tiles->rects[TileBL]
	operation: NSCompositeSourceOver];
      [tiles->images[TileBR] compositeToPoint:
	NSMakePoint(
	  rect.origin.x + rect.size.width - brs.width,
	  rect.origin.y)
	fromRect: tiles->rects[TileBR]
	operation: NSCompositeSourceOver];

      inFill = NSMakeRect (rect.origin.x +cls.width,
	rect.origin.y + bms.height,
	rect.size.width - cls.width - crs.width,
	rect.size.height - bms.height - tms.height);

      if (style == GSThemeFillStyleCenter)
	{
	  NSRect	r = tiles->rects[TileCM];

	  r.origin.x
	    = inFill.origin.x + (inFill.size.width - r.size.width) / 2;
	  r.origin.y
	    = inFill.origin.y + (inFill.size.height - r.size.height) / 2;
	  [tiles->images[TileCM] compositeToPoint: r.origin
					 fromRect: tiles->rects[TileCM]
					operation: NSCompositeSourceOver];
	}
      else if (style == GSThemeFillStyleRepeat)
	{
	  [self fillRect: inFill
	    withRepeatedImage: tiles->images[TileCM]
	    fromRect: tiles->rects[TileCM]
	    center: YES];
	}
      else if (style == GSThemeFillStyleScale)
	{
	  NSImage	*im = [tiles->images[TileCM] copy];
	  NSRect	r =  tiles->rects[TileCM];
	  NSSize	s = [tiles->images[TileCM] size];
	  NSPoint	p = inFill.origin;
	  float		sx = inFill.size.width / r.size.width;
	  float		sy = inFill.size.height / r.size.height;

	  r.size.width = inFill.size.width;
	  r.size.height = inFill.size.height;
	  r.origin.x *= sx;
	  r.origin.y *= sy;
	  s.width *= sx;
	  s.height *= sy;
	  

	  [im setScalesWhenResized: YES];
	  [im setSize: s];
	  [im compositeToPoint: p
		      fromRect: r
		     operation: NSCompositeSourceOver];
	  RELEASE(im);
	}
    }
  return inFill;
}

- (void) fillVerticalRect: (NSRect)rect
		withImage: (NSImage*)image
		 fromRect: (NSRect)source
		  flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSBezierPath		*path;
  unsigned		repetitions;
  unsigned		count;
  NSPoint		p;

  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = (rect.size.height / source.size.height) + 1;

  if (flipped)
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + rect.size.height - count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  else
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  DPSgrestore (ctxt);	
}

@end



@implementation	GSDrawTiles
- (id) copyWithZone: (NSZone*)zone
{
  GSDrawTiles	*c = (GSDrawTiles*)NSCopyObject(self, 0, zone);
  unsigned	i;

  c->images[0] = [images[0] copy];
  for (i = 1; i < 9; i++)
    {
      unsigned	j;

      for (j = 0; j < i; j++)
        {
	  if (images[i] == images[j])
	    {
	      break;
	    }
	}
      if (j < i)
        {
	  c->images[i] = RETAIN(c->images[j]);
	}
      else
        {
	  c->images[i] = [images[i] copy];
	}
    }
  return c;
}

- (void) dealloc
{
  unsigned	i;

  for (i = 0; i < 9; i++)
    {
      RELEASE(images[i]);
    }
  [super dealloc];
}

/**
 * Simple initialiser, assume the single image is split into nine equal tiles.
 * If the image size is not divisible by three, the corners are made equal
 * in size and the central parts slightly smaller.
 */
- (id) initWithImage: (NSImage*)image
{
  NSSize	s = [image size];

  return [self initWithImage: image
		  horizontal: s.width / 3.0
		    vertical: s.height / 3.0];
}

- (id) initWithImage: (NSImage*)image horizontal: (float)x vertical: (float)y
{
  unsigned	i;
  NSSize	s = [image size];

  x = floor(x);
  y = floor(y);

  rects[TileTL] = NSMakeRect(0.0, s.height - y, x, y);
  rects[TileTM] = NSMakeRect(x, s.height - y, s.width - 2.0 * x, y);
  rects[TileTR] = NSMakeRect(s.width - x, s.height - y, x, y);
  rects[TileCL] = NSMakeRect(0.0, y, x, s.height - 2.0 * y);
  rects[TileCM] = NSMakeRect(x, y, s.width - 2.0 * x, s.height - 2.0 * y);
  rects[TileCR] = NSMakeRect(s.width - x, y, x, s.height - 2.0 * y);
  rects[TileBL] = NSMakeRect(0.0, 0.0, x, y);
  rects[TileBM] = NSMakeRect(x, 0.0, s.width - 2.0 * x, y);
  rects[TileBR] = NSMakeRect(s.width - x, 0.0, x, y);

  for (i = 0; i < 9; i++)
    {
      if (rects[i].origin.x < 0.0 || rects[i].origin.y < 0.0
	|| rects[i].size.width <= 0.0 || rects[i].size.height <= 0.0)
        {
	  images[i] = nil;
	  rects[i] = NSZeroRect;
	}
      else
        {
	  images[i] = RETAIN(image);
	}
    }  

  return self;
}

- (void) scaleUp: (int)multiple
{
  if (multiple > 1)
    {
      unsigned	i;
      NSSize	s;

      [images[0] setScalesWhenResized: YES];
      s = [images[0] size];
      s.width *= multiple;
      s.height *= multiple;
      [images[0] setSize: s];
      rects[0].size.height *= multiple;
      rects[0].size.width *= multiple;
      rects[0].origin.x *= multiple;
      rects[0].origin.y *= multiple;
      for (i = 1; i < 9; i++)
        {
	  unsigned	j;

	  for (j = 0; j < i; j++)
	    {
	      if (images[i] == images[j])
		{
		  break;
		}
	    }
	  if (j == i)
	    {
	      [images[i] setScalesWhenResized: YES];
	      s = [images[i] size];
	      s.width *= multiple;
	      s.height *= multiple;
	      [images[i] setSize: s];
	    }
	  rects[i].size.height *= multiple;
	  rects[i].size.width *= multiple;
	  rects[i].origin.x *= multiple;
	  rects[i].origin.y *= multiple;
	}
    }
}
@end

