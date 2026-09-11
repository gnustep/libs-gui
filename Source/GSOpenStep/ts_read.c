/*
 * ts_read.c — NeXT typedstream decoder.
 *
 * Layout of a stream:
 *   <streamer version byte> <len> "streamtyped" <system version int>
 *   then one or more typed groups: <encoding string> <value>*
 *
 * An object is  NEW · class-chain · (encoding, values)* · END_OF_OBJECT,
 * or a back-reference to an object already seen. Small integers ride in
 * the head byte; larger ones are introduced by a tag. Strings, classes
 * and objects are shared: written once, then referenced by number.
 *
 * Everything the writer needs to reproduce the exact bytes (integer
 * widths, reference-vs-literal, table order) is recorded in the tree.
 */
#include "ts_read.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- arena so the whole tree frees in one go -------------------------- */
typedef struct arena_blk {
    struct arena_blk *next;
    size_t used, cap;
    unsigned char data[1];
} arena_blk;

typedef struct {
    arena_blk *head;
    size_t allocated;
} arena;

static void *arena_alloc(arena *a, size_t n)
{
    arena_blk *b;
    size_t cap;

    if (n > 256u * 1024u * 1024u - 15u) return NULL;
    n = (n + 15u) & ~(size_t)15u;          /* keep everything aligned */
    if (n > 256u * 1024u * 1024u - a->allocated) return NULL;
    a->allocated += n;
    if (a->head && a->head->cap - a->head->used >= n) {
        void *p = a->head->data + a->head->used;
        a->head->used += n;
        return p;
    }
    cap = n > 64u * 1024u ? n : 64u * 1024u;
    b = malloc(sizeof(arena_blk) + cap);
    if (!b) return NULL;
    b->next = a->head;
    b->used = n;
    b->cap  = cap;
    a->head = b;
    return b->data;
}

static void arena_free(arena *a)
{
    arena_blk *b = a->head;
    while (b) { arena_blk *n = b->next; free(b); b = n; }
    a->head = NULL;
}

/* ---- reader state ----------------------------------------------------- */

/*
 * There are TWO independent reference-numbering spaces, established by
 * decoding the fixtures (an earlier single-table model failed on
 * frontEnd.nib at byte 109, which is how we know):
 *
 *   - shared strings: every literal shared string, including class names
 *     and type-encoding strings, in encounter order;
 *   - objects and classes: one shared sequence, in encounter order.
 *
 * frontEnd.nib pins both down. Its `94` (ref 2) appears in class-chain
 * terminator position and resolves to the NSObject *class*, while its
 * `96` (ref 4) sits where a group encoding is expected and resolves to
 * the shared string "@@".
 *
 * A reference that resolves to the wrong kind is an error rather than a
 * silent coercion, so a wrong model surfaces on the next fixture instead
 * of quietly drifting.
 */
typedef enum { SLOT_CLASS, SLOT_OBJECT, SLOT_CSTR } slot_kind;

typedef struct {
    slot_kind kind;
    union { ts_class *cls; ts_object *obj; char *cstr; } u;
} slot;

typedef struct {
    const uint8_t *buf;
    size_t len, pos;
    int    big_endian;      /* set from the signature spelling */
    arena  ar;
    ts_err *err;

    slot   *slots;          /* objects + classes share this numbering */
    size_t  nslots, cslots;

    char  **strs;           /* shared strings have their own */
    size_t  nstrs, cstrs;

    unsigned depth;
    uint32_t next_obj_id;
    uint32_t next_cls_id;
} rd;

static int fail(rd *r, size_t off, const char *fmt, ...);

static int fail(rd *r, size_t off, const char *fmt, ...)
{
    va_list ap;
    if (r->err->ok) {                     /* keep the first failure */
        va_start(ap, fmt);
        vsnprintf(r->err->msg, sizeof r->err->msg, fmt, ap);
        va_end(ap);
        r->err->off = off;
        r->err->ok  = 0;
    }
    return -1;
}

static int need(rd *r, size_t n)
{
    if (n > r->len - r->pos)
        return fail(r, r->pos, "truncated: need %zu byte(s), %zu left",
                    n, r->len - r->pos);
    return 0;
}

static int u8(rd *r, uint8_t *out)
{
    if (need(r, 1)) return -1;
    *out = r->buf[r->pos++];
    return 0;
}

