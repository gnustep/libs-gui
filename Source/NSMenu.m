/* 
   NSMenu.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: David Lazaro Saz <khelekir@encomix.es>
   Date: Oct 1999
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   and: 
   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   
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
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSScreen.h>

static NSZone	*menuZone = NULL;

static NSString	*NSMenuLocationsKey = @"NSMenuLocations";

@interface	NSMenu (GNUstepPrivate)
- (NSString*) _locationKey;
@end

@implementation	NSMenu (GNUstepPrivate)
- (NSString*) _locationKey
{
  if (menu_is_beholdenToPopUpButton == YES)
    {
      return nil;		/* Can't save	*/
    }
  if (menu_supermenu == nil)
    {
      if ([NSApp mainMenu] == self)
	{
	  return @"\033";	/* Root menu.	*/
	}
      else
	{
	  return nil;		/* Unused menu.	*/
	}
    }
  else if (menu_supermenu->menu_supermenu == nil)
    {
      return [NSString stringWithFormat: @"\033%@", [self title]];
    }
  else
    {
      return [[menu_supermenu _locationKey] stringByAppendingFormat: @"\033%@",
	[self title]];
    }
}

@end


@implementation NSMenu

/*
 * Class Methods
 */
+ (void) initialize
{
  if (self == [NSMenu class])
    {
      [self setVersion: 1];
    }
}

+ (void) setMenuZone: (NSZone*)zone
{
  menuZone = zone;
}

+ (NSZone*) menuZone
{
  return menuZone;
}

/*
 * Initializing a New NSMenu
 */
- (id) init
{
  return [self initWithTitle: @"Menu"];
}

- (BOOL)_ownedByPopUp
{
  return menu_is_beholdenToPopUpButton;
}

- (void)_setOwnedByPopUp: (BOOL)flag
{
  menu_is_beholdenToPopUpButton = flag;

  if (flag == YES)
    {
      [titleView removeFromSuperviewWithoutNeedingDisplay];
    }
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  RELEASE(menu_notifications);
  RELEASE(menu_title);
  RELEASE(menu_items);
  RELEASE(menu_view);
  RELEASE(aWindow);
  RELEASE(bWindow);
  RELEASE(titleView);

  [super dealloc];
}

- (id) initWithTitle: (NSString*)aTitle
{
  NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];
  NSRect                winRect   = {{0,0},{20,23}};

  [super init];

  // Keep the title.
  ASSIGN(menu_title, aTitle);

  // Create an array to store out menu items.
  menu_items = [NSMutableArray new];

  // Create a NSMenuView to draw our menu items.
  menu_view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)];

  // Set ourself as the menu for this view.
  [menu_view setMenu: self];

  // We have no supermenu.
  menu_supermenu = nil;
  menu_is_tornoff = NO;
  menu_is_visible = NO;
  menu_follow_transient = NO;
  menu_changedMessagesEnabled = YES;
  menu_notifications = [NSMutableArray new];
  menu_is_beholdenToPopUpButton = NO;
  menu_changed = YES;
  // According to the spec, menus do autoenable by default.
  menu_autoenable = YES;

  // Transient windows private stuff.
  _oldAttachedMenu = nil;

  // Create the windows that will display the menu.
  aWindow = [[NSMenuWindow alloc] init];
  bWindow = [[NSMenuWindow alloc] init];

  titleView = [NSMenuWindowTitleView new];
  [titleView setFrameOrigin: NSMakePoint(0, winRect.size.height - 23)];
  [titleView setFrameSize: NSMakeSize (winRect.size.width, 23)];
  [[aWindow contentView] addSubview: menu_view];
  [[aWindow contentView] addSubview: titleView];
  [titleView setMenu: self];

  // Set up the notification to start the process of redisplaying
  // the menus where the user left them the last time.
  [theCenter addObserver: self
	        selector: @selector(_showTornOffMenuIfAny:)
	            name: NSApplicationWillFinishLaunchingNotification 
	          object: NSApp];

  return self;
}

/*
 * Setting Up the Menu Commands
 */
