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

#ifndef GSFONTASSETINSTALLER_H
#define GSFONTASSETINSTALLER_H

#import <Foundation/NSObject.h>

@interface GSFontAssetInstaller : NSObject

+ (GSFontAssetInstaller *) sharedFontInstaller;
+ (void) setDefaultClass: (Class)cls;

// abstract methods

/**
 * Validates a downloaded font file.
 * This method can be overridden to implement custom validation
 * logic, such as checking font metadata, licensing information,
 * or performing security scans. The default implementation
 * checks file existence, size, and format signatures.
 */
- (BOOL) validateFontPath: (NSString *)fontPath error: (NSError **)error;

/**
 * Installs a font file to the appropriate system location.
 * This method can be overridden to implement custom installation
 * strategies, such as using system APIs, registering with font
 * management services, or applying custom permissions. Returns
 * YES if installation was successful, NO otherwise.
 */
- (BOOL) installFontPath: (NSString *)fontPath error: (NSError **)error;

/**
 * Returns the system fonts directory for the current platform.
 * This method can be overridden to customize the system font
 * installation location or to support additional platforms.
 */
- (NSString *) systemFontsDirectory;

/**
 * Returns the user fonts directory for the current platform.
 * This method can be overridden to customize the user font
 * installation location or to support additional platforms.
 */
- (NSString *) userFontsDirectory;

@end

#endif
