/*
   <Title>GSToolbarView.m</title>

   <abstract>The toolbar view class.</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: January 2004
   
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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSString.h>
#include "AppKit/NSBezierPath.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSColorList.h"
#include "AppKit/NSDragging.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSPasteboard.h"
// It contains GSMovableToolbarItemPboardType declaration
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSToolbarView.h"

typedef enum {
  ToolbarViewDefaultHeight = 62,
  ToolbarViewRegularHeight = 62,
  ToolbarViewSmallHeight = 52
} ToolbarViewHeight;

static const int ClippedItemsViewWidth = 28;

// Internal
static const int current_version = 1;
static NSColorList *SystemExtensionsColors;
static NSColor *StandardBackgroundColor;
static NSColor *BackgroundColor;
static NSColor *BorderColor;


// Toolbar color extensions

static void initSystemExtensionsColors(void)
{
  NSColor *toolbarBackgroundColor;
  NSColor *toolbarBorderColor;
  NSDictionary *colors;
  
  /* Set up a dictionary containing the names of all the system extensions 
     colors as keys and with colors in string format as values. */
  toolbarBorderColor = [NSColor colorWithCalibratedRed: 0.5 
                                                 green: 0.5 
                                                  blue: 0.5 
                                                 alpha: 1.0];
  
  // Window background color by tranparency                                                 
  toolbarBackgroundColor = [NSColor clearColor]; 
  
  // Window backgound color hardcoded
  /* toolbarBackgroundColor = [NSColor colorWithCalibratedRed: 0.8 
                                                        green: 0.8 
                                                         blue: 0.8 
                                                        alpha: 1.0]; */
                                                        
  colors = [[NSDictionary alloc] initWithObjectsAndKeys: 
    toolbarBackgroundColor, @"toolbarBackgroundColor",toolbarBorderColor,
    @"toolbarBorderColor", nil];
                                                             
  SystemExtensionsColors = [NSColorList colorListNamed: @"System extensions"];
  if (SystemExtensionsColors == nil)
    {
      SystemExtensionsColors = [[NSColorList alloc] initWithName: @"System extensions"];
    }

    {
      NSEnumerator *e;
      NSString *colorKey;
      NSColor *color;
      BOOL changed = NO;

      // Set up default system extensions colors

      e = [colors keyEnumerator];
  
      while ((colorKey = (NSString *)[e nextObject])) 
        {
          if ([SystemExtensionsColors colorWithKey: colorKey])
            continue;

          color = [colors objectForKey: colorKey];
          [SystemExtensionsColors setColor: color forKey: colorKey];

          changed = YES;
        }

      if (changed)
        [SystemExtensionsColors writeToFile: nil];
    }


  /* Never released, but that's not a problem because the variables are 
     static and then will be deallocated with the class when the application
     quits. */
  StandardBackgroundColor = 
      [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
  RETAIN(StandardBackgroundColor);
  BackgroundColor = 
      [SystemExtensionsColors colorWithKey: @"toolbarBackgroundColor"];
  BorderColor = 
      [SystemExtensionsColors colorWithKey: @"toolbarBorderColor"];
  RETAIN(BackgroundColor);
  RETAIN(BorderColor);
}

@implementation NSColor (GSToolbarViewAdditions)
+ (NSColor *) toolbarBackgroundColor
{
  return [SystemExtensionsColors colorWithKey: @"toolbarBackgroundColor"];
}

+ (NSColor *) toolbarBorderColor
{
  return [SystemExtensionsColors colorWithKey: @"toolbarBorderColor"]; 
}
@end

/*
 * Toolbar related code
 */
@interface NSToolbar (GNUstepPrivate)
- (void) _build;

- (void) _concludeRemoveItem: (NSToolbarItem *)item 
         atIndex: (int)index 
         broadcast: (BOOL)broadcast;
- (int) _indexOfItem: (NSToolbarItem *)item;
- (void) _insertPassivelyItem: (NSToolbarItem *)item atIndex: (int)newIndex;
- (void) _moveItemFromIndex: (int)index 
         toIndex: (int)newIndex 
         broadcast: (BOOL)broacast;

