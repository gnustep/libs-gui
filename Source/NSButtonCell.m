/** <title>NSButtonCell</title>

   <abstract>The button cell class</abstract>

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

#include "gnustep/gui/config.h"
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include <gnustep/base/GSCategories.h>

#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSSound.h"
#include "AppKit/NSWindow.h"

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

  [self setAlignment: NSCenterTextAlignment];
  _cell.is_bordered = YES;
  _showAltStateMask = NSNoCellMask;	// configure as a NSMomentaryPushButton
  _highlightsByMask = NSPushInCellMask | NSChangeGrayCellMask;
  _delayInterval = 0.4;
  _repeatInterval = 0.075;
  _keyEquivalentModifierMask = NSCommandKeyMask;
  _keyEquivalent = @"";
  _altContents = @"";

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

  return [self _init];
}

- (id) initTextCell: (NSString*)aString
{
  [super initTextCell: aString];

  return [self _init];
}

- (void) dealloc
{
  RELEASE(_altContents);
  RELEASE(_altImage);
  RELEASE(_keyEquivalent);
  RELEASE(_keyEquivalentFont);
  RELEASE(_sound);

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

- (int) cellAttribute: (NSCellAttribute)aParameter
{
  int value = 0;

  switch (aParameter)
    {
    case NSPushInCell:
      if (_highlightsByMask & NSPushInCellMask)
	value = 1;
      break;
    case NSChangeGrayCell:
      if (_showAltStateMask & NSChangeGrayCellMask)
	value = 1;
      break;
    case NSCellLightsByGray:
      if (_highlightsByMask & NSChangeGrayCellMask)
	value = 1;
      break;
    case NSChangeBackgroundCell:
      if (_showAltStateMask & NSChangeBackgroundCellMask)
	value = 1;
      break;
    case NSCellLightsByBackground:
      if (_highlightsByMask & NSChangeBackgroundCellMask)
	value = 1;
      break;
    case NSCellChangesContents:
      if (_showAltStateMask & NSContentsCellMask)
	value = 1;
      break;
    case NSCellLightsByContents:
      if (_highlightsByMask & NSContentsCellMask)
	value = 1;
      break;
    default:
      value = [super cellAttribute: aParameter];
      break;
    }

  return value;
}

- (void) setCellAttribute: (NSCellAttribute)aParameter to: (int)value
{
  switch (aParameter)
    {
    case NSPushInCell:
      if (value)
	_highlightsByMask |= NSPushInCellMask;
      else
	_highlightsByMask &= ~NSPushInCellMask;
      break;
    case NSChangeGrayCell:
      if (value)
	_showAltStateMask |= NSChangeGrayCellMask;
      else
	_showAltStateMask &= ~NSChangeGrayCellMask;
      break;
    case NSChangeBackgroundCell:
      if (value)
	_showAltStateMask |= NSChangeBackgroundCellMask;
      else
	_showAltStateMask &= ~NSChangeBackgroundCellMask;
      break;
    case NSCellChangesContents:
      if (value)
	_showAltStateMask |= NSContentsCellMask;
      else
	_showAltStateMask &= ~NSContentsCellMask;
      break;
    case NSCellLightsByGray:
      if (value)
	_highlightsByMask |= NSChangeGrayCellMask;
      else
	_highlightsByMask &= ~NSChangeGrayCellMask;
      break;
    case NSCellLightsByBackground:
      if (value)
	_highlightsByMask |= NSChangeBackgroundCellMask;
      else
	_highlightsByMask &= ~NSChangeBackgroundCellMask;
      break;
    case NSCellLightsByContents:
      if (value)
	_highlightsByMask |= NSContentsCellMask;
      else
	_highlightsByMask &= ~NSContentsCellMask;
      break;
    default:
      [super setCellAttribute: aParameter to: value];
    }
}

- (void) setFont: (NSFont*)fontObject		
{
  int size;

  [super setFont: fontObject];
  if ((_keyEquivalentFont != nil) && (fontObject != nil) && 
      ((size = [fontObject pointSize]) != [_keyEquivalentFont pointSize]))
    {
      [self setKeyEquivalentFont: [_keyEquivalentFont fontName] 
	    size: size];       
    }
}

- (void) setTitle: (NSString*)aString
{
  [self setStringValue: aString];
}

- (void) setAlternateTitle: (NSString*)aString
{
  ASSIGNCOPY(_altContents, aString);

  if (_control_view)
    {
      if ([_control_view isKindOfClass: [NSControl class]])
	{
	  [(NSControl*)_control_view updateCell: self];
	}
    }
}

- (NSAttributedString *)attributedAlternateTitle
{
  // TODO
  NSDictionary *dict;
  NSAttributedString *attrStr;

  dict = [self _nonAutoreleasedTypingAttributes];
  attrStr = [[NSAttributedString alloc] initWithString: _altContents 
					attributes: dict];
  RELEASE(dict);

  return AUTORELEASE(attrStr);
}

- (void)setAttributedAlternateTitle:(NSAttributedString *)aString
{
  // TODO
  NSString *alternateTitle;
  
  alternateTitle = AUTORELEASE ([[aString string] copy]);
  
  [self setAlternateTitle: alternateTitle];
}

- (NSAttributedString *)attributedTitle
{
  return [self attributedStringValue];
}

- (void)setAttributedTitle:(NSAttributedString *)aString
{
  [self setAttributedStringValue: aString];
}

- (void)setTitleWithMnemonic:(NSString *)aString
{
  // TODO
  [super setTitleWithMnemonic: aString];    
}

- (NSString *)alternateMnemonic
{
  // TODO
  return @"";
}

- (unsigned)alternateMnemonicLocation
{
  // TODO
  return NSNotFound;
}

- (void)setAlternateMnemonicLocation:(unsigned)location
{
  // TODO
}

- (void)setAlternateTitleWithMnemonic:(NSString *)aString
{
  unsigned int location = [aString rangeOfString: @"&"].location;

  [self setAlternateTitle: [aString stringByReplacingString: @"&"
				    withString: @""]];
  // TODO: We should underline this character
  [self setAlternateMnemonicLocation: location];
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
  ASSIGNCOPY(_keyEquivalent, key);
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

  // This seems the best to achieve a correct behaviour
  // (consistent with Nextstep)
  if (!(_cell.is_bordered 
	|| (_highlightsByMask & NSChangeBackgroundCellMask)
	|| (_highlightsByMask & NSChangeGrayCellMask)))
    return NO;
    
  return !_buttoncell_is_transparent;
}

- (NSBezelStyle)bezelStyle
{
  return _bezel_style;
}

- (void)setBezelStyle:(NSBezelStyle)bezelStyle
{
  _bezel_style = bezelStyle;
}

- (BOOL)showsBorderOnlyWhileMouseInside
{
  return _shows_border_only_while_mouse_inside;
}

- (void)setShowsBorderOnlyWhileMouseInside:(BOOL)show
{
  // FIXME: Switch mouse tracking on
  _shows_border_only_while_mouse_inside = show;
}

- (NSGradientType)gradientType
{
  return _gradient_type;
}

- (void)setGradientType:(NSGradientType)gradientType
{
  _gradient_type = gradientType;
}

- (BOOL)imageDimsWhenDisabled
{
  return _image_dims_when_disabled;
}

- (void)setImageDimsWhenDisabled:(BOOL)flag
{
  _image_dims_when_disabled = flag;
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
  // Don't store the button type anywhere

  switch (buttonType)
    {
      case NSMomentaryLightButton: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSNoCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSMomentaryPushButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSNoCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSMomentaryChangeButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSNoCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSPushOnPushOffButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSOnOffButton: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSToggleButton: 
	[self setHighlightsBy: NSPushInCellMask | NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImageDimsWhenDisabled: YES];
	break;
      case NSSwitchButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_SwitchOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_SwitchOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	[self setBordered: NO];
	[self setBezeled: NO];
	[self setImageDimsWhenDisabled: NO];
	break;
      case NSRadioButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_RadioOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_RadioOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	[self setBordered: NO];
	[self setBezeled: NO];
	[self setImageDimsWhenDisabled: NO];
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

// FIXME: The spec says that the stringValue and setStringValue methods should 
// also be redefined. But this does not fit to the way we uses this for the title.

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
      // FIXME Should check the bezel and gradient style
      if (_cell.is_highlighted && (_highlightsByMask & NSPushInCellMask))
        {
          NSDrawGrayBezel(cellFrame, NSZeroRect);
        }
      else
        {
          NSDrawButton(cellFrame, NSZeroRect);
        }
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSRect	imageRect;
  NSAttributedString	*titleToDisplay;
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

  /* Pushed in buttons contents are displaced to the bottom right 1px.  */
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., flippedView ? 1. : -1.);
    }

  /* Determine the background color. */
  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      backgroundColor = [NSColor selectedControlColor];
    }

  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  /* Draw the cell's background color.  
     We draw when there is a border or when highlightsByMask
     is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
     as required by our nextstep-like look and feel.  */
  if (_cell.is_bordered 
      || (_highlightsByMask & NSChangeBackgroundCellMask)
      || (_highlightsByMask & NSChangeGrayCellMask))
    {
      [backgroundColor set];
      NSRectFill (cellFrame);
    }

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   */
  if (mask & NSContentsCellMask)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
        {
	  imageToDisplay = _cell_image;
	}
      titleToDisplay = [self attributedAlternateTitle];
      if (titleToDisplay == nil || [titleToDisplay length] == 0)
        {
	  titleToDisplay = [self attributedTitle];
	}
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = [self attributedTitle];
    }

  if (imageToDisplay)
    {
      imageSize = [imageToDisplay size];
    }

  if (titleToDisplay && (ipos == NSImageAbove || ipos == NSImageBelow))
    {
      titleSize = [titleToDisplay size];
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
      [imageToDisplay compositeToPoint: position operation: NSCompositeSourceOver];
    }
  if (titleToDisplay != nil)
    {
      [self _drawAttributedText: titleToDisplay inFrame: titleRect];
    }

  if (_cell.shows_first_responder
      && [[controlView window] firstResponder] == controlView)
    {
      if (_cell.is_bordered || _cell.is_bezeled)
	NSDottedFrameRect(cellFrame);
      else if (ipos == NSImageOnly)
	NSDottedFrameRect(cellFrame);
      else
	NSDottedFrameRect(titleRect);
    }
}

