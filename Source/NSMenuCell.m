/* 
   NSMenuCell.m

   Cell class for menu items

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/NSMenuCell.h>
#include <gnustep/gui/NSMenu.h>
#include <gnustep/base/NSCoder.h>

//
// Class variables
//
BOOL MB_NSMENUCELL_USES_KEY;

@implementation NSMenuCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSMenuCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Managing User Key Equivalents 
//
+ (void)setUsesUserKeyEquivalents:(BOOL)flag
{
  MB_NSMENUCELL_USES_KEY = flag;
}

+ (BOOL)usesUserKeyEquivalents
{
  return MB_NSMENUCELL_USES_KEY;
}

//
// Instance methods
//
- (unsigned int)menuIdentifier
{
  return menu_identifier;
}

- (void)setMenuIdentifier:(unsigned int)theID
{
  menu_identifier = theID;
}

//
// Initialization
//
- init
{
  return [self initTextCell:@"Text"];
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];
  [self setEnabled:YES];
  sub_menu = nil;
  return self;
}

- (void)dealloc
{
  [sub_menu release];
  [super dealloc];
}

//
// Checking for a Submenu 
//
- (BOOL)hasSubmenu
{
  if (sub_menu)
    return YES;
  else
    return NO;
}

- (NSMenu *)submenu
{
  return sub_menu;
}

- (void)setSubmenu:(NSMenu *)aMenu
{
  [sub_menu release];
  sub_menu = aMenu;
  [sub_menu retain];
}

- (NSString *)userKeyEquivalent
{
  return key_equivalent;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: key_equivalent];
  [aCoder encodeObject: sub_menu];
  [aCoder encodeValueOfObjCType: "I" at: &menu_identifier];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  key_equivalent = [aDecoder decodeObject];
  sub_menu = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: "I" at: &menu_identifier];

  return self;
}

@end

