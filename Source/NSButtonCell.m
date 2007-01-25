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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
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
#include "GNUstepGUI/GSTheme.h"
#include "GNUstepGUI/GSNibCompatibility.h"

#include <math.h>

typedef struct _GSButtonCellFlags 
{
#ifdef WORDS_BIGENDIAN
  unsigned int isPushin:1;
  unsigned int changeContents:1;
  unsigned int changeBackground:1;
  unsigned int changeGray:1;
  unsigned int highlightByContents:1;
  unsigned int highlightByBackground:1;
  unsigned int highlightByGray:1;
  unsigned int drawing:1;
  unsigned int isBordered:1;
  unsigned int imageDoesOverlap:1;
  unsigned int isHorizontal:1;
  unsigned int isBottomOrLeft:1;
  unsigned int isImageAndText:1;
  unsigned int isImageSizeDiff:1;
  unsigned int hasKeyEquiv:1;
  unsigned int lastState:1;
  unsigned int isTransparent:1;
  unsigned int unused1:6; // inset:2 doesn't dim:1 gradient:3
  unsigned int useButtonImageSource:1;
  unsigned int unused2:8; // alt mnemonic loc.
#else
  unsigned int unused2:8; // alt mnemonic loc.
  unsigned int useButtonImageSource:1;
  unsigned int unused1:6; // inset:2 doesn't dim:1 gradient:3
  unsigned int isTransparent:1;
  unsigned int lastState:1;
  unsigned int hasKeyEquiv:1;
  unsigned int isImageSizeDiff:1;
  unsigned int isImageAndText:1;
  unsigned int isBottomOrLeft:1;
  unsigned int isHorizontal:1;
  unsigned int imageDoesOverlap:1;
  unsigned int isBordered:1;
  unsigned int drawing:1;
  unsigned int highlightByGray:1;
  unsigned int highlightByBackground:1;
  unsigned int highlightByContents:1;
  unsigned int changeGray:1;
  unsigned int changeBackground:1;
  unsigned int changeContents:1;
  unsigned int isPushin:1;
#endif
} GSButtonCellFlags;

/**<p> TODO Description</p>
 */
@implementation NSButtonCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSButtonCell class])
    [self setVersion: 2];
}

/*
 * Instance methods
 */
- (id) _init
{
  // Implicitly performed by allocation:
  //
  //_buttoncell_is_transparent = NO;

  [self setAlignment: NSCenterTextAlignment];
  _cell.is_bordered = YES;
  [self setButtonType: NSMomentaryPushInButton];
  _delayInterval = 0.4;
  _repeatInterval = 0.075;
  _keyEquivalentModifierMask = NSCommandKeyMask;
  _keyEquivalent = @"";
  _altContents = @"";
  _gradient_type = NSGradientNone;

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
  RELEASE(_backgroundColor);

  [super dealloc];
}

/** 
 *<p>The GNUstep implementation does nothing here
 *  (to match the Mac OS X behavior) because with
 * NSButtonCell GNUstep implementation the cell type is bound to the image
 * position. We implemented this behavior because it permits to have
 * -setFont: -setTitle -setImage: methods which are symetrical by not altering
 * directly the cell type and to validate the fact that the cell type is more
 * characterized by the potential visibility of the image (which is under the
 * control of the method -setImagePosition:) than by the value of the image
 * ivar itself (related to -setImage: method).  
 * On Mac OS X, the NSButtonCell cell type is NSTextCellType by default or
 * NSImageCellType if the initialization has been done with -initImageCell:,
 * it should be noted that the cell type never changes later.</p>
 */
- (void) setType: (NSCellType)aType
{
}

/** <p>Returns the NSButtonCell's title.</p>
    <p>See Also: -setTitle: [NSCell-stringValue]</p>
 */
- (NSString*) title
{
  return [self stringValue];
}

/** <p>Returns the NSButtonCell's alternate title ( used when highlighted ).
    </p><p>See Also: -setAlternateTitle:</p>
 */
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

