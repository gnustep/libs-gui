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

@class NSString;

@class NSMenu;
@class NSImage;

/**
 * Specifies the methods that an object must implement if it is to be
 * placed in a menu as a menu item.  The [NSMenuItem] class provides
 * a reference implementation suitable for most uses.
 */
@protocol NSMenuItem <NSCopying, NSCoding, NSObject>

+ (id<NSMenuItem>) separatorItem;
+ (void) setUsesUserKeyEquivalents: (BOOL)flag;
+ (BOOL) usesUserKeyEquivalents;

- (SEL) action;
- (BOOL) hasSubmenu;
- (NSImage*) image;
- (id) initWithTitle: (NSString*)aString
	      action: (SEL)aSelector
       keyEquivalent: (NSString*)charCode;
- (BOOL) isEnabled;
- (BOOL) isSeparatorItem;
- (NSString*) keyEquivalent;
- (unsigned int) keyEquivalentModifierMask;
- (NSMenu*) menu;
- (NSImage*) mixedStateImage;
- (NSString*) mnemonic;
- (unsigned) mnemonicLocation;
- (NSImage*) offStateImage;
- (NSImage*) onStateImage;
- (id) representedObject;
- (void) setAction: (SEL)aSelector;
- (void) setEnabled: (BOOL)flag;
- (void) setImage: (NSImage*)menuImage;
- (void) setKeyEquivalent: (NSString*)aKeyEquivalent;
- (void) setKeyEquivalentModifierMask: (unsigned int)mask;
- (void) setMenu: (NSMenu*)menu;
- (void) setMixedStateImage: (NSImage*)image;
- (void) setMnemonicLocation: (unsigned) location;
- (void) setOffStateImage: (NSImage*)image;
- (void) setOnStateImage: (NSImage*)image;
- (void) setRepresentedObject: (id)anObject;
- (void) setState: (int)state;
- (void) setSubmenu: (NSMenu*)submenu;
- (void) setTag: (int)anInt;
- (void) setTarget: (id)anObject;
- (void) setTitle: (NSString*)aString;
- (void) setTitleWithMnemonic: (NSString*)stringWithAmpersand;
- (int) state;
- (NSMenu*) submenu;
- (int) tag;
- (id) target;
- (NSString*) title;
- (unsigned int) userKeyEquivalentModifierMask;
- (NSString*) userKeyEquivalent;

@end

@interface NSMenuItem : NSObject <NSMenuItem>
{
  NSMenu *_menu;
  NSString *_title;
  NSString *_keyEquivalent;
  unsigned int _keyEquivalentModifierMask;
  unsigned _mnemonicLocation;
  int _state;
  BOOL _enabled;
  NSImage *_image;
  NSImage *_onStateImage;
  NSImage *_offStateImage;
  NSImage *_mixedStateImage;
  id _target;
  SEL _action;
  int _tag;
  id _representedObject;
  NSMenu *_submenu;
  BOOL _changesState;
}

@end

#ifndef	NO_GNUSTEP
@interface NSMenuItem (GNUstepExtra)
- (void) setChangesState: (BOOL)flag;
- (BOOL) changesState;
@end
#endif

#endif // _GNUstep_H_NSMenuItem

