/* Implementation of class GSFontAssetDownloader
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
#import "GNUstepGUI/GSFontAssetDownloader.h"
#import "AppKit/NSFontDescriptor.h"
#import "AppKit/NSFontAssetRequest.h"
#import "AppKit/NSPanel.h"
#import "AppKit/NSProgressIndicator.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSButton.h"
#import "AppKit/NSApplication.h"

static Class _defaultDownloaderClass = nil;

/*
 * EXAMPLE USAGE OF CLASS REPLACEMENT SYSTEM:
 *
 * // Custom downloader that logs all operations
 * @interface LoggingFontDownloader : GSFontAssetDownloader
 * @end
 *
 * @implementation LoggingFontDownloader
 * - (NSURL *) fontURLForDescriptor: (NSFontDescriptor *)descriptor {
 *     NSLog(@"Resolving URL for font: %@", [descriptor objectForKey: NSFontNameAttribute]);
 *     return [super fontURLForDescriptor: descriptor];
 * }
 *
 * - (NSString *) downloadFontFromURL: (NSURL *)fontURL error: (NSError **)error {
 *     NSLog(@"Downloading font from: %@", fontURL);
 *     return [super downloadFontFromURL: fontURL error: error];
 * }
 * @end
 *
 * // To use the custom downloader globally:
 * [GSFontAssetDownloader setDefaultDownloaderClass: [LoggingFontDownloader class]];
 *
 * // To restore default behavior:
 * [GSFontAssetDownloader setDefaultDownloaderClass: nil];
 */

@implementation GSFontAssetDownloader

- (instancetype) initWithOptions: (NSUInteger)options
{
  self = [super init];
  if (self != nil)
    {
      _options = options;
    }
  return self;
}

- (instancetype) init
{
  return [self initWithOptions: 0];
}

- (void) dealloc
{
  [self hideProgressPanel];
  [super dealloc];
}

+ (void) setDefaultDownloaderClass: (Class)downloaderClass
{
  if (downloaderClass != nil && ![downloaderClass isSubclassOfClass: [GSFontAssetDownloader class]])
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Downloader class must be a subclass of GSFontAssetDownloader"];
      return;
    }
  _defaultDownloaderClass = downloaderClass;
}

+ (Class) defaultDownloaderClass
{
  return _defaultDownloaderClass ? _defaultDownloaderClass : [GSFontAssetDownloader class];
}

+ (instancetype) downloaderWithOptions: (NSUInteger)options
{
  Class downloaderClass = [self defaultDownloaderClass];
  return [[downloaderClass alloc] initWithOptions: options];
}

- (BOOL) downloadAndInstallFontWithDescriptor: (NSFontDescriptor *)descriptor
					error: (NSError **)error
{
  // Delegate to the format-specific method with default format
  return [self downloadAndInstallFontWithDescriptor: descriptor
                                     preferredFormat: nil
                                               error: error];
}