/** <p>Sets the NSButtonCell's font to <var>fontObject</var>.
    The key equivalent font size is changed to match the <var>fontObject</var>
    if needed.</p><p>See Also: [NSCell-font] -keyEquivalentFont 
    -setKeyEquivalentFont: -setKeyEquivalentFont:size:</p>
 */
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

/**<p>Sets the NSButtonCell's title to <var>aString</var>.</p>
   <p>See Also: -title [NSCell-setStringValue:]</p>
 */
- (void) setTitle: (NSString*)aString
{
  [self setStringValue: aString];
}

/**<p>Sets the NSButtonCell's alternate title ( used when highlighted ) 
   to <var>aString</var> and update the cell if it contains 
   a NSControl view.</p><p>See Also: -alternateTitle</p>
 */
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

/**<p>Returns the NSButtonCell's alternate image.</p>
   <p>See Also: -setAlternateImage:</p> 
 */
- (NSImage*) alternateImage
{
  return _altImage;
}

/** <p>Returns the NSButtonCell's image position. See <ref type="type" 
    id="NSCellImagePosition">NSCellImagePosition</ref> for more information.
    </p><p>See Also: -setImagePosition:</p>
 */
- (NSCellImagePosition) imagePosition
{
  return _cell.image_position;
}

- (void) setImage: (NSImage *)anImage
{
  if (anImage) 
    {
      NSAssert ([anImage isKindOfClass: [NSImage class]],
		NSInvalidArgumentException);
    }
  
  if (_cell.image_position == NSNoImage)
    {
      [self setImagePosition: NSImageOnly];
    }
  
  ASSIGN (_cell_image, anImage);
}

/**<p>Sets the NSButtonCell's alternate image to <var>anImage</var>.</p>
   <p>See Also: -alternateImage</p>
 */
- (void) setAlternateImage: (NSImage*)anImage
{
  ASSIGN(_altImage, anImage);
}

/**<p>Sets the image position. The GNUstep implementation depends only on 
   the image position. If the image position is set to <ref type="type"
   id="NSCellImagePosition">NSNoImage</ref> then the type is set to
   <ref type="type" id="NSCellImagePosition">NSTextCellType</ref>, to
   <ref type="type" id="NSCellImagePosition">NSImageCellType</ref> otherwise
   </p><p>See Also: -imagePosition</p>
*/
- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  _cell.image_position = aPosition;
   
  // In the GNUstep NSButtonCell implementation, the cell type depends only on
  // the image position. 
    
  if (_cell.image_position == NSNoImage)
    {
      /* NOTE: If we always call -setType: on superclass, the cell _content will
         be reset each time. When we alter a button displaying both an image and
         a title, by just calling -setImagePosition: with 'NSNoImage' value,
         the current title is reset to NSCell default one. That's why we have to
         set cell type ourself when a custom title (or attributed title) is
         already in use. 
         Take note that [self title] is able to return the attributed title in
         NSString form.
         We precisely match Mac OS X behavior currently. That means... When you
         switch from 'NSNoImage' option to another one, the title will be the
         one in use before you switched to 'NSNoImage'. The reverse with the
         image isn't true, when you switch to 'NSNoImage' option, the current
         image is lost (image value being reset to nil).
      */
      if ([self title] == nil || [[self title] isEqualToString: @""])
        {
          [super setType: NSTextCellType];
        }
      else
        { 
          _cell.type = NSTextCellType;
        }
    }
  else
    {
      [super setType: NSImageCellType];
    }
}

/**<p>Gets the NSButtonCell's <var>delay</var> and the <var>interval</var>
   parameters used when NSButton sends continouly action messages.
   By default <var>delay</var> is 0.4 and <var>interval</var> is 0.075.</p>
   <p>See Also: -setPeriodicDelay:interval:
   [NSCell-trackMouse:inRect:ofView:untilMouseUp:]</p>
 */
- (void) getPeriodicDelay: (float*)delay interval: (float*)interval
{
  *delay = _delayInterval;
  *interval = _repeatInterval;
}

