/* 
   NSMenuItem.h

   The menu cell protocol and the GNUstep menu cell class.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
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

#ifndef _GNUstep_H_NSMenuItem
#define _GNUstep_H_NSMenuItem

#include <AppKit/NSButtonCell.h>

@protocol NSMenuItem <NSCopying, NSCoding>

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

- (void)setTitle:(NSString*)aString;
- (NSString*)title;

- (void)setTag:(int)anInt;
- (int)tag;

- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;

- (BOOL)hasSubmenu;

- (void)setKeyEquivalent:(NSString*)aKeyEquivalent;
- (NSString*)keyEquivalent;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;
- (unsigned int)keyEquivalentModifierMask;

+ (void)setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL)usesUserKeyEquivalents;
- (NSString*)userKeyEquivalent;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

@end


@interface NSMenuItem : NSButtonCell <NSMenuItem>
{
  id representedObject;
  BOOL hasSubmenu;

  // Reserved for back-end use
  void *be_mi_reserved;
}

- (void)setTitle:(NSString*)aString;
- (NSString*)title;

- (BOOL)hasSubmenu;

+ (void)setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL)usesUserKeyEquivalents;
- (NSString*)userKeyEquivalent;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

@end


/* Private stuff; it should be in a private header file but it really doesn't
   worth the effort. */
enum {
  INTERCELL_SPACE = 1,
  RIGHT_IMAGE_WIDTH = 12,
  ADDITIONAL_WIDTH = RIGHT_IMAGE_WIDTH + 15
};

#endif // _GNUstep_H_NSMenuItem
