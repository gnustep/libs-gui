/* 
   NSMenu.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999

   A completely rewritten version of the original source by Scott Christley.
   and: 
   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   and: 
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   
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
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSMatrix.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSMenuItemCell.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSScreen.h>

static NSZone *menuZone = NULL;

static NSString* NSMenuLocationsKey = @"NSMenuLocations";

@implementation NSMenu

// Class Methods
+ (void) initialize
{
  if (self == [NSMenu class])
    {
      [self setVersion: 1];
    }
}

+ (void) setMenuZone: (NSZone *)zone
{
  menuZone = zone;
}

// Methods.

- (id) init
{
  return [self initWithTitle: @"Menu"];
  //return self;
}

- (id) initWithPopUpButton: (NSPopUpButton *)popb
{
  NSRect aRect;
  NSRect winRect = {{0, 0}, {20, 17}};

  [super init];

  // Create an array to store out cells.
  menu_items = [NSMutableArray new];

  // Create a NSMenuView to draw our cells.
  aRect = [popb frame];

  menu_view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)
				       cellSize: aRect.size];

  // Set ourself as the menu for this view.
  [menu_view setMenu: self];

  // We have no supermenu.
  menu_supermenu = nil;
  menu_is_tornoff = NO;
  menu_is_visible = NO;
  menu_follow_transient = NO;
  menu_is_beholdenToPopUpButton = YES;
  ASSIGN(menu_popb, popb);

  menu_changed = YES;
  /* According to the spec, menus do autoenable by default */
  menu_autoenable = YES;

  aWindow = [[NSMenuWindow alloc] initWithContentRect:winRect
                                styleMask: NSBorderlessWindowMask
                                backing: NSBackingStoreRetained
                                defer: NO];
  [[aWindow contentView] addSubview:menu_view];

  return self;
}

- (id) popupButton
{
  return menu_popb;
}

- (BOOL) _isBeholdenToPopUpButton
{
  return menu_is_beholdenToPopUpButton;
}

- (id) initWithTitle: (NSString *)aTitle
{
  NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
  NSApplication* theApp = [NSApplication sharedApplication];
  NSRect winRect = {{0, 0}, {20, 17}};
  //float titleWidth = 0;

  [super init];

  // Keep the title.
  ASSIGN(menu_title, aTitle);

  // Create an array to store out cells.
  menu_items = [NSMutableArray new];

  // Create a NSMenuView to draw our cells.
  menu_view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)];

  // Set ourself as the menu for this view.
  [menu_view setMenu: self];

  // We have no supermenu.
  menu_supermenu = nil;
  menu_is_tornoff = NO;
  menu_is_visible = NO;
  menu_follow_transient = NO;
  menu_is_beholdenToPopUpButton = NO;

  menu_changed = YES;
  /* According to the spec, menus do autoenable by default */
  menu_autoenable = YES;

  aWindow = [[NSMenuWindow alloc] initWithContentRect:winRect
                                styleMask: NSBorderlessWindowMask
                                backing: NSBackingStoreRetained
                                defer: NO];
  bWindow = [[NSMenuWindow alloc] initWithContentRect:winRect
                                styleMask: NSBorderlessWindowMask
                                backing: NSBackingStoreRetained
                                defer: NO];
  
  titleView = [NSMenuWindowTitleView new];
  [titleView setFrameOrigin: NSMakePoint(0, winRect.size.height-22)];
  [titleView setFrameSize: NSMakeSize (winRect.size.width, 22)];
  [[aWindow contentView] addSubview:menu_view];
  [[aWindow contentView] addSubview:titleView];
  [titleView setMenu: self];
 
  [defaultCenter addObserver: self
                    selector: @selector(_showTornOffMenuIfAny:)
                    name: NSApplicationWillFinishLaunchingNotification 
                    object: theApp];
  return self;
}

/*
 * - (void)insertItem: (id <NSMenuItem>)newItem
 *            atIndex: (int)index
 *
 * This method has been modified to convert anything that conforms to the
 * <NSMenuItem> Protocol into a NSMenuItemCell which will be added to the
 * items array.
 *
 * Blame: Michael
 */

