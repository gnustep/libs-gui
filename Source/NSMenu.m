/* 
   NSMenu.m

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
#include <math.h>

#ifdef MAX
# undef MAX
#endif
#define MAX(a, b) \
    ({typeof(a) _a = (a); typeof(b) _b = (b);     \
	_a > _b ? _a : _b; })


@interface NSMenu (PrivateMethods2)
- (void) _menuChanged;
@end

@interface NSMenuMatrix (PrivateMethods2)
- (void) _resizeMenuForCellSize;
@end

//*****************************************************************************
//
// 		NSMenuMatrix 
//
//*****************************************************************************

@implementation NSMenuMatrix

// Class variables
static NSFont* menuFont = nil;

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

- (id) initWithFrame: (NSRect)rect
{
  [super initWithFrame: rect];
  cells = [NSMutableArray new];

  /* Don't initialize menuFont in +initialize since we don't know if the
     DGS process knows anything about the fonts yet. */
  if (!menuFont)
    menuFont = [[NSFont systemFontOfSize: 0] retain];

  cellSize = NSMakeSize (1, [menuFont pointSize] - [menuFont descender] + 6);
  return self;
}

- (void) dealloc
{
  NSDebugLog (@"NSMenuMatrix of menu '%@' dealloc", [menu title]);

  [cells release];
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSMenuMatrix* copy = [[isa allocWithZone: zone] initWithFrame: [self frame]];
  int i, count;

  NSDebugLog (@"copy menu matrix of menu with title '%@'", [menu title]);
  for (i = 0, count = [cells count]; i < count; i++)
    {
      id aCell = [cells objectAtIndex: i];
      id cellCopy = [[aCell copyWithZone: zone] autorelease];

      [copy->cells addObject: cellCopy];
    }

  copy->cellSize = cellSize;
  copy->menu = menu;
  if (selectedCell)
    {
      int index = [cells indexOfObject: selectedCell];

      copy->selectedCell = [[cells objectAtIndex: index] retain];
    }
  copy->selectedCellRect = selectedCellRect;

  return copy;
}

- (void) _resizeMenuForCellSize
{
  int i, count;
  float titleWidth;

  /* Compute the new width of the menu cells matrix */
  cellSize.width = 0;
  count = [cells count];
  for (i = 0; i < count; i++)
    {
      titleWidth = [menuFont widthOfString: 
				  [[cells objectAtIndex: i] stringValue]];
      cellSize.width = MAX(titleWidth + ADDITIONAL_WIDTH, cellSize.width);
    }
  cellSize.width = MAX([menuFont widthOfString: [menu title]]
			  + ADDITIONAL_WIDTH,
			cellSize.width);

  /* Resize the frame to hold all the menu cells */
  [super setFrameSize: NSMakeSize (cellSize.width,
      count ? (cellSize.height + INTERCELL_SPACE)*count - INTERCELL_SPACE : 0)];
}

- (id <NSMenuItem>)insertItemWithTitle: (NSString*)aString
				action: (SEL)aSelector
			 keyEquivalent: (NSString*)charCode
			       atIndex: (unsigned int)index
{
  id menuCell = [[[NSMenu cellClass] new] autorelease];

  [menuCell setFont: menuFont];
  [menuCell setTitle: aString];
  [menuCell setAction: aSelector];
  [menuCell setKeyEquivalent: charCode];

  [cells insertObject: menuCell atIndex: index];

  return menuCell;
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  int row = [cells indexOfObject: anItem];

  if (row == -1)
    return;

  [cells removeObjectAtIndex: row];
}

- (NSArray*) itemArray
{
  return cells;
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  unsigned i, count = [cells count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [cells objectAtIndex: i];
      if ([[menuCell title] isEqual: aString])
	return menuCell;
    }
  return nil;
}

- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  unsigned i, count = [cells count];
  id menuCell;

  for (i = 0; i < count; i++)
    {
      menuCell = [cells objectAtIndex: i];
      if ([menuCell tag] == aTag)
	return menuCell;
    }
  return nil;
}

- (NSRect) cellFrameAtRow: (int)index
{
  unsigned count = [cells count];
  NSRect rect;

  NSAssert(index >= 0 && index < count+1, @"invalid row coordinate");

  rect.origin.x = 0;
  rect.origin.y = (count - index - 1)
		  * (cellSize.height + INTERCELL_SPACE);
  rect.size = cellSize;

  return rect;
}

