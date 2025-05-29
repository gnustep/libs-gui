/** <title>GSMovieView</title>

   <abstract>Encapsulate a movie</abstract>

   Copyright <copy>(C) 2025 Free Software Foundation, Inc.</copy>

   Author: Gregory Casamento <greg.casamento@gmail.com>
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

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSMovie.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSSound.h"

#import "GSMovieView.h"

#include <libswresample/swresample.h>

static NSDictionary *NSDictionaryFromAVPacket(AVPacket *packet)
{
  NSData *data = [NSData dataWithBytes:packet->data length:packet->size];
  NSNumber *pts = [NSNumber numberWithLongLong:packet->pts];
  NSNumber *duration = [NSNumber numberWithInt:packet->duration];
  NSNumber *flags = [NSNumber numberWithInt:packet->flags];

  return [NSDictionary dictionaryWithObjectsAndKeys:
			 data, @"data",
		       pts, @"pts",
		       duration, @"duration",
		       flags, @"flags",
		       nil];
}

static AVPacket AVPacketFromNSDictionary(NSDictionary *dict)
{
  NSData *data = [dict objectForKey:@"data"];
  NSNumber *pts = [dict objectForKey:@"pts"];
  NSNumber *duration = [dict objectForKey:@"duration"];
  NSNumber *flags = [dict objectForKey:@"flags"];
  
  AVPacket *packet = av_packet_alloc();
  packet->data = (uint8_t *)[data bytes];
  packet->size = (int)[data length];
  packet->pts = [pts longLongValue];
  packet->duration = [duration intValue];
  packet->flags = [flags intValue];

  return *packet;
}

@interface FFmpegAudioPlayer : NSObject
{
  AVCodecContext *_audioCodecCtx;
  AVFrame *_audioFrame;
  SwrContext *_swrCtx;
  ao_device *_aoDev;
  ao_sample_format _aoFmt;
  int64_t _lastPTS;
  int64_t _audioClock;
  AVRational _timeBase;
  NSMutableArray *_audioPackets;
  NSThread *_audioThread;
  BOOL _running;
  float _volume; /* 0.0 to 1.0 */
  BOOL _started;
}

- (void) prepareAudioWithFormatContext:(AVFormatContext *)formatCtx
                           streamIndex:(int)audioStreamIndex;
- (void) decodeAudioPacket:(AVPacket *)packet;
- (void) start;
- (void) stop;
- (void) setVolume: (float)volume;

@end

@implementation FFmpegAudioPlayer
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _audioCodecCtx = NULL;
      _audioFrame = NULL;
      _swrCtx = NULL;
      _lastPTS = 0;
      _audioClock = 0;
      _audioPackets = nil;
      _audioThread = nil;
      _running = NO;
      _volume = 1.0;
      _started = NO;
    }
  return self;
}

- (void)dealloc
{
  [self stop];

  if (_audioFrame)
    av_frame_free(&_audioFrame);

  if (_audioCodecCtx)
    avcodec_free_context(&_audioCodecCtx);

  if (_swrCtx)
    swr_free(&_swrCtx);

  if (_aoDev)
    ao_close(_aoDev);

  RELEASE(_audioPackets);

  ao_shutdown();
  [super dealloc];
}

- (void) prepareAudioWithFormatContext:(AVFormatContext *)formatCtx
                           streamIndex:(int)audioStreamIndex
{
  ao_initialize();
  int driver = ao_default_driver_id();
  int out_channels = 2;
  
  AVCodecParameters *audioPar = formatCtx->streams[audioStreamIndex]->codecpar;
  const AVCodec *audioCodec = avcodec_find_decoder(audioPar->codec_id);

  if (!audioCodec)
    {
      NSLog(@"Audio codec not found.");
      return;
    }

  _audioCodecCtx = avcodec_alloc_context3(audioCodec);
  avcodec_parameters_to_context(_audioCodecCtx, audioPar);

  if (avcodec_open2(_audioCodecCtx, audioCodec, NULL) < 0)
    {
      NSLog(@"Failed to open audio codec.");
      return;
    }

  _audioFrame = av_frame_alloc();
  swr_alloc_set_opts2(&_swrCtx,
		      &(AVChannelLayout){ .order = AV_CHANNEL_ORDER_NATIVE,
			  .nb_channels = out_channels,
			  .u.mask = AV_CH_LAYOUT_STEREO },
		      AV_SAMPLE_FMT_S16,
		      _audioCodecCtx->sample_rate,
		      &_audioCodecCtx->ch_layout,
		      _audioCodecCtx->sample_fmt,
		      _audioCodecCtx->sample_rate,
		      0, NULL);
  swr_init(_swrCtx);

  memset(&_aoFmt, 0, sizeof(ao_sample_format));
  _aoFmt.bits = 16;
  _aoFmt.channels = out_channels;
  _aoFmt.rate = _audioCodecCtx->sample_rate;
  _aoFmt.byte_format = AO_FMT_NATIVE;

  _aoDev = ao_open_live(driver, &_aoFmt, NULL);
  _timeBase = formatCtx->streams[audioStreamIndex]->time_base;
  _lastPTS = 0;
  _audioClock = av_gettime();
  _audioPackets = [[NSMutableArray alloc] init];
  _running = YES;
  // [self start];
}

