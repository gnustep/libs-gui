/** <title>NSMenuItemCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
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

static Class	colorClass = 0;		/* Cache color class.	*/
static NSImage	*arrowImage = nil;	/* Cache arrow image.	*/
static NSImage	*arrowImageH = nil;


+ (void) initialize
{
  if (self == [NSMenuItemCell class])
    {
      [self setVersion: 1];
      colorClass = [NSColor class];
      arrowImage = [[NSImage imageNamed: @"common_3DArrowRight"] copy];
      arrowImageH = [[NSImage imageNamed: @"common_3DArrowRightH"] copy];
    }
}

- (id) init
{
  [super init];
  _target = nil;
  _highlightsByMask = NSChangeBackgroundCellMask;
  _showAltStateMask = NSNoCellMask;
  _cell.image_position = NSNoImage;
  [self setAlignment: NSLeftTextAlignment];
  [self setFont: [NSFont menuFontOfSize: 0]];

  return self;
}

- (void) dealloc
{
  RELEASE(_menuItem);
  RELEASE(_menuView);

  [super dealloc];
}

- (void) setHighlighted:(BOOL)flag
{
  _cell.is_highlighted = flag;
}

- (BOOL) isHighlighted
{
  // Same as in super class
  return _cell.is_highlighted;
}

- (void) setMenuItem:(NSMenuItem *)item
{
  ASSIGN(_menuItem, item);
}

- (NSMenuItem *) menuItem
{
  return _menuItem;
}

- (void) setMenuView:(NSMenuView *)menuView
{
  ASSIGN(_menuView, menuView);
  if ([[_menuView menu] _ownedByPopUp])
    {
      _mcell_belongs_to_popupbutton = YES;
      [self setImagePosition: NSImageRight];
    }
}

- (NSMenuView *) menuView
{
  return _menuView;
}

- (void) calcSize
{
  NSSize   componentSize;
  NSImage *anImage = nil;
  float    neededMenuItemHeight = 20;

  // State Image
  if ([_menuItem changesState])
    {
      // NSOnState
      if ([_menuItem onStateImage])
        componentSize = [[_menuItem onStateImage] size];
      else
      	componentSize = NSMakeSize(0,0);
      _stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;

      // NSOffState
      if ([_menuItem offStateImage])
        componentSize = [[_menuItem offStateImage] size];
      else
      	componentSize = NSMakeSize(0,0);
      if (componentSize.width > _stateImageWidth)
	_stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;

      // NSMixedState
      if ([_menuItem mixedStateImage])
        componentSize = [[_menuItem mixedStateImage] size];
      else
      	componentSize = NSMakeSize(0,0);
      if (componentSize.width > _stateImageWidth)
	_stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;
    }
  else
    {
      _stateImageWidth = 0.0;
    }

  // Image
  if ((anImage = [_menuItem image]) && _cell.image_position == NSNoImage)
    [self setImagePosition: NSImageLeft];
  if (anImage)
    {
      componentSize = [anImage size];
      _imageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;
    }
  else
    {
      _imageWidth = 0.0;
    }

  // Title and Key Equivalent
  componentSize = [self _sizeText: [_menuItem title]];
  _titleWidth = componentSize.width;
  if (componentSize.height > neededMenuItemHeight)
    neededMenuItemHeight = componentSize.height;
  componentSize = [self _sizeText: [_menuItem keyEquivalent]];
  _keyEquivalentWidth = componentSize.width;
  if (componentSize.height > neededMenuItemHeight)
    neededMenuItemHeight = componentSize.height;

  // Submenu Arrow
  if ([_menuItem hasSubmenu])
    {
      componentSize = [arrowImage size];
      _keyEquivalentWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
	neededMenuItemHeight = componentSize.height;
    }

  // Cache definitive height
  _menuItemHeight = neededMenuItemHeight;

  // At the end we set sizing to NO.
  _needs_sizing = NO;
}

- (void) setNeedsSizing:(BOOL)flag
{
  _needs_sizing = flag;
}

- (BOOL) needsSizing
{
  return _needs_sizing;
}

- (float) imageWidth
{
  if (_needs_sizing)
    [self calcSize];

  return _imageWidth;
}

- (float) titleWidth
{
  if (_needs_sizing)
    [self calcSize];

  return _titleWidth;
}

- (float) keyEquivalentWidth
{
  if (_needs_sizing)
    [self calcSize];

  return _keyEquivalentWidth;
}

- (float) stateImageWidth
{
  if (_needs_sizing)
    [self calcSize];

  return _stateImageWidth;
}

