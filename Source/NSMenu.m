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

#include "config.h"
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include "AppKit/NSMatrix.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSMenuView.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSPopUpButton.h"
#include "AppKit/NSPopUpButtonCell.h"
#include "AppKit/NSScreen.h"
#include "AppKit/NSAttributedString.h"


/*
  Drawing related:

              NSMenu superMenu   (if not root menu, the parent meu)
                ^
                |
                |    +------------------> NSMenuView view  (content, draws the menu items)
                |    |
              NSMenu +----------+-------> NSMenuPanel A    (regular window, torn off window)
                |    |          `-------> NSMenuPanel B    (transient window)
                |    |           
                |    +------------------> NSString title   (title)
                |
                v
              NSMenu attachedMenu  (the menu that is attached to this one, during navigation)
              


   +--[NSMenuPanel]------+
   | +-[NSMenuView]----+ |
   | | title if applic | |
   | | +-------------+ | |
   | | | NSMenuItem- | | |
   | | | Cell        | | |
   | | +-------------+ | |
   | |       .         | |
   | |       .         | |
   | +-----------------+ |
   +---------------------+

   The two windows
   ---------------

   Basically we have for a menu two windows, window A and window B.
   Window A is the regular window and Window B is used for transient windows.

   At any one time, the views, like title view, NSMenuView are put either in
   window A or in window B.  They are moved over from one window to the oter
   when needed.

   the code is supposed to know when it is using window A or B.
   But it will probably only work correctly when

   window A correspond to _transient == NO
   window B correspond to _transient == YES
*/


/* Subclass of NSPanel since menus cannot become key */
@interface NSMenuPanel : NSPanel
@end

@interface NSMenuView (GNUstepPrivate)
- (NSArray *)_itemCells;
@end


static NSZone	*menuZone = NULL;
static NSString	*NSMenuLocationsKey = @"NSMenuLocations";
static NSString *NSEnqueuedMenuMoveName = @"EnqueuedMoveNotificationName";
static NSNotificationCenter *nc;

@interface	NSMenu (GNUstepPrivate)

- (NSString *) _locationKey;
- (NSMenuPanel *) _createWindow;
- (void) _updateUserDefaults: (id) notification;
- (void) _rightMouseDisplay: (NSEvent*)theEvent;

@end


