/* 
   VideofileSource.m

   Load and read video data using libvideofile.

   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by:  Stefan Bidigaray <stefanbidi@gmail.com>
   Date: Jun 2009
   
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

#include <Foundation/Foundation.h>
#include "GNUstepGUI/GSVideoSource.h"

#include <libavcodec/avcodec.h>

#define INBUF_SIZE 4096 + AV_INPUT_BUFFER_PADDING_SIZE

@interface VideofileSource : NSObject <GSVideoSource>
{
  NSData *_data;
  
  NSUInteger _currentPosition;
  NSTimeInterval _dur;
  int _encoding;
}

- (NSData *)data;
- (NSUInteger)currentPosition;
- (void)setCurrentPosition: (NSUInteger)curPos;
@end

@implementation VideofileSource

+ (NSArray *)videoUnfilteredFileTypes
{
  return [NSArray arrayWithObjects: @"aa", @"aac", @"apng", @"asf", @"concat",
                  @"dash", @"imf", @"flv", @"live_flv", @"kux", @"git", @"hls", @"image2",
                  @"mov", @"mp4", @"3gp", @"mpegts", @"mpjpeg", @"rawvideo", @"sbg",
                  @"tedcaptions", @"vapoursynth",nil];
}
+ (NSArray *)videoUnfilteredTypes
{
  /* FIXME: I'm not sure what the UTI for all the types above are. */
  return [self videoUnfilteredFileTypes];
}
+ (BOOL)canInitWithData: (NSData *)data
{
  return YES;
}

- (void)dealloc
{
  TEST_RELEASE (_data);
  [super dealloc];
}

- (id)initWithData: (NSData *)data
{
  self = [super init];

  if (self == nil)
    {
      return nil;
    }
  
  ASSIGN(_data, data);
 
  return self;
}

- (NSUInteger) readBytes: (void *)bytes length: (NSUInteger)length
{
  NSRange range;
  NSUInteger len = length; //- 1;

  if (_currentPosition >= [_data length] - 1)
    {
      return 0;
    }
  
  if (length > [_data length] - _currentPosition)
    {
      len = [_data length] - _currentPosition;
    }
  
  range = NSMakeRange(_currentPosition, len);
  [_data getBytes: bytes range: range];
  _currentPosition += len;
  
  return len;
}

- (NSTimeInterval)duration
{
  return _dur;
}

- (void)setCurrentTime: (NSTimeInterval)currentTime
{
}

- (NSTimeInterval)currentTime
{
  return 0.0; // (NSTimeInterval)((double)frames / (double)_info.samplerate);
}

- (int)encoding
{
  return _encoding;
}

- (NSUInteger)sampleRate;
{
  return 0; // (NSUInteger)_info.samplerate;
}

- (NSByteOrder)byteOrder
{
  // Equivalent to sending native byte order...
  // Videofile always reads as native format.
  return NS_UnknownByteOrder;
}

- (NSData *)data
{
  return _data;
}

- (NSUInteger)currentPosition
{
  return _currentPosition;
}

- (void)setCurrentPosition: (NSUInteger)curPos
{
  _currentPosition = curPos;
}

@end