- (void) _toolbarViewWillMoveToSuperview: (NSView *)newSuperview;

// Accessors
- (void) _setToolbarView: (GSToolbarView *)toolbarView;
- (GSToolbarView *) _toolbarView;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (void) _layout;

// Accessors
- (NSView *) _backView;
- (NSMenuItem *) _defaultMenuFormRepresentation;
- (BOOL) _isModified;
- (BOOL) _isFlexibleSpace;
@end

@interface GSToolbarButton
- (NSToolbarItem *) toolbarItem;
@end

@interface GSToolbarBackView
- (NSToolbarItem *) toolbarItem;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _handleBackViewsFrame;
- (void) _handleViewsVisibility;
- (void) _reload;
- (void) _takeInAccountFlexibleSpaces;
- (int) _insertionIndexAtPoint: (NSPoint)location;

// Accessors
- (float) _heightFromLayout;
- (NSArray *) _visibleBackViews;
- (BOOL) _usesStandardBackgroundColor;
- (void) _setUsesStandardBackgroundColor: (BOOL)standard;
@end

@interface GSToolbarClippedItemsButton : NSButton
{
  NSToolbar *_toolbar;
}

- (id) init;

// Accessors 
- (NSMenu *) returnMenu; 
/* This method cannot be called "menu" otherwise it would override NSResponder
   method with the same name. */

- (void) layout;
- (void) setToolbar: (NSToolbar *)toolbar; 
@end

@implementation GSToolbarClippedItemsButton
- (id) init
{
  NSImage *image = [NSImage imageNamed: @"common_ToolbarClippedItemsMark"];
  NSRect dummyRect = NSMakeRect(0, 0, ClippedItemsViewWidth, 100);
  // The correct height will be set by the layout method
  
  if ((self = [super initWithFrame: dummyRect]) != nil) 
    {
      [self setBordered: NO];
      [[self cell] setHighlightsBy: NSChangeGrayCellMask 
        | NSChangeBackgroundCellMask];
      [self setAutoresizingMask: NSViewNotSizable];
      [self setImagePosition: NSImageOnly];
      [image setScalesWhenResized: YES];
      // [image setSize: NSMakeSize(20, 20)];
      [self setImage: image];
      return self;
    }
  return nil;
}

/* 
 * Not really used, it is here to be used by the developer who want to adjust
 * easily a toolbar view attached to a toolbar which is not bind to a window.
 */
- (void) layout 
{
  NSSize layoutSize = NSMakeSize([self frame].size.width, 
    [[_toolbar _toolbarView] _heightFromLayout]);

  [self setFrameSize: layoutSize];
}

- (void) mouseDown: (NSEvent *)event 
{
  NSMenu *clippedItemsMenu = [self menuForEvent: event];
   
  [super highlight: YES];
   
  if (clippedItemsMenu != nil)
    {
      [NSMenu popUpContextMenu: clippedItemsMenu withEvent: event 
              forView: self];
    }
    
  [super highlight: NO];
}

- (NSMenu *) menuForEvent: (NSEvent *)event 
{
  if ([event type] == NSLeftMouseDown)
    {
      return [self returnMenu];
    }
    
  return nil;
}

- (NSMenu *) returnMenu 
{
  /* This method cannot be called "menu" otherwise it would
     override NSResponder method with the same name. */
  NSMenu *menu = [[NSMenu alloc] initWithTitle: @""];
  NSEnumerator *e;
  id item;
  NSArray *visibleItems;
  
  visibleItems = [_toolbar visibleItems];

  e = [[_toolbar items] objectEnumerator];
  while ((item = [e nextObject]) != nil)
    {
      if (![visibleItems containsObject: item])
        {
          id menuItem;
      
          menuItem = [item menuFormRepresentation];
          if (menuItem == nil)
            menuItem = [item _defaultMenuFormRepresentation];
            
          if (menuItem != nil)
            [menu addItem: menuItem];
        }
    }

  return AUTORELEASE(menu);
}

// Accessors

