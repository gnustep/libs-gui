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

#include "config.h"
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSValue.h>
#include <GNUstepBase/GSCategories.h>

#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSSound.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSDrawFunctions.h"

#include <math.h>

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
  _gradient_type = NSGradientNone;
  _image_dims_when_disabled = NO;

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
  return !_buttoncell_is_transparent && _cell.is_bordered;
}

- (NSBezelStyle) bezelStyle
{
  return _bezel_style;
}

- (void) setBezelStyle: (NSBezelStyle)bezelStyle
{
  _bezel_style = bezelStyle;
}

- (BOOL) showsBorderOnlyWhileMouseInside
{
  return _shows_border_only_while_mouse_inside;
}

- (void) setShowsBorderOnlyWhileMouseInside: (BOOL)show
{
  if (_shows_border_only_while_mouse_inside == show)
    {
      return;
    }

  _shows_border_only_while_mouse_inside = show;
  // FIXME Switch mouse tracking on
}

- (NSGradientType) gradientType
{
  return _gradient_type;
}

- (void) setGradientType: (NSGradientType)gradientType
{
  _gradient_type = gradientType;
}

- (BOOL) imageDimsWhenDisabled
{
  return _image_dims_when_disabled;
}

- (void) setImageDimsWhenDisabled:(BOOL)flag
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
	[self setImage: [NSImage imageNamed: @"NSSwitch"]];
	[self setAlternateImage: [NSImage imageNamed: @"NSHighlightedSwitch"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	[self setBordered: NO];
	[self setBezeled: NO];
	[self setImageDimsWhenDisabled: NO];
	break;
      case NSRadioButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"NSRadioButton"]];
	[self setAlternateImage: [NSImage imageNamed: @"NSHighlightedRadioButton"]];
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

- (void) setObjectValue: (id)object
{
  if (object == nil)
    {
      [self setState: NSOffState];
    }
  else if ([object respondsToSelector: @selector(intValue)])
    {
      [self setState: [object intValue]];
    }
  else
    {
      [self setState: NSOnState];
    }
}

