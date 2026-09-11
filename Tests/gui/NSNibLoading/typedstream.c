/* Standalone binary decoder regression test; also run with ASan/UBSan.
 * cc -ISource -fsanitize=address,undefined Tests/gui/NSNibLoading/typedstream.c
 *    Source/GSOpenStep/ts_read.c -o /tmp/typedstream-test
 * /tmp/typedstream-test Tests/gui/NSNibLoading/OpenStepFixtures/objects-v4-le.nib
 */
#include "GSOpenStep/ts_read.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void parse(const unsigned char *bytes, size_t n)
{
  ts_err error;
  ts_archive *a = GSOpenStepTSReadMemory(bytes, n, &error);
  if (a == NULL) assert(!error.ok && error.off <= n && error.msg[0]);
  else { assert(error.ok); GSOpenStepTSFree(a); }
}

int main(int argc, char **argv)
{
  FILE *f;
  long length;
  unsigned char *bytes, *copy;
  size_t i, j;
  unsigned random = 12345;
  const unsigned char huge[] = "\4\13streamtyped\1\204\27[999999999999999999999i]";
  f = fopen(argc > 1 ? argv[1] : "OpenStepFixtures/objects-v4-le.nib", "rb");
  if (!f && argc == 1) f = fopen("../OpenStepFixtures/objects-v4-le.nib", "rb");
  assert(f);
  assert(!fseek(f, 0, SEEK_END)); length = ftell(f); assert(length > 0);
  rewind(f);
  bytes = malloc((size_t)length); copy = malloc((size_t)length); assert(bytes && copy);
  assert(fread(bytes, 1, (size_t)length, f) == (size_t)length); fclose(f);
  for (i = 0; i <= (size_t)length; i++) parse(bytes, i);
  for (i = 0; i < (size_t)length; i++)
    for (j = 0; j < 256; j += 17)
      { memcpy(copy, bytes, (size_t)length); copy[i] = (unsigned char)j; parse(copy, (size_t)length); }
  for (i = 0; i < 10000; i++)
    {
      for (j = 0; j < 64 && j < (size_t)length; j++)
        { random = random * 1664525u + 1013904223u; copy[j] = random >> 24; }
      parse(copy, (size_t)length < 64 ? (size_t)length : 64);
    }
  parse(huge, sizeof huge - 1);
  {
    char nested[300];
    memset(nested, '^', sizeof nested); nested[sizeof nested - 1] = 0;
    assert(GSOpenStepTSTypeSpan(nested) == -1);
  }
  free(bytes); free(copy);
  puts("typedstream: truncation, mutation, random input and encoding limits passed");
  return 0;
}