static int peek_head(rd *r, int8_t *out)
{
    *out = 0;
    if (r->pos >= r->len)
        return fail(r, r->pos, "truncated: expected a head byte");
    *out = (int8_t)r->buf[r->pos];
    return 0;
}

/* ---- integers --------------------------------------------------------- */

/* Tags occupy -128..-111. The lower bound is the whole negative range of
 * int8_t, so testing it would be tautological — only the top matters. */
static int is_tag(int8_t h)
{
    return h <= TS_TAG_LAST;
}

/*
 * A tag that cannot begin a reference. Reference numbers use the integer
 * encoding, so INTEGER_2/INTEGER_4 must reach the reference path: in
 * Preference.nib byte 5852 holds `81 81 00`, i.e. int16 129, which is
 * reference #239 — just past the 0..237 that fit in a head byte.
 */
static int is_nonref_tag(int8_t h)
{
    return is_tag(h) && h != TS_TAG_INTEGER_2 && h != TS_TAG_INTEGER_4;
}

/*
 * Read an integer. Small values live in the head byte; -127/-126
 * introduce 2- and 4-byte little-endian values. `sign` selects whether
 * an inline head byte is interpreted signed (ints) or unsigned (lengths).
 */
static int rd_int(rd *r, int64_t *out, ts_int_width *iw, int sign)
{
    uint8_t b;
    int8_t h;
    size_t off = r->pos;

    if (u8(r, &b)) return -1;
    h = (int8_t)b;

    if (h == TS_TAG_INTEGER_2) {
        uint16_t v;
        if (need(r, 2)) return -1;
        v = r->big_endian
              ? (uint16_t)((uint16_t)r->buf[r->pos] << 8 | r->buf[r->pos + 1])
              : (uint16_t)((uint16_t)r->buf[r->pos + 1] << 8 | r->buf[r->pos]);
        *out = sign ? (int64_t)(int16_t)v : (int64_t)v;
        r->pos += 2;
        *iw = TS_INT_16;
        return 0;
    }
    if (h == TS_TAG_INTEGER_4) {
        uint32_t v; int i;
        if (need(r, 4)) return -1;
        v = 0;
        for (i = 0; i < 4; i++)
            v |= (uint32_t)r->buf[r->pos + i] << (8 * (r->big_endian ? 3 - i : i));
        *out = sign ? (int64_t)(int32_t)v : (int64_t)v;
        r->pos += 4;
        *iw = TS_INT_32;
        return 0;
    }
    if (is_tag(h))
        return fail(r, off, "expected an integer, found tag %d", (int)h);

    *out = sign ? (int64_t)h : (int64_t)b;
    *iw  = TS_INT_INLINE;
    return 0;
}

/* ---- shared table ----------------------------------------------------- */

static int slot_push(rd *r, slot s, uint32_t *idx)
{
    if (r->nslots == r->cslots) {
        size_t nc = r->cslots ? r->cslots * 2 : 64;
        slot *ns = realloc(r->slots, nc * sizeof *ns);
        if (!ns) return fail(r, r->pos, "out of memory");
        r->slots = ns;
        r->cslots = nc;
    }
    if (idx) *idx = (uint32_t)r->nslots;
    r->slots[r->nslots++] = s;
    return 0;
}

static int slot_get(rd *r, uint32_t ref, slot_kind want, slot *out, size_t off)
{
    if (ref >= r->nslots)
        return fail(r, off, "reference #%u out of range (%zu known)",
                    ref, r->nslots);
    if (r->slots[ref].kind != want)
        return fail(r, off, "reference #%u is a %s, expected a %s",
                    ref,
                    r->slots[ref].kind == SLOT_CLASS ? "class" :
                    r->slots[ref].kind == SLOT_CSTR ? "C string" : "object",
                    want == SLOT_CLASS ? "class" :
                    want == SLOT_CSTR ? "C string" : "object");
    *out = r->slots[ref];
    return 0;
}

/*
 * A reference number is written with the ordinary integer encoding, so
 * values beyond the inline head-byte range arrive as INTEGER_2/4. Reading
 * it as a single byte works only for small archives — Preference.nib
 * fails at byte 5852 that way.
 */
