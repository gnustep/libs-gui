/* 
   NSToolbarItem.m

   The Toolbar item class.
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>,
	    Quentin Mathe <qmathe@club-internet.fr>
   Date: May 2002
   
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

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSParagraphStyle.h"
#include "GNUstepGUI/GSToolbar.h"
#include "GNUstepGUI/GSToolbarView.h"

/*
 * Each NSToolbarItem object are coupled with a backView which is their representation 
 * on the screen.
 * backView for the standard toolbar item (without custom view) are NSButton subclass
 * called GSToolbarButton.
 * backView for the toolbar item with a custom view are NSView subclass called
 * GSToolbarBackView.
 * GSToolbarButton and GSToolbarBackView are adjusted according to their content and
 * their title when the method layout is called.
 * The predefined GNUstep toolbar items are implemented with a class cluster pattern :
 * initWithToolbarItemIdentifier: returns differents concrete subclass in accordance
 * with the item identifier.
 */
 
typedef enum {
  ItemBackViewDefaultHeight = 60,
  ItemBackViewRegularHeight = 60,
  ItemBackViewSmallHeight = 50
} ItemBackViewHeight;

typedef enum {
  ItemBackViewDefaultWidth = 60,
  ItemBackViewRegularWidth = 60,
  ItemBackViewSmallWidth = 50
} ItemBackViewWidth;

static const int ItemBackViewX = 0;
static const int ItemBackViewY = 0;
static const int InsetItemViewX = 10;
static const int InsetItemViewY = 26;
static const int InsetItemTextX = 3;
static const int InsetItemTextY = 4;
 
static NSFont *NormalFont = nil; // See NSToolbarItem -initialize method
// [NSFont smallSystemFontSize] or better should be NSControlContentFontSize
  
static NSFont *SmallFont = nil;

