/*
   NSButtonCell.m

   The button cell class

   Copyright (C) 1996-1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	        Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998

   Modified: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
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
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/PSOperators.h>

@implementation NSButtonCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSButtonCell class])
    [self setVersion: 1];
}

/*
 * Instance methods
 */
- (id) _init
{
  // Implicitly performed by allocation:
  //
  //_buttoncell_is_transparent = NO;
  //_altContents = nil;

  _cell.text_align = NSCenterTextAlignment;
  _cell.is_bordered = YES;
  _showAltStateMask = NSNoCellMask;	// configure as a NSMomentaryPushButton
  _highlightsByMask = NSPushInCellMask | NSChangeGrayCellMask;
  _delayInterval = 0.4;
  _repeatInterval = 0.075;
  _keyEquivalentModifierMask = NSCommandKeyMask;

  return self;
}

- (id) init
{
  [self initTextCell: @"Button"];

  return self;
}

- (id) initImageCell: (NSImage*)anImage
{
  [super initImageCell: anImage];

  _contents = nil;

  return [self _init];
}

- (id) initTextCell: (NSString*)aString
{
  [super initTextCell: aString];

  return [self _init];
}

- (void) dealloc
{
  [_altContents release];
  [_altImage release];
  [_keyEquivalent release];
  [_keyEquivalentFont release];

  [super dealloc];
}

/*
 * Setting the Titles
 */
- (NSString*) title								
{
  return [self stringValue];
}

- (NSString*) alternateTitle					
{
  return _altContents;
}

- (void) setFont: (NSFont*)fontObject		
{
  [super setFont: fontObject];
}

- (void) setTitle: (NSString*)aString
{
  [self setStringValue: aString];
}

- (void) setAlternateTitle: (NSString*)aString
{
  NSString* string = [aString copy];

  ASSIGN(_altContents, string);
  [string release]; 
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl*)_control_view updateCell: self];
}

/*
 * Setting the Images
 */
- (NSImage*) alternateImage						
{
  return _altImage;
}

- (NSCellImagePosition) imagePosition			
{
  return _cell.image_position;
}

- (void) setAlternateImage: (NSImage*)anImage
{
  ASSIGN(_altImage, anImage);
}

- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  _cell.image_position = aPosition;
}

/*
 * Setting the Repeat Interval
 */
- (void) getPeriodicDelay: (float*)delay interval: (float*)interval
{
  *delay = _delayInterval;
  *interval = _repeatInterval;
}

- (void) setPeriodicDelay: (float)delay interval: (float)interval
{
  _delayInterval = delay;
  _repeatInterval = interval;
}

/*
 * Setting the Key Equivalent
 */
- (NSString*) keyEquivalent
{
  return _keyEquivalent;
}

- (NSFont*) keyEquivalentFont
{
  return _keyEquivalentFont;
}

- (unsigned int) keyEquivalentModifierMask
{
  return _keyEquivalentModifierMask;
}

- (void) setKeyEquivalent: (NSString*)key
{
  if (_keyEquivalent != key)
    {
      [_keyEquivalent release];
      _keyEquivalent = [key copy];
    }
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  _keyEquivalentModifierMask = mask;
}

- (void) setKeyEquivalentFont: (NSFont*)fontObj
{
  ASSIGN(_keyEquivalentFont, fontObj);
}

- (void) setKeyEquivalentFont: (NSString*)fontName size: (float)fontSize
{
  ASSIGN(_keyEquivalentFont, [NSFont fontWithName: fontName size: fontSize]);
}

/*
 * Modifying Graphic Attributes
 */
- (BOOL) isTransparent					
{
  return _buttoncell_is_transparent;
}

- (void) setTransparent: (BOOL)flag	
{
  _buttoncell_is_transparent = flag;
}

- (BOOL) isOpaque
{
  /*
   * MacOS-X says we should return !transparent && [self isBordered], 
   * but that's wrong in our case, since if there is no border, 
   * we draw the interior of the cell to fill completely the bounds.  
   * They are likely to draw differently.
   */
  return !_buttoncell_is_transparent;
}

