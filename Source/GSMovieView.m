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
  float _volume;
}

- (void)prepareAudioWithFormatContext:(AVFormatContext *)formatCtx
                           streamIndex:(int)audioStreamIndex;
- (void)decodeAudioPacket:(AVPacket *)packet;
- (void)startAudioThread;
- (void)stopAudioThread;
- (void)submitPacket:(AVPacket *)packet;
- (int64_t) currentAudioTimeUsec;
- (void) setVolume: (float)volume;

@end

@implementation FFmpegAudioPlayer

- (int64_t) currentAudioTimeUsec
{
  return _audioClock + (av_rescale_q(_lastPTS, _timeBase, (AVRational){1,1000000}));
}

- (void)prepareAudioWithFormatContext:(AVFormatContext *)formatCtx streamIndex:(int)audioStreamIndex
{
  ao_initialize();
  int driver = ao_default_driver_id();

  AVCodecParameters *audioPar = formatCtx->streams[audioStreamIndex]->codecpar;
  AVCodec *audioCodec = avcodec_find_decoder(audioPar->codec_id);
  if (!audioCodec) return;

  _audioCodecCtx = avcodec_alloc_context3(audioCodec);
  avcodec_parameters_to_context(_audioCodecCtx, audioPar);
  if (avcodec_open2(_audioCodecCtx, audioCodec, NULL) < 0) return;

  _audioFrame = av_frame_alloc();
  _swrCtx = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S16, _audioCodecCtx->sample_rate,
                               _audioCodecCtx->channel_layout, _audioCodecCtx->sample_fmt,
                               _audioCodecCtx->sample_rate, 0, NULL);
  swr_init(_swrCtx);

  memset(&_aoFmt, 0, sizeof(ao_sample_format));
  _aoFmt.bits = 16;
  _aoFmt.channels = 2;
  _aoFmt.rate = _audioCodecCtx->sample_rate;
  _aoFmt.byte_format = AO_FMT_NATIVE;
  _aoDev = ao_open_live(driver, &_aoFmt, NULL);

  _timeBase = formatCtx->streams[audioStreamIndex]->time_base;
  _lastPTS = 0;
  _audioClock = av_gettime();
  _audioPackets = [[NSMutableArray alloc] init];
  _running = YES;
  _audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadEntry) object:nil];
  [_audioThread start];
}

- (void)submitPacket:(AVPacket *)packet
{
  NSData *data = [NSData dataWithBytes: packet->data
				length: packet->size];
  NSNumber *pts = [NSNumber numberWithInt: (packet->pts)];
  NSDictionary *dict =
    [NSDictionary dictionaryWithObjectsAndKeys: data, @"data",
		  pts, @"pts", nil];

  @synchronized (_audioPackets)
    {
      [_audioPackets addObject: dict];
    }
}

- (void)audioThreadEntry
{
  while (_running)
    {
      CREATE_AUTORELEASE_POOL(pool);
      NSDictionary *dict = nil;
      @synchronized (_audioPackets)
	{
	  if ([_audioPackets count] > 0)
	    {
	      dict = [[_audioPackets objectAtIndex:0] retain];
	      [_audioPackets removeObjectAtIndex:0];
	    }
	}

      // Unpack the data from the dictionary...
      if (dict)
	{
	  NSData *data = [dict objectForKey: @"data"];
	  NSNumber *pts = [dict objectForKey: @"pts"];
	  
	  AVPacket packet;
	  av_init_packet(&packet);
	  packet.data = (uint8_t *)[data bytes];
	  packet.size = (int)[data length];
	  packet.pts = [pts longLongValue];
	  
	  [self decodeAudioPacket:&packet];
	  RELEASE(dict);
	}
      RELEASE(pool);
    }
}

- (void)decodeAudioPacket:(AVPacket *)packet
{
  if (!_audioCodecCtx || !_swrCtx || !_aoDev) return;
  if (avcodec_send_packet(_audioCodecCtx, packet) < 0) return;

  while (avcodec_receive_frame(_audioCodecCtx, _audioFrame) == 0)
    {
      int outSamples = _audioFrame->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);
      uint8_t *outBuf = (uint8_t *) malloc(outBytes);
      uint8_t *outPtrs[] = { outBuf };

      swr_convert(_swrCtx, outPtrs, outSamples,
                  (const uint8_t **) _audioFrame->data, outSamples);

      // Apply volume
      int16_t *samples = (int16_t *)outBuf;
      for (int i = 0; i < outBytes / 2; ++i)
	{
	  samples[i] = samples[i] * _volume;
	}
      
      ao_play(_aoDev, (char *) outBuf, outBytes);
      free(outBuf);
    }
}