@interface GSToolbar (GNUstepPrivate)
- (GSToolbarView *) _toolbarView;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (void) _layout;
// ---
- (NSView *) _backView;
- (NSMenuItem *) _defaultMenuFormRepresentation;
- (BOOL) _isFlexibleSpace;
- (BOOL) _isModified;
- (BOOL) _selectable;
- (GSToolbar *) _toolbar;
- (void) _setSelectable: (BOOL)selectable;
- (BOOL) _selected;
- (void) _setSelected: (BOOL)selected;
- (void) _setToolbar: (GSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;
@end

/*
 * NSButton subclass is the toolbar buttons _backView
 */
@interface GSToolbarButton : NSButton
{
  NSToolbarItem *_toolbarItem;
  SEL _toolbarItemAction;
}

- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem;
- (void) layout;

// Accessors
- (NSToolbarItem *) toolbarItem;
- (SEL) toolbarItemAction;
- (void) setToolbarItemAction: (SEL)action;
@end

@interface GSToolbarButtonCell : NSButtonCell
{
  NSRect titleRect;
  NSRect imageRect;
}

@end

// ---

@implementation GSToolbarButton
+ (void) initialize
{
  if (self == [GSToolbarButton class])
    [GSToolbarButton setCellClass: [GSToolbarButtonCell class]];
}  

- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem
{ 
  self = [super initWithFrame: NSMakeRect(ItemBackViewX, ItemBackViewY,
    ItemBackViewDefaultWidth, ItemBackViewDefaultHeight)]; 
  // Frame will be reset by the layout method
  
  if (self != nil)
    {
      // Don't do an ASSIGN here, the toolbar item itself retains us.
      _toolbarItem = toolbarItem;
      
      //[self setCell: [[GSToolbarButtonCell alloc] init]];
    }
  return self;   
}

- (void) dealloc
{ 
  // Nothing to do currently
  
  [super dealloc];
}

- (void) layout
{
  float textWidth, layoutedWidth = -1, layoutedHeight = -1;
  NSAttributedString *attrStr;
  NSDictionary *attr;
  NSFont *font;
  unsigned int borderMask = [[[_toolbarItem toolbar] _toolbarView] borderMask];
  NSString *label = [_toolbarItem label];
  
  // Adjust the layout in accordance with NSToolbarSizeMode
  
  font = NormalFont;
  
  switch ([[_toolbarItem toolbar] sizeMode])
    {
      case NSToolbarSizeModeDefault:
	layoutedWidth = ItemBackViewDefaultWidth;
	layoutedHeight = ItemBackViewDefaultHeight;
	[[_toolbarItem image] setSize: NSMakeSize(32, 32)];
	break;
      case NSToolbarSizeModeRegular:
        layoutedWidth = ItemBackViewRegularWidth;
        layoutedHeight = ItemBackViewRegularHeight;
	[[_toolbarItem image] setSize: NSMakeSize(32, 32)];
	break;
      case NSToolbarSizeModeSmall:
        layoutedWidth = ItemBackViewSmallWidth;
	layoutedHeight = ItemBackViewSmallHeight;
	[[_toolbarItem image] setSize: NSMakeSize(24, 24)];
	// Not use [self image] here because it can return nil, when image position is
	// set to NSNoImage. Even if NSToolbarDisplayModeTextOnly is not true anymore
	// -setImagePosition: is only called below, then [self image] can still returns 
	// nil.
	font = SmallFont;
	break;
      default:
	; // Invalid
    }
    
  [[self cell] setFont: font];
  
  // Adjust the layout in accordance with the border
  
  if (!(borderMask & GSToolbarViewBottomBorder))
    {
      layoutedHeight++;
      layoutedWidth++;
    }

  if (!(borderMask & GSToolbarViewTopBorder))
    {
      layoutedHeight++;
      layoutedWidth++; 
    }
             
  // Adjust the layout in accordance with the label
	
  attr = [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName];
  if (label == nil || [label isEqualToString: @""])
    label = @"Dummy";
  attrStr = [[NSAttributedString alloc] initWithString: label attributes: attr];
      
  textWidth = [attrStr size].width + 2 * InsetItemTextX;
  if (layoutedWidth != -1 && textWidth > layoutedWidth) 
     layoutedWidth = textWidth;
     
  // Adjust the layout in accordance with NSToolbarDisplayMode
  
  switch ([[_toolbarItem toolbar] displayMode])
    {
      case NSToolbarDisplayModeDefault:
        [self setImagePosition: NSImageAbove];
        break;
      case NSToolbarDisplayModeIconAndLabel:
        [self setImagePosition: NSImageAbove];
        break;
      case NSToolbarDisplayModeIconOnly:
        [self setImagePosition: NSImageOnly];
        layoutedHeight -= [attrStr size].height + InsetItemTextY;
	layoutedWidth -= [attrStr size].height + InsetItemTextY;
	break;
      case NSToolbarDisplayModeLabelOnly:
        [self setImagePosition: NSNoImage];
        layoutedHeight = [attrStr size].height + InsetItemTextY * 2;
	break;
      default:
	; // Invalid
    }
  DESTROY(attrStr);
      
  // Set the frame size to use the new layout
  
  [self setFrameSize: NSMakeSize(layoutedWidth, layoutedHeight)];
   
}

- (void) mouseDown: (NSEvent *)event
{
  if ([_toolbarItem _selectable] && [self state])
    return; // Abort in case the button is selectable and selected
    // HACK: must be improved to handle drag event
  
  [super mouseDown: event];
}

- (BOOL) sendAction: (SEL)action to: (id)target
{ 
  if ([_toolbarItem _selectable])
    [[_toolbarItem toolbar] setSelectedItemIdentifier: [_toolbarItem itemIdentifier]];
  
  if (_toolbarItemAction)
    {
      return [NSApp sendAction: _toolbarItemAction to: target from: _toolbarItem];
    }
  else
    {
      return NO;
    }
}

- (NSToolbarItem *) toolbarItem
{
  return _toolbarItem;
}

- (void) setToolbarItemAction: (SEL) action
{
  _toolbarItemAction = action;
}

- (SEL) toolbarItemAction
{
  return _toolbarItemAction;
}

@end

@implementation GSToolbarButtonCell

// Overriden NSButtonCell method
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSSize titleSize = [[self attributedTitle] size];
  // We ignore alternateAttributedTitle, it is not needed
  
  // We store the values we need to customize the drawing into titleRect and imageRect
  
  titleRect.origin.x = cellFrame.origin.x;
  titleRect.origin.y = cellFrame.origin.y + InsetItemTextY;
  titleRect.size.width =  cellFrame.size.width;
  titleRect.size.height = titleSize.height;
  
  imageRect.origin.x = cellFrame.origin.x;
  imageRect.origin.y = cellFrame.origin.y;
  if ([self imagePosition] != NSImageOnly)     
    imageRect.origin.y += titleRect.size.height;
  imageRect.size.width = cellFrame.size.width;
  imageRect.size.height = cellFrame.size.height;
  if ([self imagePosition] != NSImageOnly)     
    imageRect.size.height -= titleRect.size.height;
    
  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

// Overriden NSCell method
- (void) _drawAttributedText: (NSAttributedString*)aString 
		     inFrame: (NSRect)aRect
{
  if (aString == nil)
    return;

  /** Important: text should always be vertically centered without
   * considering descender [as if descender did not exist].
   * This is particularly important for single line texts.
   * Please make sure the output remains always correct.
   */
  // We ignore aRect value

  [aString drawInRect: titleRect];
}

// Overriden NSButtonCell method
- (void) _drawImage: (NSImage *)anImage inFrame: (NSRect)aRect isFlipped: (BOOL)flipped
{
  NSSize size;
  NSPoint position;

  // We ignore aRect value
  
  size = [anImage size];
  position.x = MAX(NSMidX(imageRect) - (size.width / 2.), 0.);
  position.y = MAX(NSMidY(imageRect) - (size.height / 2.), 0.);
  
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if (flipped)
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

@end

/*
 * Back view used to enclose toolbar item's custom view
 */
@interface GSToolbarBackView : NSView
{
  NSToolbarItem *_toolbarItem;
  NSFont *_font;
  BOOL _enabled;
  BOOL _showLabel;
}

- (id) initWithToolbarItem: (NSToolbarItem *)toolbarItem;
- (NSToolbarItem *) toolbarItem;
- (BOOL) enabled;
- (void) setEnabled: (BOOL)enabled;
@end

@implementation GSToolbarBackView

- (id)initWithToolbarItem: (NSToolbarItem *)toolbarItem
{  
  self = [super initWithFrame: NSMakeRect(ItemBackViewX, ItemBackViewY, ItemBackViewDefaultWidth,
  ItemBackViewDefaultHeight)];
  // Frame will be reset by the layout method
  
  if (self != nil)
    {  
      // Don't do an ASSIGN here, the toolbar item itself retains us.
      _toolbarItem = toolbarItem;
    }
  
  return self;
}

- (void) dealloc
{ 
  // _font is pointing on a static variable then we do own it and don't need
  // to release it.
  
  [super dealloc];
}

- (void) drawRect: (NSRect)rect
{  
  [super drawRect: rect]; // We draw _view which is a subview
     
  if (_showLabel)
    {
      NSAttributedString *attrString;
      NSDictionary *attr;
      NSColor *color;
      NSMutableParagraphStyle *pStyle = [NSMutableParagraphStyle defaultParagraphStyle];
      NSRect titleRect;
      NSRect viewBounds = [self bounds];

      if (_enabled)
        {
          color = [NSColor blackColor];
        }
      else
        {
          color = [NSColor disabledControlTextColor];
        }
	
      [pStyle setAlignment: NSCenterTextAlignment];
      
      // We draw the label
      attr = [NSDictionary dictionaryWithObjectsAndKeys: _font, 
					   NSFontAttributeName,
							 color,
				NSForegroundColorAttributeName,
				                        pStyle,
				 NSParagraphStyleAttributeName,
						          nil];
      attrString = [[NSAttributedString alloc] initWithString: [_toolbarItem label] attributes: attr];
      
      titleRect.origin.x = viewBounds.origin.x;
      titleRect.origin.y = viewBounds.origin.y + InsetItemTextY;
      titleRect.size.width = viewBounds.size.width;
      titleRect.size.height = [attrString size].height;
      [attrString drawInRect: titleRect];
      
      DESTROY(attrString);
   }
}

- (void) layout
{
  NSView *view = [_toolbarItem view];
  float insetItemViewY;
  float textWidth, layoutedWidth = -1, layoutedHeight = -1;
  NSAttributedString *attrStr;
  NSDictionary *attr;
  unsigned int borderMask = [[[_toolbarItem toolbar] _toolbarView] borderMask];
  NSString *label = [_toolbarItem label];
  
  _font = NormalFont;
  
  if ([view superview] == nil) // Show the view to eventually hide it later
    [self addSubview: view];
    
  // Adjust the layout in accordance with NSToolbarSizeMode
  
  switch ([[_toolbarItem toolbar] sizeMode])
    {
      case NSToolbarSizeModeDefault:
	layoutedWidth = ItemBackViewDefaultWidth;
	layoutedHeight = ItemBackViewDefaultHeight;
	if ([view frame].size.height > 32)
	  [view removeFromSuperview];
	break;
      case NSToolbarSizeModeRegular:
        layoutedWidth = ItemBackViewRegularWidth;
        layoutedHeight = ItemBackViewRegularHeight;
	if ([view frame].size.height > 32)
	  [view removeFromSuperview];
	break;
      case NSToolbarSizeModeSmall:
        layoutedWidth = ItemBackViewSmallWidth;
	layoutedHeight = ItemBackViewSmallHeight;
	_font = SmallFont;
	if ([view frame].size.height > 24)
	  [view removeFromSuperview];
	break;
      default:
	NSLog(@"Invalid NSToolbarSizeMode"); // invalid
    } 
    
  // Adjust the layout in accordance with the border
  
  if (!(borderMask & GSToolbarViewBottomBorder))
    {
      layoutedHeight++;
      layoutedWidth++;
    }

  if (!(borderMask & GSToolbarViewTopBorder))
    {
      layoutedHeight++;
      layoutedWidth++; 
    }
  
  // Adjust the layout in accordance with the label
 
  attr = [NSDictionary dictionaryWithObject: _font forKey: NSFontAttributeName];
  if (label == nil || [label isEqualToString: @""])
    label = @"Dummy";
  attrStr = [[NSAttributedString alloc] initWithString: label attributes: attr];
      
  textWidth = [attrStr size].width + 2 * InsetItemTextX;
  if (textWidth > layoutedWidth)
    layoutedWidth = textWidth;
    
  // Adjust the layout in accordance with NSToolbarDisplayMode
  
  _enabled = YES;
  _showLabel = YES; 
  // This boolean variable is used to known when it's needed to draw the label in the -drawRect:
  // method.
   
  switch ([[_toolbarItem toolbar] displayMode])
    {
      case NSToolbarDisplayModeDefault:
        break; // Nothing to do
      case NSToolbarDisplayModeIconAndLabel:
        break; // Nothing to do
      case NSToolbarDisplayModeIconOnly:
        _showLabel = NO;
        layoutedHeight -= [attrStr size].height + InsetItemTextY;
	break;
      case NSToolbarDisplayModeLabelOnly:
        _enabled = NO;
        layoutedHeight = [attrStr size].height + InsetItemTextY * 2;
	if ([view superview] != nil)
	  [view removeFromSuperview];
	break;
      default:
	; // Invalid
    }
   
  // If the view is visible... 
  // Adjust the layout in accordance with the view width in the case it is needed
  
  if ([view superview] != nil)
    { 
    if (layoutedWidth < [view frame].size.width + 2 * InsetItemViewX)
      layoutedWidth = [view frame].size.width + 2 * InsetItemViewX; 
    }
  
  // Set the frame size to use the new layout
  
  [self setFrameSize: NSMakeSize(layoutedWidth, layoutedHeight)];
  
  // If the view is visible...
  // Adjust the view position in accordance with the new layout
  
  if ([view superview] != nil)
    {
      if (_showLabel)
        {
          insetItemViewY = ([self frame].size.height 
	    - [view frame].size.height - [attrStr size].height - InsetItemTextX) / 2
	    + [attrStr size].height + InsetItemTextX;
	}
      else
        {
	  insetItemViewY = ([self frame].size.height - [view frame].size.height) / 2;
	}
	
      [view setFrameOrigin: 
        NSMakePoint((layoutedWidth - [view frame].size.width) / 2, insetItemViewY)];
    }
  DESTROY(attrStr);
}

- (NSToolbarItem *)toolbarItem
{
  return _toolbarItem;
}

- (BOOL) enabled
{
  id view = [_toolbarItem view];
 
  if ([view respondsToSelector: @selector(setEnabled:)])
  {
    return [view enabled];
  }
    
  return _enabled;
}

- (void) setEnabled: (BOOL)enabled
{
  id view = [_toolbarItem view];
 
  _enabled = enabled;
  if ([view respondsToSelector: @selector(setEnabled:)])
  {
    [view setEnabled: enabled];
  }
}

@end

/*
 *
 * Standard toolbar items.
 *
 */

// ---- NSToolbarSeparatorItemIdentifier
@interface GSToolbarSeparatorItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSeparatorItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarSeparatorItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [(NSButton *)[self _backView] setImagePosition: NSImageOnly];
  [(NSButton *)[self _backView] setImage: image];
  // We bypass the toolbar item accessor to set the image in order to have it (48 * 48) not resized
   
  [[self _backView] setFrameSize: NSMakeSize(30, ItemBackViewDefaultHeight)];
  
  return self;
}

- (NSMenuItem *) _defaultMenuFormRepresentation 
{
  return nil; // Override the default implementation in order to do nothing
}

- (void) _layout 
{
  NSView *backView = [self _backView];
  
  // Override the default implementation
  
  [(id)backView layout];
  [backView setFrameSize: NSMakeSize(30, [backView frame].size.height)];
}
@end

// ---- NSToolbarSpaceItemIdentifier
@interface GSToolbarSpaceItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSpaceItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{ 
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setLabel: @""];
  
  return self;
}

