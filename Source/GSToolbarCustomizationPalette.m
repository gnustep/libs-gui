/* 
   GSToolbarCustomizationPalette.m

   The palette which allows to customize toolbar
   
   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: January 2007
   
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

#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSToolbarItem.h"

#include "NSToolbarFrameworkPrivate.h"
#include "GSToolbarCustomizationPalette.h"

#define DEBUG_LEVEL @"Toolbar"

/* Customization View */
@interface GSToolbarCustomizationView : NSView
{
}

- (void) setToolbarItems: (NSArray *)items;
- (NSArray *) paletteItemsWithToolbarItems: (NSArray *)items;
- (void) layout;

@end

@implementation GSToolbarCustomizationView

/* If the toolbar item has a custom view and the item is in use in the 
   toolbar, this view has already a superview. We need to make a copy of it 
   in order to be able to put it in the customization view. 
   As a safety measure, we makes a copy of all toolbar items, thereby of all
   views. This ensures the toolbar items displayed in the palette don't 
   reference a toolbar. */
- (NSArray *) paletteItemsWithToolbarItems: (NSArray *)items
{
  NSMutableArray *paletteItems = [NSMutableArray array];
  NSEnumerator *e = [items objectEnumerator];
  NSToolbarItem *item = nil;

  e = [items objectEnumerator];
  while ((item = [e nextObject]) != nil)
    {
      NSToolbarItem *newItem = [item copy];

      if ([newItem paletteLabel] != nil)
        [newItem setLabel: [newItem paletteLabel]];
      [newItem setEnabled: YES];
      [newItem _layout];
      [paletteItems addObject: newItem];
    }

  NSDebugLLog(DEBUG_LEVEL, @"Generated palette items %@ from toolbar items %@", 
    paletteItems, items);

  return paletteItems;
}

- (void) layout
{
  NSSize boundsSize = [self bounds].size;
  float maxWidth = boundsSize.width;
  float maxHeight = boundsSize.height;
  float hAccumulator = 0.0;
  float vAccumulator = 0.0;
  NSEnumerator *e = [[self subviews] objectEnumerator];
  NSView *layoutedView = nil;
  int lastRow = 0;
  int index = 0;

  // Loop over all subviews
  while ((layoutedView = [e nextObject]) != nil)
    {
      NSRect frame = [layoutedView frame];
      NSSize size = frame.size;
      float height = size.height;
      float width = size.width;
 
      if ((hAccumulator + width) <= maxWidth)
        {
          // Position view in row
          if (vAccumulator < height)
            {
              vAccumulator = height;
              // FIXME: need to adjust all other elements of row
            }
        }
      else
        {
          // Move on to next row
          maxHeight -= vAccumulator;
          hAccumulator = 0.0;
          vAccumulator = height;
          lastRow = index;
        }

      [layoutedView setFrameOrigin: NSMakePoint(hAccumulator, 
                                                maxHeight - vAccumulator)];
      hAccumulator += width;
      index++;
    }
}

- (void) setToolbarItems: (NSArray *)items
{
  NSArray *paletteItems = [self paletteItemsWithToolbarItems: items];
  NSEnumerator *e;
  NSView *itemView;
  NSToolbarItem *item;

  // Remove all old subviews
  e = [[self subviews] objectEnumerator];
  while ((itemView = [e nextObject]) != nil)
    {
      [itemView removeFromSuperview];
    }

  NSDebugLLog(DEBUG_LEVEL, @"Will insert the views of toolbar items %@ in \
    customization view", paletteItems);
  e = [paletteItems objectEnumerator];
  while ((item = [e nextObject]) != nil)
    {
      itemView = [item _backView];
      if (itemView != nil)
        {
          [self addSubview: itemView];
        }
      else
        {
          NSLog(@"Toolbar item %@ will not be visible in the customization \
            view or if you insert it in a toolbar now. The view is already in \
            use in superview or does not implement NSCoding protocol", item);
        }
    }

  [self layout];
}

@end

/* Main implementation */

@implementation GSToolbarCustomizationPalette

+ (id) palette
{
  return AUTORELEASE([[GSToolbarCustomizationPalette alloc] 
    init]);
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      BOOL nibLoaded = [NSBundle loadNibNamed: @"GSToolbarCustomizationPalette" 
                                        owner: self];

      if (nibLoaded == NO)
        {
          NSLog(@"Failed to load GSToolbarCustomizationPalette");
          RELEASE(self);
          return nil;
        }

      _allowedItems = [NSMutableArray new];
      _defaultItems = [NSMutableArray new];
    }

  return self;
}

- (void) dealloc
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];

  DESTROY(_customizationWindow);
  DESTROY(_customizationView);
  DESTROY(_defaultTemplateView);
  DESTROY(_sizeCheckBox);
  DESTROY(_displayPopup);
  DESTROY(_doneButton);

  DESTROY(_defaultItems);
  DESTROY(_allowedItems);

  [super dealloc];
}

- (void) awakeFromNib
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  NSDebugLLog(DEBUG_LEVEL, @"GSToolbarCustomizationPalette awaking from nib");

  [nc addObserver: self 
         selector: @selector(paletteDidEnd:) 
             name: NSWindowWillCloseNotification
           object: _customizationWindow];
}

/* It's safer to keep no reference on the toolbar itself. The customization 
   palette isn't bound to the toolbar passed as parameter, in other words the 
   palette can be used to customize other toolbars with the same identifier.
   In spite of this, a reference must be kept on the toolbar which initiated 
   the customization to let it know when the customization has ended. */
- (void) showForToolbar: (NSToolbar *)toolbar
{
  NSArray *itemIdentifiers = nil;
  NSEnumerator *e = nil;
  NSString *identifier = nil;
  id delegate = [toolbar delegate];

  [_allowedItems removeAllObjects];
  [_defaultItems removeAllObjects];

  if (delegate == nil)
    {
      NSLog(@"The toolbar %@ needs a delegate to allow customization", 
        toolbar);
      return;
    }

  itemIdentifiers = [delegate toolbarAllowedItemIdentifiers: toolbar];
  e = [itemIdentifiers objectEnumerator];
  while ((identifier = [e nextObject]) != nil)
    {
      [_allowedItems addObject: [delegate toolbar: toolbar 
                            itemForItemIdentifier: identifier
                        willBeInsertedIntoToolbar: NO]];
    }

  itemIdentifiers = [delegate toolbarDefaultItemIdentifiers: toolbar];
  e = [itemIdentifiers objectEnumerator];
  while ((identifier = [e nextObject]) != nil)
    {
      [_defaultItems addObject: [delegate toolbar: toolbar 
                            itemForItemIdentifier: identifier
                        willBeInsertedIntoToolbar: NO]];
    }

  [_customizationView setToolbarItems: _allowedItems];

  /* We retain ourself to keep us alive until the palette is closed (this is 
     useful in case nobody retains us). */
  RETAIN(self);
  /* No need to retain the toolbar because it will first request us to close 
     when it goes away. */
  _toolbar = toolbar;

  [_customizationWindow makeKeyAndOrderFront: self];
}

- (void) close
{
  [_customizationWindow close];
}

- (void) paletteDidEnd: (NSNotification *)notif
{
  [_toolbar _setCustomizationPaletteIsRunning: NO];
  _toolbar = nil;

  /* We can now get rid safely of the extra retain done in -showForToolbar: */
  RELEASE(self);
}

@end
