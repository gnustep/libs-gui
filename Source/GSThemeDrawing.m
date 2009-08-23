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

#import "AppKit/NSBezierPath.h"
#import "AppKit/NSColorList.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/PSOperators.h"

#import "GNUstepGUI/GSToolbarView.h"


@implementation	GSTheme (Drawing)

- (void) drawButton: (NSRect)frame 
                 in: (NSCell*)cell 
               view: (NSView*)view 
              style: (int)style 
              state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;
  NSColor	*color = nil;
  NSString	*name = [self nameForElement: cell];

  if (name == nil)
    {
      name = @"NSButton";
    }

  color = [self colorNamed: name state: state cache: YES];
  if (color == nil)
    {
      if (state == GSThemeNormalState)
	{
          color = [NSColor controlBackgroundColor];
	}
      else if (state == GSThemeHighlightedState)
	{
          color = [NSColor selectedControlColor];
	}
      else if (state == GSThemeSelectedState)
	{
          color = [NSColor selectedControlColor];
	}
    }

  tiles = [self tilesNamed: name state: state cache: YES];
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

- (NSSize) buttonBorderForCell: (NSCell*)cell
			 style: (int)style 
			 state: (GSThemeControlState)state
{
  GSDrawTiles	*tiles = nil;
  NSString	*name = [self nameForElement: cell];

  if (name == nil)
    {
      name = @"NSButton";
    }

  tiles = [self tilesNamed: name state: state cache: YES];
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


/* NSScroller themeing.
 */
- (NSButtonCell*) cellForScrollerArrow: (NSScrollerArrow)arrow
			    horizontal: (BOOL)horizontal
{
  NSButtonCell	*cell;
  NSString	*name;
  
  cell = [NSButtonCell new];
  if (horizontal)
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerLeftArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowRight"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowRightH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerRightArrow;
	}
    }
  else
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowUp"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowUpH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerUpArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowDown"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowDownH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerDownArrow;
	}
    }
  [self setName: name forElement: cell temporary: YES];
  RELEASE(cell);
  return cell;
}

- (NSCell*) cellForScrollerKnob: (BOOL)horizontal
{
  NSButtonCell	*cell;

  cell = [NSButtonCell new];
  [cell setButtonType: NSMomentaryChangeButton];
  [cell setImage: [NSImage imageNamed: @"common_Dimple"]];
  [cell setImagePosition: NSImageOnly];
  if (horizontal)
    {
      [self setName: GSScrollerHorizontalKnob forElement: cell temporary: YES];
    }
  else
    {
      [self setName: GSScrollerVerticalKnob forElement: cell temporary: YES];
    }
  RELEASE(cell);
  return cell;
}

- (NSCell*) cellForScrollerKnobSlot: (BOOL)horizontal
{
  NSButtonCell	*cell;
  NSColor	*color;

  cell = [NSButtonCell new];
  [cell setBordered: NO];
  [cell setTitle: nil];

  if (horizontal)
    {
      color = [self colorNamed: GSScrollerHorizontalSlot
			 state: GSThemeNormalState
			 cache: YES];
      [self setName: GSScrollerHorizontalSlot forElement: cell temporary: YES];
    }
  else
    {
      color = [self colorNamed: GSScrollerVerticalSlot
			 state: GSThemeNormalState
			 cache: YES];
      [self setName: GSScrollerVerticalSlot forElement: cell temporary: YES];
    }
  if (color == nil)
    {
      color = [NSColor scrollBarColor];
    }
  [cell setBackgroundColor: color];
  RELEASE(cell);
  return cell;
}

- (float) defaultScrollerWidth
{
  return 18.0;
}

- (void) drawToobarRect: (NSRect)aRect
                  frame: (NSRect)viewFrame
             borderMask: (unsigned int)borderMask
{
  // We draw the background
  [[NSColor toolbarBackgroundColor] set];
  [NSBezierPath fillRect: aRect];
  
  // We draw the border
  [[NSColor toolbarBorderColor] set];
  if (borderMask & GSToolbarViewBottomBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 0.5) 
                    toPoint: NSMakePoint(viewFrame.size.width, 0.5)];
    }
  if (borderMask & GSToolbarViewTopBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 
                                                     viewFrame.size.height - 0.5) 
                    toPoint: NSMakePoint(viewFrame.size.width, 
                                         viewFrame.size.height -  0.5)];
    }
  if (borderMask & GSToolbarViewLeftBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0) 
                    toPoint: NSMakePoint(0.5, viewFrame.size.height)];
    }
  if (borderMask & GSToolbarViewRightBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5,0)
                    toPoint: NSMakePoint(viewFrame.size.width - 0.5, 
                                         viewFrame.size.height)];
    }
}

- (NSRect) drawStepperLightButton: (NSRect) border :(NSRect) clip
{
/*
  NSRect highlightRect = NSInsetRect(border, 1., 1.);
  [[GSTheme theme] drawButton: border : clip];
  return highlightRect;
*/
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge}; 
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge}; 
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, dark, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

- (void) drawStepperUpButton: (NSRect) aRect
{
  NSRect unHighlightRect = [self drawStepperLightButton: aRect :NSZeroRect];
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);
      
  PSsetlinewidth(1.0);
  [[NSColor controlShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  [[NSColor controlLightHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

- (void) drawStepperHighlightUpButton: (NSRect) aRect
{
  NSRect highlightRect = [self drawStepperLightButton: aRect :NSZeroRect];
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetlinewidth(1.0);
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

- (void) drawStepperDownButton: (NSRect) aRect
{
  NSRect unHighlightRect = [self drawStepperLightButton: aRect :NSZeroRect];
  [[NSColor controlBackgroundColor] set];
  NSRectFill(unHighlightRect);

  PSsetlinewidth(1.0);
  [[NSColor controlShadowColor] set];
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  [[NSColor controlLightHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

- (void) drawStepperHighlightDownButton: (NSRect) aRect
{
  NSRect highlightRect = [self drawStepperLightButton: aRect :NSZeroRect];
  [[NSColor selectedControlColor] set];
  NSRectFill(highlightRect);
  
  PSsetlinewidth(1.0);
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  [[NSColor controlHighlightColor] set];
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  [[NSColor controlDarkShadowColor] set];
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

- (void) drawButtonCellImage: (NSButtonCell *) cell 
	           withFrame: (NSRect) aRect
	            position: (NSPoint) position
{
  NSImage *anImage = [cell image];
  BOOL disabled = [cell isEnabled];
  BOOL dims = [cell imageDimsWhenDisabled];

  if (disabled && dims)
    {
      [anImage dissolveToPoint: position fraction: 0.5];
    }
  else
    {
      [anImage compositeToPoint: position 
	       operation: NSCompositeSourceOver];
    }
} 
@end