- (NSMenuItem *) _defaultMenuFormRepresentation 
{
  return nil; // Override the default implementation in order to do nothing
}
@end

// ---- NSToolbarFlexibleSpaceItemIdentifier
@interface GSToolbarFlexibleSpaceItem : NSToolbarItem
{
}
@end

@implementation GSToolbarFlexibleSpaceItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setLabel: @""];
  [self _layout];
  
  return self;
}

- (NSMenuItem *) _defaultMenuFormRepresentation 
{
  return nil; // Override the default implementation in order to do nothing
}

- (void) _layout 
{
  NSView *backView = [self _backView];
  
  [(id)backView layout];
  
  [backView setFrameSize: NSMakeSize(0, [backView frame].size.height)];
  
  // Override the default implementation in order to reset the _backView to a zero width
}
@end

// ---- NSToolbarShowColorsItemIdentifier
@interface GSToolbarShowColorsItem : NSToolbarItem
{
}
@end

@implementation GSToolbarShowColorsItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarShowColorsItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Colors"]; // FIX ME: localize

  // Set action...
  [self setTarget: nil]; // Goes to first responder..
  [self setAction: @selector(orderFrontColorPanel:)];

  return self;
}
@end

// ---- NSToolbarShowFontsItemIdentifier
@interface GSToolbarShowFontsItem : NSToolbarItem
{
}
@end

