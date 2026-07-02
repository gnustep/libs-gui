/*
   GSNibArchiveLoader.m

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
*/

#import "config.h"
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibArchiveKeyedUnarchiver.h"
#import "GNUstepGUI/GSNibLoading.h"

@interface GSNibArchiveLoader : GSModelLoader
@end

@implementation GSNibArchiveLoader
+ (BOOL) canReadData: (NSData *)data
{
  return [GSNibArchiveKeyedUnarchiver canReadData: data];
}

+ (NSString *) type
{
  return @"nibarchive";
}

+ (float) priority
{
  return 2.0;
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone
{
  BOOL loaded = NO;
  GSNibArchiveKeyedUnarchiver *unarchiver = nil;

  NS_DURING
    {
      id object;

      unarchiver = [[GSNibArchiveKeyedUnarchiver alloc]
        initForReadingWithData: data];
      [unarchiver setObjectZone: zone];
      [unarchiver setClass: [NSWindowTemplate class]
	      forClassName: @"NSWindow"];
      object = [unarchiver decodeObjectForKey: @"IB.objectdata"];
      if ([object isKindOfClass: [NSIBObjectData class]])
        {
          [object awakeWithContext: context];
          loaded = YES;
        }
      else if (object != nil)
        {
          NSLog(@"NIBArchive without container object!");
        }
      else
        {
          NSLog(@"IB.objectdata not found when loading NIBArchive.");
        }
    }
  NS_HANDLER
    {
      NSLog(@"Exception occurred while loading NIBArchive: %@",
        [localException reason]);
    }
  NS_ENDHANDLER

  RELEASE(unarchiver);
  if (loaded == NO)
    {
      NSLog(@"Failed to load NIBArchive nib");
    }

  return loaded;
}
@end
