/*
copyright 2026 Free Software Foundation, Inc.

Tests for the PCMGain software-gain helpers.
*/

#include "Testing.h"

#include <Foundation/Foundation.h>
#include "PCMGain.h"

/* Build a signed little-endian sample of n bytes. */
static void putLE(uint8_t *p, int n, int32_t v)
{
  uint32_t u = (uint32_t)v;
  int i;
  for (i = 0; i < n; i++)
    {
      p[i] = (uint8_t)((u >> (8 * i)) & 0xff);
    }
}

/* Build a signed big-endian sample of n bytes. */
static void putBE(uint8_t *p, int n, int32_t v)
{
  uint32_t u = (uint32_t)v;
  int i;
  for (i = 0; i < n; i++)
    {
      p[i] = (uint8_t)((u >> (8 * (n - 1 - i))) & 0xff);
    }
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("PCMGain software gain");

  /* 16-bit little-endian: 1000 * 0.5 == 500 */
  {
    uint8_t in[4];
    uint8_t out[4];
    putLE(in + 0, 2, 1000);
    putLE(in + 2, 2, -2000);
    putLE(out + 0, 2, 0);
    putLE(out + 2, 2, 0);
    PCMGainApply(in, 4, 16, NO, 0.5f, out);
    pass(/* 1000 -> 500 */ (out[0] == 0xF4 && out[1] == 0x01)
         && /* -2000 -> -1000 */
            (out[2] == (uint8_t)0x18 && out[3] == (uint8_t)0xFC),
         "16-bit LE scales by 0.5");
  }

  /* 16-bit big-endian: 1000 * 0.5 == 500 */
  {
    uint8_t in[4];
    uint8_t out[4];
    putBE(in + 0, 2, 1000);
    putBE(out + 0, 2, 0);
    PCMGainApply(in, 2, 16, YES, 0.5f, out);
    pass(out[0] == 0x01 && out[1] == 0xF4,
         "16-bit BE scales by 0.5");
  }

  /* 8-bit: -100 * 0.5 == -50 */
  {
    uint8_t in[2];
    uint8_t out[2];
    in[0] = (uint8_t)-100;
    in[1] = (uint8_t)100;
    out[0] = 0; out[1] = 0;
    PCMGainApply(in, 2, 8, NO, 0.5f, out);
    pass(out[0] == (uint8_t)-50 && out[1] == (uint8_t)50,
         "8-bit scales by 0.5");
  }

  /* 32-bit little-endian: 1000000 * 0.5 == 500000 */
  {
    uint8_t in[8];
    uint8_t out[8];
    putLE(in, 4, 1000000);
    putLE(in + 4, 4, -1000000);
    memset(out, 0, 8);
    PCMGainApply(in, 8, 32, NO, 0.5f, out);
    pass(/* 500000 == 0x07A120 */
         (out[0] == 0x20 && out[1] == 0xA1 && out[2] == 0x07 && out[3] == 0x00)
         && /* -500000 */
            (out[4] == (uint8_t)0xE0 && out[5] == (uint8_t)0x5E
             && out[6] == (uint8_t)0xF8 && out[7] == (uint8_t)0xFF),
         "32-bit LE scales by 0.5");
  }

  /* 24-bit little-endian: 1000 * 0.5 == 500, -1000 * 0.5 == -500 */
  {
    uint8_t in[6];
    uint8_t out[6];
    putLE(in, 3, 1000);
    putLE(in + 3, 3, -1000);
    memset(out, 0, 6);
    PCMGainApply(in, 6, 24, NO, 0.5f, out);
    pass(/* 500 == 0x0001F4 */ (out[0] == 0xF4 && out[1] == 0x01 && out[2] == 0x00)
         && /* -500 */
            (out[3] == 0x0C && out[4] == 0xFE && out[5] == 0xFF),
         "24-bit LE scales by 0.5");
  }

  /* vol >= 1.0 copies bytes unchanged to a different buffer */
  {
    uint8_t in[4];
    uint8_t out[4];
    putLE(in, 2, 1234);
    out[0] = 0xAA; out[1] = 0xBB; out[2] = 0xCC; out[3] = 0xDD;
    PCMGainApply(in, 4, 16, NO, 1.0f, out);
    pass(memcmp(in, out, 4) == 0, "vol 1.0 copies to out buffer");
  }

  /* vol 0.0 zeroes the samples */
  {
    uint8_t in[4];
    uint8_t out[4];
    putLE(in, 2, 1234);
    putLE(in + 2, 2, -1234);
    memset(out, 0xFF, 4);
    PCMGainApply(in, 4, 16, NO, 0.0f, out);
    pass(out[0] == 0 && out[1] == 0 && out[2] == 0 && out[3] == 0,
         "vol 0.0 zeroes samples");
  }

  /* in-place scaling modifies the source buffer */
  {
    uint8_t buf[4];
    putLE(buf, 2, 1000);
    putLE(buf + 2, 2, -1000);
    PCMGainApply(buf, 4, 16, NO, 0.5f, buf);
    pass(buf[0] == 0xF4 && buf[1] == 0x01
         && buf[2] == 0x0C && buf[3] == (uint8_t)0xFE,
         "in-place scaling modifies source");
  }

  END_SET("PCMGain software gain");

  DESTROY(arp);
  return 0;
}
