/*
 * Binary OPENSTEP nib compatibility, isolated from AppKit element classes.
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
 * This file is part of GNUstep GUI, licensed under the GNU Lesser General
 * Public License, version 2 or later.  See COPYING.LIB.
 *
 * Historical layouts are from NIBMAKER-FOR-OPENSTEP (see GSOpenStep/README).
 * A typed stream is NOT a GNUstep NSArchiver archive.  Translate the measured
 * layouts to the keyed fields already understood by GSNibLoading/AppKit.
 * The object table is built before unarchiving, so cycles, replacements and
 * shared instances remain the responsibility of NSKeyedUnarchiver.
 */
#import "config.h"
#import <Foundation/Foundation.h>
#import "AppKit/NSButtonCell.h"
#import "GSOpenStepNibReader.h"
#include "GSOpenStep/ts_read.h"
#include <math.h>
#include <string.h>

BOOL
GSOpenStepNibIsTypedStream(NSData *data)
{
  const unsigned char *b = [data bytes];
  return [data length] >= 13 && (b[0] == 3 || b[0] == 4) && b[1] == 11
    && (!memcmp(b + 2, "streamtyped", 11)
        || !memcmp(b + 2, "typedstream", 11));
}

static void
Bad(const ts_object *o, NSString *reason)
{
  [NSException raise: NSInvalidUnarchiveOperationException
              format: @"OPENSTEP nib: %s version %lld at byte %lu: %@",
    o && o->cls ? o->cls->name.text : "archive",
    o && o->cls ? (long long)o->cls->version : 0,
    o ? (unsigned long)o->byte_off : 0, reason];
}

static const ts_group *
Group(const ts_object *o, NSUInteger *index, const char *encoding)
{
  const ts_group *g;
  if (*index >= o->ngroups)
    Bad(o, @"missing typed group");
  g = &o->groups[(*index)++];
  if (strcmp(g->encoding.text, encoding))
    Bad(o, [NSString stringWithFormat: @"expected '%s', found '%s' at byte %lu",
      encoding, g->encoding.text, (unsigned long)g->byte_off]);
  return g;
}

static long long
Integer(const ts_value *v)
{
  if (v->kind == TS_V_INT) return v->u.i.v;
  if (v->kind == TS_V_BYTE) return v->u.byte;
  Bad(NULL, @"expected an integer");
  return 0;
}

static double
Real(const ts_value *v)
{
  double n;
  if (v->kind == TS_V_FLOAT) n = v->u.f;
  else if (v->kind == TS_V_DOUBLE) n = v->u.d;
  else n = Integer(v);
  if (!isfinite(n)) Bad(NULL, @"non-finite geometry or colour");
  return n;
}

static const ts_object *
Object(const ts_value *v)
{
  if (v->kind == TS_V_NIL) return NULL;
  if (v->kind != TS_V_OBJECT) Bad(NULL, @"expected an object reference");
  return v->u.obj.o;
}

static NSString *
Text(const ts_value *v)
{
  const char *s;
  size_t n;
  NSString *result;
  if (v->kind == TS_V_NIL) return nil;
  if (v->kind == TS_V_STRING) { s = v->u.str.p; n = v->u.str.n; }
  else if (v->kind == TS_V_SELECTOR || v->kind == TS_V_SHARED
           || v->kind == TS_V_CSTR)
    { s = v->u.shared.text; n = v->u.shared.len; }
  else { Bad(NULL, @"expected string bytes"); return nil; }
  if (s == NULL) return nil;
  /* These archives predate UTF-8.  Do not guess UTF-8 from byte validity. */
  result = AUTORELEASE([[NSString alloc] initWithBytes: s length: n
                                            encoding: NSNEXTSTEPStringEncoding]);
  if (result == nil) Bad(NULL, @"invalid NEXTSTEP string");
  return result;
}

static NSString *
StringObject(const ts_object *o)
{
  if (o == NULL) return nil;
  if (strcmp(o->cls->name.text, "NSString") || o->cls->version != 1
      || o->ngroups != 1 || strcmp(o->groups[0].encoding.text, "+"))
    Bad(o, @"expected NSString version 1");
  return Text(&o->groups[0].vals[0]);
}

static NSNumber *Number(long long n)
{
  return [NSNumber numberWithLongLong: n];
}

