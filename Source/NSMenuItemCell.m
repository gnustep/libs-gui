/* 
   NSMenuItemCell.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
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
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItemCell.h>

#include <AppKit/PSOperators.h>

@implementation NSMenuItemCell

+ (void) initialize
{
  if (self == [NSMenuItemCell class])
    {
      // Initial version
      [self setVersion:2];
    }
}

- (id) init
{
  mcell_has_submenu = NO;
  [super init];
  _target = nil;
  _highlightsByMask = NSChangeBackgroundCellMask;
  _showAltStateMask = NSNoCellMask;
  _cell.image_position = NSNoImage;
  _cell.text_align = NSLeftTextAlignment;

  _drawMethods[0] = (DrawingIMP)
    [self methodForSelector:@selector(drawStateImageWithFrame:inView:)];
  _drawMethods[1] = (DrawingIMP)
    [self methodForSelector:@selector(drawImageWithFrame:inView:)];
  _drawMethods[2] = (DrawingIMP)
    [self methodForSelector:@selector(drawTitleWithFrame:inView:)];
  _drawMethods[3] = (DrawingIMP)
    [self methodForSelector:@selector(drawKeyEquivalentWithFrame:inView:)];

  return self;
}

- (void) setHighlighted:(BOOL)flag
{
  mcell_highlighted = flag;
}

- (BOOL) isHighlighted
{
  return mcell_highlighted;
}

- (void) highlight: (BOOL)flag
	 withFrame: (NSRect)cellFrame
	    inView: (NSView*)controlView
{
  if (mcell_highlighted != flag)
    {
      // Save last view drawn to
      if (_control_view != controlView)
	_control_view = controlView;

      [controlView lockFocus];

      mcell_highlighted = flag;
      [self drawInteriorWithFrame: cellFrame inView: controlView];

      [controlView unlockFocus];
    }
}

- (void) setMenuItem:(NSMenuItem *)item
{
  ASSIGN(mcell_item, item);
}

- (NSMenuItem *) menuItem
{
  return mcell_item;
}

- (void) setMenuView:(NSMenuView *)menuView
{
  ASSIGN(mcell_menuView, menuView);
}

- (NSMenuView *) menuView
{
  return mcell_menuView;
}

- (void) calcSize
{
  NSSize   componentSize;
  NSImage *anImage = nil;
  float    neededMenuItemHeight = 20;

  // State Image
  if ([mcell_item changesState])
    {
      // NSOnState
      componentSize = [[mcell_item onStateImage] size];
      mcell_stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;

      // NSOffState
      componentSize = [[mcell_item offStateImage] size];
      if (componentSize.width > mcell_stateImageWidth)
	mcell_stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;

      // NSMixedState
      componentSize = [[mcell_item mixedStateImage] size];
      if (componentSize.width > mcell_stateImageWidth)
	mcell_stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;
    }
  else
    {
      mcell_stateImageWidth = 0.0;
    }

  // Image
  if ((anImage = [mcell_item image]))
    [self setImagePosition: NSImageLeft];
  componentSize = [anImage size];
  mcell_imageWidth = componentSize.width;
  if (componentSize.height > neededMenuItemHeight)
    neededMenuItemHeight = componentSize.height;

  // Title and Key Equivalent
  // FIXME: Calculate height (Lazaro).
  if (_cell_font)
    {
      mcell_titleWidth = [_cell_font widthOfString:[mcell_item title]];
      mcell_keyEquivalentWidth =
	[_cell_font widthOfString:[mcell_item keyEquivalent]];
    }
  else
    {
      mcell_titleWidth = [[NSFont menuFontOfSize:12]
			   widthOfString:[mcell_item title]];
      mcell_keyEquivalentWidth = [[NSFont menuFontOfSize:12]
				   widthOfString:[mcell_item keyEquivalent]];
    }

  // Submenu Arrow
  if ([mcell_item hasSubmenu])
    {
      componentSize = [[NSImage imageNamed:@"common_3DArrowRight"] size];
      mcell_keyEquivalentWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;
    }

  // Cache definitive height
  mcell_menuItemHeight = neededMenuItemHeight;

  // At the end we set sizing to NO.
  mcell_needs_sizing = NO;
}

- (void) setNeedsSizing:(BOOL)flag
{
  mcell_needs_sizing = flag;
}

- (BOOL) needsSizing
{
  return mcell_needs_sizing;
}

- (float) imageWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_imageWidth;
}

- (float) titleWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_titleWidth;
}

- (float) keyEquivalentWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_keyEquivalentWidth;
}

- (float) stateImageWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_stateImageWidth;
}

//
// Sizes for drawing taking into account NSMenuView adjustments.
//
- (NSRect) imageRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [mcell_menuView imageAndTitleOffset];
  cellFrame.size.width = [mcell_menuView imageAndTitleWidth];
  if ([mcell_item changesState])
    cellFrame.origin.x += [mcell_menuView stateImageWidth]
                       + 2 * [mcell_menuView horizontalEdgePadding];

  switch (_cell.image_position)
    {
      case NSNoImage: 
	cellFrame = NSZeroRect;
	break;

      case NSImageOnly:
      case NSImageOverlaps:
	break;

      case NSImageLeft:
	cellFrame.size.width = mcell_imageWidth;
	break;

      case NSImageRight:
	cellFrame.origin.x  += mcell_titleWidth + xDist;
	cellFrame.size.width = mcell_imageWidth;
	break;

      case NSImageBelow: 
	cellFrame.size.height /= 2;
	break;

      case NSImageAbove: 
	cellFrame.size.height /= 2;
        cellFrame.origin.y += cellFrame.size.height;
	break;
    }

  return cellFrame;
}

- (NSRect) keyEquivalentRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [mcell_menuView keyEquivalentOffset];
  cellFrame.size.width = [mcell_menuView keyEquivalentWidth];

  return cellFrame;
}

- (NSRect) stateImageRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [mcell_menuView stateImageOffset];
  cellFrame.size.width = [mcell_menuView stateImageWidth];

  return cellFrame;
}

- (NSRect) titleRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [mcell_menuView imageAndTitleOffset];
  cellFrame.size.width = [mcell_menuView imageAndTitleWidth];
  if ([mcell_item changesState])
    cellFrame.origin.x += [mcell_menuView stateImageWidth]
                        + 2 * [mcell_menuView horizontalEdgePadding];

  switch (_cell.image_position)
    {
      case NSNoImage:
      case NSImageOverlaps:
	break;

      case NSImageOnly: 
	cellFrame = NSZeroRect;
	break;

      case NSImageLeft:
	cellFrame.origin.x  += mcell_imageWidth + xDist;
	cellFrame.size.width = mcell_titleWidth;
	break;

      case NSImageRight: 
	cellFrame.size.width = mcell_titleWidth;
	break;

      case NSImageBelow:
	cellFrame.size.height /= 2;
	cellFrame.origin.y += cellFrame.size.height;
	break;

      case NSImageAbove: 
	cellFrame.size.height /= 2;
	break;
    }

  return cellFrame;
}

//
// Drawing.
//
- (void) drawBorderAndBackgroundWithFrame:(NSRect)cellFrame
				  inView:(NSView *)controlView
{
  if (_cell.is_highlighted && (_highlightsByMask & NSPushInCellMask))
    {
      NSDrawGrayBezel(cellFrame, NSZeroRect);
    }
  else
    {
      NSDrawButton(cellFrame, NSZeroRect);
    }
}

- (void) drawImageWithFrame:(NSRect)cellFrame
		    inView:(NSView *)controlView
{
  NSSize   size;
  NSPoint  position;

  cellFrame = [self imageRectForBounds: cellFrame];
  size = [mcell_imageToDisplay size];
  position.x = MAX(NSMidX(cellFrame) - (size.width/2.), 0.);
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([controlView isFlipped])
    position.y += size.height;
  [mcell_imageToDisplay compositeToPoint: position operation: NSCompositeCopy];
}

- (void) drawKeyEquivalentWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
  cellFrame = [self keyEquivalentRectForBounds: cellFrame];

  if ([mcell_item hasSubmenu])
    {
      NSSize   size;
      NSPoint  position;
      NSImage *arrowImage = [NSImage imageNamed:@"common_3DArrowRight"];

      size = [arrowImage size];
      position.x = cellFrame.origin.x + cellFrame.size.width - size.width;
      position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
	position.y += size.height;
      [arrowImage  compositeToPoint: position operation: NSCompositeCopy];
    }
  else
    [self _drawText: [mcell_item keyEquivalent] inFrame: cellFrame];
}

- (void) drawSeparatorItemWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
  // FIXME: This only has sense in MacOS or Windows interface styles.
  // Maybe somebody wants to support this (Lazaro).
}

- (void) drawStateImageWithFrame:(NSRect)cellFrame
			 inView:(NSView *)controlView
{
  NSSize   size;
  NSPoint  position;
  NSImage *imageToDisplay;

  cellFrame = [self stateImageRectForBounds: cellFrame];

  switch ([mcell_item state])
    {
      case NSOnState:
	imageToDisplay = [mcell_item onStateImage];
	break;

      case NSMixedState:
	imageToDisplay = [mcell_item mixedStateImage];
	break;

      case NSOffState:
      default:
	imageToDisplay = [mcell_item offStateImage];
	break;
    }

  size = [imageToDisplay size];
  position.x = MAX(NSMidX(cellFrame) - (size.width/2.),0.);
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.),0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([controlView isFlipped])
    position.y += size.height;
  [imageToDisplay compositeToPoint: position operation: NSCompositeCopy];
}

- (void) drawTitleWithFrame:(NSRect)cellFrame
		    inView:(NSView *)controlView
{
  if ([mcell_item isEnabled])
    _cell.is_enabled = YES;
  else
    _cell.is_enabled = NO;

  [self _drawText: [mcell_item title]
	  inFrame: [self titleRectForBounds: cellFrame]];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  // Do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  [controlView lockFocus];

  // Draw the border if needed
  if (_cell.is_bordered)
    [self drawBorderAndBackgroundWithFrame: cellFrame inView: controlView];

  [self drawInteriorWithFrame: cellFrame inView: controlView];

  [controlView unlockFocus];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL	    showAlternate = NO;
  unsigned  mask;
  NSColor  *backgroundColor = nil;

  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  cellFrame = [self drawingRectForBounds: cellFrame];

  // Pushed in buttons contents are displaced to the bottom right 1px
  if (_cell.is_bordered && mcell_highlighted
      && (_highlightsByMask & NSPushInCellMask))
    PStranslate(1., [controlView isFlipped] ? 1. : -1.);

  // Determine the background color
  if (_cell.state)
    {
      if (_showAltStateMask
	  & (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
	backgroundColor = [NSColor selectedMenuItemColor];
    }

  if (mcell_highlighted)
    {
      if (_highlightsByMask
	  & (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
	backgroundColor = [NSColor selectedMenuItemColor];
    }

  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  // Set cell's background color
  [backgroundColor set];
  NSRectFill(cellFrame);

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   * The results are saved in two ivars for use in other
   * drawing methods.
   */
  if (mcell_highlighted)
    mask = _highlightsByMask;
  else
    mask = _showAltStateMask;
  if (mask & NSContentsCellMask)
    showAlternate = _cell.state;

  if (mcell_highlighted || showAlternate)
    {
      mcell_imageToDisplay = _altImage;
      if (!mcell_imageToDisplay)
	mcell_imageToDisplay = [mcell_item image];
      mcell_titleToDisplay = _altContents;
      if (mcell_titleToDisplay == nil || [mcell_titleToDisplay isEqual: @""])
        mcell_titleToDisplay = [mcell_item title];
    }
  else
    {
      mcell_imageToDisplay = [mcell_item image];
      mcell_titleToDisplay = [mcell_item title];
    }

  if (mcell_imageToDisplay)
    {
      mcell_imageWidth = [mcell_imageToDisplay size].width;
      [mcell_imageToDisplay setBackgroundColor: backgroundColor];
    }

  // Draw the state image
  if (mcell_stateImageWidth > 0)
    _drawMethods[0](self, @selector(drawStateImageWithFrame:inView:),
		   cellFrame, controlView);

  // Draw the image
  if (mcell_imageWidth > 0)
    _drawMethods[1](self, @selector(drawImageWithFrame:inView:),
		   cellFrame, controlView);

  // Draw the title
  if (mcell_titleWidth > 0)
    _drawMethods[2](self, @selector(drawTitleWithFrame:inView:),
		   cellFrame, controlView);

  // Draw the key equivalent
  if (mcell_keyEquivalentWidth > 0)
    _drawMethods[3](self, @selector(drawKeyEquivalentWithFrame:inView:),
		   cellFrame, controlView);
}

