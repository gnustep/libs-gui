/* 
   PCMGain.h

   Software-gain (sample scaling) helpers for NSSound sink plug-ins.

   Copyright (C) 2026 Free Software Foundation, Inc.

   Written by:  Simon Peter
   Date: 2026

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

#ifndef PCMGain_h
#define PCMGain_h

/*
 * Software-gain helpers for NSSound sink plug-ins.
 *
 * NSSound volume must change the amplitude of the samples themselves,
 * never a mixer or device-level volume, so fades stay local to the app
 * playing the sound.
 */

#include <stdint.h>
#include <string.h>

/*
 * Per-byte-count PCM accessors. Splitting the read/write paths by sample
 * size (1, 2, 3 and 4 bytes) removes the loops and byte-swap math that a
 * generic helper would run for every sample, so the gain scaling is both
 * faster and easier to follow.
 */

/* 8-bit samples have no byte order to worry about. */
static inline int32_t PCMGainRead8(const uint8_t *p)
{
  return (int32_t)(int8_t)p[0];
}

static inline int32_t PCMGainRead16(const uint8_t *p, BOOL be)
{
  uint32_t u;
  if (be)
    u = ((uint32_t)p[0] << 8) | p[1];
  else
    u = ((uint32_t)p[1] << 8) | p[0];
  /* Sign-extend the 16-bit value into a 32-bit signed integer. */
  return (int32_t)((u ^ 0x8000u) - 0x8000u);
}

static inline int32_t PCMGainRead24(const uint8_t *p, BOOL be)
{
  uint32_t u;
  if (be)
    u = ((uint32_t)p[0] << 16) | ((uint32_t)p[1] << 8) | p[2];
  else
    u = ((uint32_t)p[2] << 16) | ((uint32_t)p[1] << 8) | p[0];
  /* Sign-extend the 24-bit value into a 32-bit signed integer. */
  return (int32_t)((u ^ 0x800000u) - 0x800000u);
}

static inline int32_t PCMGainRead32(const uint8_t *p, BOOL be)
{
  uint32_t u;
  if (be)
    u = ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16)
      | ((uint32_t)p[2] << 8) | p[3];
  else
    u = ((uint32_t)p[3] << 24) | ((uint32_t)p[2] << 16)
      | ((uint32_t)p[1] << 8) | p[0];
  return (int32_t)u;
}

static inline void PCMGainWrite8(uint8_t *p, int32_t v)
{
  if (v < -128)
    v = -128;
  else if (v > 127)
    v = 127;
  p[0] = (uint8_t)(int8_t)v;
}

static inline void PCMGainWrite16(uint8_t *p, BOOL be, int32_t v)
{
  if (v < -32768)
    v = -32768;
  else if (v > 32767)
    v = 32767;
  {
    uint32_t u = (uint32_t)v;
    if (be)
      {
        p[0] = (uint8_t)(u >> 8);
        p[1] = (uint8_t)(u & 0xff);
      }
    else
      {
        p[0] = (uint8_t)(u & 0xff);
        p[1] = (uint8_t)(u >> 8);
      }
  }
}

static inline void PCMGainWrite24(uint8_t *p, BOOL be, int32_t v)
{
  if (v < -8388608)
    v = -8388608;
  else if (v > 8388607)
    v = 8388607;
  {
    uint32_t u = (uint32_t)v;
    if (be)
      {
        p[0] = (uint8_t)(u >> 16);
        p[1] = (uint8_t)(u >> 8);
        p[2] = (uint8_t)(u & 0xff);
      }
    else
      {
        p[0] = (uint8_t)(u & 0xff);
        p[1] = (uint8_t)(u >> 8);
        p[2] = (uint8_t)(u >> 16);
      }
  }
}

static inline void PCMGainWrite32(uint8_t *p, BOOL be, int32_t v)
{
  uint32_t u = (uint32_t)v;
  if (be)
    {
      p[0] = (uint8_t)(u >> 24);
      p[1] = (uint8_t)(u >> 16);
      p[2] = (uint8_t)(u >> 8);
      p[3] = (uint8_t)(u & 0xff);
    }
  else
    {
      p[0] = (uint8_t)(u & 0xff);
      p[1] = (uint8_t)(u >> 8);
      p[2] = (uint8_t)(u >> 16);
      p[3] = (uint8_t)(u >> 24);
    }
}

/*
 * Scale signed PCM data (bits = 8/16/24/32, byteFormat big-endian flag)
 * by vol into out. out may equal bytes for in-place scaling; otherwise
 * it must have room for length bytes.
 */
static inline void PCMGainApply(void *bytes, NSUInteger length, int bits,
                                BOOL be, float vol, void *out)
{
  const NSUInteger stride = (NSUInteger)(bits / 8);
  const NSUInteger count = (stride > 0) ? length / stride : 0;
  const uint8_t *src = bytes;
  uint8_t *dst = out;
  NSUInteger i;

  /* No gain to apply: copy when writing to a separate buffer. */
  if (vol >= 1.0f || stride == 0)
    {
      if (out != bytes)
        {
          memcpy(out, bytes, length);
        }
      return;
    }

  switch (bits)
    {
      case 8:
        for (i = 0; i < count; i++)
          {
            int32_t s = PCMGainRead8(src + i);
            PCMGainWrite8(dst + i, (int32_t)((float)s * vol));
          }
        break;

      case 16:
        for (i = 0; i < count; i++)
          {
            int32_t s = PCMGainRead16(src + i * 2, be);
            PCMGainWrite16(dst + i * 2, be, (int32_t)((float)s * vol));
          }
        break;

      case 24:
        for (i = 0; i < count; i++)
          {
            int32_t s = PCMGainRead24(src + i * 3, be);
            PCMGainWrite24(dst + i * 3, be, (int32_t)((float)s * vol));
          }
        break;

      case 32:
        for (i = 0; i < count; i++)
          {
            int32_t s = PCMGainRead32(src + i * 4, be);
            PCMGainWrite32(dst + i * 4, be, (int32_t)((float)s * vol));
          }
        break;

      default:
        /* Unknown sample width: leave the data untouched. */
        if (out != bytes)
          {
            memcpy(out, bytes, length);
          }
        return;
    }

  /* Copy any trailing partial frame (should not happen for valid PCM). */
  if (stride > 0 && (length % stride) && out != bytes)
    {
      memcpy(dst + count * stride, src + count * stride, length - count * stride);
    }
}

#endif /* PCMGain_h */