- (id) objectValue
{
  if (_cell.state == NSOffState)
    {	
      return [NSNumber numberWithBool: NO];
    }
  else if (_cell.state == NSOnState)
    {	
      return [NSNumber numberWithBool: YES];
    }
  else // NSMixedState
    {	
      return [NSNumber numberWithInt: -1];
    }
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
  if ((_cell.is_bordered) && 
      (!_shows_border_only_while_mouse_inside || _mouse_inside))
    {
      // FIXME Should check the bezel and gradient style
      if (_cell.is_highlighted && (_highlightsByMask & NSPushInCellMask))
        {
	  [GSDrawFunctions drawGrayBezel: cellFrame : NSZeroRect];
        }
      else
        {
	  [GSDrawFunctions drawButton: cellFrame : NSZeroRect];
        }
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawGradientWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  float   start_white = 0.0;
  float   end_white = 0.0;
  float   white = 0.0;
  float   white_step = 0.0;
  float   h, s, v, a;
  NSColor *lightGray = nil;
  NSColor *gray = nil;
  NSColor *darkGray = nil;
  NSPoint p1, p2;

  lightGray = [NSColor colorWithDeviceRed:0.83 green:0.83 blue:0.83 alpha:1.0];
  gray = [NSColor colorWithDeviceRed:0.50 green:0.50 blue:0.50 alpha:1.0];
  darkGray = [NSColor colorWithDeviceRed:0.32 green:0.32 blue:0.32 alpha:1.0];

  switch (_gradient_type)
    {
    case NSGradientNone:
      return;
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
  white_step = fabs(start_white - end_white)/
               (cellFrame.size.width + cellFrame.size.height);

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

  /* Draw the cell's background color.  
     We draw when there is a border or when highlightsByMask
     is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
     as required by our nextstep-like look and feel.  */
  if (_cell.is_bordered 
      || (_highlightsByMask & NSChangeBackgroundCellMask)
      || (_highlightsByMask & NSChangeGrayCellMask))
    {
      /* Determine the background color. */
      if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
        {
          backgroundColor = [NSColor selectedControlColor];
        }
      else if (_cell.is_bordered) 
        {
          backgroundColor = [NSColor controlBackgroundColor];
        }
      
      if (backgroundColor != nil) 
        {
          [backgroundColor set];
          NSRectFill (cellFrame);
        }
      
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

  if (imageToDisplay && ipos != NSNoImage)
    {
      imageSize = [imageToDisplay size];
    }

  if (titleToDisplay && ipos != NSImageOnly)
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
  
  /*
  The size calculations here should be changed very carefully, and _must_ be
  kept in sync with -cellSize. Changing the calculations to require more
  space isn't OK; this breaks interfaces designed using the old sizes by
  clipping away parts of the title.

  The current size calculations ensure that for bordered or bezeled cells,
  there's always at least a three point margin between the size returned by
  -cellSize and the minimum size required not to clip text. (In other words,
  the text can become three points wider (due to eg. font mismatches) before
  you lose the last character.)
  */
  switch (ipos)
    {
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
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
	  }
	titleRect = imageRect;
	titleRect.origin.x += imageSize.width + GSCellTextImageXDist;
	titleRect.size.width = NSMaxX(cellFrame) - titleRect.origin.x;
	if (titleSize.width + 3 <= titleRect.size.width)
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
	  }
	titleRect.origin = cellFrame.origin;
	titleRect.size.width = imageRect.origin.x - titleRect.origin.x - GSCellTextImageXDist;
	titleRect.size.height = cellFrame.size.height;
	if (titleSize.width + 3 <= titleRect.size.width)
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
	imageRect.origin.y = NSMaxY(titleRect) + GSCellTextImageYDist;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = NSMaxY(cellFrame) - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.y -= 1;
	  }
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageBelow: 
	/*
	 * In this case, imageRect is all the space we can allocate
	 * below the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = NSMaxY(cellFrame) - titleSize.height;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = titleRect.origin.y - GSCellTextImageYDist - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.y += 1;
	  }
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageOverlaps: 
	imageRect = cellFrame;
	titleRect = cellFrame;
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;
    }

  // Draw gradient
  if (!_cell.is_highlighted && _gradient_type != NSGradientNone)
    {
      [self drawGradientWithFrame: cellFrame inView: controlView];
    }
    
  // Draw image
  if (imageToDisplay != nil)
    {
      NSSize size;
      NSPoint position;

      size = [imageToDisplay size];
      position.x = MAX(NSMidX(imageRect) - (size.width / 2.), 0.);
      position.y = MAX(NSMidY(imageRect) - (size.height / 2.), 0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if (flippedView)
	{
	  position.y += size.height;
	}
	
      if (_cell.is_disabled && _image_dims_when_disabled)
	{
	  [imageToDisplay dissolveToPoint: position fraction: 0.5];
	}
      else
	{
	  [imageToDisplay compositeToPoint: position 
	                         operation: NSCompositeSourceOver];
	}
    }

  // Draw title
  if (titleToDisplay != nil)
    {
      [self _drawAttributedText: titleToDisplay inFrame: titleRect];
    }

  // Draw first responder
  if (_cell.shows_first_responder
      && [[controlView window] firstResponder] == controlView)
    {
      NSDottedFrameRect(cellFrame);
    }
}

- (NSSize) cellSize
{
  NSSize s;
  NSSize borderSize;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSAttributedString	*titleToDisplay;
  NSSize	imageSize = NSZeroSize;
  NSSize	titleSize = NSZeroSize;
  
  /* The size calculations here must be kept in sync with
  -drawInteriorWithFrame. */

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

  if (titleToDisplay != nil)
    {
      titleSize = [titleToDisplay size];
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
	s.width = imageSize.width + titleSize.width + GSCellTextImageXDist;
	s.height = MAX(imageSize.height, titleSize.height);
	break;
	
      case NSImageBelow: 
      case NSImageAbove: 
	s.width = MAX(imageSize.width, titleSize.width);
	s.height = imageSize.height + titleSize.height + GSCellTextImageYDist;
	break;
	
      case NSImageOverlaps: 
	s.width = MAX(imageSize.width, titleSize.width);
	s.height = MAX(imageSize.height, titleSize.height);
	break;
    }
  
  // Get border size
  if (_cell.is_bordered)
    // Buttons only have three paths for border (NeXT looks)
    borderSize = NSMakeSize (3.0, 3.0);
  else
    borderSize = NSZeroSize;

  if ((_cell.is_bordered && (_cell.image_position != NSImageOnly))
      || _cell.is_bezeled)
    {
      borderSize.width += 6;
      borderSize.height += 6;
    }

  // Add border size
  s.width += borderSize.width;
  s.height += borderSize.height;

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
  [(NSView *)[event userData] setNeedsDisplay: YES];
}

- (void) mouseExited: (NSEvent *)event
{
  _mouse_inside = NO;
  [(NSView *)[event userData] setNeedsDisplay: YES];
}

/**
 * Simulates a single mouse click on the button cell. This method overrides the
 * cell method performClickWithFrame:inView: to add the possibility to play a sound
 * associated with the click. 
 */
- (void) performClickWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  if (_sound != nil)
    {
      [_sound play];
    }
    
  [super performClickWithFrame: cellFrame inView: controlView];
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
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      NSString *alternateContents = [aDecoder decodeObjectForKey: @"NSAlternateContents"];
      NSImage *alternateImage = [aDecoder decodeObjectForKey: @"NSAlternateImage"];
      //NSControl *control = [aDecoder decodeObjectForKey: @"NSControlView"];
      NSString *key = [aDecoder decodeObjectForKey: @"NSKeyEquivalent"];
      int bFlags;
      int bFlags2;
      int delay = 0;
      int interval = 0;
      
      [self setAlternateImage: alternateImage];
      [self setAlternateTitle: alternateContents];
      [self setKeyEquivalent: key];

      if ([aDecoder containsValueForKey: @"NSButtonFlags"])
        {
	  bFlags = [aDecoder decodeIntForKey: @"NSButtonFlags"];
	  // FIXME
	}
      if ([aDecoder containsValueForKey: @"NSButtonFlags2"])
        {
	  bFlags2 = [aDecoder decodeIntForKey: @"NSButtonFlags2"];
	  // FIXME
	}

      if ([aDecoder containsValueForKey: @"NSPeriodicDelay"])
        {
	  delay = [aDecoder decodeIntForKey: @"NSPeriodicDelay"];
	}
      if ([aDecoder containsValueForKey: @"NSPeriodicInterval"])
        {
	  interval = [aDecoder decodeIntForKey: @"NSPeriodicInterval"];
	}
      [self setPeriodicDelay: delay interval: interval];
    }
  else
    {
      // FIXME: Add new ivars
      BOOL tmp;
      
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
    }
  return self;
}

@end