- (void)audioThreadEntry
{
  while (_running)
    {
      CREATE_AUTORELEASE_POOL(pool);
      {
	NSDictionary *dict = nil;
	
	@synchronized (_audioPackets)
	  {
	    if (!_started && [_audioPackets count] < 5)
	      {
		usleep(5000);
		continue;
	      }
	    if ([_audioPackets count] > 0)
	      {
		dict = [[_audioPackets objectAtIndex:0] retain];
		[_audioPackets removeObjectAtIndex:0];
	      }
	  }
	
	if (!_started && dict)
	  {
	    _audioClock = av_gettime();
	    _started = YES;
	  }
	
	if (dict)
	  {
	    AVPacket packet = AVPacketFromNSDictionary(dict);
	    int64_t packetTime = av_rescale_q(packet.pts, _timeBase, (AVRational){1, 1000000});
	    int64_t now = av_gettime() - _audioClock;
	    int64_t delay = packetTime - now;
	    if (delay > 0)
	      usleep((useconds_t)delay);
	    
	    [self decodeAudioPacket:&packet];
	    [dict release];
	  }
	else
	  {
	    usleep(1000);
	  }
      }
      RELEASE(pool);
    }
}

- (void)decodeAudioPacket:(AVPacket *)packet
{
  if (!_audioCodecCtx || !_swrCtx || !_aoDev)
    return;

  if (avcodec_send_packet(_audioCodecCtx, packet) < 0)
    return;

  while (avcodec_receive_frame(_audioCodecCtx, _audioFrame) == 0)
    {
      int outSamples = _audioFrame->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);
      uint8_t *outBuf = (uint8_t *) malloc(outBytes);
      uint8_t *outPtrs[] = { outBuf };

      swr_convert(_swrCtx, outPtrs, outSamples,
                  (const uint8_t **) _audioFrame->data,
		  outSamples);

      // Apply volume
      int16_t *samples = (int16_t *)outBuf;
      int i = 0;
      for (i = 0; i < outBytes / 2; ++i)
	{
	  samples[i] = samples[i] * _volume;
	}
      
      ao_play(_aoDev, (char *) outBuf, outBytes);
      free(outBuf);
    }
}

- (void)submitPacket:(AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);
  @synchronized (_audioPackets)
    {
      [_audioPackets addObject:dict];
    }
}

- (void)start
{
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void)stop
{
  _running = NO;
  [_audioThread cancel];
  while (![_audioThread isFinished])
    usleep(1000);
  [_audioThread release];
  _audioThread = nil;
}

- (void)setVolume:(float)volume
{
  if (volume < 0.0) volume = 0.0;
  if (volume > 1.0) volume = 1.0;
  _volume = volume;
}

@end

@implementation GSMovieView

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _currentFrame = nil;
      _videoThread = nil;
      _feedThread = nil;
      _audioPlayer = [[FFmpegAudioPlayer alloc] init];
      _videoPackets = RETAIN([[NSMutableArray alloc] init]);
      _running = NO;
      _started = NO;
      _videoClock = 0;
      _videoCodecCtx = 0;
      _swsCtx = NULL;
    }
  return self;
}

- (void)dealloc
{
  [self stop: nil];

  if (_videoFrame)
    av_frame_free(&_videoFrame);
  if (_videoCodecCtx)
    avcodec_free_context(&_videoCodecCtx);
  if (_swsCtx)
    sws_freeContext(_swsCtx);

  DESTROY(_videoPackets);
  // DESTROY(_currentFrame);
  DESTROY(_audioPlayer);

  [super dealloc];
}