- (NSSize) cellSize 
{
  NSSize s;
  NSSize borderSize;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSAttributedString	*titleToDisplay;
  NSSize	imageSize;
  NSSize	titleSize;
  
  /* 
   * The following code must be kept in sync with -drawInteriorWithFrame
   */ 
  if (_cell.is_highlighted)
    {
      mask = _highlightsByMask;
    }
  else if (_cell.state)
    {
      mask = _showAltStateMask;
    }
  else
    {
      mask = NSNoCellMask;
    }
  
  if (mask & NSContentsCellMask)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
	{
	  imageToDisplay = _cell_image;
	}
      titleToDisplay = [self attributedAlternateTitle];
      if (titleToDisplay == nil || [titleToDisplay length] == 0)
        {
	  titleToDisplay = [self attributedTitle];
	}
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = [self attributedTitle];
    }
  
  if (imageToDisplay)
    {
      imageSize = [imageToDisplay size];
    }
  else
    { 
      imageSize = NSZeroSize;
    }

  if (titleToDisplay != nil)
    {
      titleSize = [titleToDisplay size];
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

      /* Add some more space because it looks better.  */
      borderSize.height += 2;
      borderSize.width  += 3;
    }
  
  // Add border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;

  return s;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  // FIXME
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
    {
      return theRect;
    }
}

