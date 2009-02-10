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

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include "AppKit/NSApplication.h"
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSDragging.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSParagraphStyle.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSView.h"
#include "GNUstepGUI/GSToolbarView.h"
#include "AppKit/NSToolbarItem.h"

#include "NSToolbarFrameworkPrivate.h"

/*
 * Each NSToolbarItem object are coupled with a backView which is their 
 * representation on the screen.
 * backView for the standard toolbar item (without custom view) are NSButton 
 * subclass called GSToolbarButton.
 * backView for the toolbar item with a custom view are NSView subclass called
 * GSToolbarBackView.
 * GSToolbarButton and GSToolbarBackView are adjusted according to their content
 * and their title when the method layout is called.
 * The predefined GNUstep toolbar items are implemented with a class cluster 
 * pattern: initWithToolbarItemIdentifier: returns differents concrete subclass 
 * in accordance with the item identifier.
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

NSString *GSMovableToolbarItemPboardType = @"GSMovableToolbarItemPboardType";

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
+ (Class) cellClass
{
  return [GSToolbarButtonCell class];
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

      [self setTitle: @""];
      [self setEnabled: NO];
      [_cell setBezeled: YES];
      [self setImagePosition: NSImageAbove];
      [self setHighlightsBy: 
                NSChangeGrayCellMask | NSChangeBackgroundCellMask];
      [self setFont: [NSFont systemFontOfSize: 11]]; 
      /* [NSFont smallSystemFontSize] or better should be 
         controlContentFontSize. */
    }

  return self;   
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
        /* Not use [self image] here because it can return nil, when image 
           position is set to NSNoImage. Even if NSToolbarDisplayModeTextOnly 
           is not true anymore -setImagePosition: is only called below, then 
           [self image] can still returns nil. */
        font = SmallFont;
        break;
      default:
        ; // Invalid
    }
    
  [self setFont: font];
  
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
  if ([[_toolbarItem toolbar] displayMode] != NSToolbarDisplayModeIconOnly 
    && layoutedWidth != -1 && textWidth > layoutedWidth) 
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

/*
 * The code below should be kept in sync with GSToolbarBackView methods which
 * have identical names.
 */
 
- (void) mouseDown: (NSEvent *)event
{
  NSToolbar *toolbar = [_toolbarItem toolbar];
  
  if (([event modifierFlags] == NSCommandKeyMask 
       && [toolbar allowsUserCustomization])
      || [toolbar customizationPaletteIsRunning] || toolbar == nil)
    {          
      NSSize viewSize = [self frame].size;
      NSImage *image = [[NSImage alloc] initWithSize: viewSize];
      NSCell *cell = [self cell];
      NSPasteboard *pboard;
      int index = -1;
          
      // Prepare the drag
      
      RETAIN(self); 
      /* We need to keep this view (aka self) to be able to draw the drag
         image. */
      
      // Draw the drag content in an image
      
      /* The code below is only partially supported by GNUstep, then NSImage
         needs to be improved. */
      [image lockFocus];
      [cell setShowsFirstResponder: NO]; // To remove the dotted rect
      [cell drawWithFrame: 
                NSMakeRect(0, 0, viewSize.width, viewSize.height) inView: nil];
      [cell setShowsFirstResponder: YES];
      [image unlockFocus];
      
      pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
      [pboard declareTypes: [NSArray arrayWithObject: GSMovableToolbarItemPboardType] 
              owner: nil];
      if (toolbar != nil)
	      {
          index = [toolbar _indexOfItem: _toolbarItem];
        }
      [pboard setString: [NSString stringWithFormat:@"%d", index] 
              forType: GSMovableToolbarItemPboardType];
          
      [self dragImage: image 
            at: NSMakePoint(0.0, viewSize.height)
            offset: NSMakeSize(0.0, 0.0)
            event: event 
            pasteboard: pboard 
            source: self
            slideBack: NO];          
      RELEASE(image);
    }
  else if ([event modifierFlags] != NSCommandKeyMask)
    {
      [super mouseDown: event];
    }
}