static int rd_refnum(rd *r, uint32_t *ref, ts_int_width *iw)
{
    int64_t v;
    if (rd_int(r, &v, iw, 1)) return -1;
    if (v > TS_REF_FIRST + (int64_t)0x7fffffff || v < TS_REF_FIRST)
        return fail(r, r->pos, "bad reference number %lld", (long long)v);
    *ref = (uint32_t)(v - TS_REF_FIRST);
    return 0;
}

/* Shared strings are numbered separately from objects/classes. */
static int str_push(rd *r, char *p)
{
    if (r->nstrs == r->cstrs) {
        size_t nc = r->cstrs ? r->cstrs * 2 : 64;
        char **ns = realloc(r->strs, nc * sizeof *ns);
        if (!ns) return fail(r, r->pos, "out of memory");
        r->strs = ns;
        r->cstrs = nc;
    }
    r->strs[r->nstrs++] = p;
    return 0;
}

static int str_get(rd *r, uint32_t ref, char **out, size_t off)
{
    if (ref >= r->nstrs)
        return fail(r, off, "shared string #%u out of range (%zu known)",
                    ref, r->nstrs);
    *out = r->strs[ref];
    return 0;
}

/* ---- strings ---------------------------------------------------------- */

/* An unshared string: length then raw bytes. Always written literally. */
static int rd_unshared(rd *r, char **text, size_t *len, ts_int_width *lw)
{
    int64_t n;
    char *p;

    if (rd_int(r, &n, lw, 0)) return -1;
    if (n < 0) return fail(r, r->pos, "negative string length %lld",
                           (long long)n);
    if (need(r, (size_t)n)) return -1;
    p = arena_alloc(&r->ar, (size_t)n + 1);
    if (!p) return fail(r, r->pos, "out of memory");
    memcpy(p, r->buf + r->pos, (size_t)n);
    p[n] = '\0';
    r->pos += (size_t)n;
    *text = p;
    *len  = (size_t)n;
    return 0;
}

/*
 * A shared string: NIL, or NEW followed by an unshared string (which
 * enters the table), or a back-reference to one already stored.
 */
static int rd_shared(rd *r, ts_sharedref *out)
{
    int8_t h;
    size_t off = r->pos;

    memset(out, 0, sizeof *out);
    if (peek_head(r, &h)) return -1;

    if (h == TS_TAG_NIL) {
        r->pos++;
        out->text = NULL;
        return 0;
    }
    if (h == TS_TAG_NEW) {
        char *p; size_t n; ts_int_width lw;
        r->pos++;
        if (rd_unshared(r, &p, &n, &lw)) return -1;
        if (str_push(r, p)) return -1;
        out->text = p;
        out->len  = n;
        return 0;
    }
    if (is_nonref_tag(h))
        return fail(r, off, "expected a shared string, found tag %d", (int)h);

    {
        char *p = NULL;
        uint32_t ref;
        ts_int_width riw;
        if (rd_refnum(r, &ref, &riw)) return -1;
        if (str_get(r, ref, &p, off)) return -1;
        out->text    = p;
        out->len     = strlen(p);
        out->was_ref = 1;
        out->ref     = ref;
    }
    return 0;
}

/* ---- classes ---------------------------------------------------------- */

static int rd_class(rd *r, ts_class **out);

static int rd_class_body(rd *r, ts_class **out);

static int rd_class(rd *r, ts_class **out)
{
    int result;
    if (r->depth >= 128) return fail(r, r->pos, "nesting limit exceeded");
    r->depth++;
    result = rd_class_body(r, out);
    r->depth--;
    return result;
}

