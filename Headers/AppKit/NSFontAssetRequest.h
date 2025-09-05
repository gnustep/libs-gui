/* Definition of class NSFontAssetRequest
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Tue Apr  7 08:06:56 EDT 2020

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

#ifndef _NSFontAssetRequest_h_GNUSTEP_GUI_INCLUDE
#define _NSFontAssetRequest_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSError.h>

DEFINE_BLOCK_TYPE(GSFontAssetCompletionHandler, BOOL, NSError*);

@class NSProgress;
@class NSFontDescriptor;
@class GSFontAssetDownloader;
// @protocol NSProgressReporting;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

enum {
  NSFontAssetRequestOptionUsesStandardUI = 1 << 0, // Use standard system UI for downloading.
};
typedef NSUInteger NSFontAssetRequestOptions;

APPKIT_EXPORT_CLASS
@interface NSFontAssetRequest : NSObject // <NSProgressReporting>
{
  NSArray *_fontDescriptors;
  NSFontAssetRequestOptions _options;
  NSMutableArray *_downloadedFontDescriptors;
  NSProgress *_progress;
  BOOL _downloadInProgress;
  GSFontAssetDownloader *_downloader;
}

- (instancetype) initWithFontDescriptors: (NSArray *)fontDescriptors
                                 options: (NSFontAssetRequestOptions)options;

/**
 * Sets the default downloader class to be used for all new font asset requests.
 * The specified class must be a subclass of GSFontAssetDownloader.
 * Pass nil to restore the default GSFontAssetDownloader behavior.
 */
+ (void) setDefaultDownloaderClass: (Class)downloaderClass;

/**
 * Returns the currently registered default downloader class.
 */
+ (Class) defaultDownloaderClass;

/**
 * Returns an array of font descriptors that have been successfully downloaded.
 */
- (NSArray *) downloadedFontDescriptors;

/**
 * Returns the progress object for the font asset request.
 */
- (NSProgress *) progress;

/**
 * Downloads the specified font assets.
 */
- (void)downloadFontAssetsWithCompletionHandler: (GSFontAssetCompletionHandler)completionHandler;

/**
 * Sets a custom font asset downloader.
 * This allows clients to provide custom downloading strategies
 * by subclassing GSFontAssetDownloader and overriding specific
 * methods for URL resolution, downloading, validation, or installation.
 * The downloader parameter specifies the custom downloader to use,
 * replacing the default downloader instance.
 */
- (void) setFontAssetDownloader: (GSFontAssetDownloader *)downloader;

/**
 * Returns the current font asset downloader.
 * This can be used to inspect or modify the downloader's configuration,
 * or to access the downloader for direct use in custom scenarios.
 * Returns the GSFontAssetDownloader instance currently being used.
 */
- (GSFontAssetDownloader *) fontAssetDownloader;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSFontAssetRequest_h_GNUSTEP_GUI_INCLUDE */
