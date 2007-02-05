/** <title>NSMenuItem</title>

   <abstract>The menu cell class.</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   Author:  David Lazaro Saz <khelekir@encomix.es>
   Date: Sep 1999
   
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include "config.h"
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <GNUstepBase/GSCategories.h>
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSCell.h"

static BOOL usesUserKeyEquivalents = NO;
static Class imageClass;

@interface GSMenuSeparator : NSMenuItem

@end

@implementation GSMenuSeparator

- (id) init
{
  self = [super initWithTitle: @"-----------"
		action: NULL
		keyEquivalent: @""];
  _enabled = NO;
  _changesState = NO;
  return self;
}

- (BOOL) isSeparatorItem
{
  return YES;
}

// FIXME: We need a lot of methods to switch of changes for a separator
@end


@implementation NSMenuItem

+ (void) initialize
{
  if (self == [NSMenuItem class])
    {
      [self setVersion: 3];
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
  return AUTORELEASE([GSMenuSeparator new]);
}

- (id) init
{
  return [self initWithTitle: @""
	       action: NULL
	       keyEquivalent: @""];
}

- (void) dealloc
{
  TEST_RELEASE(_title);
  TEST_RELEASE(_keyEquivalent);
  TEST_RELEASE(_image);
  TEST_RELEASE(_onStateImage);
  TEST_RELEASE(_offStateImage);
  TEST_RELEASE(_mixedStateImage);
  TEST_RELEASE(_submenu);
  TEST_RELEASE(_representedObject);
  TEST_RELEASE(_toolTip);
  [super dealloc];
}

- (id) initWithTitle: (NSString*)aString
	      action: (SEL)aSelector
       keyEquivalent: (NSString*)charCode
{
  self = [super init];
  //_menu = nil;
  [self setTitle: aString];
  [self setKeyEquivalent: charCode];
  _keyEquivalentModifierMask = NSCommandKeyMask;
  _mnemonicLocation = 255; // No mnemonic
  _state = NSOffState;
  _enabled = YES;
  //_image = nil;
  // Set the images according to the spec. On: check mark; off: dash.
  [self setOnStateImage: [imageClass imageNamed: @"NSMenuCheckmark"]];
  [self setMixedStateImage: [imageClass imageNamed: @"NSMenuMixedState"]];
  //_offStateImage = nil;
  //_target = nil;
  _action = aSelector;
  //_changesState = NO;
  return self;
}

- (void) setMenu: (NSMenu*)menu
{
  /* The menu is retaining us.  Do not retain it.  */
  _menu = menu;
  if (_submenu != nil)
    {
      [_submenu setSupermenu: menu];
      [self setTarget: _menu];
    }
}

- (NSMenu*) menu
{
  return _menu;
}

- (BOOL) hasSubmenu
{
  return (_submenu == nil) ? NO : YES;
}

- (void) setSubmenu: (NSMenu*)submenu
{
  if ([submenu supermenu] != nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"submenu (%@) already has supermenu (%@)",
		   [submenu title], [[submenu supermenu] title]];
    }
  ASSIGN(_submenu, submenu);
  if (submenu != nil)
    {
      [submenu setSupermenu: _menu];
      [submenu setTitle: _title];
    }
  [self setTarget: _menu];
  [self setAction: @selector(submenuAction:)];
  [_menu itemChanged: self];
}

- (NSMenu*) submenu
{
  return _submenu;
}

- (void) setTitle: (NSString*)aString
{
  if (nil == aString)
    aString = @"";

  ASSIGNCOPY(_title,  aString);
  [_menu itemChanged: self];
}

- (NSString*) title
{
  return _title;
}

- (BOOL) isSeparatorItem
{
  return NO;
}

- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  if (nil == aKeyEquivalent)
    aKeyEquivalent = @"";

  ASSIGNCOPY(_keyEquivalent,  aKeyEquivalent);
  [_menu itemChanged: self];
}

- (NSString*) keyEquivalent
{
  if (usesUserKeyEquivalents)
    return [self userKeyEquivalent];
  else
    return _keyEquivalent;
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  _keyEquivalentModifierMask = mask;
}

- (unsigned int) keyEquivalentModifierMask
{
  return _keyEquivalentModifierMask;
}

- (NSString*) userKeyEquivalent
{
  NSString *userKeyEquivalent = [(NSDictionary*)[[[NSUserDefaults standardUserDefaults]
				      persistentDomainForName: NSGlobalDomain]
				     objectForKey: @"NSCommandKeys"]
				    objectForKey: _title];

  if (nil == userKeyEquivalent)
    userKeyEquivalent = @"";

  return userKeyEquivalent;
}