@implementation NSMenuPanel
- (BOOL) canBecomeKeyWindow
{
  /* See [NSWindow-_lossOfKeyOrMainWindow] */
  if (self == (NSMenuPanel *)[[NSApp mainMenu] window])
    return YES;
  return NO;
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

/**
   Will track the mouse movement.  It will trigger the updating of the user
   defaults in due time.
*/
- (void) _menuMoved: (id) notification
{
  NSNotification *resend;

  resend = [NSNotification notificationWithName: NSEnqueuedMenuMoveName
					 object: self];
  
  [[NSNotificationQueue defaultQueue]
    enqueueNotification: resend
    postingStyle: NSPostASAP
    coalesceMask: NSNotificationCoalescingOnSender
    forModes:  [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

/**
   Save the current menu position in the standard user defaults
*/
- (void) _updateUserDefaults: (id) notification
{
  NSString *key;

  NSDebugLLog (@"NSMenu", @"Synchronizing user defaults");
  key = [self _locationKey];
  if (key != nil)
    {
      NSUserDefaults		*defaults;
      NSMutableDictionary	*menuLocations;
      NSString			*locString;

      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [defaults objectForKey: NSMenuLocationsKey];
      if ([menuLocations isKindOfClass: [NSDictionary class]])
	menuLocations = [menuLocations mutableCopy];
      else
	menuLocations = nil;

      if ([_aWindow isVisible]
	&& ([self isTornOff] || ([NSApp mainMenu] == self)))
        {
          if (menuLocations == nil)
            {
              menuLocations = AUTORELEASE([[NSMutableDictionary alloc]
		initWithCapacity: 2]);
            }
          locString = [[self window] stringWithSavedFrame];
          [menuLocations setObject: locString forKey: key];
        }
      else
        {
          [menuLocations removeObjectForKey: key];
        }

      if ([menuLocations count] > 0)
        {
          [defaults setObject: menuLocations forKey: NSMenuLocationsKey];
        }
      else
        {
          [defaults removeObjectForKey: NSMenuLocationsKey];
        }
      [defaults synchronize];
    }
}

- (void) _rightMouseDisplay: (NSEvent*)theEvent
{
  [self displayTransient];
  [_view mouseDown: theEvent];
  [self closeTransient];
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
 *
 */
- (id) init
{
  return [self initWithTitle: [[NSProcessInfo processInfo] processName]];
}

- (void) dealloc
{
  [nc removeObserver: self];

  // Now clean the pointer to us stored each _items element
  [_items makeObjectsPerformSelector: @selector(setMenu:) withObject: nil];

  RELEASE(_notifications);
  RELEASE(_title);
  RELEASE(_items);
  [_view setMenu: nil];
  RELEASE(_view);
  RELEASE(_aWindow);
  RELEASE(_bWindow);

  [super dealloc];
}

/*
   
*/
- (id) initWithTitle: (NSString*)aTitle
{
  NSMenuView *menuRep;

  [super init];

  // Keep the title.
  ASSIGN(_title, aTitle);

  // Create an array to store our menu items.
  _items = [[NSMutableArray alloc] init];

  _changedMessagesEnabled = YES;
  _notifications = [[NSMutableArray alloc] init];
  _needsSizing = YES;
  // According to the spec, menus do autoenable by default.
  _autoenable = YES;


  /* Please note that we own all this menu network of objects.  So, 
     none of these objects should be retaining us.  When we are deallocated,
     we release all the objects we own, and that should cause deallocation
     of the whole menu network.  */

  // Create the windows that will display the menu.
  _aWindow = [self _createWindow];
  _bWindow = [self _createWindow];
  [_bWindow setLevel: NSPopUpMenuWindowLevel];

  // Create a NSMenuView to draw our menu items.
  menuRep = [[NSMenuView alloc] initWithFrame: NSZeroRect];
  [self setMenuRepresentation: menuRep];
  RELEASE(menuRep);

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

  [nc addObserver: self
      selector: @selector(_showOnActivateApp:)
      name: NSApplicationWillBecomeActiveNotification 
      object: NSApp];

  [nc addObserver: self
      selector: @selector (_menuMoved:)
      name: NSWindowDidMoveNotification
      object: _aWindow];

  [nc addObserver: self
      selector: @selector (_updateUserDefaults:)
      name: NSEnqueuedMenuMoveName
      object: self];
  
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
    {
      NSLog(@"The object %@ is already attached to a menu, then it isn't possible to add it.\n", newItem);
      return;
    }
  
  [_items insertObject: newItem atIndex: index];
  _needsSizing = YES;
  
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
  _needsSizing = YES;
  
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
}

- (void) itemChanged: (id <NSMenuItem>)anObject
{
  NSNotification *changed;
  NSDictionary   *d;
  int index = [self indexOfItem: anObject];

  if (-1 == index)
    return;

  _needsSizing = YES;

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
  if (index >= (int)[_items count] || index < 0)
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
}


- (NSMenu *) attachedMenu
{
  if (_attachedMenu && _transient
      && !_attachedMenu->_transient)
    return nil;

  return _attachedMenu;
}


/**
   Look for the semantics in the header.  Note that
   this implementation works because there are ... cases:
   <enum>
   <item>
   This menu is transient, its supermenu is also transient.
   In this case we just do the check between the transient windows
   and everything is fine
   </item>
   <item>
   The menu is transient, its supermenu is not transient.
   This can go WRONG
   </item>
   </enum>
*/
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
	  id	      validator = nil;
	  BOOL	      wasEnabled = [item isEnabled];
	  BOOL	      shouldBeEnabled;

	  // Update the submenu items if any.
	  if ([item hasSubmenu])
	    [[item submenu] update];

	  // If there is no action - there can be no validator for the item.
	  if (action)
	    {
	      validator = [NSApp targetForAction: action 
				 to: [item target]
				 from: item];
	    }
	  else if (_popUpButtonCell != nil)
	    {
	      if (NULL != (action = [_popUpButtonCell action]))
	        {
		  validator = [NSApp targetForAction: action
				     to: [_popUpButtonCell target]
				     from: [_popUpButtonCell controlView]];
		}
	    }

	  if (validator == nil)
	    {
	      if ((action == NULL) && (_popUpButtonCell != nil))
		{
		  shouldBeEnabled = YES;
		}
	      else 
		{
		  shouldBeEnabled = NO;
		}
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

  if (_needsSizing && ([_aWindow isVisible] || [_bWindow isVisible]))
    {
      NSDebugLLog (@"NSMenu", @" Calling Size To Fit (A)");
      [self sizeToFit];
    }
  
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
	      if ([item isEnabled])
		{
		  [_view performActionWithHighlightingForItemAtIndex: i];
		}
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

  _needsSizing = YES;
  if ([_aWindow isVisible] || [_bWindow isVisible])
    {
      [self sizeToFit];
    }
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

  if (_view == menuRep)
    {
      return;
    }

  contentView = [_aWindow contentView];
  if (_view != nil)
    {
      // remove the old representation
      [contentView removeSubview: _view];
      [_view setMenu: nil];
    }

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
// Wim 20030301: Question, what happens when the notification trigger
// new notifications?  I think it is not allowed to add items
// to the _notifications array while enumerating it.
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
  NSRect oldWindowFrame;
  NSRect newWindowFrame;
  NSRect menuFrame;
  NSSize size;

  [_view sizeToFit];
  
  menuFrame = [_view frame];
  size = menuFrame.size;
 
	// Main
  oldWindowFrame = [_aWindow frame];
  newWindowFrame = [NSWindow frameRectForContentRect: menuFrame
                             styleMask: [_aWindow styleMask]];
  
  if (oldWindowFrame.size.height > 1)
    {
      newWindowFrame.origin = NSMakePoint (oldWindowFrame.origin.x,
                                           oldWindowFrame.origin.y
                                           + oldWindowFrame.size.height
                                           - newWindowFrame.size.height);
    }
  [_aWindow setFrame: newWindowFrame display: NO];
  
  // Transient
  oldWindowFrame = [_bWindow frame];
  newWindowFrame = [NSWindow frameRectForContentRect: menuFrame
                             styleMask: [_bWindow styleMask]];
  if (oldWindowFrame.size.height > 1)
    {
      newWindowFrame.origin = NSMakePoint (oldWindowFrame.origin.x,
                                           oldWindowFrame.origin.y
                                           + oldWindowFrame.size.height
                                           - newWindowFrame.size.height);
    }
  [_bWindow setFrame: newWindowFrame display: NO];
  
  if (_popUpButtonCell == nil)
    {
      [_view setFrameOrigin: NSMakePoint (0, 0)];
    }
  
  [_view setNeedsDisplay: YES];
  
  _needsSizing = NO;
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
  [menu _rightMouseDisplay: event];
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

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSString	*dTitle;
  NSArray	*dItems;
  BOOL		dAuto;
  unsigned	i;

  if ([aDecoder allowsKeyedCoding])
    {
      dAuto = YES;
      dTitle = [aDecoder decodeObjectForKey: @"NSTitle"];
      dItems = [aDecoder decodeObjectForKey: @"NSMenuItems"];
    }
  else
    {
      dTitle = [aDecoder decodeObject];
      dItems = [aDecoder decodeObject];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &dAuto];
    }
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

- (void) setTornOff: (BOOL)flag
{
  NSMenu	*supermenu;

  _is_tornoff = flag; 

  if (flag)
    {
      supermenu = [self supermenu];
      if (supermenu != nil)
        {
          [[supermenu menuRepresentation] setHighlightedItemIndex: -1];
          supermenu->_attachedMenu = nil;
        }
    }
  [_view update];
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

	  if ([menuLocations isKindOfClass: [NSDictionary class]])
	    location = [menuLocations objectForKey: key];
	  else
	    location = nil;
	  if (location && [location isKindOfClass: [NSString class]])
	    {
	      [self setTornOff: YES];
	      [self display];
	    }
	}
    }
}

- (void) _showOnActivateApp: (NSNotification*)notification
{
  if ([NSApp mainMenu] == self)
  {
    [self display];
    // we must make sure that any attached submenu is visible too.
    [[self attachedMenu] display];
  }
}

- (BOOL) isTransient
{
  return _transient;
} 

- (BOOL) isPartlyOffScreen
{
  return IS_OFFSCREEN ([self window]);
}

- (void) _performMenuClose: (id)sender
{
  if (_attachedMenu)
    [_view detachSubmenu];
  
  [_view setHighlightedItemIndex: -1];
  [self close];
  [self setTornOff: NO];
  [self _updateUserDefaults: nil];
} 

- (void) display
{
  if (_transient)
    {
      NSDebugLLog (@"NSMenu", 
                   @"trying to display while alreay displayed transient");
    }

  if (_needsSizing)
    {
      [self sizeToFit];
    }
  
  if (_superMenu && ![self isTornOff])
    {                 
      // query super menu for position
      [_aWindow setFrameOrigin: [_superMenu locationForSubmenu: self]];
      _superMenu->_attachedMenu = self;
    }
  else if ([_aWindow frame].origin.y <= 0 
           && _popUpButtonCell == nil)   // get geometry only if not set
    {
      [self setGeometry];
    }
  
  NSDebugLLog (@"NSMenu", 
               @"Display, origin: %@", 
               NSStringFromPoint ([_aWindow frame].origin));
  
  [_aWindow orderFrontRegardless];
}

- (void) displayTransient
{
  NSPoint location;
  NSView *contentView;

  if (_transient)
    {
      NSDebugLLog (@"NSMenu", @"displaying transient while it is transient");
      return;
    }

  if (_needsSizing)
    {
      [self sizeToFit];
    }
  
  _oldHiglightedIndex = [[self menuRepresentation] highlightedItemIndex];
  _transient = YES;
  
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

  contentView = [_bWindow contentView];
  [contentView addSubview: _view];

  [_view update];
  
  [_bWindow orderFront: self];
}

- (void) setGeometry
{
  NSString       *key;
  NSUserDefaults *defaults;
  NSDictionary   *menuLocations;
  NSString       *location;
  
  NSPoint        origin;
  NSScanner      *scanner;
  int            value;

  origin = NSMakePoint (0, [[NSScreen mainScreen] frame].size.height 
      - [_aWindow frame].size.height);
      
  if (nil != (key = [self _locationKey]))
    {
      defaults = [NSUserDefaults standardUserDefaults];
      menuLocations = [defaults objectForKey: NSMenuLocationsKey];

      if ([menuLocations isKindOfClass: [NSDictionary class]])
	location = [menuLocations objectForKey: key];
      else
	location = nil;
 
      if (location && [location isKindOfClass: [NSString class]])
        {
          scanner = [NSScanner scannerWithString: location];
          [scanner scanInt: &value];
          origin.x = value;
          [scanner scanInt: &value];
          origin.y = value;
        }
    }
  
  [_aWindow setFrameOrigin: origin];
  [_bWindow setFrameOrigin: origin];
}

- (void) close
{
  NSMenu *sub = [self attachedMenu];


  if (_transient)
    {
      NSDebugLLog (@"NSMenu", @"We should not close ordinary menu while transient version is still open");
    }
  
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

  if (_superMenu && ![self isTornOff])
    {
      _superMenu->_attachedMenu = nil;
      [[_superMenu menuRepresentation] setHighlightedItemIndex: -1];
    }
}

- (void) closeTransient
{
  NSView *contentView;

  if (_transient == NO)
    {
      NSDebugLLog (@"NSMenu",
	@"Closing transient: %@ while it is NOT transient now", _title);
      return;
    }
  
  [_bWindow orderOut: self];
  [_view removeFromSuperviewWithoutNeedingDisplay];

  contentView = [_aWindow contentView];
  [contentView addSubview: _view];

  [contentView setNeedsDisplay: YES]; 
  
  // Restore the old submenu (if any).
  if (_superMenu != nil)
    {
      _superMenu->_attachedMenu = _oldAttachedMenu;
      [[_superMenu menuRepresentation] setHighlightedItemIndex:
	[_superMenu indexOfItemWithSubmenu: _superMenu->_attachedMenu]];
    }

  [[self menuRepresentation] setHighlightedItemIndex: _oldHiglightedIndex];
  
  _transient = NO;
  [_view update];
}

- (NSWindow*) window
{
  if (_transient)
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
  NSWindow *theWindow = [self window];

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
  NSWindow *theWindow = _transient ? _bWindow : _aWindow;
  NSRect    frameRect = [theWindow frame];
  NSRect    screenRect = [[NSScreen mainScreen] frame];
  NSPoint   vector    = {0.0, 0.0};
  BOOL      moveIt    = NO;
  
  // 1 - determine the amount we need to shift in the y direction.
  if (NSMinY (frameRect) < 0)
    {
      vector.y = MIN (SHIFT_DELTA, -NSMinY (frameRect));
      moveIt = YES;
    }
  else if (NSMaxY (frameRect) > NSMaxY (screenRect))
    {
      vector.y = -MIN (SHIFT_DELTA, NSMaxY (frameRect) - NSMaxY (screenRect));
      moveIt = YES;
    }

  // 2 - determine the amount we need to shift in the x direction.
  if (NSMinX (frameRect) < 0)
    {
      vector.x = MIN (SHIFT_DELTA, -NSMinX (frameRect));
      moveIt = YES;
    }
  // Note the -3.  This is done so the menu, after shifting completely
  // has some spare room on the right hand side.  This is needed otherwise
  // the user can never access submenus of this menu.
  else if (NSMaxX (frameRect) > NSMaxX (screenRect) - 3)
    {
      vector.x
	= -MIN (SHIFT_DELTA, NSMaxX (frameRect) - NSMaxX (screenRect) + 3);
      moveIt = YES;
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
                 || masterMenu->_transient);
           masterMenu = candidateMenu);
      
      masterLocation = [[masterMenu window] frame].origin;
      destinationPoint.x = masterLocation.x + vector.x;
      destinationPoint.y = masterLocation.y + vector.y;
      
      [masterMenu nestedSetFrameOrigin: destinationPoint];
    }
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
	  [_aWindow setLevel: NSPopUpMenuWindowLevel];
	  [_bWindow setLevel: NSPopUpMenuWindowLevel];
	}
    }
  [self update];
}

- (NSString*) description
{
  return [NSString stringWithFormat: @"NSMenu: %@ (%@)",
            _title, _transient ? @"Transient": @"Normal"];
}

@end

