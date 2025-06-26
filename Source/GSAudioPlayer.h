/** <title>GSAudioPlayer</title>

   <abstract>This class is just a quick sound player for GSMovieView</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: May 2025

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

#ifndef _GNUstep_H_GSAudioPlayer
#define _GNUstep_H_GSAudioPlayer

#import "config.h"

#import <Foundation/NSObject.h>
#import "AppKit/NSMovieView.h"

#include <ao/ao.h>
#include <unistd.h>

/* FFmpeg headers */
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavcodec/codec.h>
#include <libavutil/imgutils.h>
#include <libavutil/time.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>

@class NSDictionary;
@class NSMutableArray;
@class NSThread;

// Audio player for NSMovieView...
@interface GSAudioPlayer : NSObject
{
  AVCodecContext *_audioCodecCtx;
  AVFrame *_audioFrame;
  SwrContext *_swrCtx;
  ao_device *_aoDev;
  ao_sample_format _aoFmt;
  int64_t _audioClock;
  AVRational _timeBase;

  float _volume; /* 0.0 to 1.0 */
  BOOL _running;
  BOOL _muted;
}

- (void) prepareWithFormatContext: (AVFormatContext *)formatCtx
		      streamIndex: (int)audioStreamIndex;

// Decode and play the packet...
- (NSData *) decodePacketToData: (AVPacket *)packet;
- (BOOL) decodePacket: (AVPacket *)packet;
- (BOOL) decodeDictionary: (NSDictionary *)dict;
- (void) playData: (NSData *)data;

// Controls...
- (float) volume;
- (void) setVolume: (float)volume;
- (void) setMuted: (BOOL)muted;
- (BOOL) isMuted;

@end

#endif // end of _GNUstep_H_GSAudioPlayer