/*
 * Modifying Graphic Attributes
 */
- (int) highlightsBy						
{
  return _highlightsByMask;
}

- (void) setHighlightsBy: (int)mask	
{
  _highlightsByMask = mask;
}

- (void) setShowsStateBy: (int)mask	
{
  _showAltStateMask = mask;
}

- (void) setButtonType: (NSButtonType)buttonType
{
  _cell.type = buttonType;

  switch (buttonType)
    {
      case NSMomentaryLight: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSMomentaryPushButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSMomentaryChangeButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSPushOnPushOffButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	break;
      case NSOnOffButton: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	break;
      case NSToggleButton: 
	[self setHighlightsBy: NSPushInCellMask | NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	break;
      case NSSwitchButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_SwitchOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_SwitchOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	break;
      case NSRadioButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_RadioOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_RadioOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	break;
    }
}

- (int) showsStateBy						
{
  return _showAltStateMask;
}

- (void) setIntValue: (int)anInt		
{
  [self setState: (anInt != 0)];
}

- (void) setFloatValue: (float)aFloat	
{
  [self setState: (aFloat != 0)];
}

- (void) setDoubleValue: (double)aDouble
{
  [self setState: (aDouble != 0)];
}

- (int) intValue							
{
  return _cell.state;
}

- (float) floatValue						
{
  return _cell.state;
}

- (double) doubleValue					
{
  return _cell.state;
}

/*
 * Displaying
 */
- (NSColor*) textColor
{
  if (_cell.is_disabled == YES)
    return [NSColor disabledControlTextColor];
  if ((_cell.state && (_showAltStateMask & NSChangeGrayCellMask))
      || (_cell.is_highlighted && (_highlightsByMask & NSChangeGrayCellMask)))
    return [NSColor selectedControlTextColor];
  return [NSColor controlTextColor];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // draw the border if needed
  if (_cell.is_bordered)
    {
      [controlView lockFocus];
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

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL		showAlternate = NO;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSRect	imageRect;
  NSString	*titleToDisplay;
  NSRect	titleRect;
  NSSize	imageSize = {0, 0};
  NSSize        titleSize = {0, 0};
  NSColor	*backgroundColor = nil;
  BOOL		flippedView = [controlView isFlipped];
  NSCellImagePosition ipos = _cell.image_position;

  // transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  _control_view = controlView;

  cellFrame = [self drawingRectForBounds: cellFrame];
  [controlView lockFocus];

  // pushed in buttons contents are displaced to the bottom right 1px
  if (_cell.is_bordered && _cell.is_highlighted
    && (_highlightsByMask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., flippedView ? 1. : -1.);
    }

  // determine the background color
  if (_cell.state)
    {
      if (_showAltStateMask
	& (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
	{
	  backgroundColor = [NSColor selectedControlColor];
	}
    }

  if (_cell.is_highlighted)
    {
      if (_highlightsByMask
	& (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
	{
	  backgroundColor = [NSColor selectedControlColor];
	}
    }

  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  // set cell's background color
  [backgroundColor set];
  NSRectFill(cellFrame);

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   */
  if (_cell.is_highlighted)
    mask = _highlightsByMask;
  else
    mask = _showAltStateMask;
  if (mask & NSContentsCellMask)
    showAlternate = _cell.state;

  if (showAlternate || _cell.is_highlighted)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
	imageToDisplay = _cell_image;
      titleToDisplay = _altContents;
      if (titleToDisplay == nil || [titleToDisplay isEqual: @""])
        titleToDisplay = _contents;
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = _contents;
    }

  if (imageToDisplay)
    {
      [imageToDisplay setBackgroundColor: backgroundColor];
      imageSize = [imageToDisplay size];
    }

  if (titleToDisplay && (ipos == NSImageAbove || ipos == NSImageBelow))
    {
      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
					   _cell_font, 
					 NSFontAttributeName,
					 nil];
      titleSize = [titleToDisplay sizeWithAttributes: dict];
    }

  if (flippedView == YES)
    {
      if (ipos == NSImageAbove)
	{
	  ipos = NSImageBelow;
	}
      else if (ipos == NSImageBelow)
	{
	  ipos = NSImageAbove;
	}
    }
  
  switch (ipos)
    {
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	break;

      case NSImageOnly: 
	titleToDisplay = nil;
	imageRect = cellFrame;
	break;

      case NSImageLeft: 
	imageRect.origin = cellFrame.origin;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x += 3;
	    imageRect.size.height -= 2;
	    imageRect.origin.y += 1;
	  }
	titleRect = imageRect;
	titleRect.origin.x += imageSize.width + xDist;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    titleRect.size.width -= 3;
	  }
	break;

      case NSImageRight: 
	imageRect.origin.x = NSMaxX(cellFrame) - imageSize.width;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x -= 3;
	    imageRect.size.height -= 2;
	    imageRect.origin.y += 1;
	  }
	titleRect.origin = cellFrame.origin;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	titleRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 3;
	  }
	break;

      case NSImageAbove: 
	/*
         * In this case, imageRect is all the space we can allocate
	 * above the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = cellFrame.origin.y;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.origin.y += titleRect.size.height + yDist;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = cellFrame.size.height;
	imageRect.size.height -= titleSize.height + yDist;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.size.width -= 6;
	    imageRect.origin.x   += 3;
	    titleRect.size.width -= 6;
	    titleRect.origin.x   += 3;
	    imageRect.size.height -= 1;
	    titleRect.size.height -= 1;
	    titleRect.origin.y    += 1;
	  }
	break;

      case NSImageBelow: 
	/*
	 * In this case, imageRect is all the space we can allocate
	 * below the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = cellFrame.origin.y + cellFrame.size.height;
	titleRect.origin.y -= titleSize.height;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = cellFrame.size.height;
	imageRect.size.height -= titleSize.height + yDist;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.size.width -= 6;
	    imageRect.origin.x   += 3;
	    titleRect.size.width -= 6;
	    titleRect.origin.x   += 3;
	    imageRect.size.height -= 1;
	    imageRect.origin.y    += 1;
	    titleRect.size.height -= 1;
	  }
	break;

      case NSImageOverlaps: 
	titleRect = cellFrame;
	imageRect = cellFrame;
	// TODO: Add distance from border if needed
	break;
    }
  if (imageToDisplay != nil)
    {
      NSSize size;
      NSPoint position;

      size = [imageToDisplay size];
      position.x = MAX(NSMidX(imageRect) - (size.width/2.),0.);
      position.y = MAX(NSMidY(imageRect) - (size.height/2.),0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if (flippedView)
	{
	  position.y += size.height;
	}
      [imageToDisplay compositeToPoint: position operation: NSCompositeCopy];
    }
  if (titleToDisplay != nil)
    {
      [self _drawText: titleToDisplay inFrame: titleRect];
    }
  [controlView unlockFocus];
}

- (NSSize) cellSize 
{
  NSSize s;
  NSSize borderSize;
  BOOL		showAlternate = NO;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSString	*titleToDisplay;
  NSSize	imageSize;
  NSSize	titleSize;
  
  /* 
   * The following code must be kept in sync with -drawInteriorWithFrame
   */
  
  if (_cell.is_highlighted)
    mask = _highlightsByMask;
  else
    mask = _showAltStateMask;
  if (mask & NSContentsCellMask)
    showAlternate = _cell.state;
  
  if (showAlternate || _cell.is_highlighted)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
	imageToDisplay = _cell_image;
      titleToDisplay = _altContents;
      if (titleToDisplay == nil || [titleToDisplay isEqual: @""])
	titleToDisplay = _contents;
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = _contents;
    }
  
  if (imageToDisplay)
    imageSize = [imageToDisplay size];
  else 
    imageSize = NSZeroSize;
  
  if (titleToDisplay != nil)
    {
      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
					   _cell_font, 
					 NSFontAttributeName,
					 nil];
      titleSize = [titleToDisplay sizeWithAttributes: dict];

    }
  else
    {
      titleSize = NSZeroSize;
    }
  
  switch (_cell.image_position)
    {
      case NSNoImage: 
	s = titleSize;
	break;
	
      case NSImageOnly: 
	s = imageSize;
	break;
	
      case NSImageLeft: 
      case NSImageRight: 
	s.width = imageSize.width + titleSize.width + xDist;
	if (imageSize.height > titleSize.height)
	  s.height = imageSize.height;
	else 
	  s.height = titleSize.height;
	break;
	
      case NSImageBelow: 
      case NSImageAbove: 
	if (imageSize.width > titleSize.width)
	  s.width = imageSize.width;
	else 
	  s.width = titleSize.width;
	s.height = imageSize.height + titleSize.height; // + yDist ??
	break;
	
      case NSImageOverlaps: 
	if (imageSize.width > titleSize.width)
	  s.width = imageSize.width;
	else
	  s.width = titleSize.width;
	
	if (imageSize.height > titleSize.height)
	  s.height = imageSize.height;
	else
	  s.height = titleSize.height;

	break;
    }
  
  // Get border size
  if (_cell.is_bordered)
    // Buttons only have three paths for border (NeXT looks)
    borderSize = NSMakeSize (1.5, 1.5);
  else
    borderSize = NSZeroSize;

  if ((_cell.is_bordered || _cell.is_bezeled) 
    && (_cell.image_position != NSImageOnly))
    {
      borderSize.height += 1;
      borderSize.width  += 3;
    }
  
  // Add border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;

  return s;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  if (_cell.is_bordered)
    {
      /*
       * Special case:  Buttons have only three different paths for border.
       * One white path at the top left corner, one black path at the
       * bottom right and another in dark gray at the inner bottom right.
       */
      float yDelta = [_control_view isFlipped] ? 1. : 2.;
      return NSMakeRect (theRect.origin.x + 1.,
			 theRect.origin.y + yDelta,
			 theRect.size.width - 3.,
			 theRect.size.height - 3.);
    }
  else
    return theRect;
}

