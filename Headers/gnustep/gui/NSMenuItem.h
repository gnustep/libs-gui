/* 
   NSMenuItem.h

   The menu cell protocol and the GNUstep menu cell class.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  David Lazaro Saz <khelekir@encomix.es>
   Date: Sep 1999

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

+ (void)setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL)usesUserKeyEquivalents;

+ (id <NSMenuItem>)separatorItem;

- (id)initWithTitle:(NSString *)aString
	     action:(SEL)aSelector
      keyEquivalent:(NSString *)charCode;

- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;

- (BOOL)hasSubmenu;
- (void)setSubmenu:(NSMenu *)submenu;
- (NSMenu *)submenu;

- (void)setTitle:(NSString*)aString;
- (NSString*)title;
- (BOOL)isSeparatorItem;

- (void)setKeyEquivalent:(NSString*)aKeyEquivalent;
- (NSString*)keyEquivalent;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;
- (unsigned int)keyEquivalentModifierMask;

- (NSString*)userKeyEquivalent;

- (void)setMnemonicLocation:(unsigned) location;
- (unsigned)mnemonicLocation;
- (NSString *)mnemonic;
- (void)setTitleWithMnemonic:(NSString *)stringWithAmpersand;

- (void)setImage:(NSImage *)menuImage;
- (NSImage *)image;

- (void)setState:(int)state;
- (int)state;
- (void)setOnStateImage:(NSImage *)image;
- (NSImage *)onStateImage;
- (void)setOffStateImage:(NSImage *)image;
- (NSImage *)offStateImage;
- (void)setMixedStateImage:(NSImage *)image;
- (NSImage *)mixedStateImage;

- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

- (void)setTag:(int)anInt;
- (int)tag;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

@end

@interface NSMenuItem : NSObject <NSMenuItem>
{
  NSMenu *mi_menu;
  NSString *mi_title;
  NSString *mi_keyEquivalent;
  unsigned int mi_keyEquivalentModifierMask;
  unsigned mi_mnemonicLocation;
  int mi_state;
  BOOL mi_enabled;
  NSImage *mi_image;
  NSImage *mi_onStateImage;
  NSImage *mi_offStateImage;
  NSImage *mi_mixedStateImage;
  id mi_target;
  SEL mi_action;
  int mi_tag;
  id mi_representedObject;
  BOOL mi_hasSubmenu;
  NSMenu *mi_submenu;
  BOOL mi_changesState;

  // Reserved for back-end use
  void *be_mi_reserved;
}

+ (void)setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL)usesUserKeyEquivalents;

+ (id <NSMenuItem>)separatorItem;

- (id)initWithTitle:(NSString *)aString
	     action:(SEL)aSelector
      keyEquivalent:(NSString *)charCode;

- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;

- (BOOL)hasSubmenu;
- (void)setSubmenu:(NSMenu *)submenu;
- (NSMenu *)submenu;

- (void)setTitle:(NSString *)aString;
- (NSString *)title;
- (BOOL)isSeparatorItem;

- (void)setKeyEquivalent:(NSString *)aKeyEquivalent;
- (NSString *)keyEquivalent;
- (void)setKeyEquivalentModifierMask:(unsigned int)mask;
- (unsigned int)keyEquivalentModifierMask;

- (NSString *)userKeyEquivalent;

- (void)setMnemonicLocation:(unsigned) location;
- (unsigned)mnemonicLocation;
- (NSString *)mnemonic;
- (void)setTitleWithMnemonic:(NSString *)stringWithAmpersand;

- (void)setImage:(NSImage *)menuImage;
- (NSImage *)image;

- (void)setState:(int)state;
- (int)state;
- (void)setOnStateImage:(NSImage *)image;
- (NSImage *)onStateImage;
- (void)setOffStateImage:(NSImage *)image;
- (NSImage *)offStateImage;
- (void)setMixedStateImage:(NSImage *)image;
- (NSImage *)mixedStateImage;

- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

- (void)setTag:(int)anInt;
- (int)tag;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

@end

@interface NSMenuItem (GNUstepExtra)

- (void)setChangesState:(BOOL)flag;
- (BOOL)changesState;

@end

/* Private stuff; it should be in a private header file but it really doesn't
   worth the effort. */
enum {
  INTERCELL_SPACE = 1,
  RIGHT_IMAGE_WIDTH = 12,
  ADDITIONAL_WIDTH = RIGHT_IMAGE_WIDTH + 15
};

#endif // _GNUstep_H_NSMenuItem