- (BOOL) downloadAndInstallFontWithDescriptor: (NSFontDescriptor *)descriptor
                               preferredFormat: (NSString *)format
                                        error: (NSError **)error
{
  if (descriptor == nil)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font descriptor is nil"
							   forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				      code: -1001
				  userInfo: userInfo];
	}
      return NO;
    }

  NSError *localError = nil;
  NSString *downloadedPath = nil;
  BOOL success = NO;

  // Show progress panel if standard UI is requested
  NSString *fontName = [descriptor objectForKey: NSFontNameAttribute];
  if (fontName == nil)
    {
      fontName = [descriptor objectForKey: NSFontFamilyAttribute];
    }
  if (fontName == nil)
    {
      fontName = @"Font";
    }

  NSString *progressMessage = [NSString stringWithFormat: @"Downloading %@...", fontName];
  [self showProgressPanelWithMessage: progressMessage];
  [self updateProgressPanel: 0.1 withMessage: progressMessage];

  NS_DURING
    {
      // Get font URL from descriptor
      [self updateProgressPanel: 0.2 withMessage: @"Resolving font URL..."];
      NSURL *fontURL = [self fontURLForDescriptor: descriptor];
      if (fontURL == nil)
	{
	  if (error != NULL)
	    {
	      NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"No font URL available for descriptor"
							       forKey: NSLocalizedDescriptionKey];
	      *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
					  code: -1002
				      userInfo: userInfo];
	    }
	  return NO;
	}

      // Download the font file
      [self updateProgressPanel: 0.3 withMessage: @"Starting download..."];
      // Check if this is a CSS URL (like Google Fonts API) and handle appropriately
      NSString *urlString = [fontURL absoluteString];
      if ([urlString containsString: @"fonts.googleapis.com/css"] ||
          [urlString containsString: @"fonts.google.com/css"] ||
          [urlString containsString: @"fonts.gstatic.com/css"] ||
          [urlString hasSuffix: @".css"] ||
          [[fontURL pathExtension] isEqualToString: @"css"])
        {
          // This is a CSS URL containing @font-face declarations
          // Use the specified format, or default to truetype/ttf if none specified
          NSString *preferredFormat = format ? format : @"truetype";
          [self updateProgressPanel: 0.4 withMessage: @"Downloading CSS and extracting font URLs..."];
          downloadedPath = [self downloadFontDataFromCSSURL: fontURL withFormat: preferredFormat error: &localError];
        }
      else
        {
          // This is a direct font file URL
          [self updateProgressPanel: 0.4 withMessage: @"Downloading font file..."];
          downloadedPath = [self downloadFontFromURL: fontURL error: &localError];
        }

      if (downloadedPath == nil)
	{
	  [self hideProgressPanel];
	  if (error != NULL)
	    {
	      *error = localError;
	    }
	  return NO;
	}

      // Validate the downloaded font file
      [self updateProgressPanel: 0.7 withMessage: @"Validating font file..."];
      if (![self validateFontFile: downloadedPath error: &localError])
	{
	  [self hideProgressPanel];
	  if (error != NULL)
	    {
	      *error = localError;
	    }
	  return NO;
	}

      // Install the font
      [self updateProgressPanel: 0.8 withMessage: @"Installing font..."];
      success = [self installFontAtPath: downloadedPath error: &localError];
      if (success)
        {
          [self updateProgressPanel: 1.0 withMessage: @"Font installed successfully!"];
          // Brief delay to show completion
          [NSThread sleepForTimeInterval: 0.5];
        }
      else if (error != NULL)
	{
	  *error = localError;
	}
    }
  NS_HANDLER
    {
      [self hideProgressPanel];
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				    @"Font download and installation failed", NSLocalizedDescriptionKey,
				    [localException reason], NSLocalizedFailureReasonErrorKey,
				    nil];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				      code: -1003
				  userInfo: userInfo];
	}
      success = NO;
    }
  NS_ENDHANDLER

  // Clean up temporary download file
  if (downloadedPath != nil)
    {
      [[NSFileManager defaultManager] removeItemAtPath: downloadedPath error: nil];
    }

  // Hide progress panel
  [self hideProgressPanel];

  return success;
}