static void
ValidateClass(const ts_class *c, const ts_object *o, unsigned depth)
{
  static const struct { const char *name; int version; const char *parent; } layouts[] = {
    {"NSObject", 0, NULL}, {"NSString", 1, "NSObject"},
    {"NSArray", 0, "NSObject"}, {"NSMutableArray", 0, "NSArray"},
    {"NSSet", 0, "NSObject"}, {"NSMutableSet", 0, "NSSet"},
    {"NSIBObjectData", 24, "NSObject"}, {"NSCustomObject", 41, "NSObject"},
    {"NSCustomResource", 41, "NSObject"}, {"NSIBConnector", 17, "NSObject"},
    {"NSIBOutletConnector", 0, "NSIBConnector"}, {"NSIBControlConnector", 0, "NSIBConnector"},
    {"NSResponder", 0, "NSObject"}, {"NSView", 41, "NSResponder"},
    {"NSControl", 41, "NSView"}, {"NSCustomView", 41, "NSView"},
    {"NSButton", 0, "NSControl"}, {"NSTextField", 25, "NSControl"},
    {"NSMatrix", 60, "NSControl"}, {"NSBox", 41, "NSView"},
    {"NSCell", 60, "NSObject"}, {"NSActionCell", 17, "NSCell"},
    {"NSButtonCell", 57, "NSActionCell"}, {"NSTextFieldCell", 61, "NSActionCell"},
    {"NSWindowTemplate", 41, "NSObject"}, {"NSFont", 21, "NSObject"},
    {"NSColor", 0, "NSObject"}
  };
  NSUInteger i;
  if (!c || !c->name.text || depth >= 64) Bad(o, @"invalid class hierarchy");
  for (i = 0; i < sizeof layouts / sizeof layouts[0]; i++)
    if (!strcmp(c->name.text, layouts[i].name) && c->version == layouts[i].version)
      {
        if (layouts[i].parent == NULL)
          { if (c->super) Bad(o, @"NSObject has a superclass"); }
        else
          {
            if (!c->super || !c->super->name.text
                || strcmp(c->super->name.text, layouts[i].parent))
              Bad(o, @"unexpected superclass in historical layout");
            ValidateClass(c->super, o, depth + 1);
          }
        return;
      }
  Bad(o, [NSString stringWithFormat: @"unsupported layout %s version %lld",
    c->name.text, (long long)c->version]);
}

static NSDictionary *UID(NSUInteger n)
{
  return [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedInteger: n]
                                    forKey: @"CF$UID"];
}

/* Deliberately private.  Adding a layout never changes an AppKit class. */
@interface GSOpenStepNibTranslator : NSObject
{
  NSMutableArray *_objects;
  NSMutableDictionary *_references;
  NSMutableDictionary *_classes;
  NSMutableArray *_visible;
  NSMutableArray *_periodic;
  const ts_object *_owner;
  unsigned _depth;
}
- (NSDictionary *) reference: (const ts_object *)o;
- (NSData *) translate: (const ts_archive *)archive;
- (void) visit: (const ts_value *)v seen: (NSMutableSet *)seen depth: (unsigned)depth;
@end

