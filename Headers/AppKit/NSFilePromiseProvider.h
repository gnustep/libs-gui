/* Interface of class NSFilePromiseProvider
   Copyright (C) 2024 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 05-05-2024

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

#ifndef _NSFilePromiseProvider_h_GNUSTEP_GUI_INCLUDE
#define _NSFilePromiseProvider_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSError;
@class NSFilePromiseProvider;  
@class NSOperationQueue;
@class NSString;
@class NSURL;

DEFINE_BLOCK_TYPE_NO_ARGS(GSFilePromiseProviderCompletionHandler, NSError*);

@protocol NSFilePromiseProviderDelegate
- (NSString *) filePromiseProvider: (NSFilePromiseProvider *)filePromiseProvider filenameForType: (NSString *)fileType;

- (void)filePromiseProvider: (NSFilePromiseProvider *)filePromiseProvider 
          writePromiseToURL: (NSURL *)url 
          completionHandler: (GSFilePromiseProviderCompletionHandler)completionHandler;

- (NSOperationQueue *)operationQueueForFilePromiseProvider: (NSFilePromiseProvider *)filePromiseProvider;
@end
  
APPKIT_EXPORT_CLASS
@interface NSFilePromiseProvider : NSObject
{
  NSString *_fileType;
  id<NSFilePromiseProviderDelegate> _delegate;
  id _userInfo;
}

- (instancetype) initWithFileType: (NSString *)fileType delegate: (id<NSFilePromiseProviderDelegate>)delegate;

- (id<NSFilePromiseProviderDelegate>) delegate;
- (void) setDelegate: (id<NSFilePromiseProviderDelegate>) delegate;

- (NSString *) fileType;
- (void) setFileType: (NSString *)fileType;

- (id) userInfo;
- (void) setUserInfo: (id)userInfo;
  
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSFilePromiseProvider_h_GNUSTEP_GUI_INCLUDE */

