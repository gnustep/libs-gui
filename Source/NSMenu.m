/** <title>NSMenu</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Aug 2001
   Author: David Lazaro Saz <khelekir@encomix.es>
   Date: Oct 1999
   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
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
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSAttributedString.h>

/* Subclass of NSPanel since menus cannot become key */
@interface NSMenuPanel : NSPanel
@end

/* A menu's title is an instance of this class */
@interface NSMenuWindowTitleView : NSView
{
  id  menu;
  NSButton *button;
}

- (void) addCloseButton;
- (void) releaseCloseButton;
- (void) createButton;
- (void) setMenu: (NSMenu*)menu;
- (NSMenu*) menu;

@end

@interface NSMenuView (GNUstepPrivate)
- (NSArray *)_itemCells;
@end


static NSZone	*menuZone = NULL;
static NSString	*NSMenuLocationsKey = @"NSMenuLocations";
static NSNotificationCenter *nc;

@interface	NSMenu (GNUstepPrivate)
- (NSString *) _locationKey;
- (NSMenuPanel *) _createWindow;
@end

@implementation NSMenuPanel
- (BOOL) canBecomeKeyWindow
{
  /* This should be NO, but there's currently a bug in the interaction
     with WindowMaker that causes spurious deactivation of the app
     if the app icon is the only window that can become key */
  return YES;
}
@end

@implementation	NSMenu (GNUstepPrivate)

- (NSString*) _locationKey
{
  if (_superMenu == nil)
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
  else if (_superMenu->_superMenu == nil)
    {
      return [NSString stringWithFormat: @"\033%@", [self title]];
    }
  else
    {
      return [[_superMenu _locationKey] stringByAppendingFormat: @"\033%@",
	[self title]];
    }
}

/* Create a non autorelease window for this menu.  */
- (NSMenuPanel*) _createWindow
{
  NSMenuPanel *win = [[NSMenuPanel alloc] 
		     initWithContentRect: NSZeroRect
		     styleMask: NSBorderlessWindowMask
		     backing: NSBackingStoreBuffered
		     defer: YES];
  [win setLevel: NSSubmenuWindowLevel];
  [win setWorksWhenModal: NO];
  [win setBecomesKeyOnlyIfNeeded: YES];

  return win;
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
      nc = [NSNotificationCenter defaultCenter];
      menuZone = NSCreateZone(0, 0, YES);
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

- (void) dealloc
{
  [nc removeObserver: self];

  RELEASE(_notifications);
  RELEASE(_title);
  RELEASE(_items);
  RELEASE(_view);
  RELEASE(_aWindow);
  RELEASE(_bWindow);
  RELEASE(_titleView);

  [super dealloc];
}

- (id) initWithTitle: (NSString*)aTitle
{
  float  height;
  NSView *contentView;

  [super init];

  // Keep the title.
  ASSIGN(_title, aTitle);

  // Create an array to store out menu items.
  _items = [[NSMutableArray alloc] init];

  // We have no supermenu.
  // _superMenu = nil;
  // _is_tornoff = NO;
  // _follow_transient = NO;

  _changedMessagesEnabled = YES;
  _notifications = [[NSMutableArray alloc] init];
  _changed = YES;
  // According to the spec, menus do autoenable by default.
  _autoenable = YES;

  // Transient windows private stuff.
  // _oldAttachedMenu = nil;

  /* Please note that we own all this menu network of objects.  So, 
     none of these objects should be retaining us.  When we are deallocated,
     we release all the objects we own, and that should cause deallocation
     of the whole menu network.  */

  // Create the windows that will display the menu.
  _aWindow = [self _createWindow];
  _bWindow = [self _createWindow];

  // Create a NSMenuView to draw our menu items.
  _view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)];
  [_view setMenu: self];

  // Create the title view
  height = [[_view class] menuBarHeight];
  _titleView = [[NSMenuWindowTitleView alloc] initWithFrame: 
						NSMakeRect(0, 0, 50, height)];
  [_titleView setMenu: self];

  contentView = [_aWindow contentView];
  [contentView addSubview: _view];
  [contentView addSubview: _titleView];

  /* Set up the notification to start the process of redisplaying
     the menus where the user left them the last time.  
     
     Use NSApplicationDidFinishLaunching, and not
     NSApplicationWillFinishLaunching, so that the programmer can set
     up menus in NSApplicationWillFinishLaunching.
  */
  [nc addObserver: self
      selector: @selector(_showTornOffMenuIfAny:)
      name: NSApplicationDidFinishLaunchingNotification 
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

  if (![(id)newItem conformsToProtocol: @protocol(NSMenuItem)])
    {
      NSLog(@"You must use an object that conforms to NSMenuItem.\n");
      return;
    }

  /*
   * If the item is already attached to another menu it
   * isn't added.
   */
  if ([newItem menu] != nil)
    return;
  
  [_items insertObject: newItem atIndex: index];
  _changed = YES;
  
  // Create the notification for the menu representation.
  d = [NSDictionary
	  dictionaryWithObject: [NSNumber numberWithInt: index]
	  forKey: @"NSMenuItemIndex"];
  inserted = [NSNotification
		 notificationWithName: NSMenuDidAddItemNotification
		 object: self
		 userInfo: d];
  
  if (_changedMessagesEnabled)
    [nc postNotification: inserted];
  else
    [_notifications addObject: inserted];

  // Set this after the insert notification has been send.
  [newItem setMenu: self];

  // Update the menu.
  [self update];
}

