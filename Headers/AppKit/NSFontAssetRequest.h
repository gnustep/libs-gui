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
#import <Foundation/NSProgress.h>

/**
 * Block type for font asset download completion handling.
 * This block is called when a font asset download operation completes,
 * either successfully or with an error.
 * The first parameter indicates success (YES) or failure (NO).
 * The second parameter contains an NSError object describing any error
 * that occurred, or nil on success.
 */
DEFINE_BLOCK_TYPE(GSFontAssetCompletionHandler, BOOL, NSError*);

@class NSFontDescriptor;
@class GSFontAssetDownloader;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

/**
 * Options for controlling font asset request behavior.
 * These flags modify how font assets are downloaded and presented to the user.
 */
enum {
  /**
   * Use the standard system user interface for font downloading.
   * When set, the system will display standard progress dialogs and
   * user notifications during the font download process.
   */
  NSFontAssetRequestOptionUsesStandardUI = 1 << 0, // Use standard system UI for downloading.
};
typedef NSUInteger NSFontAssetRequestOptions;

/**
 * NSFontAssetRequest provides a mechanism for downloading font assets that are
 * not currently available on the local system. This is particularly useful for
 * applications that need to access fonts that may be available through system
 * font downloading services or cloud-based font libraries.
 *
 * The class manages the entire download process, including progress tracking,
 * error handling, and notification when fonts become available. It supports
 * downloading multiple fonts simultaneously and provides completion handlers
 * for asynchronous notification of download status.
 *
 * Font asset requests are created with an array of font descriptors that
 * specify the desired fonts, along with options that control the download
 * behavior and user interface presentation. The download process is
 * asynchronous and non-blocking, allowing applications to continue normal
 * operation while fonts are being retrieved.
 */
APPKIT_EXPORT_CLASS
@interface NSFontAssetRequest : NSObject <NSProgressReporting>
{
  NSArray *_fontDescriptors;
  NSFontAssetRequestOptions _options;
  NSMutableArray *_downloadedFontDescriptors;
  NSProgress *_progress;
  BOOL _downloadInProgress;
  GSFontAssetDownloader *_downloader;
}

/**
 * Initializes a font asset request with the specified font descriptors and options.
 * Creates a new font asset request that will attempt to download the fonts
 * described by the provided font descriptors. The options parameter controls
 * how the download process behaves and whether standard system UI is used.
 * The fontDescriptors parameter should contain an array of NSFontDescriptor
 * objects describing the fonts to be downloaded. Each descriptor should specify
 * enough information to uniquely identify the desired font.
 * The options parameter contains flags controlling the download behavior,
 * such as whether to use standard system UI for progress indication.
 * Returns a newly initialized font asset request object.
 */
- (instancetype) initWithFontDescriptors: (NSArray *)fontDescriptors
                                 options: (NSFontAssetRequestOptions)options;

/**
 * Returns an array of font descriptors for fonts that have been successfully downloaded.
 * This method returns the subset of requested fonts that are now available on
 * the local system after successful download. The returned descriptors can be
 * used to create NSFont objects for the newly available fonts.
 * Returns an array of NSFontDescriptor objects representing successfully
 * downloaded fonts, or an empty array if no fonts have been downloaded yet.
 */
- (NSArray *) downloadedFontDescriptors;

/**
 * Returns an NSProgress object for tracking download progress.
 * The progress object provides detailed information about the download operation,
 * including completion percentage, estimated time remaining, and cancellation
 * capabilities. Applications can observe this progress object to provide
 * custom progress UI or to implement cancellation logic.
 * Returns an NSProgress object representing the current state of the font
 * download operation.
 */
- (NSProgress *) progress;

/**
 * Initiates the font asset download process with a completion handler.
 * This method begins the asynchronous download of the requested font assets.
 * The download process runs in the background, and the provided completion
 * handler is called when the operation finishes, either successfully or with
 * an error.
 * The completion handler receives a boolean indicating success and an error
 * object (if applicable). On successful completion, the downloadedFontDescriptors
 * method will return descriptors for the newly available fonts.
 * The completionHandler parameter is a block that will be called when the download
 * operation completes. The block receives a boolean indicating success and an
 * NSError object on failure.
 */
- (void)downloadFontAssetsWithCompletionHandler: (GSFontAssetCompletionHandler)completionHandler;

@end

@interface NSFontAssetRequest (GNUstep)

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
