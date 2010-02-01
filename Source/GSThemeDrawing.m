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

#import "AppKit/NSAttributedString.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSButtonCell.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSColorList.h"
#import "AppKit/NSColorWell.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSMenuItemCell.h"
#import "AppKit/NSParagraphStyle.h"
#import "AppKit/NSProgressIndicator.h"
#import "AppKit/NSScroller.h"
#import "AppKit/NSView.h"
#import "AppKit/PSOperators.h"

#import "GNUstepGUI/GSToolbarView.h"
#import "GNUstepGUI/GSTitleView.h"


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
      name = GSStringFromBezelStyle(style);
    }

  color = [self colorNamed: name state: state];
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

  tiles = [self tilesNamed: name state: state];
  if (tiles == nil)
    {
      tiles = [self tilesNamed: @"NSButton" state: state];
    }

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundedBezelStyle:
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
	  background: color];
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
      name = GSStringFromBezelStyle(style);
    }

  tiles = [self tilesNamed: name state: state];
  if (tiles == nil)
    {
      tiles = [self tilesNamed: @"NSButton" state: state];
    } 

  if (tiles == nil)
    {
      switch (style)
        {
	  case NSRoundRectBezelStyle:
	  case NSTexturedRoundedBezelStyle:
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
      // FIXME: We assume the button's top and right padding are the same as
      // its bottom and left.
      return NSMakeSize(tiles->contentRect.origin.x,
                        tiles->contentRect.origin.y);
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
  [cell setImagePosition: NSImageOnly];
  if (horizontal)
    {
      [self setName: GSScrollerHorizontalKnob forElement: cell temporary: YES];
      [cell setImage: [NSImage imageNamed: @"common_DimpleHoriz"]];
    }
  else
    {
      [self setName: GSScrollerVerticalKnob forElement: cell temporary: YES];
      [cell setImage: [NSImage imageNamed: @"common_Dimple"]];
  
    }
  RELEASE(cell);
  return cell;
}

- (NSCell*) cellForScrollerKnobSlot: (BOOL)horizontal
{
  GSDrawTiles   *tiles;
  NSButtonCell	*cell;
  NSColor	*color;
  NSString      *name;

  if (horizontal)
    {
      name = GSScrollerHorizontalSlot;
    }
  else
    {
      name = GSScrollerVerticalSlot;
    }

  tiles = [self tilesNamed: name state: GSThemeNormalState];
  color = [self colorNamed: name state: GSThemeNormalState];

  cell = [NSButtonCell new];
  [cell setBordered: (tiles != nil)];
  [cell setTitle: nil];

  [self setName: name forElement: cell temporary: YES];
 
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

- (NSColor *) toolbarBackgroundColor
{
  NSColor *color;

  color = [self colorNamed: @"toolbarBackgroundColor"
                state: GSThemeNormalState];
  if (color == nil)
    {
      color = [NSColor clearColor];
    }
  return color;
}

- (NSColor *) toolbarBorderColor
{
  NSColor *color;

  color = [self colorNamed: @"toolbarBorderColor"
                state: GSThemeNormalState];
  if (color == nil)
    {
      color = [NSColor grayColor];
    }
  return color;
}

- (void) drawToolbarRect: (NSRect)aRect
                   frame: (NSRect)viewFrame
              borderMask: (unsigned int)borderMask
{
  // We draw the background
  [[self toolbarBackgroundColor] set];
  [NSBezierPath fillRect: aRect];
  
  // We draw the border
  [[self toolbarBorderColor] set];
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

- (BOOL) toolbarIsOpaque
{
  if ([[self toolbarBackgroundColor] alphaComponent] < 1.0)
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

// NSStepperCell drawing
// Hard coded values for button sizes
#define STEPPER_WIDTH 15
#define STEPPER_HEIGHT 11

- (NSRect) stepperUpButtonRectWithFrame: (NSRect)frame
{
  NSRect upRect;

  upRect.size.width = STEPPER_WIDTH;
  upRect.size.height = STEPPER_HEIGHT;
  upRect.origin.x = NSMaxX(frame) - STEPPER_WIDTH - 1;
  upRect.origin.y = NSMinY(frame) + ((int)frame.size.height / 2) + 1;
  return upRect;
}

- (NSRect) stepperDownButtonRectWithFrame: (NSRect)frame
{
  NSRect downRect;

  downRect.size.width = STEPPER_WIDTH;
  downRect.size.height = STEPPER_HEIGHT;
  downRect.origin.x = NSMaxX(frame) - STEPPER_WIDTH - 1;
  downRect.origin.y = NSMinY(frame) + ((int)frame.size.height / 2) - STEPPER_HEIGHT + 1;
  return downRect;
}

- (void) drawStepperBorder: (NSRect)frame
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge};
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *grays[] = {black, black}; 
  NSRect twoButtons;
  
  twoButtons.origin.x = NSMaxX(frame) - STEPPER_WIDTH - 1;
  twoButtons.origin.y = NSMinY(frame) + ((int)frame.size.height / 2) - STEPPER_HEIGHT;
  twoButtons.size.width = STEPPER_WIDTH + 1;
  twoButtons.size.height = 2 * STEPPER_HEIGHT + 1;
  
  NSDrawColorTiledRects(twoButtons, NSZeroRect,
                        up_sides, grays, 2);
}

- (NSRect) drawStepperLightButton: (NSRect)border : (NSRect)clip
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

- (void) drawStepperUpButton: (NSRect)aRect
{
  NSRect unHighlightRect = [self drawStepperLightButton: aRect : NSZeroRect];
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

- (void) drawStepperHighlightUpButton: (NSRect)aRect
{
  NSRect highlightRect = [self drawStepperLightButton: aRect : NSZeroRect];
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

- (void) drawStepperDownButton: (NSRect)aRect
{
  NSRect unHighlightRect = [self drawStepperLightButton: aRect : NSZeroRect];
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

- (void) drawStepperHighlightDownButton: (NSRect)aRect
{
  NSRect highlightRect = [self drawStepperLightButton: aRect : NSZeroRect];
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

- (void) drawStepperCell: (NSCell*)cell
               withFrame: (NSRect)cellFrame
                  inView: (NSView*)controlView
             highlightUp: (BOOL)highlightUp
           highlightDown: (BOOL)highlightDown
{
  NSRect upRect;
  NSRect downRect;

  [self drawStepperBorder: cellFrame];

  upRect = [self stepperUpButtonRectWithFrame: cellFrame];
  downRect = [self stepperDownButtonRectWithFrame: cellFrame];
  
  if (highlightUp)
    [self drawStepperHighlightUpButton: upRect];
  else
    [self drawStepperUpButton: upRect];

  if (highlightDown)
    [self drawStepperHighlightDownButton: downRect];
  else
    [self drawStepperDownButton: downRect];
}

// NSSegmentedControl drawing methods

- (void) drawSegmentedControlSegment: (NSCell *)cell
                           withFrame: (NSRect)cellFrame
                              inView: (NSView *)controlView
                               style: (NSSegmentStyle)style  
                               state: (GSThemeControlState)state
                         roundedLeft: (BOOL)roundedLeft
                        roundedRight: (BOOL)roundedRight
{
  GSDrawTiles *tiles;
  NSString  *name = GSStringFromSegmentStyle(style);
  if (roundedLeft)
    {
      name = [name stringByAppendingString: @"RoundedLeft"];
    }
  if (roundedRight)
    {
      name = [name stringByAppendingString: @"RoundedRight"];
    }

  tiles = [self tilesNamed: name state: state];
 
  if (tiles == nil)
    {
      [self drawButton: cellFrame
                    in: cell
                  view: controlView
                 style: NSRegularSquareBezelStyle
                 state: state];
    }
  else
    {
      [self fillRect: cellFrame
           withTiles: tiles
          background: [NSColor clearColor]];
    }
}

- (void) drawImage: (NSImage *)image
      inButtonCell: (NSButtonCell *) cell 
	 withFrame: (NSRect) aRect
	  position: (NSPoint) position
{
  BOOL enabled = [cell isEnabled];
  BOOL dims = [cell imageDimsWhenDisabled];

  if (!enabled && dims)
    {
      [image dissolveToPoint: position fraction: 0.5];
    }
  else
    {
      [image compositeToPoint: position 
	            operation: NSCompositeSourceOver];
    }
}

- (void) drawBackgroundForMenuView: (NSMenuView*)menuView
                         withFrame: (NSRect)bounds
                         dirtyRect: (NSRect)dirtyRect
                        horizontal: (BOOL)horizontal 
{
  NSString  *name = horizontal ? GSMenuHorizontalBackground : 
    GSMenuVerticalBackground;
  GSDrawTiles *tiles = [self tilesNamed: name state: GSThemeNormalState];
 
  if (tiles == nil)
    {
     NSRectEdge sides[2]; 
     float      grays[] = {NSDarkGray, NSDarkGray};
     if (horizontal == YES)
        {
          sides[0] = NSMinYEdge;
          sides[1] = NSMinYEdge;
          NSDrawTiledRects(bounds, dirtyRect, sides, grays, 2);
        }
      else
        {
          sides[0] = NSMinXEdge;
          sides[1] = NSMaxYEdge;
          // Draw the dark gray upper left lines.
          NSDrawTiledRects(bounds, dirtyRect, sides, grays, 2);
        }
    }
  else
    {
      [self fillRect: bounds
           withTiles: tiles
          background: [NSColor clearColor]];
    }
}

- (void) drawBorderAndBackgroundForMenuItemCell: (NSMenuItemCell *)cell
                                      withFrame: (NSRect)cellFrame
                                         inView: (NSView *)controlView
                                          state: (GSThemeControlState)state
                                   isHorizontal: (BOOL)isHorizontal
{
  NSString  *name = isHorizontal ? GSMenuHorizontalItem :
    GSMenuVerticalItem;
  GSDrawTiles *tiles = [self tilesNamed: name state: state];
 
  if (tiles == nil)
    {
 
      NSColor	*backgroundColor = [cell backgroundColor];

      if (isHorizontal)
	{
	  cellFrame = [cell drawingRectForBounds: cellFrame];
	  [backgroundColor set];
	  NSRectFill(cellFrame);
	  return;
	}

      // Set cell's background color
      [backgroundColor set];
      NSRectFill(cellFrame);

      if (![cell isBordered])
	return;

      if (state == GSThemeSelectedState)
	{
          [self drawGrayBezel: cellFrame withClip: NSZeroRect];
        }
      else
        {
          [self drawButton: cellFrame withClip: NSZeroRect];
        }
    }
  else
    {
      [self fillRect: cellFrame
           withTiles: tiles
          background: [NSColor clearColor]];
    }
}

- (Class) titleViewClassForMenuView: (NSMenuView *)aMenuView
{
  return [GSTitleView class];
}

// NSColorWell drawing method
- (NSRect) drawColorWellBorder: (NSColorWell*)well
                    withBounds: (NSRect)bounds
                      withClip: (NSRect)clipRect
{
  NSRect aRect = bounds;

  if ([well isBordered])
    {
      /*
       * Draw border.
       */
      [self drawButton: aRect withClip: clipRect];

      /*
       * Fill in control color.
       */
      if ([[well cell] isHighlighted] || [well isActive])
	{
	  [[NSColor selectedControlColor] set];
	}
      else
	{
	  [[NSColor controlColor] set];
	}
      aRect = NSInsetRect(aRect, 2.0, 2.0);
      NSRectFill(NSIntersectionRect(aRect, clipRect));

      /*
       * Set an inset rect for the color area
       */
      aRect = NSInsetRect(bounds, 8.0, 8.0);
    }

  /*
   * OpenStep 4.2 behavior is to omit the inner border for
   * non-enabled NSColorWell objects.
   */
  if ([well isEnabled])
    {
      /*
       * Draw inner frame.
       */
      [self drawGrayBezel: aRect withClip: clipRect];
      aRect = NSInsetRect(aRect, 2.0, 2.0);
    }

  return aRect;
}

// progress indicator drawing methods
static NSColor *fillColour = nil;
#define MaxCount 10
static int indeterminateMaxCount = MaxCount;
static int spinningMaxCount = MaxCount;
static NSColor *indeterminateColors[MaxCount];
static NSImage *spinningImages[MaxCount];

- (void) initProgressIndicatorDrawing
{
  int i;
  
  // FIXME: Should come from defaults and should be reset when defaults change
  // FIXME: Should probably get the color from the color extension list (see NSToolbar)
  fillColour = RETAIN([NSColor controlShadowColor]);

  // Load images for indeterminate style
  for (i = 0; i < MaxCount; i++)
    {
      NSString *imgName = [NSString stringWithFormat: @"common_ProgressIndeterminate_%d", i + 1];
      NSImage *image = [NSImage imageNamed: imgName];
      
      if (image == nil)
        {
          indeterminateMaxCount = i;
          break;
        }
          indeterminateColors[i] = RETAIN([NSColor colorWithPatternImage: image]);
    }
  
  // Load images for spinning style
  for (i = 0; i < MaxCount; i++)
    {
      NSString *imgName = [NSString stringWithFormat: @"common_ProgressSpinning_%d", i + 1];
      NSImage *image = [NSImage imageNamed: imgName];
      
      if (image == nil)
        {
          spinningMaxCount = i;
          break;
        }
      spinningImages[i] = RETAIN(image); 
    }
}

- (void) drawProgressIndicator: (NSProgressIndicator*)progress
                    withBounds: (NSRect)bounds
                      withClip: (NSRect)rect
                       atCount: (int)count
                      forValue: (double)val
{
   NSRect r;

   if (fillColour == nil)
     {
       [self initProgressIndicatorDrawing];
     }

   // Draw the Bezel
   if ([progress isBezeled])
     {
       // Calc the inside rect to be drawn
       r = [self drawProgressIndicatorBezel: bounds withClip: rect];
     }
   else
     {
       r = bounds;
     }

   if ([progress style] == NSProgressIndicatorSpinningStyle)
     {
       NSRect imgBox = {{0,0}, {0,0}};

       if (spinningMaxCount != 0)
	 {
	   count = count % spinningMaxCount;
	   imgBox.size = [spinningImages[count] size];
	   [spinningImages[count] drawInRect: r 
				    fromRect: imgBox 
				   operation: NSCompositeSourceOver
				    fraction: 1.0];
	 }
     }
   else
     {
       if ([progress isIndeterminate])
         {
	   if (indeterminateMaxCount != 0)
	     {
	       count = count % indeterminateMaxCount;
	       [indeterminateColors[count] set];
	       NSRectFill(r);
	     }
         }
       else
         {
           // Draw determinate 
           if ([progress isVertical])
             {
               float height = NSHeight(r) * val;
               
               if ([progress isFlipped])
                 {
                   // Compensate for the flip
                   r.origin.y += NSHeight(r) - height;
                 }
               r.size.height = height;
             }
           else
             {
               r.size.width = NSWidth(r) * val;
             }
           r = NSIntersectionRect(r, rect);
           if (!NSIsEmptyRect(r))
             {
               [self drawProgressIndicatorBarDeterminate: (NSRect)r];
             }
         }
     }
}

- (NSRect) drawProgressIndicatorBezel: (NSRect)bounds withClip: (NSRect) rect
{
  return [self drawGrayBezel: bounds withClip: rect];
}

- (void) drawProgressIndicatorBarDeterminate: (NSRect)bounds
{
  [fillColour set];
  NSRectFill(bounds);
}

// Table drawing methods
- (void) drawTableCornerView: (NSView*)cornerView
                   withClip: (NSRect)aRect
{
  NSRect divide;
  NSRect rect;
  GSDrawTiles *tiles = [self tilesNamed: GSTableCorner state: GSThemeNormalState];

  if ([cornerView isFlipped])
    {
      NSDivideRect(aRect, &divide, &rect, 1.0, NSMaxYEdge);
    }
  else
    {
      NSDivideRect(aRect, &divide, &rect, 1.0, NSMinYEdge);
    }

  if (tiles == nil)
    { 
      [[NSColor blackColor] set];
      NSRectFill(divide);
      rect = [self drawDarkButton: rect withClip: aRect];
      [[NSColor controlShadowColor] set];
      NSRectFill(rect);
    }
  else
    {
       [self fillRect: aRect
            withTiles: tiles
           background: [NSColor clearColor]];
    }
}

- (void) drawTableHeaderCell: (NSTableHeaderCell *)cell
                   withFrame: (NSRect)cellFrame
                      inView: (NSView *)controlView
                       state: (GSThemeControlState)state
{
  GSDrawTiles *tiles = [self tilesNamed: GSTableHeader state: state];

  if (tiles == nil)
    {
      NSRect rect;
      if (state == GSThemeHighlightedState)
        {
          rect = [self drawButton: cellFrame withClip: cellFrame];
          [[NSColor controlColor] set];
          NSRectFill(rect);        
        }
      else
        {
          rect = [self drawDarkButton: cellFrame withClip: cellFrame];
          [[NSColor controlShadowColor] set];
          NSRectFill(rect);
        }
    }
  else
    {
      [self fillRect: cellFrame
           withTiles: tiles
          background: [NSColor clearColor]];
    }
}


// Window decoration drawing methods
/* These include the black border. */
#define TITLE_HEIGHT 23.0
#define RESIZE_HEIGHT 9.0

- (float) titlebarHeight
{
  return TITLE_HEIGHT;
}

- (float) resizebarHeight
{
  return RESIZE_HEIGHT;
}

static NSDictionary *titleTextAttributes[3] = {nil, nil, nil};

- (void) drawTitleBarRect: (NSRect)titleBarRect 
             forStyleMask: (unsigned int)styleMask
                    state: (int)inputState 
                 andTitle: (NSString*)title
{
  static const NSRectEdge edges[4] = {NSMinXEdge, NSMaxYEdge,
				    NSMaxXEdge, NSMinYEdge};
  float grays[3][4] =
    {{NSLightGray, NSLightGray, NSDarkGray, NSDarkGray},
    {NSWhite, NSWhite, NSDarkGray, NSDarkGray},
    {NSLightGray, NSLightGray, NSBlack, NSBlack}};
  NSRect workRect;

  if (!titleTextAttributes[0])
    {
      NSMutableParagraphStyle *p;

      p = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      [p setLineBreakMode: NSLineBreakByClipping];

      titleTextAttributes[0] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	  p, NSParagraphStyleAttributeName,
	  nil];

      titleTextAttributes[1] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor blackColor], NSForegroundColorAttributeName, /* TODO: need a named color for this */
	  p, NSParagraphStyleAttributeName,
	  nil];

      titleTextAttributes[2] = [[NSMutableDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 0], NSFontAttributeName,
	  [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	  p, NSParagraphStyleAttributeName,
	  nil];

      RELEASE(p);
    }

  /*
  Draw the black border towards the rest of the window. (The outer black
  border is drawn in -drawRect: since it might be drawn even if we don't have
  a title bar.
  */
  [[NSColor blackColor] set];
  PSmoveto(0, NSMinY(titleBarRect) + 0.5);
  PSrlineto(titleBarRect.size.width, 0);
  PSstroke();

  /*
  Draw the button-like border.
  */
  workRect = titleBarRect;
  workRect.origin.x += 1;
  workRect.origin.y += 1;
  workRect.size.width -= 2;
  workRect.size.height -= 2;

  workRect = NSDrawTiledRects(workRect, workRect, edges, grays[inputState], 4);
 
  /*
  Draw the background.
  */
  switch (inputState) 
    {
    default:
    case 0:
      [[NSColor windowFrameColor] set];
      break;
    case 1:
      [[NSColor lightGrayColor] set];
      break;
    case 2:
      [[NSColor darkGrayColor] set];
      break;
    }
  NSRectFill(workRect);

  /* Draw the title. */
  if (styleMask & NSTitledWindowMask)
    {
      NSSize titleSize;
    
      if (styleMask & NSMiniaturizableWindowMask)
	{
	  workRect.origin.x += 17;
	  workRect.size.width -= 17;
	}
      if (styleMask & NSClosableWindowMask)
	{
	  workRect.size.width -= 17;
	}
  
      titleSize = [title sizeWithAttributes: titleTextAttributes[inputState]];
      if (titleSize.width <= workRect.size.width)
	workRect.origin.x = NSMidX(workRect) - titleSize.width / 2;
      workRect.origin.y = NSMidY(workRect) - titleSize.height / 2;
      workRect.size.height = titleSize.height;
      [title drawInRect: workRect
	 withAttributes: titleTextAttributes[inputState]];
    }
}

- (void) drawResizeBarRect: (NSRect)resizeBarRect
{
  [[NSColor lightGrayColor] set];
  PSrectfill(1.0, 1.0, resizeBarRect.size.width - 2.0, RESIZE_HEIGHT - 3.0);

  PSsetlinewidth(1.0);

  [[NSColor blackColor] set];
  PSmoveto(0.0, 0.5);
  PSlineto(resizeBarRect.size.width, 0.5);
  PSstroke();

  [[NSColor darkGrayColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 0.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 0.5);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 1.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 1.5);
  PSstroke();


  /* Only draw the notches if there's enough space. */
  if (resizeBarRect.size.width < 30 * 2)
    return;

  [[NSColor darkGrayColor] set];
  PSmoveto(27.5, 1.0);
  PSlineto(27.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 28.5, 1.0);
  PSlineto(resizeBarRect.size.width - 28.5, RESIZE_HEIGHT - 2.0);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(28.5, 1.0);
  PSlineto(28.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 27.5, 1.0);
  PSlineto(resizeBarRect.size.width - 27.5, RESIZE_HEIGHT - 2.0);
  PSstroke();
}

- (void) drawWindowBorder: (NSRect)rect 
                withFrame: (NSRect)frame 
             forStyleMask: (unsigned int)styleMask
                    state: (int)inputState 
                 andTitle: (NSString*)title
{
  if (styleMask & (NSTitledWindowMask | NSClosableWindowMask 
                   | NSMiniaturizableWindowMask))
    {
      NSRect titleBarRect;

      titleBarRect = NSMakeRect(0.0, frame.size.height - TITLE_HEIGHT,
                                frame.size.width, TITLE_HEIGHT);
      if (NSIntersectsRect(rect, titleBarRect))
        [self drawTitleBarRect: titleBarRect 
              forStyleMask: styleMask
              state: inputState 
              andTitle: title];
    }

  if (styleMask & NSResizableWindowMask)
    {
      NSRect resizeBarRect;

      resizeBarRect = NSMakeRect(0.0, 0.0, frame.size.width, RESIZE_HEIGHT);
      if (NSIntersectsRect(rect, resizeBarRect))
        [self drawResizeBarRect: resizeBarRect];
    }

  if (styleMask & (NSTitledWindowMask | NSClosableWindowMask 
                   | NSMiniaturizableWindowMask | NSResizableWindowMask))
    {
      PSsetlinewidth(1.0);
      [[NSColor blackColor] set];
      if (NSMinX(rect) < 1.0)
	{
	  PSmoveto(0.5, 0.0);
	  PSlineto(0.5, frame.size.height);
	  PSstroke();
	}
      if (NSMaxX(rect) > frame.size.width - 1.0)
	{
	  PSmoveto(frame.size.width - 0.5, 0.0);
	  PSlineto(frame.size.width - 0.5, frame.size.height);
	  PSstroke();
	}
      if (NSMaxY(rect) > frame.size.height - 1.0)
	{
	  PSmoveto(0.0, frame.size.height - 0.5);
	  PSlineto(frame.size.width, frame.size.height - 0.5);
	  PSstroke();
	}
      if (NSMinY(rect) < 1.0)
	{
	  PSmoveto(0.0, 0.5);
	  PSlineto(frame.size.width, 0.5);
	  PSstroke();
	}
    }
}

@end
