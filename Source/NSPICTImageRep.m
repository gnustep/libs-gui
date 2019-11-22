/* Implementation of class NSPICTImageRep
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: heron
   Date: Fri Nov 15 04:24:51 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/

#include <AppKit/NSPICTImageRep.h>

@implementation NSPICTImageRep

+ (instancetype) imageRepWithData: (NSData *)imageData
{
  return AUTORELEASE([[self alloc] initWithData: imageData]);
}

- (instancetype) initWithData: (NSData *)imageData
{
  self = [super init];
  if (self != nil)
    {
      BOOL result = NO;
      
      ASSIGNCOPY(_imageData, imageData);
      result = [self _readPICTHeader];
      if (result == NO)
        {
          RELEASE(self);
          return nil;
        }
    }
  return self;
}

- (NSRect) boundingBox
{
  return _boundingBox;
}

- (NSData *) PICTRepresentation
{
  return [_pictRepresentation copy];
}

- (BOOL) _readPICTHeader
{
  _position = 512;
  return NO;
}

- (BOOL) _drawPICT
{
  return NO;
}

- (BOOL) draw
{
  return [self _drawPICT];
}

@end