- (NSURL *) fontURLForDescriptor: (NSFontDescriptor *)descriptor
{
  // Check if descriptor has a URL attribute (custom extension)
  NSURL *fontURL = [descriptor objectForKey: @"NSFontURLAttribute"];
  if (fontURL != nil)
    {
      return fontURL;
    }

  // Try to construct URL from font name for common font sources
  NSString *fontName = [descriptor objectForKey: NSFontNameAttribute];
  NSString *familyName = [descriptor objectForKey: NSFontFamilyAttribute];

  if (fontName == nil && familyName == nil)
    {
      return nil;
    }

  NSString *searchName = fontName ? fontName : familyName;
  NSString *encodedName = [searchName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

  // Example: Try Google Fonts API (this is simplified - real implementation would use proper API)
  NSString *urlString = [NSString stringWithFormat: @"https://fonts.googleapis.com/css2?family=%@", encodedName];

  return [NSURL URLWithString: urlString];
}

- (NSArray *) extractFontURLsFromCSS: (NSString *)cssContent
			  withFormat: (NSString *)format
			       error: (NSError **)error
{
  if (cssContent == nil || [cssContent length] == 0)
    {
      if (error != NULL)
        {
          NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"CSS content is nil or empty"
                                                               forKey: NSLocalizedDescriptionKey];
          *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
                                       code: -2100
                                   userInfo: userInfo];
        }
      return nil;
    }

  NSMutableArray *fontURLs = [NSMutableArray array];

  // Regular expression to match src: url(...) format('...') patterns
  NSString *pattern = @"src:\\s*url\\(([^)]+)\\)\\s*format\\(['\"]([^'\"]+)['\"]\\)";
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                         options: NSRegularExpressionCaseInsensitive
                                                                           error: error];
  if (regex == nil)
    {
      return nil;
    }

  NSArray *matches = [regex matchesInString: cssContent
                                    options: 0
                                      range: NSMakeRange(0, [cssContent length])];
  NSEnumerator *men = [matches objectEnumerator];
  NSTextCheckingResult *match = nil;

  while ((match = [men nextObject]) != nil)
    {
      if ([match numberOfRanges] >= 3)
        {
          NSRange urlRange = [match rangeAtIndex: 1];
          NSRange formatRange = [match rangeAtIndex: 2];

          NSString *urlString = [cssContent substringWithRange: urlRange];
          NSString *formatString = [cssContent substringWithRange: formatRange];

          // Clean up URL string (remove quotes if present)
          urlString = [urlString stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\"' "]];

          // Check if format matches what we're looking for
          if (format == nil || [formatString isEqualToString: format])
            {
              NSURL *url = [NSURL URLWithString: urlString];
              if (url != nil)
                {
                  [fontURLs addObject: url];
                }
            }
        }
    }

  return [fontURLs copy];
}

- (NSString *) downloadFontDataFromCSSURL: (NSURL *)cssURL
                               withFormat: (NSString *)format
                                    error: (NSError **)error
{
  if (cssURL == nil)
    {
      if (error != NULL)
        {
          NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"CSS URL is nil"
                                                               forKey: NSLocalizedDescriptionKey];
          *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
                                       code: -2101
                                   userInfo: userInfo];
        }
      return nil;
    }

  // First, download the CSS content
  NSString *cssContent = nil;
  NSError *cssError = nil;

  [self updateProgressPanel: 0.45 withMessage: @"Downloading CSS file..."];

  NS_DURING
    {
      NSData *cssData = [NSData dataWithContentsOfURL: cssURL];
      if (cssData != nil)
        {
          cssContent = [[NSString alloc] initWithData: cssData encoding: NSUTF8StringEncoding];
        }
    }
  NS_HANDLER
    {
      if (error != NULL)
        {
          NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"Failed to download CSS from URL", NSLocalizedDescriptionKey,
                                                 [localException reason], NSLocalizedFailureReasonErrorKey,
                                                 nil];
          *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
                                       code: -2102
                                   userInfo: userInfo];
        }
      return nil;
    }
  NS_ENDHANDLER

  if (cssContent == nil)
    {
      if (error != NULL)
        {
          NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Failed to parse CSS content"
                                                               forKey: NSLocalizedDescriptionKey];
          *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
                                       code: -2103
                                   userInfo: userInfo];
        }
      return nil;
    }

  // Extract font URLs from CSS
  [self updateProgressPanel: 0.5 withMessage: @"Parsing CSS and extracting font URLs..."];
  NSArray *fontURLs = [self extractFontURLsFromCSS: cssContent
                                         withFormat: format
                                              error: &cssError];
  if (fontURLs == nil || [fontURLs count] == 0)
    {
      if (error != NULL)
        {
          *error = cssError ?: [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
                                                   code: -2104
                                               userInfo: [NSDictionary dictionaryWithObject: @"No font URLs found in CSS"
                                                                                     forKey: NSLocalizedDescriptionKey]];
        }
      return nil;
    }

  // Download the first matching font URL (you could modify this to download all or let user choose)
  [self updateProgressPanel: 0.6 withMessage: @"Downloading font file from extracted URL..."];
  NSURL *fontURL = [fontURLs firstObject];
  return [self downloadFontFromURL: fontURL error: error];
}