/** <p>Sets the NSButtonCell's  <var>delay</var> and <var>interval</var> 
    parameters used when NSButton sends continouly action messages.
    By default <var>delay</var> is 0.4 and <var>interval</var> is 0.075.</p>
    <p>See Also: -getPeriodicDelay:interval: 
    [NSCell-trackMouse:inRect:ofView:untilMouseUp:]</p>
 */
- (void) setPeriodicDelay: (float)delay interval: (float)interval
{
  _delayInterval = delay;
  _repeatInterval = interval;
}

/**<p>Returns the NSButtonCell's key equivalent. The key equivalent and its
   modifier mask are used to simulate the click of the button in
   [NSButton-performKeyEquivalent:]. Returns an empty string if no key
   equivalent is defined. By default NSButtonCell hasn't key equivalent.</p>
   <p>See Also: -setKeyEquivalent: [NSButton-performKeyEquivalent:]
   -keyEquivalentModifierMask [NSButtonCell-keyEquivalent]</p>
 */
- (NSString*) keyEquivalent
{
  return _keyEquivalent;
}

/**<p>Returns the NSFont of the key equivalent.</p>
 *<p>See Also: -setKeyEquivalentFont:</p>
 */
- (NSFont*) keyEquivalentFont
{
  return _keyEquivalentFont;
}

/** <p>Returns the modifier mask of the NSButtonCell's key equivalent. 
    The key equivalent and its modifier mask are used to simulate the click
    of the button in  [NSButton-performKeyEquivalent:]. The default mask is 
    NSCommandKeyMask.</p><p>See Also: -setKeyEquivalentModifierMask:
    -keyEquivalent [NSButton-performKeyEquivalent:]</p>
 */
- (unsigned int) keyEquivalentModifierMask
{
  return _keyEquivalentModifierMask;
}

/** <p>Sets the NSButtonCell's key equivalent to <var>key</var>. The key
    equivalent and its modifier mask are used to simulate the click
    of the button in  [NSButton-performKeyEquivalent:]. By default NSButton
    hasn't   key equivalent.</p><p>See Also: -keyEquivalent 
    -setKeyEquivalentModifierMask: [NSButton-performKeyEquivalent:]</p>
*/
- (void) setKeyEquivalent: (NSString*)key
{
  ASSIGNCOPY(_keyEquivalent, key);
}

/** <p>Sets the modifier mask of the NSButtonCell's key equivalent to
    <var>mask</var>. The key equivalent and its modifier mask are used to
    simulate the click of the button in [NSButton-performKeyEquivalent:]. 
    By default the mask is NSCommandKeyMask.</p>
    <p>See Also: -keyEquivalentModifierMask  
    -setKeyEquivalent: [NSButton-performKeyEquivalent:]</p>
*/
- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  _keyEquivalentModifierMask = mask;
}

/**<p>Sets the NSFont of the key equivalent to <var>fontObject</var>.</p>
 *<p>See Also: -keyEquivalentFont -setFont:</p>
 */
- (void) setKeyEquivalentFont: (NSFont*)fontObj
{
  ASSIGN(_keyEquivalentFont, fontObj);
}

/**<p>Sets the NSFont with size <var>fontSize</var> of the key equivalent 
   to <var>fontName</var>.</p>
   <p>See Also: -keyEquivalentFont -setKeyEquivalentFont: -setFont:</p>
 */
- (void) setKeyEquivalentFont: (NSString*)fontName size: (float)fontSize
{
  ASSIGN(_keyEquivalentFont, [NSFont fontWithName: fontName size: fontSize]);
}

/**<p>Returns whether the button cell is transparent.</p>
   <p>See Also: -setTransparent:</p>
 */
- (BOOL) isTransparent
{
  return _buttoncell_is_transparent;
}

/**<p>Sets whether the button cell is transparent.</p>
   <p>See Also: -isTransparent </p>
 */
- (void) setTransparent: (BOOL)flag
{
  _buttoncell_is_transparent = flag;
}