static int rd_class_body(rd *r, ts_class **out)
{
    int8_t h;
    size_t off = r->pos;

    *out = NULL;
    if (peek_head(r, &h)) return -1;

    if (h == TS_TAG_NIL) {                 /* end of the superclass chain */
        r->pos++;
        return 0;
    }
    if (h == TS_TAG_NEW) {
        ts_class *c;
        slot s;
        r->pos++;
        c = arena_alloc(&r->ar, sizeof *c);
        if (!c) return fail(r, off, "out of memory");
        memset(c, 0, sizeof *c);
        c->byte_off = off;
        c->id = r->next_cls_id++;
        /* The class enters the table before its superclass is read, so
         * a self-referential chain resolves the way the writer wrote it. */
        s.kind = SLOT_CLASS;
        s.u.cls = c;
        if (slot_push(r, s, NULL)) return -1;
        if (rd_shared(r, &c->name)) return -1;
        if (!c->name.text || !c->name.len
            || strlen(c->name.text) != c->name.len)
            return fail(r, off, "missing or invalid class name");
        if (rd_int(r, &c->version, &c->version_iw, 1)) return -1;
        if (rd_class(r, &c->super)) return -1;
        c->super_is_nil = (c->super == NULL);
        *out = c;
        return 0;
    }
    if (is_nonref_tag(h))
        return fail(r, off, "expected a class, found tag %d", (int)h);

    {
        slot s;
        uint32_t ref;
        ts_int_width riw;
        if (rd_refnum(r, &ref, &riw)) return -1;
        if (slot_get(r, ref, SLOT_CLASS, &s, off)) return -1;
        *out = s.u.cls;
    }
    return 0;
}

/* ---- type encodings --------------------------------------------------- */

/* Length in bytes of one complete type at `p`, or -1 if unhandled. */
static int type_span(const char *p, unsigned depth)
{
    const char *s = p;
    int n;

    if (depth >= 64) return -1;
    switch (*p) {
    case '\0': return -1;
    case 'c': case 'C': case 's': case 'S': case 'i': case 'I':
    case 'l': case 'L': case 'q': case 'Q': case 'f': case 'd':
    case 'B': case '*': case '@': case '#': case ':': case '%':
    case '+': case '!': case 'v':
        return 1;
    case '[':                                  /* [N type] */
        p++;
        while (*p >= '0' && *p <= '9') p++;
        if (p == s + 1) return -1;             /* missing count */
        n = type_span(p, depth + 1);
        if (n < 0) return -1;
        p += n;
        if (*p != ']') return -1;
        return (int)(p - s) + 1;
    case '{': case '(': {                      /* {name=types} / (name=types) */
        char close = (*p == '{') ? '}' : ')';
        p++;
        while (*p && *p != '=' && *p != close) p++;
        if (*p == '=') {
            p++;
            while (*p && *p != close) {
                n = type_span(p, depth + 1);
                if (n < 0) return -1;
                p += n;
            }
        }
        if (*p != close) return -1;
        return (int)(p - s) + 1;
    }
    case '^':                                  /* pointer to something */
        n = type_span(p + 1, depth + 1);
        if (n < 0) return -1;
        return n + 1;
    default:
        return -1;                             /* unknown: fail safe */
    }
}

int GSOpenStepTSTypeSpan(const char *p)
{
    return type_span(p, 0);
}

int GSOpenStepTSTypeCount(const char *enc)
{
    int count = 0, n;
    if (!enc) return -1;
    while (*enc) {
        n = GSOpenStepTSTypeSpan(enc);
        if (n < 0) return -1;
        enc += n;
        count++;
    }
    return count;
}

/* ---- values ----------------------------------------------------------- */

static int rd_object(rd *r, ts_value *v);
static int rd_value(rd *r, const char *enc, ts_value *v);

static int rd_float(rd *r, ts_value *v, int is_double)
{
    int8_t h;
    size_t off = r->pos;

    if (peek_head(r, &h)) return -1;
    if (h == TS_TAG_FLOATING_POINT) {
        r->pos++;
        if (is_double) {
            uint64_t bits = 0; int i;
            if (need(r, 8)) return -1;
            for (i = 0; i < 8; i++)
                bits |= (uint64_t)r->buf[r->pos + i]
                        << (8 * (r->big_endian ? 7 - i : i));
            r->pos += 8;
            memcpy(&v->u.d, &bits, 8);
            v->kind = TS_V_DOUBLE;
        } else {
            uint32_t bits = 0; int i;
            if (need(r, 4)) return -1;
            for (i = 0; i < 4; i++)
                bits |= (uint32_t)r->buf[r->pos + i]
                        << (8 * (r->big_endian ? 3 - i : i));
            r->pos += 4;
            memcpy(&v->u.f, &bits, 4);
            v->kind = TS_V_FLOAT;
        }
        return 0;
    }
    /* Whole numbers are stored as integers even in float slots. */
    {
        int64_t iv; ts_int_width iw;
        if (rd_int(r, &iv, &iw, 1)) return fail(r, off, "bad float");
        v->kind = is_double ? TS_V_DOUBLE : TS_V_FLOAT;
        v->u.i.v = iv;                 /* remembered as an integer form */
        v->u.i.iw = iw;
        v->sub_encoding = NULL;
        v->kind = TS_V_INT;            /* replayed as the integer it was */
        return 0;
    }
}

