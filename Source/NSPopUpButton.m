/* 
   NSPopUpButton.m

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSPopUpButton.h>
#include <gnustep/gui/NSApplication.h>

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
  [super initWithFrame:frameRect];
  list_items = [NSMutableArray array];
  is_up = NO;
  pulls_down = flag;
  selected_item = 0;

  return self;
}

- (void)dealloc
{
  int i, j;

  j = [list_items count];
  for (i = 0;i < j; ++i)
    [[list_items objectAtIndex:i] release];
  [super dealloc];
}

//
// Target and Action 
//
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

//
// Adding Items 
//
- (void)addItemWithTitle:(NSString *)title
{
  char out[80];

  [list_items addObject:title];
  [self synchronizeTitleAndSelectedItem];
}

- (void)addItemsWithTitles:(NSArray *)itemTitles
{}

- (void)insertItemWithTitle:(NSString *)title
		    atIndex:(unsigned int)index
{}

//
// Removing Items 
//
- (void)removeAllItems
{}

- (void)removeItemWithTitle:(NSString *)title
{}

- (void)removeItemAtIndex:(int)index
{}

//
// Querying the NSPopUpButton about Its Items 
//
- (int)indexOfItemWithTitle:(NSString *)title
{
  return 0;
}

- (int)indexOfSelectedItem
{
  return selected_item;
}

- (int)numberOfItems
{
  return [list_items count];
}

- (NSMenuCell *)itemAtIndex:(int)index
{
  return nil;
}

- (NSMatrix *)itemMatrix
{
  return nil;
}

- (NSString *)itemTitleAtIndex:(int)index
{
  return nil;
}

- (NSArray *)itemTitles
{
  return list_items;
}

- (NSMenuCell *)itemWithTitle:(NSString *)title
{
  return nil;
}

- (NSMenuCell *)lastItem
{
  if ([list_items count] != 0)
    return [list_items lastObject];
  else
    return nil;
}

- (NSMenuCell *)selectedItem
{
  return nil;
}

- (NSString *)titleOfSelectedItem
{
  if ([list_items count] != 0)
    return [list_items objectAtIndex:selected_item];
  else
    return nil;
}

//
// Manipulating the NSPopUpButton
//
- (NSFont *)font
{
  return nil;
}

- (BOOL)pullsDown
{
  return pulls_down;
}

- (void)selectItemAtIndex:(int)index
{
  char out[80];

  if ((index >= 0) && (index <= [list_items count]))
    {
      selected_item = index;
      [self synchronizeTitleAndSelectedItem];
    }
}

- (void)selectItemWithTitle:(NSString *)title
{}

- (void)setFont:(NSFont *)fontObject
{}

- (void)setPullsDown:(BOOL)flag
{
  pulls_down = flag;
}

- (void)setTitle:(NSString *)aString
{}

- (NSString *)stringValue
{
  return nil;
}

- (void)synchronizeTitleAndSelectedItem
{
}

//
// Displaying the NSPopUpButton's Items 
//
- (BOOL)autoenablesItems
{
  return NO;
}

- (void)setAutoenablesItems:(BOOL)flag
{}

//
// Handle events
//
- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

- (void)mouseMoved:(NSEvent *)theEvent
{
}

- (NSView *)hitTest:(NSPoint)aPoint
{
  NSPoint p;
  char out[80];
  NSRect wr;

  // First check ourselves
  if ([self mouse:aPoint inRect:bounds]) return self;

  return nil;
}

//
// Displaying
//
- (void)drawRect:(NSRect)rect
{
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: list_items];
  [aCoder encodeRect: list_rect];
  [aCoder encodeValueOfObjCType: "i" at: &selected_item];
  [aCoder encodeObjectReference: pub_target withName: @"Target"];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &pulls_down];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  list_items = [aDecoder decodeObject];
  list_rect = [aDecoder decodeRect];
  [aDecoder decodeValueOfObjCType: "i" at: &selected_item];
  [aDecoder decodeObjectAt: &pub_target withName: NULL];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &pub_action];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_up];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &pulls_down];

  return self;
}

@end
