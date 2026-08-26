/* 
   AudioOutputSink.m

   Sink audio data to the Open Sound System

   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by:  David Chisnall <theraven@sucs.org>
   Date: Jun 2009
   
   This file is part of the GNUstep GUI Library.

*/ 

#import <Foundation/Foundation.h>
#import <GNUstepGUI/GSSoundSource.h>
#import <GNUstepGUI/GSSoundSink.h>

#include "PCMGain.h"

#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/soundcard.h>


#if SOUND_VERSION >= 0x040000 
#define OSS_V4
#endif


@interface GSOSSSoundSink : NSObject <GSSoundSink>
{
	NSString *devicePath;
	int dev;
	int channels;
	int format;
	int rate;
	/* Software gain applied to samples; never the device play volume */
	float volume;
	void *gainBuffer;
	size_t gainBufferSize;
}
@end

const static NSString *DefaultDevice = @"/dev/dsp";

@implementation GSOSSSoundSink
+ (BOOL)canInitWithPlaybackDevice: (NSString *)playbackDevice
{
	if (NULL == playbackDevice)
	{
		playbackDevice = DefaultDevice;
	}
	const char *device = [playbackDevice UTF8String];
	BOOL success = NO;
	int d = open(device, O_WRONLY, 0);
	if (-1 != d)
	{
		int ver;
		/* Check that this is an OSS device by trying an OSS ioctl on it */
		success = (-1 != ioctl(d, OSS_GETVERSION, &ver));
		close(d);
	}
	return success;
}
- (BOOL)configureDevice
{
	/* Close the device if it's open already. */
	[self close];

	/* Open the device */
	if (-1 == (dev = open([devicePath UTF8String], O_WRONLY, 0)))
	{
		return NO;
	}

	/* Set the number of channels */
	if (-1 == ioctl(dev, SNDCTL_DSP_CHANNELS, &channels))
	{
		[self close];
		return NO;
	}

	/* Set the sample format. */
	if (-1 == ioctl(dev, SNDCTL_DSP_SETFMT, &format))
	{
		[self close];
		return NO;
	}

	if (-1 == ioctl(dev, SNDCTL_DSP_SPEED, &rate))
	{
		[self close];
		return NO;
	}

	return YES;
}


- (id)initWithEncoding: (int)encoding
              channels: (NSUInteger)channelCount
            sampleRate: (NSUInteger)sampleRate
             byteOrder: (NSByteOrder)byteOrder
{
	if (nil == (self = [super init])) { return nil; }

	dev = -1;
	volume = 1.0f;
	gainBuffer = NULL;
	gainBufferSize = 0;
	channels = channelCount;
	rate = sampleRate;

	switch (encoding)
	{
		case GSSoundFormatPCMS8:
			format = AFMT_S8;
			break;

		case GSSoundFormatPCM16:
			switch (byteOrder)
			{
				case NS_LittleEndian:
					format = AFMT_S16_LE;
					break;
				case NS_BigEndian:
					format = AFMT_S16_BE;
					break;
				default:
					format = AFMT_S16_NE;
			}
			break;

		case GSSoundFormatPCM24:
			switch (byteOrder)
			{
				case NS_LittleEndian:
					format = AFMT_S24_LE;
					break;
				case NS_BigEndian:
					format = AFMT_S24_BE;
					break;
				default:
					format = AFMT_S24_NE;
			}
			break;

		case GSSoundFormatPCM32:
			switch (byteOrder)
			{
				case NS_LittleEndian:
					format = AFMT_S32_LE;
					break;
				case NS_BigEndian:
					format = AFMT_S32_BE;
					break;
				default:
					format = AFMT_S32_NE;
			}
			break;

		case GSSoundFormatFloat32: 
/* Some OSS implementations (e.g. FreeBSD) don't support AFMT_FLOAT)
 * Fall through to unsupported formats if this is one of them.
 */
#ifdef AFMT_FLOAT 
			format = AFMT_FLOAT;
			break;
#endif

		/* Does this even exist? */
		case GSSoundFormatFloat64:
		default:
			[self release];
			return nil;
	}
  
	/* Try to initialise this device */
	if (![self configureDevice])
	{
		[self release];
		return nil;
	}
  
  return self;
}

- (BOOL)open
{
  return [self configureDevice];
}

- (void)close
{
	if (-1 != dev)
	{
		close(dev);
		dev = -1;
	}
}

- (void)dealloc
{
	[self close];
	free(gainBuffer);
	DESTROY(devicePath);
	[super dealloc];
}

- (BOOL)playBytes: (void*)bytes length: (NSUInteger)length
{
	/* Volume fades must lower the sample amplitude itself, so scale
	   the PCM data instead of touching the OSS play volume. */
	void *out = bytes;

	if (volume < 1.0f)
	{
		int bits;
		BOOL be;

		switch (format)
		{
			case AFMT_S8:			bits = 8;  be = NO; break;
			case AFMT_S16_LE:		bits = 16; be = NO; break;
			case AFMT_S16_BE:		bits = 16; be = YES; break;
			case AFMT_S24_LE:		bits = 24; be = NO; break;
			case AFMT_S24_BE:		bits = 24; be = YES; break;
			case AFMT_S32_LE:		bits = 32; be = NO; break;
			case AFMT_S32_BE:		bits = 32; be = YES; break;
			default:
				/* AFMT_S*_NE aliases map to a LE/BE case above on
				   most platforms; fall back to 16-bit little-endian. */
				bits = 16; be = NO; break;
		}

		if (gainBufferSize < length)
		{
			void *nb = realloc(gainBuffer, length);
			if (nb != NULL)
			{
				gainBuffer = nb;
				gainBufferSize = length;
			}
		}
		if (gainBuffer != NULL)
		{
			PCMGainApply(bytes, length, bits, be, volume, gainBuffer);
			out = gainBuffer;
		}
	}

	do 
	{
		int written = write(dev, out, (size_t)length);
		if (-1 == written)
		{
			return NO;
		}
		length -= written;
		out += written;
	} while (length > 0);
	return YES;
}

/* Software gain on the samples, not the OSS mixer */
- (void)setVolume: (float)v
{
	if (v < 0.0f)
	{
		v = 0.0f;
	}
	else if (v > 1.0f)
	{
		v = 1.0f;
	}
	volume = v;
}

- (float)volume
{
	return volume;
}

- (void)setPlaybackDeviceIdentifier: (NSString*)playbackDeviceIdentifier
{
	ASSIGN(devicePath, playbackDeviceIdentifier);
	[self configureDevice];
}

- (NSString*)playbackDeviceIdentifier
{
	return devicePath;
}
/* Not implemented */
- (void)setChannelMapping: (NSArray*)channelMapping { return; }
- (NSArray*)channelMapping { return nil; }

@end