- (unsigned int) userKeyEquivalentModifierMask
{
  // FIXME
  return NSCommandKeyMask;
}

- (void) setMnemonicLocation: (unsigned)location
{
  _mnemonicLocation = location;
  [_menu itemChanged: self];
}

- (unsigned) mnemonicLocation
{
  if (_mnemonicLocation != 255)
    return _mnemonicLocation;
  else
    return NSNotFound;
}

- (NSString*) mnemonic
{
  if (_mnemonicLocation != 255)
    return [_title substringWithRange: NSMakeRange(_mnemonicLocation, 1)];
  else
    return @"";
}

- (void) setTitleWithMnemonic: (NSString*)stringWithAmpersand
{
  unsigned int location = [stringWithAmpersand rangeOfString: @"&"].location;

  [self setTitle: [stringWithAmpersand stringByReplacingString: @"&"
				       withString: @""]];
  [self setMnemonicLocation: location];
}

- (void) setImage: (NSImage *)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_image, image);
  [_menu itemChanged: self];
}

- (NSImage*) image
{
  return _image;
}

- (void) setState: (int)state
{
  if (_state == state)
    return;

  _state = state;
  _changesState = YES;
  [_menu itemChanged: self];
}

- (int) state
{
  return _state;
}

- (void) setOnStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_onStateImage, image);
  [_menu itemChanged: self];
}

- (NSImage*) onStateImage
{
  return _onStateImage;
}

- (void) setOffStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_offStateImage, image);
  [_menu itemChanged: self];
}

- (NSImage*) offStateImage
{
  return _offStateImage;
}

- (void) setMixedStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_mixedStateImage, image);
  [_menu itemChanged: self];
}

- (NSImage*) mixedStateImage
{
  return _mixedStateImage;
}

- (void) setEnabled: (BOOL)flag
{
  if (flag == _enabled)
    return;

  _enabled = flag;
  [_menu itemChanged: self];
}

- (BOOL) isEnabled
{
  return _enabled;
}

- (void) setTarget: (id)anObject
{
  if (_target == anObject)
    return;

  _target = anObject;
  [_menu itemChanged: self];
}

- (id) target
{
  return _target;
}

- (void) setAction: (SEL)aSelector
{
  if (_action == aSelector)
    return;

  _action = aSelector;
  [_menu itemChanged: self];
}

- (SEL) action
{
  return _action;
}

- (void) setTag: (int)anInt
{
  _tag = anInt;
}

- (int) tag
{
  return _tag;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN(_representedObject, anObject);
}

- (id) representedObject
{
  return _representedObject;
}

- (NSAttributedString *)attributedTitle
{
  // FIXME
  return nil;
}

-(void) setAttributedTitle: (NSAttributedString *)title
{
  // FIXME
  [self setTitle: [title string]];
}

- (int)indentationLevel
{
  return _indentation;
}

- (void)setIndentationLevel: (int)level
{
  _indentation = level;
}

- (BOOL)isAlternate
{
  return _isAlternate;
}

- (void) setAlternate: (BOOL)isAlternate
{
  _isAlternate = isAlternate;
}

- (void) setToolTip: (NSString *)toolTip
{
  ASSIGN(_toolTip, toolTip);
}

- (NSString *) toolTip
{
  return _toolTip;
}