- (void) insertItem: (id <NSMenuItem>)newItem
	    atIndex: (int)index
{
  NSNotification *inserted;
  NSDictionary   *d;

  if ([(id)newItem conformsToProtocol: @protocol(NSMenuItem)])
    {
      if ([(id)newItem isKindOfClass: [NSMenuItem class]])
        {
	  /*
           * If the item is already attached to another menu it
	   * isn't added.
	   */
	  if ([(NSMenuItem *)newItem menu] != nil)
	    return;

  	  d = [NSDictionary
		dictionaryWithObject: [NSNumber numberWithInt: index]
		              forKey: @"NSMenuItemIndex"];

          [menu_items insertObject: newItem atIndex: index];
	  [(NSMenuItem *)newItem setMenu: self];

	  // Create the notification for the menu representation.
	  inserted = [NSNotification
		       notificationWithName: NSMenuDidAddItemNotification
		                     object: self
		                   userInfo: d];

	  if (menu_changedMessagesEnabled)
	    [[NSNotificationCenter defaultCenter] postNotification: inserted];
	  else
	    [menu_notifications addObject: inserted];
	}
      else
        {
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

- (id <NSMenuItem>) insertItemWithTitle: (NSString*)aString
			         action: (SEL)aSelector
			  keyEquivalent: (NSString*)charCode 
			        atIndex: (unsigned int)index
{
  id anItem = [NSMenuItem new];

  [anItem setTitle: aString];
  [anItem setAction: aSelector];
  [anItem setKeyEquivalent: charCode];

  // Insert the new item into the stream.

  [self insertItem: anItem atIndex: index];

  // For returns sake.

  return anItem;
}

- (void) addItem: (id <NSMenuItem>)newItem
{
  [self insertItem: newItem atIndex: [menu_items count]];
}

- (id <NSMenuItem>) addItemWithTitle: (NSString*)aString
			      action: (SEL)aSelector 
		       keyEquivalent: (NSString*)keyEquiv
{
  return [self insertItemWithTitle: aString
			    action: aSelector
		     keyEquivalent: keyEquiv
			   atIndex: [menu_items count]];
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  [self removeItemAtIndex: [menu_items indexOfObjectIdenticalTo: anItem]];
}

- (void) removeItemAtIndex: (int)index
{
  NSNotification	*removed;
  NSDictionary		*d;
  id			anItem = [menu_items objectAtIndex: index];

  if (!anItem)
    return;

  if ([anItem isKindOfClass: [NSMenuItem class]])
    {
      d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: index]
				      forKey: @"NSMenuItemIndex"];

      [anItem setMenu: nil];
      [menu_items removeObjectAtIndex: index];

      removed = [NSNotification
		  notificationWithName: NSMenuDidRemoveItemNotification
		                object: self
		              userInfo: d];

      if (menu_changedMessagesEnabled)
	[[NSNotificationCenter defaultCenter] postNotification: removed];
      else
	[menu_notifications addObject: removed];
    }
  else
    {
      NSLog(@"You must use an NSMenuItem, or a derivative thereof.\n");
    }

  menu_changed = YES;
}

- (void) itemChanged: (id <NSMenuItem>)anObject
{
  NSNotification *changed;
  NSDictionary   *d;

  d = [NSDictionary
	dictionaryWithObject: [NSNumber
				numberWithInt: [self indexOfItem: anObject]]
	              forKey: @"NSMenuItemIndex"];

  changed = [NSNotification
	      notificationWithName: NSMenuDidChangeItemNotification
	                    object: self
	                  userInfo: d];

  if (menu_changedMessagesEnabled)
    [[NSNotificationCenter defaultCenter] postNotification: changed];
  else
    [menu_notifications addObject: changed];

  // Update the menu.
  [self update];
}

/*
 * Finding Menu Items
 */
- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  unsigned i;
  unsigned count = [menu_items count];

  for (i = 0; i < count; i++)
    {
      id menuItem = [menu_items objectAtIndex: i];

      if ([menuItem tag] == aTag)
        return menuItem;
    }
  return nil;
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  unsigned i;
  unsigned count = [menu_items count];

  for (i = 0; i < count; i++)
    {
      id menuItem = [menu_items objectAtIndex: i];

      if ([[menuItem title] isEqual: aString])
        return menuItem;
    }
  return nil;
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  if (index >= [menu_items count] || index < 0)
    [NSException  raise: NSRangeException
		 format: @"Range error in method -itemAtIndex: "];

  return [menu_items objectAtIndex: index];
}

