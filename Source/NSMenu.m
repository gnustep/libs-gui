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

@interface NSMenuWindow : NSPanel

- (void)moveToPoint:(NSPoint)aPoint;

@end

/* A menu's title is an instance of this class */
@interface NSMenuWindowTitleView : NSView
{
  int titleHeight;
  id  menu;
  NSButton* button;
  NSButtonCell* buttonCell;
}

- (void) _addCloseButton;
- (void) _releaseCloseButton;
- (void) windowBecomeTornOff;
- (void) setMenu: (NSMenu*)menu;
- (NSMenu*) menu;

@end

@interface NSMenuWindowTitleView (height)
+ (float) titleHeight;
@end

@implementation NSMenuWindowTitleView (height)
+ (float) titleHeight
{
  NSFont *font = [NSFont boldSystemFontOfSize: 0.0];

  /* Should make up 23 for the default font */
  return ([font boundingRectForFont].size.height) + 8;
}
@end

static NSZone	*menuZone = NULL;

static NSString	*NSMenuLocationsKey = @"NSMenuLocations";

@interface	NSMenu (GNUstepPrivate)
- (NSString*) _locationKey;
@end

@implementation	NSMenu (GNUstepPrivate)
- (NSString*) _locationKey
{
  if (_is_beholdenToPopUpButton == YES)
    {
      return nil;		/* Can't save	*/
    }
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

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

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
  float                 height = [NSMenuWindowTitleView titleHeight];
  NSRect                winRect   =  { {0 , 0}, {20, height} };
  NSView *contentView;

  [super init];

  // Keep the title.
  ASSIGN(_title, aTitle);

  // Create an array to store out menu items.
  _items = [[NSMutableArray alloc] init];

  // Create a NSMenuView to draw our menu items.
  _view = [[NSMenuView alloc] initWithFrame: NSMakeRect(0,0,50,50)];

  // Set ourself as the menu for this view.
  [_view setMenu: self];

  // We have no supermenu.
  // _superMenu = nil;
  // _is_tornoff = NO;
  // _follow_transient = NO;
  // _is_beholdenToPopUpButton = NO;

  _changedMessagesEnabled = YES;
  _notifications = [[NSMutableArray alloc] init];
  _changed = YES;
  // According to the spec, menus do autoenable by default.
  _autoenable = YES;

  // Transient windows private stuff.
  // _oldAttachedMenu = nil;

  // Create the windows that will display the menu.
  _aWindow = [[NSMenuWindow alloc] init];
  _bWindow = [[NSMenuWindow alloc] init];

  _titleView = [[NSMenuWindowTitleView alloc] init];
  [_titleView setFrameOrigin: NSMakePoint(0, winRect.size.height - height)];
  [_titleView setFrameSize: NSMakeSize (winRect.size.width, height)];

  contentView = [_aWindow contentView];
  [contentView addSubview: _view];
  [contentView addSubview: _titleView];

  [_titleView setMenu: self];

  // Set up the notification to start the process of redisplaying
  // the menus where the user left them the last time.
  [[NSNotificationCenter defaultCenter] addObserver: self
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

          [_items insertObject: newItem atIndex: index];
	  [(NSMenuItem *)newItem setMenu: self];

	  // Create the notification for the menu representation.
	  inserted = [NSNotification
		       notificationWithName: NSMenuDidAddItemNotification
		                     object: self
		                   userInfo: d];

	  if (_changedMessagesEnabled)
	    [[NSNotificationCenter defaultCenter] postNotification: inserted];
	  else
	    [_notifications addObject: inserted];
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

  _changed = YES;
}

- (id <NSMenuItem>) insertItemWithTitle: (NSString*)aString
			         action: (SEL)aSelector
			  keyEquivalent: (NSString*)charCode 
			        atIndex: (unsigned int)index
{
  id anItem = [[NSMenuItem alloc] init];

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
  [self removeItemAtIndex: [_items indexOfObjectIdenticalTo: anItem]];
}

- (void) removeItemAtIndex: (int)index
{
  NSNotification	*removed;
  NSDictionary		*d;
  id			anItem = [_items objectAtIndex: index];

  if (!anItem)
    return;

  if ([anItem isKindOfClass: [NSMenuItem class]])
    {
      d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: index]
				      forKey: @"NSMenuItemIndex"];

      [anItem setMenu: nil];
      [_items removeObjectAtIndex: index];

      removed = [NSNotification
		  notificationWithName: NSMenuDidRemoveItemNotification
		                object: self
		              userInfo: d];

      if (_changedMessagesEnabled)
	[[NSNotificationCenter defaultCenter] postNotification: removed];
      else
	[_notifications addObject: removed];
    }
  else
    {
      NSLog(@"You must use an NSMenuItem, or a derivative thereof.\n");
    }

  _changed = YES;
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

  if (_changedMessagesEnabled)
    [[NSNotificationCenter defaultCenter] postNotification: changed];
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
      if ([[[_items objectAtIndex: i] title]
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
	    forItem: (id <NSMenuItem>)anItem 
{
  [(NSMenuItem *)anItem setSubmenu: aMenu];
  [anItem setTarget: self];
  [anItem setAction: @selector(submenuAction:)];
  if (aMenu != nil)
    {
      aMenu->_superMenu = self;
      ASSIGN(aMenu->_title, [anItem title]);
    }
  [self itemChanged: anItem];
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
  NSRect	frame;
  NSRect	submenuFrame;
  NSWindow	*win_link;

  if (![self isFollowTransient])
    {
      win_link = _aWindow;
    }
  else
    {
      win_link = _bWindow;
    }

  frame = [win_link frame];
            
  if (aSubmenu)
    {
      submenuFrame = [aSubmenu->_aWindow frame];
    }
  else
    submenuFrame = NSZeroRect;

  // FIXME: Fix this to support styles when the menus move.
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil)
      == GSWindowMakerInterfaceStyle)
    {
      NSRect aRect = [_view rectOfItemAtIndex: 
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
  return _superMenu;
}

- (void) setSupermenu: (NSMenu *)supermenu
{
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
	  // Recurse through submenus.
          if ([[item submenu] performKeyEquivalent: theEvent])
            {
              // The event has been handled by an item in the submenu.
              return YES;
            }
        }
      else
        {
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
      [NSApp sendAction: [item action]
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
  if ([menuRep isKindOfClass: [NSMenuView class]])
    ASSIGN(_view, menuRep);
  else
    NSLog(@"You must use an NSMenuView, or a derivative thereof.\n");
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
	      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
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

  windowFrame = [_aWindow frame];
  [_view sizeToFit];

  menuFrame = [_view frame];

  size.width = menuFrame.size.width;
  size.height = menuFrame.size.height;

  if (!_is_beholdenToPopUpButton)
    {
      float height = [NSMenuWindowTitleView titleHeight];

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
    }
  else
    {
      [_aWindow setContentSize: size];
      [_aWindow setFrameTopLeftPoint:
	NSMakePoint(NSMinX(windowFrame),NSMaxY(windowFrame))];
    }

  [_aWindow display];

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

  /*
   * Make sure that items and submenus are set correctly.
   */
  for (i = 0; i < [dItems count]; i++)
    {
      NSMenuItem	*item = [dItems objectAtIndex: i];
      NSMenu		*sub = [item submenu];

      [self addItem: item];
      if (sub != nil)
	{
	  [self setSubmenu: sub forItem: item];
	}
    }

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

  _is_tornoff = flag;

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
	      [_titleView windowBecomeTornOff];
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
  [_titleView _releaseCloseButton];
} 

- (void) _rightMouseDisplay: (NSEvent*)theEvent
{
  [self displayTransient];
  [_view mouseDown: theEvent];
  [self closeTransient];
}

- (void) display
{
  if (_changed)
    [self sizeToFit];

  if (_is_beholdenToPopUpButton)
    {
      [_aWindow orderFront: nil];
      return;
    }

  if (_superMenu && ![self isTornOff])      // query super menu for
    {                                           // position
      [_aWindow setFrameOrigin: [_superMenu locationForSubmenu: self]];
      _superMenu->_attachedMenu = self;
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
    [_titleView _releaseCloseButton];

  contentView = [_bWindow contentView];
  [contentView addSubview: _view];
  [contentView addSubview: _titleView];

  [_bWindow orderFront: self];

  _isPartlyOffScreen = IS_OFFSCREEN(_bWindow);
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
    [_titleView _addCloseButton];

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

- (void) nestedSetFrameOrigin: (NSPoint) aPoint
{
  NSRect frame;

  // Move ourself and get our width.
  if (_follow_transient)
    {
      [(NSMenuWindow*)_bWindow moveToPoint: aPoint];
      frame = [_bWindow frame];
    }
  else
    {
      [(NSMenuWindow*)_aWindow moveToPoint: aPoint];
      frame = [_aWindow frame];
    }


  // Do the same for attached menus.
  if (_attachedMenu)
    {
      // First locate the origin.
      aPoint.x += frame.size.width;
      aPoint.y += frame.size.height
	- [_attachedMenu->_aWindow frame].size.height;
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
  return _is_beholdenToPopUpButton;
}

- (void)_setOwnedByPopUp: (BOOL)flag
{
  if (_is_beholdenToPopUpButton != flag)
    {
      _is_beholdenToPopUpButton = flag;
      if (flag == YES)
	{
	  [_titleView removeFromSuperviewWithoutNeedingDisplay];
	  [_aWindow setLevel: NSPopUpMenuWindowLevel];
	  [_bWindow setLevel: NSPopUpMenuWindowLevel];
	}
    }
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

- (void) _initDefaults
{
  [super _initDefaults];
  _windowLevel = NSSubmenuWindowLevel;
}

- (id) init
{
  self = [self initWithContentRect: NSZeroRect
			 styleMask: NSBorderlessWindowMask
			   backing: NSBackingStoreBuffered
			     defer: YES];
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
  NSRect frameRect = _frame;

  frameRect.origin = aPoint;
  DPSplacewindow(GSCurrentContext(), frameRect.origin.x, frameRect.origin.y,
		 frameRect.size.width, frameRect.size.height, 
		 [self windowNumber]);
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
	  menuLocations = [[NSMutableDictionary alloc] initWithCapacity: 2];
	}
      locString = [[menu window] stringWithSavedFrame];
      [menuLocations setObject: locString forKey: key];
      [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
      RELEASE(menuLocations);
      [defaults synchronize];
    }
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
      NSRect rect = { { _frame.size.width - imageSize.width - 4,
                      (_frame.size.height - imageSize.height) / 2},
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
  RETAIN(button);
  [button removeFromSuperview];
}
  
- (void) _addCloseButton
{
  [self addSubview: button];
}
@end /* NSMenuWindowTitleView */
