/*
 * ts_read.h — typedstream decoder.
 *
 * Parses untrusted bytes: every read is bounds-checked and any anomaly
 * stops decoding with a message and the offset, rather than guessing.
 * A decode that silently stops early would look correct until the
 * round-trip gate, so GSOpenStepTSReadMemory() also requires that the whole file
 * was consumed.
 */
#ifndef TS_READ_H
#define TS_READ_H

#include "ts_types.h"

typedef struct {
    char   msg[256];
    size_t off;        /* byte offset where it went wrong */
    int    ok;
} ts_err;

/* Decode a whole archive. Returns NULL on failure with *err filled in.
 * Requires that decoding consumes exactly `len` bytes. */
ts_archive *GSOpenStepTSReadMemory(const uint8_t *buf, size_t len, ts_err *err);

void GSOpenStepTSFree(ts_archive *a);

/* Type-encoding walker, shared by reader, writer and dumper.
 * Returns the number of values the encoding describes, or -1 if the
 * encoding contains a construct we do not handle (fail safe: the caller
 * aborts the decode instead of mis-parsing the rest of the stream). */
int GSOpenStepTSTypeCount(const char *enc);

/* Byte length of one complete type at `p`, or -1 if unhandled. */
int GSOpenStepTSTypeSpan(const char *p);

#endif /* TS_READ_H */
