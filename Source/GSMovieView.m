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
#import <Foundation/NSURL.h>

#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSMovie.h"
#import "AppKit/NSPasteboard.h"

#import "GSMovieView.h"

@interface FFmpegAudioPlayer : NSObject
{
  AVCodecContext *audioCodecCtx;
  AVFrame *audioFrame;
  SwrContext *swrCtx;
}

- (void)prepareAudioWithFormatContext:(AVFormatContext *)formatCtx streamIndex:(int)audioStreamIndex;
- (void)decodeAudioPacket:(AVPacket *)packet;

@end

@implementation FFmpegAudioPlayer
- (void)prepareAudioWithFormatContext:(AVFormatContext *)formatCtx streamIndex:(int)audioStreamIndex
{
  AVCodecParameters *audioPar = formatCtx->streams[audioStreamIndex]->codecpar;
  AVCodec *audioCodec = avcodec_find_decoder(audioPar->codec_id);
  if (!audioCodec)
    {
      NSLog(@"Audio codec not found.");
      return;
    }
  audioCodecCtx = avcodec_alloc_context3(audioCodec);
  avcodec_parameters_to_context(audioCodecCtx, audioPar);
  if (avcodec_open2(audioCodecCtx, audioCodec, NULL) < 0)
    {
      NSLog(@"Failed to open audio codec.");
      return;
    }

  audioFrame = av_frame_alloc();
  swrCtx = swr_alloc_set_opts(NULL,
			      AV_CH_LAYOUT_STEREO,
			      AV_SAMPLE_FMT_S16,
			      audioCodecCtx->sample_rate,
			      audioCodecCtx->channel_layout,
			      audioCodecCtx->sample_fmt,
			      audioCodecCtx->sample_rate,
			      0, NULL);
  swr_init(swrCtx);

  NSLog(@"Audio codec: %s, Sample rate: %d, Channels: %d",
	audioCodec->name,
	audioPar->sample_rate,
	audioPar->channels);
}

- (void)decodeAudioPacket:(AVPacket *)packet
{
  if (!audioCodecCtx || !swrCtx) return;
  if (avcodec_send_packet(audioCodecCtx, packet) < 0) return;
  while (avcodec_receive_frame(audioCodecCtx, audioFrame) == 0)
    {
      int outSamples = audioFrame->nb_samples;
      int outBytes = av_samples_get_buffer_size(NULL, 2, outSamples, AV_SAMPLE_FMT_S16, 1);
      uint8_t *outBuf = (uint8_t *)malloc(outBytes);
      uint8_t *outPtrs[] = { outBuf };
      
      swr_convert(swrCtx, outPtrs, outSamples,
		  (const uint8_t **)audioFrame->data, outSamples);
      
      [audioBuffer appendBytes:outBuf length:outBytes];
      free(outBuf);
    }
}

- (void)finalizeAndPlayBuffer
{
  int sampleRate = audioCodecCtx->sample_rate;
  int outBytes = (int)[audioBuffer length];
  int byteRate = sampleRate * 2 * 2;
  int blockAlign = 2 * 2;
  
  NSMutableData *wav = [NSMutableData data];
  [wav appendBytes:"RIFF" length:4];
  uint32_t chunkSize = 36 + outBytes;
  [wav appendBytes:&chunkSize length:4];
  [wav appendBytes:"WAVEfmt " length:8];
  
  uint32_t subchunk1Size = 16;
  [wav appendBytes:&subchunk1Size length:4];
  uint16_t audioFormat = 1, numChannels = 2, bitsPerSample = 16;
  [wav appendBytes:&audioFormat length:2];
  [wav appendBytes:&numChannels length:2];
  [wav appendBytes:&sampleRate length:4];
  [wav appendBytes:&byteRate length:4];
  [wav appendBytes:&blockAlign length:2];
  [wav appendBytes:&bitsPerSample length:2];
  
  [wav appendBytes:"data" length:4];
  [wav appendBytes:&outBytes length:4];
  [wav appendData:audioBuffer];
  
  sound = [[NSSound alloc] initWithData:wav];
  [sound play];
}

- (void)dealloc
{
  if (audioFrame) av_frame_free(&audioFrame);
  if (audioCodecCtx) avcodec_free_context(&audioCodecCtx);
  if (swrCtx) swr_free(&swrCtx);
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
    }
  return self;
}

- (void) dealloc
{
  [self stop: nil];
  RELEASE(_currentFrame);
  [super dealloc];
}

- (void)logStreamMetadata
{
  AVStream *vs = formatContext->streams[videoStreamIndex];
  double duration = (double)formatContext->duration / AV_TIME_BASE;
  NSString *info = [NSString stringWithFormat:@"Video: %dx%d %@ %.2fs",
			     codecContext->width,
			     codecContext->height,
			     [NSString stringWithUTF8String:avcodec_get_name(codecContext->codec_id)],
			     duration];
  [metadataLabel setStringValue:info];
  NSLog(@"%@", info);

  if (audioStreamIndex != -1)
    {
      AVCodecParameters *ap = formatContext->streams[audioStreamIndex]->codecpar;
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
      AVMediaType type = formatContext->streams[i]->codecpar->codec_type;
      if (type == AVMEDIA_TYPE_VIDEO && _videoStreamIndex == -1)
	{
	  _videoStreamIndex = i;
	}
      else if (type == AVMEDIA_TYPE_AUDIO && _audioStreamIndex == -1)
	{
	  _audioStreamIndex = i;
	}
    }

  if (_videoStreamIndex == -1) return;

  AVCodecParameters *codecPar = _formatContext->streams[_videoStreamIndex]->codecpar;
  const AVCodec *codec = avcodec_find_decoder(codecPar->codec_id);

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
	      // AUTORELEASE(image);
	      AUTORELEASE(rep);

	      break;
	    }
	}
    av_packet_unref(&packet);
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

@end
