/* 
   NSPopUpButton.m

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: June 1999
   
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

#include <gnustep/gui/config.h>
#import <Foundation/Foundation.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSFont.h>

//
// NSPopUpButton implementation
//

@implementation NSPopUpButton

///////////////////////////////////////////////////////////////
//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPopUpButton class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Initializing an NSPopUpButton 
//
- init
{
  return [self initWithFrame:NSZeroRect pullsDown:NO];
}

- (id)initWithFrame:(NSRect)frameRect
{
  return [self initWithFrame:frameRect pullsDown:NO];
}

- (id)initWithFrame:(NSRect)frameRect
	  pullsDown:(BOOL)flag
{
  NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];

  [super initWithFrame:frameRect];

  /* Create our menu */

  popb_menu = [[NSMenu alloc] initWithPopUpButton:self];

  is_up = NO;
  popb_pullsDown = flag;
  popb_selectedItem = 0;

  [super setTarget: self];

  /*
   * Set ourselves up to recieve the notification when we need to popup
   * the menu.
   */

  [defaultCenter addObserver: self
		    selector: @selector(_popup:)
			name: NSPopUpButtonWillPopUpNotification
		      object: self];

  return self;
}

- (void)setMenu:(NSMenu *)menu
{
}

- (NSMenu *)menu
{
  return popb_menu;
}

- (void)setPullsDown:(BOOL)flag
{
  popb_pullsDown = flag;
}

- (BOOL)pullsDown
{
  return popb_pullsDown;
}

- (void)setAutoenablesItems:(BOOL)flag
{
  popb_autoenableItems = flag;
}

- (BOOL)autoenablesItems
{
  return popb_autoenableItems;
}

- (void)addItemWithTitle:(NSString *)title
{
  [self insertItemWithTitle: title atIndex: [self numberOfItems]];
}

- (void)addItemsWithTitles:(NSArray *)itemTitles
{
  int i;

  for (i=0;i<[itemTitles count];i++)
    {
      [self addItemWithTitle:[itemTitles objectAtIndex:i]];
    }
}

