/* 
   NSMenu.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   A completely rewritten version of the original source by Scott Christley.
   
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

#ifndef _GNUstep_H_NSMenu
#define _GNUstep_H_NSMenu

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSMenuItem.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSEvent;
@class NSMatrix;
@class NSPopUpButton;
@class NSPopUpButtonCell;
@class NSView;
@class NSWindow;
@class NSMutableArray;


@protocol NSMenuView 
/**
   Set the menu that this view object will be drawing.
   This method will NOT retain the menu.
   In normal usage an instance of NSMenu will
   use this method to supply the NSMenuView with reference
   to itself.  The NSMenu will retain the NSMenuView.
 */
- (void)setMenu:(NSMenu *)menu;
/**
   Set the currently highlighted item.

   This is used by the NSMenu class to restore
   the selected item when it is temporary set to
   another item.  This happens when both the regular
   version and the transient version are on the screen.

   A value of -1 means that no item will be highlighted.
*/
- (void)setHighlightedItemIndex:(int)index;
/**
   Returns the currently highlighted item.  Returns -1
   if no item is highlighted.
*/
- (int)highlightedItemIndex;

/**
   This should ensure that if there is an attached
   submenu this submenu will be detached.

   Detaching means that this particular menu representation
   should be removed from the screen.

   It should implement a deep detach, that is, all
   attached submenus of this menu should also be detached.
*/
- (void) detachSubmenu;

/**
  This will relayout the NSMenuView. 

  It should be called when the menu changes.  Changes include
  becoming detached, adding or removing submenu items etcetera.

  However, normally it does not need to be called directly because
  Because the NSMenuView is supposed to listen to the NSMenu notifications
  for the item added, removed and change notifications.

  It should be called explicitly when other changes occur, such as
  becoming detached or changing the title.
*/
- (void)update;

/**
   Hm, why is this method needed?  Shouldn't this be done by
   the update method?
*/
- (void)sizeToFit;  //!!!

/**
   Method used by NSMenuItemCell to draw itself correctly and nicely
   lined up with the other menu items.
*/
- (float)stateImageWidth; 
/**
   Method used by NSMenuItemCell to draw itself correctly and nicely
   lined up with the other menu items
*/
- (float)imageAndTitleOffset;
/**
   Methos used by NSMenuItemCell to draw itself correctly and nicely
   lined up with the other menu items.
*/
- (float)imageAndTitleWidth;
/**
   Methos used by NSMenuItemCell to draw itself correctly and nicely
   lined up with the other menu items.
*/
- (float)keyEquivalentOffset;
/**
  Used by NSItemCell to ...
*/
- (float)keyEquivalentWidth;

/**
   Used by the NSMenu to determine where to position a
   submenu.
*/
- (NSPoint)locationForSubmenu:(NSMenu *)aSubmenu;

- (void)performActionWithHighlightingForItemAtIndex:(int)index; //????

/**
   <p>
   This is method is responsible for handling all events while
   the user is interacting with this menu.  It should pass on this
   call to another menurepresentation when the user moves the
   mouse cursor over either a submenu or over the supermenu.
   </p><p>
   The method returns when the interaction from the user with the
   menu system is over.
   </p><p>
   The method returns NO when the user releases the mouse button
   above a submenu item and  YES in all other cases.
   </p>
   <p>
   This return value can be used to determine if submenus should
   be removed from the screen or that they are supposed to stay.
   </p>
   <p>
   The implementation should roughly follow the following logic:
   </p>
   <example>
{
  while (have not released mouse button)
   {
     if (mouse hovers over submenu, or supermenu)
       {
          if ([(menurepresentation under mouse)
                       trackWithEvent: the event])
             {
                [self detachSubmenu];
                return YES;
             }
          return NO;
       }
       //highlight item under  mouse

       if (highlighting submenu item)
         {
           [self attachSubmenuAtIndex:..];
         }
       else
         {
           [self detachSubmenu];
         }
       get next event.
   }

 execute the menu action if applicable;

 return YES | NO depending on the situation;
}
</example>

   Note that actual implementations tend to be more complicated because
   because of all kind of useability issues.   Useabilities issues to
   look out for are:
   <list>
   <item> Menus that are only partly on the screen.  Those need to be moved while
          navigation the menu.</item>
   <item> Submenus that are hard to reach.  If the natural route to the content of a submenu
          travels through other menu items you do not want to remove the submenu immediately.
          </item>
   <item> Transient menus require slightly different behaviour from the normal menus.
   For example, when selecting a action from a transient menu that brings up a modal
   panel you would expect the transient menu to dissappear.  However in the normal
   menu system you want it to stay, so you still have feedback on which menu action
   triggered the modal panel.
   </item>
   </list>

*/
- (BOOL)trackWithEvent:(NSEvent *)event;

