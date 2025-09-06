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

  NS_DURING
    {
      // Get font URL from descriptor
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
      downloadedPath = [self downloadFontFromURL: fontURL error: &localError];
      if (downloadedPath == nil)
	{
	  if (error != NULL)
	    {
	      *error = localError;
	    }
	  return NO;
	}

      // Validate the downloaded font file
      if (![self validateFontFile: downloadedPath error: &localError])
	{
	  if (error != NULL)
	    {
	      *error = localError;
	    }
	  return NO;
	}

      // Install the font
      success = [self installFontAtPath: downloadedPath error: &localError];
      if (!success && error != NULL)
	{
	  *error = localError;
	}
    }
  NS_HANDLER
    {
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

  // For demo purposes, construct URLs to Google Fonts or system font repositories
  // In a real implementation, this would use actual font service APIs
  NSString *searchName = fontName ? fontName : familyName;
  NSString *encodedName = [searchName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

  // Example: Try Google Fonts API (this is simplified - real implementation would use proper API)
  NSString *urlString = [NSString stringWithFormat: @"https://fonts.googleapis.com/css2?family=%@", encodedName];

  return [NSURL URLWithString: urlString];
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
  NSString *filename = [[fontURL lastPathComponent] stringByAppendingPathExtension: @"ttf"];
  if ([filename length] == 0 || [filename isEqualToString: @".ttf"])
    {
      filename = [NSString stringWithFormat: @"font_%d.ttf", (int)[NSDate timeIntervalSinceReferenceDate]];
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

  // Check for common font file signatures (TTF, OTF, WOFF)
  const unsigned char *bytes = [fontData bytes];

  // TTF signature: 0x00, 0x01, 0x00, 0x00 or 'true'
  // OTF signature: 'OTTO'
  // WOFF signature: 'wOFF'
  if ((bytes[0] == 0x00 && bytes[1] == 0x01 && bytes[2] == 0x00 && bytes[3] == 0x00) ||
      (bytes[0] == 't' && bytes[1] == 'r' && bytes[2] == 'u' && bytes[3] == 'e') ||
      (bytes[0] == 'O' && bytes[1] == 'T' && bytes[2] == 'T' && bytes[3] == 'O') ||
      (bytes[0] == 'w' && bytes[1] == 'O' && bytes[2] == 'F' && bytes[3] == 'F'))
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

@end
