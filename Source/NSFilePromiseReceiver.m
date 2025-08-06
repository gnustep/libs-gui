/*
   NSFilePromiseReceiver.m

   Receiver for file promises in drag and drop operations

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

#import <AppKit/NSFilePromiseReceiver.h>
#import <AppKit/NSFilePromiseProvider.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSOperationQueue.h>
#import <Foundation/NSError.h>
#import <Foundation/NSDictionary.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

@implementation NSFilePromiseReceiver

- (void)dealloc
{
  RELEASE(_fileTypes);
  RELEASE(_fileNames);
  [super dealloc];
}

- (NSArray *)fileTypes
{
  return _fileTypes;
}

- (NSArray *)fileNames
{
  return _fileNames;
}

- (void)receivePromisedFilesAtDestination:(NSURL *)destinationDir
                                  options:(NSDictionary *)options
                        operationQueue:(NSOperationQueue *)operationQueue
                                reader:(void (^)(NSURL *fileURL, NSError * _Nullable error))reader
{
  // This is a placeholder implementation
  // In a full implementation, this would coordinate with the drag and drop system
  // to receive the actual file data from NSFilePromiseProvider instances

  if (reader)
    {
      NSError *error = [NSError errorWithDomain:@"NSFilePromiseReceiverDomain"
                                           code:1
                                       userInfo:@{NSLocalizedDescriptionKey: @"File promise receiving not fully implemented"}];
      reader(nil, error);
    }
}

#pragma mark - NSPasteboardReading

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  extern NSString * const NSFilePromiseProviderUTI;
  return [NSArray arrayWithObject:NSFilePromiseProviderUTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type
                                         pasteboard:(NSPasteboard *)pasteboard
{
  return NSPasteboardReadingAsPropertyList;
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList
                                        ofType:(NSString *)type
{
  self = [super init];
  if (self)
    {
      extern NSString * const NSFilePromiseProviderUTI;
      if ([type isEqualToString:NSFilePromiseProviderUTI] && [propertyList isKindOfClass:[NSDictionary class]])
        {
          NSDictionary *dict = (NSDictionary *)propertyList;
          NSString *fileType = [dict objectForKey:@"fileType"];
          if (fileType)
            {
              _fileTypes = [[NSArray arrayWithObject:fileType] retain];
              // For now, generate a generic filename
              // In a full implementation, this would come from the provider's delegate
              NSString *fileName = [NSString stringWithFormat:@"promised_file.%@", fileType];
              _fileNames = [[NSArray arrayWithObject:fileName] retain];
            }
        }
    }
  return self;
}

@end

#endif