- (void)setVolume:(float)volume
{
  if (volume < 0.0) volume = 0.0;
  if (volume > 1.0) volume = 1.0;
  _volume = volume;
}

- (void)dealloc
{
  _running = NO;
  [_audioThread cancel];
  while (![_audioThread isFinished]) usleep(1000);
  RELEASE(_audioThread);

  if (_audioFrame) av_frame_free(&_audioFrame);
  if (_audioCodecCtx) avcodec_free_context(&_audioCodecCtx);
  if (_swrCtx) swr_free(&_swrCtx);
  if (_aoDev) ao_close(_aoDev);
  [_audioPackets release];
  ao_shutdown();
  [super dealloc];
}

@end

@implementation GSMovieView

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _videoStreamIndex = -1;
      _audioStreamIndex = -1;
      _decodeTimer = nil;
      _currentFrame = nil;
      _buffer = NULL;
      _swsCtx = NULL;
      _avframe = NULL;
      _avframeRGB = NULL;
      _codecContext = NULL;
      _formatContext = NULL;
      _audioPlayer = [[FFmpegAudioPlayer alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [self stop: nil];
  RELEASE(_currentFrame);
  RELEASE(_audioPlayer);
  [super dealloc];
}

- (void)logStreamMetadata
{
  AVStream *vs = _formatContext->streams[_videoStreamIndex];
  double duration = (double)_formatContext->duration / AV_TIME_BASE;
  NSString *info = [NSString stringWithFormat:@"Video: %dx%d %@ %.2fs",
			     _codecContext->width,
			     _codecContext->height,
			     [NSString stringWithUTF8String:avcodec_get_name(_codecContext->codec_id)],
			     duration];
  // [_metadataLabel setStringValue:info];
  NSLog(@"%@", info);

  if (_audioStreamIndex != -1)
    {
      AVCodecParameters *ap = _formatContext->streams[_audioStreamIndex]->codecpar;
      NSLog(@"Audio codec: %s, sample rate: %d, channels: %d",
	    avcodec_get_name(ap->codec_id),
	    ap->sample_rate,
	    ap->channels);
    }
}

- (void) resetDecoder
{
  [self stop: nil];
  RELEASE(_currentFrame);
  _videoStreamIndex = -1;
  _audioStreamIndex = -1;
}

- (void) updateImage: (NSImage *)image
{
  ASSIGN(_currentFrame, image);
  [self setNeedsDisplay:YES];
}

- (void) prepareDecoder
{
  NSString *moviePath = [[_movie URL] path];

  _formatContext = avformat_alloc_context();
  if (avformat_open_input(&_formatContext, [moviePath UTF8String], NULL, NULL) != 0) return;
  if (avformat_find_stream_info(_formatContext, NULL) < 0) return;

  _videoStreamIndex = -1;
  _audioStreamIndex = -1;
  for (int i = 0; i < _formatContext->nb_streams; i++)
    {
      if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO
	  && _videoStreamIndex == -1)
	{
	  _videoStreamIndex = i;
	}
      else if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO
	       && _audioStreamIndex == -1)
	{
	  _audioStreamIndex = i;
	}
    }

  if (_videoStreamIndex == -1) return;
  if (_audioStreamIndex != -1)
    {
      [_audioPlayer setVolume: [super volume]];
      [_audioPlayer prepareAudioWithFormatContext: _formatContext
				      streamIndex: _audioStreamIndex];
    }
  
  AVCodecParameters *codecPar = _formatContext->streams[_videoStreamIndex]->codecpar;
  const AVCodec *codec = avcodec_find_decoder(codecPar->codec_id);

  _videoTimeBase = _formatContext->streams[_videoStreamIndex]->time_base;
  _codecContext = avcodec_alloc_context3(codec);
  avcodec_parameters_to_context(_codecContext, codecPar);
  if (avcodec_open2(_codecContext, codec, NULL) < 0) return;

  _avframe = av_frame_alloc();
  _avframeRGB = av_frame_alloc();

  int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, _codecContext->width, _codecContext->height, 1);
  _buffer = (uint8_t *)av_malloc(numBytes * sizeof(uint8_t));
  av_image_fill_arrays(_avframeRGB->data, _avframeRGB->linesize, _buffer, AV_PIX_FMT_RGB24,
		       _codecContext->width, _codecContext->height, 1);

  _swsCtx = sws_getContext(_codecContext->width, _codecContext->height, _codecContext->pix_fmt,
			   _codecContext->width, _codecContext->height, AV_PIX_FMT_RGB24,
			   SWS_BILINEAR, NULL, NULL, NULL);

  [self logStreamMetadata];
}

