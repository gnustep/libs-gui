/* 
   NSMenuCell.h

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

#ifndef _GNUstep_H_NSMenuCell
#define _GNUstep_H_NSMenuCell

#include <AppKit/stdappkit.h>
#include <AppKit/NSButtonCell.h>
#include <Foundation/NSCoder.h>

@class NSMenu;

@interface NSMenuCell : NSButtonCell <NSCoding>

{
  // Attributes
  NSString *key_equivalent;
  NSMenu *sub_menu;
  unsigned int menu_identifier;

  // Reserved for back-end use
  void *be_mc_reserved;
}

//
// WIN32 methods
//
- (unsigned int)menuIdentifier;
- (void)setMenuIdentifier:(unsigned int)theID;

//
// Checking for a Submenu 
//
- (BOOL)hasSubmenu;
- (NSMenu *)submenu;
- (void)setSubmenu:(NSMenu *)aMenu;

//
// Managing User Key Equivalents 
//
+ (void)setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL)usesUserKeyEquivalents;
- (NSString *)userKeyEquivalent;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSMenuCell
