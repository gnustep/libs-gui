/* Implementation of class NSFilePromiseProvider
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

#import <Foundation/NSError.h>
#import <Foundation/NSString.h>

#import "AppKit/NSFilePromiseProvider.h"

@implementation NSFilePromiseProvider

- (instancetype) initWithFileType: (NSString *)fileType delegate: (id<NSFilePromiseProviderDelegate>)delegate
{
  self = [super init];

  if (self != nil)
    {
      ASSIGN(_fileType, fileType);
      _delegate = delegate;
    }
  
  return self;
}

- (id<NSFilePromiseProviderDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSFilePromiseProviderDelegate>)delegate
{
  _delegate = delegate; // retained by caller...
}

- (NSString *) fileType
{
  return _fileType;
}

- (void) setFileType: (NSString *)fileType
{
  ASSIGN(_fileType, fileType);
}

- (id) userInfo
{
  return _userInfo;
}

- (void) setUserInfo: (id)userInfo
{
  ASSIGN(_userInfo, userInfo);
}

@end