- (int) numberOfItems
{
  return [menu_items count];
}

- (NSArray*) itemArray
{
  return (NSArray*)menu_items;
}

/*
 * Finding Indices of Menu Items
 */
- (int) indexOfItem: (id <NSMenuItem>)anObject
{
  return [menu_items indexOfObjectIdenticalTo: anObject];
}

- (int) indexOfItemWithTitle: (NSString*)aTitle
{
  id anItem;

  if ((anItem = [self itemWithTitle: aTitle]))
    return [menu_items indexOfObjectIdenticalTo: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTag: (int)aTag
{
  id anItem;

  if ((anItem = [self itemWithTag: aTag]))
    return [menu_items indexOfObjectIdenticalTo: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTarget: (id)anObject
		    andAction: (SEL)actionSelector
{
  unsigned i;
  unsigned count = [menu_items count];

  for (i = 0; i < count; i++)
    {
      NSMenuItem *menuItem = [menu_items objectAtIndex: i];

      if (actionSelector == 0 || sel_eq([menuItem action], actionSelector))
	{
	  if ([[menuItem target] isEqual: anObject])
	    {
	      return i;
	    }
	}
    }

  return -1;
}

- (int) indexOfItemWithRepresentedObject: (id)anObject
{
  int i, count = [menu_items count];

  for (i = 0; i < count; i++)
    {
      if ([[[menu_items objectAtIndex: i] representedObject]
	isEqual: anObject])
	{
	  return i;
	}
    }

  return -1;
}

- (int) indexOfItemWithSubmenu: (NSMenu *)anObject
{
  int i, count = [menu_items count];

  for (i = 0; i < count; i++)
    {
      if ([[[menu_items objectAtIndex: i] title]
	    isEqual: [anObject title]])
	{
	  return i;
	}
    }
  
  return -1;
}

//
// Managing Submenus.
//
- (void) setSubmenu: (NSMenu *)aMenu
	    forItem: (id <NSMenuItem>) anItem 
{
  [(NSMenuItem *)anItem setSubmenu: aMenu];
  [anItem setTarget: self];
  [anItem setAction: @selector(submenuAction:)];
  if (aMenu)
    aMenu->menu_supermenu = self;

  ASSIGN(aMenu->menu_title, [anItem title]);

  [self itemChanged: anItem];
}

- (void) submenuAction: (id)sender
{
  [menu_view detachSubmenu];
}

- (NSMenu *) attachedMenu
{
  if (menu_attachedMenu && menu_follow_transient
      && !menu_attachedMenu->menu_follow_transient)
    return nil;

  return menu_attachedMenu;
}

- (BOOL) isAttached
{
  return menu_supermenu && [menu_supermenu attachedMenu] == self;
}

- (BOOL) isTornOff
{
  return menu_is_tornoff;
}

- (NSPoint) locationForSubmenu: (NSMenu*)aSubmenu
{
  NSRect    frame;
  NSRect    submenuFrame;
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

  // FIXME: Fix this to support styles when the menus move.
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil)
      == GSWindowMakerInterfaceStyle)
    {
      NSRect aRect = [menu_view rectOfItemAtIndex: 
				[self indexOfItemWithTitle: [aSubmenu title]]];
      NSPoint subOrigin = [win_link convertBaseToScreen: 
				      NSMakePoint(aRect.origin.x,
						  aRect.origin.y)];

      return NSMakePoint (frame.origin.x + frame.size.width,
			  subOrigin.y - (submenuFrame.size.height - 43));
    }
  else
    {
      return NSMakePoint (frame.origin.x + frame.size.width,
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

//
// Enabling and Disabling Menu Items
//
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
  if ([self autoenablesItems])
    {
      unsigned i, count;

      count = [menu_items count];  
      
      // Temporary disable automatic displaying of menu.
      [self setMenuChangedMessagesEnabled: NO];
      
      for (i = 0; i < count; i++)
	{
	  NSMenuItem *item = [menu_items objectAtIndex: i];
	  SEL	      action = [item action];
	  id	      target;
	  id	      validator = nil;
	  BOOL	      wasEnabled = [item isEnabled];
	  BOOL	      shouldBeEnabled;

	  // Update the submenu items if any.
	  if ([item hasSubmenu])
	    [[item submenu] update];

	  // If there is no action - there can be no validator for the item.
	  if (action)
	    {
	      // If there is a target use that for validation (or nil).
	      if ((target = [item target]))
		{
		  if ([target respondsToSelector: action])
		    {  
		      validator = target;
		    }
		}
	      else
		{
		  validator = [NSApp targetForAction: action];
		}
	    }
      
	  if (validator == nil)
	    {
	      shouldBeEnabled = NO;
	    }
	  else if ([validator
		     respondsToSelector: @selector(validateMenuItem:)])
	    {
	      shouldBeEnabled = [validator validateMenuItem: item];
	    }
	  else
	    {
	      shouldBeEnabled = YES;
	    }

	  if (shouldBeEnabled != wasEnabled)
	    {
	      [item setEnabled: shouldBeEnabled];
	      [[self window] display];
	    }
	}
          
      // Reenable displaying of menus
      [self setMenuChangedMessagesEnabled: YES];
    }

  if (menu_changed)
    [self sizeToFit];

  return;
}

//
// Handling Keyboard Equivalents
//
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  unsigned      i;
  unsigned      count = [menu_items count];
  NSEventType   type = [theEvent type];
         
  if (type != NSKeyDown && type != NSKeyUp) 
    return NO;
             
  for (i = 0; i < count; i++)
    {
      NSMenuItem *item = [menu_items objectAtIndex: i];
                                    
      if ([item hasSubmenu])
        {
	  // Recurse through submenus.
          if ([[item submenu] performKeyEquivalent: theEvent])
            {
              // The event has been handled by an item in the submenu.
              return YES;
            }
        }
      else
        {
          if ([[item keyEquivalent] isEqual: 
				      [theEvent charactersIgnoringModifiers]])
	    {
	      [menu_view performActionWithHighlightingForItemAtIndex: i];
	      return YES;
	    }
	}
    }
  return NO; 
}

//
// Simulating Mouse Clicks
//
- (void)  performActionForItemAtIndex: (int)index
{
  id<NSMenuItem> item = [menu_items objectAtIndex: index];
  NSNotificationCenter *nc;
  NSDictionary *d;

  if (![item isEnabled])
    return;

  // Send the actual action and the estipulated notifications.
  nc = [NSNotificationCenter defaultCenter];
  d = [NSDictionary dictionaryWithObject: item forKey: @"MenuItem"];
  [nc postNotificationName: NSMenuWillSendActionNotification
                    object: self
                  userInfo: d];
  if ([item action])
    {
      [[NSApplication sharedApplication] sendAction: [item action]
					 to: [item target]
					 from: item];
    }
  [nc postNotificationName: NSMenuDidSendActionNotification
                    object: self
                  userInfo: d];
}

//
// Setting the Title
//
- (void) setTitle: (NSString*)aTitle
{
  ASSIGN(menu_title, aTitle);
  [self sizeToFit];
}
  
- (NSString*) title
{
  return menu_title;
}

//
// Setting the Representing Object
//
- (void) setMenuRepresentation: (id)menuRep
{
  if ([menuRep isKindOfClass: [NSMenuView class]])
    ASSIGN(menu_view, menuRep);
  else
    NSLog(@"You must use an NSMenuView, or a derivative thereof.\n");
}

- (id) menuRepresentation
{
  return menu_view;
}

//
// Updating the Menu Layout
//
- (void) setMenuChangedMessagesEnabled: (BOOL)flag
{ 
  if (menu_changedMessagesEnabled != flag)
    {
      if (flag)
	{
	  if ([menu_notifications count])
	    {
	      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	      NSEnumerator *enumerator = [menu_notifications objectEnumerator];
	      id            aNotification;

	      while ((aNotification = [enumerator nextObject]))
		[nc postNotification: aNotification];
	    }

	  // Clean the notification array.
	  [menu_notifications removeAllObjects];
	}

      menu_changedMessagesEnabled = flag;
    }
}
 
- (BOOL) menuChangedMessagesEnabled
{
  return menu_changedMessagesEnabled;
}

- (void) sizeToFit
{
  NSRect windowFrame;
  NSRect menuFrame;
  NSSize size;

  windowFrame = [aWindow frame];
  [menu_view sizeToFit];

  menuFrame = [menu_view frame];

  size.width = menuFrame.size.width;
  size.height = menuFrame.size.height;

  if (!menu_is_beholdenToPopUpButton)
    {
      size.height += 23;
      [aWindow setContentSize: size];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];
      windowFrame = [bWindow frame];
      [bWindow setContentSize: size];
      [bWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];
      [menu_view setFrameOrigin: NSMakePoint(0, 0)];
      [titleView setFrame: NSMakeRect(0,size.height-23,size.width,23)];
    }
  else
    {
      [aWindow setContentSize: size];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];
    }

  [aWindow display];

  menu_changed = NO;
}

/*
 * Displaying Context Sensitive Help
 */
- (void) helpRequested: (NSEvent *)event
{
  // TODO: Won't be implemented until we have NSHelp*
}

/*
 * NSCoding Protocol
 */
- (void) encodeWithCoder: (NSCoder*)encoder
{
  [encoder encodeObject: menu_title];
  [encoder encodeObject: menu_items];
  [encoder encodeObject: menu_view];
  [encoder encodeConditionalObject: menu_supermenu];
  [encoder encodeConditionalObject: menu_popb];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &menu_autoenable];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &menu_is_tornoff];
  [encoder encodeValueOfObjCType: @encode(BOOL)
	                     at: &menu_is_beholdenToPopUpButton];
}

