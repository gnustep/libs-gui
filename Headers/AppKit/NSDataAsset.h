/* Definition of class NSDataAsset
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Fri Jan 17 10:25:34 EST 2020

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSDataAsset_h_GNUSTEP_GUI_INCLUDE
#define _NSDataAsset_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSData, NSBundle, NSString;

typedef NSString* NSDataAssetName;

APPKIT_EXPORT_CLASS
/**
 * NSDataAsset provides a convenient interface for accessing data resources
 * stored within application bundles. This class enables loading and managing
 * data assets that are packaged with applications, such as configuration files,
 * templates, reference data, or any binary content that needs to be accessible
 * at runtime. Data assets are identified by name and can be loaded from the
 * main bundle or from specified bundles. The class automatically handles
 * resource location, loading, and type identification based on file extensions
 * and bundle organization. NSDataAsset simplifies resource management by
 * providing a unified interface for accessing bundled data regardless of the
 * underlying file system structure or bundle configuration.
 */
@interface NSDataAsset : NSObject <NSCopying>
{
  NSDataAssetName _name;
  NSBundle *_bundle;
  NSData *_data;
  NSString *_typeIdentifier;
}

// Initializing the Data Asset
/**
 * Initializes a new data asset instance with the specified name, loading the
 * corresponding data from the main application bundle. The name parameter
 * identifies the data asset within the bundle's resource hierarchy, typically
 * corresponding to a file name without extension. The system searches for
 * the named resource using standard bundle loading mechanisms and creates
 * an NSDataAsset instance that provides access to the loaded data. This
 * convenience initializer simplifies resource loading when working with
 * the main bundle and eliminates the need to specify bundle references
 * explicitly. The initialization process includes automatic type detection
 * based on file characteristics and bundle metadata.
 */
- (instancetype) initWithName: (NSDataAssetName)name;
/**
 * Initializes a new data asset instance with the specified name and bundle,
 * enabling data loading from custom or alternative bundles. The name parameter
 * identifies the target data asset within the specified bundle's resource
 * structure. The bundle parameter specifies the source bundle from which to
 * load the data asset, allowing access to resources in frameworks, plugins,
 * or other bundle-based components. This method provides precise control over
 * resource location and enables modular applications to access data assets
 * from various bundle sources. The initialization process handles bundle
 * validation, resource location, and automatic type identification for the
 * loaded data asset.
 */
- (instancetype) initWithName: (NSDataAssetName)name bundle: (NSBundle *)bundle;

// Accessing data...
/**
 * Returns the data content of this data asset as an NSData object. The
 * returned data represents the complete binary or text content of the
 * underlying resource file as loaded from the bundle. This method provides
 * direct access to the raw data without any processing or transformation,
 * allowing applications to handle the data according to their specific
 * requirements. The data is loaded and cached during initialization, so
 * subsequent calls to this method return the same data instance efficiently.
 * Applications can use this data for any purpose including parsing,
 * processing, or direct consumption based on the asset's content type and
 * application needs.
 */
- (NSData *) data;

// Getting data asset information
/**
 * Returns the name identifier of this data asset as specified during
 * initialization. The name serves as the primary identifier for the data
 * asset within its containing bundle and corresponds to the resource name
 * used to locate and load the underlying data file. This property maintains
 * the original name reference throughout the asset's lifetime, enabling
 * applications to track and identify data assets consistently. The name
 * typically corresponds to a file name without extension, following bundle
 * resource naming conventions. Applications can use this name for logging,
 * debugging, or resource management purposes.
 */
- (NSDataAssetName) name;
/**
 * Returns the type identifier string that describes the format or content
 * type of this data asset. The type identifier is typically determined
 * automatically during asset loading based on file extensions, content
 * analysis, or bundle metadata. This identifier follows standard UTI
 * conventions when possible, providing standardized type information that
 * applications can use for content handling decisions. The type identifier
 * enables applications to process data assets appropriately based on their
 * format, apply correct parsing logic, or filter assets by content type.
 * This information supports type-safe data handling and proper resource
 * management.
 */
- (NSString *) typeIdentifier;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSDataAsset_h_GNUSTEP_GUI_INCLUDE */