- (void) setToolbar: (NSToolbar *)toolbar
{
  // Don't do an ASSIGN here, the toolbar view retains us.
  _toolbar = toolbar;
}
@end

// ---

// Implementation GSToolbarView

@implementation GSToolbarView
+ (void) initialize
{
  if (self == [GSToolbarView class])
    initSystemExtensionsColors();
}

- (id) initWithFrame: (NSRect)frame
{
  if ((self = [super initWithFrame: frame]) == nil)
    {
      return nil;
    }
    
  _heightFromLayout = ToolbarViewDefaultHeight;
  [self setFrame: NSMakeRect(frame.origin.x, frame.origin.y, 
                             frame.size.width, _heightFromLayout)];
        
  _clipView = [[NSClipView alloc] initWithFrame: 
                                      NSMakeRect(0, 0, frame.size.width, 
                                                 _heightFromLayout)];
  [_clipView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [self addSubview: _clipView];
  // Adjust the clip view frame
  [self setBorderMask: GSToolbarViewTopBorder | GSToolbarViewBottomBorder 
        | GSToolbarViewRightBorder | GSToolbarViewLeftBorder]; 
  
  _clippedItemsMark = [[GSToolbarClippedItemsButton alloc] init];
  
  [self registerForDraggedTypes: 
            [NSArray arrayWithObject: GSMovableToolbarItemPboardType]];
  
  return self;
}

- (void) dealloc
{
  //NSLog(@"Toolbar view dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  RELEASE(_toolbar);
  RELEASE(_clippedItemsMark);
  RELEASE(_clipView);

  [super dealloc];
}

// Dragging related methods

- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)info
{
  NSToolbar *toolbar = [self toolbar];
  NSArray *allowedItemIdentifiers = 
    [[toolbar delegate] toolbarAllowedItemIdentifiers: toolbar];
  NSString *itemIdentifier = 
    [(NSToolbarItem *)[[info draggingSource] toolbarItem] itemIdentifier];
  
  if ([self _insertionIndexAtPoint: [info draggingLocation]] != NSNotFound
    && [allowedItemIdentifiers containsObject: itemIdentifier]);
    {
      return NSDragOperationGeneric;
    }
        
  return NSDragOperationNone;
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)info
{
  NSToolbar *toolbar = [self toolbar];
  NSArray *allowedItemIdentifiers = 
    [[toolbar delegate] toolbarAllowedItemIdentifiers: toolbar];
  NSString *itemIdentifier = 
    [(NSToolbarItem *)[[info draggingSource] toolbarItem] itemIdentifier];
  
  if ([self _insertionIndexAtPoint: [info draggingLocation]] != NSNotFound
    && [allowedItemIdentifiers containsObject: itemIdentifier]);
    {
      return NSDragOperationGeneric;
    }
        
  return NSDragOperationNone;
}

- (void) draggingEnded: (id <NSDraggingInfo>)info
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSString *str = [pboard stringForType: [[pboard types] objectAtIndex: 0]];
  int index = [str intValue];
  NSToolbar *toolbar = [self toolbar];
  
  [toolbar _concludeRemoveItem: 
    [[info draggingSource] toolbarItem] atIndex: index broadcast: YES];
}

- (void) draggingExited: (id <NSDraggingInfo>)info
{
  // Nothing to do
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)info
{
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)info
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSString *str = [pboard stringForType: [[pboard types] objectAtIndex: 0]];
  int index = [str intValue];
  NSToolbar *toolbar = [self toolbar];
  NSToolbarItem *item = [[info draggingSource] toolbarItem];
  int newIndex = [self _insertionIndexAtPoint: [info draggingLocation]]; 
  // Calculate the index
      
  [toolbar _insertPassivelyItem:item atIndex: index];
  RELEASE(item);
  [toolbar _moveItemFromIndex: index toIndex: newIndex broadcast: YES]; 
  
  return YES;
}

- (void) concludeDragOperation: (id <NSDraggingInfo>)info
{
  // Nothing to do currently
}

// More overrided methods

