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

#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSProcessInfo.h>

#include <AppKit/NSMatrix.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSMenu.h>

#define ASSIGN(variable, value) \
  [value retain]; \
  [variable release]; \
  variable = value;

#ifdef MAX
# undef MAX
#endif
# define MAX(a, b) \
    ({typedef _ta = (a), _tb = (b);   \
	_ta _a = (a); _tb _b = (b);     \
	_a > _b ? _a : _b; })


@interface NSMenu (PrivateMethods2)
- (void)_menuChanged;
@end


@implementation NSMenuMatrix

// Class variables
static NSFont* menuFont = nil;

- initWithFrame:(NSRect)rect
{
  [super initWithFrame:rect];
  cells = [NSMutableArray new];

  /* Don't initialize menuFont in +initialize since we don't know if the
     DGS process knows anything about the fonts yet. */
  if (!menuFont)
    menuFont = [[NSFont systemFontOfSize:0] retain];

  cellSize = NSMakeSize (1, [menuFont pointSize] - [menuFont descender] + 4);
  return self;
}

- (void)dealloc
{
  NSDebugLog (@"NSMenuMatrix of menu '%@' dealloc", [menu title]);

  [cells release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
  NSMenuMatrix* copy = NSAllocateObject (isa, 0, zone);
  int i, count;

  NSDebugLog (@"copy menu matrix of menu with title '%@'", [menu title]);
  copy->cells = [[NSMutableArray alloc] initWithCapacity:[cells count]];
  for (i = 0, count = [cells count]; i < count; i++) {
    id aCell = [cells objectAtIndex:i];
    id cellCopy = [[aCell copyWithZone:zone] autorelease];

    [copy->cells addObject:cellCopy];
  }

  copy->cellSize = cellSize;
  copy->menu = menu;
  if (selectedCell) {
    int index = [cells indexOfObject:selectedCell];

    copy->selectedCell = [[cells objectAtIndex:index] retain];
  }
  copy->selectedCellRect = selectedCellRect;

  return copy;
}

- (void)_resizeMenuForCellSize
{
  /* Resize the frame to hold all the menu cells */
  [super setFrameSize:NSMakeSize (cellSize.width,
      (cellSize.height + INTERCELL_SPACE) * [cells count] - INTERCELL_SPACE)];
}

- (id <NSMenuItem>)insertItemWithTitle:(NSString*)aString
				action:(SEL)aSelector
			 keyEquivalent:(NSString*)charCode
			       atIndex:(unsigned int)index
{
  id menuCell = [[[NSMenu cellClass] new] autorelease];
  float titleWidth;

  [menuCell setTitle:aString];
  [menuCell setAction:aSelector];
  [menuCell setKeyEquivalent:charCode];
  [menuCell setFont:menuFont];

  titleWidth = [menuFont widthOfString:aString];
  cellSize = NSMakeSize (MAX(titleWidth + ADDITIONAL_WIDTH, cellSize.width),
			 cellSize.height);
  [cells insertObject:menuCell atIndex:index];

  [self _resizeMenuForCellSize];

  return menuCell;
}

- (void)removeItem:(id <NSMenuItem>)anItem
{
  int row = [cells indexOfObject:anItem];
  float titleWidth;
  int i, count;

  if (row == -1)
    return;

  [cells removeObjectAtIndex:row];

  /* Compute the new width of the menu cells matrix */
  cellSize.width = 0;
  count = [cells count];
  for (i = 0; i < count; i++) {
    titleWidth = [menuFont widthOfString:[cells objectAtIndex:i]];
    cellSize.width = MAX(titleWidth + ADDITIONAL_WIDTH, cellSize.width);
  }

  [self _resizeMenuForCellSize];
}

- (NSArray*)itemArray			{ return cells; }

- (id <NSMenuItem>)itemWithTitle:(NSString*)aString
{
  int i, count = [cells count];
  id menuCell;

  for (i = 0; i < count; i++) {
    menuCell = [cells objectAtIndex:i];
    if ([[menuCell title] isEqual:aString])
      return menuCell;
  }
  return nil;
}

- (id <NSMenuItem>)itemWithTag:(int)aTag
{
  int i, count = [cells count];
  id menuCell;

  for (i = 0; i < count; i++) {
    menuCell = [cells objectAtIndex:i];
    if ([menuCell tag] == aTag)
      return menuCell;
  }
  return nil;
}

- (NSRect)cellFrameAtRow:(int)index
{
  NSRect rect;

  rect.origin.x = 0;
  rect.origin.y = ([cells count] - index - 1)
		  * (cellSize.height + INTERCELL_SPACE);
  rect.size = cellSize;

  return rect;
}

- (void)drawRect:(NSRect)rect
{
  int i, count = [cells count];
  NSRect intRect = {{0, 0}, {0, 0}};

  intRect.size = cellSize;
  for (i = count - 1; i >= 0; i--) {
    id aCell = [cells objectAtIndex:i];

    [aCell drawWithFrame:intRect inView:self];
    intRect.origin.y += cellSize.height + INTERCELL_SPACE;
  }
  [[self window] flushWindow];
}

- (NSSize)cellSize			{ return cellSize; }
- (void)setMenu:(NSMenu*)anObject	{ menu = anObject; }
- (void)setSelectedCell:(id)aCell	{ ASSIGN(selectedCell, aCell); }
- (id)selectedCell			{ return selectedCell; }
- (NSRect)selectedCellRect		{ return selectedCellRect; }

@end /* NSMenuMatrix */


@implementation NSMenu

// Class variables
static NSZone *menuZone = NULL;
static Class menuCellClass = nil;

+ (void)initialize
{
  menuCellClass = [NSMenuItem class];
}

+ (void)setMenuZone:(NSZone*)zone
{
  menuZone = zone;
}

+ (NSZone*)menuZone
{
  return menuZone;
}

+ (void)setCellClass:(Class)aClass
{
  menuCellClass = aClass;
}

+ (Class)cellClass
{
  return menuCellClass;
}

- init
{
  return [self initWithTitle:
		[[[NSProcessInfo processInfo] processName] lastPathComponent]];
}

- (id)initWithTitle:(NSString*)aTitle
{
  // SUBCLASS to initialize other "instance variables"
  NSRect rect = {{0, 0}, {80, 20}};

  ASSIGN(title, aTitle);
  menuCells = [[NSMenuMatrix alloc] initWithFrame:rect];
  [menuCells setMenu:self];
  menuChangedMessagesEnabled = YES;
  autoenablesItems = YES;
  return self;
}

- (void)dealloc
{
  NSDebugLog (@"NSMenu '%@' dealloc", title);

  [title release];
  [menuCells release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
  NSMenu* copy = NSAllocateObject (isa, 0, zone);
  int i, count;
  NSArray* cells;

  NSDebugLog (@"copy menu with title '%@'", [self title]);

  copy->title = [title copyWithZone:zone];

  copy->menuCells = [menuCells copyWithZone:zone];
  [copy->menuCells setMenu:copy];

  /* Change the supermenu object of the new cells to the new menu */
  cells = [copy->menuCells itemArray];
  for (i = 0, count = [cells count]; i < count; i++) {
    id cell = [cells objectAtIndex:i];

    if ([cell hasSubmenu]) {
      NSMenu* submenu = [cell target];

      submenu->supermenu = copy;
    }
  }

  [copy->menuCells setFrame:[menuCells frame]];

  copy->supermenu = supermenu;
  copy->attachedMenu = nil;
  copy->autoenablesItems = autoenablesItems;
  copy->menuChangedMessagesEnabled = menuChangedMessagesEnabled;
  copy->menuHasChanged = menuHasChanged;

  return copy;
}

- (id <NSMenuItem>)addItemWithTitle:(NSString*)aString
			     action:(SEL)aSelector
		      keyEquivalent:(NSString*)charCode
{
  return [self insertItemWithTitle:aString
			    action:aSelector
		     keyEquivalent:charCode
			   atIndex:[[menuCells itemArray] count]];
}

- (id <NSMenuItem>)insertItemWithTitle:(NSString*)aString
				action:(SEL)aSelector
			 keyEquivalent:(NSString*)charCode
			       atIndex:(unsigned int)index
{
  id menuCell = [menuCells insertItemWithTitle:aString
					action:aSelector
				 keyEquivalent:charCode
				       atIndex:index];
  [self _menuChanged];

  return menuCell;
}

- (void)removeItem:(id <NSMenuItem>)anItem
{
  [menuCells removeItem:anItem];
  [self _menuChanged];
}

- (NSArray*)itemArray
{
  return [menuCells itemArray];
}

- (id <NSMenuItem>)itemWithTag:(int)aTag
{
  return [menuCells itemWithTag:aTag];
}

- (id <NSMenuItem>)itemWithTitle:(NSString*)aString
{
  return [menuCells itemWithTitle:aString];
}

- (void)setSubmenu:(NSMenu*)aMenu forItem:(id <NSMenuItem>)anItem
{
  NSString* itemTitle = [anItem title];

  [anItem setTarget:aMenu];
  [anItem setAction:@selector(submenuAction:)];
  if (aMenu)
    aMenu->supermenu = self;

  [itemTitle retain];
//  [aMenu->title release];
  aMenu->title = itemTitle;

  [self _menuChanged];
}

- (void)submenuAction:(id)sender
{
  // SUBCLASS
}

- (NSMenu*)attachedMenu
{
  return attachedMenu;
}

- (BOOL)isAttached
{
  return supermenu && [supermenu attachedMenu] == self;
}

- (BOOL)isTornOff
{
  // SUBCLASS
  return NO;
}

- (NSPoint)locationForSubmenu:(NSMenu*)aSubmenu
{
  // SUBCLASS
  return NSZeroPoint;
}

- (NSMenu*)supermenu
{
  return supermenu;
}

- (void)setAutoenablesItems:(BOOL)flag
{
  autoenablesItems = flag;
}

- (BOOL)autoenablesItems
{
  return autoenablesItems;
}

- (void)update
{
  // SUBCLASS to redisplay the menu

  id cells;
  int i, count;

  if (![[NSApp mainMenu] autoenablesItems])
    return;

  cells = [menuCells itemArray];
  count = [cells count];

  /* Temporary disable automatic displaying of menu */
  [self setMenuChangedMessagesEnabled:NO];

  for (i = 0; i < count; i++) {
    id<NSMenuItem> cell = [cells objectAtIndex:i];
    SEL action = [cell action];
    id target;
    NSWindow* keyWindow;
    NSWindow* mainWindow;
    id responder;
    id delegate;
    BOOL found = NO;

    /* Update the submenu items if any */
    if ([cell hasSubmenu]) {
      [[cell target] update];
      continue;
    }

    if (!action) {
      [cell setEnabled:NO];
      continue;
    }

    /* Search the target */
    if ((target = [cell target])) {
      if ([target respondsToSelector:action]) {
	if ([target respondsToSelector:@selector(validateMenuItem:)])
	  [cell setEnabled:[target validateMenuItem:cell]];
	else
	  [cell setEnabled:YES];
	continue;
      }
    }

    /* Search the key window's responder chain */
    keyWindow = [NSApp keyWindow];
    responder = [keyWindow firstResponder];
    while (responder && !found) {
      if ([responder respondsToSelector:action]) {
	if ([responder respondsToSelector:@selector(validateMenuItem:)])
	  [cell setEnabled:[responder validateMenuItem:cell]];
	else
	  [cell setEnabled:YES];
	found = YES;
      }
      responder = [responder nextResponder];
    }
    if (found)
      continue;

    /* Search the key window */
    if ([keyWindow respondsToSelector:action]) {
      if ([keyWindow respondsToSelector:@selector(validateMenuItem:)])
	[cell setEnabled:[keyWindow validateMenuItem:cell]];
      else
	[cell setEnabled:YES];
      continue;
    }

    /* Search the key window's delegate */
    delegate = [keyWindow delegate];
    if ([delegate respondsToSelector:action]) {
      if ([delegate respondsToSelector:@selector(validateMenuItem:)])
	[cell setEnabled:[delegate validateMenuItem:cell]];
      else
	[cell setEnabled:YES];
      continue;
    }

    mainWindow = [NSApp mainWindow];
    if (mainWindow != keyWindow) {
      /* Search the main window's responder chain */
      responder = [mainWindow firstResponder];
      while (responder && !found) {
	if ([responder respondsToSelector:action]) {
	  if ([responder respondsToSelector:@selector(validateMenuItem:)])
	    [cell setEnabled:[responder validateMenuItem:cell]];
	  else
	    [cell setEnabled:YES];
	  found = YES;
	}

	responder = [responder nextResponder];
      }
      if (found)
	continue;

      /* Search the main window */
      if ([mainWindow respondsToSelector:action]) {
	if ([mainWindow respondsToSelector:@selector(validateMenuItem:)])
	  [cell setEnabled:[mainWindow validateMenuItem:cell]];
	else
	  [cell setEnabled:YES];
	continue;
      }

      /* Search the main window's delegate */
      delegate = [mainWindow delegate];
      if ([delegate respondsToSelector:action]) {
	if ([delegate respondsToSelector:@selector(validateMenuItem:)])
	  [cell setEnabled:[delegate validateMenuItem:cell]];
	else
	  [cell setEnabled:YES];
	continue;
      }
    }

    /* Search the NSApplication object */
    if ([NSApp respondsToSelector:action]) {
      if ([NSApp respondsToSelector:@selector(validateMenuItem:)])
	[cell setEnabled:[NSApp validateMenuItem:cell]];
      else
	[cell setEnabled:YES];
      continue;
    }

    /* Search the NSApplication object's delegate */
    delegate = [NSApp delegate];
    if ([delegate respondsToSelector:action]) {
      if ([delegate respondsToSelector:@selector(validateMenuItem:)])
	[cell setEnabled:[delegate validateMenuItem:cell]];
      else
	[cell setEnabled:YES];
      continue;
    }

    [cell setEnabled:NO];
  }

  /* Reenable displaying of menus */
  [self setMenuChangedMessagesEnabled:YES];

  [self sizeToFit];
}

- (void)performActionForItem:(id <NSMenuItem>)cell
{
  SEL action;
  id target;
  NSWindow* keyWindow;
  NSWindow* mainWindow;
  id responder;
  id delegate;

  if (![cell isEnabled])
    return;

  action = [cell action];

  /* Search the target */
  if ((target = [cell target]) && [target respondsToSelector:action]) {
    [target perform:action withObject:cell];
    return;
  }

  /* Search the key window's responder chain */
  keyWindow = [NSApp keyWindow];
  responder = [keyWindow firstResponder];
  while (responder) {
    if ([responder respondsToSelector:action]) {
      [responder perform:action withObject:cell];
      return;
    }
    responder = [responder nextResponder];
  }

  /* Search the key window */
  if ([keyWindow respondsToSelector:action]) {
    [keyWindow perform:action withObject:cell];
    return;
  }

  /* Search the key window's delegate */
  delegate = [keyWindow delegate];
  if ([delegate respondsToSelector:action]) {
    [delegate perform:action withObject:cell];
    return;
  }

  mainWindow = [NSApp mainWindow];
  if (mainWindow != keyWindow) {
    /* Search the main window's responder chain */
    responder = [mainWindow firstResponder];
    while (responder) {
      if ([responder respondsToSelector:action]) {
	[responder perform:action withObject:cell];
	return;
      }
      responder = [responder nextResponder];
    }

    /* Search the main window */
    if ([mainWindow respondsToSelector:action]) {
      [mainWindow perform:action withObject:cell];
      return;
    }

    /* Search the main window's delegate */
    delegate = [mainWindow delegate];
    if ([delegate respondsToSelector:action]) {
      [delegate perform:action withObject:cell];
      return;
    }
  }

  /* Search the NSApplication object */
  if ([NSApp respondsToSelector:action]) {
    [NSApp perform:action withObject:cell];
    return;
  }

  /* Search the NSApplication object's delegate */
  delegate = [NSApp delegate];
  if ([delegate respondsToSelector:action]) {
    [delegate perform:action withObject:cell];
    return;
  }
}

- (BOOL)performKeyEquivalent:(NSEvent*)theEvent
{
  id cells = [menuCells itemArray];
  int i, count = [cells count];
  NSEventType type = [theEvent type];

  if (type != NSKeyDown || type != NSKeyUp)
    return NO;

  for (i = 0; i < count; i++) {
    id<NSMenuItem> cell = [cells objectAtIndex:i];

    if ([cell hasSubmenu]) {
      if ([[cell target] performKeyEquivalent:theEvent])
	/* The event has been handled by a cell in submenu */
	return YES;
    }
    else {
      if ([[cell keyEquivalent] isEqual:[theEvent charactersIgnoringModifiers]]
	  && [cell keyEquivalentModifierMask] == [theEvent modifierFlags]) {
	[menuCells lockFocus];
	[(id)cell performClick:self];
	[menuCells unlockFocus];
	return YES;
      }
    }
  }

  return NO;
}

- (void)setMenuChangedMessagesEnabled:(BOOL)flag
{
  menuChangedMessagesEnabled = flag;
}

- (BOOL)menuChangedMessagesEnabled
{
  return menuChangedMessagesEnabled;
}

- (void)sizeToFit
{
  // SUBCLASS
  menuHasChanged = NO;
}

- (NSString*)title
{
  return title;
}

- (NSMenuMatrix*)menuCells
{
  return menuCells;
}

- initWithCoder:(NSCoder*)aDecoder
{
  return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
}

@end /* NSMenu */


@implementation NSMenu (PrivateMethods2)
- (void)_menuChanged
{
  menuHasChanged = YES;
  if (menuChangedMessagesEnabled)
    [self sizeToFit];
}
@end