- (void)insertItemWithTitle:(NSString *)title
		    atIndex:(int)index
{
  [popb_menu insertItemWithTitle: title
		          action: @selector(_buttonPressed:)
		   keyEquivalent: @""
			 atIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeAllItems
{
  [(NSMutableArray *)[popb_menu itemArray] removeAllObjects];

/*
  for (i=0;i<[self numberOfItems];i++)
    {
      [popb_menu removeItemAtIndex:i];
    }
*/

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeItemWithTitle:(NSString *)title
{
  [popb_menu removeItemAtIndex: [self indexOfItemWithTitle: title]];

  [self synchronizeTitleAndSelectedItem];
}

- (void)removeItemAtIndex:(int)index
{
  [popb_menu removeItemAtIndex: index];

  [self synchronizeTitleAndSelectedItem];
}

- (id <NSMenuItem>)selectedItem
{
  if (popb_selectedItem >= 0)
    return [[popb_menu itemArray] objectAtIndex: popb_selectedItem];
  else
    return nil;
}

- (NSString *)titleOfSelectedItem
{
// FIXME
  return [[[popb_menu itemArray] objectAtIndex: popb_selectedItem] title];
}

- (int)indexOfSelectedItem
{
  if (popb_selectedItem >= 0)
    return popb_selectedItem;

  return -1;
}

- (void)selectItem:(id <NSMenuItem>)anObject
{
  [self selectItemAtIndex:[self indexOfItem: anObject]];
}

- (void)selectItemAtIndex:(int)index
{
  if (index == -1)
    {
      popb_selectedItem = -1;
    }
  else
    {
      popb_selectedItem = index;
    }

  [self synchronizeTitleAndSelectedItem];
}

- (void)selectItemWithTitle:(NSString *)title
{
  [self selectItemAtIndex:[self indexOfItemWithTitle: title]];
}

- (int)numberOfItems
{
  return [popb_menu numberOfItems];
}

- (NSArray *)itemArray 
{
  return [popb_menu itemArray];
}

- (id <NSMenuItem>)itemAtIndex:(int)index
{
  return [popb_menu itemAtIndex: index];
}

- (NSString *)itemTitleAtIndex:(int)index
{
  return [[self itemAtIndex: index] title];
}

- (NSArray *)itemTitles
{
  NSMutableArray *anArray = [NSMutableArray new];
  int i;

  for (i=0;i<[self numberOfItems];i++)
    {
      [anArray addObject:[[self itemAtIndex:i] title]];
    }

  return anArray;
}

- (id <NSMenuItem>)itemWithTitle:(NSString *)title
{
  return [popb_menu itemWithTitle: title];
}

- (id <NSMenuItem>)lastItem
{
  return [[popb_menu itemArray] lastObject];
}

- (int)indexOfItem:(id <NSMenuItem>)anObject
{
  return [popb_menu indexOfItem: anObject];
}

- (int)indexOfItemWithTag:(int)tag
{
  return [popb_menu indexOfItemWithTag: tag];
}

- (int)indexOfItemWithTitle:(NSString *)title
{
  return [popb_menu indexOfItemWithTitle: title];
}

- (int)indexOfItemWithRepresentedObject:(id)anObject
{
  return [popb_menu indexOfItemWithRepresentedObject: anObject];
}

- (int)indexOfItemWithTarget:(id)target
		   andAction:(SEL)actionSelector
{
  return [popb_menu indexOfItemWithTarget: target andAction: actionSelector];
}

- (void)setPreferredEdge:(NSRectEdge)edge
{
  // urph
}

- (NSRectEdge)preferredEdge
{
  // urph
  return -1;
}

- (void)setTitle:(NSString *)aString
{
  if (!popb_pullsDown)
    {
      int aIndex = [self indexOfItemWithTitle:aString];
  
      if (aIndex >= 0)
        popb_selectedItem = aIndex;
      else
        {
         [self addItemWithTitle:aString];
          popb_selectedItem = [self indexOfItemWithTitle:aString];
         [self setNeedsDisplay:YES];
        }
    }
  else
    {
      [self setNeedsDisplay:YES];
    }
}

- (SEL)action 
{ 
  return pub_action;
}
 
- (void)setAction:(SEL)aSelector
{
  pub_action = aSelector;
}
 
- (id)target
{
  return pub_target;
}
 
- (void)setTarget:(id)anObject
{
  pub_target = anObject;
}

- (void)_buttonPressed:(id)sender
{
  popb_selectedItem = [self indexOfItemWithRepresentedObject:[sender representedObject]];

  [self synchronizeTitleAndSelectedItem];

  [self setNeedsDisplay:YES];
    
  if (pub_target && pub_action)
    [pub_target performSelector:pub_action withObject:self];

  if (popb_pullsDown)
    popb_selectedItem = 0;
}

- (void)synchronizeTitleAndSelectedItem
{
  // urph
  if (popb_selectedItem > [self numberOfItems] - 1)
    {
      popb_selectedItem = 0;
    }

  [self sizeToFit];
}

- (void)sizeToFit
{
  [[popb_menu menuView] sizeToFit];
} 

- (void)_popup:(NSNotification*)notification
{
  NSPopUpButton *popb = [notification object];
  NSRect butf;
  NSRect winf;   

  butf = [popb frame];
  butf = [[popb superview] convertRect: butf toView: nil];
  butf.origin = [[popb window] convertBaseToScreen: butf.origin];

  [[popb_menu menuView] sizeToFit];

  winf = [NSMenuWindow frameRectForContentRect: [[popb_menu menuView] frame]
                                     styleMask: [[popb_menu window] styleMask]];
  /*
   * Set popup window frame origin so that the top-left corner of the
   * window lines up with the top-left corner of this button.
   */
  winf.origin = butf.origin;
  winf.origin.y += butf.size.height - winf.size.height;
  
  /*
   * Small hack to fix line up.
   */

  winf.origin.x += 1;
  winf.origin.y -= 1;
 
//NSLog(@"butf %@", NSStringFromRect(butf));
//NSLog(@"winf %@", NSStringFromRect(winf));

  if (popb_pullsDown == NO)
    {
      winf.origin.y += (popb_selectedItem * butf.size.height);
    }

//  [[popb menu] sizeToFit];
  [[[popb menu] window] setFrame: winf display:YES];
  [[[popb menu] window] orderFront:nil];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName: NSPopUpButtonWillPopUpNotification
                    object: self
                  userInfo: nil];

  [[popb_menu menuView] mouseDown:
    [NSEvent mouseEventWithType: NSLeftMouseDown
                       location: [[popb_menu window] mouseLocationOutsideOfEventStream]
                  modifierFlags: [theEvent modifierFlags]
                      timestamp: [theEvent timestamp]
                   windowNumber: [[popb_menu window] windowNumber]
                        context: [theEvent context]
                    eventNumber: [theEvent eventNumber]
                     clickCount: [theEvent clickCount]
                       pressure: [theEvent pressure]]];

}

/*
- (void)mouseUp:(NSEvent *)theEvent
{
  NSPoint cP;

  cP = [window convertBaseToScreen: [theEvent locationInWindow]];
  cP = [popb_win convertScreenToBase: cP];
 
//NSLog(@"location x = %d, y = %d\n", (int)cP.x, (int)cP.y);
    
  [popb_view mouseUp:
    [NSEvent mouseEventWithType: NSLeftMouseUp
                       location: cP
                  modifierFlags: [theEvent modifierFlags]
                      timestamp: [theEvent timestamp]
                   windowNumber: [popb_win windowNumber]
                        context: [theEvent context]
                    eventNumber: [theEvent eventNumber]
                     clickCount: [theEvent clickCount]
                       pressure: [theEvent pressure]]];

  [popb_win orderOut: nil];
}
*/

- (NSView *)hitTest:(NSPoint)aPoint
{
  // First check ourselves
//  if ([self mouse:aPoint inRect:bounds]) return self;
  if ([self mouse:aPoint inRect: frame]) return self;

  return nil;
}

//
// Displaying
//
- (void)drawRect:(NSRect)rect
{
  id aCell;

  if ([popb_menu numberOfItems] == 0)
    {
      [[NSPopUpButtonCell new] drawWithFrame:bounds inView:self];
      return;
    }

  if (!popb_pullsDown)
    aCell  = [[popb_menu itemArray] objectAtIndex:popb_selectedItem]; 
  else
    aCell  = [[popb_menu itemArray] objectAtIndex:0]; 

  [aCell drawWithFrame:bounds inView:self]; 
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
/*
  [aCoder encodeObject: list_items];
  [aCoder encodeRect: list_rect];
  [aCoder encodeValueOfObjCType: @encode(int) at: &selected_item];
  [aCoder encodeConditionalObject: pub_target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &pulls_down];
*/
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];
/*
  [aDecoder decodeValueOfObjCType: @encode(id) at: &list_items];
  list_rect = [aDecoder decodeRect];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &selected_item];
  pub_target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &pulls_down];
*/
  return self;
}
@end