static int rd_object(rd *r, ts_value *v)
{
    int8_t h;
    size_t off = r->pos;

    v->kind = TS_V_OBJECT;
    v->u.obj.o = NULL;
    v->u.obj.was_ref = 0;

    if (peek_head(r, &h)) return -1;

    if (h == TS_TAG_NIL) {
        r->pos++;
        v->kind = TS_V_NIL;
        return 0;
    }
    if (h == TS_TAG_NEW) {
        ts_object *o;
        slot s;
        size_t cap = 0;

        r->pos++;
        o = arena_alloc(&r->ar, sizeof *o);
        if (!o) return fail(r, off, "out of memory");
        memset(o, 0, sizeof *o);
        o->byte_off = off;
        o->id = r->next_obj_id++;
        s.kind = SLOT_OBJECT;
        s.u.obj = o;
        if (slot_push(r, s, NULL)) return -1;   /* before the body: cycles */

        if (rd_class(r, &o->cls)) return -1;
        if (!o->cls)
            return fail(r, off, "object has no class");

        for (;;) {
            ts_group *g;
            int n, i;

            if (peek_head(r, &h)) return -1;
            if (h == TS_TAG_END_OF_OBJECT) { r->pos++; break; }

            if (o->ngroups == cap) {
                size_t nc = cap ? cap * 2 : 4;
                ts_group *ng = arena_alloc(&r->ar, nc * sizeof *ng);
                if (!ng) return fail(r, r->pos, "out of memory");
                if (o->groups) memcpy(ng, o->groups, o->ngroups * sizeof *ng);
                o->groups = ng;
                cap = nc;
            }
            g = &o->groups[o->ngroups];
            memset(g, 0, sizeof *g);
            g->byte_off = r->pos;
            if (rd_shared(r, &g->encoding)) return -1;
            if (!g->encoding.text)
                return fail(r, g->byte_off, "nil type encoding");

            n = GSOpenStepTSTypeCount(g->encoding.text);
            if (n < 0)
                return fail(r, g->byte_off, "unhandled type encoding \"%s\"",
                            g->encoding.text);
            g->nvals = (size_t)n;
            g->vals = n ? arena_alloc(&r->ar, (size_t)n * sizeof *g->vals) : NULL;
            if (n && !g->vals) return fail(r, r->pos, "out of memory");

            {
                const char *e = g->encoding.text;
                for (i = 0; i < n; i++) {
                    int span = GSOpenStepTSTypeSpan(e);
                    char tmp[128];
                    if (span < 0 || (size_t)span >= sizeof tmp)
                        return fail(r, r->pos, "type too complex: %s", e);
                    memcpy(tmp, e, (size_t)span);
                    tmp[span] = '\0';
                    memset(&g->vals[i], 0, sizeof g->vals[i]);
                    g->vals[i].byte_off = r->pos;
                    if (rd_value(r, tmp, &g->vals[i])) return -1;
                    e += span;
                }
            }
            o->ngroups++;
        }
        o->byte_end = r->pos;
        v->u.obj.o = o;
        return 0;
    }
    if (is_nonref_tag(h))
        return fail(r, off, "expected an object, found tag %d", (int)h);

    {
        slot s;
        uint32_t ref;
        ts_int_width riw;
        if (rd_refnum(r, &ref, &riw)) return -1;
        if (ref < r->nslots && r->slots[ref].kind == SLOT_CLASS) {
            /* A Class is an object too: NEXTSTEP archives reference one
             * in an '@' slot (TableInspector.nib byte 324, DBTableVector
             * pointing at its own class). Keep it as a class value. */
            v->kind = TS_V_CLASS;
            v->u.cls.c = r->slots[ref].u.cls;
            v->u.cls.was_ref = 1;
            v->u.cls.ref = ref;
            return 0;
        }
        if (slot_get(r, ref, SLOT_OBJECT, &s, off)) return -1;
        v->u.obj.o = s.u.obj;
        v->u.obj.was_ref = 1;
        v->u.obj.ref = ref;
    }
    return 0;
}

