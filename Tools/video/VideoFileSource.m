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

@interface VideofileSource : NSObject <GSVideoSource>
{
  NSData *_data;
  
  NSUInteger _curPos;
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
  // sf_close (_video);
  
  [super dealloc];
}

- (id)initWithData: (NSData *)data
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }
  
  _data = data;
  RETAIN(_data);
  
  // _info.format = 0;
  /*
  _video = sf_open_virtual (&dataIO, SFM_READ, &_info, self);
  if (_video == NULL)
    {
      DESTROY(self);
      return nil;
    }
  */
  
  // Setup immutable values...
  /* FIXME: support multiple types */
  // _dur = (double)_info.frames / (double)_info.samplerate;
  
  return self;
}

- (NSUInteger)readBytes: (void *)bytes length: (NSUInteger)length
{
  return 0; // (NSUInteger) (sf_read_short (_video, bytes, (length>>1))<<1);
}

- (NSTimeInterval)duration
{
  return _dur;
}

- (void)setCurrentTime: (NSTimeInterval)currentTime
{
  // sf_count_t frames = (sf_count_t)((double)_info.samplerate * currentTime);
  // sf_seek (_video, frames, SEEK_SET);
}
- (NSTimeInterval)currentTime
{
  // sf_count_t frames;
  // frames = sf_seek (_video, 0, SEEK_CUR);
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
  return _curPos;
}

- (void)setCurrentPosition: (NSUInteger)curPos
{
  _curPos = curPos;
}

@end
