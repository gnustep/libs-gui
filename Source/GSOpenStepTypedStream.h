/* Internal representation of an OPENSTEP typed stream. */
#ifndef GS_OPENSTEP_TYPED_STREAM_H
#define GS_OPENSTEP_TYPED_STREAM_H

#include <stddef.h>
#include <stdint.h>

typedef enum {
  TS_V_NIL, TS_V_INT, TS_V_FLOAT, TS_V_DOUBLE, TS_V_BYTE,
  TS_V_STRING, TS_V_SHARED, TS_V_SELECTOR, TS_V_CSTR,
  TS_V_OBJECT, TS_V_CLASS, TS_V_ARRAY, TS_V_STRUCT
} ts_vkind;

typedef struct ts_class ts_class;
typedef struct ts_object ts_object;
typedef struct ts_value ts_value;

typedef struct { const char *text; size_t len; } ts_sharedref;

struct ts_value {
  ts_vkind kind;
  union {
    struct { int64_t v; } i;
    float f;
    double d;
    uint8_t byte;
    struct { char *p; size_t n; } str;
    ts_sharedref shared;
    struct { ts_object *o; } obj;
    struct { ts_class *c; } cls;
    struct { ts_value *v; size_t n; } list;
  } u;
  char *sub_encoding;
  size_t byte_off;
};

typedef struct {
  ts_sharedref encoding;
  ts_value *vals;
  size_t nvals;
  size_t byte_off;
} ts_group;

struct ts_class {
  ts_sharedref name;
  int64_t version;
  ts_class *super;
  uint32_t id;
  size_t byte_off;
};

struct ts_object {
  ts_class *cls;
  ts_group *groups;
  size_t ngroups;
  uint32_t id;
  size_t byte_off;
  size_t byte_end;
};

typedef struct {
  uint8_t streamer_version;
  char signature[16];
  int big_endian;
  int64_t system_version;
  ts_group *root;
  size_t nroot;
  void *pool;
} ts_archive;

typedef struct { char msg[256]; size_t off; int ok; } ts_err;

ts_archive *GSOpenStepTSReadMemory(const uint8_t *bytes, size_t length,
                                   ts_err *error);
void GSOpenStepTSFree(ts_archive *archive);
int GSOpenStepTSTypeSpan(const char *encoding);
int GSOpenStepTSTypeCount(const char *encoding);

#endif