@end



/**
<p>
Menus provide the user with a list of actions and/or submenus.
Submenus themselves are full fledged menus and so a heirarchical
structure of appears.
</p>
<p>
Every application has one special menu, the so called Application menu.
This menu is always visible on the screen when the application is active.
This menu normally contains items like, <em>info</em>, 
<em>services</em>, <em>print</em>, <em>hide</em> and <em>quit</em>.
</p>
<p>
After the <em>info</em> item normally some submenus follow containing
the application specific actions.
</p>
<p>
On GNUstep the content of the menu is stacked vertically as oppossed to
the Windows and Mac world, where they are stacked horizontally.
Also because the menus are not part of any normal window they can be dragged
around opened and closed independend of the application windows.
</p>
<p>
This can lead to a few menus being open simultanuously.
The collection of open menus is remembered,
when the program is started again, all the torn off menus aka
detached menus, are displayed at their last known position.
</p>
<p>
The menu behaviour is richer than in most other environments and
bear some explanation.  This explanation is aimed at users of Menus but more so
at the developer of custom menus.
</p>
<deflist>
<term>Application menu</term>
<desc>There alwasy at least one menu
present and visible while the application is active.  This is the application menu.
This window can never be closed.
</desc>
<term>Attached menu</term>
<desc>
Normally when you click in a menu
on a submenu item, the submenu is shown directly next to the menu you click in.
The submenu is now called an <em>attached</em> menu.   It is attached to the
menu that was clicked in.
</desc>
<term>Detached menu</term>
<desc>
A menu is detached when it is not attached
to its parent menu.  A menu can become
detached when the user drags a submenu away from its parents.  
A detached window contains in its title a close button.
</desc>
<term>Transient menu</term>
<desc>
A transient menu is a menu that dissappears as
soon as the user stops interacting with the menus.
Typically a transient menu is created when a right mouse click appears in an
application window.  The right mouse click will bring up the Application menu
at the place the user clicks.  While keeping the mouse button down the
user can select items by moving around.  When releasing the button, all
transient menus will be removed from the screen and the action will be executed.
<p>
It is important to note that it is impossible to click in transient menus.
</p>
</desc>
<term>Attached transient menu</term>
<desc>
This is a menu that is attached and transient at the same time.
</desc>
</deflist>

A single NSMenu instance can be displayed zero or one times when the user is
not interaction with the menus.
When the user is interaction with the menus it can occur that the same NSMenu
is displayed in two locations at the same time.  This is only possible
when one of the displayed instances is a transient menu.

To understand how the diffent kind of menus are created lets look at some user actions:

<list>
<item>The user clicks on an item which is not a submenu.<br/>
      The item is highlighted until the action corresponding with the item is completed.
      More precisely,  the application highlights the menu item, performs the action, and unhighlights the item.
</item>
<item>The user clicks on a submenu item which is not highlighted already<br/>
      If the submenu is not a detached menu, the submenu will become an attached
      menu to the menu that is clicked in.  The item that is clicked in will
      become highlighted and stays highlighted.
      <p>
      If the submenu is a detached menu, the transient version of the submenu
      will be shown
      </p>
      
</item>
<item>The user clicks on a submenu item which is highlighted<br/>
      This means that the submenu is an attached submenu for this menu.
      After clicking the submenu item will no be no longer highlighted and
      the submenu will be removed from the screen.
</item>
<item>The user drags over a menu item<br/>
      The item will be highlighted, if the item is a submenu item, the submenu
      will be shown as an attached submenu.  This can be transient, or non transient.
</item>
</list>



<br/>
<strong>Customizing the look of Menus</strong>
<br/>

There are basically three ways of customizing the look of NSMenu
<enum>
<item>Using custom NSMenuItemCell's.  This you should do when you want to influence
the look of the items displayed in the menu.</item>
<item>Using custom NSMenuView.  This is the class to modify if you want to change
the way the menu is layout on the screen.  So if you want to stack the menu
items horizontally, you should change this class.  This should be rarely needed.
</item>
<item>Reimplement NSMenu.  This you should not do. But, if you implement
everything yourself you can achieve anything.
</item>
</enum>

<br/>
<strong>Information for implementing custom NSMenuView class</strong>
<br/>
When implementing a custom NSMenuView class it is important
to keep the following information in mind.

<list>
<item> The menus (or the menu items) form a tree.  Navigating through this tree
is done with the methods [NSMenu-supermenu], which returns the parent menu
of the receiver, and with [NSMenu-itemAtIndex:] which returns a
NSMenuItem on which we can call [(NSMenuItem)-submenu] for a child menu.
</item>
<item> The menus as displayed on the screen do NOT form a tree.
This because detached and transient menus lead to duplicate menus on the screen.
</item>
</list>

The displayed menus on the screen have the following structure:

<enum>
<item>The ordered graph of displayed menus (note, NOT the set of NSMenus) form a collection of line graphs.</item>
<item>The attached menus are precisely the non root vertices in this graph.</item>
<item>An attached menu of a transient menu is itself a transient menu.</item>
<item>The collection of transient menus form connect subgraph of the menu graph.</item>
</enum>

*/
@interface NSMenu : NSObject <NSCoding, NSCopying>
{
  NSString *_title;
  NSMutableArray *_items;
  NSView<NSMenuView>* _view;
  NSMenu *_superMenu;
  NSMenu *_attachedMenu;
  NSMutableArray *_notifications;
  BOOL _changedMessagesEnabled;
  BOOL _autoenable;
  BOOL _needsSizing;
  BOOL _is_tornoff;