- (void) drawRect: (NSRect)aRect
{
  NSRect viewFrame = [self frame];
  
  // We draw the background
  if (![BackgroundColor isEqual: [NSColor clearColor]])
    {
      [BackgroundColor set];
      [NSBezierPath fillRect: aRect];
    }
  
  // We draw the border
  [BorderColor set];
  if (_borderMask & GSToolbarViewBottomBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 0.5) 
                    toPoint: NSMakePoint(viewFrame.size.width, 0.5)];
    }
  if (_borderMask & GSToolbarViewTopBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 
                                                     viewFrame.size.height - 0.5) 
                    toPoint: NSMakePoint(viewFrame.size.width, 
                                         viewFrame.size.height -  0.5)];
    }
  if (_borderMask & GSToolbarViewLeftBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0) 
                    toPoint: NSMakePoint(0.5, viewFrame.size.height)];
    }
  if (_borderMask & GSToolbarViewRightBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5,0)
                    toPoint: NSMakePoint(viewFrame.size.width - 0.5, 
                                         viewFrame.size.height)];
    }
  
  [super drawRect: aRect];
}

- (BOOL) isOpaque
{
  if ([BackgroundColor isEqual: [NSColor clearColor]])
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

- (void) windowDidResize: (NSNotification *)notification
{ 
  if ([self superview] == nil) 
    return;
  
  [self _reload];
}

- (void) viewWillMoveToSuperview: (NSView *)newSuperview
{ 
  [super viewWillMoveToSuperview: newSuperview];
  
  [_toolbar _toolbarViewWillMoveToSuperview: newSuperview]; 
  // Allow to update the validation system which is window specific 
}

- (void) viewDidMoveToWindow
{ 
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  /* NSView method called when a view is moved to a window (NSView has a
     variable _window). */
  [super viewDidMoveToWindow]; 
  
  [nc removeObserver: self name: NSWindowDidResizeNotification object: nil];
  [nc addObserver: self selector: @selector(windowDidResize:) 
                            name: NSWindowDidResizeNotification 
                          object: _window];
}

// Accessors

- (unsigned int) borderMask
{
  return _borderMask;
}

- (NSToolbar *) toolbar
{
  return _toolbar;
}

- (void) setBorderMask: (unsigned int)borderMask
{
  NSRect toolbarViewFrame = [self frame];
  NSRect rect = NSMakeRect(0, 0, toolbarViewFrame.size.width, 
                           toolbarViewFrame.size.height);
  
  _borderMask = borderMask;
  
  // Take in account the border
  if (_borderMask & GSToolbarViewBottomBorder)
    {
      rect = NSMakeRect(rect.origin.x, ++rect.origin.y, rect.size.width, 
                        --rect.size.height);
    }

  if (_borderMask & GSToolbarViewTopBorder)
    {
      rect = NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, 
                        --rect.size.height); 
    }
    
  if (_borderMask & GSToolbarViewLeftBorder)
    {
      rect = NSMakeRect(++rect.origin.x, rect.origin.y, --rect.size.width, 
                        rect.size.height);
    }
    
  if (_borderMask & GSToolbarViewRightBorder)
    {
      rect = NSMakeRect(rect.origin.x, rect.origin.y, --rect.size.width, 
                        rect.size.height);
    }
    
  [_clipView setFrame: rect];
}

- (void) setToolbar: (NSToolbar *)toolbar 
{
  if (_toolbar == toolbar)
    return;

  // We unset the toolbar view from the previous toolbar    
  [_toolbar _setToolbarView: nil];
  ASSIGN(_toolbar, toolbar);
  // We set the toolbar view on the new toolbar
  [_toolbar _setToolbarView: self];

  [_clippedItemsMark setToolbar: _toolbar];
  // Load the toolbar in the toolbar view
  [self _reload];
}

- (NSColor *) standardBackgroundColor
{
  return StandardBackgroundColor;
}

// Private methods

