/*
 * ts_types.h — NeXT typedstream object model.
 *
 * The tree stores decoded values *plus the wire decisions that produced
 * them* (integer width, literal-vs-back-reference, table order). That is
 * what makes byte-identical re-encoding attainable: the writer replays
 * choices instead of re-deriving them, since several byte sequences can
 * decode to the same logical value.
 */
#ifndef TS_TYPES_H
#define TS_TYPES_H

#include <stddef.h>
#include <stdint.h>

/* ---- container tags (signed head byte) -------------------------------- */
#define TS_TAG_FIRST          (-128)
#define TS_TAG_INTEGER_2      (-127)
#define TS_TAG_INTEGER_4      (-126)
#define TS_TAG_FLOATING_POINT (-125)
#define TS_TAG_NEW            (-124)
#define TS_TAG_NIL            (-123)
#define TS_TAG_END_OF_OBJECT  (-122)
#define TS_TAG_LAST           (-111)
#define TS_REF_FIRST          (-110)   /* head byte -110 == reference #0 */
/* "this reference has no recorded wire number": authored XML, where the
 * encoder assigns instead of verifying. */
#define TS_REF_UNKNOWN        0xFFFFFFFFu

#define TS_STREAMER_OLD        3
#define TS_STREAMER_CURRENT    4

/* ---- how an integer was written (replayed verbatim) ------------------- */
typedef enum {
    TS_INT_INLINE = 0,   /* small value carried in the head byte */
    TS_INT_16,           /* TS_TAG_INTEGER_2 + 2 bytes           */
    TS_INT_32            /* TS_TAG_INTEGER_4 + 4 bytes           */
} ts_int_width;

/* ---- value kinds ------------------------------------------------------ */
typedef enum {
    TS_V_NIL = 0,
    TS_V_INT,
    TS_V_FLOAT,
    TS_V_DOUBLE,
    TS_V_BYTE,        /* c/C — raw single byte, not tag-encoded */
    TS_V_STRING,      /* '+' unshared string: length + bytes    */
    TS_V_SHARED,      /* '%' shared string / atom               */
    TS_V_SELECTOR,    /* ':' selector (shared string)           */
    TS_V_CSTR,        /* '*' C string (shared)                  */
    TS_V_OBJECT,      /* '@'                                    */
    TS_V_CLASS,       /* '#'                                    */
    TS_V_ARRAY,       /* [N type]                               */
    TS_V_STRUCT       /* {name=types}                           */
} ts_vkind;

struct ts_object;
struct ts_class;
struct ts_value;

/* A shared string as it sits in the stream: either written literally
 * (the first time) or referenced. `text` is owned by the string table. */
typedef struct {
    const char *text;     /* NUL-terminated view into the table   */
    size_t      len;
    int         was_ref;  /* referenced rather than written out   */
    uint32_t    ref;      /* reference number when was_ref        */
    int         wrapped;  /* '*' as the NEXTSTEP-era streamer writes it:
                             1 = NEW then a shared string (NEW len bytes,
                                 or a shared-string ref); the NEW takes a
                                 number in the object/class table;
                             2 = a plain reference to such a wrapper
                                 (object-table number in `ref`);
                             0 = OPENSTEP style, shared string only */
} ts_sharedref;

typedef struct ts_value {
    ts_vkind kind;
    union {
        struct { int64_t v; ts_int_width iw; } i;
        float  f;
        double d;
        uint8_t byte;
        struct { char *p; size_t n; ts_int_width lw; } str;  /* '+' */
        ts_sharedref shared;                                  /* % : * */
        struct { struct ts_object *o; int was_ref; uint32_t ref; } obj;
        struct { struct ts_class  *c; int was_ref; uint32_t ref; } cls;
        struct { struct ts_value *v; size_t n; } list;        /* array/struct */
    } u;
    /* For arrays/structs: the element/field encoding, owned here. */
    char *sub_encoding;
    size_t byte_off;       /* offset in the source file — diagnosis only */
} ts_value;

/* One encodeValuesOfObjCTypes: call — an encoding string then its values. */
typedef struct {
    ts_sharedref encoding;   /* the type-encoding string */
    ts_value    *vals;
    size_t       nvals;
    size_t       byte_off;
} ts_group;

typedef struct ts_class {
    ts_sharedref name;
    int64_t      version;
    ts_int_width version_iw;
    struct ts_class *super;   /* chain; NULL after the last */
    int          super_is_nil;/* chain ended with NIL vs a reference */
    uint32_t     id;          /* decode order */
    size_t       byte_off;
} ts_class;

typedef struct ts_object {
    ts_class *cls;
    ts_group *groups;
    size_t    ngroups;
    uint32_t  id;             /* decode order — stable identity for XML */
    size_t    byte_off;
    size_t    byte_end;
} ts_object;

/* Whole archive. */
typedef struct {
    uint8_t      streamer_version;
    char         signature[16];   /* "streamtyped" or "typedstream" */
    int          big_endian;
    int64_t      system_version;
    ts_int_width system_version_iw;

    ts_group    *root;            /* top-level typed value group(s) */
    size_t       nroot;

    /* Ownership pools — freed by GSOpenStepTSFree(). */
    void        *pool;
} ts_archive;

#endif /* TS_TYPES_H */