- (void) decodeAndDisplayNextFrame
{
  AVPacket packet;

  av_init_packet(&packet);
  packet.data = NULL;
  packet.size = 0;

  while (av_read_frame(_formatContext, &packet) >= 0)
    {
      if (!_playing) break;

      if (packet.stream_index == _videoStreamIndex)
	{
	  avcodec_send_packet(_codecContext, &packet);
	  if (avcodec_receive_frame(_codecContext, _avframe) == 0)
	    {
	      sws_scale(_swsCtx, (const uint8_t * const *)_avframe->data, _avframe->linesize, 0,
			_codecContext->height, _avframeRGB->data, _avframeRGB->linesize);

	      NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes: _avframeRGB->data
						      pixelsWide: _codecContext->width
						      pixelsHigh: _codecContext->height
						   bitsPerSample: 8
						 samplesPerPixel: 3
							hasAlpha: NO
							isPlanar: NO
						  colorSpaceName: NSCalibratedRGBColorSpace
						     bytesPerRow: _avframeRGB->linesize[0]
						    bitsPerPixel: 24];
	      NSSize imageSize = NSMakeSize(_codecContext->width, _codecContext->height);
	      NSImage *image = [[NSImage alloc] initWithSize: imageSize];

	      [image addRepresentation:rep];
	      [self performSelectorOnMainThread: @selector(updateImage:)
				     withObject: image
				  waitUntilDone: NO];
	      AUTORELEASE(rep);

	      break;
	    }
	}
      else if (packet.stream_index == _audioStreamIndex)
	{
	  [_audioPlayer submitPacket: &packet];
	}
    av_packet_unref(&packet);

    // Sync on sound stream...
    int64_t ptsUsec = av_rescale_q(_avframe->pts, _videoTimeBase, (AVRational){1,1000000});
    int64_t nowUsec = [_audioPlayer currentAudioTimeUsec];
    if (ptsUsec > nowUsec)
      {
	usleep((unsigned int)(ptsUsec - nowUsec));
      }
    }
}

- (void) drawRect: (NSRect)dirtyRect
{
  [super drawRect: dirtyRect];
  if (_currentFrame)
    {
      [_currentFrame drawInRect: [self bounds]];
    }
}

- (void) setMovie: (NSMovie*)movie
{
  [self resetDecoder];
  [super setMovie: movie];
  [self prepareDecoder];
}

- (void) start: (id)sender
{
  [super start: sender];
  [self setRate: 1.0 / 30.0];
  [self setVolume: 1.0];

  _decodeTimer =
    [NSTimer scheduledTimerWithTimeInterval: [self rate]
				     target: self
				   selector: @selector(decodeAndDisplayNextFrame)
				   userInfo: nil
				    repeats: YES];
}

- (void) stop: (id)sender
{
  [super stop: sender];

  if (_decodeTimer)
    {
      [_decodeTimer invalidate];
      RELEASE(_decodeTimer);
      _decodeTimer = nil;
    }

  if (_avframe)
    {
      av_frame_free(&_avframe);
      _avframe = NULL;
    }

  if (_avframeRGB)
    {
      av_frame_free(&_avframeRGB);
      _avframeRGB = NULL;
    }

  if (_buffer)
    {
      av_free(_buffer);
      _buffer = NULL;
    }

  if (_codecContext)
    {
      avcodec_free_context(&_codecContext);
      _codecContext = NULL;
    }

  if (_formatContext)
    {
      avformat_close_input(&_formatContext);
      _formatContext = NULL;
    }

  if (_swsCtx)
    {
      sws_freeContext(_swsCtx);
      _swsCtx = NULL;
    }
}

- (void) setVolume: (float)volume
{
  [super setVolume: volume];
  [_audioPlayer setVolume: volume];
}

- (NSRect) movieRect
{
  return NSMakeRect(0.0, 0.0,
		    (float)_codecContext->width,
		    (float)_codecContext->height);
}

@end
