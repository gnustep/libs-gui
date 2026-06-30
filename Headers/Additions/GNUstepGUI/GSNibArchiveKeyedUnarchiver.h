/*
   GSNibArchiveKeyedUnarchiver.h

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
*/

#ifndef _GNUstep_H_GSNibArchiveKeyedUnarchiver
#define _GNUstep_H_GSNibArchiveKeyedUnarchiver

#import <AppKit/AppKitDefines.h>
#import <Foundation/NSKeyedArchiver.h>

@class NSData;

APPKIT_EXPORT_CLASS
@interface GSNibArchiveKeyedUnarchiver : NSKeyedUnarchiver
{
  NSData *_data;
  const uint8_t *_bytes;
  NSUInteger _length;
  NSMutableArray *_m_objects;
  NSMutableArray *_keys;
  NSMutableArray *_values;
  NSMutableArray *_classNames;
  NSMutableDictionary *_decodedObjects;
  NSMutableDictionary *_classNameMap;
  NSMutableArray *_objectStack;
  NSMutableArray *_cursorStack;
  id _na_delegate;
  NSZone *_objectZone;
}

+ (BOOL) canReadData: (NSData *)data;
- (id) initForReadingWithData: (NSData *)data;
- (id) _decodeArrayOfObjectsForKey: (NSString *)key;
- (id) _decodePropertyListForKey: (NSString *)key;
@end

#endif