- (void) _handleBackViewsFrame
{
  NSEnumerator *e = [[_toolbar items] objectEnumerator];
  NSToolbarItem *item;
  NSView *itemBackView;
  NSRect itemBackViewFrame;
  float x = 0;
  float newHeight = 0;
  // ---
  NSArray *subviews = [self subviews];
  
  //_heightFromLayout = 0;

  while ((item = [e nextObject]) != nil) 
    {
      itemBackView = [item _backView];
      if ([subviews containsObject: itemBackView] == NO
        || [item _isModified] 
        || [item _isFlexibleSpace])
        {
          // When a label is changed, _isModified returns YES to let us known we
          // must recalculate the text length and then the size for the edited
          // item back view
          [item _layout];
        }
      
      itemBackViewFrame = [itemBackView frame];
      [itemBackView setFrame: NSMakeRect(x, itemBackViewFrame.origin.y, 
        itemBackViewFrame.size.width, itemBackViewFrame.size.height)];
        
      x += [itemBackView frame].size.width;
      
      if (itemBackViewFrame.size.height > newHeight)
       newHeight = itemBackViewFrame.size.height;
    }
    
  if (newHeight > 0)
    _heightFromLayout = newHeight;
}

- (void) _handleViewsVisibility
{
  NSArray *items = [_toolbar items];
  
  /* The back views which are associated with each toolbar item (the toolbar
     items doesn't reflect the toolbar view content) */
  NSArray *backViews = [items valueForKey: @"_backView"];
  
  /* The back views which will be visible in the toolbar view (when
     _handleViewsVisibility will be terminated). */
  NSArray *visibleBackViews;
  
  NSArray *subviews;
  NSEnumerator *e;
  NSView *backView;
  NSRect clipViewFrame;
  
  // First, we resize
  [self _handleBackViewsFrame];
  [self _takeInAccountFlexibleSpaces];
  
  // Then we retrieve the back views which should be visible now that the resize
  // process has been taken in account
  visibleBackViews = [self _visibleBackViews];
  
  // ---
     
  // We remove each back view associated with a removed toolbar item
 
  e = [[_clipView subviews] objectEnumerator];
  
  while ((backView = [e nextObject]) != nil) 
    {
      if ([backViews containsObject: backView] == NO)
        {
          if ([backView superview] != nil) 
            [backView removeFromSuperview];
        }
    }
      
  // We add each backView associated with an added toolbar item
  
  e = [backViews objectEnumerator];
  subviews = [_clipView subviews];
 
  while ((backView = [e nextObject]) != nil) 
  {
    if ([subviews containsObject: backView] == NO)
      {
        [_clipView addSubview: backView];
      }
  }
  
  // ---
     
  /* We manage the clipped items view in the case it should become visible or
     invisible */
  
  clipViewFrame = [_clipView frame];  
  
  if ([visibleBackViews count] < [backViews count])
    {
      NSView *lastVisibleBackView = [visibleBackViews lastObject];
      float width = 0;
      
      // Resize the clip view
      
      if (lastVisibleBackView != nil)
        width = NSMaxX([lastVisibleBackView frame]);  
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x,
                                      clipViewFrame.origin.y, 
                                      width,
                                      clipViewFrame.size.height)]; 
        
      // Adjust the clipped items mark frame handling   
      
      [_clippedItemsMark layout];
      
      clipViewFrame = [_clipView frame]; // We get the new _clipView frame
      [_clippedItemsMark setFrameOrigin: NSMakePoint(
        [self frame].size.width - ClippedItemsViewWidth, clipViewFrame.origin.y)];
        
      // ---
        
      if ([_clippedItemsMark superview] == nil)       
        [self addSubview: _clippedItemsMark];  
      
    }
  else if (([_clippedItemsMark superview] != nil) 
    && ([visibleBackViews count] == [backViews count])) 
    {      
      [_clippedItemsMark removeFromSuperview];
      
      [_clipView setFrame: NSMakeRect(clipViewFrame.origin.x, 
                                      clipViewFrame.origin.y, 
                                      [self frame].size.width, 
                                      clipViewFrame.size.height)]; 
    }
}

- (void) _reload 
{  
  [self _handleViewsVisibility]; 
  [self setNeedsDisplay: YES];
}