- (id) initWithCoder: (NSCoder*)decoder
{
  NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];
  NSRect                winRect   = {{0,0},{20,23}};

  menu_title = [[decoder decodeObject] retain];
  menu_items = [[decoder decodeObject] retain];
  menu_view  = [[decoder decodeObject] retain];
  menu_supermenu = [decoder decodeObject];
  menu_popb      = [decoder decodeObject];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &menu_autoenable];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &menu_is_tornoff];
  [decoder decodeValueOfObjCType: @encode(BOOL)
	                       at: &menu_is_beholdenToPopUpButton];

  menu_attachedMenu = nil;
  menu_changedMessagesEnabled = YES;
  menu_notifications = [NSMutableArray new];
  menu_follow_transient = NO;
  menu_is_visible = NO;

  // Mark the menu as changed in order to get it resized.
  menu_changed = YES;

  // Transient windows private stuff.
  _oldAttachedMenu = nil;

  // Create the windows that will display the menu.
  aWindow = [[NSMenuWindow alloc] initWithContentRect: winRect
                                            styleMask: NSBorderlessWindowMask
                                              backing: NSBackingStoreRetained
                                                defer: NO];
  bWindow = [[NSMenuWindow alloc] initWithContentRect: winRect
                                            styleMask: NSBorderlessWindowMask
                                              backing: NSBackingStoreRetained
                                                defer: NO];
  
  titleView = [NSMenuWindowTitleView new];
  [titleView setFrameOrigin: NSMakePoint(0, winRect.size.height - 23)];
  [titleView setFrameSize: NSMakeSize (winRect.size.width, 23)];
  [[aWindow contentView] addSubview: menu_view];
  [[aWindow contentView] addSubview: titleView];
  [titleView setMenu: self];

  // Set up the notification to start the process of redisplaying
  // the menus where the user left them the last time.
  [theCenter addObserver: self
	        selector: @selector(_showTornOffMenuIfAny:)
	            name: NSApplicationWillFinishLaunchingNotification 
	          object: NSApp];

  return self;
}