@implementation GSOpenStepNibTranslator
- (id) init
{
  if ((self = [super init]))
    {
      _objects = [[NSMutableArray alloc] initWithObjects: @"$null", nil];
      _references = [NSMutableDictionary new];
      _classes = [NSMutableDictionary new];
      _visible = [NSMutableArray new];
      _periodic = [NSMutableArray new];
    }
  return self;
}
- (void) dealloc
{
  RELEASE(_objects); RELEASE(_references); RELEASE(_classes); RELEASE(_visible);
  RELEASE(_periodic);
  [super dealloc];
}
- (NSDictionary *) literal: (id)value
{
  NSUInteger index;
  if (value == nil) return UID(0);
  index = [_objects count];
  [_objects addObject: value];
  return UID(index);
}
- (NSDictionary *) classReference: (NSString *)name
{
  NSDictionary *ref = [_classes objectForKey: name];
  if (ref == nil)
    {
      ref = [self literal: [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"$classname", [NSArray arrayWithObjects: name, @"NSObject", nil],
        @"$classes", nil]];
      [_classes setObject: ref forKey: name];
    }
  return ref;
}
- (NSDictionary *) array: (NSArray *)refs
{
  return [self literal: [NSDictionary dictionaryWithObjectsAndKeys:
    [self classReference: @"NSMutableArray"], @"$class", refs, @"NS.objects", nil]];
}
- (void) object: (const ts_value *)v key: (NSString *)key
           into: (NSMutableDictionary *)d
{
  [d setObject: [self reference: Object(v)] forKey: key];
}
- (void) rect: (const ts_value *)v key: (NSString *)key
         into: (NSMutableDictionary *)d
{
  double w = Real(v + 2), h = Real(v + 3);
  if (w < 0 || h < 0) Bad(NULL, @"negative rectangle size");
  [d setObject: [self literal: [NSString stringWithFormat: @"{{%.17g, %.17g}, {%.17g, %.17g}}", Real(v), Real(v + 1), w, h]]
        forKey: key];
}
- (NSArray *) elements: (const ts_object *)o
{
  NSUInteger i = 0, n, k;
  long long count;
  const ts_group *g;
  NSMutableArray *refs = [NSMutableArray array];
  if (o == NULL) return refs;
  if (strcmp(o->cls->name.text, "NSArray")
      && strcmp(o->cls->name.text, "NSMutableArray")
      && strcmp(o->cls->name.text, "NSSet")
      && strcmp(o->cls->name.text, "NSMutableSet"))
    Bad(o, @"expected an array or set");
  if (!o->ngroups) Bad(o, @"missing collection count");
  g = Group(o, &i, strstr(o->cls->name.text, "Set")
                   ? "I" : "i");
  count = Integer(g->vals);
  if (count < 0 || (unsigned long long)count != o->ngroups - 1)
    Bad(o, @"collection count does not match its groups");
  n = (NSUInteger)count;
  for (k = 0; k < n; k++)
    {
      g = Group(o, &i, "@");
      if (Object(g->vals) == NULL) Bad(o, @"nil collection element");
      [refs addObject: [self reference: Object(g->vals)]];
    }
  return refs;
}
- (void) container: (const ts_object *)o into: (NSMutableDictionary *)d
{
  NSUInteger i = 0, section, k;
  const ts_group *g;
  const char *encodings[] = {"@@", "@@", "@i"};
  NSString *keys[] = {@"NSObjectsKeys", @"NSNamesKeys", @"NSOidsKeys"};
  NSString *values[] = {@"NSObjectsValues", @"NSNamesValues", @"NSOidsValues"};
  g = Group(o, &i, "@");
  _owner = Object(g->vals);
  if (_owner == NULL || strcmp(_owner->cls->name.text, "NSCustomObject"))
    Bad(o, @"missing File's Owner placeholder");
  [self object: g->vals key: @"NSRoot" into: d];
  for (section = 0; section < 3; section++)
    {
      long long count;
      NSMutableArray *a = [NSMutableArray array], *b = [NSMutableArray array];
      if (section == 2)
        {
          g = Group(o, &i, "@");
          [_visible addObjectsFromArray: [self elements: Object(g->vals)]];
          g = Group(o, &i, "@");
          [self object: g->vals key: @"NSConnections" into: d];
          g = Group(o, &i, "@");
          if (Object(g->vals)) Bad(o, @"unsupported nonempty auxiliary container field");
        }
      g = Group(o, &i, "i");
      count = Integer(g->vals);
      if (count < 0 || (unsigned long long)count > o->ngroups - i)
        Bad(o, @"invalid map count");
      for (k = 0; k < (NSUInteger)count; k++)
        {
          const ts_object *key;
          g = Group(o, &i, encodings[section]);
          key = Object(g->vals);
          if (key == NULL) Bad(o, @"nil map key");
          [a addObject: [self reference: key]];
          if (section == 2)
            {
              /* Wire IDs identify references, not nib ownership/proxy IDs.
               * OPENSTEP may assign a positive nib ID to File's Owner. */
              long long oid = key == _owner ? -1 : Integer(g->vals + 1);
              [b addObject: [self literal: Number(oid)]];
            }
          else
            {
              if (Object(g->vals + 1) == NULL) Bad(o, @"nil map value");
              [b addObject: [self reference: Object(g->vals + 1)]];
            }
        }
      [d setObject: [self array: a] forKey: keys[section]];
      [d setObject: [self array: b] forKey: values[section]];
    }
  g = Group(o, &i, "i");
  [d setObject: Number(Integer(g->vals)) forKey: @"NSNextOid"];
  g = Group(o, &i, "i");
  if (Integer(g->vals) != 0 || i != o->ngroups)
    Bad(o, @"unsupported trailing container section");
  [d setObject: [self array: _visible] forKey: @"NSVisibleWindows"];
}