static int rd_value_body(rd *r, const char *enc, ts_value *v);

static int rd_value(rd *r, const char *enc, ts_value *v)
{
    int result;
    if (r->depth >= 128) return fail(r, r->pos, "nesting limit exceeded");
    r->depth++;
    result = rd_value_body(r, enc, v);
    r->depth--;
    return result;
}

static int rd_value_body(rd *r, const char *enc, ts_value *v)
{
    switch (*enc) {
    case 'c': case 'C': case 'B': {          /* raw byte, no tag */
        uint8_t b;
        if (u8(r, &b)) return -1;
        v->kind = TS_V_BYTE;
        v->u.byte = b;
        return 0;
    }
    case 's': case 'S': case 'i': case 'I':
    case 'l': case 'L': case 'q': case 'Q': {
        int64_t iv; ts_int_width iw;
        int sign = (*enc == 's' || *enc == 'i' || *enc == 'l' || *enc == 'q');
        if (rd_int(r, &iv, &iw, sign)) return -1;
        v->kind = TS_V_INT;
        v->u.i.v = iv;
        v->u.i.iw = iw;
        return 0;
    }
    case 'f': return rd_float(r, v, 0);
    case 'd': return rd_float(r, v, 1);
    case '@': return rd_object(r, v);
    case '#': {
        ts_class *c;
        if (rd_class(r, &c)) return -1;
        v->kind = TS_V_CLASS;
        v->u.cls.c = c;
        return 0;
    }
    case '+': {                               /* unshared string */
        char *p; size_t n; ts_int_width lw;
        if (rd_unshared(r, &p, &n, &lw)) return -1;
        v->kind = TS_V_STRING;
        v->u.str.p = p;
        v->u.str.n = n;
        v->u.str.lw = lw;
        return 0;
    }
    case '*': {
        /*
         * A C string is uniqued in the OBJECT table by the typedstream
         * library (every data.nib in the corpus, both endiannesses; the
         * OPENSTEP fixtures contain no '*' at all): NIL for NULL; NEW,
         * which takes an object-table number, followed by the text as an
         * ordinary shared string (literal, or a shared-string reference:
         * `84 9a` in PS2MouseInspector.nib points at the class name
         * "View"); or a plain reference to an earlier such NEW
         * (NetwaveInspector.nib byte 1313; IBMTokenRingInspector.nib
         * byte 2924 has one with a positive head byte, ref #160).
         */
        ts_sharedref s;
        int8_t h;
        size_t off = r->pos;
        if (peek_head(r, &h)) return -1;
        memset(&s, 0, sizeof s);
        v->kind = TS_V_CSTR;
        if (h == TS_TAG_NIL) {
            r->pos++;
            v->u.shared = s;              /* text NULL */
            return 0;
        }
        if (h == TS_TAG_NEW) {
            slot sl;
            uint32_t idx;
            r->pos++;
            sl.kind = SLOT_CSTR;
            sl.u.cstr = NULL;
            if (slot_push(r, sl, &idx)) return -1;
            if (rd_shared(r, &s)) return -1;
            r->slots[idx].u.cstr = (char *)s.text;
            s.wrapped = 1;
            v->u.shared = s;
            return 0;
        }
        if (is_nonref_tag(h))
            return fail(r, off, "expected a C string, found tag %d", (int)h);
        {
            slot sl;
            uint32_t ref;
            ts_int_width riw;
            if (rd_refnum(r, &ref, &riw)) return -1;
            if (slot_get(r, ref, SLOT_CSTR, &sl, off)) return -1;
            s.text = sl.u.cstr;
            s.len = sl.u.cstr ? strlen(sl.u.cstr) : 0;
            s.was_ref = 1;
            s.ref = ref;
            s.wrapped = 2;
            v->u.shared = s;
            return 0;
        }
    }
    case '%': case ':': {
        ts_sharedref s;
        if (rd_shared(r, &s)) return -1;
        v->kind = (*enc == '%') ? TS_V_SHARED : TS_V_SELECTOR;
        v->u.shared = s;
        return 0;
    }
    case '!': case 'v':                        /* no data on the wire */
        v->kind = TS_V_NIL;
        return 0;
    case '[': {                                /* [N type] */
        const char *p = enc + 1;
        long count = 0;
        int span, i;
        char sub[128];

        while (*p >= '0' && *p <= '9') {
            if (count > (1048576 - (*p - '0')) / 10)
                return fail(r, r->pos, "array count exceeds limit");
            count = count * 10 + (*p++ - '0');
        }
        span = GSOpenStepTSTypeSpan(p);
        if (span < 0 || (size_t)span >= sizeof sub)
            return fail(r, r->pos, "bad array encoding %s", enc);
        memcpy(sub, p, (size_t)span);
        sub[span] = '\0';

        v->kind = TS_V_ARRAY;
        v->u.list.n = (size_t)count;
        v->sub_encoding = arena_alloc(&r->ar, (size_t)span + 1);
        if (!v->sub_encoding) return fail(r, r->pos, "out of memory");
        memcpy(v->sub_encoding, sub, (size_t)span + 1);

        /* char arrays are raw bytes — the common [24c] font-name case */
        if ((sub[0] == 'c' || sub[0] == 'C') && span == 1) {
            char *p2;
            if (need(r, (size_t)count)) return -1;
            p2 = arena_alloc(&r->ar, (size_t)count + 1);
            if (!p2) return fail(r, r->pos, "out of memory");
            memcpy(p2, r->buf + r->pos, (size_t)count);
            p2[count] = '\0';
            r->pos += (size_t)count;
            v->kind = TS_V_STRING;
            v->u.str.p = p2;
            v->u.str.n = (size_t)count;
            v->u.str.lw = TS_INT_INLINE;      /* no length on the wire */
            v->sub_encoding = arena_alloc(&r->ar, 4);
            if (v->sub_encoding) { v->sub_encoding[0] = 'c'; v->sub_encoding[1] = 0; }
            return 0;
        }
        v->u.list.v = count ? arena_alloc(&r->ar, (size_t)count * sizeof(ts_value))
                            : NULL;
        if (count && !v->u.list.v) return fail(r, r->pos, "out of memory");
        for (i = 0; i < count; i++) {
            memset(&v->u.list.v[i], 0, sizeof v->u.list.v[i]);
            v->u.list.v[i].byte_off = r->pos;
            if (rd_value(r, sub, &v->u.list.v[i])) return -1;
        }
        return 0;
    }
    case '{': case '(': {                      /* struct / union */
        const char *p = enc + 1;
        char close = (*enc == '{') ? '}' : ')';
        size_t cap = 0;
        int span;
        char sub[128];

        while (*p && *p != '=' && *p != close) p++;
        if (*p == '=') p++;

        v->kind = TS_V_STRUCT;
        v->u.list.v = NULL;
        v->u.list.n = 0;
        v->sub_encoding = arena_alloc(&r->ar, strlen(enc) + 1);
        if (!v->sub_encoding) return fail(r, r->pos, "out of memory");
        strcpy(v->sub_encoding, enc);

        while (*p && *p != close) {
            span = GSOpenStepTSTypeSpan(p);
            if (span < 0 || (size_t)span >= sizeof sub)
                return fail(r, r->pos, "bad struct encoding %s", enc);
            memcpy(sub, p, (size_t)span);
            sub[span] = '\0';
            if (v->u.list.n == cap) {
                size_t nc = cap ? cap * 2 : 4;
                ts_value *nv = arena_alloc(&r->ar, nc * sizeof *nv);
                if (!nv) return fail(r, r->pos, "out of memory");
                if (v->u.list.v) memcpy(nv, v->u.list.v, v->u.list.n * sizeof *nv);
                v->u.list.v = nv;
                cap = nc;
            }
            memset(&v->u.list.v[v->u.list.n], 0, sizeof v->u.list.v[0]);
            v->u.list.v[v->u.list.n].byte_off = r->pos;
            if (rd_value(r, sub, &v->u.list.v[v->u.list.n])) return -1;
            v->u.list.n++;
            p += span;
        }
        return 0;
    }
    case '^': {                                /* pointer: encoded as an object */
        return rd_object(r, v);
    }
    default:
        return fail(r, r->pos, "unhandled type '%c'", *enc);
    }
}