  // GNUstepExtra category
  NSPopUpButtonCell *_popUpButtonCell;
  BOOL _transient;

@private
  NSWindow *_aWindow;
  NSWindow *_bWindow;
  NSMenu *_oldAttachedMenu;
  int     _oldHiglightedIndex;
}

/* Controlling Allocation Zones */
+ (void) setMenuZone: (NSZone*)zone;
+ (NSZone*) menuZone;


/**
 *
 *<init/>
 */

- (id) initWithTitle: (NSString*)aTitle;

/* Setting Up the Menu Commands */
- (void) addItem: (id <NSMenuItem>)newItem;
- (id <NSMenuItem>) addItemWithTitle: (NSString *)aString
                              action: (SEL)aSelector
                       keyEquivalent: (NSString *)keyEquiv;
- (void) insertItem: (id <NSMenuItem>)newItem
            atIndex: (int)index;
- (id <NSMenuItem>) insertItemWithTitle: (NSString *)aString
                                 action: (SEL)aSelector
                          keyEquivalent: (NSString *)charCode
                                atIndex: (unsigned int)index;
- (void) itemChanged: (id <NSMenuItem>)anObject;
- (void) removeItem: (id <NSMenuItem>)anItem;
- (void) removeItemAtIndex: (int)index;

/* Finding menu items */
/**
 * Returns an array containing all menu items in this menu.
 */
- (NSArray*) itemArray;
- (id <NSMenuItem>) itemAtIndex: (int)index;
- (id <NSMenuItem>) itemWithTag: (int)aTag;
- (id <NSMenuItem>) itemWithTitle: (NSString*)aString;
- (int) numberOfItems;

/* Finding Indices of Menu Items */
- (int) indexOfItem: (id <NSMenuItem>)anObject;
- (int) indexOfItemWithTitle: (NSString *)aTitle;
- (int) indexOfItemWithTag: (int)aTag;
- (int) indexOfItemWithTarget: (id)anObject
                   andAction: (SEL)actionSelector;
- (int) indexOfItemWithRepresentedObject: (id)anObject;
- (int) indexOfItemWithSubmenu: (NSMenu *)anObject;

/* Managing submenus */
- (void) setSubmenu: (NSMenu*)aMenu forItem: (id <NSMenuItem>)anItem;
- (void) submenuAction: (id)sender;

/**
   Returns the menu that is attached to this menu.  
   <p>
   If two instances of this menu are visible,
   return the attached window of the transient version
   of this menu.  
   </p>
   <p>
   If no menu is attached return nil. 
   </p>
*/
- (NSMenu*) attachedMenu;
/**
   Returns if this menu is attached to its supermenu,
   return nil if it does not have a parent menu.
   <p>
   If two instances of this menu are visible, return
   the outcome of the check for the transient version
   of the menu.
   </p>
*/
- (BOOL) isAttached;
/**
   If there are two instances of this menu visible, return NO.
   Otherwise, return YES if we are a detached menu and visible.
*/
- (BOOL) isTornOff;

/**
   Returns the position where submenu will be displayed
   when it will be displayed as an attached menu of this menu.
   The result is undefined when aSubmenu is not actually a submenu
   of this menu.
*/
- (NSPoint) locationForSubmenu:(NSMenu*)aSubmenu;
/**
   Returns the supermenu of this menu.  Return nil
   if this is the application menu.  
*/
- (NSMenu*) supermenu;
/**
   Set the supermenu of this menu.
   TODO:  add explanation if this will change remove this menu
   from the old supermenu or if it does not.
*/
- (void) setSupermenu: (NSMenu *)supermenu;

/* Enabling and disabling menu items */
- (BOOL) autoenablesItems;
- (void) setAutoenablesItems: (BOOL)flag;
- (void) update;

