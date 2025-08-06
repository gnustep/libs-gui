/*
   NSFilePromiseProvider.h

   Provider for file promises in drag and drop operations

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: GitHub Copilot <copilot@github.com>
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

#ifndef _GNUstep_H_NSFilePromiseProvider
#define _GNUstep_H_NSFilePromiseProvider
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <AppKit/NSPasteboard.h>

@class NSString;
@class NSURL;
@class NSOperationQueue;
@class NSArray;

@protocol NSFilePromiseProviderDelegate;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

// UTI for file promise pasteboard type
APPKIT_EXPORT NSString * const NSFilePromiseProviderUTI;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

APPKIT_EXPORT_CLASS
@interface NSFilePromiseProvider : NSObject <NSPasteboardWriting>
{
  NSString *_fileType;
  id<NSFilePromiseProviderDelegate> _delegate;
  id _userInfo;
}

/** Initializes a file promise provider with the specified file type.
 * The file type should be a UTI (Uniform Type Identifier) that describes
 * the type of file that will be provided when the promise is fulfilled.
 */
- (instancetype)initWithFileType:(NSString *)fileType
                        delegate:(id<NSFilePromiseProviderDelegate>)delegate;

#if GS_HAS_DECLARED_PROPERTIES
@property (readonly, copy) NSString *fileType;
@property (weak) id<NSFilePromiseProviderDelegate> delegate;
@property (strong) id userInfo;
#else
/** Returns the file type (UTI) that this provider will create.
 * This is the Uniform Type Identifier for the type of file
 * that will be created when the promise is fulfilled.
 */
- (NSString *)fileType;

/** Returns the delegate responsible for fulfilling file promises.
 * The delegate provides the actual file data when a drop occurs.
 */
- (id<NSFilePromiseProviderDelegate>)delegate;

/** Sets the delegate responsible for fulfilling file promises.
 * The delegate must implement the required methods to provide
 * file data when the promise needs to be fulfilled.
 */
- (void)setDelegate:(id<NSFilePromiseProviderDelegate>)delegate;

/** Returns arbitrary user data associated with this provider.
 * Applications can use this to store context information
 * needed to fulfill the file promise.
 */
- (id)userInfo;

/** Sets arbitrary user data associated with this provider.
 * Applications can store context information here that will
 * be needed when fulfilling the file promise.
 */
- (void)setUserInfo:(id)userInfo;
#endif

@end

@protocol NSFilePromiseProviderDelegate <NSObject>

@required

/** Returns the name for the file that will be created.
 * This method is called when the system needs to know what
 * filename to use for the promised file.
 */
- (NSString *)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider
                  fileNameForType:(NSString *)fileType;

/** Writes the promised file to the specified URL.
 * This method is called when the drop occurs and the actual
 * file needs to be created. The implementation should write
 * the file data to the provided URL.
 */
- (void)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider
          writePromiseToURL:(NSURL *)url
          completionHandler:(void (^)(NSError * _Nullable error))completionHandler;

@optional

/** Returns the operation queue for file writing operations.
 * If not implemented, file writing will occur on a default queue.
 * Implement this to control which queue is used for file operations.
 */
- (NSOperationQueue *)operationQueueForFilePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider;

@end

#endif

#endif // _GNUstep_H_NSFilePromiseProvider