- (void)drawRect: (NSRect)rect
{
  unsigned i, count = [cells count];
  int max, howMany;
  NSRect intRect = {{0, 0}, {0, 0}};

  // If there are no cells then just return
  if (count == 0) return;

  max = ceil((float)count - rect.origin.y / (cellSize.height + INTERCELL_SPACE));
  howMany = ceil(rect.size.height / (cellSize.height + INTERCELL_SPACE));

  intRect.origin.y = (count - max) * (cellSize.height + INTERCELL_SPACE);
  intRect.size = cellSize;
  for (i = max - 1; howMany > 0; i--, howMany--)
    {
      id aCell = [cells objectAtIndex: i];

      [aCell drawWithFrame: intRect inView: self];
      intRect.origin.y += cellSize.height + INTERCELL_SPACE;
    }
}

- (NSSize) cellSize
{
  return cellSize;
}

- (void) setMenu: (NSMenu*)anObject
{
  menu = anObject;
}

- (void) setSelectedCell: (id)aCell
{
  selectedCell = aCell;
}

- (id) selectedCell
{
  return selectedCell;
}

- (NSRect) selectedCellRect
{
  return selectedCellRect;
}

@end /* NSMenuMatrix */


//*****************************************************************************
//
// 		NSMenu 
//
//*****************************************************************************

@implementation NSMenu

// Class variables
static NSZone *menuZone = NULL;
static Class menuCellClass = nil;

+ (void) initialize
{
  menuCellClass = [NSMenuItem class];
}

+ (void) setMenuZone: (NSZone*)zone
{
  menuZone = zone;
}

+ (NSZone*) menuZone
{
  return menuZone;
}

+ (void) setCellClass: (Class)aClass
{
  menuCellClass = aClass;
}

+ (Class) cellClass
{
  return menuCellClass;
}

- (id) init
{
  return [self initWithTitle: 
		[[[NSProcessInfo processInfo] processName] lastPathComponent]];
}

- (id) initWithTitle: (NSString*)aTitle
{
  // SUBCLASS to initialize other "instance variables"
  NSRect rect = {{0, 0}, {80, 20}};

  ASSIGN(title, aTitle);
  menuCells = [[NSMenuMatrix alloc] initWithFrame: rect];
  [menuCells setMenu: self];
  menuChangedMessagesEnabled = YES;
  autoenablesItems = YES;
  return self;
}

- (void) dealloc
{
  NSDebugLog (@"NSMenu '%@' dealloc", title);

  [title release];
  [menuCells release];
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSMenu	*copy = NSAllocateObject (isa, 0, zone);
  unsigned	i, count;
  NSArray	*cells;

  NSDebugLog (@"copy menu with title '%@'", [self title]);

  copy->title = [title copyWithZone: zone];

  copy->menuCells = [menuCells copyWithZone: zone];
  [copy->menuCells setMenu: copy];

  /* Change the supermenu object of the new cells to the new menu */
  cells = [copy->menuCells itemArray];
  for (i = 0, count = [cells count]; i < count; i++) {
    id cell = [cells objectAtIndex: i];

    if ([cell hasSubmenu]) {
      NSMenu* submenu = [cell target];

      submenu->supermenu = copy;
    }
  }

  [copy->menuCells setFrame: [menuCells frame]];

  copy->supermenu = supermenu;
  copy->attachedMenu = nil;
  copy->autoenablesItems = autoenablesItems;
  copy->menuChangedMessagesEnabled = menuChangedMessagesEnabled;
  copy->menuHasChanged = menuHasChanged;

  return copy;
}

- (id <NSMenuItem>) addItemWithTitle: (NSString*)aString
			      action: (SEL)aSelector
		       keyEquivalent: (NSString*)charCode
{
  return [self insertItemWithTitle: aString
			    action: aSelector
		     keyEquivalent: charCode
			   atIndex: [[menuCells itemArray] count]];
}

- (id <NSMenuItem>) insertItemWithTitle: (NSString*)aString
				 action: (SEL)aSelector
			  keyEquivalent: (NSString*)charCode
				atIndex: (unsigned int)index
{
  id menuCell = [menuCells insertItemWithTitle: aString
					action: aSelector
				 keyEquivalent: charCode
				atIndex: index];
  menuHasChanged = YES;

  return menuCell;
}

- (void) removeItem: (id <NSMenuItem>)anItem
{
  [menuCells removeItem: anItem];
  menuHasChanged = YES;
}

