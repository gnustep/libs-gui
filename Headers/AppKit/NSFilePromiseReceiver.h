/* Interface of class NSFilePromiseReceiver
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

#ifndef _NSFilePromiseReceiver_h_GNUSTEP_GUI_INCLUDE
#define _NSFilePromiseReceiver_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>

#import "AppKit/AppKitDefines.h"
#import "AppKit/NSPasteboard.h"

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSArray;
@class NSError;
@class NSOperationQueue;
@class NSURL;

DEFINE_BLOCK_TYPE(GSFilePromiseReceiverReaderHandler, void, NSURL*, NSError*);

APPKIT_EXPORT_CLASS
@interface NSFilePromiseReceiver <NSPasteboardReading> : NSObject
{
  NSArray *_fileNames;
  NSArray *_fileTypes;
  NSArray *_readableDraggedTypes;
}

- (NSArray *) fileNames;
- (void) setFileNames: (NSArray *)fileNames;

- (NSArray *) fileTypes;
- (void) setFileTypes: (NSArray *)fileTypes;

- (NSArray *) readableDraggedTypes;

- (void) receivePromisedFilesAtDestination: (NSURL *)destinationDir
				   options: (NSDictionary *)options
			    operationQueue: (NSOperationQueue *)operationQueue
				    reader: (GSFilePromiseReceiverReaderHandler)reader;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSFilePromiseReceiver_h_GNUSTEP_GUI_INCLUDE */
