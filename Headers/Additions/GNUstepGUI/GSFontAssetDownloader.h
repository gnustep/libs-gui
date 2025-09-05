/* Definition of class GSFontAssetDownloader
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

#ifndef _GSFontAssetDownloader_h_GNUSTEP_GUI_INCLUDE
#define _GSFontAssetDownloader_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSError.h>

@class NSFontDescriptor;
@class NSURL;
@class NSString;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)

/**
 * GSFontAssetDownloader provides a pluggable mechanism for downloading
 * and installing font assets from various sources. This class can be
 * subclassed to implement custom font downloading strategies, such as
 * downloading from different font services, using authentication, or
 * implementing custom validation and installation procedures.
 *
 * The default implementation supports downloading fonts from HTTP/HTTPS
 * URLs and local file URLs, with basic validation and cross-platform
 * installation to standard font directories.
 *
 * Subclasses can override individual methods to customize specific
 * aspects of the download and installation process while reusing
 * other parts of the default implementation.
 *
 * CLASS REPLACEMENT SYSTEM:
 *
 * GSFontAssetDownloader supports a class replacement system that allows
 * applications to register a custom downloader class to be used globally.
 * This enables complete customization of font downloading behavior without
 * needing to modify every NSFontAssetRequest instance.
 *
 * Example usage:
 *
 * // Define a custom downloader class
 * @interface MyCustomFontDownloader : GSFontAssetDownloader
 * @end
 *
 * @implementation MyCustomFontDownloader
 * - (NSURL *) fontURLForDescriptor: (NSFontDescriptor *)descriptor {
 *     // Custom URL resolution logic
 *     return [NSURL URLWithString: @"https://my-font-service.com/..."];
 * }
 * @end
 *
 * // Register the custom class globally
 * [GSFontAssetDownloader setDefaultDownloaderClass: [MyCustomFontDownloader class]];
 *
 * // Or through NSFontAssetRequest
 * [NSFontAssetRequest setDefaultDownloaderClass: [MyCustomFontDownloader class]];
 *
 * // All new font asset requests will now use the custom downloader
 * NSFontAssetRequest *request = [[NSFontAssetRequest alloc]
 *     initWithFontDescriptors: descriptors options: 0];
 */
GS_EXPORT_CLASS
@interface GSFontAssetDownloader : NSObject
{
  NSUInteger _options;
}

/**
 * Registers a custom downloader class to be used instead of the default
 * GSFontAssetDownloader class. The registered class must be a subclass
 * of GSFontAssetDownloader. Pass nil to restore the default behavior.
 */
+ (void) setDefaultDownloaderClass: (Class)downloaderClass;

/**
 * Returns the currently registered downloader class, or GSFontAssetDownloader
 * if no custom class has been registered.
 */
+ (Class) defaultDownloaderClass;

/**
 * Creates a new font asset downloader instance using the currently
 * registered downloader class. This is the preferred method for creating
 * downloader instances as it respects any custom downloader class that
 * has been registered.
 */
+ (instancetype) downloaderWithOptions: (NSUInteger)options;

/**
 * Creates a new font asset downloader with the specified options.
 * The options parameter contains flags that control the download
 * and installation behavior, such as whether to use standard UI
 * or install to user vs system directories.
 */
- (instancetype) initWithOptions: (NSUInteger)options;

/**
 * Downloads and installs a font from the specified descriptor.
 * This is the main entry point for font downloading. The method
 * orchestrates the complete process: URL resolution, download,
 * validation, and installation. Returns YES if the font was
 * successfully downloaded and installed, NO otherwise.
 */
- (BOOL) downloadAndInstallFontWithDescriptor: (NSFontDescriptor *)descriptor
                                        error: (NSError **)error;

/**
 * Resolves a font URL from a font descriptor.
 * This method can be overridden to implement custom URL resolution
 * strategies, such as querying different font services or using
 * authentication tokens. The default implementation looks for a
 * custom URL attribute or constructs URLs from font names.
 */
- (NSURL *) fontURLForDescriptor: (NSFontDescriptor *)descriptor;

/**
 * Downloads a font file from the specified URL.
 * This method can be overridden to implement custom download
 * strategies, such as using authentication, custom headers, or
 * progress callbacks. Returns the path to the downloaded temporary
 * file, or nil on failure.
 */
- (NSString *) downloadFontFromURL: (NSURL *)fontURL
                             error: (NSError **)error;

/**
 * Validates a downloaded font file.
 * This method can be overridden to implement custom validation
 * logic, such as checking font metadata, licensing information,
 * or performing security scans. The default implementation
 * checks file existence, size, and format signatures.
 */
- (BOOL) validateFontFile: (NSString *)fontPath
                    error: (NSError **)error;

/**
 * Installs a font file to the appropriate system location.
 * This method can be overridden to implement custom installation
 * strategies, such as using system APIs, registering with font
 * management services, or applying custom permissions. Returns
 * YES if installation was successful, NO otherwise.
 */
- (BOOL) installFontAtPath: (NSString *)fontPath
                     error: (NSError **)error;

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

/**
 * Returns the options that were specified when creating this downloader.
 */
- (NSUInteger) options;

@end

#endif	/* GS_API_MACOSX */

#endif	/* _GSFontAssetDownloader_h_GNUSTEP_GUI_INCLUDE */
