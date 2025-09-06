/* Implementation of cla#import <Foundation/Foundation.h>
   Copyright (C) 2019 Free Software Foundation, Inc.

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

#import <Foundation/Foundation.h>
#import "AppKit/NSFontAssetRequest.h"
#import "AppKit/NSFontDescriptor.h"
#import "GNUstepGUI/GSFontAssetDownloader.h"

@interface NSFontAssetRequest (Private)
- (void) _performFontDownloadWithCompletionHandler: (GSFontAssetCompletionHandler)completionHandler;
- (void) _updateProgressWithDescription: (NSString *)description;
- (void) _completeDownloadWithError: (NSError *)error
                  completionHandler: (GSFontAssetCompletionHandler)completionHandler;
@end

@implementation NSFontAssetRequest

+ (void) setDefaultDownloaderClass: (Class)downloaderClass
{
  [GSFontAssetDownloader setDefaultDownloaderClass: downloaderClass];
}

+ (Class) defaultDownloaderClass
{
  return [GSFontAssetDownloader defaultDownloaderClass];
}

- (instancetype) initWithFontDescriptors: (NSArray *)fontDescriptors
                                 options: (NSFontAssetRequestOptions)options
{
  self = [super init];
  if (self != nil)
    {
      _fontDescriptors = [fontDescriptors copy];
      _options = options;
      _downloadedFontDescriptors = [[NSMutableArray alloc] init];
      _progress = [NSProgress progressWithTotalUnitCount: [fontDescriptors count]];
      [_progress setCompletedUnitCount: 0];
      _downloadInProgress = NO;
      _downloader = [[GSFontAssetDownloader alloc] initWithOptions: options];
      // [_progress setLocalizedDescription: @"Downloading fonts..."];
      // [_progress setLocalizedAdditionalDescription: @"Preparing to download font assets"];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_fontDescriptors);
  RELEASE(_downloadedFontDescriptors);
  RELEASE(_progress);
  RELEASE(_downloader);
  [super dealloc];
}

- (NSArray *) downloadedFontDescriptors
{
  return [[_downloadedFontDescriptors copy] autorelease];
}

- (NSProgress *) progress
{
  return _progress;
}

- (void) downloadFontAssetsWithCompletionHandler:
  (GSFontAssetCompletionHandler)completionHandler
{
  NSAssert(completionHandler != NULL, @"Completion handler cannot be nil");

  if (_downloadInProgress)
    {
      // Already downloading, call completion handler with error
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font asset download already in progress"
                                                           forKey: NSLocalizedDescriptionKey];
      NSError *error = [NSError errorWithDomain: @"NSFontAssetRequestErrorDomain"
                                          code: -1001
                                      userInfo: userInfo];
      CALL_NON_NULL_BLOCK(completionHandler, error);
      return;
    }

  _downloadInProgress = YES;

  // Use timer-based simulation instead of GCD blocks for compatibility
  [self performSelector: @selector(_performFontDownloadWithCompletionHandler:)
             withObject: completionHandler
             afterDelay: 0.0];
}

- (void) _performFontDownloadWithCompletionHandler: (GSFontAssetCompletionHandler)completionHandler
{
  NSError *downloadError = nil;
  BOOL success = YES;
  NSUInteger i, count;

  NS_DURING
    {
      count = [_fontDescriptors count];

      // Process each font descriptor
      for (i = 0; i < count; i++)
        {
          NSFontDescriptor *descriptor = [_fontDescriptors objectAtIndex: i];
          NSError *fontError = nil;

          // Update progress description
          NSString *fontName = [descriptor objectForKey: NSFontNameAttribute];
          if (fontName == nil)
            {
              fontName = @"Unknown";
            }
          NSString *progressDescription = [NSString stringWithFormat: @"Processing font: %@", fontName];
          [self _updateProgressWithDescription: progressDescription];

          // Check if progress was cancelled
          if ([_progress isCancelled])
            {
              success = NO;
              NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font asset download was cancelled"
                                                               forKey: NSLocalizedDescriptionKey];
              downloadError = [NSError errorWithDomain: @"NSFontAssetRequestErrorDomain"
                                                 code: -1002
                                             userInfo: userInfo];
              break;
            }

          // Use the downloader to download and install the font
          if ([_downloader downloadAndInstallFontWithDescriptor: descriptor error: &fontError])
            {
              // Successfully downloaded and installed
              [_downloadedFontDescriptors addObject: descriptor];
              NSLog(@"Successfully installed font: %@", fontName);
            }
          else
            {
              NSLog(@"Failed to download/install font %@: %@", fontName, [fontError localizedDescription]);
            }

          // Update progress
          [_progress setCompletedUnitCount: i + 1];
        }

      if (success)
        {
          [self _updateProgressWithDescription: @"Font download and installation completed"];
        }
    }
  NS_HANDLER
    {
      success = NO;
      NSString *reason = [localException reason];
      if (reason == nil)
        {
          reason = @"Unknown error";
        }
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Font asset download failed", NSLocalizedDescriptionKey,
                                reason, NSLocalizedFailureReasonErrorKey,
                                nil];
      downloadError = [NSError errorWithDomain: @"NSFontAssetRequestErrorDomain"
                                         code: -1003
                                     userInfo: userInfo];
    }
  NS_ENDHANDLER

  [self _completeDownloadWithError: downloadError
                 completionHandler: completionHandler];
}

- (void) _updateProgressWithDescription: (NSString *)description
{
  // [_progress setLocalizedAdditionalDescription: description];
}

- (void) _completeDownloadWithError: (NSError *)downloadError
                  completionHandler: (GSFontAssetCompletionHandler)completionHandler
{
  _downloadInProgress = NO;

  if (downloadError == nil)
    {
      // Success case - no error
      CALL_NON_NULL_BLOCK(completionHandler, nil);
    }
  else
    {
      // Error case
      CALL_NON_NULL_BLOCK(completionHandler, downloadError);
    }
}

// Additional helper methods that could be useful

- (NSArray *) fontDescriptors
{
  return [[_fontDescriptors copy] autorelease];
}

- (NSFontAssetRequestOptions) options
{
  return _options;
}

- (BOOL) isDownloadInProgress
{
  return _downloadInProgress;
}

/**
 * Sets a custom font asset downloader.
 * This allows clients to provide custom downloading strategies
 * by subclassing GSFontAssetDownloader and overriding specific
 * methods for URL resolution, downloading, validation, or installation.
 */
- (void) setFontAssetDownloader: (GSFontAssetDownloader *)downloader
{
  if (downloader != _downloader)
    {
      RELEASE(_downloader);
      _downloader = [downloader retain];
    }
}

/**
 * Returns the current font asset downloader.
 * This can be used to inspect or modify the downloader's configuration.
 */
- (GSFontAssetDownloader *) fontAssetDownloader
{
  return _downloader;
}

@end
