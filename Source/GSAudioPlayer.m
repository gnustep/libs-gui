/** <title>GSAudioPlayer</title>

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

#import "GSAudioPlayer.h"
#import "GSAVUtils.h"

@implementation GSAudioPlayer
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _audioCodecCtx = NULL;
      _audioFrame = NULL;
      _swrCtx = NULL;
      _audioClock = 0;
      _volume = 1.0;
    }
  return self;
}

- (void)dealloc
{
  if (_audioFrame)
    {
      av_frame_free(&_audioFrame);
    }

  if (_audioCodecCtx)
    {
      avcodec_free_context(&_audioCodecCtx);
    }

  if (_swrCtx)
    {
      swr_free(&_swrCtx);
    }

  if (_aoDev)
    {
      ao_close(_aoDev);
    }

  ao_shutdown();
  [super dealloc];
}

- (void) prepareWithFormatContext: (AVFormatContext *)formatCtx
		      streamIndex: (int)audioStreamIndex
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
  int r = swr_init(_swrCtx);
  if (r == 0)
    {
      NSLog(@"[GSAudioPlayer] WARNING: swr_init returned 0");
    }

  memset(&_aoFmt, 0, sizeof(ao_sample_format));
  _aoFmt.bits = 16;
  _aoFmt.channels = out_channels;
  _aoFmt.rate = _audioCodecCtx->sample_rate;
  _aoFmt.byte_format = AO_FMT_NATIVE;

  _aoDev = ao_open_live(driver, &_aoFmt, NULL);
  _timeBase = formatCtx->streams[audioStreamIndex]->time_base;
  _audioClock = av_gettime();
  _running = YES;
}

- (void)decodePacket: (AVPacket *)packet
{
  if (!_audioCodecCtx || !_swrCtx || !_aoDev)
    {
      return;
    }

  if (avcodec_send_packet(_audioCodecCtx, packet) < 0)
    {
      return;
    }

  if (packet->flags & AV_PKT_FLAG_CORRUPT)
    {
      NSLog(@"Skipping corrupt audio packet");
      return;
    }

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
	  if ([self isMuted])
	    {
	      samples[i] = 0.0;
	    }
	  else
	    {
	      samples[i] = samples[i] * _volume;
	    }
	}

      ao_play(_aoDev, (char *) outBuf, outBytes);
      free(outBuf);
    }
}

- (void) decodeDictionary: (NSDictionary *)dict
{
  AVPacket packet = AVPacketFromNSDictionary(dict);
  [self decodePacket: &packet];
}

- (void) setVolume: (float)volume
{
  if (volume < 0.0)
    {
      volume = 0.0;
    }

  if (volume > 1.0)
    {
      volume = 1.0;
    }

  _volume = volume;
}

- (float) volume
{
  return _volume;
}

- (void) setMuted: (BOOL)muted
{
  _muted = muted;
}

- (BOOL) isMuted
{
  return _muted;
}

@end