- (NSArray*) itemArray
{
  return [menuCells itemArray];
}

- (id <NSMenuItem>) itemWithTag: (int)aTag
{
  return [menuCells itemWithTag: aTag];
}

- (id <NSMenuItem>) itemWithTitle: (NSString*)aString
{
  return [menuCells itemWithTitle: aString];
}

- (void) setSubmenu: (NSMenu*)aMenu forItem: (id <NSMenuItem>)anItem
{
  NSString	*itemTitle = [anItem title];

  [anItem setTarget: aMenu];
  [anItem setAction: @selector(submenuAction:)];
  if (aMenu)
    aMenu->supermenu = self;

  ASSIGN(aMenu->title, itemTitle);
  [self _menuChanged];
}

- (void) submenuAction: (id)sender
{
}

- (NSMenu*) attachedMenu
{
  return attachedMenu;
}

- (BOOL) isAttached
{
  return supermenu && [supermenu attachedMenu] == self;
}

- (BOOL) isTornOff
{
  // SUBCLASS
  return NO;
}

- (NSPoint) locationForSubmenu: (NSMenu*)aSubmenu
{
  // SUBCLASS
  return NSZeroPoint;
}

- (NSMenu*) supermenu
{
  return supermenu;
}

- (void) setAutoenablesItems: (BOOL)flag
{
  autoenablesItems = flag;
}

- (BOOL) autoenablesItems
{
  return autoenablesItems;
}

- (void) update
{
  // SUBCLASS to redisplay the menu if necessary

  id cells;
  int i, count;
  id theApp = [NSApplication sharedApplication];

  if (![self autoenablesItems])
    return;

  cells = [menuCells itemArray];
  count = [cells count];

  /* Temporary disable automatic displaying of menu */
  [self setMenuChangedMessagesEnabled: NO];

  for (i = 0; i < count; i++)
    {
      id<NSMenuItem> cell = [cells objectAtIndex: i];
      SEL action = [cell action];
      id target;
      NSWindow* keyWindow;
      NSWindow* mainWindow;
      id responder;
      id delegate;
      id validator = nil;
      BOOL wasEnabled = [cell isEnabled];
      BOOL shouldBeEnabled;

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
	  [menuCells setNeedsDisplayInRect: [menuCells cellFrameAtRow: i]];
	}
    }

  if (menuHasChanged)
    [self sizeToFit];

  /* Reenable displaying of menus */
  [self setMenuChangedMessagesEnabled: YES];
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

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  id cells = [menuCells itemArray];
  int i, count = [cells count];
  NSEventType type = [theEvent type];

  if (type != NSKeyDown || type != NSKeyUp)
    return NO;

  for (i = 0; i < count; i++) {
    id<NSMenuItem> cell = [cells objectAtIndex: i];

    if ([cell hasSubmenu]) {
      if ([[cell target] performKeyEquivalent: theEvent])
	/* The event has been handled by a cell in submenu */
	return YES;
    }
    else {
      if ([[cell keyEquivalent] isEqual: [theEvent charactersIgnoringModifiers]]
	  && [cell keyEquivalentModifierMask] == [theEvent modifierFlags]) {
	[menuCells lockFocus];
	[(id)cell performClick: self];
	[menuCells unlockFocus];
	return YES;
      }
    }
  }

  return NO;
}

- (void) setMenuChangedMessagesEnabled: (BOOL)flag
{
  menuChangedMessagesEnabled = flag;
}

- (BOOL) menuChangedMessagesEnabled
{
  return menuChangedMessagesEnabled;
}

- (void) sizeToFit
{
  // SUBCLASS
  [menuCells _resizeMenuForCellSize];
  [menuCells setNeedsDisplay: YES];
  menuHasChanged = NO;
}

- (void) setTitle: (NSString*)aTitle
{
  ASSIGN(title, aTitle);
  [self sizeToFit];
}

- (NSString*) title
{
  return title;
}

- (NSMenuMatrix*) menuCells
{
  return menuCells;
}

- (id)  initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

- (void)  encodeWithCoder: (NSCoder*)aCoder
{
}

// non OS spec methods
- (void) _rightMouseDisplay
{
}

@end /* NSMenu */


@implementation NSMenu (PrivateMethods2)

- (void) _menuChanged
{
  menuHasChanged = YES;
  if (menuChangedMessagesEnabled)
    [self sizeToFit];
}

@end