/* Check the complete inheritance chain, rather than accepting an unknown
 * subclass and discarding its state.  Each version below has a measured layout.
 * NEXTSTEP's unprefixed AppKit is a different layout family, not an alias. */
- (void) fields: (const ts_class *)c object: (const ts_object *)o
         index: (NSUInteger *)i into: (NSMutableDictionary *)d depth: (unsigned)depth
{
  const char *name;
  const ts_group *g;
  const ts_value *v;
  if (c == NULL) return;
  if (depth >= 64) Bad(o, @"cyclic or excessively deep class hierarchy");
  [self fields: c->super object: o index: i into: d depth: depth + 1];
  name = c->name.text;
#define IS(n, ver) (!strcmp(name, n) && c->version == (ver))
#define GET(enc) do { g = Group(o, i, enc); v = g->vals; } while (0)
#define OBJ(n, k) [self object: v + (n) key: k into: d]
#define INT(n, key) [d setObject: Number(Integer(v + (n))) forKey: key]
  if (IS("NSObject", 0)) return;
  if (IS("NSIBObjectData", 24))
    { [self container: o into: d]; *i = o->ngroups; }
  else if (IS("NSArray", 0) || IS("NSSet", 0))
    { [d setObject: [self elements: o] forKey: @"NS.objects"]; *i = o->ngroups; }
  else if (IS("NSMutableArray", 0) || IS("NSMutableSet", 0)
           || IS("NSButton", 0) || IS("NSIBOutletConnector", 0)
           || IS("NSIBControlConnector", 0)) return;
  else if (IS("NSCustomObject", 41) || IS("NSCustomResource", 41))
    {
      GET("@@"); OBJ(0, @"NSClassName");
      if (!strcmp(name, "NSCustomResource")) OBJ(1, @"NSResourceName");
      else OBJ(1, @"NSExtension");
    }
  else if (IS("NSIBConnector", 17))
    { GET("@@@"); OBJ(0, @"NSSource"); OBJ(1, @"NSDestination"); OBJ(2, @"NSLabel"); }
  else if (IS("NSResponder", 0))
    {
      GET("@");
      /* NSView's parent is established by NSSubviews after its initializer
       * has allocated view state.  Decoding it here creates premature cycles. */
    }
  else if (IS("NSView", 41))
    {
      unsigned long flags;
      GET("i"); flags = (unsigned long)Integer(v);
      if (flags != 0) Bad(o, @"unsupported OPENSTEP view flags");
      [d setObject: Number(0x100) forKey: @"NSvFlags"];
      GET("@@@@ffffffff"); OBJ(0, @"NSSubviews");
      if (Object(v + 1) || Object(v + 2) || Object(v + 3))
        Bad(o, @"unsupported view transform or auxiliary state");
      [self rect: v + 4 key: @"NSFrame" into: d];
      [self rect: v + 8 key: @"NSBounds" into: d];
      GET("@"); /* superview: established by NSSubviews */
      GET("@"); if (Object(v)) Bad(o, @"unsupported view auxiliary object");
      GET("@"); OBJ(0, @"NSNextKeyView");
      GET("@"); OBJ(0, @"NSPreviousKeyView");
    }
  else if (IS("NSCustomView", 41))
    { GET("@@"); OBJ(0, @"NSClassName"); OBJ(1, @"NSExtension"); }
  else if (IS("NSControl", 41))
    { GET("icc@"); INT(0, @"NSTag"); OBJ(3, @"NSCell"); }
  else if (IS("NSTextField", 25))
    { GET("@"); OBJ(0, @"NSDelegate"); GET(":");
      if (Text(v)) Bad(o, @"unsupported text-field validation selector"); }
  else if (IS("NSCell", 60))
    {
      GET("ii");
      /* Bits 16..9 in the first historical word are opaque (commonly all
       * set), not Cocoa's line-break/appearance fields.  The second word's
       * measured text alignment is independent of those bits. */
      [d setObject: Number(Integer(v) & ~0x1fe00LL) forKey: @"NSCellFlags"];
      INT(1, @"NSCellFlags2");
      GET("@@@@"); OBJ(0, @"NSContents"); OBJ(1, @"NSSupport");
      if (Object(v + 2) || Object(v + 3)) Bad(o, @"unsupported cell auxiliary state");
    }
  else if (IS("NSActionCell", 17))
    {
      GET("i:"); INT(0, @"NSTag");
      [d setObject: [self literal: Text(v + 1)] forKey: @"NSAction"];
      GET("@"); OBJ(0, @"NSTarget");
      GET("@"); /* control view is assigned when the control adopts the cell */
    }
  else if (IS("NSButtonCell", 57))
    {
      GET("ssIi@@@@@");
      if (Integer(v) < 0 || Integer(v + 1) < 0)
        Bad(o, @"negative periodic interval");
      INT(3, @"NSButtonFlags"); OBJ(4, @"NSAlternateContents");
      OBJ(5, @"NSKeyEquivalent"); OBJ(6, @"NSNormalImage"); OBJ(7, @"NSAlternateImage");
      if (Object(v + 8)) Bad(o, @"unsupported button auxiliary object");
      /* The existing keyed decoder reads integral seconds.  Preserve the
       * historical millisecond values in loader metadata and apply them
       * through NSButtonCell's public API before awakening the nib. */
      [_periodic addObject: [self array: [NSArray arrayWithObjects:
        [_references objectForKey: Number(o->id)],
        [self literal: [NSNumber numberWithDouble: Real(v) / 1000.0]],
        [self literal: [NSNumber numberWithDouble: Real(v + 1) / 1000.0]], nil]]];
    }
  else if (IS("NSTextFieldCell", 61))
    { GET("c@@"); INT(0, @"NSDrawsBackground"); OBJ(1, @"NSBackgroundColor"); OBJ(2, @"NSTextColor"); }
  else if (IS("NSBox", 41))
    {
      GET("ff@@ccc");
      [d setObject: [self literal: [NSString stringWithFormat: @"{%.17g, %.17g}", Real(v), Real(v + 1)]]
            forKey: @"NSOffsets"];
      OBJ(2, @"NSTitleCell"); OBJ(3, @"NSContentView");
      INT(4, @"NSBorderType"); INT(5, @"NSTitlePosition");
      GET("@"); if (Object(v)) Bad(o, @"unsupported box auxiliary object");
    }
  else if (IS("NSMatrix", 60))
    {
      long long rows, cols;
      NSArray *cells;
      GET("#iiii:::ffffi@@@@@");
      if (v->kind != TS_V_CLASS || v->u.cls.c == NULL)
        Bad(o, @"missing matrix cell class");
      {
        const ts_class *cellClass = v->u.cls.c;
        ValidateClass(cellClass, o, 0);
        while (cellClass && strcmp(cellClass->name.text, "NSCell"))
          cellClass = cellClass->super;
        if (!cellClass) Bad(o, @"matrix cell class is not a cell");
      }
      [d setObject: [self literal: [NSString stringWithUTF8String: v->u.cls.c->name.text]]
            forKey: @"NSCellClass"];
      rows = Integer(v + 3); cols = Integer(v + 4);
      cells = [self elements: Object(v + 13)];
      if (rows < 0 || cols < 0 || rows > 1048576 || cols > 1048576
          || rows * cols != (long long)[cells count]) Bad(o, @"invalid matrix dimensions");
      if (Integer(v + 1) < -1 || Integer(v + 2) < -1
          || Integer(v + 1) >= rows || Integer(v + 2) >= cols)
        Bad(o, @"invalid matrix selection");
      INT(1, @"NSSelectedRow"); INT(2, @"NSSelectedCol");
      INT(3, @"NSNumRows"); INT(4, @"NSNumCols"); INT(12, @"NSMatrixFlags");
      [d setObject: [self array: cells] forKey: @"NSCells"];
      [d setObject: [self literal: [NSString stringWithFormat: @"{%.17g, %.17g}", Real(v + 8), Real(v + 9)]]
            forKey: @"NSCellSize"];
      [d setObject: [self literal: [NSString stringWithFormat: @"{%.17g, %.17g}", Real(v + 10), Real(v + 11)]]
            forKey: @"NSIntercellSpacing"];
      GET("@"); OBJ(0, @"NSBackgroundColor");
      GET("@"); OBJ(0, @"NSCellBackgroundColor");
      GET("@"); OBJ(0, @"NSProtoCell");
    }
  else if (IS("NSWindowTemplate", 41))
    {
      unsigned long flags;
      GET("iiffffi@@@@@c");
      INT(0, @"NSWindowStyleMask"); INT(1, @"NSWindowBacking");
      [self rect: v + 2 key: @"NSWindowRect" into: d];
      INT(6, @"NSWTFlags"); flags = (unsigned long)Integer(v + 6);
      OBJ(7, @"NSWindowTitle"); OBJ(8, @"NSWindowClass");
      OBJ(10, @"NSWindowView"); OBJ(11, @"NSFrameAutosaveName");
      if (flags & 0x08000000UL) [_visible addObject: [_references objectForKey: Number(o->id)]];
      GET("ffff"); /* archived screen geometry */
      GET("c"); if (Integer(v)) Bad(o, @"unsupported window trailing flag");
      if (*i < o->ngroups)
        { GET("ff"); Bad(o, @"unsupported window size extension"); }
    }
  else if (IS("NSFont", 21))
    {
      size_t n, length;
      const unsigned char *bytes;
      NSString *fontName;
      GET("i"); length = (size_t)Integer(v);
      if (*i >= o->ngroups) Bad(o, @"missing font bytes");
      g = &o->groups[(*i)++]; v = g->vals;
      if (g->nvals != 1 || v->kind != TS_V_STRING || v->u.str.n != length || length < 8)
        Bad(o, @"invalid font name buffer");
      {
        char encoding[64];
        snprintf(encoding, sizeof encoding, "[%luc]", (unsigned long)length);
        if (strcmp(g->encoding.text, encoding)) Bad(o, @"invalid font byte-array encoding");
      }
      bytes = (const unsigned char *)v->u.str.p;
      for (n = 8; n < length && bytes[n]; n++) { }
      fontName = AUTORELEASE([[NSString alloc] initWithBytes: bytes + 8 length: n - 8
                                                  encoding: NSNEXTSTEPStringEncoding]);
      if (![fontName length]) Bad(o, @"empty font name");
      [d setObject: [self literal: fontName] forKey: @"NSName"];
      GET("f"); [d setObject: [NSNumber numberWithDouble: Real(v)] forKey: @"NSSize"];
      GET("c"); GET("c"); GET("c"); GET("c");
      if (Integer(v)) Bad(o, @"unsupported system font role");
    }
  else if (IS("NSColor", 0))
    {
      long long space;
      GET("c"); space = Integer(v);
      [d setObject: Number(space) forKey: @"NSColorSpace"];
      if (space >= 1 && space <= 5)
        {
          NSMutableArray *parts = [NSMutableArray array];
          NSUInteger j;
          GET(space <= 2 ? "ffff" : (space <= 4 ? "ff" : "fffff"));
          for (j = 0; j < g->nvals; j++)
            [parts addObject: [NSString stringWithFormat: @"%.9g", Real(v + j)]];
          [d setObject: [[parts componentsJoinedByString: @" "] dataUsingEncoding: NSASCIIStringEncoding]
                forKey: space <= 2 ? @"NSRGB" : (space <= 4 ? @"NSWhite" : @"NSCYMK")];
        }
      else if (space == 6)
        { GET("@@@"); OBJ(0, @"NSCatalogName"); OBJ(1, @"NSColorName"); OBJ(2, @"NSColor"); }
      else Bad(o, @"unsupported colour space");
    }
  else
    Bad(o, [NSString stringWithFormat: @"unsupported layout %s version %lld",
      name, (long long)c->version]);
#undef IS
#undef GET
#undef OBJ
#undef INT
}