/**<p>Returns whether the NSButtonCell is opaque. Returns YES if the button 
   cell is not transparent and if the cell is bordered. NO otherwise</p>
 */
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

/**<p>Returns a mask describing how the button cell is highlighted : </p>
   <p> NSNoCellMask, NSContentsCellMask,NSPushInCellMask,NSChangeGrayCellMask,
   NSChangeBackgroundCellMask</p>
   <p>See Also : -setHighlightsBy:</p>
 */
- (int) highlightsBy
{
  return _highlightsByMask;
}

/**<p>Sets a mask describing how the button cell is highlighted :  </p>
   <p> NSNoCellMask, NSContentsCellMask,NSPushInCellMask,NSChangeGrayCellMask,
   NSChangeBackgroundCellMask</p>
   <p>See Also : -highlightsBy</p>
 */
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
      case NSMomentaryPushInButton: 
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

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(_backgroundColor, color);
}

- (void) drawBezelWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  unsigned		mask;
  GSThemeControlState	buttonState = GSThemeNormalState;

  // set the mask
  if (_cell.is_highlighted)
    {
      mask = _highlightsByMask;
      if (_cell.state)
        {
	  mask &= ~_showAltStateMask;
	}
    }
  else if (_cell.state)
    mask = _showAltStateMask;
  else
    mask = NSNoCellMask;

  /* Determine the background color. 
     We draw when there is a border or when highlightsByMask
     is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
     as required by our nextstep-like look and feel.  */
  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      buttonState = GSThemeHighlightedState;
    }

  /* Pushed in buttons contents are displaced to the bottom right 1px.  */
  if (mask & NSPushInCellMask)
    {
      buttonState = GSThemeSelectedState;
    }

  [[GSTheme theme] drawButton: cellFrame 
		   in: self 
		   view: controlView
		   style: _bezel_style
		   state: buttonState];
}

- (void) drawImage: (NSImage*)anImage 
	 withFrame: (NSRect)aRect 
	    inView: (NSView*)controlView
{
  // Draw image
  if (anImage != nil)
    {
      NSSize size;
      NSPoint position;
      
      size = [anImage size];
      position.x = MAX(NSMidX(aRect) - (size.width / 2.), 0.);
      position.y = MAX(NSMidY(aRect) - (size.height / 2.), 0.);
      
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
        {
	  position.y += size.height;
	}
      
      if (_cell.is_disabled && _image_dims_when_disabled)
        {
	  [anImage dissolveToPoint: position fraction: 0.5];
	}
      else
        {
	  [anImage compositeToPoint: position 
		          operation: NSCompositeSourceOver];
	}
    }
}

