/*
   IMCustomObject.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: November 1997
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <Foundation/NSObjCRuntime.h>
#include <AppKit/GMArchiver.h>
#include "AppKit/IMCustomObject.h"

@implementation NSObject(ModelUnarchiving)

- (id)nibInstantiate
{
  return self;
}

@end


@implementation IMCustomObject

extern id _nibOwner;
extern BOOL _fileOwnerDecoded;

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  IMCustomObject* customObject = [[self new] autorelease];
  Class class;

  customObject->className = [unarchiver decodeStringWithName:@"className"];
  customObject->extension = [unarchiver decodeObjectWithName:@"extension"];
  customObject->realObject = [unarchiver decodeObjectWithName:@"realObject"];

  if (!_fileOwnerDecoded) {
    _fileOwnerDecoded = YES;
    customObject->realObject = _nibOwner;
    return customObject;
  }

  class = NSClassFromString (customObject->className);
  if (class)
    customObject->realObject = [[class alloc] init];
  else {
    NSLog (@"Class %@ not linked into application!", customObject->className);
  }

  return customObject;
}

- (id)nibInstantiate
{
  return realObject;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:className withName:@"className"];
  if (realObject)
    [archiver encodeObject:realObject withName:@"realObject"];
  if (extension)
    [archiver encodeObject:extension withName:@"extension"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return self;
}

@end


@implementation IMCustomView

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  IMCustomView* customView = [[self new] autorelease];
  Class class;

  customView->className = [unarchiver decodeStringWithName:@"className"];
  customView->extension = [unarchiver decodeObjectWithName:@"extension"];
  customView->realObject = [unarchiver decodeObjectWithName:@"realObject"];

  if (!_fileOwnerDecoded) {
    _fileOwnerDecoded = YES;
    customView->realObject = _nibOwner;
    return customView;
  }

  class = NSClassFromString (customView->className);
  if (class)
    customView->realObject = [[class alloc] init];
  else {
    NSLog (@"Class %@ not linked into application!", customView->className);
  }

  return customView;
}

- (id)nibInstantiate
{
  return realObject;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:className withName:@"className"];
  if (realObject)
    [archiver encodeObject:realObject withName:@"realObject"];
  if (extension)
    [archiver encodeObject:extension withName:@"extension"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return self;
}

@end
