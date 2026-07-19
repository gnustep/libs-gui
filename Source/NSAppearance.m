/* Implementation of class NSAppearance
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Jan 15 07:03:39 EST 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <AppKit/NSAppearance.h>
#import <Foundation/NSArchiver.h>

NSAppearance *__currentAppearance = nil;

@implementation NSAppearance

// Creating an appearance...
+ (instancetype) appearanceNamed: (NSString *)name
{
  return AUTORELEASE([[NSAppearance alloc] initWithAppearanceNamed: name
                                                            bundle: nil]);
}

- (instancetype) initWithAppearanceNamed: (NSString *)name bundle: (NSBundle *)bundle
{
  self = [super init];
  if (self)
    {
      ASSIGNCOPY(_name, name);
      _allowsVibrancy
        = [name isEqualToString: NSAppearanceNameVibrantLight]
        || [name isEqualToString: NSAppearanceNameVibrantDark]
        || [name isEqualToString:
             NSAppearanceNameAccessibilityHighContrastVibrantLight]
        || [name isEqualToString:
             NSAppearanceNameAccessibilityHighContrastVibrantDark];
    }
  return self;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
    }
  else
    {
      ASSIGN(_name, [coder decodeObject]);
      [coder decodeValueOfObjCType: @encode(BOOL) at: &_allowsVibrancy];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    if ([coder allowsKeyedCoding])
    {
    }
  else
    {
      [coder encodeObject: _name];
      [coder encodeValueOfObjCType: @encode(BOOL) at: &_allowsVibrancy];
    }
}

- (void) dealloc
{
  RELEASE(_name);
  [super dealloc];
}

// Getting the appearance name
- (NSString *) name
{
  return _name;
}

/* The appearance a vibrant appearance is a variant of.  Anything else stands
   for itself, so it only ever matches its own name. */
- (NSAppearanceName) _baseAppearanceName
{
  if ([_name isEqualToString: NSAppearanceNameVibrantLight]
    || [_name isEqualToString:
         NSAppearanceNameAccessibilityHighContrastVibrantLight])
    {
      return NSAppearanceNameAqua;
    }
  if ([_name isEqualToString: NSAppearanceNameVibrantDark]
    || [_name isEqualToString:
         NSAppearanceNameAccessibilityHighContrastVibrantDark])
    {
      return NSAppearanceNameDarkAqua;
    }
  return _name;
}

// Determining the most appropriate appearance
- (NSAppearanceName) bestMatchFromAppearancesWithNames: (NSArray *)appearances
{
  NSAppearanceName base;

  if ([appearances containsObject: _name])
    {
      return _name;
    }

  base = [self _baseAppearanceName];
  if (base != nil && [appearances containsObject: base])
    {
      return base;
    }

  return nil;
}

// Getting and setting the appearance
+ (void) setCurrentAppearance: (NSAppearance *)appearance
{
  ASSIGN(__currentAppearance, appearance);
}

+ (NSAppearance *) currentAppearance
{
  if (__currentAppearance == nil)
    {
      __currentAppearance = [[NSAppearance alloc]
        initWithAppearanceNamed: NSAppearanceNameAqua
                         bundle: nil];
    }
  return __currentAppearance;
}

// Managing vibrancy
- (BOOL) allowsVibrancy
{
  return _allowsVibrancy;
}

@end