// Overridden methods from the superclass...
- (BOOL) isPlaying
{
  return _running;
}

- (IBAction) start: (id)sender
{
  [self setRate: 1.0 / 30.0];
  [self setVolume: 1.0];

  _feedThread = RETAIN([[NSThread alloc] initWithTarget:self selector:@selector(feed) object:nil]);
  [_feedThread start];
  [_audioPlayer start];
}

- (IBAction) stop: (id)sender
{
  [_feedThread cancel];
  [self stop];
  [_audioPlayer stop];

  DESTROY(_feedThread);
}

- (void) setVolume: (float)volume
{
  [super setVolume: volume];
  [_audioPlayer setVolume: volume];
}

- (NSRect) movieRect
{
  return NSMakeRect(0.0, 0.0,
		    (float)_videoCodecCtx->width,
		    (float)_videoCodecCtx->height);
}

// Video playback methods...
- (void) updateImage: (NSImage *)image
{
  ASSIGN(_currentFrame, image);
  [self setNeedsDisplay:YES];
}

- (void) drawRect: (NSRect)dirtyRect
{
  [super drawRect: dirtyRect];
  if (_currentFrame)
    {
      [_currentFrame drawInRect: [self bounds]];
    }
}

- (void) feed
{
  NSMovie *movie = [self movie];
  NSURL *url = [movie URL];
  const char *path = [[url path] UTF8String]; 
  NSLog(@"[Info] Opening file: %s | Timestamp: %ld", path, av_gettime());
  avformat_network_init();

  AVFormatContext *formatCtx = NULL;
  if (avformat_open_input(&formatCtx, path, NULL, NULL) != 0)
    {
      NSLog(@"[Error] Could not open file: %s | Timestamp: %ld", path, av_gettime());
      return;
    }

  if (avformat_find_stream_info(formatCtx, NULL) < 0)
    {
      NSLog(@"[Error] Could not find stream info. | Timestamp: %ld", av_gettime());
      avformat_close_input(&formatCtx);
      return;
    }

  int videoStream = -1;
  for (unsigned int i = 0; i < formatCtx->nb_streams; i++)
    {
      if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
        {
          videoStream = i;
          break;
        }
    }

  int audioStream = -1;
  for (unsigned int i = 0; i < formatCtx->nb_streams; i++)
    {
      if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO)
        {
          audioStream = i;
          break;
        }
    }  

  if (videoStream == -1)
    {
      NSLog(@"[Error] No video stream found. | Timestamp: %ld", av_gettime());
      avformat_close_input(&formatCtx);
      return;
    }

  // If it's video only we just log it and continue...
  if (audioStream == -1)
    {
      NSLog(@"[Error] No audio stream found. | Timestamp: %ld", av_gettime());
    }

  [self prepareVideoWithFormatContext:formatCtx streamIndex:videoStream];

  AVPacket packet;
  int64_t i = 0;
  while (av_read_frame(formatCtx, &packet) >= 0)
    {
      // After 1000 frames, start the thread...
      if (i == 1000)
	{
	  [self start];
	}
      
      if (packet.stream_index == videoStream)
        [self submitVideoPacket: &packet];

      if (packet.stream_index == audioStream)
        [_audioPlayer submitPacket: &packet];      

      av_packet_unref(&packet);
      i++;
    }

  // if we had a very short video... play it.
  if (i < 1000)
    {
      NSLog(@"[GSMovieView] Starting short video... | Timestamp: %ld", av_gettime());
      [self start];
    }
  
  avformat_close_input(&formatCtx);
}

- (void)prepareVideoWithFormatContext:(AVFormatContext *)formatCtx streamIndex:(int)videoStreamIndex
{
  AVCodecParameters *videoPar = formatCtx->streams[videoStreamIndex]->codecpar;
  const AVCodec *videoCodec = avcodec_find_decoder(videoPar->codec_id);
  if (!videoCodec)
    {
      NSLog(@"[Error] Unsupported video codec. | Timestamp: %ld", av_gettime());
      return;
    }
  
  _videoCodecCtx = avcodec_alloc_context3(videoCodec);
  avcodec_parameters_to_context(_videoCodecCtx, videoPar);
  if (avcodec_open2(_videoCodecCtx, videoCodec, NULL) < 0)
    {
      NSLog(@"[Error] Failed to open video codec. | Timestamp: %ld", av_gettime());
      return;
    }
  
  _videoFrame = av_frame_alloc();
  _swsCtx = sws_getContext(videoPar->width, videoPar->height, _videoCodecCtx->pix_fmt,
                           videoPar->width, videoPar->height, AV_PIX_FMT_RGB24,
                           SWS_BILINEAR, NULL, NULL, NULL);

  _timeBase = formatCtx->streams[videoStreamIndex]->time_base;
  _videoPackets = RETAIN([[NSMutableArray alloc] init]);
  _videoClock = av_gettime();
  _running = NO;
  _started = NO;
}