- (void) drawTitle: (NSAttributedString*)titleToDisplay 
	 withFrame: (NSRect)frame 
	    inView: (NSView*)control
{
  [self _drawAttributedText: titleToDisplay
	inFrame: frame];
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
  if ((_cell.is_bordered)
    && (!_shows_border_only_while_mouse_inside || _mouse_inside))
    {
	[self drawBezelWithFrame: cellFrame inView: controlView];
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];

  // Draw first responder
  if (_cell.shows_first_responder
    && [[controlView window] firstResponder] == controlView)
    {
      // FIXME: Should depend on _cell.focus_ring_type
      [[GSTheme theme] drawFocusFrame: [self drawingRectForBounds: cellFrame] 
		                 view: controlView];
    }
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
      default:
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	 imageRect = NSZeroRect;
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageOnly: 
	titleToDisplay = nil;
	imageRect = cellFrame;
	titleRect = NSZeroRect;
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
	titleRect.size.width = imageRect.origin.x - titleRect.origin.x
			       - GSCellTextImageXDist;
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
	titleRect.origin = cellFrame.origin;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    titleRect.origin.y += 3;
	  }

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = NSMaxY(titleRect) + GSCellTextImageYDist;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = NSMaxY(cellFrame) - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.size.height -= 3;
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
	if (_cell.is_bordered || _cell.is_bezeled)
	  {
	    titleRect.origin.y -= 3;
	  }

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height
	  = titleRect.origin.y - GSCellTextImageYDist - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.y += 3;
	    imageRect.size.height -= 3;
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
	// FIXME: I think this method is wrong.
      [self drawGradientWithFrame: cellFrame inView: controlView];
    }

  // Draw image
  if (imageToDisplay != nil)
    {
      [self drawImage: imageToDisplay
	    withFrame: imageRect
	       inView: controlView];
    }

  // Draw title
  if (titleToDisplay != nil)
    {
      [self drawTitle: titleToDisplay withFrame: titleRect inView: controlView];
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
      default:
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
    {
      GSThemeControlState	buttonState = GSThemeNormalState;

      /* Determine the background color. 
	 We draw when there is a border or when highlightsByMask
	 is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
	 as required by our nextstep-like look and feel.  */
      if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
        {
	  buttonState = GSThemeHighlightedState;
	}
      
      /* Pushed in buttons contents are displaced to the bottom right 1px.  */
      if (mask & NSPushInCellMask)
        {
	  buttonState = GSThemeSelectedState;
	}

      borderSize = [[GSTheme theme] buttonBorderForStyle: _bezel_style 
				                   state: buttonState];
    }
  else
    borderSize = NSZeroSize;

  // Add border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;

  return s;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  if (_cell.is_bordered)
    {
      NSSize borderSize;
      unsigned	mask;
      GSThemeControlState buttonState = GSThemeNormalState;
      NSRect interiorFrame;

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
  
      /* Determine the background color. 
	 We draw when there is a border or when highlightsByMask
	 is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
	 as required by our nextstep-like look and feel.  */
      if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
        {
	  buttonState = GSThemeHighlightedState;
	}
      
      if (mask & NSPushInCellMask)
        {
	  buttonState = GSThemeSelectedState;
	}

      borderSize = [[GSTheme theme] buttonBorderForStyle: _bezel_style 
				                   state: buttonState];
      interiorFrame = NSInsetRect(theRect, borderSize.width, borderSize.height);

      /* Pushed in buttons contents are displaced to the bottom right 1px.  */
      if (mask & NSPushInCellMask)
	{
	  interiorFrame
	    = NSOffsetRect(interiorFrame, 1.0, [_control_view isFlipped] ? 1.0 : -1.0);
	}
      return interiorFrame;
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

/**Simulates a single mouse click on the button cell. This method overrides the
  cell method performClickWithFrame:inView: to add the possibility to
  play a sound associated with the click. 
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
  
  c->_altContents = [_altContents copyWithZone: zone];
  TEST_RETAIN(_altImage);
  TEST_RETAIN(_keyEquivalent);
  TEST_RETAIN(_keyEquivalentFont);
  TEST_RETAIN(_sound);
  TEST_RETAIN(_backgroundColor);

  return c;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;

  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      GSButtonCellFlags buttonCellFlags;
      unsigned int bFlags = 0;
      unsigned int bFlags2 = 0;
      NSImage *image = [self image];
      NSButtonImageSource *bi = nil;

      if ([self keyEquivalent] != nil)
	{
	  [aCoder encodeObject: [self keyEquivalent] forKey: @"NSKeyEquivalent"];
	}
      if ([self image] != nil)
	{
	  [aCoder encodeObject: [self image] forKey: @"NSNormalImage"];
	}
      if ([self alternateTitle] != nil)
	{
	  [aCoder encodeObject: [self alternateTitle] forKey: @"NSAlternateContents"];
	}

      buttonCellFlags.useButtonImageSource = (([NSImage imageNamed: @"NSSwitch"] == image) ||
					      ([NSImage imageNamed: @"NSRadioButton"] == image));
      buttonCellFlags.isTransparent = [self isTransparent];
      buttonCellFlags.isBordered = [self isBordered]; 
      buttonCellFlags.isImageAndText = (image != nil);
      buttonCellFlags.hasKeyEquiv = ([self keyEquivalent] != nil);

      // cell attributes...
      buttonCellFlags.isPushin = [self cellAttribute: NSPushInCell]; 
      buttonCellFlags.highlightByBackground = [self cellAttribute: NSCellLightsByBackground];
      buttonCellFlags.highlightByContents = [self cellAttribute: NSCellLightsByContents];
      buttonCellFlags.highlightByGray = [self cellAttribute: NSCellLightsByGray];
      buttonCellFlags.changeBackground = [self cellAttribute: NSChangeBackgroundCell];
      buttonCellFlags.changeContents = [self cellAttribute: NSCellChangesContents];
      buttonCellFlags.changeGray = [self cellAttribute: NSChangeGrayCell];

      // set these to zero...
      buttonCellFlags.unused1 = 0; // 32;
      buttonCellFlags.unused2 = 0; // 255;
      buttonCellFlags.lastState = 0;
      buttonCellFlags.isImageSizeDiff = 0;
      buttonCellFlags.imageDoesOverlap = 0;
      buttonCellFlags.drawing = 0;
      buttonCellFlags.isBottomOrLeft = 0;

      memcpy((void *)&bFlags, (void *)&buttonCellFlags,sizeof(unsigned int));
      [aCoder encodeInt: bFlags forKey: @"NSButtonFlags"];

      // style and border.
      bFlags2 != [self showsBorderOnlyWhileMouseInside] ? 0x8 : 0;
      bFlags2 |= (([self bezelStyle] & 0x7) | (([self bezelStyle] & 0x18) << 2));
      [aCoder encodeInt: bFlags2 forKey: @"NSButtonFlags2"];

      // alternate image encoding...
      if (image != nil)
	{
	  if ([image isKindOfClass: [NSImage class]] && buttonCellFlags.useButtonImageSource)
	    {
	      if ([NSImage imageNamed: @"NSSwitch"] == image)
		{
		  bi = [[NSButtonImageSource alloc] initWithImageNamed: @"NSHighlightedSwitch"];
		}
	      else if ([NSImage imageNamed: @"NSRadioButton"] == image)
		{
		  bi = [[NSButtonImageSource alloc] initWithImageNamed: @"NSHighlightedRadioButton"];
		}
	    }
	}

      // encode button image source, if it exists...
      if (bi != nil)
	{
	  [aCoder encodeObject: bi forKey: @"NSAlternateImage"];      
	}
      else if (_altImage != nil)
	{
	  [aCoder encodeObject: _altImage forKey: @"NSAlternateImage"];
	}

      // repeat and delay
      [aCoder encodeInt: (int)_delayInterval forKey: @"NSPeriodicDelay"];
      [aCoder encodeInt: (int)_repeatInterval forKey: @"NSPeriodicInterval"];
    }
  else
    {
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

      [aCoder encodeObject: _sound];
      [aCoder encodeObject: _backgroundColor];
      [aCoder encodeValueOfObjCType: @encode(float)
	      at: &_delayInterval];
      [aCoder encodeValueOfObjCType: @encode(float)
	      at: &_repeatInterval];
      [aCoder encodeValueOfObjCType: @encode(unsigned int)
	      at: &_bezel_style];
      [aCoder encodeValueOfObjCType: @encode(unsigned int)
	      at: &_gradient_type];
      tmp = _image_dims_when_disabled;
      [aCoder encodeValueOfObjCType: @encode(BOOL)
	      at: &tmp];
      tmp = _shows_border_only_while_mouse_inside;
      [aCoder encodeValueOfObjCType: @encode(BOOL)
	      at: &tmp];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      int delay = 0;
      int interval = 0;      
      // NSControl *control = [aDecoder decodeObjectForKey: @"NSControlView"];

      if ([aDecoder containsValueForKey: @"NSKeyEquivalent"])
        {
	  [self setKeyEquivalent: [aDecoder decodeObjectForKey: @"NSKeyEquivalent"]];
	}
      if ([aDecoder containsValueForKey: @"NSNormalImage"])
        {
	  [self setImage: [aDecoder decodeObjectForKey: @"NSNormalImage"]];
	}
      if ([aDecoder containsValueForKey: @"NSAlternateContents"])
        {
	  [self setAlternateTitle: [aDecoder decodeObjectForKey: @"NSAlternateContents"]];
	}
      if ([aDecoder containsValueForKey: @"NSButtonFlags"])
        {
	  unsigned int bFlags = [aDecoder decodeIntForKey: @"NSButtonFlags"];
	  GSButtonCellFlags buttonCellFlags;
	  memcpy((void *)&buttonCellFlags,(void *)&bFlags,sizeof(struct _GSButtonCellFlags));

	  [self setTransparent: buttonCellFlags.isTransparent];
	  [self setBordered: buttonCellFlags.isBordered];
	  
	  [self setCellAttribute: NSPushInCell
		to: buttonCellFlags.isPushin];
	  [self setCellAttribute: NSCellLightsByBackground 
		to: buttonCellFlags.highlightByBackground];
	  [self setCellAttribute: NSCellLightsByContents   
		to: buttonCellFlags.highlightByContents];
	  [self setCellAttribute: NSCellLightsByGray
		to: buttonCellFlags.highlightByGray]; 
	  [self setCellAttribute: NSChangeBackgroundCell   
		to: buttonCellFlags.changeBackground];
	  [self setCellAttribute: NSCellChangesContents    
		to: buttonCellFlags.changeContents];
	  [self setCellAttribute: NSChangeGrayCell
		to: buttonCellFlags.changeGray]; 
	  
	  [self setImagePosition: NSImageLeft];
	}
      if ([aDecoder containsValueForKey: @"NSButtonFlags2"])
        {
	  int bFlags2;

	  bFlags2 = [aDecoder decodeIntForKey: @"NSButtonFlags2"];
	  [self setShowsBorderOnlyWhileMouseInside: (bFlags2 & 0x8)];
	  [self setBezelStyle: (bFlags2 & 0x7) | ((bFlags2 & 0x20) >> 2)];
	}
      if ([aDecoder containsValueForKey: @"NSAlternateImage"])
        {
	  id image;

	  //
	  // NOTE: Okay... this is a humongous kludge.   It seems as though
	  // Cocoa is doing something very odd here.  It doesn't seem to 
	  // encode system images for buttons normally, if it is using 
	  // images at all. Until I figure out what, this will stay.  
	  // Danger, Will Robinson! :)
	  //
	  image = [aDecoder decodeObjectForKey: @"NSAlternateImage"];
	  if ([image isKindOfClass: [NSImage class]])
	    {
	      if ([NSImage imageNamed: @"NSSwitch"] == image)
		{
		  image = [NSImage imageNamed: @"NSHighlightedSwitch"];
		  if ([self image] == nil)
		    {
		      [self setImage: [NSImage imageNamed: @"NSSwitch"]];
		    }		    
		}
	      else if ([NSImage imageNamed: @"NSRadioButton"] == image)
		{
		  image = [NSImage imageNamed: @"NSHighlightedRadioButton"];
		  if ([self image] == nil)
		    {
		      [self setImage: [NSImage imageNamed: @"NSRadioButton"]];
		    }		    
		}
	      
	      [self setAlternateImage: image];
	    }
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

      if ([aDecoder versionForClassName: @"NSButtonCell"] >= 2)
      {
	  [aDecoder decodeValueOfObjCType: @encode(id) at: &_sound];
	  [aDecoder decodeValueOfObjCType: @encode(id) at: &_backgroundColor];
	  [aDecoder decodeValueOfObjCType: @encode(float) at: &_delayInterval];
	  [aDecoder decodeValueOfObjCType: @encode(float) at: &_repeatInterval];
	  [aDecoder decodeValueOfObjCType: @encode(unsigned int)
		                       at: &_bezel_style];
	  [aDecoder decodeValueOfObjCType: @encode(unsigned int)
		                       at: &_gradient_type];
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
	  _image_dims_when_disabled = tmp;
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
	  _shows_border_only_while_mouse_inside = tmp;
      }
    }
  return self;
}

@end