- (NSString *) downloadFontFromURL: (NSURL *)fontURL
			     error: (NSError **)error
{
  if (fontURL == nil)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font URL is nil"
							   forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				      code: -2001
				  userInfo: userInfo];
	}
      return nil;
    }

  // Create temporary file for download
  NSString *tempDir = NSTemporaryDirectory();
  NSString *filename = [fontURL lastPathComponent];

  // Determine appropriate file extension based on URL or default to ttf
  if ([filename length] == 0 || [[filename pathExtension] length] == 0)
    {
      // Try to determine extension from URL path
      NSString *urlPath = [fontURL path];
      if ([urlPath containsString: @".woff2"])
        {
          filename = [NSString stringWithFormat: @"font_%d.woff2", (int)[NSDate timeIntervalSinceReferenceDate]];
        }
      else if ([urlPath containsString: @".woff"])
        {
          filename = [NSString stringWithFormat: @"font_%d.woff", (int)[NSDate timeIntervalSinceReferenceDate]];
        }
      else if ([urlPath containsString: @".otf"])
        {
          filename = [NSString stringWithFormat: @"font_%d.otf", (int)[NSDate timeIntervalSinceReferenceDate]];
        }
      else
        {
          filename = [NSString stringWithFormat: @"font_%d.ttf", (int)[NSDate timeIntervalSinceReferenceDate]];
        }
    }
  NSString *tempPath = [tempDir stringByAppendingPathComponent: filename];

  // Download the font file
  NSData *fontData = nil;

  NS_DURING
    {
      // For HTTPS URLs, try to download
      if ([[fontURL scheme] isEqualToString: @"https"] || [[fontURL scheme] isEqualToString: @"http"])
	{
	  fontData = [NSData dataWithContentsOfURL: fontURL];
	}
      // For file URLs, copy the file
      else if ([[fontURL scheme] isEqualToString: @"file"])
	{
	  fontData = [NSData dataWithContentsOfURL: fontURL];
	}
    }
  NS_HANDLER
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"Failed to download font from URL", NSLocalizedDescriptionKey,
						 [localException reason], NSLocalizedFailureReasonErrorKey,
						 nil];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -2002
				   userInfo: userInfo];
	}
      return nil;
    }
  NS_ENDHANDLER

    if (fontData == nil || [fontData length] == 0)
      {
	if (error != NULL)
	  {
	    NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"No data received from font URL"
								 forKey: NSLocalizedDescriptionKey];
	    *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
					 code: -2003
				     userInfo: userInfo];
	  }
	return nil;
      }

  // Write font data to temporary file
  if (![fontData writeToFile: tempPath atomically: YES])
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Failed to write font data to temporary file"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -2004
				   userInfo: userInfo];
	}
      return nil;
    }

  return tempPath;
}

- (BOOL) validateFontFile: (NSString *)fontPath
		    error: (NSError **)error
{
  if (fontPath == nil)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font path is nil"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -3001
				   userInfo: userInfo];
	}
      return NO;
    }

  // Check if file exists
  if (![[NSFileManager defaultManager] fileExistsAtPath: fontPath])
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font file does not exist"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -3002
				   userInfo: userInfo];
	}
      return NO;
    }

  // Basic validation - check file size and magic bytes
  NSData *fontData = [NSData dataWithContentsOfFile: fontPath];
  if (fontData == nil || [fontData length] < 12)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font file is too small or unreadable"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -3003
				   userInfo: userInfo];
	}
      return NO;
    }

  // Check for common font file signatures (TTF, OTF, WOFF, WOFF2)
  const unsigned char *bytes = [fontData bytes];

  // TTF signature: 0x00, 0x01, 0x00, 0x00 or 'true'
  // OTF signature: 'OTTO'
  // WOFF signature: 'wOFF'
  // WOFF2 signature: 'wOF2'
  if ((bytes[0] == 0x00 && bytes[1] == 0x01 && bytes[2] == 0x00 && bytes[3] == 0x00) ||
      (bytes[0] == 't' && bytes[1] == 'r' && bytes[2] == 'u' && bytes[3] == 'e') ||
      (bytes[0] == 'O' && bytes[1] == 'T' && bytes[2] == 'T' && bytes[3] == 'O') ||
      (bytes[0] == 'w' && bytes[1] == 'O' && bytes[2] == 'F' && bytes[3] == 'F') ||
      (bytes[0] == 'w' && bytes[1] == 'O' && bytes[2] == 'F' && bytes[3] == '2'))
    {
      return YES;
    }

  if (error != NULL)
    {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font file does not have a valid font signature"
							   forKey: NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				   code: -3004
			       userInfo: userInfo];
    }
  return NO;
}

