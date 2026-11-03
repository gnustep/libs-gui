/* 
   AudioOutputSink.m

   Sink audio data to libao.

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
#include <GNUstepGUI/GSSoundSource.h>
#include <GNUstepGUI/GSSoundSink.h>
#include <ao/ao.h>

#include "PCMGain.h"

@interface AudioOutputSink : NSObject <GSSoundSink>
{
  ao_device *_dev;
  int _driver;
  ao_sample_format _format;
  /* Software gain applied to samples in playBytes; never a mixer */
  float _volume;
  void *_gainBuffer;
  NSUInteger _gainBufferSize;
}
@end

@implementation AudioOutputSink

+ (void) initialize
{
  /* FIXME: According to the docs, this needs a corresponding ao_shutdown(). */
  ao_initialize ();
}

+ (BOOL)canInitWithPlaybackDevice: (NSString *)playbackDevice
{
  // This is currently the only sink in NSSound, just say
  // YES to everything.
  /* FIXME: What is OS X's identifier for the main sound? */
  return (playbackDevice == nil ? YES : NO);
}

- (void)dealloc
{
  free(_gainBuffer);
  _gainBuffer = NULL;
  _gainBufferSize = 0;
  [super dealloc];
}

- (id)initWithEncoding: (int)encoding
              channels: (NSUInteger)channelCount
            sampleRate: (NSUInteger)sampleRate
             byteOrder: (NSByteOrder)byteOrder
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }
  
  _format.channels = (int)channelCount;
  _format.rate = (int)sampleRate;
  _volume = 1.0;
  _gainBuffer = NULL;
  _gainBufferSize = 0;
  
  switch (encoding)
    {
      case GSSoundFormatPCMS8:
        _format.bits = 8;
        break;
      
      case GSSoundFormatPCM16:
        _format.bits = 16;
        break;
      
      case GSSoundFormatPCM24:
        _format.bits = 24;
        break;
      
      case GSSoundFormatPCM32:
        _format.bits = 32;
        break;
      
      case GSSoundFormatFloat32: // Float and double not supported by libao.
      case GSSoundFormatFloat64:
      default:
        DESTROY(self);
        return nil;
    }
  
	if (byteOrder == NS_LittleEndian)
	  {
	    _format.byte_format = AO_FMT_LITTLE;
    }
  else if (byteOrder == NS_BigEndian)
    {
      _format.byte_format = AO_FMT_BIG;
    }
  else
    {
      _format.byte_format = AO_FMT_NATIVE;
    }

  return self;
}

- (BOOL)open
{
  _driver = ao_default_driver_id();
  
  _dev = ao_open_live(_driver, &_format, NULL);
  return ((_dev == NULL) ? NO : YES);
}

- (void)close
{
  ao_close(_dev);
}

- (BOOL)playBytes: (void *)bytes length: (NSUInteger)length
{
  void *out = bytes;
  int ret;

  /* Fade/volume is done by scaling the samples (amplitude), so it
     stays independent of any system mixer settings. */
  if (_volume < 1.0f)
    {
      BOOL be;
      int bits = _format.bits;

      switch (_format.byte_format)
        {
          case AO_FMT_BIG:
            be = YES;
            break;
          case AO_FMT_LITTLE:
            be = NO;
            break;
          default:
            /* AO_FMT_NATIVE depends on the host byte order. */
            be = (NSHostByteOrder() == NS_BigEndian);
            break;
        }

      if (_gainBufferSize < length)
        {
          void *nb = realloc(_gainBuffer, length);
          if (nb != NULL)
            {
              _gainBuffer = nb;
              _gainBufferSize = length;
            }
        }
      /* If we could not allocate a scratch buffer, play unscaled. */
      if (_gainBuffer != NULL && _gainBufferSize >= length)
        {
          PCMGainApply(bytes, length, bits, be, _volume, _gainBuffer);
          out = _gainBuffer;
        }
    }

  ret = ao_play(_dev, out, (uint_32)length);
  return (ret == 0 ? NO : YES);
}

/* Volume as software gain on the samples, not a device/mixer change */
- (void)setVolume: (float)volume
{
  if (volume < 0.0f)
    {
      volume = 0.0f;
    }
  else if (volume > 1.0f)
    {
      volume = 1.0f;
    }
  _volume = volume;
}

- (float)volume
{
  return _volume;
}

- (void)setPlaybackDeviceIdentifier: (NSString *)playbackDeviceIdentifier
{
  return;
}

- (NSString *)playbackDeviceIdentifier
{
  return nil;
}

- (void)setChannelMapping: (NSArray *)channelMapping
{
  return;
}

- (NSArray *)channelMapping
{
  return nil;
}

@end

