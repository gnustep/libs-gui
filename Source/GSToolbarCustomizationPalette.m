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

#include "AppKit/NSNibLoading.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSToolbarItem.h"
#include "GNUstepGUI/GSFlow.h"
#include "GNUstepGUI/GSToolbar.h"
#include "GNUstepGUI/GSToolbarCustomizationPalette.h"

#define DEBUG_LEVEL @"Toolbar"

/* Private methods */

@interface GSToolbar (Private)
- (void) _setCustomizationPaletteIsRunning: (BOOL)isRunning;
@end

@interface NSToolbarItem (Private)
- (void) _layout;
@end

/* Customization View */

// TODO: Make subclass of GSFlow once GSFlow will be refactored as a subclass
// of NSView
@interface GSToolbarCustomizationView : NSView
{
  GSFlow *flowLayout;
}

- (void) setToolbarItems: (NSArray *)items;

@end

@implementation GSToolbarCustomizationView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];

  if (self != nil)
    {
      flowLayout = [[GSFlow alloc] initWithViews: nil viewContainer: self];
      NSDebugLLog(DEBUG_LEVEL, @"New toolbar customization view with flow %@", 
        flowLayout);
    }

  return self;
}

- (void) dealloc
{
  DESTROY(flowLayout);

  [super dealloc];
}

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

- (void) setToolbarItems: (NSArray *)items
{
  NSArray *paletteItems = [self paletteItemsWithToolbarItems: items];
  NSArray *itemViews = [paletteItems valueForKey: @"_backView"];
  NSEnumerator *e = [itemViews objectEnumerator];
  NSView *itemView = nil;

  NSDebugLLog(DEBUG_LEVEL, @"Will insert the views %@ of toolbar items %@ in \
    customization view", itemViews, paletteItems);

  while ((itemView = [e nextObject]) != nil)
    {
      if (itemView != nil)
        {
          [flowLayout addView: itemView];
        }
      else
        {
          NSLog(@"Toolbar item view %@ will not be visible in the customization \
            view or if you insert it in a toolbar now. The view is already in use \
            in superview %@ or does not implement NSCoding protocol", itemView, [itemView superview]);
        }
    }

  [flowLayout setUpViewTree];
  [flowLayout layout];

  NSDebugLLog(DEBUG_LEVEL, @"Views displayed by flow in %@: %@", 
    [flowLayout viewContainer], [[flowLayout viewContainer] subviews]);
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
          NSLog(@"Failed to load gorm for GSToolbarCustomizationPalette");
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
- (void) showForToolbar: (GSToolbar *)toolbar
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
  identifier = nil;

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

//   NSView *view = _view;
//   GSToolbar *toolbar = [self toolbar];
//   /* If the toolbar item has a custom view and the item is in use in the 
//      toolbar, this view has already a superview. We need to make a copy of it 
//      in order to be able to put it in the customization view. 
//      As a safety measure, we try to return a copy of any view which has a 
//      superview already set. */
// 
//   if (([view superview] != nil || [toolbar customizationPaletteIsRunning])
//     && [view respondsToSelector: @selector(copyWithZone:)])
//     {
//       view = [_view copyWithZone: NULL];
//       AUTORELEASE(view);
//     }
//   else
//     {
//       NSLog(@"Toolbar item view %@ will not be visible in the customization \
//         view or if you insert it in a toolbar now. The view is already in use \
//         in superview %@", _view, [view superview]);
//     }