/*
 * NSCopying protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSMenuItem *copy = (NSMenuItem*)NSCopyObject (self, 0, zone);

  // We reset the menu to nil to allow the reuse of the copy
  copy->_menu = nil;
  copy->_title = [_title copyWithZone: zone];
  copy->_keyEquivalent = [_keyEquivalent copyWithZone: zone];
  copy->_image = [_image copyWithZone: zone];
  copy->_onStateImage = [_onStateImage copyWithZone: zone];
  copy->_offStateImage = [_offStateImage copyWithZone: zone];
  copy->_mixedStateImage = [_mixedStateImage copyWithZone: zone];
  copy->_representedObject = RETAIN(_representedObject);
  copy->_submenu = [_submenu copy];
  copy->_toolTip = RETAIN(_toolTip);

  return copy;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _title forKey: @"NSTitle"];
      [aCoder encodeObject: NSStringFromSelector(_action) forKey: @"NSAction"];
      [aCoder encodeObject: _keyEquivalent forKey: @"NSKeyEquiv"];
      [aCoder encodeObject: _onStateImage forKey: @"NSOnImage"];
      [aCoder encodeObject: _offStateImage forKey: @"NSOffImage"]; // ???????
      [aCoder encodeObject: _mixedStateImage forKey: @"NSMixedImage"]; 
      [aCoder encodeObject: _target forKey: @"NSTarget"]; 
      [aCoder encodeObject: _menu forKey: @"NSMenu"];
      [aCoder encodeObject: _submenu forKey: @"NSSubmenu"];
      [aCoder encodeInt: _keyEquivalentModifierMask forKey: @"NSKeyEquivModMask"];
      [aCoder encodeInt: _mnemonicLocation forKey: @"NSMnemonicLoc"];
      [aCoder encodeInt: _state forKey: @"NSState"];
    }
  else
    {
      [aCoder encodeObject: _title];
      [aCoder encodeObject: _keyEquivalent];
      [aCoder encodeValueOfObjCType: "I" at: &_keyEquivalentModifierMask];
      [aCoder encodeValueOfObjCType: "I" at: &_mnemonicLocation];
      [aCoder encodeValueOfObjCType: "i" at: &_state];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_enabled];
      [aCoder encodeObject: _image];
      [aCoder encodeObject: _onStateImage];
      [aCoder encodeObject: _offStateImage];
      [aCoder encodeObject: _mixedStateImage];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_changesState];
      [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
      [aCoder encodeValueOfObjCType: "i" at: &_tag];
      [aCoder encodeConditionalObject: _representedObject];
      [aCoder encodeObject: _submenu];
      [aCoder encodeConditionalObject: _target];
      
      // version 3
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isAlternate];
      [aCoder encodeValueOfObjCType: @encode(char) at: &_indentation];
      [aCoder encodeObject: _toolTip];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      NSString *title;
      NSString *action;
      NSString *key;
      NSImage *mixedImage;
      NSImage *onImage;
      id target;
      NSMenu *submenu;

      title = [aDecoder decodeObjectForKey: @"NSTitle"];
      action = [aDecoder decodeObjectForKey: @"NSAction"];
      key = [aDecoder decodeObjectForKey: @"NSKeyEquiv"];
      mixedImage = [aDecoder decodeObjectForKey: @"NSMixedImage"];
      onImage = [aDecoder decodeObjectForKey: @"NSOnImage"];
      target = [aDecoder decodeObjectForKey: @"NSTarget"];
      [aDecoder decodeObjectForKey: @"NSMenu"];
      submenu = [aDecoder decodeObjectForKey: @"NSSubmenu"];

      self = [self initWithTitle: title
		   action: NSSelectorFromString(action)
		   keyEquivalent: key];
      [self setTarget: target];
      [self setMixedStateImage: mixedImage];
      [self setOnStateImage: onImage];
      [self setSubmenu: submenu];

      if ([aDecoder containsValueForKey: @"NSKeyEquivModMask"])
        {
	  int keyMask = [aDecoder decodeIntForKey: @"NSKeyEquivModMask"];
	  [self setKeyEquivalentModifierMask: keyMask];
	}
      if ([aDecoder containsValueForKey: @"NSMnemonicLoc"])
        {
	  int loc = [aDecoder decodeIntForKey: @"NSMnemonicLoc"];
	  [self setMnemonicLocation: loc];
	}
      if ([aDecoder containsValueForKey: @"NSState"])
        {
	  int state = [aDecoder decodeIntForKey: @"NSState"];
	  [self setState: state];
	}
    }
  else
    {
      int version = [aDecoder versionForClassName: 
				  @"NSMenuItem"];
    
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_title];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_keyEquivalent];
      [aDecoder decodeValueOfObjCType: "I" at: &_keyEquivalentModifierMask];
      [aDecoder decodeValueOfObjCType: "I" at: &_mnemonicLocation];
      [aDecoder decodeValueOfObjCType: "i" at: &_state];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_enabled];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_image];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_onStateImage];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_offStateImage];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_mixedStateImage];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_changesState];
      if (version == 1)
        {
	  _target = [aDecoder decodeObject];
	}
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
      [aDecoder decodeValueOfObjCType: "i" at: &_tag];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_representedObject];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_submenu];
      if (version >= 2)
        {
	  _target = [aDecoder decodeObject];
	}
      if (version == 3)
        {
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isAlternate];
	  [aDecoder decodeValueOfObjCType: @encode(char) at: &_indentation];
	  [aDecoder decodeValueOfObjCType: @encode(id) at: &_toolTip];
	}
    }

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
  _changesState = flag;
}

- (BOOL) changesState
{
  return _changesState;
}

@end