- (BOOL) installFontAtPath: (NSString *)fontPath
		     error: (NSError **)error
{
  if (fontPath == nil)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Font path is nil"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -4001
				   userInfo: userInfo];
	}
      return NO;
    }

  NSString *filename = [fontPath lastPathComponent];
  NSString *destinationDir;

  // Determine installation directory based on options
  if (_options & NSFontAssetRequestOptionUsesStandardUI)
    {
      // Install to user fonts directory for user-level installation
      destinationDir = [self userFontsDirectory];
    }
  else
    {
      // Try system fonts directory, fall back to user directory
      destinationDir = [self systemFontsDirectory];
      if (destinationDir == nil)
	{
	  destinationDir = [self userFontsDirectory];
	}
    }

  if (destinationDir == nil)
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Cannot determine font installation directory"
							       forKey: NSLocalizedDescriptionKey];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -4002
				   userInfo: userInfo];
	}
      return NO;
    }

  // Create destination directory if needed
  NSError *dirError = nil;
  if (![[NSFileManager defaultManager] createDirectoryAtPath: destinationDir
				 withIntermediateDirectories: YES
						  attributes: nil
						       error: &dirError])
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"Failed to create font installation directory", NSLocalizedDescriptionKey,
						 [dirError localizedDescription], NSLocalizedFailureReasonErrorKey,
						 nil];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -4003
				   userInfo: userInfo];
	}
      return NO;
    }

  // Copy font to destination
  NSString *destinationPath = [destinationDir stringByAppendingPathComponent: filename];
  NSError *copyError = nil;

  // Remove existing font file if present
  if ([[NSFileManager defaultManager] fileExistsAtPath: destinationPath])
    {
      [[NSFileManager defaultManager] removeItemAtPath: destinationPath error: nil];
    }

  if (![[NSFileManager defaultManager] copyItemAtPath: fontPath
					       toPath: destinationPath
						error: &copyError])
    {
      if (error != NULL)
	{
	  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"Failed to copy font to installation directory", NSLocalizedDescriptionKey,
						 [copyError localizedDescription], NSLocalizedFailureReasonErrorKey,
						 nil];
	  *error = [NSError errorWithDomain: @"GSFontAssetDownloaderErrorDomain"
				       code: -4004
				   userInfo: userInfo];
	}
      return NO;
    }

  // Notify system of new font (platform-specific)
#ifdef __APPLE__
  // On macOS, fonts are automatically detected when placed in font directories
  NSLog(@"Font installed to: %@", destinationPath);
#elif defined(__linux__)
  // On Linux, run fc-cache to update font cache
  system("fc-cache -f");
  NSLog(@"Font installed and cache updated: %@", destinationPath);
#else
  NSLog(@"Font installed to: %@", destinationPath);
#endif

  return YES;
}

- (NSString *) systemFontsDirectory
{
#ifdef __APPLE__
  return @"/Library/Fonts";
#elif defined(__linux__)
  return @"/usr/local/share/fonts";
#else
  return nil; // Platform not supported for system font installation
#endif
}

- (NSString *) userFontsDirectory
{
  NSString *homeDir = NSHomeDirectory();

#ifdef __APPLE__
  return [homeDir stringByAppendingPathComponent: @"Library/Fonts"];
#elif defined(__linux__)
  return [homeDir stringByAppendingPathComponent: @".fonts"];
#else
  // Generic Unix/other systems
  return [homeDir stringByAppendingPathComponent: @".fonts"];
#endif
}

- (NSUInteger) options
{
  return _options;
}

