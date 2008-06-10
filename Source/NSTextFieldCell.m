/** <title>NSTextFieldCell</title>

   <abstract>Cell class for the text field entry control</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 1999
   
   This file is part of the GNUstep GUI Library.

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

#include "config.h"
#include <Foundation/NSNotification.h>
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSControl.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSTextField.h"
#include "AppKit/NSTextFieldCell.h"
#include "AppKit/NSText.h"

static NSColor *bgCol;
static NSColor *txtCol;

@interface NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n;
// Minor optimization -- cache isOpaque.
- (BOOL) _isOpaque;
@end

@implementation NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n
{
  ASSIGN(bgCol, [NSColor textBackgroundColor]);
  ASSIGN(txtCol, [NSColor textColor]); 
}

- (BOOL) _isOpaque
{
  if (_textfieldcell_draws_background == NO 
      || _background_color == nil 
      || [_background_color alphaComponent] < 1.0)
    return NO;
  else
    return YES;   
}
@end

@implementation NSTextFieldCell
+ (void) initialize
{
  if (self == [NSTextFieldCell class])
    {
      [self setVersion: 2];
      [[NSNotificationCenter defaultCenter] 
          addObserver: self
          selector: @selector(_systemColorsChanged:)
          name: NSSystemColorsDidChangeNotification
          object: nil];
      [self _systemColorsChanged: nil];
    }
}

//
// Initialization
//
- (id) initTextCell: (NSString *)aString
{
  self = [super initTextCell: aString];
  if (self == nil)
    return self;

  ASSIGN(_text_color, txtCol);
  ASSIGN(_background_color, bgCol);
//  _textfieldcell_draws_background = NO;
//  _textfieldcell_is_opaque = NO;
  _action_mask = NSKeyUpMask | NSKeyDownMask;
  return self;
}

- (void) dealloc
{
  RELEASE(_background_color);
  RELEASE(_text_color);
  RELEASE(_placeholder);
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSTextFieldCell *c = [super copyWithZone: zone];

  RETAIN(_background_color);
  RETAIN(_text_color);
  c->_placeholder = [_placeholder copyWithZone: zone];

  return c;
}

//
// Modifying Graphic Attributes 
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN (_background_color, aColor);
  _textfieldcell_is_opaque = [self _isOpaque];
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

/** <p>Returns the color used to draw the background</p>
    <p>See Also: -setBackgroundColor:</p>
 */
- (NSColor *) backgroundColor
{
  return _background_color;
}


/** <p>Sets whether the NSTextFieldCell draw its background color</p>
    <p>See Also: -drawsBackground</p>
 */