//
// Sizes for drawing taking into account NSMenuView adjustments.
//
- (NSRect) imageRectForBounds:(NSRect)cellFrame
{
  if (_mcell_belongs_to_popupbutton && _cell.image_position)
    {
      /* Special case: draw image on the extreme right [FIXME check the distance]*/
      cellFrame.origin.x  += cellFrame.size.width - _imageWidth - 4;
      cellFrame.size.width = _imageWidth;
      return cellFrame;
    }

  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [_menuView imageAndTitleOffset];
  cellFrame.size.width = [_menuView imageAndTitleWidth];
  /* If the state image has no width we do not add additional padding.  */
  if ([_menuItem changesState]  &&  _stateImageWidth > 0)
    {
      cellFrame.origin.x += [_menuView stateImageWidth]
	+ 2 * [_menuView horizontalEdgePadding];
    }

  switch (_cell.image_position)
    {
      case NSNoImage: 
	cellFrame = NSZeroRect;
	break;

      case NSImageOnly:
      case NSImageOverlaps:
	break;

      case NSImageLeft:
	cellFrame.size.width = _imageWidth;
	break;

      case NSImageRight:
	cellFrame.origin.x  += _titleWidth + xDist;
	cellFrame.size.width = _imageWidth;
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
  cellFrame.origin.x  += [_menuView keyEquivalentOffset];
  cellFrame.size.width = [_menuView keyEquivalentWidth];

  return cellFrame;
}

- (NSRect) stateImageRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [_menuView stateImageOffset];
  cellFrame.size.width = [_menuView stateImageWidth];

  return cellFrame;
}

- (NSRect) titleRectForBounds:(NSRect)cellFrame
{
  // Calculate the image part of cell frame from NSMenuView
  cellFrame.origin.x  += [_menuView imageAndTitleOffset];
  cellFrame.size.width = [_menuView imageAndTitleWidth];
  /* If the state image has no width we do not add additional padding.  */
  if ([_menuItem changesState]  &&  _stateImageWidth > 0)
    {
      cellFrame.origin.x += [_menuView stateImageWidth]
	+ 2 * [_menuView horizontalEdgePadding];
    }

  switch (_cell.image_position)
    {
      case NSNoImage:
      case NSImageOverlaps:
	break;

      case NSImageOnly: 
	cellFrame = NSZeroRect;
	break;

      case NSImageLeft:
	cellFrame.origin.x  += _imageWidth + xDist;
	cellFrame.size.width = _titleWidth;
	break;

      case NSImageRight: 
	cellFrame.size.width = _titleWidth;
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
- (void) drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
				  inView: (NSView *)controlView
{
  if (!_cell.is_bordered)
    return;

  [controlView lockFocus];

  if (_mcell_belongs_to_popupbutton)
    {
      cellFrame.origin.x--;
    }

  if (_cell.is_highlighted && (_highlightsByMask & NSPushInCellMask))
    {
      NSDrawGrayBezel(cellFrame, NSZeroRect);
    }
  else
    {
      NSDrawButton(cellFrame, NSZeroRect);
    }

  [controlView unlockFocus];
}

- (void) drawImageWithFrame: (NSRect)cellFrame
		     inView: (NSView *)controlView
{
  NSSize	size;
  NSPoint	position;

  cellFrame = [self imageRectForBounds: cellFrame];
  size = [_imageToDisplay size];
  position.x = MAX(NSMidX(cellFrame) - (size.width/2.), 0.);
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([controlView isFlipped])
    position.y += size.height;

  if (nil != _backgroundColor)
    [_imageToDisplay setBackgroundColor: _backgroundColor];
  [_imageToDisplay compositeToPoint: position operation: NSCompositeSourceOver];
}

- (void) drawKeyEquivalentWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
  cellFrame = [self keyEquivalentRectForBounds: cellFrame];

  if ([_menuItem hasSubmenu])
    {
      NSSize	size;
      NSPoint	position;
      NSImage	*imageToDraw;

      if (_cell.is_highlighted)
	imageToDraw = arrowImageH;
      else
	imageToDraw = arrowImage;
      size = [imageToDraw size];
      position.x = cellFrame.origin.x + cellFrame.size.width - size.width;
      position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
	position.y += size.height;

      if (nil != _backgroundColor)
	[imageToDraw setBackgroundColor: _backgroundColor];
      [imageToDraw compositeToPoint: position operation: NSCompositeSourceOver];
    }
  else
    [self _drawText: [_menuItem keyEquivalent] inFrame: cellFrame];
}

- (void) drawSeparatorItemWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
  // FIXME: This only has sense in MacOS or Windows interface styles.
  // Maybe somebody wants to support this (Lazaro).
}