/*
 * NSCopying Protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  return self;
}
@end

@implementation NSMenu (GNUstepExtra)

#define IS_OFFSCREEN(WINDOW) \
  !(NSContainsRect([[NSScreen mainScreen] frame], [WINDOW frame]))

- (void) _setTornOff: (BOOL)flag
{
  NSMenu	*supermenu;

  menu_is_tornoff = flag;

  supermenu = [self supermenu];
  if (supermenu != nil)
    {
      [[supermenu menuRepresentation] setHighlightedItemIndex: -1];
      supermenu->menu_attachedMenu = nil;
    }
}

- (void) _showTornOffMenuIfAny: (NSNotification*)notification
{
  if ([NSApp mainMenu] != self)
    {
      NSString		*key;
      NSString		*location;
      NSUserDefaults	*defaults;
      NSDictionary	*menuLocations;

      key = [self _locationKey];
      defaults  = [NSUserDefaults standardUserDefaults];
      menuLocations = [defaults objectForKey: NSMenuLocationsKey];
      
      location = [menuLocations objectForKey: key];
      if (location && [location isKindOfClass: [NSString class]])
	{
	  [titleView windowBecomeTornOff];
	  [self _setTornOff: YES];
	  [self display];
	}
    }
}

- (BOOL) isFollowTransient
{
  return menu_follow_transient;
} 

- (BOOL) isPartlyOffScreen
{
  return menu_isPartlyOffScreen;
}

- (void) nestedCheckOffScreen
{
  // This method is used when the menu is moved.
  if (menu_attachedMenu)
    [menu_attachedMenu nestedCheckOffScreen];

  menu_isPartlyOffScreen = IS_OFFSCREEN(aWindow);
}

- (void) _performMenuClose: (id)sender
{
  NSString		*key;

  if (menu_attachedMenu)
    [menu_view detachSubmenu];

  key = [self _locationKey];
  if (key != nil)
    {
      NSUserDefaults		*defaults;
      NSMutableDictionary	*menuLocations;

      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [[defaults objectForKey: NSMenuLocationsKey] mutableCopy];
      [menuLocations removeObjectForKey: key];
      [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
      RELEASE(menuLocations);
      [defaults synchronize];
    }

  [menu_view setHighlightedItemIndex: -1];
  [self _setTornOff: NO];
  [self close];
  [titleView _releaseCloseButton];
} 

- (void) _rightMouseDisplay
{
  // TODO: implement this method.
}

- (void) display
{
  if (menu_changed)
    [self sizeToFit];

  if (menu_is_beholdenToPopUpButton)
    {
      menu_is_visible = YES;
      [aWindow orderFront: nil];
      return;
    }

  if (menu_supermenu && ![self isTornOff])      // query super menu for
    {                                           // position
      [aWindow setFrameOrigin: [menu_supermenu locationForSubmenu: self]];
      menu_supermenu->menu_attachedMenu = self;
    }
  else
    {
      NSString	*key = [self _locationKey];
      
      if (key != nil)
	{
	  NSUserDefaults	*defaults;
	  NSDictionary		*menuLocations;
	  NSString		*location;

	  defaults = [NSUserDefaults standardUserDefaults];
	  menuLocations = [defaults objectForKey: NSMenuLocationsKey];
	  location = [menuLocations objectForKey: key];
	  if (location && [location isKindOfClass: [NSString class]])
	    {
	      [aWindow setFrameFromString: location];
	    }
	  else
	    {
	      float	aPoint = [[NSScreen mainScreen] frame].size.height
		             - [aWindow frame].size.height;

	      [aWindow setFrameOrigin: NSMakePoint(0,aPoint)];
	      [bWindow setFrameOrigin: NSMakePoint(0,aPoint)];
	    }
	}
    }

  menu_is_visible = YES;

  [aWindow orderFrontRegardless];

  menu_isPartlyOffScreen = IS_OFFSCREEN(aWindow);

  /*
   * If we have just been made visible, we must make sure that any attached
   * submenu is visible too.
   */
  [[self attachedMenu] display];
}

