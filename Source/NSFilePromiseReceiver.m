/* Implementation of class NSFilePromiseReceiver
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

#import "AppKit/NSFilePromiseReceiver.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSOperation.h>

#import "GSFastEnumeration.h"

@implementation NSFilePromiseReceiver

// NSPasteboardReading protocol -- start

- (id)initWithPasteboardPropertyList: (id)propertyList ofType: (NSString *)type
{
  self = [super init];

  if (self != nil)
    {
    }

  return self;
}

+ (NSArray *) readableTypesForPasteboard: (NSPasteboard *)pasteboard
{
  return nil;
}

// NSPasteboardReading protocol -- end

- (void) dealloc
{
  RELEASE(_fileNames);
  RELEASE(_fileTypes);
  RELEASE(_readableDraggedTypes);
  [super dealloc];
}

- (NSArray *) fileNames
{
  return _fileNames;
}

- (void) setFileNames: (NSArray *)fileNames
{
  ASSIGN(_fileNames, fileNames);
}

- (NSArray *) fileTypes
{
  return _fileTypes;
}

- (void) setFileTypes: (NSArray *)fileTypes
{
  ASSIGN(_fileTypes, fileTypes);
}

- (NSArray *) readableDraggedTypes
{
  return _readableDraggedTypes;
}

- (void) receivePromisedFilesAtDestination: (NSURL *)destinationDir
				   options: (NSDictionary *)options
			    operationQueue: (NSOperationQueue *)operationQueue
				    reader: (GSFilePromiseReceiverReaderHandler)reader
{
}

@end