- (void) _takeInAccountFlexibleSpaces
{
  NSArray *items = [_toolbar items];
  NSEnumerator *e = [items objectEnumerator];
  NSToolbarItem *item;
  NSView *backView; 
  NSRect lastBackViewFrame;
  float lengthAvailable;
  unsigned int flexibleSpaceItemsNumber = 0;
  BOOL mustAdjustNext = NO;
  float x = 0;
  
  if ([items count] == 0)
    return; 
  
  lastBackViewFrame = [[[items lastObject] _backView] frame];
  lengthAvailable = [self frame].size.width - NSMaxX(lastBackViewFrame);

  if (lengthAvailable < 1)
    return;
  
  while ((item = [e nextObject]) != nil) 
  {
    if ([item _isFlexibleSpace])
    {
      flexibleSpaceItemsNumber++;
    }
  }
  
  if (lengthAvailable < flexibleSpaceItemsNumber)
    return; 
  
  e = [items objectEnumerator];
  while ((item = [e nextObject]) != nil)
  {
    backView = [item _backView];
    if ([item _isFlexibleSpace])
    {
      NSRect backViewFrame = [backView frame];
      
      [backView setFrame: NSMakeRect(x, backViewFrame.origin.y,
        lengthAvailable / flexibleSpaceItemsNumber, 
        backViewFrame.size.height)];
      mustAdjustNext = YES;
    }
    else if (mustAdjustNext)
    {
      NSRect backViewFrame = [backView frame];
      
      [backView setFrame: NSMakeRect(x, backViewFrame.origin.y,
        backViewFrame.size.width, backViewFrame.size.height)];
    }
    x += [backView frame].size.width;
  }
  
}

- (int) _insertionIndexAtPoint: (NSPoint)location
{
  id hitView = [self hitTest: location];
  NSRect hitViewFrame = [hitView frame];
  int index;
  
  if ((hitView != nil)
    && ([hitView isKindOfClass: NSClassFromString(@"GSToolbarButton")] 
    || [hitView isKindOfClass: NSClassFromString(@"GSToolbarBackView")]))
    {
      index = [_toolbar _indexOfItem: [hitView toolbarItem]];
      if (location.x - hitViewFrame.origin.x > hitViewFrame.size.width / 2)
        index++;
      
      return index; 
    }
  return NSNotFound;
}

// Accessors private methods

- (float) _heightFromLayout
{    
  float height = _heightFromLayout;
  
  if (_borderMask & GSToolbarViewBottomBorder)
    {
      height++;
    }

  if (_borderMask & GSToolbarViewTopBorder)
    {
      height++; 
    }
      
  return height;
}

/*
 * Will return the visible (not clipped) back views in the toolbar view even
 * when the toolbar is not visible.
 * May be should be renamed _notClippedBackViews method.
 */
- (NSArray *) _visibleBackViews 
{
  NSArray *items = [_toolbar items];
  NSView *backView;
  int i, n = [items count];
  float backViewsWidth = 0, toolbarWidth = [self frame].size.width;

  [_visibleBackViews release];
  _visibleBackViews = [[NSMutableArray alloc] init];
  
  for (i = 0; i < n; i++)
    {
      backView = [[items objectAtIndex:i] _backView];
  
      backViewsWidth += [backView frame].size.width;

      if ((backViewsWidth + ClippedItemsViewWidth <= toolbarWidth)
        || (i == n - 1 && backViewsWidth <= toolbarWidth))
        {
          [_visibleBackViews addObject: backView];
        }     
    }
  
  return _visibleBackViews;
  
}

- (BOOL) _usesStandardBackgroundColor
{
  return [BackgroundColor isEqual: [self standardBackgroundColor]];
}

- (void) _setUsesStandardBackgroundColor: (BOOL)standard
{
  if (standard)
    {
      RELEASE(BackgroundColor);
      BackgroundColor = [self standardBackgroundColor];
    }
  else
    {
      BackgroundColor = [NSColor clearColor];
      RETAIN(BackgroundColor);
    }
}

@end