//
// NSCopying protocol
//
- (id) copyWithZone: (NSZone*)zone
{
  NSMenuItemCell *c = [super copyWithZone: zone];

  c->mcell_highlighted = mcell_highlighted;
  c->mcell_has_submenu = mcell_has_submenu;
  if (mcell_item)
    c->mcell_item = [mcell_item copyWithZone: zone];
  c->mcell_menuView = mcell_menuView;
  c->mcell_needs_sizing = mcell_needs_sizing;

  memcpy(c->_drawMethods, _drawMethods, sizeof(DrawingIMP) * 4);

  return c;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &mcell_highlighted];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &mcell_has_submenu];
  [aCoder encodeConditionalObject: mcell_item];
  [aCoder encodeConditionalObject: mcell_menuView];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &mcell_highlighted];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &mcell_has_submenu];
  mcell_item     = [aDecoder decodeObject];
  mcell_menuView = [aDecoder decodeObject];

  mcell_needs_sizing = YES;

  _drawMethods[0] = (DrawingIMP)
    [self methodForSelector:@selector(drawStateImageWithFrame:inView:)];
  _drawMethods[1] = (DrawingIMP)
    [self methodForSelector:@selector(drawImageWithFrame:inView:)];
  _drawMethods[2] = (DrawingIMP)
    [self methodForSelector:@selector(drawTitleWithFrame:inView:)];
  _drawMethods[3] = (DrawingIMP)
    [self methodForSelector:@selector(drawKeyEquivalentWithFrame:inView:)];

  return self;
}

@end
