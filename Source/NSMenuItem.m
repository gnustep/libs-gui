/* 
   NSMenuItem.m

   The menu cell class.

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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenu.h>

static BOOL usesUserKeyEquivalents = NO;

static Class imageClass;

@implementation NSMenuItem

+ (void) initialize
{
  if (self == [NSMenuItem class])
    {
      [self setVersion: 1];
      imageClass = [NSImage class];
    }
}

+ (void) setUsesUserKeyEquivalents: (BOOL)flag
{
  usesUserKeyEquivalents = flag;
}

+ (BOOL) usesUserKeyEquivalents
{
  return usesUserKeyEquivalents;
}

+ (id <NSMenuItem>) separatorItem
{
  // FIXME: implementation needed (Lazaro).
  return nil;
}

- (id) init
{
  self = [super init];
  mi_target = nil;
  mi_menu = nil;
  mi_mnemonicLocation = 255; // No mnemonic
  mi_image = nil;
  mi_onStateImage = nil;
  mi_offStateImage = nil;
  mi_mixedStateImage = nil;
  mi_enabled = YES;
  mi_state = NSOffState;
  mi_changesState = NO;
  return self;
}

- (void) dealloc
{
  NSDebugLog (@"NSMenuItem '%@' dealloc", [self title]);

  TEST_RELEASE(mi_title);
  TEST_RELEASE(mi_keyEquivalent);
  TEST_RELEASE(mi_image);
  TEST_RELEASE(mi_onStateImage);
  TEST_RELEASE(mi_offStateImage);
  TEST_RELEASE(mi_mixedStateImage);
  TEST_RELEASE(mi_submenu);
  TEST_RELEASE(mi_representedObject);
  [super dealloc];
}

- (id) initWithTitle: (NSString*)aString
	      action: (SEL)aSelector
       keyEquivalent: (NSString*)charCode
{
  self = [self init];
  [self setTitle: aString];
  mi_action = aSelector;
  [self setKeyEquivalent: charCode];
  // Set the images according to the spec. On: check mark; off: dash.
  [self setOnStateImage: [imageClass imageNamed: @"common_2DCheckMark"]];
  [self setMixedStateImage: [imageClass imageNamed: @"common_2DDash"]];
  return self;
}

- (void) setMenu: (NSMenu*)menu
{
  mi_menu = menu;
  if (mi_submenu != nil)
    {
      [mi_submenu setSupermenu: menu];
      [self setTarget: mi_menu];
    }
}

- (NSMenu*) menu
{
  return mi_menu;
}

- (BOOL) hasSubmenu
{
  return (mi_submenu == nil) ? NO : YES;
}

- (void) setSubmenu: (NSMenu*)submenu
{
  if ([submenu supermenu] != nil)
    [NSException raise: NSInvalidArgumentException
		format: @"submenu already has supermenu: "];
  ASSIGN(mi_submenu, submenu);
  [submenu setSupermenu: mi_menu];
  [self setTarget: mi_menu];
  [self setAction: @selector(submenuAction:)];
}

- (NSMenu*) submenu
{
  return mi_submenu;
}

- (void) setTitle: (NSString*)aString
{
  NSString *_string;

  if (!aString)
    _string = @"";
  else
    _string = [aString copy];

  TEST_RELEASE(mi_title);
  mi_title = _string;
}

- (NSString*) title
{
  return mi_title;
}

- (BOOL) isSeparatorItem
{
  // FIXME: This stuff only makes sense in MacOS or Windows alike
  // interface styles. Maybe someone wants to implement this (Lazaro).
  return NO;
}

- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  NSString *_string;

  if (!aKeyEquivalent)
    _string = @"";
  else
    _string = [aKeyEquivalent copy];

  TEST_RELEASE(mi_keyEquivalent);
  mi_keyEquivalent = _string;
}

- (NSString*) keyEquivalent
{
  if (usesUserKeyEquivalents)
    return [self userKeyEquivalent];
  else
    return mi_keyEquivalent;
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  mi_keyEquivalentModifierMask = mask;
}

- (unsigned int) keyEquivalentModifierMask
{
  return mi_keyEquivalentModifierMask;
}

- (NSString*) userKeyEquivalent
{
  NSString	*userKeyEquivalent = [[[[NSUserDefaults standardUserDefaults]
      persistentDomainForName:NSGlobalDomain]
      objectForKey:@"NSCommandKeys"]
      objectForKey:mi_title];

  if (!userKeyEquivalent)
    userKeyEquivalent = @"";

  return userKeyEquivalent;
}

- (void) setMnemonicLocation: (unsigned)location
{
  mi_mnemonicLocation = location;
}

- (unsigned) mnemonicLocation
{
  if (mi_mnemonicLocation != 255)
    return mi_mnemonicLocation;
  else
    return NSNotFound;
}

- (NSString*) mnemonic
{
  if (mi_mnemonicLocation != 255)
    return [[mi_title substringFromIndex: mi_mnemonicLocation]
	                substringToIndex: 1];
  else
    return @"";
}

- (void) setTitleWithMnemonic: (NSString*)stringWithAmpersand
{
  // FIXME: Do something more than copy the string.  Anyway this will only
  // sense in Windows, so... (Lazaro).
  NSString *_string;

  if (!stringWithAmpersand)
    _string = @"";
  else
    _string = [stringWithAmpersand copy];

  TEST_RELEASE(mi_title);
  mi_title = _string;
}

- (void) setImage: (NSImage *)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(mi_image, image);
}

- (NSImage*) image
{
  return mi_image;
}

- (void) setState: (int)state
{
  mi_state = state;
  mi_changesState = YES;
}

- (int) state
{
  return mi_state;
}

- (void) setOnStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(mi_onStateImage, image);
}

- (NSImage*) onStateImage
{
  return mi_onStateImage;
}

- (void) setOffStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(mi_offStateImage, image);
}

- (NSImage*) offStateImage
{
  return mi_offStateImage;
}

- (void) setMixedStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(mi_mixedStateImage, image);
}

- (NSImage*) mixedStateImage
{
  return mi_mixedStateImage;
}

- (void) setEnabled: (BOOL)flag
{
  mi_enabled = flag;
}

- (BOOL) isEnabled
{
  return mi_enabled;
}

- (void) setTarget: (id)anObject
{
  mi_target = anObject;
}

- (id) target
{
  return mi_target;
}

- (void) setAction: (SEL)aSelector
{
  mi_action = aSelector;
}

- (SEL) action
{
  return mi_action;
}

- (void) setTag: (int)anInt
{
  mi_tag = anInt;
}

- (int) tag
{
  return mi_tag;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN(mi_representedObject, anObject);
}

- (id) representedObject
{
  return mi_representedObject;
}

/*
 * NSCopying protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSMenuItem *copy = [[isa allocWithZone: zone] init];

  NSDebugLog (@"menu item '%@' copy", [self title]);
  copy->mi_menu = mi_menu;
  copy->mi_title = [mi_title copyWithZone: zone];
  copy->mi_keyEquivalent = [mi_keyEquivalent copyWithZone: zone];
  copy->mi_keyEquivalentModifierMask = mi_keyEquivalentModifierMask;
  copy->mi_mnemonicLocation = mi_mnemonicLocation;
  copy->mi_state = mi_state;
  copy->mi_enabled = mi_enabled;
  ASSIGN(copy->mi_image, mi_image);
  ASSIGN(copy->mi_onStateImage, mi_onStateImage);
  ASSIGN(copy->mi_offStateImage, mi_offStateImage);
  ASSIGN(copy->mi_mixedStateImage, mi_mixedStateImage);
  copy->mi_changesState = mi_changesState;
  copy->mi_target = mi_target;
  copy->mi_action = mi_action;
  copy->mi_tag = mi_tag;
  copy->mi_representedObject = RETAIN(mi_representedObject);
  copy->mi_submenu = [mi_submenu copy];

  return copy;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: mi_title];
  [aCoder encodeObject: mi_keyEquivalent];
  [aCoder encodeValueOfObjCType: "I" at: &mi_keyEquivalentModifierMask];
  [aCoder encodeValueOfObjCType: "I" at: &mi_mnemonicLocation];
  [aCoder encodeValueOfObjCType: "i" at: &mi_state];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &mi_enabled];
  [aCoder encodeObject: mi_image];
  [aCoder encodeObject: mi_onStateImage];
  [aCoder encodeObject: mi_offStateImage];
  [aCoder encodeObject: mi_mixedStateImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &mi_changesState];
  [aCoder encodeConditionalObject: mi_target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &mi_action];
  [aCoder encodeValueOfObjCType: "i" at: &mi_tag];
  [aCoder encodeConditionalObject: mi_representedObject];
  [aCoder encodeObject: mi_submenu];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_title];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_keyEquivalent];
  [aDecoder decodeValueOfObjCType: "I" at: &mi_keyEquivalentModifierMask];
  [aDecoder decodeValueOfObjCType: "I" at: &mi_mnemonicLocation];
  [aDecoder decodeValueOfObjCType: "i" at: &mi_state];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &mi_enabled];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_onStateImage];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_offStateImage];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_mixedStateImage];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &mi_changesState];
  mi_target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &mi_action];
  [aDecoder decodeValueOfObjCType: "i" at: &mi_tag];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_representedObject];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &mi_submenu];

  return self;
}

@end

@implementation NSMenuItem (GNUstepExtra)

/*
 * These methods support the special arranging in columns of menu
 * items in GNUstep.  There's no need to use them outside but if
 * they are used the display is more pleasant.
 */
- (void) setChangesState: (BOOL)flag
{
  mi_changesState = flag;
}

- (BOOL) changesState
{
  return mi_changesState;
}

@end
