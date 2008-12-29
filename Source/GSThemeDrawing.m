/** <title>GSThemeDrawing</title>

   <abstract>The theme methods for drawing controls</abstract>

   Copyright (C) 2004-2008 Free Software Foundation, Inc.

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

#import "GSThemePrivate.h"
#import "AppKit/NSGraphics.h"


@implementation	GSTheme (Drawing)

- (void) drawButton: (NSRect)frame 
                 in: (NSCell*)cell 
               view: (NSView*)view 
              style: (int)style 
              state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;
  NSColor	*color = nil;

  if (state == GSThemeNormalState)
    {
      tiles = [self tilesNamed: @"NSButtonNormal" cache: YES];
      color = [NSColor controlBackgroundColor];
    }
  else if (state == GSThemeHighlightedState)
    {
      tiles = [self tilesNamed: @"NSButtonHighlighted" cache: YES];
      color = [NSColor selectedControlColor];
    }
  else if (state == GSThemeSelectedState)
    {
      tiles = [self tilesNamed: @"NSButtonPushed" cache: YES];
      color = [NSColor selectedControlColor];
    }

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundBezelStyle:
	  case NSRoundedBezelStyle:
	    [self drawRoundBezel: frame withColor: color];
	    break;
	  case NSTexturedSquareBezelStyle:
	    frame = NSInsetRect(frame, 0, 1);
	  case NSSmallSquareBezelStyle:
	  case NSRegularSquareBezelStyle:
	  case NSShadowlessSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 1);
	    break;
	  case NSThickSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 1.5);
	    break;
	  case NSThickerSquareBezelStyle:
	    [color set];
	    NSRectFill(frame);
	    [[NSColor controlShadowColor] set];
	    NSFrameRectWithWidth(frame, 2);
	    break;
	  case NSCircularBezelStyle:
	    frame = NSInsetRect(frame, 3, 3);
	  case NSHelpButtonBezelStyle:
	    [self drawCircularBezel: frame withColor: color]; 
	    break;
	  case NSDisclosureBezelStyle:
	  case NSRoundedDisclosureBezelStyle:
	  case NSRecessedBezelStyle:
	    // FIXME
	    break;
	  default:
	    [color set];
	    NSRectFill(frame);

	    if (state == GSThemeNormalState || state == GSThemeHighlightedState)
	      {
		[self drawButton: frame withClip: NSZeroRect];
	      }
	    else if (state == GSThemeSelectedState)
	      {
		[self drawGrayBezel: frame withClip: NSZeroRect];
	      }
	}
    }
  else
    {
      /* Use tiles to draw button border with central part filled with color
       */
      [self fillRect: frame
	   withTiles: tiles
	  background: color
	   fillStyle: GSThemeFillStyleNone];
    }
}

- (NSSize) buttonBorderForStyle: (int)style 
			  state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;

  if (state == GSThemeNormalState)
    {
      tiles = [self tilesNamed: @"NSButtonNormal" cache: YES];
    }
  else if (state == GSThemeHighlightedState)
    {
      tiles = [self tilesNamed: @"NSButtonHighlighted" cache: YES];
    }
  else if (state == GSThemeSelectedState)
    {
      tiles = [self tilesNamed: @"NSButtonPushed" cache: YES];
    }

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundBezelStyle:
	  case NSRoundedBezelStyle:
	    return NSMakeSize(5, 5);
	  case NSTexturedSquareBezelStyle:
	    return NSMakeSize(3, 3);
	  case NSSmallSquareBezelStyle:
	  case NSRegularSquareBezelStyle:
	  case NSShadowlessSquareBezelStyle:
	    return NSMakeSize(2, 2);
	  case NSThickSquareBezelStyle:
	    return NSMakeSize(3, 3);
	  case NSThickerSquareBezelStyle:
	    return NSMakeSize(4, 4);
	  case NSCircularBezelStyle:
	    return NSMakeSize(5, 5);
	  case NSHelpButtonBezelStyle:
	    return NSMakeSize(2, 2);
	  case NSDisclosureBezelStyle:
	  case NSRoundedDisclosureBezelStyle:
	  case NSRecessedBezelStyle:
	    // FIXME
	    return NSMakeSize(0, 0);
	  default:
	    return NSMakeSize(3, 3);
	}
    }
  else
    {
      NSSize cls = tiles->rects[TileCL].size;
      NSSize bms = tiles->rects[TileBM].size;

      return NSMakeSize(cls.width, bms.height);
    }
}

- (void) drawFocusFrame: (NSRect) frame view: (NSView*) view
{
  NSDottedFrameRect(frame);
}

- (void) drawWindowBackground: (NSRect) frame view: (NSView*) view
{
  NSColor *c;

  c = [[view window] backgroundColor];
  [c set];
  NSRectFill (frame);
}

- (void) drawBorderType: (NSBorderType)aType 
                  frame: (NSRect)frame 
                   view: (NSView*)view
{
  switch (aType)
    {
      case NSLineBorder:
        [[NSColor controlDarkShadowColor] set];
        NSFrameRect(frame);
        break;
      case NSGrooveBorder:
        [self drawGroove: frame withClip: NSZeroRect];
        break;
      case NSBezelBorder:
        [self drawWhiteBezel: frame withClip: NSZeroRect];
        break;
      case NSNoBorder: 
      default:
        break;
    }
}

- (NSSize) sizeForBorderType: (NSBorderType)aType
{
  // Returns the size of a border
  switch (aType)
    {
      case NSLineBorder:
        return NSMakeSize(1, 1);
      case NSGrooveBorder:
      case NSBezelBorder:
        return NSMakeSize(2, 2);
      case NSNoBorder: 
      default:
        return NSZeroSize;
    }
}

- (void) drawBorderForImageFrameStyle: (NSImageFrameStyle)frameStyle
                                frame: (NSRect)frame 
                                 view: (NSView*)view
{
  switch (frameStyle)
    {
      case NSImageFrameNone:
        // do nothing
        break;
      case NSImageFramePhoto:
        [self drawFramePhoto: frame withClip: NSZeroRect];
        break;
      case NSImageFrameGrayBezel:
        [self drawGrayBezel: frame withClip: NSZeroRect];
        break;
      case NSImageFrameGroove:
        [self drawGroove: frame withClip: NSZeroRect];
        break;
      case NSImageFrameButton:
        [self drawButton: frame withClip: NSZeroRect];
        break;
    }
}

- (NSSize) sizeForImageFrameStyle: (NSImageFrameStyle)frameStyle
{
  // Get border size
  switch (frameStyle)
    {
      case NSImageFrameNone:
      default:
        return NSZeroSize;
      case NSImageFramePhoto:
        // FIXME
        return NSMakeSize(2, 2);
      case NSImageFrameGrayBezel:
      case NSImageFrameGroove:
      case NSImageFrameButton:
        return NSMakeSize(2, 2);
    }
}

@end