- (void) displayTransient
{
  NSPoint location;

  menu_follow_transient = YES;

  // Cache the old submenu if any.
  _oldAttachedMenu = menu_supermenu->menu_attachedMenu;
  menu_supermenu->menu_attachedMenu = self;

  // Query the supermenu our position.
  location = [menu_supermenu locationForSubmenu: self];

  [bWindow setFrameOrigin: location];

  [menu_view removeFromSuperviewWithoutNeedingDisplay];
  [titleView removeFromSuperviewWithoutNeedingDisplay];

  if (menu_is_tornoff)
    [titleView _releaseCloseButton];

  [[bWindow contentView] addSubview: menu_view];
  [[bWindow contentView] addSubview: titleView];

  [bWindow orderFront: self];

  menu_isPartlyOffScreen = IS_OFFSCREEN(bWindow);
}

- (void) close
{
  NSMenu	*sub = [self attachedMenu];

  /*
   * If we have an attached submenu, we must close that too - but then make
   * sure we still have a record of it so that it can be re-displayed if we
   * are redisplayed.
   */
  if (sub != nil)
    {
      [sub close];
      menu_attachedMenu = sub;
    }
  [aWindow orderOut: self];
  menu_is_visible = NO;

  if (menu_supermenu)
    menu_supermenu->menu_attachedMenu = nil;
}