- (NSDictionary *) reference: (const ts_object *)o
{
  NSNumber *key;
  NSDictionary *ref;
  NSMutableDictionary *d;
  NSUInteger index = 0;
  NSString *name;
  if (o == NULL) return UID(0);
  key = Number(o->id);
  ref = [_references objectForKey: key];
  if (ref) return ref;
  if (_depth >= 128) Bad(o, @"object nesting limit exceeded");
  ValidateClass(o->cls, o, 0);
  name = [NSString stringWithUTF8String: o->cls->name.text];
  if ([name isEqual: @"NSString"])
    {
      ref = [self literal: StringObject(o)];
      [_references setObject: ref forKey: key];
      return ref;
    }
  d = [NSMutableDictionary dictionary];
  ref = [self literal: d];
  [_references setObject: ref forKey: key]; /* before following references */
  if ([name isEqual: @"NSIBOutletConnector"]) name = @"NSNibOutletConnector";
  if ([name isEqual: @"NSIBControlConnector"]) name = @"NSNibControlConnector";
  [d setObject: [self classReference: name] forKey: @"$class"];
  _depth++;
  [self fields: o->cls object: o index: &index into: d depth: 0];
  _depth--;
  if (index != o->ngroups) Bad(o, @"unconsumed typed groups");
  return ref;
}
- (void) visit: (const ts_value *)v seen: (NSMutableSet *)seen depth: (unsigned)depth
{
  NSUInteger i, j;
  if (depth >= 128) Bad(NULL, @"graph nesting limit exceeded");
  if (v->kind == TS_V_OBJECT && v->u.obj.o)
    {
      const ts_object *o = v->u.obj.o;
      NSNumber *key = Number(o->id);
      if ([seen containsObject: key]) return;
      [seen addObject: key];
      [self reference: o];
      for (i = 0; i < o->ngroups; i++)
        for (j = 0; j < o->groups[i].nvals; j++)
          [self visit: &o->groups[i].vals[j] seen: seen depth: depth + 1];
    }
  else if (v->kind == TS_V_ARRAY || v->kind == TS_V_STRUCT)
    for (i = 0; i < v->u.list.n; i++)
      [self visit: &v->u.list.v[i] seen: seen depth: depth + 1];
}
- (NSData *) translate: (const ts_archive *)archive
{
  const ts_object *root;
  NSDictionary *top, *plist;
  NSData *data;
  NSString *error = nil;
  if (archive->nroot != 1 || strcmp(archive->root[0].encoding.text, "@"))
    Bad(NULL, @"expected a single root object");
  root = Object(archive->root[0].vals);
  if (!root || strcmp(root->cls->name.text, "NSIBObjectData"))
    Bad(root, @"expected native OPENSTEP NSIBObjectData");
  /* Translate the root before reading the metadata accumulated by its cells. */
  {
    id rootRef = [self reference: root];
    /* Even an object in an auxiliary field must have a supported layout.
     * Do this before executing any application initializers or awake methods. */
    [self visit: archive->root[0].vals seen: [NSMutableSet set] depth: 0];
    top = [NSDictionary dictionaryWithObjectsAndKeys: rootRef, @"IB.objectdata",
      [self array: _periodic], @"GSOpenStepPeriodicIntervals", nil];
  }
  plist = [NSDictionary dictionaryWithObjectsAndKeys:
    @"NSKeyedArchiver", @"$archiver", Number(100000), @"$version",
    _objects, @"$objects", top, @"$top", nil];
  data = [NSPropertyListSerialization dataFromPropertyList: plist
    format: NSPropertyListBinaryFormat_v1_0 errorDescription: &error];
  if (data == nil)
    {
      NSString *reason = AUTORELEASE(error);
      Bad(NULL, reason);
    }
  return data;
}
@end

NSData *
GSOpenStepNibKeyedData(NSData *data)
{
  ts_err error;
  ts_archive *archive;
  GSOpenStepNibTranslator *translator;
  NSData *result = nil;
  if (!GSOpenStepNibIsTypedStream(data)) Bad(NULL, @"not a typed stream");
  archive = GSOpenStepTSReadMemory([data bytes], [data length], &error);
  if (archive == NULL)
    [NSException raise: NSInvalidUnarchiveOperationException
                format: @"OPENSTEP typed stream at byte %lu: %s",
                  (unsigned long)error.off, error.msg];
  translator = [GSOpenStepNibTranslator new];
  @try { result = [translator translate: archive]; }
  @finally { RELEASE(translator); GSOpenStepTSFree(archive); }
  return result;
}

void
GSOpenStepNibFinishDecoding(NSKeyedUnarchiver *coder)
{
  NSArray *entries = [coder decodeObjectForKey: @"GSOpenStepPeriodicIntervals"];
  for (NSArray *entry in entries)
    {
      NSButtonCell *cell = [entry objectAtIndex: 0];
      [cell setPeriodicDelay: [[entry objectAtIndex: 1] doubleValue]
                   interval: [[entry objectAtIndex: 2] doubleValue]];
    }
}
