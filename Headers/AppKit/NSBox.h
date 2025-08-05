/*
   NSBox.h

   Simple box view that can display a border and title

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

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

#ifndef _GNUstep_H_NSBox
#define _GNUstep_H_NSBox
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSView.h>

@class NSString;
@class NSColor;
@class NSFont;

/** Title positioning of an NSBox:
 * <list>
 *  <item>NSNoTitle</item>
 *  <item>NSAboveTop</item>
 *  <item>NSAtTop</item>
 *  <item>NSBelowTop</item>
 *  <item>NSAboveBottom</item>
 *  <item>NSAtBottom</item>
 *  <item>NSBelowBottom</item>
 * </list>
 */
typedef enum _NSTitlePosition {
  NSNoTitle,
  NSAboveTop,
  NSAtTop,
  NSBelowTop,
  NSAboveBottom,
  NSAtBottom,
  NSBelowBottom
} NSTitlePosition;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
typedef enum _NSBoxType
{
  NSBoxPrimary=0,
  NSBoxSecondary,
  NSBoxSeparator,
  NSBoxOldStyle
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
  , NSBoxCustom
#endif
} NSBoxType;
#endif

/**
 *  Class: NSBox
 *  Description: NSBox is a container view capable of drawing a border and title
 *               around its content. It is often used to group related interface
 *               elements visually and semantically.
 *
 *  Instance Variables:
 *    _cell            - The underlying cell used for drawing.
 *    _content_view    - The view contained inside the box.
 *    _offsets         - Margins between the border and the content.
 *    _border_rect     - Rectangle defining the area of the border.
 *    _title_rect      - Rectangle defining the area of the title.
 *    _border_type     - Type of border drawn (line, bezel, etc).
 *    _title_position  - Position of the title relative to the border.
 *    _box_type        - General appearance of the box.
 *    _fill_color      - Fill color (only if NSBoxCustom).
 *    _border_color    - Border color (only if NSBoxCustom).
 *    _border_width    - Width of the border (only if NSBoxCustom).
 *    _corner_radius   - Corner radius for rounded borders (only if NSBoxCustom).
 *    _transparent     - Determines whether the box is drawn transparently.
 */

APPKIT_EXPORT_CLASS
@interface NSBox : NSView <NSCoding>
{
  // Attributes
  id _cell;
  id _content_view;
  NSSize _offsets;
  NSRect _border_rect;
  NSRect _title_rect;
  NSBorderType _border_type;
  NSTitlePosition _title_position;
  NSBoxType _box_type;
  // Only used when the type is NSBoxCustom
  NSColor *_fill_color;
  NSColor *_border_color;
  CGFloat _border_width;
  CGFloat _corner_radius;
  BOOL _transparent;
}

//
// Getting and Modifying the Border and Title
//

/**
 *  Returns the rectangle used to draw the box's border.
 */
- (NSRect)borderRect;

/**
 *  Returns the border type of the box.
 */
- (NSBorderType)borderType;

/**
 *  Sets the border type of the box.
 */
- (void)setBorderType:(NSBorderType)aType;

/**
 *  Sets the title string displayed by the box.
 */
- (void)setTitle:(NSString *)aString;

/**
 *  Sets the font used to display the title.
 */
- (void)setTitleFont:(NSFont *)fontObj;

/**
 *  Sets the title position relative to the box.
 */
- (void)setTitlePosition:(NSTitlePosition)aPosition;

/**
 *  Returns the current title string.
 */
- (NSString *)title;

/**
 *  Returns the cell used to draw the title.
 */
- (id)titleCell;

/**
 *  Returns the font used for the title.
 */
- (NSFont *)titleFont;

/**
 *  Returns the title's position relative to the box.
 */
- (NSTitlePosition)titlePosition;

/**
 *  Returns the rectangle used to draw the title.
 */
- (NSRect)titleRect;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 *  Sets the title string and enables keyboard shortcut via mnemonic.
 */
- (void)setTitleWithMnemonic:(NSString *)aString;

/**
 *  Returns the type of box used.
 */
- (NSBoxType)boxType;

/**
 *  Sets the box's display type.
 */
- (void)setBoxType:(NSBoxType)aType;
#endif

//
// Setting and Placing the Content View
//

/**
 *  Returns the view contained within the box.
 */
- (id)contentView;

/**
 *  Returns the margins applied to the content view.
 */
- (NSSize)contentViewMargins;

/**
 *  Sets the content view of the box.
 */
- (void)setContentView:(NSView *)aView;

/**
 *  Sets the margins around the content view.
 */
- (void)setContentViewMargins:(NSSize)offsetSize;

//
// Resizing the Box
//

/**
 *  Adjusts the box frame to fit a given content frame.
 */
- (void)setFrameFromContentFrame:(NSRect)contentFrame;

/**
 *  Resizes the box to tightly fit its content.
 */
- (void)sizeToFit;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * Returns the minimum size of the box.
 */
-(NSSize) minimumSize;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 *  Returns the fill color when using NSBoxCustom.
 */
- (NSColor*)fillColor;

/**
 *  Sets the fill color when using NSBoxCustom.
 */
- (void)setFillColor:(NSColor*)newFillColor;

/**
 *  Returns the border color when using NSBoxCustom.
 */
- (NSColor*)borderColor;

/**
 *  Sets the border color when using NSBoxCustom.
 */
- (void)setBorderColor:(NSColor*)newBorderColor;

/**
 *  Returns the width of the border when using NSBoxCustom.
 */
- (CGFloat)borderWidth;

/**
 *  Sets the width of the border when using NSBoxCustom.
 */
- (void)setBorderWidth:(CGFloat)borderWidth;

/**
 *  Returns the corner radius when using NSBoxCustom.
 */
- (CGFloat)cornerRadius;

/**
 *  Sets the corner radius when using NSBoxCustom.
 */
- (void)setCornerRadius:(CGFloat)cornerRadius;

/**
 *  Returns whether the box is transparent.
 */
- (BOOL)isTransparent;

/**
 *  Sets whether the box should be transparent.
 */
- (void)setTransparent:(BOOL)transparent;
#endif
@end

#endif // _GNUstep_H_NSBox
