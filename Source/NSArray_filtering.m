/* 
   <title>NSArray_filtering.m</title>

   <abstract>Object filtering extensions for NSArray</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: February 2004
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#import "NSArray_filtering.h"

// Extensions
@implementation NSArray (ObjectsWithValueForKey)

- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key 
{
  NSMutableArray *result = [NSMutableArray array];
  NSArray *keys = [self valueForKey: key];
  int i, n = 0;
  
  if (keys == nil)
    return nil;
  
  n = [keys count];
  
  for (i = 0; i < n; i++)
    {
      if ([[keys objectAtIndex: i] isEqual: value])
        {
          [result addObject: [self objectAtIndex: i]];
        }
    }
    
  if ([result count] == 0)
    return nil;
  
  return result;
}
@end
