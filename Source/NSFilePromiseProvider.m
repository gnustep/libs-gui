/*
   NSFilePromiseProvider.m

   Provider for file promises in drag and drop operations

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

#import <AppKit/NSFilePromiseProvider.h>

#import "Foundation/NSString.h"
#import "Foundation/NSArray.h"
#import "Foundation/NSURL.h"
#import "Foundation/NSOperation.h"
#import "Foundation/NSError.h"
#import "Foundation/NSDictionary.h"

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

// UTI for file promise items
NSString * const NSFilePromiseProviderUTI = @"com.apple.NSFilePromiseProvider";

@implementation NSFilePromiseProvider

- (instancetype)initWithFileType:(NSString *)fileType
                        delegate:(id<NSFilePromiseProviderDelegate>)delegate
{
  self = [super init];
  if (self)
    {
      _fileType = [fileType copy];
      _delegate = delegate;
    }
  return self;
}

- (void)dealloc
{
  RELEASE(_fileType);
  RELEASE(_userInfo);

  [super dealloc];
}

- (NSString *)fileType
{
  return _fileType;
}

- (id<NSFilePromiseProviderDelegate>)delegate
{
  return _delegate;
}

- (void)setDelegate:(id<NSFilePromiseProviderDelegate>)delegate
{
  _delegate = delegate;
}

- (id)userInfo
{
  return _userInfo;
}

- (void)setUserInfo:(id)userInfo
{
  ASSIGN(_userInfo, userInfo);
}

#pragma mark - NSPasteboardWriting

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [NSArray arrayWithObject: NSFilePromiseProviderUTI];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqualToString: NSFilePromiseProviderUTI])
    {
      // Return a dictionary with file type information
      return [NSDictionary dictionaryWithObjectsAndKeys:
                _fileType, @"fileType",
                nil];
    }
  return nil;
}

- (NSPasteboardWritingOptions)writingOptionsForType: (NSString *)type
                                         pasteboard: (NSPasteboard *)pasteboard
{
  return 0;
}

@end

#endif