- (void) closeTransient
{
  [bWindow orderOut: self];
  [menu_view removeFromSuperviewWithoutNeedingDisplay];
  [titleView removeFromSuperviewWithoutNeedingDisplay];

  [[aWindow contentView] addSubview: menu_view];

  if (menu_is_tornoff)
    [titleView _addCloseButton];

  [[aWindow contentView] addSubview: titleView];

  [[aWindow contentView] setNeedsDisplay: YES];

  // Restore the old submenu.
  menu_supermenu->menu_attachedMenu = _oldAttachedMenu;

  menu_follow_transient = NO;

  menu_isPartlyOffScreen = IS_OFFSCREEN(aWindow);
}

- (NSWindow *) window
{
  if (menu_follow_transient)
    return (NSWindow *)bWindow;
  else
    return (NSWindow *)aWindow;
}

- (void) nestedSetFrameOrigin: (NSPoint) aPoint
{
  NSRect frame;

  // Move ourself and get our width.
  if (menu_follow_transient)
    {
      [bWindow moveToPoint: aPoint];
      frame = [bWindow frame];
    }
  else
    {
      [aWindow moveToPoint: aPoint];
      frame = [aWindow frame];
    }


  // Do the same for attached menus.
  if (menu_attachedMenu)
    {
      // First locate the origin.
      aPoint.x += frame.size.width;
      aPoint.y += frame.size.height
	- [menu_attachedMenu->aWindow frame].size.height;
      [menu_attachedMenu nestedSetFrameOrigin: aPoint];
    }
}

#define SHIFT_DELTA 18.0