- (void) showProgressPanelWithMessage: (NSString *)message
{
  if (!(_options & NSFontAssetRequestOptionUsesStandardUI))
    {
      return; // Don't show UI if not requested
    }

  if (_progressPanel != nil)
    {
      [self hideProgressPanel]; // Hide existing panel if any
    }

  // Create the progress panel
  NSRect panelFrame = NSMakeRect(0, 0, 400, 120);
  _progressPanel = [[NSPanel alloc] initWithContentRect: panelFrame
                                              styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                backing: NSBackingStoreBuffered
                                                  defer: NO];
  [_progressPanel setTitle: @"Font Download"];
  [_progressPanel setLevel: NSModalPanelWindowLevel];
  [_progressPanel setReleasedWhenClosed: NO];

  // Create and configure the status label
  NSRect labelFrame = NSMakeRect(20, 70, 360, 20);
  _statusLabel = [[NSTextField alloc] initWithFrame: labelFrame];
  [_statusLabel setStringValue: message ? message : @"Downloading font..."];
  [_statusLabel setBezeled: NO];
  [_statusLabel setDrawsBackground: NO];
  [_statusLabel setEditable: NO];
  [_statusLabel setSelectable: NO];
  [[_progressPanel contentView] addSubview: _statusLabel];

  // Create and configure the progress indicator
  NSRect progressFrame = NSMakeRect(20, 40, 360, 20);
  _progressIndicator = [[NSProgressIndicator alloc] initWithFrame: progressFrame];
  [_progressIndicator setStyle: NSProgressIndicatorStyleBar];
  [_progressIndicator setIndeterminate: NO];
  [_progressIndicator setMinValue: 0.0];
  [_progressIndicator setMaxValue: 1.0];
  [_progressIndicator setDoubleValue: 0.0];
  [[_progressPanel contentView] addSubview: _progressIndicator];

  // Create and configure the cancel button
  NSRect buttonFrame = NSMakeRect(310, 10, 80, 25);
  _cancelButton = [[NSButton alloc] initWithFrame: buttonFrame];
  [_cancelButton setTitle: @"Cancel"];
  [_cancelButton setTarget: self];
  [_cancelButton setAction: @selector(cancelDownload:)];
  [[_progressPanel contentView] addSubview: _cancelButton];

  // Center and show the panel
  [_progressPanel center];
  [_progressPanel makeKeyAndOrderFront: nil];
}

- (void) updateProgressPanel: (double)progress withMessage: (NSString *)message
{
  if (_progressPanel == nil || !(_options & NSFontAssetRequestOptionUsesStandardUI))
    {
      return;
    }

  if (_progressIndicator != nil)
    {
      [_progressIndicator setDoubleValue: progress];
    }

  if (_statusLabel != nil && message != nil)
    {
      [_statusLabel setStringValue: message];
    }

  // Process events to update the UI
  NSEvent *event;
  while ((event = [NSApp nextEventMatchingMask: NSEventMaskAny
                                     untilDate: [NSDate distantPast]
                                        inMode: NSDefaultRunLoopMode
                                       dequeue: YES]))
    {
      [NSApp sendEvent: event];
    }
}

- (void) hideProgressPanel
{
  if (_progressPanel != nil)
    {
      [_progressPanel orderOut: nil];
      DESTROY(_progressPanel);
    }

  if (_statusLabel != nil)
    {
      DESTROY(_statusLabel);
    }

  if (_progressIndicator != nil)
    {
      DESTROY(_progressIndicator);
    }

  if (_cancelButton != nil)
    {
      DESTROY(_cancelButton);
    }
}

- (void) cancelDownload: (id)sender
{
  // For now, just hide the panel
  // In a full implementation, this would cancel the actual download operation
  [self hideProgressPanel];

  // Post a notification that download was cancelled
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"GSFontAssetDownloadCancelled"
                  object: self];
}

+ (void) demonstrateProgressPanel
{
  // Create a downloader with standard UI enabled
  GSFontAssetDownloader *downloader = [GSFontAssetDownloader downloaderWithOptions: NSFontAssetRequestOptionUsesStandardUI];

  // Show the progress panel
  [downloader showProgressPanelWithMessage: @"Demonstrating progress panel..."];

  // Simulate progress updates
  for (int i = 1; i <= 10; i++)
    {
      double progress = i / 10.0;
      NSString *message = [NSString stringWithFormat: @"Step %d of 10...", i];
      [downloader updateProgressPanel: progress withMessage: message];
      [NSThread sleepForTimeInterval: 0.5]; // Simulate work
    }

  // Hide the panel
  [downloader hideProgressPanel];
  RELEASE(downloader);
}

@end
