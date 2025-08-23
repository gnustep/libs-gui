/** <title>GSAudioPlayer</title>

   <abstract>Audio player with master clock functionality for GSMovieView synchronization</abstract>

   This class provides audio playback capabilities and serves as the master clock
   for audio-video synchronization. The audio clock is continuously updated during
   playback and can be accessed by GSMovieView to synchronize video frame display.

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
  float _playbackRate; /* 0.5 to 2.0, 1.0 = normal speed */
  unsigned int _loopMode:3;

  // Audio filtering for time stretching (alternative implementation)
  SwrContext *_stretchSwrCtx;  // Secondary resampler for time stretching
  AVFrame *_stretchedFrame;    // Frame for stretched audio

  // Reusable audio buffer for conversion
  uint8_t *_audioBuffer;
  int _audioBufferSize;
  int _audioStreamIndex;
  AVFormatContext *_formatCtx;
  AVStream *_stream;
  
  NSMutableArray *_audioPackets;
  NSThread *_audioThread;

  BOOL _running;
  BOOL _started;
  BOOL _muted;
}

// Initialize...
- (void) prepareWithFormatContext: (AVFormatContext *)formatCtx
		      streamIndex: (int)audioStreamIndex;
- (void) reset;

// Decode stream...
- (int) decodePacket: (AVPacket *)packet;
- (void) submitPacket: (AVPacket *)packet;
// - (void) startAudio;
// - (void) stopAudio;
- (void) setPlaying: (BOOL)f;
- (BOOL) isPlaying;
- (IBAction) start: (id)sender;
- (IBAction) stop: (id)sender;

// Set volume...
- (float) volume;
- (void) setVolume: (float)volume;
- (void) setMuted: (BOOL)muted;
- (BOOL) isMuted;

// Show loop status...
- (NSQTMovieLoopMode) loopMode;
- (void) setLoopMode: (NSQTMovieLoopMode)mode;

// Seeking methods...
- (BOOL) seekToTime: (int64_t)timestamp;

// Audio clock access for synchronization...
- (int64_t) currentAudioClock;
- (BOOL) isAudioStarted;
- (int64_t) currentPlaybackTime; // Returns current playback time in microseconds

// Time stretching support (sample rate based)...
- (float) playbackRate;
- (void) setPlaybackRate: (float)rate; // 0.5 to 2.0, 1.0 = normal speed
- (BOOL) initializeTimeStretching;
- (void) cleanupTimeStretching;

@end

#endif // end of _GNUstep_H_GSAudioPlayer