- (void) start
{
  NSLog(@"[GSMovieView] Starting video thread | Timestamp: %ld", av_gettime());
  if (!_running)
    {
      _running = YES;
      _videoThread = RETAIN([[NSThread alloc] initWithTarget:self selector:@selector(videoThreadEntry) object:nil]);
      [_videoThread start];
    }
}

- (void) stop
{
  NSLog(@"[GSMovieView] Stopping video thread | Timestamp: %ld", av_gettime());
  if (_running)
    {
      _running = NO;
      [_videoThread cancel];
      while (![_videoThread isFinished])
        usleep(1000);
      DESTROY(_videoThread);
    }
}

- (void)submitVideoPacket:(AVPacket *)packet
{
  NSDictionary *dict = NSDictionaryFromAVPacket(packet);
  @synchronized (_videoPackets)
    {
      [_videoPackets addObject:dict];
    }
}

- (void)videoThreadEntry
{
  while (_running)
    {
      CREATE_AUTORELEASE_POOL(pool);
        {
          NSDictionary *dict = nil;

          @synchronized (_videoPackets)
            {
              if (!_started && [_videoPackets count] < 3)
                {
                  usleep(5000);
                  [pool release];
                  continue;
                }
              if ([_videoPackets count] > 0)
                {
                  dict = RETAIN([_videoPackets objectAtIndex:0]);
                  [_videoPackets removeObjectAtIndex:0];
                }
            }

          if (!_started && dict)
            {
              _videoClock = av_gettime();
              _started = YES;
            }

          if (dict)
            {
              // NSLog(@"[GSMovieView] Rendering frame PTS: %ld | Delay: %ld us", packet.pts, delay);
              AVPacket packet = AVPacketFromNSDictionary(dict);

              int64_t packetTime = av_rescale_q(packet.pts, _timeBase, (AVRational){1, 1000000});
              int64_t now = av_gettime() - _videoClock;
              int64_t delay = packetTime - now;
              if (delay > 0)
                usleep((useconds_t)delay);

              [self decodeVideoPacket:&packet];
              RELEASE(dict);
            }
          else
            {
              usleep(1000);
            }
	  RELEASE(pool);
        }
    }
}

- (void)decodeVideoPacket:(AVPacket *)packet
{
  if (!_videoCodecCtx || !_swsCtx)
    return;

  if (avcodec_send_packet(_videoCodecCtx, packet) < 0)
    return;

  while (avcodec_receive_frame(_videoCodecCtx, _videoFrame) == 0)
    {
      uint8_t *rgbData[1];
      int rgbLineSize[1];
      
      int width = _videoCodecCtx->width;
      int height = _videoCodecCtx->height;
      
      rgbLineSize[0] = width * 3;
      rgbData[0] = (uint8_t *)malloc(height * rgbLineSize[0]);
      
      sws_scale(_swsCtx,
                (const uint8_t * const *)_videoFrame->data,
                _videoFrame->linesize,
                0,
                height,
                rgbData,
                rgbLineSize);
      
      NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
				   initWithBitmapDataPlanes: &rgbData[0]
						 pixelsWide: width
						 pixelsHigh: height
					      bitsPerSample: 8
					    samplesPerPixel: 3
						   hasAlpha: NO
						   isPlanar: NO
					     colorSpaceName: NSCalibratedRGBColorSpace
						bytesPerRow: rgbLineSize[0]
					       bitsPerPixel: 24];
      
      NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(width, height)];
      [image addRepresentation: bitmap];
      [self performSelectorOnMainThread: @selector(updateImage:)
			     withObject: image
			  waitUntilDone: NO];      
      
      RELEASE(bitmap);
      free(rgbData[0]);
    }
}

@end
