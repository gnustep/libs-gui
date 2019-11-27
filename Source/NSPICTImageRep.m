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

#define BYTE unsigned char
#define DWORD unsigned int
#define WORD unsigned short
#define SHORT short

struct PICT_Header
{
  // Initial header
  SHORT file_size;
  SHORT x_top_left;
  SHORT y_top_left;
  SHORT x_lower_right;
  SHORT y_lower_right;

  // Version 2
  SHORT version_operator;
  SHORT version_num;

  // picSize
  WORD pic_size;
  WORD image_top;
  WORD image_left;
  WORD image_bottom;
  WORD image_right;

  // picFrame v2
  WORD version;
  WORD pic_version;
  WORD reserved_header_opcode;
  WORD header_opcode;
  DWORD picture_size_bytes;
  DWORD original_horizontal_resolution;
  DWORD original_vertical_resolution;
  WORD x_value_of_top_left_of_image;
  WORD y_value_of_top_left_of_image;
  WORD x_value_of_lower_right_of_image;
  WORD y_value_of_lower_right_of_image;
  DWORD reserved;
};

@implementation NSPICTImageRep

+ (instancetype) imageRepWithData: (NSData *)imageData
{
  return AUTORELEASE([[self alloc] initWithData: imageData]);
}

- (BOOL) _readHeader
{
  NSUInteger pos = 0;
  _position = pos;
  return NO;
}

- (instancetype) initWithData: (NSData *)imageData
{
  self = [super init];
  if (self != nil)
    {
      BOOL result = NO;
      
      ASSIGNCOPY(_imageData, imageData);
      result = [self _readHeader];
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

- (BOOL) _drawPICT
{
  return NO;
}

- (BOOL) draw
{
  return [self _drawPICT];
}

@end