/*
 * NSCopying protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSButtonCell	*c = [super copyWithZone: zone];

  c->_altContents = [_altContents copyWithZone: zone];
  if (_altImage)
    c->_altImage = [_altImage retain];
  c->_keyEquivalent = [_keyEquivalent copyWithZone: zone];
  if (_keyEquivalentFont)
    c->_keyEquivalentFont = [_keyEquivalentFont retain];
  c->_keyEquivalentModifierMask = _keyEquivalentModifierMask;
  c->_buttoncell_is_transparent = _buttoncell_is_transparent;
  c->_highlightsByMask = _highlightsByMask;
  c->_showAltStateMask = _showAltStateMask;

  return c;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;
  [super encodeWithCoder: aCoder];

  NSDebugLog(@"NSButtonCell: start encoding\n");

  [aCoder encodeObject: _keyEquivalent];
  [aCoder encodeObject: _keyEquivalentFont];
  [aCoder encodeObject: _altContents];
  [aCoder encodeObject: _altImage];
  tmp = _buttoncell_is_transparent;
  [aCoder encodeValueOfObjCType: @encode(BOOL)
			     at: &tmp];
  [aCoder encodeValueOfObjCType: @encode(unsigned int)
			     at: &_keyEquivalentModifierMask];
  [aCoder encodeValueOfObjCType: @encode(unsigned int)
			     at: &_highlightsByMask];
  [aCoder encodeValueOfObjCType: @encode(unsigned int)
			     at: &_showAltStateMask];

  NSDebugLog(@"NSButtonCell: finish encoding\n");
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL tmp;
  [super initWithCoder: aDecoder];

  NSDebugLog(@"NSButtonCell: start decoding\n");

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_keyEquivalent];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_keyEquivalentFont];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_altContents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_altImage];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
  _buttoncell_is_transparent = tmp;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int)
			       at: &_keyEquivalentModifierMask];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int)
			       at: &_highlightsByMask];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int)
			       at: &_showAltStateMask];

  NSDebugLog(@"NSButtonCell: finish decoding\n");

  return self;
}

@end
