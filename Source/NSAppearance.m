/* Implementation of class NSAppearance
   Copyright (C) 2019 Free Software Foundation, Inc.
   
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

NSAppearance *__currentAppearance = nil;

@implementation NSAppearance

// Creating an appearance...
+ (instancetype) appearanceNamed: (NSString *)name
{
  return [[NSAppearance alloc] initWithAppearanceNamed: name bundle: nil];
}

- (instancetype) initWithAppearanceNamed: (NSString *)name bundle: (NSBundle *)bundle
{
  self = [super init];
  if(self)
    {
      ASSIGNCOPY(_name, name);
      _allowsVibrancy = NO;
    }
  return self;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (instancetype) copyWithZone: (NSZone *)zone
{
  return nil;
}

// Getting the appearance name
- (NSString *) name
{
  return _name;
}

// Determining the most appropriate appearance
- (NSAppearanceName) bestMatchFromAppearancesWithNames: (NSArray *)appearances
{
  return nil;
}

// Getting and setting the appearance
+ (void) setCurrentAppearance: (NSAppearance *)appearance
{
  ASSIGN(__currentAppearance, appearance);
}

+ (NSAppearance *) currentAppearance
{
  return __currentAppearance;
}

// Managing vibrancy
- (BOOL) allowsVibrancy
{
  return _allowsVibrancy;
}

@end

const NSAppearanceName NSAppearanceNameAqua = @"NSAppearanceNameAqua";
const NSAppearanceName NSAppearanceNameDarkAqua = @"NSAppearanceNameDarkAqua";
const NSAppearanceName NSAppearanceNameVibrantLight = @"NSAppearanceNameVibrantLight";
const NSAppearanceName NSAppearanceNameVibrantDark = @"NSAppearanceNameVibrantDark";
const NSAppearanceName NSAppearanceNameAccessibilityHighContrastAqua = @"NSAppearanceNameAccessibilityHighContrastAqua";
const NSAppearanceName NSAppearanceNameAccessibilityHighContrastDarkAqua = @"NSAppearanceNameAccessibilityHighContrastDarkAqua";
const NSAppearanceName NSAppearanceNameAccessibilityHighContrastVibrantLight = @"NSAppearanceNameAccessibilityHighContrastVibrantLight";
const NSAppearanceName NSAppearanceNameAccessibilityHighContrastVibrantDark = @"NSAppearanceNameAccessibilityHighContrastVibrantDark";
const NSAppearanceName NSAppearanceNameLightContent = @"NSAppearanceNameLightContent";