/* Handling keyboard equivalents */
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent;

/* Simulating Mouse Clicks */
- (void) performActionForItemAtIndex: (int)index;

/**
   Change the title of the menu.
*/
- (void) setTitle: (NSString*)aTitle;
/**
   Returns the current title.
*/
- (NSString*) title;

/**
   Set the View that should be used to display the menu.
   <p>
   The default is NSMenuView, but a user can supply its
   own NSView object as long as it
   </p>
   <list>
   <item>Inherits from NSView</item>
   <item>Implements NSMenuView protocol</item>
   </list>
*/
- (void) setMenuRepresentation: (id) menuRep;
/**
   Return the NSView that is used for drawing
   the menu.
   It is the view set with [NSMenu-setMenuRepresentation:] and
   therefore it should be safe to assume it is an NSView
   implementing the NSMenuView protocol.
*/
- (id) menuRepresentation;

/* Updating Menu Layout */
- (void) setMenuChangedMessagesEnabled: (BOOL)flag;
- (BOOL) menuChangedMessagesEnabled;
- (void) sizeToFit;

/* Displaying Context-Sensitive Help */
- (void) helpRequested: (NSEvent*)event;

+ (void) popUpContextMenu: (NSMenu*)menu
		withEvent: (NSEvent*)event
		  forView: (NSView*)view;

@end


/**
 * Specifies the protocol to which an object must confirm if it is to be
 * used to validate menu items (in order to implement automatic enabling
 * and disabling of menu items).
 */

@protocol	NSMenuValidation
/**
 * <p>The receiver should return YES if the menuItem is valid ... and should
 * be enabled in the menu, NO if it is invalid and the user should not be
 * able to select it.
 * </p>
 * <p>This method is invoked automatically to determine whether menu items
 * should be enabled or disabled automatically whenever [NSMenu-update] is
 * invoked (usually by the applications event loop).
 * </p>
 */
- (BOOL) validateMenuItem: (id<NSMenuItem>)menuItem;
@end

#ifndef	NO_GNUSTEP
@interface NSObject (NSMenuActionResponder)
- (BOOL) validateMenuItem: (NSMenuItem*)aMenuItem;
@end

/**
   This interface exist contains methods that are meant
   for the NSMenuView.  If you write your own implementation
   of the NSMenuView interface you can use these methods
   to popup other menus or close them.  
*/
@interface NSMenu (GNUstepExtra)

/**
   Returns YES if there is a transient version
   of this menu displayed on the screen.
*/
- (BOOL) isTransient;
/**
   Returns the window in which this menu is displayed.
   If there is a transient version it will return the
   window in which the transient version is displayed.
   If the Menu is not displayed at all the result
   is meaningless.
*/
- (NSWindow*) window;

/* Shows the menu window on screen */
/**
   Show menu on the screen.  This method can/should be used by
   the menurepresentation to display a submenu on the screen.
  */
- (void) display;
/**
   Display the transient version of the menu.  
*/
- (void) displayTransient;

/**
   Positions the menu according to the standard user defaults.
   If the position is not found in the defaults revert to positioning
   the window in the upper left corner.
*/
- (void) setGeometry;      

/**
   When the flag is YES 
   this method will detach the receiver from its parent and
   update the menurepresentation so it will display a close
   button if appropriate.

   If the flag is NO this method will update the menurepresentation
   so it will be able to remove the close button if needed.
   Note that it will not reattach to its parent menu.
*/
- (void) setTornOff: (BOOL) flag;


/**
   Remove the window from the screen.  This method can/should be
   used by the menurepresentation to remove a submenu from the screen.
  */
- (void) close;
/**
   Remove the transient version of the window from the screen.
   This method is used by NSMenuView implementations that need
   to open/close transient menus.
*/
- (void) closeTransient;   

/* Moving menus */
- (void) nestedSetFrameOrigin: (NSPoint)aPoint;

/* Shift partly off-screen menus */
- (BOOL) isPartlyOffScreen; 
- (void) shiftOnScreen;

/* Popup behaviour */
- (BOOL) _ownedByPopUp;
- (void) _setOwnedByPopUp: (NSPopUpButtonCell*)popUp;
@end
#endif

APPKIT_EXPORT NSString* const NSMenuDidSendActionNotification;
APPKIT_EXPORT NSString* const NSMenuWillSendActionNotification;
APPKIT_EXPORT NSString* const NSMenuDidAddItemNotification;
APPKIT_EXPORT NSString* const NSMenuDidRemoveItemNotification;
APPKIT_EXPORT NSString* const NSMenuDidChangeItemNotification;

#endif // _GNUstep_H_NSMenu