- (void) insertItem: (id <NSMenuItem>)newItem
	    atIndex: (int)index
{
  NSNotificationCenter *nc;
  NSDictionary *d;

  if ([(id)newItem conformsToProtocol: @protocol(NSMenuItem)])
    {
      if ([(id)newItem isKindOfClass: [NSMenuItemCell class]]
	  || [(id)newItem isKindOfClass: [NSPopUpButtonCell class]])
        {
	  nc = [NSNotificationCenter defaultCenter];
  	  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:index]
					  forKey: @"NSMenuItemIndex"];
  	  [nc postNotificationName: NSMenuDidAddItemNotification
                    	    object: self
                          userInfo: d];

          [menu_items insertObject: newItem atIndex: index];
	}
      else
        {

	  // The item we received conformed to <NSMenuItem> which is good,
	  // but it wasn't an NSMenuItemCell which is bad. Therefore, we
	  // loop through the system and create an NSMenuItemCell for
	  // this bad boy.

          [self insertItemWithTitle: [newItem title]
			     action: [newItem action]
		      keyEquivalent: [newItem keyEquivalent]
			    atIndex: index];
        }
    }
  else
    NSLog(@"You must use an object that conforms to NSMenuItem.\n");

  menu_changed = YES;
}

- (id <NSMenuItem>) insertItemWithTitle: (NSString *)aString
			         action: (SEL)aSelector
			  keyEquivalent: (NSString *)charCode 
			        atIndex: (unsigned int)index
{
  id anItem;

  if (menu_is_beholdenToPopUpButton)
    {
      anItem = [NSPopUpButtonCell new];
      [anItem setTarget: menu_popb];
    }
  else
    anItem = [NSMenuItemCell new];

  [anItem setTitle: aString];
  [anItem setAction: aSelector];
  [anItem setKeyEquivalent: charCode];

  // Insert the new item into the stream.

  [self insertItem:anItem atIndex:index];

  // For returns sake.

  return anItem;
}

- (void) addItem: (id <NSMenuItem>)newItem
{
  [self insertItem: newItem atIndex: [menu_items count]];
}

- (id <NSMenuItem>) addItemWithTitle: (NSString *)aString
			      action: (SEL)aSelector 
		       keyEquivalent: (NSString *)keyEquiv
{
  return [self insertItemWithTitle: aString
			    action: aSelector
		     keyEquivalent: keyEquiv
			   atIndex: [menu_items count]];
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  [self removeItemAtIndex:[menu_items indexOfObject: anItem]];
}

- (void) removeItemAtIndex: (int)index
{
  NSNotificationCenter *nc;
  NSDictionary *d;
  id anItem = [menu_items objectAtIndex:index];

  if (!anItem)
    return;

  if ([(NSMenuItemCell *)anItem isKindOfClass: [NSMenuItemCell class]]
	  || [(id)anItem isKindOfClass: [NSPopUpButtonCell class]])
    {
      nc = [NSNotificationCenter defaultCenter];
      d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:index]
				      forKey: @"NSMenuItemIndex"];
      [nc postNotificationName: NSMenuDidRemoveItemNotification
                        object: self
                      userInfo: d];

      [menu_items removeObjectAtIndex: index];
    }
  else
    {
      NSLog(@"You must use an NSMenuItemCell, or a derivative thereof.\n");
    }

  menu_changed = YES;
}

- (void) itemChanged: (id <NSMenuItem>)anObject
{
  // another nebulous method in NSMenu. Is this correct?

  NSNotificationCenter *nc;
  NSDictionary *d;

  nc = [NSNotificationCenter defaultCenter];
  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:[self indexOfItem: anObject]]
                                  forKey: @"NSMenuItemIndex"];
  [nc postNotificationName: NSMenuDidChangeItemNotification
                    object: self
                  userInfo: d];  
}

- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  unsigned i, count = [menu_items count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [menu_items objectAtIndex: i];
      if ([menuCell tag] == aTag)
        return menuCell;
    }
  return nil;
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  unsigned i, count = [menu_items count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [menu_items objectAtIndex: i];
      if ([[menuCell title] isEqual: aString])
        return menuCell;
    }
  return nil;
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  if (index >= [menu_items count] || index < 0)
	[NSException raise:NSRangeException format:@"menu index %i out of range",
	index];
  return [menu_items objectAtIndex: index];
}

- (int) numberOfItems
{
  return [menu_items count];
}

- (NSArray *) itemArray
{
  return (NSArray *)menu_items;
}

- (int) indexOfItem: (id <NSMenuItem>)anObject
{
  if (![(NSMenuItemCell *)anObject isKindOfClass: [NSMenuItemCell class]]
	  || ![(id)anObject isKindOfClass: [NSPopUpButtonCell class]])
    {
      NSLog(@"You must use an NSMenuItemCell, or a derivative thereof.\n");
      return -1;
    }
  return [menu_items indexOfObject: anObject];
}

- (int) indexOfItemWithTitle: (NSString *)aTitle
{
  id anItem;

  if ((anItem = [self itemWithTitle: aTitle]))
    return [menu_items indexOfObject: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTag: (int)aTag
{
  id anItem;

  if ((anItem = [self itemWithTag: aTag]))
    return [menu_items indexOfObject: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTarget: (id)anObject
		   andAction: (SEL)actionSelector
{
  return -1;
}

- (int) indexOfItemWithRepresentedObject: (id)anObject
{
  int i;

  for (i=0;i<[menu_items count];i++)
    {
      if ([[[menu_items objectAtIndex:i] representedObject]
	isEqual:anObject])
	{
	  return i;
	}
    }

  return -1;
}

- (int) indexOfItemWithSubmenu: (NSMenu *)anObject
{
  int i;

  for (i=0;i<[menu_items count];i++)
    {
      if ([[[menu_items objectAtIndex:i] title]
	isEqual:[anObject title]])
	{
	  return i;
	}
    }
  
  return -1;
}

// Dealing with submenus.

- (void) setSubmenu: (NSMenu *)aMenu
	    forItem: (id <NSMenuItem>) anItem 
{
  [anItem setTarget: aMenu];
  [anItem setAction: @selector(submenuAction:)];
  if (aMenu)
    aMenu->menu_supermenu = self;

  ASSIGN(aMenu->menu_title, [anItem title]);

  // notification that the menu has changed.
}

- (void) submenuAction: (id)sender
{
}

- (NSMenu *) attachedMenu
{
  return menu_attached_menu;
}

- (BOOL) isAttached
{
  // eh?
  return menu_supermenu && [menu_supermenu attachedMenu] == self;
}

- (BOOL) isTornOff
{
  return menu_is_tornoff;
}

- (NSPoint) locationForSubmenu: (NSMenu*)aSubmenu
{
  NSRect frame;
  NSRect submenuFrame;
  NSWindow *win_link;

  if (![self isFollowTransient])
    {
      frame = [aWindow frame];
      win_link = aWindow;
    }
  else
    {
      frame = [bWindow frame];
      win_link = bWindow;
    }
            
  if (aSubmenu)
    {
      submenuFrame = [aSubmenu->aWindow frame];
    }
  else
    submenuFrame = NSZeroRect;

  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) == GSWindowMakerInterfaceStyle)
    {
      NSRect aRect = [menu_view rectOfItemAtIndex:[self indexOfItemWithTitle:[aSubmenu title]]];
      NSPoint subOrigin = [win_link convertBaseToScreen: NSMakePoint(aRect.origin.x, aRect.origin.y)];

      return NSMakePoint (frame.origin.x + frame.size.width + 1,
                         subOrigin.y - (submenuFrame.size.height - 42));
    }
  else
    {
      return NSMakePoint (frame.origin.x + frame.size.width + 1,
                          frame.origin.y + frame.size.height
                          - submenuFrame.size.height);
    }
}

- (NSMenu *) supermenu
{
  return menu_supermenu;
}

- (void) setSupermenu: (NSMenu *)supermenu
{
  ASSIGN(menu_supermenu, supermenu);
}

- (void) setAutoenablesItems: (BOOL)flag
{
  menu_autoenable = flag;
}

- (BOOL) autoenablesItems
{
  return menu_autoenable;
}

- (void) update
{
  // FIXME: needs to be checked.
  id		cells;
  unsigned	i, count;
  id		theApp = [NSApplication sharedApplication];

  if (menu_changed)
    [self sizeToFit];

  if (![self autoenablesItems])
    return;
      
  count = [menu_items count];  
      
  /* Temporary disable automatic displaying of menu */
  [self setMenuChangedMessagesEnabled: NO];
      
  for (i = 0; i < count; i++)
    {
      id<NSMenuItem>	cell = [menu_items objectAtIndex: i];
      SEL		action = [cell action];
      id		target;
      NSWindow		*keyWindow;
      NSWindow		*mainWindow;
      id		responder;
      id		delegate;
      id		validator = nil;
      BOOL		 wasEnabled = [cell isEnabled];
      BOOL		shouldBeEnabled;
  
      /* Update the submenu items if any */
      if ([cell hasSubmenu])
        [[cell target] update];
      
      /* If there is no action - there can be no validator for the cell */
      if (action)
        {
          /* If there is a target use that for validation (or nil). */
          if ((target = [cell target]))
            {
              if ([target respondsToSelector: action])
                {  
                  validator = target;
                }
            }
          else
            {
              validator = [theApp targetForAction: action];
            }
        }
      
      if (validator == nil)
        {
          shouldBeEnabled = NO;
        }
      else if ([validator respondsToSelector: @selector(validateMenuItem:)])
        {
          shouldBeEnabled = [validator validateMenuItem: cell];
        }
      else
        {
          shouldBeEnabled = YES;
        }
             
      if (shouldBeEnabled != wasEnabled)
        {
          [cell setEnabled: shouldBeEnabled];
	  [[self window] display];
//          [menu_view setNeedsDisplay:YES];
//	  [menu_view setNeedsDisplayInRect:[menu_view rectOfItemAtIndex:i]];
// FIXME
//          [menuCells setNeedsDisplayInRect: [menuCells cellFrameAtRow: i]];
        }
    }
          
  /* Reenable displaying of menus */
  [self setMenuChangedMessagesEnabled: YES];
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  unsigned      i;
  unsigned      count = [menu_items count];
  NSEventType   type = [theEvent type];
         
  if (type != NSKeyDown && type != NSKeyUp) 
    return NO;
             
  for (i = 0; i < count; i++)
    {
      id<NSMenuItem> cell = [menu_items objectAtIndex: i];
                                    
      if ([cell hasSubmenu])
        {
          if ([[cell target] performKeyEquivalent: theEvent])
            {
              /* The event has been handled by a cell in submenu */
              return YES;
            }
        }
      else
        {
          if ([[cell keyEquivalent] isEqual: 
            [theEvent charactersIgnoringModifiers]])
            {
              [menu_view lockFocus];
              [(id)cell performClick: self];
              [menu_view unlockFocus];
              return YES;           
            }
        }
    }
  return NO; 
}

- (void)  performActionForItem: (id <NSMenuItem>)cell
{
  NSNotificationCenter *nc;
  NSDictionary *d;

  if (![cell isEnabled])
    return;
  
  nc = [NSNotificationCenter defaultCenter];
  d = [NSDictionary dictionaryWithObject: cell forKey: @"MenuItem"];
  [nc postNotificationName: NSMenuWillSendActionNotification
                    object: self
                  userInfo: d];
  [[NSApplication sharedApplication] sendAction: [cell action]
                                             to: [cell target]
                                           from: cell];
  [nc postNotificationName: NSMenuDidSendActionNotification
                                    object: self
                                  userInfo: d];
}

- (void) setTitle: (NSString*)aTitle
{
  ASSIGN(menu_title, aTitle);
  [self sizeToFit];
}
  
- (NSString*) title
{
  return menu_title;
}

- (void) setMenuRepresentation: (id)menuRep
{
  ASSIGN(menu_rep, menuRep);
}

- (id) menuRepresentation
{
  return menu_rep;
}

- (void) setMenuChangedMessagesEnabled: (BOOL)flag
{ 
  menu_ChangedMessagesEnabled = flag;
}
 
- (BOOL) menuChangedMessagesEnabled
{
  return menu_ChangedMessagesEnabled;
}

- (void) sizeToFit
{
  NSRect mFrame;
  NSSize size;


  //-setTitleWidth: ends up calling -sizeToFit.
  [menu_view setTitleWidth:[[NSFont systemFontOfSize:12] widthOfString:menu_title]];
  mFrame = [menu_view frame];

  size.width = mFrame.size.width;
  size.height = mFrame.size.height;

  if (!menu_is_beholdenToPopUpButton)
    {
      size.height += 22;
      [aWindow setContentSize: size];
      [bWindow setContentSize: size];
      [menu_view setFrameOrigin: NSMakePoint(0, 0)];
      [titleView setFrame: NSMakeRect(0,size.height-22,size.width,22)];
    }
  else
    {
      [aWindow setContentSize: size];
    }

  [aWindow display];

  menu_changed = NO;
}

- (void) helpRequested: (NSEvent *)event
{
  // Won't be implemented until we have NSHelp*
}

// NSCoding
- (id) initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

//NSCopying
- (id) copyWithZone: (NSZone*)zone
{
  return self;
}
@end

@implementation NSMenu (GNUstepPrivate)

- (void)_showTornOffMenuIfAny: (NSNotification*)notification
{
NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
NSDictionary* menuLocations = [defaults objectForKey: NSMenuLocationsKey];
NSString* key;
NSArray* array;
      
    if ([[NSApplication sharedApplication] mainMenu] == self)
        key = nil;                                  // Ignore the main menu
    else
        key = [self title];
                                                                 
    if (key)
        {
        array = [menuLocations objectForKey: key];
        if (array && [array isKindOfClass: [NSArray class]])
            {
	    [titleView windowBecomeTornOff];
            [self _setTornOff:YES];
            [self display];
            }
        }
}

- (BOOL) isFollowTransient
{
  return menu_follow_transient;
} 

- (void) _setTornOff:(BOOL)flag
{ 
  menu_is_tornoff = flag;

  [[[self supermenu] menuView] setHighlightedItemIndex:-1];

/*
  if (flag)
    {
      if (menu_supermenu)
        {
          menu_supermenu->menu_attached_menu = nil;
          menu_supermenu = nil;
        }
    }
*/
}

- (void) _performMenuClose:(id)sender
{
  NSUserDefaults* defaults;
  NSMutableDictionary* menuLocations;
  NSString* key;

  [self _setTornOff:NO];
  [self close];
  [titleView _releaseCloseButton];

  defaults = [NSUserDefaults standardUserDefaults];
  menuLocations = [[[defaults objectForKey: NSMenuLocationsKey]
			mutableCopy] autorelease];

  key = [self title];                             // Remove window's position$
  if (key)                                        // info from defaults db
    {
      [menuLocations removeObjectForKey: key];
      [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
      [defaults synchronize];
    }
} 

- (void) _rightMouseDisplay
{
  // TODO: implement this method 
  ;
}

- (void) display
{
    if (menu_changed)
        [self sizeToFit];

    if (menu_supermenu && ![self isTornOff])      // query super menu for
      {                                           // position
        [aWindow setFrameOrigin:[menu_supermenu locationForSubmenu: self]];
        menu_supermenu->menu_attached_menu = self;
      }
    else
      {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary* menuLocations = [defaults
                                        objectForKey: NSMenuLocationsKey];
        NSString* key;
        NSArray* array;
        NSPoint origin; 
      
        if ([[NSApplication sharedApplication] mainMenu] == self)
            key = @"Main menu";
        else
            key = [self title];
      
        if (key)
            {
            array = [menuLocations objectForKey: key];
            if (array && [array isKindOfClass: [NSArray class]])
                {
                origin.x = [[array objectAtIndex: 0] floatValue];
                origin.y = [[array objectAtIndex: 1] floatValue];
                [aWindow setFrameOrigin: origin];
                }
            else
              {
	        float aPoint = [[NSScreen mainScreen] frame].size.height - [aWindow frame].size.height;

                [aWindow setFrameOrigin:NSMakePoint(0,aPoint)];
                [bWindow setFrameOrigin:NSMakePoint(0,aPoint)];
              }
            }
      }

  [self submenuAction: nil];
  
  menu_is_visible = YES;
  [aWindow orderFront:nil];
}

- (void) displayTransient
{
  menu_follow_transient = YES;

    if (menu_supermenu)                         // query super menu for our
    {                                           // position
        NSPoint location = [menu_supermenu locationForSubmenu: self];
    
        [bWindow setFrameOrigin: location];
        menu_supermenu->menu_attached_menu = self;
    }
  
  [menu_view removeFromSuperviewWithoutNeedingDisplay];
  [titleView removeFromSuperviewWithoutNeedingDisplay];
  
  [titleView _releaseCloseButton];
  
  [[bWindow contentView] addSubview:menu_view];
  [[bWindow contentView] addSubview:titleView];
  
  [bWindow orderFront:self];
}

- (void) close
{
  [aWindow orderOut:self];
  menu_is_visible = NO;
}

- (void) closeTransient
{
  [bWindow orderOut:self];
  [menu_view removeFromSuperviewWithoutNeedingDisplay];
  [titleView removeFromSuperviewWithoutNeedingDisplay];
    
  [[aWindow contentView] addSubview:menu_view];
  [titleView _addCloseButton];
  [[aWindow contentView] addSubview:titleView];
  [[aWindow contentView] setNeedsDisplay:YES];

  menu_follow_transient = NO;
}

- (NSWindow *) window
{ 
  return (NSWindow *)aWindow;
}
            
- (NSMenuView *) menuView
{
  return menu_view;
}
@end

@implementation NSMenuWindow

+ (void) initialize
{
  if (self == [NSMenuWindow class])
    {
      [self setVersion: 1];
    }
}

- (id) init
{
  return [self initWithContentRect: NSZeroRect
			 styleMask: NSBorderlessWindowMask
			   backing: NSBackingStoreBuffered
			     defer: NO];
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (BOOL) canBecomeKeyWindow
{
  return NO;
}

- (BOOL) worksWhenModal
{
  return YES;
}

@end

@implementation NSMenuWindowTitleView
- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
} 
 
- (void)setMenu: (NSMenu*)aMenu          { menu = aMenu; }
- (NSMenu*)menu                         { return menu; }
  
- (void) drawRect: (NSRect)rect
{
  NSRect floodRect = rect;
                            
  NSDrawButton(rect, rect);
  
  floodRect.origin.x += 1;
  floodRect.origin.y += 2;
  floodRect.size.height -= 3;
  floodRect.size.width -= 3;
  [[NSColor windowFrameColor] set];
  NSRectFill(floodRect);
      
  [[NSColor windowFrameTextColor] set];
  [[NSFont boldSystemFontOfSize:12] set];
  PSmoveto(rect.origin.x + 5, rect.origin.y + 6);
  PSshow([[menu title] cString]);
  
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSUserDefaults *defaults;
  NSMutableDictionary *menuLocations;
  NSMenu 	*appMainMenu;
  NSPoint origin;
  NSArray* array;
  NSString* key;

  NSPoint       lastLocation;
  NSPoint       location;
  unsigned      eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
                            | NSPeriodicMask | NSRightMouseUpMask;
  BOOL          done = NO;
  NSApplication *theApp = [NSApplication sharedApplication];
  NSDate        *theDistantFuture = [NSDate distantFuture];

  lastLocation = [theEvent locationInWindow];
   
  if ([menu supermenu])
    {
      [self windowBecomeTornOff];
      [menu _setTornOff:YES];
    }
 
  [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

  while (!done)
    {
      theEvent = [theApp nextEventMatchingMask: eventMask
                                     untilDate: theDistantFuture
                                        inMode: NSEventTrackingRunLoopMode
                                       dequeue: YES];
  
      switch ([theEvent type])
        {
          case NSRightMouseUp:
          case NSLeftMouseUp:
          /* right mouse up or left mouse up means we're done */
            done = YES; 
            break;
          case NSPeriodic:   
            location = [window mouseLocationOutsideOfEventStream];
            if (NSEqualPoints(location, lastLocation) == NO)
              {
                NSMenu *aMenu = menu;
                BOOL aDone = NO;
                NSPoint origin = [window frame].origin;

                origin.x += (location.x - lastLocation.x);
                origin.y += (location.y - lastLocation.y);
                [window setFrameOrigin: origin];
  
/* FIXME: Michael wrote this crappy hack.
                while (!aDone)
                  {
                    if ((aMenu = [aMenu attachedMenu]))
                      {
                        NSPoint origin;
  
                        if ([aMenu isTornOff])
                          {
                            aDone = YES;
                            return;
                          }  
     
                        origin = [[aMenu window] frame].origin;
  
                        origin.x += (location.x - lastLocation.x);
                        origin.y += (location.y - lastLocation.y);
                        [[aMenu window] setFrameOrigin: origin];
                      }
                    else
                      aDone = YES;
                  }
*/
              }
            break;
         
          default:
            break;
        }
    }
  [NSEvent stopPeriodicEvents];

  // save position code goes here. FIXME.
  appMainMenu = [NSApp mainMenu];
  defaults = [NSUserDefaults standardUserDefaults];
  menuLocations = [[[defaults objectForKey: NSMenuLocationsKey] mutableCopy] autorelease]; 

  if (!menuLocations)
    menuLocations = [NSMutableDictionary dictionaryWithCapacity: 2];
  origin = [[menu window] frame].origin;
  array = [NSArray arrayWithObjects:
                        [[NSNumber numberWithInt: origin.x] stringValue],
                        [[NSNumber numberWithInt: origin.y] stringValue], nil];

  if (menu == appMainMenu)
    key = @"Main menu";
  else
    key = [menu title];                             // Save menu window pos

  [menuLocations setObject: array forKey: key];         // in defaults databa
  [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
  [defaults synchronize];
}

- (void) windowBecomeTornOff
{
  if ([menu isTornOff])                               // do nothing if menu
    return;                                         // is already torn off
  else
    {                                               // show close button
      NSImage* closeImage = [NSImage imageNamed: @"common_Close"];
      NSImage* closeHImage = [NSImage imageNamed: @"common_CloseH"];
      NSSize imageSize = [closeImage size];
      NSRect rect = { { frame.size.width - imageSize.width - 4,
                      (frame.size.height - imageSize.height) / 2},
                      { imageSize.height, imageSize.width } };
      int mask = NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin;

      button = [[NSButton alloc] initWithFrame: rect];
      [button setButtonType: NSMomentaryLight];        // configure the menu's
      [button setImagePosition: NSImageOnly];          // close button
      [button setImage: closeImage];
      [button setAlternateImage: closeHImage];
      [button setBordered: NO];
      [button setTarget: menu];
      [button setAction: @selector(_performMenuClose:)];
              [button setAutoresizingMask: NSViewMinXMargin];

      [self addSubview: button];
      [self setAutoresizingMask: mask];
                       
      [button display]; 
      [self setNeedsDisplay:YES]; 
    }
}
            
- (void) _releaseCloseButton
{
  [button retain];
  [button removeFromSuperview];
}
  
- (void) _addCloseButton
{
  [self addSubview:button];
}
@end /* NSMenuWindowTitleView */