- (void) setDrawsBackground: (BOOL)flag
{
  _textfieldcell_draws_background = flag;
  _textfieldcell_is_opaque = [self _isOpaque];
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

/** <p>Returns whether the NSTextFieldCell draw its background color</p>
    <p>See Also: -setBackgroundColor:</p>
 */
- (BOOL) drawsBackground
{
  return _textfieldcell_draws_background;
}

/** <p>Sets the text color to aColor</p>
    <p>See Also: -textColor</p>
 */
- (void) setTextColor: (NSColor *)aColor
{
  ASSIGN (_text_color, aColor);
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

/** <p>Returns the text color</p>
    <p>See Also: -setTextColor:</p>
 */
- (NSColor *) textColor
{
  return _text_color;
}

- (void) setBezelStyle: (NSTextFieldBezelStyle)style
{
    _bezelStyle = style;
}

- (NSTextFieldBezelStyle) bezelStyle
{
  return _bezelStyle;
}

- (NSAttributedString*) placeholderAttributedString
{
  if (_textfieldcell_placeholder_is_attributed_string == YES)
    {
      return (NSAttributedString*)_placeholder;
    }
  else
    {
      return nil;
    }
}

- (NSString*) placeholderString
{
  if (_textfieldcell_placeholder_is_attributed_string == YES)
    {
      return nil;
    }
  else
    {
      return (NSString*)_placeholder;
    }
}

- (void) setPlaceholderAttributedString: (NSAttributedString*)string
{
  ASSIGN(_placeholder, string);
  _textfieldcell_placeholder_is_attributed_string = YES;
}

- (void) setPlaceholderString: (NSString*)string
{
  ASSIGN(_placeholder, string);
  _textfieldcell_placeholder_is_attributed_string = NO;
}

- (NSText *) setUpFieldEditorAttributes: (NSText *)textObject
{
  textObject = [super setUpFieldEditorAttributes: textObject];
  [textObject setDrawsBackground: _textfieldcell_draws_background];
  [textObject setBackgroundColor: _background_color];
  [textObject setTextColor: _text_color];
  return textObject;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (_textfieldcell_draws_background)
	  {
      if ([self isEnabled])
	      {
          [_background_color set];
        }
      else
	      {
          [[NSColor controlBackgroundColor] set];
        }
      NSRectFill([self drawingRectForBounds: cellFrame]);
    }
      
  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

/* 
   Attributed string that will be displayed.
 */
- (NSAttributedString*)_drawAttributedString
{
  NSAttributedString *attrStr;

  attrStr = [super _drawAttributedString];
  if (attrStr == nil)
    {
      attrStr = [self placeholderAttributedString];
      if (attrStr == nil)
        {
          NSString *string;
          NSDictionary *attributes;
          NSMutableDictionary *newAttribs;
      
          string = [self placeholderString];
          if (string == nil)
            {
              return nil;
            }

          attributes = [self _nonAutoreleasedTypingAttributes];
          newAttribs = [NSMutableDictionary 
                           dictionaryWithDictionary: attributes];
          [newAttribs setObject: [NSColor disabledControlTextColor]
                      forKey: NSForegroundColorAttributeName];
          
          return AUTORELEASE([[NSAttributedString alloc]
                                 initWithString: string
                                 attributes: newAttribs]);
        }
      else
        {
          return attrStr;
        }
    }
  else
    {
      return attrStr;
    }
}

- (BOOL) isOpaque
{
  return _textfieldcell_is_opaque;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;
  [super encodeWithCoder: aCoder];

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: [self backgroundColor] forKey: @"NSBackgroundColor"];
      [aCoder encodeObject: [self textColor] forKey: @"NSTextColor"];
      [aCoder encodeBool: [self drawsBackground] forKey: @"NSDrawsBackground"];
    }
  else
    {
      [aCoder encodeValueOfObjCType: @encode(id) at: &_background_color];
      [aCoder encodeValueOfObjCType: @encode(id) at: &_text_color];
      tmp = _textfieldcell_draws_background;
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
 
  if ([aDecoder allowsKeyedCoding])
    {
      id textColor = RETAIN([aDecoder decodeObjectForKey: @"NSTextColor"]);
      id backColor = RETAIN([aDecoder decodeObjectForKey: @"NSBackgroundColor"]);

      [self setBackgroundColor: backColor];
      [self setTextColor: textColor];
      if ([aDecoder containsValueForKey: @"NSDrawsBackground"])
        {
          [self setDrawsBackground: [aDecoder decodeBoolForKey: 
                                                  @"NSDrawsBackground"]];
        }
    }
  else
    {
      BOOL tmp;

      if ([aDecoder versionForClassName:@"NSTextFieldCell"] < 2)
        {
          /* Replace the old default _action_mask with the new default one
             if it's set. There isn't really a way to modify this value
             on an NSTextFieldCell encoded in a .gorm file. The old default value
             causes problems with newer NSTableViews which uses this to discern 
             whether it should trackMouse:inRect:ofView:untilMouseUp: or not.
             This also disables the action from being sent on an uneditable and
             unselectable text fields.
          */
          if (_action_mask == NSLeftMouseUpMask)
            {
              _action_mask = NSKeyUpMask | NSKeyDownMask;
            }
        }

      [aDecoder decodeValueOfObjCType: @encode(id) at: &_background_color];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_text_color];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
      _textfieldcell_draws_background = tmp;
      _textfieldcell_is_opaque = [self _isOpaque];
    }

  return self;
}

@end