- (id <NSMenuItem>) insertItemWithTitle: (NSString*)aString
			         action: (SEL)aSelector
			  keyEquivalent: (NSString*)charCode 
			        atIndex: (unsigned int)index
{
  NSMenuItem *anItem = [[NSMenuItem alloc] initWithTitle: aString
					   action: aSelector
					   keyEquivalent: charCode];

  // Insert the new item into the menu.
  [self insertItem: anItem atIndex: index];

  // For returns sake.
  return AUTORELEASE(anItem);
}

- (void) addItem: (id <NSMenuItem>)newItem
{
  [self insertItem: newItem atIndex: [_items count]];
}

- (id <NSMenuItem>) addItemWithTitle: (NSString*)aString
			      action: (SEL)aSelector 
		       keyEquivalent: (NSString*)keyEquiv
{
  return [self insertItemWithTitle: aString
			    action: aSelector
		     keyEquivalent: keyEquiv
			   atIndex: [_items count]];
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  int index = [self indexOfItem: anItem];

  if (-1 == index)
    return;

  [self removeItemAtIndex: index];
}

- (void) removeItemAtIndex: (int)index
{
  NSNotification *removed;
  NSDictionary	 *d;
  id		 anItem = [_items objectAtIndex: index];

  if (!anItem)
    return;

  [anItem setMenu: nil];
  [_items removeObjectAtIndex: index];
  _changed = YES;
  
  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: index]
		    forKey: @"NSMenuItemIndex"];
  removed = [NSNotification
		notificationWithName: NSMenuDidRemoveItemNotification
		object: self
		userInfo: d];
  
  if (_changedMessagesEnabled)
    [nc postNotification: removed];
  else
    [_notifications addObject: removed];

  // Update the menu.
  [self update];
}

- (void) itemChanged: (id <NSMenuItem>)anObject
{
  NSNotification *changed;
  NSDictionary   *d;
  int index = [self indexOfItem: anObject];

  if (-1 == index)
    return;

  _changed = YES;

  d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: index]
		    forKey: @"NSMenuItemIndex"];
  changed = [NSNotification
	      notificationWithName: NSMenuDidChangeItemNotification
	                    object: self
	                  userInfo: d];

  if (_changedMessagesEnabled)
    [nc postNotification: changed];
  else
    [_notifications addObject: changed];

  // Update the menu.
  [self update];
}