- (void) draggedImage: (NSImage *)dragImage beganAt: (NSPoint)location
{
  NSToolbar *toolbar = [_toolbarItem toolbar];
  
  // FIXME: Where is this released?
  RETAIN(_toolbarItem); 
  /* We retain the toolbar item to be able to have have it reinsered later by 
     the dragging destination. */
  
  [toolbar _performRemoveItem: _toolbarItem];
}

- (void) draggedImage: (NSImage *)dragImage 
              endedAt: (NSPoint)location 
            operation: (NSDragOperation)operation
{
  RELEASE(self); // The view is no more needed : no more drawing to do with it.
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
  return isLocal ? NSDragOperationGeneric : NSDragOperationNone;
}

/*
 * End of the code to keep in sync
 */

- (BOOL) sendAction: (SEL)action to: (id)target
{ 
  if ([_toolbarItem _selectable])
    {
      [[_toolbarItem toolbar] 
        setSelectedItemIdentifier: [_toolbarItem itemIdentifier]];
    }
  
  if (_toolbarItemAction)
    {
      return [NSApp sendAction: _toolbarItemAction 
                            to: target 
                          from: _toolbarItem];
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

// FIXME: Why use this and not the action of the cell?
- (void) setToolbarItemAction: (SEL)action
{
  _toolbarItemAction = action;
}

- (SEL) toolbarItemAction
{
  return _toolbarItemAction;
}

@end

@implementation GSToolbarButtonCell

/* Overriden NSButtonCell method to handle cell type in a basic way which avoids
   to lose image or empty title on new image position (when this involves a cell
   type switch) and the need to reset it. That would happen in GSToolbarButton
   -layout method (on toolbar display mode switch).
   Note that empty title are used with space or separator toolbar items. */
- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  _cell.image_position = aPosition;

  if (_cell.image_position == NSNoImage)
    {
      _cell.type = NSTextCellType;
    }
  else
    {
      _cell.type = NSImageCellType;
    }
}

// Overriden NSButtonCell method to make sure all text is at the same height.
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL flippedView = [controlView isFlipped];
  NSCellImagePosition ipos = _cell.image_position;
  // We ignore alternateAttributedTitle, it is not needed
  NSSize titleSize = [[self attributedTitle] size];
  
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

  /* We store the values we need to customize the drawing into titleRect and 
     imageRect. */
  switch (ipos)
    {
      case NSNoImage: 
        titleRect = cellFrame;
        break;

      case NSImageOnly: 
        imageRect = cellFrame;
        break;

      default:
      case NSImageBelow: 
        titleRect.origin.x = cellFrame.origin.x;
        titleRect.origin.y = NSMaxY(cellFrame) - titleSize.height - InsetItemTextY;
        titleRect.size.width = cellFrame.size.width;
        titleRect.size.height = titleSize.height;
        
        imageRect.origin.x = cellFrame.origin.x;
        imageRect.origin.y = cellFrame.origin.y;
        imageRect.size.width = cellFrame.size.width;
        imageRect.size.height = cellFrame.size.height - titleRect.size.height;
        break;

      case NSImageAbove: 
        titleRect.origin.x = cellFrame.origin.x;
        titleRect.origin.y = cellFrame.origin.y + InsetItemTextY;
        titleRect.size.width = cellFrame.size.width;
        titleRect.size.height = titleSize.height;
        
        imageRect.origin.x = cellFrame.origin.x;
        imageRect.origin.y = cellFrame.origin.y + titleRect.size.height;
        imageRect.size.width = cellFrame.size.width;
        imageRect.size.height = cellFrame.size.height - titleRect.size.height;
        break;
    }

  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

// Overriden NSCell method
- (void) _drawAttributedText: (NSAttributedString*)aString 
                     inFrame: (NSRect)aRect
{
  if (aString == nil)
    return;

  /* Important: text should always be vertically centered without considering 
     descender (as if descender did not exist). This is particularly important 
     for single line texts.Please make sure the output remains always 
     correct. */

  [aString drawInRect: titleRect]; // We ignore aRect value
}

// Overriden NSButtonCell method
- (void) drawImage: (NSImage *)anImage withFrame: (NSRect)aRect inView: (NSView*)controlView
{
  // We ignore aRect value
  [super drawImage: anImage withFrame: imageRect inView: controlView];
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
- (void) layout;
- (BOOL) isEnabled;
- (void) setEnabled: (BOOL)enabled;
@end

@implementation GSToolbarBackView

- (id)initWithToolbarItem: (NSToolbarItem *)toolbarItem
{  
  self = [super initWithFrame: NSMakeRect(ItemBackViewX, ItemBackViewY, 
    ItemBackViewDefaultWidth, ItemBackViewDefaultHeight)];
  // Frame will be reset by the layout method
  
  if (self != nil)
    {  
      // Don't do an ASSIGN here, the toolbar item itself retains us.
      _toolbarItem = toolbarItem;
    }
  
  return self;
}

- (void) drawRect: (NSRect)rect
{  
  if (_showLabel)
    {
      NSAttributedString *attrString;
      NSDictionary *attr;
      NSColor *color;
      NSMutableParagraphStyle *pStyle;
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
        
      pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      [pStyle setAlignment: NSCenterTextAlignment];
      
      // We draw the label
      attr = [NSDictionary dictionaryWithObjectsAndKeys: _font, 
        NSFontAttributeName, color, NSForegroundColorAttributeName, pStyle,
        NSParagraphStyleAttributeName, nil];
      RELEASE(pStyle);

      attrString = [[NSAttributedString alloc] 
        initWithString: [_toolbarItem label] attributes: attr];
      
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
        NSLog(@"Invalid NSToolbarSizeMode"); // Invalid
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
  /* This boolean variable is used to known when it's needed to draw the label
     in the -drawRect: method. */
   
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
   
  /* If the view is visible... 
     Adjust the layout in accordance with the view width in the case it is 
     needed. */
  
  if ([view superview] != nil)
    { 
      if (layoutedWidth < [view frame].size.width + 2 * InsetItemViewX)
        layoutedWidth = [view frame].size.width + 2 * InsetItemViewX; 
    }
  
  // Set the frame size to use the new layout
  
  [self setFrameSize: NSMakeSize(layoutedWidth, layoutedHeight)];
  
  /* If the view is visible...
     Adjust the view position in accordance with the new layout. */
  
  if ([view superview] != nil)
    {
      if (_showLabel)
        {
          insetItemViewY = ([self frame].size.height - [view frame].size.height 
            - [attrStr size].height - InsetItemTextX) / 2 
            + [attrStr size].height + InsetItemTextX;
        }
      else
        {
          insetItemViewY = ([self frame].size.height 
            - [view frame].size.height) / 2;
        }
        
      [view setFrameOrigin: NSMakePoint((layoutedWidth 
        - [view frame].size.width) / 2, insetItemViewY)];
    }
    
  DESTROY(attrStr);
}

- (NSView *) hitTest: (NSPoint)point
{
  NSEvent *event = [NSApp currentEvent];
  
  if ([self mouse: point inRect: [self frame]] 
    && [event modifierFlags] == NSCommandKeyMask
    && [event type] == NSLeftMouseDown)
    {
      return self;
    }
  else
    {
      return [super hitTest: point];
    }
}

/*
 * The code below should be kept in sync with GSToolbarButton methods which 
 * have identical names.
 */
  
- (void) mouseDown: (NSEvent *)event
{
  NSToolbar *toolbar = [_toolbarItem toolbar];
  
  if (([event modifierFlags] == NSCommandKeyMask 
       && [toolbar allowsUserCustomization])
      || [toolbar customizationPaletteIsRunning] || toolbar == nil)
    {          
      NSSize viewSize = [self frame].size;
      NSImage *image = [[NSImage alloc] initWithSize: viewSize];
      NSPasteboard *pboard;
      int index = -1;
      
      // Prepare the drag
      
      RETAIN(self); 
      /* We need to keep this view (aka self) to be able to draw the drag
         image. */
      
      // Draw the drag content in an image
      
      /* The code below is only partially supported by GNUstep, then NSImage
         needs to be improved. */
      [image lockFocus];
      [self drawRect: 
                NSMakeRect(0, 0, viewSize.width, viewSize.height)];
      [image unlockFocus];
      
      pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
      [pboard declareTypes: [NSArray arrayWithObject: GSMovableToolbarItemPboardType] 
              owner: nil];
      if (toolbar != nil)
	      {
          index = [toolbar _indexOfItem: _toolbarItem];
        }
      [pboard setString: [NSString stringWithFormat:@"%d", index] 
              forType: GSMovableToolbarItemPboardType];
      
      [self dragImage: image 
            at: NSMakePoint(0.0, viewSize.height)
            offset: NSMakeSize(0.0, 0.0)
            event: event 
            pasteboard: pboard 
            source: self
            slideBack: NO];
      RELEASE(image);
    }
  else if ([event modifierFlags] != NSCommandKeyMask)
    {
      [super mouseDown: event];
    }
}

- (void) draggedImage: (NSImage *)dragImage beganAt: (NSPoint)location
{
  NSToolbar *toolbar = [_toolbarItem toolbar];
  
  // FIXME: Where is this released?
  RETAIN(_toolbarItem); 
  /* We retain the toolbar item to be able to have have it reinsered later by 
     the dragging destination. */
  
  [toolbar _performRemoveItem: _toolbarItem];
}

- (void) draggedImage: (NSImage *)dragImage 
              endedAt: (NSPoint)location 
            operation: (NSDragOperation)operation
{
  RELEASE(self); // The view is no more needed : no more drawing to do with it.
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
  return isLocal ? NSDragOperationGeneric : NSDragOperationNone;
}

/*
 * End of the code to keep in sync
 */

- (NSToolbarItem *)toolbarItem
{
  return _toolbarItem;
}

- (BOOL) isEnabled
{
  id view = [_toolbarItem view];
 
  if ([view respondsToSelector: @selector(isEnabled)])
    {
      return [view isEnabled];
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
 * Standard toolbar items.
 */

// ---- NSToolbarSeparatorItemIdentifier
@interface GSToolbarSeparatorItem : NSToolbarItem
{
}
@end

@implementation GSToolbarSeparatorItem
- (id) initWithItemIdentifier: (NSString *)itemIdentifier
{
  self = [super initWithItemIdentifier: itemIdentifier];
  if (!self)
    return nil;

  [(NSButton *)[self _backView] setImagePosition: NSImageOnly];
  [(NSButton *)[self _backView] setImage: 
                   [NSImage imageNamed: @"common_ToolbarSeparatorItem"]];
  /* We bypass the toolbar item accessor to set the image in order to have it
     (48 * 48) not resized. */
   
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
  if ([self toolbar] != nil)
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
  if (!self)
    return nil;
  [self setPaletteLabel: _(@"Space")];
   
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
  if (!self)
    return nil;
  [self setPaletteLabel: _(@"Flexible Space")];
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
  
  /* If the item is not part of a toolbar, this usually means it is used by
     customization palette, we shouldn't resize it in this case. */
  if ([self toolbar] != nil)
    [backView setFrameSize: NSMakeSize(0, [backView frame].size.height)];
  
  // Override the default implementation in order to reset the _backView to a zero width
}

- (BOOL) _isFlexibleSpace
{
  return YES;
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
  self = [super initWithItemIdentifier: itemIdentifier];
  if (!self)
    return nil;
  [self setImage: [NSImage imageNamed: @"common_ToolbarShowColorsItem"]];
  [self setLabel: _(@"Colors")];

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
  self = [super initWithItemIdentifier: itemIdentifier];
  if (!self)
    return nil;
  [self setImage: [NSImage imageNamed: @"common_ToolbarShowFontsItem"]];
  [self setLabel: _(@"Fonts")];

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
  self = [super initWithItemIdentifier: itemIdentifier];
  if (!self)
    return nil;
  [self setImage: [NSImage imageNamed: @"common_ToolbarCustomizeToolbarItem"]];
  [self setLabel: _(@"Customize")];

  // Set action...
  [self setTarget: nil]; // Goes to first responder..
  [self setAction: @selector(runToolbarCustomizationPalette:)];

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
  self = [super initWithItemIdentifier: itemIdentifier];
  if (!self)
    return nil;
  [self setImage: [NSImage imageNamed: @"common_Printer"]];
  [self setLabel: _(@"Print...")];

  // Set action...
  [self setTarget: nil]; // goes to first responder..
  [self setAction: @selector(printDocument:)];

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
  // GNUstep predefined toolbar items
  if ([itemIdentifier isEqualToString: NSToolbarSeparatorItemIdentifier] 
      && [self isKindOfClass: [GSToolbarSeparatorItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarSeparatorItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier isEqualToString: NSToolbarSpaceItemIdentifier]
           && [self isKindOfClass: [GSToolbarSpaceItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarSpaceItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier 
               isEqualToString: NSToolbarFlexibleSpaceItemIdentifier] 
           && [self isKindOfClass: [GSToolbarFlexibleSpaceItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarFlexibleSpaceItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier 
               isEqualToString: NSToolbarShowColorsItemIdentifier]
           && [self isKindOfClass: [GSToolbarShowColorsItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarShowColorsItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier 
               isEqualToString: NSToolbarShowFontsItemIdentifier]
           && [self isKindOfClass: [GSToolbarShowFontsItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarShowFontsItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier 
               isEqualToString: NSToolbarCustomizeToolbarItemIdentifier]
           && [self isKindOfClass: [GSToolbarCustomizeToolbarItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarCustomizeToolbarItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else if ([itemIdentifier isEqualToString: NSToolbarPrintItemIdentifier]
           && [self isKindOfClass: [GSToolbarPrintItem class]] == NO)
    {
      RELEASE(self);
      return [[GSToolbarPrintItem alloc] 
                 initWithItemIdentifier: itemIdentifier];
    }
  else
    {
      if ((self = [super init]) != nil)
        {
          // Normal toolbar items
          
          ASSIGN(_itemIdentifier, itemIdentifier);
          [self setAutovalidates: YES];

          // Set the backview to an GSToolbarButton, will get reset to a 
          // GSToolbarBackView when setView: gets called.
          RELEASE(_backView);
          _backView = [[GSToolbarButton alloc] initWithToolbarItem: self];
          
          [self _computeFlags]; 
        }        
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
  TEST_RELEASE(_view);
  RELEASE(_backView);
  
  [super dealloc];
}

- (BOOL) allowsDuplicatesInToolbar
{
  return NO;
}

- (BOOL) isEnabled
{
  if (_flags._isEnabled)
    {
      if (_view)
        return [_view isEnabled];
      else
        return [(GSToolbarButton*)_backView isEnabled];
    }
  return NO;
}

- (NSImage *)image
{
  if (_flags._image)
    {
      if (_view)
        return [_view image];
      else
        return [(GSToolbarButton*)_backView image];
    }

  return _image;
}

- (NSString *) itemIdentifier
{
  return _itemIdentifier;
}

- (NSString *) label
{
  // FIXME: I think this is not needed
  if ([[self toolbar] displayMode] == NSToolbarDisplayModeLabelOnly)
    {
      NSMenuItem *menuItem = [self menuFormRepresentation];
      
      if (menuItem != nil)
        return [menuItem title];
    }

  return _label;
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
  if (_flags._setAction)
    {
      if (_view)
        [_view setAction: action];
      else
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
  if (_flags._setEnabled)
    {
      if (_view)
        [_view setEnabled: enabled];
      else
        [(GSToolbarButton*)_backView setEnabled: enabled];
    }
}

- (void) setImage: (NSImage *)image
{
  ASSIGN(_image, image);  
      
  [_image setScalesWhenResized: YES];
  //[_image setSize: NSMakeSize(32, 32)];

  if (_flags._setImage)
    {
      if (_view)
        [_view setImage: image];
      else
        [(GSToolbarButton*)_backView setImage: image];
    }
}

- (void) setLabel: (NSString *)label
{
  ASSIGN(_label, label);
  
  if ([_backView isKindOfClass: [GSToolbarButton class]])
    [(GSToolbarButton *)_backView setTitle: _label];

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

- (void) setTag: (NSInteger)tag
{
  _tag = tag;
}

- (void) setTarget: (id)target
{
  if (_flags._setTarget)
    {
      if (_view)
        [_view setTarget: target];
      else
        [(NSButton *)_backView setTarget: target];
    }
}

- (void) setToolTip: (NSString *)toolTip
{
  ASSIGN(_toolTip, toolTip);
  [_view setToolTip: _toolTip];
}

- (void) setView: (NSView *)view
{
  if (_view == view)
    return;
    
  ASSIGN(_view, view);

  if (view)
    {
      [_view setToolTip: _toolTip];

      RELEASE(_backView);
      _backView = [[GSToolbarBackView alloc] initWithToolbarItem: self];
    }
  else
    {
      RELEASE(_backView);
      _backView = [[GSToolbarButton alloc] initWithToolbarItem: self];
    }

  [self _computeFlags]; 
}

- (void) _computeFlags
{
  if (_view == nil)
    {
      // gets
      _flags._isEnabled  = [_backView respondsToSelector: @selector(isEnabled)];
      _flags._action     = 
        [_backView respondsToSelector: @selector(toolbarItemAction)];
      _flags._target     = [_backView respondsToSelector: @selector(target)];
      _flags._image      = NO;
      // sets
      _flags._setEnabled = 
        [_backView respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = 
        [_backView respondsToSelector: @selector(setToolbarItemAction:)];
      _flags._setTarget  = 
        [_backView respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_backView respondsToSelector: @selector(setImage:)];
    }
  else
    {
      // gets
      _flags._isEnabled  = [_view respondsToSelector: @selector(isEnabled)];
      _flags._action     = [_view respondsToSelector: @selector(action)];
      _flags._target     = [_view respondsToSelector: @selector(target)];
      _flags._image      = [_view respondsToSelector: @selector(image)];
      // sets
      _flags._setEnabled = [_view respondsToSelector: @selector(setEnabled:)];
      _flags._setAction  = [_view respondsToSelector: @selector(setAction:)];
      _flags._setTarget  = [_view respondsToSelector: @selector(setTarget:)];
      _flags._setImage   = [_view respondsToSelector: @selector(setImage:)];
    }
}

- (NSInteger) tag
{
  return _tag;
}

- (NSString *) toolTip
{
  return _toolTip;
}

- (NSToolbar *) toolbar
{
  return _toolbar;
}

- (void) validate
{
  BOOL enabled = YES;
  id target;

  /* No validation for custom views */
  if (_view)
    return;

  target = [NSApp targetForAction: [self action] to: [self target] from: self];
  if (target == nil || ![target respondsToSelector: [self action]])
    {
      enabled = NO;
    }
  else if ([target respondsToSelector: @selector(validateToolbarItem:)])
    {
      enabled = [target validateToolbarItem: self];
    }
  else if ([target respondsToSelector: @selector(validateUserInterfaceItem:)])
    {
      enabled = [target validateUserInterfaceItem: self];
    }
  [self setEnabled: enabled];
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

//
// This method invokes using the toolbar item as the sender.
// When invoking from the menu, it shouldn't send the menuitem as the
// sender since some applications check this and try to get additional
// information about the toolbar item which this is coming from. Since
// we implement the menu's action, we must also validate it.
//
- (void) _sendAction: (id)sender
{
  [NSApp sendAction: [self action] 
	 to: [self target]
	 from: self];
}

- (BOOL) validateMenuItem: (NSMenuItem *)menuItem
{
  return [self isEnabled];
}

- (NSMenuItem *) _defaultMenuFormRepresentation
{
  NSMenuItem *menuItem;
  
  menuItem = [[NSMenuItem alloc] initWithTitle: [self label]  
				 action: @selector(_sendAction:) 
                                 keyEquivalent: @""];
  [menuItem setTarget: self];
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
  return NO;
}

- (BOOL) _selectable
{
  return _selectable;
}

- (BOOL) _selected
{
  return [(GSToolbarButton *)_backView state];
}

- (void) _setSelected: (BOOL)selected
{
  if (_selectable)
    {
      if ([self _selected] != selected)
        [(GSToolbarButton *)_backView setState: selected];
    }
  else
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

- (void) _setToolbar: (NSToolbar *)toolbar
{
  // Don't do an ASSIGN here, the toolbar itself retains us.
  _toolbar = toolbar;
}

- (BOOL) autovalidates
{
  return _autovalidates;
}

- (void) setAutovalidates: (BOOL)autovalidates
{
  _autovalidates = autovalidates;
}

- (NSInteger) visibilityPriority
{
  return _visibilityPriority;
}

- (void) setVisibilityPriority: (NSInteger)visibilityPriority
{
  _visibilityPriority = visibilityPriority;
}

// NSValidatedUserInterfaceItem protocol
- (SEL) action
{
  if (_flags._action)
    {
      if (_view)
        return [_view action];
      else
        return [(GSToolbarButton *)_backView toolbarItemAction];
    }
  return 0;
}

- (id) target
{
  if (_flags._target)
    {
      if (_view)
        return [_view target];
      else
        return [(GSToolbarButton *)_backView target];
    }

  return nil;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone 
{
  NSToolbarItem *new = [[NSToolbarItem allocWithZone: zone] 
    initWithItemIdentifier: _itemIdentifier];

  // Copy all items individually...
  [new setTarget: [self target]];
  [new setAction: [self action]];
  [new setToolTip: [[self toolTip] copyWithZone: zone]];
  [new setTag: [self tag]];
  [new setImage: [[self image] copyWithZone: zone]];
  [new setEnabled: [self isEnabled]];
  [new setPaletteLabel: [[self paletteLabel] copyWithZone: zone]];
  [new setLabel: [[self label] copyWithZone: zone]];
  [new setMinSize: [self minSize]];
  [new setMaxSize: [self maxSize]];
  [new setAutovalidates: [self autovalidates]];
  [new setVisibilityPriority: [self visibilityPriority]];
  [new setMenuFormRepresentation: [[self menuFormRepresentation] 
                                      copyWithZone: zone]];

  if ([self view] != nil)
    {
      NSData *encodedView = nil;
      NSView *superview = nil;

      /* NSView doesn't implement -copyWithZone:, that's why we encode
         then decode the view to create a copy of it. */
      superview = [[self view] superview];
      /* We must avoid to encode view hierarchy */
      [[self view] removeFromSuperviewWithoutNeedingDisplay];
      NSLog(@"Encode toolbar item with label %@, view %@ and superview %@", 
            [self label], [self view], superview);
      // NOTE: Keyed archiver would fail on NSSlider here.
      encodedView = [NSArchiver archivedDataWithRootObject: [self view]];
      [new setView: [NSUnarchiver unarchiveObjectWithData: encodedView]];
      // Re-add the view to its hierarchy
      [superview addSubview: [self view]];
    }

  return new;
}

@end