@implementation GSToolbarShowFontsItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarShowFontsItem"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Fonts"]; // FIX ME: localize

  // Set action...
  [self setTarget: nil]; // Goes to first responder..
  [self setAction: @selector(orderFrontFontPanel:)];

  return self;
}
@end

// ---- NSToolbarCustomizeToolbarItemIdentifier
@interface GSToolbarCustomizeToolbarItem : NSToolbarItem
{
}
@end

@implementation GSToolbarCustomizeToolbarItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarCustomizeToolbarItem"];
  
  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Customize"]; // FIX ME: localize

  // Set action...
  [self setTarget: nil]; // Goes to first responder..
  [self setAction: @selector(runCustomizationPalette:)];

  return self;
}
@end

// ---- NSToolbarPrintItemIdentifier
@interface GSToolbarPrintItem : NSToolbarItem
{
}
@end

@implementation GSToolbarPrintItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  NSImage *image = [NSImage imageNamed: @"common_Printer"];

  self = [super initWithItemIdentifier: itemIdentifier];
  [self setImage: image];
  [self setLabel: @"Print..."];  // FIX ME: localize

  // Set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(print:)];

  return self;
}
@end


@implementation NSToolbarItem
+ (void) initialize
{
  NormalFont = RETAIN([NSFont systemFontOfSize: 11]);
  // [NSFont smallSystemFontSize] or better should be NSControlContentFontSize
  
  SmallFont = RETAIN([NSFont systemFontOfSize: 9]);
}

- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  GSToolbarButton *button;
  NSButtonCell *cell;
  
  if ((self = [super init]) != nil)
    {   
    
      // GNUstep predefined toolbar items
       
      if ([itemIdentifier isEqualToString: @"NSToolbarSeparatorItemIdentifier"] 
           && ![self isKindOfClass:[GSToolbarSeparatorItem class]])
        {
          [self release];
          self = [[GSToolbarSeparatorItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarSpaceItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarSpaceItem class]])
        {
          [self release];
          self = [[GSToolbarSpaceItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarFlexibleSpaceItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarFlexibleSpaceItem class]])
        {
          [self release];
          self = [[GSToolbarFlexibleSpaceItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarShowColorsItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarShowColorsItem class]])
        {
          [self release];
          self = [[GSToolbarShowColorsItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarShowFontsItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarShowFontsItem class]])
        {
          [self release];
          self = [[GSToolbarShowFontsItem alloc] initWithItemIdentifier: itemIdentifier];
        }
    
      else if ([itemIdentifier isEqualToString: @"NSToolbarCustomizeToolbarItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarCustomizeToolbarItem class]])
        {
          [self release];
          self = [[GSToolbarCustomizeToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
        }
     
      else if ([itemIdentifier isEqualToString: @"NSToolbarPrintItemIdentifier"] 
                && ![self isKindOfClass:[GSToolbarPrintItem class]])
        {
          [self release];
          self = [[GSToolbarPrintItem alloc] initWithItemIdentifier: itemIdentifier];
        }
	
      // Normal toolbar items
      else
        {
      
          ASSIGN(_itemIdentifier, itemIdentifier);
      
          button = [[GSToolbarButton alloc] initWithToolbarItem: self];
          cell = [button cell];
	  [button setTitle: @""];
	  [button setEnabled: NO];
          [button setBordered: NO];
          [button setImagePosition: NSImageAbove];
	  [cell setBezeled: YES];
          [cell setHighlightsBy: NSChangeGrayCellMask | NSChangeBackgroundCellMask];
          [cell setFont: [NSFont systemFontOfSize: 11]]; 
	  // [NSFont smallSystemFontSize] or better should be controlContentFontSize

          [_backView release];
          _backView = button;
        }
        
      // gets
      _flags._isEnabled  = [_backView respondsToSelector: @selector(isEnabled)];
      _flags._tag        = YES;
      _flags._action     = [_backView respondsToSelector: @selector(toolbarItemAction)];	
      _flags._target     = [_backView respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_backView respondsToSelector: @selector(setEnabled:)];
      _flags._setTag     = YES;
      _flags._setAction  = [_backView respondsToSelector: @selector(setToolbarItemAction:)];
      _flags._setTarget  = [_backView respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    
    }
  
  return self;
}

- (void) dealloc
{
  RELEASE(_itemIdentifier);
  RELEASE(_label);
  RELEASE(_image);
  RELEASE(_menuFormRepresentation);
  RELEASE(_paletteLabel);
  RELEASE(_toolTip);
  RELEASE(_view);
  RELEASE(_backView);
  
  [super dealloc];
}

- (BOOL) allowsDuplicatesInToolbar
{
  return _allowsDuplicatesInToolbar;
}

- (BOOL) isEnabled
{
  if(_flags._isEnabled)
    {
      return [(id)_backView isEnabled];
    }
  return NO;
}

- (NSImage *)image
{
  if(_flags._image)
    {
      return _image;
    }
  return nil;
}

- (NSString *) itemIdentifier
{
  return _itemIdentifier;
}

- (NSString *) label
{
  NSMenuItem *menuItem = [self menuFormRepresentation];
  
  if ([[self toolbar] displayMode] == NSToolbarDisplayModeLabelOnly && menuItem != nil)
    {
      return [menuItem title];
    }
  else
    {
      return _label;
    }
}

- (NSSize) maxSize
{
  return _maxSize;
}

- (NSMenuItem *) menuFormRepresentation
{
  return _menuFormRepresentation;
}

- (NSSize) minSize
{
  return _minSize;
}

- (NSString *) paletteLabel
{
  return _paletteLabel;
}

- (void) setAction: (SEL)action
{
  if(_flags._setAction)
    {
      if ([_backView isKindOfClass: [GSToolbarButton class]])
        [(GSToolbarButton *)_backView setToolbarItemAction: action];
	if (action != NULL)
	  {
	    [self setEnabled: YES];
	  }
	else
	  {
	    [self setEnabled: NO];
	  }
    }
}

- (void) setEnabled: (BOOL)enabled
{
  if(_flags._setEnabled)
    [(id)_backView setEnabled: enabled];
}

- (void) setImage: (NSImage *)image
{
  if(_flags._setImage)
    {  
      ASSIGN(_image, image);  
      
      [_image setScalesWhenResized: YES];
      //[_image setSize: NSMakeSize(32, 32)];
      
      if ([_backView isKindOfClass: [NSButton class]])
        [(NSButton *)_backView setImage: _image];
    }
}

- (void) setLabel: (NSString *)label
{
  ASSIGN(_label, label);
  
  if ([_backView isKindOfClass: [NSButton class]])
    [(NSButton *)_backView setTitle:_label];

  _modified = YES;
  if (_toolbar != nil)
    [[_toolbar _toolbarView] _reload];
}

- (void) setMaxSize: (NSSize)maxSize
{
  _maxSize = maxSize;
}

- (void) setMenuFormRepresentation: (NSMenuItem *)menuItem
{
  ASSIGN(_menuFormRepresentation, menuItem);
}

- (void) setMinSize: (NSSize)minSize
{
  _minSize = minSize;
}

- (void) setPaletteLabel: (NSString *)paletteLabel
{
  ASSIGN(_paletteLabel, paletteLabel);
}

- (void) setTag: (int)tag
{
  if(_flags._tag)
    _tag = tag;
}

- (void) setTarget: (id)target
{
   if(_flags._target)
     {
       if ([_backView isKindOfClass: [NSButton class]])
         [(NSButton *)_backView setTarget: target];
     }
}

- (void) setToolTip: (NSString *)toolTip
{
  ASSIGN(_toolTip, toolTip);
}

- (void) setView: (NSView *)view
{
  ASSIGN(_view, view);
  
  if (_view == nil)
    {
      // gets
      _flags._isEnabled  = [_backView respondsToSelector: @selector(isEnabled)];
      _flags._action     = [_backView respondsToSelector: @selector(toolbarItemAction)];
      _flags._target     = [_backView respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_backView respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = [_backView respondsToSelector: @selector(setToolbarItemAction:)];
      _flags._setTarget  = [_backView respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    }
  else
    {
      // gets
      _flags._isEnabled  = [_view respondsToSelector: @selector(isEnabled)];
      _flags._action     = [_view respondsToSelector: @selector(action)];
      _flags._target     = [_view respondsToSelector: @selector(target)];
      _flags._image      = [_backView respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_view respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = [_view respondsToSelector: @selector(setAction:)];
      _flags._setTarget  = [_view respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    }
  
  [_backView release];
  _backView = [[GSToolbarBackView alloc] initWithToolbarItem: self];
}

- (int) tag
{
  if(_flags._tag)
    return _tag;

  return 0;
}

- (NSString *) toolTip
{
  return _toolTip;
}

- (GSToolbar *) toolbar
{
  return _toolbar;
}

- (void) validate
{
  // Validate by default, we know that all of the
  // "standard" items are correct.
  NSMenuItem *menuItem = [self menuFormRepresentation];
  id target = [self target];
  
  if ([[self toolbar] displayMode] == NSToolbarDisplayModeLabelOnly && menuItem != nil)
    {
      if ([target respondsToSelector: @selector(validateMenuItem:)])
        [self setEnabled: [target validateMenuItem: menuItem]];
    }
  else
    {
      if ([target respondsToSelector: @selector(validateToolbarItem:)])
        [self setEnabled: [target validateToolbarItem: self]];
    } 
    
  // We can get a crash here when the target is pointing garbage memory...
}

- (NSView *) view
{
  return _view;
}

// Private or package like visibility methods

- (NSView *) _backView
{
  return _backView;
}

- (NSMenuItem *) _defaultMenuFormRepresentation
{
  NSMenuItem *menuItem;
  
  menuItem = [[NSMenuItem alloc] initWithTitle: [self label]  
                                        action: [self action] 
                                 keyEquivalent: @""];
  [menuItem setTarget: [self target]];
  AUTORELEASE(menuItem);
  
  return menuItem;
}

- (void) _layout
{
  [(id)_backView layout];
}

- (BOOL) _isModified
{
  return _modified;
}

- (BOOL) _isFlexibleSpace
{
  return [self isKindOfClass: [GSToolbarFlexibleSpaceItem class]];
}

- (BOOL) _selectable
{
  return _selectable;
}

- (BOOL) _selected
{
  return [(GSToolbarButton *)_backView state];
}

- (GSToolbar *) _toolbar
{
  return _toolbar;
}

- (void) _setSelected: (BOOL)selected
{
  if (_selectable && ![self _selected] && selected)
    {
      [(GSToolbarButton *)_backView performClick:self];
    }
  else if (!selected)
    {
      [(GSToolbarButton *)_backView setState: NO];
    }
  else if (!_selectable)
    {
      NSLog(@"The toolbar item %@ is not selectable", self);
    }
}

- (void) _setSelectable: (BOOL)selectable
{
  if ([_backView isKindOfClass: [GSToolbarButton class]])
    {
      _selectable = selectable;
      [(GSToolbarButton *)_backView setButtonType: NSOnOffButton];
    }
  else
    {
      NSLog(@"The toolbar item %@ is not selectable", self);
    }   
}

- (void) _setToolbar: (GSToolbar *)toolbar
{
  // Don't do an ASSIGN here, the toolbar itself retains us.
  _toolbar = toolbar;
}

// NSValidatedUserInterfaceItem protocol
- (SEL) action
{
  if(_flags._action)
    {
      if ([_backView isKindOfClass: [GSToolbarButton class]])
        return [(GSToolbarButton *)_backView toolbarItemAction];
    }
  return 0;
}

- (id) target
{
  if(_flags._target)
    {
      if ([_backView isKindOfClass: [NSButton class]])
        return [(NSButton *)_backView target];
    }

  return nil;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone 
{
  NSToolbarItem *new = [[NSToolbarItem allocWithZone: zone] initWithItemIdentifier: _itemIdentifier];

  // Copy all items individually...
  [new setTarget: [self target]];
  [new setAction: [self action]];
  [new setView: [self view]];
  [new setToolTip: [[self toolTip] copyWithZone: zone]];
  [new setTag: [self tag]];
  [new setImage: [[self image] copyWithZone: zone]];
  [new setEnabled: [self isEnabled]];
  [new setPaletteLabel: [[self paletteLabel] copyWithZone: zone]];
  [new setMinSize: NSMakeSize(_minSize.width, _minSize.height)];
  [new setMaxSize: NSMakeSize(_maxSize.width, _maxSize.height)];

  return new;
}

@end

