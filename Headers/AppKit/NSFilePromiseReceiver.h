/*
   NSFilePromiseReceiver.h

   Receiver for file promises in drag and drop operations

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2025

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSFilePromiseReceiver
#define _GNUstep_H_NSFilePromiseReceiver

#import <Foundation/NSObject.h>

#import <AppKit/AppKitDefines.h>
#import <AppKit/NSPasteboard.h>

@class NSString;
@class NSURL;
@class NSArray;
@class NSOperationQueue;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

APPKIT_EXPORT_CLASS
@interface NSFilePromiseReceiver : NSObject <NSPasteboardReading>
{
  NSArray *_fileTypes;
  NSArray *_fileNames;
}

/** Returns the file types (UTIs) that this receiver can accept.
 * These are the Uniform Type Identifiers for file types that
 * this receiver is willing to accept from file promise providers.
 */
#if GS_HAS_DECLARED_PROPERTIES
@property (readonly, copy) NSArray *fileTypes;
@property (readonly, copy) NSArray *fileNames;
#else
- (NSArray *)fileTypes;

/** Returns the file names that will be created for the promised files.
 * This array corresponds to the fileTypes array and provides the
 * actual filenames that will be used when the promises are fulfilled.
 */
- (NSArray *)fileNames;
#endif

/** Receives the promised files to the specified destination URL.
 * This method initiates the process of fulfilling all file promises
 * represented by this receiver. The files will be created in the
 * specified destination directory.
 */
- (void)receivePromisedFilesAtDestination:(NSURL *)destinationDir
                                  options:(NSDictionary *)options
                        operationQueue:(NSOperationQueue *)operationQueue
                                reader:(void (^)(NSURL *fileURL, NSError *error))reader;

@end

#endif

#endif // _GNUstep_H_NSFilePromiseReceiver
