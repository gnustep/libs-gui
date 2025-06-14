/** <title>NSMovieView</title>

   <abstract>Encapsulate a view for Quicktime movies</abstract>

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

#ifndef _GNUstep_H_GSMovieView
#define _GNUstep_H_GSMovieView

#import "config.h"
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

@class NSImage;
@class NSTimer;
@class GSAudioPlayer;

APPKIT_EXPORT_CLASS
@interface GSMovieView : NSMovieView
{
  NSMutableArray *_videoPackets;
  NSThread *_videoThread;
  NSThread *_feedThread;
  NSImage *_currentFrame;
  NSString *_statusString;
  GSAudioPlayer *_audioPlayer;
  NSLock *_lock;

  AVCodecContext *_videoCodecCtx;
  AVFrame *_videoFrame;
  AVFormatContext *_formatCtx;
  AVStream *_stream;
  struct SwsContext *_swsCtx;
  AVRational _timeBase;

  BOOL _paused;  // is the stream paused...
  BOOL _running; // is the loop currently running...
  BOOL _started; // has the video started...
  int64_t _videoClock;
  int _videoStreamIndex;
  int _audioStreamIndex;
  int64_t _lastPts;
  int64_t _savedPts;
  CGFloat _fps;
}

// Initialization...
- (void) prepareWithFormatContext: (AVFormatContext *)formatCtx
                      streamIndex: (int)videoStreamIndex;

// Submit packets...
- (void) submitPacket: (AVPacket *)packet;
- (void) decodePacket: (AVPacket *)packet;

// Start and stop...
- (void) startVideo;
- (void) stopVideo;
- (void) setPaused: (BOOL)f;
- (BOOL) isPaused;

// Main loop to process packets...
- (void) renderFrame: (AVFrame *)videoFrame;
- (void) feedVideo;
- (BOOL) setup;
- (void) loop;
- (void) close;

@end

#endif /* _GNUstep_H_GSMovieView */