/*
 * Finding Menu Items
 */
- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  unsigned i;
  unsigned count = [_items count];

  for (i = 0; i < count; i++)
    {
      id menuItem = [_items objectAtIndex: i];

      if ([menuItem tag] == aTag)
        return menuItem;
    }
  return nil;
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  unsigned i;
  unsigned count = [_items count];

  for (i = 0; i < count; i++)
    {
      id menuItem = [_items objectAtIndex: i];

      if ([[menuItem title] isEqualToString: aString])
        return menuItem;
    }
  return nil;
}

- (id <NSMenuItem>) itemAtIndex: (int)index
{
  if (index >= [_items count] || index < 0)
    [NSException  raise: NSRangeException
		 format: @"Range error in method -itemAtIndex: "];

  return [_items objectAtIndex: index];
}

- (int) numberOfItems
{
  return [_items count];
}

- (NSArray*) itemArray
{
  return (NSArray*)_items;
}

/*
 * Finding Indices of Menu Items
 */
- (int) indexOfItem: (id <NSMenuItem>)anObject
{
  int index;

  index = [_items indexOfObjectIdenticalTo: anObject];

  if (index == NSNotFound)
    return -1;
  else
    return index;
}

- (int) indexOfItemWithTitle: (NSString*)aTitle
{
  id anItem;

  if ((anItem = [self itemWithTitle: aTitle]))
    return [_items indexOfObjectIdenticalTo: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTag: (int)aTag
{
  id anItem;

  if ((anItem = [self itemWithTag: aTag]))
    return [_items indexOfObjectIdenticalTo: anItem];
  else
    return -1;
}

- (int) indexOfItemWithTarget: (id)anObject
		    andAction: (SEL)actionSelector
{
  unsigned i;
  unsigned count = [_items count];

  for (i = 0; i < count; i++)
    {
      NSMenuItem *menuItem = [_items objectAtIndex: i];

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
  int i, count = [_items count];

  for (i = 0; i < count; i++)
    {
      if ([[[_items objectAtIndex: i] representedObject]
	isEqual: anObject])
	{
	  return i;
	}
    }

  return -1;
}

- (int) indexOfItemWithSubmenu: (NSMenu *)anObject
{
  int i, count = [_items count];

  for (i = 0; i < count; i++)
    {
      id item = [_items objectAtIndex: i];

      if ([item hasSubmenu] && 
	  [[item submenu] isEqual: anObject])
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
	    forItem: (id <NSMenuItem>)anItem 
{
  [anItem setSubmenu: aMenu];
}

- (void) submenuAction: (id)sender
{
  [_view detachSubmenu];
}

- (NSMenu *) attachedMenu
{
  if (_attachedMenu && _follow_transient
      && !_attachedMenu->_follow_transient)
    return nil;

  return _attachedMenu;
}

- (BOOL) isAttached
{
  return _superMenu && [_superMenu attachedMenu] == self;
}

- (BOOL) isTornOff
{
  return _is_tornoff;
}

- (NSPoint) locationForSubmenu: (NSMenu*)aSubmenu
{
  return [_view locationForSubmenu: aSubmenu];
}

- (NSMenu *) supermenu
{
  return _superMenu;
}

- (void) setSupermenu: (NSMenu *)supermenu
{
  /* The supermenu retains us (indirectly).  Do not retain it.  */
  _superMenu = supermenu;
}

//
// Enabling and Disabling Menu Items
//
- (void) setAutoenablesItems: (BOOL)flag
{
  _autoenable = flag;
}

- (BOOL) autoenablesItems
{
  return _autoenable;
}

- (void) update
{
  // We use this as a recursion check.
  if (!_changedMessagesEnabled)
    return;

  if ([self autoenablesItems])
    {
      unsigned i, count;

      count = [_items count];  
      
      // Temporary disable automatic displaying of menu.
      [self setMenuChangedMessagesEnabled: NO];
      
      for (i = 0; i < count; i++)
	{
	  NSMenuItem *item = [_items objectAtIndex: i];
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
	      if (nil != (target = [item target]))
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
	  else if (_popUpButtonCell != nil)
	    {
	      if (NULL != (action = [_popUpButtonCell action]))
	        {
		  // If there is a target use that for validation (or nil).
		  if (nil != (target = [_popUpButtonCell target]))
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
	    }
	}
          
      // Reenable displaying of menus
      [self setMenuChangedMessagesEnabled: YES];
    }

  if (_changed)
    [self sizeToFit];

  return;
}

//
// Handling Keyboard Equivalents
//
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  unsigned      i;
  unsigned      count = [_items count];
  NSEventType   type = [theEvent type];
         
  if (type != NSKeyDown && type != NSKeyUp) 
    return NO;
             
  for (i = 0; i < count; i++)
    {
      NSMenuItem *item = [_items objectAtIndex: i];
                                    
      if ([item hasSubmenu])
        {
	  // FIXME: Should we only check active submenus?
	  // Recurse through submenus.
          if ([[item submenu] performKeyEquivalent: theEvent])
            {
              // The event has been handled by an item in the submenu.
              return YES;
            }
        }
      else
        {
	  // FIXME: Should also check the modifier mask  
          if ([[item keyEquivalent] isEqualToString: 
				      [theEvent charactersIgnoringModifiers]])
	    {
	      [_view performActionWithHighlightingForItemAtIndex: i];
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
  id<NSMenuItem> item = [_items objectAtIndex: index];
  NSDictionary *d;
  SEL action;

  if (![item isEnabled])
    return;

  // Send the actual action and the estipulated notifications.
  d = [NSDictionary dictionaryWithObject: item forKey: @"MenuItem"];
  [nc postNotificationName: NSMenuWillSendActionNotification
                    object: self
                  userInfo: d];


  if (_popUpButtonCell != nil)
    {
      // Tell the popup button, which item was selected
      [_popUpButtonCell selectItemAtIndex: index];
    }

  if ((action = [item action]) != NULL)
    {
      [NSApp sendAction: action
	     to: [item target]
	     from: item];
    }
  else if (_popUpButtonCell != nil)
    {
      if ((action = [_popUpButtonCell action]) != NULL)
	[NSApp sendAction: action
	       to: [_popUpButtonCell target]
	       from: [_popUpButtonCell controlView]];
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
  ASSIGN(_title, aTitle);
  [self sizeToFit];
}
  
- (NSString*) title
{
  return _title;
}

//
// Setting the Representing Object
//
- (void) setMenuRepresentation: (id)menuRep
{
  NSView *contentView;

  if (![menuRep isKindOfClass: [NSMenuView class]])
    {
      NSLog(@"You must use an NSMenuView, or a derivative thereof.\n");
      return;
    }

  // remove the old representation
  contentView = [_aWindow contentView];
  [contentView removeSubview: _view];

  ASSIGN(_view, menuRep);
  [_view setMenu: self];

  // add the new representation
  [contentView addSubview: _view];
}

- (id) menuRepresentation
{
  return _view;
}

//
// Updating the Menu Layout
//
- (void) setMenuChangedMessagesEnabled: (BOOL)flag
{ 
  if (_changedMessagesEnabled != flag)
    {
      if (flag)
	{
	  if ([_notifications count])
	    {
	      NSEnumerator *enumerator = [_notifications objectEnumerator];
	      id            aNotification;

	      while ((aNotification = [enumerator nextObject]))
		[nc postNotification: aNotification];
	    }

	  // Clean the notification array.
	  [_notifications removeAllObjects];
	}

      _changedMessagesEnabled = flag;
    }
}
 
- (BOOL) menuChangedMessagesEnabled
{
  return _changedMessagesEnabled;
}

- (void) sizeToFit
{
  NSRect windowFrame;
  NSRect menuFrame;
  NSSize size;

  //if ([_view needsSizing])
    [_view sizeToFit];

  menuFrame = [_view frame];
  size = menuFrame.size;

  windowFrame = [_aWindow frame];

  if (_popUpButtonCell == nil)
    {
      float height = [[_view class] menuBarHeight];

      size.height += height;
      [_aWindow setContentSize: size];
      [_aWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];

      windowFrame = [_bWindow frame];
      [_bWindow setContentSize: size];
      [_bWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];

      [_view setFrameOrigin: NSMakePoint (0, 0)];
      [_titleView setFrame: NSMakeRect (0, size.height - height, 
				       size.width, height)];
      [_titleView setNeedsDisplay: YES];
    }
  else
    {
      [_aWindow setContentSize: size];
      [_aWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];
    }

  [_view setNeedsDisplay: YES];

  _changed = NO;
}

/*
 * Displaying Context Sensitive Help
 */
- (void) helpRequested: (NSEvent *)event
{
  // TODO: Won't be implemented until we have NSHelp*
}

+ (void) popUpContextMenu: (NSMenu*)menu
		withEvent: (NSEvent*)event
		  forView: (NSView*)view
{
  // TODO
}

/*
 * NSObject Protocol
 */
- (BOOL) isEqual: (id)anObject
{
  if (self == anObject)
    return YES;
  if ([anObject isKindOfClass: [NSMenu class]])
    {
      if (![_title isEqualToString: [anObject title]])
	return NO;
      return [[self itemArray] isEqual: [anObject itemArray]];
    }
  return NO;
}

/*
 * NSCoding Protocol
 */
- (void) encodeWithCoder: (NSCoder*)encoder
{
  [encoder encodeObject: _title];
  [encoder encodeObject: _items];
  [encoder encodeValueOfObjCType: @encode(BOOL) at: &_autoenable];
}

- (id) initWithCoder: (NSCoder*)decoder
{
  NSString	*dTitle;
  NSArray	*dItems;
  BOOL		dAuto;
  unsigned	i;

  dTitle = [decoder decodeObject];
  dItems = [decoder decodeObject];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &dAuto];

  self = [self initWithTitle: dTitle];
  [self setAutoenablesItems: dAuto];

  [self setMenuChangedMessagesEnabled: NO];
  /*
   * Make sure that items and submenus are set correctly.
   */
  for (i = 0; i < [dItems count]; i++)
    {
      NSMenuItem	*item = [dItems objectAtIndex: i];
      NSMenu		*sub = [item submenu];

      [self addItem: item];
      // FIXME: We propably don't need this, as all the fields are
      // already set up for the submenu item.
      if (sub != nil)
	{
	  [sub setSupermenu: nil];
	  [self setSubmenu: sub  forItem: item];
	}
    }
  [self setMenuChangedMessagesEnabled: YES];

  return self;
}

/*
 * NSCopying Protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSMenu *new = [[NSMenu allocWithZone: zone] initWithTitle: _title];
  unsigned i;
  unsigned count = [_items count];

  [new setAutoenablesItems: _autoenable];
  for (i = 0; i < count; i++)
    {
      // This works because the copy on NSMenuItem sets the menu to nil!!!
      [new insertItem: [[_items objectAtIndex: i] copyWithZone: zone]
	   atIndex: i];
    }
  
  return new;
}

@end

@implementation NSMenu (GNUstepExtra)

#define IS_OFFSCREEN(WINDOW) \
  !(NSContainsRect([[NSScreen mainScreen] frame], [WINDOW frame]))

- (void) _setTornOff: (BOOL)flag
{
  NSMenu	*supermenu;

  _is_tornoff = flag;

  if (flag)
    [_titleView addCloseButton];
  else
    [_titleView releaseCloseButton];

  supermenu = [self supermenu];
  if (supermenu != nil)
    {
      [[supermenu menuRepresentation] setHighlightedItemIndex: -1];
      supermenu->_attachedMenu = nil;
    }
}

- (void) _showTornOffMenuIfAny: (NSNotification*)notification
{
  if ([NSApp mainMenu] != self)
    {
      NSString		*key;

      key = [self _locationKey];
      if (key != nil)
	{
	  NSString		*location;
	  NSUserDefaults	*defaults;
	  NSDictionary		*menuLocations;

	  defaults  = [NSUserDefaults standardUserDefaults];
	  menuLocations = [defaults objectForKey: NSMenuLocationsKey];
      
	  location = [menuLocations objectForKey: key];
	  if (location && [location isKindOfClass: [NSString class]])
	    {
	      [self _setTornOff: YES];
	      [self display];
	    }
	}
    }
}

- (BOOL) isFollowTransient
{
  return _follow_transient;
} 

- (BOOL) isPartlyOffScreen
{
  return _isPartlyOffScreen;
}

- (void) nestedCheckOffScreen
{
  // This method is used when the menu is moved.
  if (_attachedMenu)
    [_attachedMenu nestedCheckOffScreen];

  _isPartlyOffScreen = IS_OFFSCREEN(_aWindow);
}

- (void) _performMenuClose: (id)sender
{
  NSString		*key;

  if (_attachedMenu)
    [_view detachSubmenu];

  key = [self _locationKey];
  if (key != nil)
    {
      NSUserDefaults		*defaults;
      NSMutableDictionary	*menuLocations;

      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [[defaults objectForKey: NSMenuLocationsKey] mutableCopy];
      [menuLocations removeObjectForKey: key];
      if ([menuLocations count] > 0)
        [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
      else
        [defaults removeObjectForKey: NSMenuLocationsKey];
      RELEASE(menuLocations);
      [defaults synchronize];
    }

  [_view setHighlightedItemIndex: -1];
  [self _setTornOff: NO];
  [self close];
} 

- (void) _rightMouseDisplay: (NSEvent*)theEvent
{
  [self displayTransient];
  [_view mouseDown: theEvent];
  [self closeTransient];
}

- (void) display
{
  NSString *key;

  if (_changed)
    [self sizeToFit];

  if (_superMenu && ![self isTornOff])
    {                 
      // query super menu for position
      [_aWindow setFrameOrigin: [_superMenu locationForSubmenu: self]];
      _superMenu->_attachedMenu = self;
    }
  else if (nil != (key = [self _locationKey]))
    {
      NSUserDefaults *defaults;
      NSDictionary *menuLocations;
      NSString *location;

      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [defaults objectForKey: NSMenuLocationsKey];
      location = [menuLocations objectForKey: key];
      if (location && [location isKindOfClass: [NSString class]])
        {
	  [_aWindow setFrameFromString: location];
	  /*
	   * May need resize in case saved frame is out of sync
	   * with number of items in menu.
	   */
	  [self sizeToFit];
	}
      else
        {
	  NSPoint aPoint = {0, [[NSScreen mainScreen] frame].size.height
			    - [_aWindow frame].size.height};
	  
	  [_aWindow setFrameOrigin: aPoint];
	  [_bWindow setFrameOrigin: aPoint];
	}
    }

  [_aWindow orderFrontRegardless];

  _isPartlyOffScreen = IS_OFFSCREEN(_aWindow);

  /*
   * If we have just been made visible, we must make sure that any attached
   * submenu is visible too.
   */
  [[self attachedMenu] display];
}

- (void) displayTransient
{
  NSPoint location;
  NSView *contentView;

  _follow_transient = YES;

  /*
   * Cache the old submenu if any and query the supermenu our position.
   * Otherwise, raise menu under the mouse.
   */
  if (_superMenu != nil)
    {
      _oldAttachedMenu = _superMenu->_attachedMenu;
      _superMenu->_attachedMenu = self;
      location = [_superMenu locationForSubmenu: self];
    }
  else
    {
      NSRect	frame = [_aWindow frame];

      location = [_aWindow mouseLocationOutsideOfEventStream];
      location = [_aWindow convertBaseToScreen: location];
      location.x -= frame.size.width/2;
      if (location.x < 0)
	location.x = 0;
      location.y -= frame.size.height - 10;
    }

  [_bWindow setFrameOrigin: location];

  [_view removeFromSuperviewWithoutNeedingDisplay];
  [_titleView removeFromSuperviewWithoutNeedingDisplay];

  if (_is_tornoff)
    [_titleView releaseCloseButton];

  contentView = [_bWindow contentView];
  [contentView addSubview: _view];
  [contentView addSubview: _titleView];

  [_bWindow orderFront: self];

  _isPartlyOffScreen = IS_OFFSCREEN(_bWindow);
}

- (void) close
{
  NSMenu *sub = [self attachedMenu];

  /*
   * If we have an attached submenu, we must close that too - but then make
   * sure we still have a record of it so that it can be re-displayed if we
   * are redisplayed.
   */
  if (sub != nil)
    {
      [sub close];
      _attachedMenu = sub;
    }
  [_aWindow orderOut: self];

  if (_superMenu)
    _superMenu->_attachedMenu = nil;
}

- (void) closeTransient
{
  NSView *contentView;
  
  [_bWindow orderOut: self];
  [_view removeFromSuperviewWithoutNeedingDisplay];
  [_titleView removeFromSuperviewWithoutNeedingDisplay];

  contentView = [_aWindow contentView];
  [contentView addSubview: _view];

  if (_is_tornoff)
    [_titleView addCloseButton];

  [contentView addSubview: _titleView];
  [contentView setNeedsDisplay: YES];

  // Restore the old submenu (if any).
  if (_superMenu != nil)
    _superMenu->_attachedMenu = _oldAttachedMenu;

  _follow_transient = NO;

  _isPartlyOffScreen = IS_OFFSCREEN(_aWindow);
}

- (NSWindow*) window
{
  if (_follow_transient)
    return (NSWindow *)_bWindow;
  else
    return (NSWindow *)_aWindow;
}

/**
   Set the frame origin of the receiver to aPoint. If a submenu of
   the receiver is attached. The frame origin of the submenu is set
   appropriately.
*/
- (void) nestedSetFrameOrigin: (NSPoint) aPoint
{
  NSWindow *theWindow = _follow_transient ? _bWindow : _aWindow;

  // Move ourself and get our width.
  [theWindow setFrameOrigin: aPoint];

  // Do the same for attached menus.
  if (_attachedMenu)
    {
      aPoint = [self locationForSubmenu: _attachedMenu];
      [_attachedMenu nestedSetFrameOrigin: aPoint];
    }
}

#define SHIFT_DELTA 18.0

- (void) shiftOnScreen
{
  NSWindow *theWindow = _follow_transient ? _bWindow : _aWindow;
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
	     (candidateMenu = masterMenu->_superMenu)
	       && (!masterMenu->_is_tornoff
		   || masterMenu->_follow_transient);
	     masterMenu = candidateMenu);

	masterLocation = [[masterMenu window] frame].origin;
	destinationPoint.x = masterLocation.x + vector.x;
	destinationPoint.y = masterLocation.y + vector.y;

	[masterMenu nestedSetFrameOrigin: destinationPoint];
    }
  else
    _isPartlyOffScreen = NO;
}

- (BOOL)_ownedByPopUp
{
  return _popUpButtonCell != nil;
}

- (void)_setOwnedByPopUp: (NSPopUpButtonCell*)popUp
{
  if (_popUpButtonCell != popUp)
    {
      _popUpButtonCell = popUp;
      if (popUp != nil)
	{
	  [_titleView removeFromSuperviewWithoutNeedingDisplay];
	  [_aWindow setLevel: NSPopUpMenuWindowLevel];
	  [_bWindow setLevel: NSPopUpMenuWindowLevel];
	}

      {
	NSArray *itemCells = [_view _itemCells];
	int i;
	int count = [itemCells count];
	
	for ( i = 0; i < count; i++ )
	  {
	    [[itemCells objectAtIndex: i] setMenuView: _view];
	  }
      }
    }
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
  NSRect workRect = [self bounds];
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
  float grays[] = {NSDarkGray, NSDarkGray};
  /* Cache the title attributes */
  static NSDictionary *attr = nil;

  // Draw the dark gray upper left lines.
  workRect = NSDrawTiledRects(workRect, workRect, sides, grays, 2);
  
  // Draw the title box's button.
  NSDrawButton(workRect, workRect);
  
  // Paint it Black!
  workRect.origin.x += 1;
  workRect.origin.y += 2;
  workRect.size.height -= 3;
  workRect.size.width -= 3;
  [[NSColor windowFrameColor] set];
  NSRectFill(workRect);

  // Draw the title
  if (attr == nil)
    {
      attr = [[NSDictionary alloc] 
	       initWithObjectsAndKeys: 
		 [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
	       [NSColor windowFrameTextColor], NSForegroundColorAttributeName,
	       nil];
    }

  // This gives the correct position
  workRect.origin.x += 5;
  workRect.size.width -= 5;
  workRect.size.height -= 2;
  [[menu title] drawInRect: workRect  withAttributes: attr];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSString		*key;
  NSPoint		lastLocation;
  NSPoint		location;
  unsigned		eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  BOOL			done = NO;
  NSDate		*theDistantFuture = [NSDate distantFuture];

  lastLocation = [theEvent locationInWindow];
   
  if (![menu isTornOff] && [menu supermenu])
    {
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
	  location = [_window mouseLocationOutsideOfEventStream];
	  if (NSEqualPoints(location, lastLocation) == NO)
	    {
	      NSPoint origin = [_window frame].origin;

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
  key = [menu _locationKey];
  if (key != nil)
    {
      NSUserDefaults		*defaults;
      NSMutableDictionary	*menuLocations;
      NSString			*locString;

      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [[defaults objectForKey: NSMenuLocationsKey] mutableCopy];
      if (menuLocations == nil)
	{
	  menuLocations = AUTORELEASE([[NSMutableDictionary alloc] initWithCapacity: 2]);
	}
      locString = [[menu window] stringWithSavedFrame];
      [menuLocations setObject: locString forKey: key];
      [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
      [defaults synchronize];
    }
}

- (void) createButton
{
  // create the menu's close button
  NSImage* closeImage = [NSImage imageNamed: @"common_Close"];
  NSImage* closeHImage = [NSImage imageNamed: @"common_CloseH"];
  NSSize imageSize = [closeImage size];
  NSRect rect = { { _frame.size.width - imageSize.width - 4,
		    (_frame.size.height - imageSize.height) / 2},
		  { imageSize.height, imageSize.width } };

  button = [[NSButton alloc] initWithFrame: rect];
  [button setButtonType: NSMomentaryLight];
  [button setImagePosition: NSImageOnly];
  [button setImage: closeImage];
  [button setAlternateImage: closeHImage];
  [button setBordered: NO];
  [button setTarget: menu];
  [button setAction: @selector(_performMenuClose:)];
  [button setAutoresizingMask: NSViewMinXMargin];
  
  [self setAutoresizingMask: NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];
}
            
- (void) releaseCloseButton
{
  [button removeFromSuperview];
}
  
- (void) addCloseButton
{
  if (button == nil)
    [self createButton];
  [self addSubview: button];
  [self setNeedsDisplay: YES];
}

- (void) rightMouseDown: (NSEvent*)theEvent
{
  // Dont show our menu
}

@end /* NSMenuWindowTitleView */