- (void) shiftOnScreen
{
  NSWindow *theWindow = menu_follow_transient ? bWindow : aWindow;
  NSRect    frameRect = [theWindow frame];
  NSPoint   vector    = {0.0, 0.0};
  BOOL      moveIt    = YES;

  if (frameRect.origin.y < 0)
    {
      if (frameRect.origin.y + SHIFT_DELTA <= 0)
	vector.y = SHIFT_DELTA;
      else
	vector.y = -frameRect.origin.y;
    }
  else if (frameRect.origin.x < 0)
    {
      if (frameRect.origin.x + SHIFT_DELTA <= 0)
	vector.x = SHIFT_DELTA;
      else
	vector.x = -frameRect.origin.x;
    }
  else
    {
      vector.x  = frameRect.origin.x + frameRect.size.width;
      vector.x -= [[NSScreen mainScreen] frame].size.width;

      if (vector.x > 0)
	{
	  if (vector.x - SHIFT_DELTA <= 0)
	    vector.x = -SHIFT_DELTA;
	  else
	    vector.x = -vector.x - 2;
	}
      else
	moveIt = NO;
    }

  if (moveIt)
    {
        NSMenu  *candidateMenu;
	NSMenu  *masterMenu;
	NSPoint  masterLocation;
	NSPoint  destinationPoint;

	// Look for the "master" menu, i.e. the one to move from.
	for (candidateMenu = masterMenu = self;
	     (candidateMenu = masterMenu->menu_supermenu)
	       && (!masterMenu->menu_is_tornoff
		   || masterMenu->menu_follow_transient);
	     masterMenu = candidateMenu);

	masterLocation = [[masterMenu window] frame].origin;
	destinationPoint.x = masterLocation.x + vector.x;
	destinationPoint.y = masterLocation.y + vector.y;

	[masterMenu nestedSetFrameOrigin: destinationPoint];
    }
  else
    menu_isPartlyOffScreen = NO;
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

- (void) initDefaults
{
  [super initDefaults];
  window_level = NSSubmenuWindowLevel;
}

- (id) init
{
  self = [self initWithContentRect: NSZeroRect
			 styleMask: NSBorderlessWindowMask
			   backing: NSBackingStoreBuffered
			     defer: NO];
  return self;
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

// This method is a hack to speed-up menu dragging.
- (void) moveToPoint: (NSPoint)aPoint
{
  NSRect frameRect = frame;

  frameRect.origin = aPoint;
  DPSplacewindow(GSCurrentContext(), frameRect.origin.x, frameRect.origin.y,
    frameRect.size.width, frameRect.size.height, [self windowNumber]);
}

@end

@implementation NSMenuWindowTitleView

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
} 
 
- (void) setMenu: (NSMenu*)aMenu
{
  menu = aMenu;
}

- (NSMenu*) menu
{
  return menu;
}
  
- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSRect             workRect = rect;


  // Draw the dark gray upper left lines.
  DPSgsave(ctxt);
    DPSsetlinewidth(ctxt, 1);
    DPSsetgray(ctxt, 0.333);
    DPSmoveto(ctxt, workRect.origin.x, workRect.origin.y);
    DPSrlineto(ctxt, 0, workRect.size.height);
    DPSrlineto(ctxt, workRect.size.width, 0);
    DPSstroke(ctxt);
  DPSgrestore(ctxt);

  // Draw the title box's button.
  workRect.size.width  -= 1;
  workRect.size.height -= 1;
  workRect.origin.x += 1;
  NSDrawButton(workRect, workRect);

  // Paint it Black!
  workRect.origin.x += 1;
  workRect.origin.y += 2;
  workRect.size.height -= 3;
  workRect.size.width -= 3;
  [[NSColor windowFrameColor] set];
  NSRectFill(workRect);

  // Draw the title.
  [[NSColor windowFrameTextColor] set];
  [[NSFont boldSystemFontOfSize: 12] set];
  PSmoveto(rect.origin.x + 7, rect.origin.y + 7);
  PSshow([[menu title] cString]);

}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSUserDefaults	*defaults;
  NSMutableDictionary	*menuLocations;
  NSString		*key;
  NSString		*locString;
  NSPoint		lastLocation;
  NSPoint		location;
  unsigned		eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  BOOL			done = NO;
  NSDate		*theDistantFuture = [NSDate distantFuture];

  lastLocation = [theEvent locationInWindow];
   
  if (![menu isTornOff] && [menu supermenu])
    {
      [self windowBecomeTornOff];
      [menu _setTornOff: YES];
    }
 
  while (!done)
    {
      theEvent = [NSApp nextEventMatchingMask: eventMask
                                     untilDate: theDistantFuture
                                        inMode: NSEventTrackingRunLoopMode
                                       dequeue: YES];
  
      switch ([theEvent type])
        {
	case NSLeftMouseUp: 
	  done = YES; 
	  break;
	case NSLeftMouseDragged:   
	  location = [window mouseLocationOutsideOfEventStream];
	  if (NSEqualPoints(location, lastLocation) == NO)
	    {
	      NSPoint origin = [window frame].origin;

	      origin.x += (location.x - lastLocation.x);
	      origin.y += (location.y - lastLocation.y);
	      [menu nestedSetFrameOrigin: origin];
	      [menu nestedCheckOffScreen];
	    }
	  break;
         
	default: 
	  break;
        }
    }

  /*
   * Same current menu frame in defaults database.
   */
  defaults = [NSUserDefaults standardUserDefaults];
  menuLocations = [[defaults objectForKey: NSMenuLocationsKey] mutableCopy];
  if (menuLocations == nil)
    menuLocations = [NSMutableDictionary dictionaryWithCapacity: 2];
  locString = [[menu window] stringWithSavedFrame];
  key = [menu _locationKey];
  [menuLocations setObject: locString forKey: key];
  [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
  RELEASE(menuLocations);
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
      [self setNeedsDisplay: YES]; 
    }
}
            
- (void) _releaseCloseButton
{
  [button retain];
  [button removeFromSuperview];
}
  
- (void) _addCloseButton
{
  [self addSubview: button];
}
@end /* NSMenuWindowTitleView */