/* ---- header + top level ----------------------------------------------- */

static int rd_header(rd *r, ts_archive *a)
{
    uint8_t b, n;

    if (u8(r, &b)) return -1;
    a->streamer_version = b;
    if (b != TS_STREAMER_CURRENT && b != TS_STREAMER_OLD)
        return fail(r, 0, "unknown streamer version %u", b);

    if (u8(r, &n)) return -1;
    if (n >= sizeof a->signature)
        return fail(r, r->pos, "signature too long (%u)", n);
    if (need(r, n)) return -1;
    memcpy(a->signature, r->buf + r->pos, n);
    a->signature[n] = '\0';
    r->pos += n;

    if (!strcmp(a->signature, "streamtyped"))      a->big_endian = 0;
    else if (!strcmp(a->signature, "typedstream")) a->big_endian = 1;
    else return fail(r, 2, "bad signature \"%s\"", a->signature);
    r->big_endian = a->big_endian;   /* governs every int/float below */

    if (rd_int(r, &a->system_version, &a->system_version_iw, 0)) return -1;
    return 0;
}

ts_archive *GSOpenStepTSReadMemory(const uint8_t *buf, size_t len, ts_err *err)
{
    ts_archive *a;
    rd r;
    size_t cap = 0;

    err->ok = 1;
    err->msg[0] = '\0';
    err->off = 0;

    memset(&r, 0, sizeof r);
    r.buf = buf;
    r.len = len;
    r.err = err;

    a = calloc(1, sizeof *a);
    if (!a) { err->ok = 0; snprintf(err->msg, sizeof err->msg, "out of memory"); return NULL; }

    if (rd_header(&r, a)) goto bad;

    /* Top level: typed groups until the bytes run out. */
    while (r.pos < r.len) {
        ts_group *g;
        int n, i;
        const char *e;

        if (a->nroot == cap) {
            size_t nc = cap ? cap * 2 : 4;
            ts_group *ng = arena_alloc(&r.ar, nc * sizeof *ng);
            if (!ng) { fail(&r, r.pos, "out of memory"); goto bad; }
            if (a->root) memcpy(ng, a->root, a->nroot * sizeof *ng);
            a->root = ng;
            cap = nc;
        }
        g = &a->root[a->nroot];
        memset(g, 0, sizeof *g);
        g->byte_off = r.pos;
        if (rd_shared(&r, &g->encoding)) goto bad;
        if (!g->encoding.text) { fail(&r, g->byte_off, "nil top-level encoding"); goto bad; }

        n = GSOpenStepTSTypeCount(g->encoding.text);
        if (n < 0) { fail(&r, g->byte_off, "unhandled encoding \"%s\"", g->encoding.text); goto bad; }
        g->nvals = (size_t)n;
        g->vals = n ? arena_alloc(&r.ar, (size_t)n * sizeof *g->vals) : NULL;
        if (n && !g->vals) { fail(&r, r.pos, "out of memory"); goto bad; }

        e = g->encoding.text;
        for (i = 0; i < n; i++) {
            int span = GSOpenStepTSTypeSpan(e);
            char tmp[128];
            if (span < 0 || (size_t)span >= sizeof tmp) { fail(&r, r.pos, "type too complex"); goto bad; }
            memcpy(tmp, e, (size_t)span);
            tmp[span] = '\0';
            memset(&g->vals[i], 0, sizeof g->vals[i]);
            g->vals[i].byte_off = r.pos;
            if (rd_value(&r, tmp, &g->vals[i])) goto bad;
            e += span;
        }
        a->nroot++;
    }

    if (r.pos != r.len) {
        fail(&r, r.pos, "%zu trailing byte(s)", r.len - r.pos);
        goto bad;
    }

    a->pool = malloc(sizeof(arena));
    if (!a->pool) { fail(&r, r.pos, "out of memory"); goto bad; }
    *(arena *)a->pool = r.ar;
    free(r.slots);
    free(r.strs);
    return a;

bad:
    arena_free(&r.ar);
    free(r.slots);
    free(r.strs);
    free(a);
    return NULL;
}

void GSOpenStepTSFree(ts_archive *a)
{
    if (!a) return;
    if (a->pool) { arena_free((arena *)a->pool); free(a->pool); }
    free(a);
}