- (void) setSound: (NSSound *)aSound
{
  ASSIGN(_sound, aSound);
}

- (NSSound *) sound
{
  return _sound;
}

- (void) mouseEntered: (NSEvent *)event
{
  _mouse_inside = YES;
}

- (void) mouseExited: (NSEvent *)event
{
  _mouse_inside = NO;
}

- (void) performClick: (id)sender
{
  if (_sound != nil)
    {
      [_sound play];
    }
  [super performClick: sender];
}

/*
 * Comparing to Another NSButtonCell
 */
- (NSComparisonResult) compare: (id)otherCell
{
  if ([otherCell isKindOfClass: [NSButtonCell class]] == NO)
    {
      [NSException raise: NSBadComparisonException
		   format: @"NSButtonCell comparison with non-NSButtonCell"];
    }
  return [super compare: otherCell];
}

/*
 * NSCopying protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSButtonCell	*c = [super copyWithZone: zone];
  
  /* Hmmm. */
  c->_altContents = [_altContents copyWithZone: zone];
  TEST_RETAIN (_altImage);
  TEST_RETAIN (_keyEquivalent);
  TEST_RETAIN (_keyEquivalentFont);

  return c;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME: Add new ivars
  BOOL tmp;
  [super encodeWithCoder: aCoder];

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

}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // FIXME: Add new ivars
  BOOL tmp;
  [super initWithCoder: aDecoder];

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

  return self;
}

@end
