/* 
   NSMenuItem.m

   The menu cell class.

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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenu.h>

static BOOL usesUserKeyEquivalents = YES;

@implementation NSMenuItem

+ (void)initialize
{
  if (self == [NSMenuItem class])
    {
      // Initial version
      [self setVersion:2];
    }
}

+ (void)setUsesUserKeyEquivalents:(BOOL)flag
{
  usesUserKeyEquivalents = flag;
}

+ (BOOL)usesUserKeyEquivalents
{
  return usesUserKeyEquivalents;
}

- init
{
  [self setAlignment:NSLeftTextAlignment];
  return self;
}

- (void)dealloc
{
  NSDebugLog (@"NSMenuItem '%@' dealloc", [self title]);

  [representedObject release];
  if (hasSubmenu)
    [target release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
  NSMenuItem* copy = [super copyWithZone:zone];

  NSDebugLog (@"menu item '%@' copy", [self title]);
  copy->representedObject = [representedObject retain];
  copy->hasSubmenu = hasSubmenu;
  if (hasSubmenu) {											// recursive call
      id submenu = [target copyWithZone:zone];				// to create our
      copy->target = [submenu retain];						// submenus
  }	

  return copy;
}

- (void)setTarget:(id)anObject
{
  hasSubmenu = anObject && [anObject isKindOfClass:[NSMenu class]];
  if (hasSubmenu) {
    [anObject retain];
    [target release];
  }
  [super setTarget:anObject];
}

- (void)setTitle:(NSString*)aString
{
  [super setStringValue:aString];
}

- (NSString*)title
{
  return [self stringValue];
}

- (BOOL)hasSubmenu
{
  return hasSubmenu;
}

- (BOOL)isEnabled
{
  if (hasSubmenu)
    return YES;
  else
    return [super isEnabled];
}

- (NSString*)keyEquivalent
{
  if (usesUserKeyEquivalents)
    return [self userKeyEquivalent];
  else
    return [super keyEquivalent];
}

- (NSString*)userKeyEquivalent
{
  NSString* userKeyEquivalent = [[[[NSUserDefaults standardUserDefaults]
      persistentDomainForName:NSGlobalDomain]
      objectForKey:@"NSCommandKeys"]
      objectForKey:[self stringValue]];

  if (!userKeyEquivalent)
    userKeyEquivalent = [super keyEquivalent];

  return userKeyEquivalent;
}

- (void)setRepresentedObject:(id)anObject
{
  ASSIGN(representedObject, anObject);
}

- (id)representedObject
{
  return representedObject;
}

@end
