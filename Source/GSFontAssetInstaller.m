/* Implementation of class GSFontAssetInstaller
   Copyright (C) 2024 Free Software Foundation, Inc.

   By: Gregory John Casamento <greg.casamento@gmail.com>
   Date: September 5, 2025

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/Foundation.h>
#import "GNUstepGUI/GSFontAssetInstaller.h"

static GSFontAssetInstaller *sharedFontAssetInstaller = nil;
static Class fontAssetClass = Nil;

@implementation GSFontAssetInstaller

+ (GSFontAssetInstaller *) sharedFontInstaller
{
  NSAssert(fontAssetClass,
	   @"Called with fontAssetClass unset."
	   @" The shared NSApplication instance must be created before methods that"
	   @" need the backend may be called.");

  if (!sharedFontAssetInstaller)
    {
      sharedFontAssetInstaller = [[fontAssetClass alloc] init];
    }

  return sharedFontAssetInstaller;
}

+ (void) setDefaultClass: (Class)cls
{
  fontAssetClass = cls;
}

- (BOOL) validateFontPath: (NSString *)fontPath error: (NSError **)error
{
  return NO; // Some backends use different font formats.
}

- (BOOL) installFontPath: (NSString *)fontPath error: (NSError **)error
{
  return NO; // Backends may put fonts in different locations.
}

- (NSString *) userFontsDirectory
{
  return nil; // Locations are OS specific.
}

- (NSString *) systemFontsDirectory
{
  return nil; // Locations are OS specific.
}

@end