- (void) drawStateImageWithFrame: (NSRect)cellFrame
			  inView: (NSView*)controlView
{
  NSSize	size;
  NSPoint	position;
  NSImage	*imageToDisplay;

  switch ([_menuItem state])
    {
      case NSOnState:
	imageToDisplay = [_menuItem onStateImage];
	break;

      case NSMixedState:
	imageToDisplay = [_menuItem mixedStateImage];
	break;

      case NSOffState:
      default:
	imageToDisplay = [_menuItem offStateImage];
	break;
    }

  if (imageToDisplay == nil)
    {
      return;
    }
  
  size = [imageToDisplay size];
  cellFrame = [self stateImageRectForBounds: cellFrame];
  position.x = MAX(NSMidX(cellFrame) - (size.width/2.),0.);
  position.y = MAX(NSMidY(cellFrame) - (size.height/2.),0.);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if ([controlView isFlipped])
    {
      position.y += size.height;
    }
  
  if (nil != _backgroundColor)
    {
      [imageToDisplay setBackgroundColor: _backgroundColor];
    }
  [imageToDisplay compositeToPoint: position operation: NSCompositeSourceOver];
}

- (void) drawTitleWithFrame:(NSRect)cellFrame
		    inView:(NSView *)controlView
{
  if ([_menuItem isEnabled])
    _cell.is_disabled = NO;
  else
    _cell.is_disabled = YES;

  [self _drawText: [_menuItem title]
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

  // Do nothing if the window is deferred
  if ([[controlView window] gState] == 0)
    return;

  // Draw the border if needed
  [self drawBorderAndBackgroundWithFrame: cellFrame inView: controlView];

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned  mask;

  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  cellFrame = [self drawingRectForBounds: cellFrame];
  [controlView lockFocus];

  if (_cell.is_highlighted)
    {
      mask = _highlightsByMask;

      if (_cell.state)
	mask &= ~_showAltStateMask;
    }
  else if (_cell.state)
    mask = _showAltStateMask;
  else
    mask = NSNoCellMask;

  // pushed in buttons contents are displaced to the bottom right 1px
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., [controlView isFlipped] ? 1. : -1.);
    }

  /*
   * Determine the background color and cache it in an ivar so that the
   * low-level drawing methods don't need to do it again.
   */
  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      _backgroundColor = [colorClass selectedMenuItemColor];
    }
  if (_backgroundColor == nil)
    _backgroundColor = [colorClass controlBackgroundColor];

  // Set cell's background color
  [_backgroundColor set];
  if (_mcell_belongs_to_popupbutton)
    {
      cellFrame.origin.x--;
      NSRectFill(cellFrame);
      cellFrame.origin.x++;
    }
  else
    {
      NSRectFill(cellFrame);
    }

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   * The results are saved in two ivars for use in other
   * drawing methods.
   */
  if (mask & NSContentsCellMask)
    {
      _imageToDisplay = _altImage;
      if (!_imageToDisplay)
	_imageToDisplay = [_menuItem image];
      _titleToDisplay = _altContents;
      if (_titleToDisplay == nil || [_titleToDisplay isEqual: @""])
        _titleToDisplay = [_menuItem title];
    }
  else
    {
      _imageToDisplay = [_menuItem image];
      _titleToDisplay = [_menuItem title];
    }

  if (_imageToDisplay)
    {
      _imageWidth = [_imageToDisplay size].width;
    }

  // Draw the state image
  if (_stateImageWidth > 0)
    [self drawStateImageWithFrame: cellFrame inView: controlView];

  // Draw the image
  if (_imageWidth > 0)
    [self drawImageWithFrame: cellFrame inView: controlView];

  // Draw the title
  if (_titleWidth > 0)
    [self drawTitleWithFrame: cellFrame inView: controlView];

  // Draw the key equivalent
  if (_keyEquivalentWidth > 0)
    [self drawKeyEquivalentWithFrame: cellFrame inView: controlView];

  [controlView unlockFocus];
  _backgroundColor = nil;
}

//
// NSCopying protocol
//
- (id) copyWithZone: (NSZone*)zone
{
  NSMenuItemCell *c = [super copyWithZone: zone];

  if (_menuItem)
    c->_menuItem = [_menuItem copyWithZone: zone];
  c->_menuView = RETAIN(_menuView);

  return c;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _menuItem];
  [aCoder encodeConditionalObject: _menuView];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  _menuItem = [aDecoder decodeObject];
  _menuView = [aDecoder decodeObject];

  _needs_sizing = YES;

  return self;
}

@end
