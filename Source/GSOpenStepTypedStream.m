/* OPENSTEP typed stream reader.  This implementation decodes only the
 * archive forms needed by the nib translator and rejects malformed input. */
#import <Foundation/Foundation.h>
#include "GSOpenStepTypedStream.h"
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { TS_INTEGER16 = -127, TS_INTEGER32 = -126, TS_REAL = -125,
       TS_NEW = -124, TS_NIL = -123, TS_END = -122,
       TS_RESERVED_LAST = -111, TS_REFERENCE_BASE = -110 };

typedef struct { int kind; void *pointer; } TSEntity;
enum { TS_CLASS_ENTITY, TS_OBJECT_ENTITY, TS_CSTRING_ENTITY };

static int
typeSpan(const char *s, unsigned depth)
{
  const char *p = s;
  int n;
  char close;
  if (depth == 64 || !*p) return -1;
  switch (*p++)
    {
    case 'c': case 'C': case 'B': case 's': case 'S': case 'i': case 'I':
    case 'l': case 'L': case 'q': case 'Q': case 'f': case 'd': case '@':
    case '#': case ':': case '%': case '+': case '*': case '!': case 'v':
      return 1;
    case '^':
      n = typeSpan(p, depth + 1);
      return n < 0 ? -1 : n + 1;
    case '[':
      if (*p < '0' || *p > '9') return -1;
      while (*p >= '0' && *p <= '9') p++;
      n = typeSpan(p, depth + 1);
      if (n < 0 || p[n] != ']') return -1;
      return (int)(p - s) + n + 1;
    case '{': case '(':
      close = *s == '{' ? '}' : ')';
      while (*p && *p != '=' && *p != close) p++;
      if (*p == '=')
        {
          p++;
          while (*p && *p != close)
            {
              n = typeSpan(p, depth + 1);
              if (n < 0) return -1;
              p += n;
            }
        }
      return *p == close ? (int)(p - s) + 1 : -1;
    default: return -1;
    }
}

int GSOpenStepTSTypeSpan(const char *s)
{
  return s ? typeSpan(s, 0) : -1;
}

int GSOpenStepTSTypeCount(const char *s)
{
  int count = 0, span;
  if (!s) return -1;
  while (*s)
    {
      span = GSOpenStepTSTypeSpan(s);
      if (span < 0 || count == 1024) return -1;
      s += span;
      count++;
    }
  return count;
}

@interface GSOpenStepStreamDecoder : NSObject
{
  const uint8_t *_bytes;
  size_t _length, _offset, _allocated;
  unsigned _depth;
  BOOL _bigEndian;
  uint32_t _classID, _objectID;
  NSMutableArray *_allocations, *_strings, *_entities;
  ts_err *_error;
}
- (id)initWithBytes:(const uint8_t *)bytes length:(size_t)length error:(ts_err *)error;
- (void)readArchive:(ts_archive *)archive;
- (void)releaseAllocations;
- (void)readValue:(ts_value *)value encoding:(const char *)encoding;
- (void)readGroup:(ts_group *)group;
@end

@implementation GSOpenStepStreamDecoder
- (id)initWithBytes:(const uint8_t *)bytes length:(size_t)length error:(ts_err *)error
{
  self = [super init];
  if (self)
    {
      _bytes = bytes; _length = length; _error = error;
      _allocations = [NSMutableArray new];
      _strings = [NSMutableArray new];
      _entities = [NSMutableArray new];
    }
  return self;
}

- (void)dealloc
{
  [_allocations release]; [_strings release]; [_entities release];
  [super dealloc];
}

- (void)releaseAllocations
{
  NSUInteger i;
  for (i = 0; i < [_allocations count]; i++)
    free([[_allocations objectAtIndex:i] pointerValue]);
  [_allocations removeAllObjects];
}

- (void)decodeError:(const char *)message
{
  if (_error->ok)
    {
      _error->ok = 0;
      _error->off = _offset;
      snprintf(_error->msg, sizeof _error->msg, "%s", message);
    }
  @throw [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                 reason:@"Invalid OPENSTEP typed stream" userInfo:nil];
}

- (void)require:(size_t)amount
{
  if (_offset > _length || amount > _length - _offset)
    [self decodeError:"truncated input"];
}

- (void *)allocate:(size_t)amount
{
  void *p;
  if (amount > 256u * 1024u * 1024u - _allocated)
    [self decodeError:"allocation limit exceeded"];
  p = calloc(1, amount ? amount : 1);
  if (!p) [self decodeError:"out of memory"];
  _allocated += amount;
  [_allocations addObject:[NSValue valueWithPointer:p]];
  return p;
}

- (int)peek
{
  [self require:1];
  return (int)(int8_t)_bytes[_offset];
}

- (uint8_t)byte
{
  [self require:1];
  return _bytes[_offset++];
}

- (int64_t)integerSigned:(BOOL)isSigned
{
  int lead = (int)(int8_t)[self byte];
  uint32_t raw = 0;
  unsigned count, i;
  if (lead != TS_INTEGER16 && lead != TS_INTEGER32)
    {
      if (lead <= TS_RESERVED_LAST) [self decodeError:"expected integer"];
      return isSigned ? lead : (uint8_t)lead;
    }
  count = lead == TS_INTEGER16 ? 2 : 4;
  [self require:count];
  for (i = 0; i < count; i++)
    raw = (raw << 8) | _bytes[_offset + (_bigEndian ? i : count - i - 1)];
  _offset += count;
  if (isSigned)
    return count == 2 ? (int16_t)raw : (int32_t)raw;
  return raw;
}

- (NSUInteger)reference
{
  int64_t number = [self integerSigned:YES] - TS_REFERENCE_BASE;
  if (number < 0 || number > INT_MAX) [self decodeError:"invalid reference"];
  return (NSUInteger)number;
}

- (char *)textWithLength:(size_t *)length
{
  int64_t n = [self integerSigned:NO];
  char *p;
  if (n < 0 || n > 1048576) [self decodeError:"string length exceeds limit"];
  [self require:(size_t)n];
  p = [self allocate:(size_t)n + 1];
  memcpy(p, _bytes + _offset, (size_t)n);
  _offset += (size_t)n;
  *length = (size_t)n;
  return p;
}

- (ts_sharedref)sharedText
{
  ts_sharedref result;
  int head = [self peek];
  NSUInteger index;
  NSValue *entry;
  result.text = NULL; result.len = 0;
  if (head == TS_NIL) { _offset++; return result; }
  if (head == TS_NEW)
    {
      char *p;
      _offset++;
      p = [self textWithLength:&result.len];
      result.text = p;
      [_strings addObject:[NSValue valueWithPointer:p]];
      return result;
    }
  if (head <= TS_RESERVED_LAST && head != TS_INTEGER16 && head != TS_INTEGER32)
    [self decodeError:"invalid shared string tag"];
  index = [self reference];
  if (index >= [_strings count]) [self decodeError:"shared string reference out of range"];
  entry = [_strings objectAtIndex:index];
  result.text = [entry pointerValue];
  result.len = strlen(result.text);
  return result;
}

- (void)addEntity:(int)kind pointer:(void *)pointer
{
  TSEntity *entry = [self allocate:sizeof *entry];
  entry->kind = kind; entry->pointer = pointer;
  [_entities addObject:[NSValue valueWithPointer:entry]];
}

- (TSEntity *)entity:(NSUInteger)index kind:(int)kind
{
  TSEntity *entry;
  if (index >= [_entities count]) [self decodeError:"object reference out of range"];
  entry = [[_entities objectAtIndex:index] pointerValue];
  if (entry->kind != kind) [self decodeError:"object reference has wrong kind"];
  return entry;
}

- (ts_class *)readClass
{
  int head = [self peek];
  ts_class *c;
  if (_depth++ >= 128) [self decodeError:"nesting limit exceeded"];
  if (head == TS_NIL) { _offset++; c = NULL; }
  else if (head == TS_NEW)
    {
      _offset++;
      c = [self allocate:sizeof *c];
      c->byte_off = _offset - 1;
      c->id = _classID++;
      [self addEntity:TS_CLASS_ENTITY pointer:c];
      c->name = [self sharedText];
      if (!c->name.text || !c->name.len || strlen(c->name.text) != c->name.len)
        [self decodeError:"invalid class name"];
      c->version = [self integerSigned:YES];
      c->super = [self readClass];
    }
  else
    {
      if (head <= TS_RESERVED_LAST && head != TS_INTEGER16 && head != TS_INTEGER32)
        [self decodeError:"invalid class tag"];
      c = [self entity:[self reference] kind:TS_CLASS_ENTITY]->pointer;
    }
  _depth--;
  return c;
}

- (void)readGroup:(ts_group *)group
{
  int count, i, span;
  const char *p;
  char part[128];
  group->byte_off = _offset;
  group->encoding = [self sharedText];
  if (!group->encoding.text ||
      strlen(group->encoding.text) != group->encoding.len)
    [self decodeError:"invalid type encoding"];
  count = GSOpenStepTSTypeCount(group->encoding.text);
  if (count < 0) [self decodeError:"unsupported type encoding"];
  group->nvals = (size_t)count;
  group->vals = count ? [self allocate:(size_t)count * sizeof(ts_value)] : NULL;
  p = group->encoding.text;
  for (i = 0; i < count; i++)
    {
      span = GSOpenStepTSTypeSpan(p);
      if (span < 0 || span >= (int)sizeof part) [self decodeError:"type encoding too long"];
      memcpy(part, p, (size_t)span); part[span] = 0;
      group->vals[i].byte_off = _offset;
      [self readValue:&group->vals[i] encoding:part];
      p += span;
    }
}

- (void)readObject:(ts_value *)value
{
  int head = [self peek];
  size_t capacity = 0;
  ts_object *object;
  NSUInteger index;
  TSEntity *entry;
  if (head == TS_NIL) { _offset++; value->kind = TS_V_NIL; return; }
  if (head == TS_NEW)
    {
      _offset++;
      object = [self allocate:sizeof *object];
      object->byte_off = _offset - 1;
      object->id = _objectID++;
      [self addEntity:TS_OBJECT_ENTITY pointer:object];
      object->cls = [self readClass];
      if (!object->cls) [self decodeError:"object has no class"];
      while ([self peek] != TS_END)
        {
          ts_group *groups;
          if (object->ngroups == 1024) [self decodeError:"too many object groups"];
          if (object->ngroups == capacity)
            {
              capacity = capacity ? capacity * 2 : 4;
              groups = [self allocate:capacity * sizeof *groups];
              if (object->groups)
                memcpy(groups, object->groups, object->ngroups * sizeof *groups);
              object->groups = groups;
            }
          [self readGroup:&object->groups[object->ngroups]];
          object->ngroups++;
        }
      _offset++;
      object->byte_end = _offset;
      value->kind = TS_V_OBJECT;
      value->u.obj.o = object;
      return;
    }
  if (head <= TS_RESERVED_LAST && head != TS_INTEGER16 && head != TS_INTEGER32)
    [self decodeError:"invalid object tag"];
  index = [self reference];
  if (index >= [_entities count]) [self decodeError:"object reference out of range"];
  entry = [[_entities objectAtIndex:index] pointerValue];
  if (entry->kind == TS_CLASS_ENTITY)
    { value->kind = TS_V_CLASS; value->u.cls.c = entry->pointer; }
  else if (entry->kind == TS_OBJECT_ENTITY)
    { value->kind = TS_V_OBJECT; value->u.obj.o = entry->pointer; }
  else [self decodeError:"invalid object reference kind"];
}

- (void)readReal:(ts_value *)value doublePrecision:(BOOL)isDouble
{
  uint64_t bits = 0;
  unsigned count = isDouble ? 8 : 4, i;
  if ([self peek] != TS_REAL)
    { value->kind = TS_V_INT; value->u.i.v = [self integerSigned:YES]; return; }
  _offset++;
  [self require:count];
  for (i = 0; i < count; i++)
    bits = (bits << 8) | _bytes[_offset + (_bigEndian ? i : count - i - 1)];
  _offset += count;
  if (isDouble)
    { value->kind = TS_V_DOUBLE; memcpy(&value->u.d, &bits, 8); }
  else
    { uint32_t b = (uint32_t)bits; value->kind = TS_V_FLOAT;
      memcpy(&value->u.f, &b, 4); }
}

- (void)readValue:(ts_value *)value encoding:(const char *)encoding
{
  const char *p;
  char part[128];
  int span, head;
  size_t count, i, capacity;
  ts_value *values;
  ts_sharedref shared;
  TSEntity *entry;
  if (_depth++ >= 128) [self decodeError:"nesting limit exceeded"];
  switch (*encoding)
    {
    case 'c': case 'C': case 'B':
      value->kind = TS_V_BYTE; value->u.byte = [self byte]; break;
    case 's': case 'i': case 'l': case 'q':
      value->kind = TS_V_INT; value->u.i.v = [self integerSigned:YES]; break;
    case 'S': case 'I': case 'L': case 'Q':
      value->kind = TS_V_INT; value->u.i.v = [self integerSigned:NO]; break;
    case 'f': [self readReal:value doublePrecision:NO]; break;
    case 'd': [self readReal:value doublePrecision:YES]; break;
    case '@': case '^': [self readObject:value]; break;
    case '#':
      value->kind = TS_V_CLASS; value->u.cls.c = [self readClass]; break;
    case '+':
      value->kind = TS_V_STRING;
      value->u.str.p = [self textWithLength:&value->u.str.n]; break;
    case '%': case ':':
      value->kind = *encoding == '%' ? TS_V_SHARED : TS_V_SELECTOR;
      value->u.shared = [self sharedText]; break;
    case '*':
      value->kind = TS_V_CSTR;
      head = [self peek];
      if (head == TS_NIL) { _offset++; break; }
      if (head == TS_NEW)
        {
          _offset++;
          entry = [self allocate:sizeof *entry];
          entry->kind = TS_CSTRING_ENTITY;
          [_entities addObject:[NSValue valueWithPointer:entry]];
          shared = [self sharedText];
          entry->pointer = (void *)shared.text;
          value->u.shared = shared;
        }
      else
        {
          if (head <= TS_RESERVED_LAST && head != TS_INTEGER16 && head != TS_INTEGER32)
            [self decodeError:"invalid C string tag"];
          entry = [self entity:[self reference] kind:TS_CSTRING_ENTITY];
          value->u.shared.text = entry->pointer;
          value->u.shared.len = entry->pointer ? strlen(entry->pointer) : 0;
        }
      break;
    case '!': case 'v': value->kind = TS_V_NIL; break;
    case '[':
      p = encoding + 1; count = 0;
      while (*p >= '0' && *p <= '9')
        {
          if (count > (1048576u - (unsigned)(*p - '0')) / 10u)
            [self decodeError:"array count exceeds limit"];
          count = count * 10u + (unsigned)(*p++ - '0');
        }
      span = GSOpenStepTSTypeSpan(p);
      if (span < 0 || span >= (int)sizeof part) [self decodeError:"bad array type"];
      memcpy(part, p, (size_t)span); part[span] = 0;
      value->sub_encoding = [self allocate:(size_t)span + 1];
      memcpy(value->sub_encoding, part, (size_t)span + 1);
      if (span == 1 && (*p == 'c' || *p == 'C'))
        {
          [self require:count];
          value->kind = TS_V_STRING;
          value->u.str.p = [self allocate:count + 1];
          memcpy(value->u.str.p, _bytes + _offset, count);
          value->u.str.n = count; _offset += count;
          break;
        }
      value->kind = TS_V_ARRAY; value->u.list.n = count;
      value->u.list.v = count ? [self allocate:count * sizeof(ts_value)] : NULL;
      for (i = 0; i < count; i++)
        { value->u.list.v[i].byte_off = _offset;
          [self readValue:&value->u.list.v[i] encoding:part]; }
      break;
    case '{': case '(':
      value->kind = TS_V_STRUCT;
      value->sub_encoding = [self allocate:strlen(encoding) + 1];
      strcpy(value->sub_encoding, encoding);
      p = encoding + 1;
      while (*p && *p != '=' && *p != '}' && *p != ')') p++;
      if (*p == '=') p++;
      capacity = 0;
      while (*p && *p != '}' && *p != ')')
        {
          span = GSOpenStepTSTypeSpan(p);
          if (span < 0 || span >= (int)sizeof part) [self decodeError:"bad structure type"];
          memcpy(part, p, (size_t)span); part[span] = 0;
          if (value->u.list.n == capacity)
            {
              capacity = capacity ? capacity * 2 : 4;
              values = [self allocate:capacity * sizeof *values];
              if (value->u.list.v)
                memcpy(values, value->u.list.v, value->u.list.n * sizeof *values);
              value->u.list.v = values;
            }
          value->u.list.v[value->u.list.n].byte_off = _offset;
          [self readValue:&value->u.list.v[value->u.list.n] encoding:part];
          value->u.list.n++; p += span;
        }
      break;
    default: [self decodeError:"unsupported value type"];
    }
  _depth--;
}

- (void)readArchive:(ts_archive *)archive
{
  uint8_t signatureLength;
  size_t capacity = 0;
  ts_group *groups;
  archive->streamer_version = [self byte];
  if (archive->streamer_version != 3 && archive->streamer_version != 4)
    [self decodeError:"unsupported streamer version"];
  signatureLength = [self byte];
  if (signatureLength != 11) [self decodeError:"invalid signature length"];
  [self require:signatureLength];
  memcpy(archive->signature, _bytes + _offset, signatureLength);
  _offset += signatureLength;
  if (!strcmp(archive->signature, "streamtyped")) _bigEndian = NO;
  else if (!strcmp(archive->signature, "typedstream")) _bigEndian = YES;
  else [self decodeError:"invalid typed stream signature"];
  archive->big_endian = _bigEndian;
  archive->system_version = [self integerSigned:NO];
  while (_offset < _length)
    {
      if (archive->nroot == 1024) [self decodeError:"too many root groups"];
      if (archive->nroot == capacity)
        {
          capacity = capacity ? capacity * 2 : 4;
          groups = [self allocate:capacity * sizeof *groups];
          if (archive->root)
            memcpy(groups, archive->root, archive->nroot * sizeof *groups);
          archive->root = groups;
        }
      [self readGroup:&archive->root[archive->nroot]];
      archive->nroot++;
    }
}
@end

ts_archive *GSOpenStepTSReadMemory(const uint8_t *bytes, size_t length,
                                   ts_err *error)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  GSOpenStepStreamDecoder *reader;
  ts_archive *archive = calloc(1, sizeof *archive);
  if (!error) { [pool release]; free(archive); return NULL; }
  error->ok = 1; error->off = 0; error->msg[0] = 0;
  if (!archive)
    { error->ok = 0; strcpy(error->msg, "out of memory"); [pool release]; return NULL; }
  reader = [[GSOpenStepStreamDecoder alloc] initWithBytes:bytes length:length error:error];
  @try { [reader readArchive:archive]; archive->pool = reader; }
  @catch (NSException *exception)
    {
      if (error->ok)
        { error->ok = 0; snprintf(error->msg, sizeof error->msg,
                                 "decoder exception: %s", [[exception reason] UTF8String]); }
      [reader releaseAllocations]; [reader release]; free(archive); archive = NULL;
    }
  [pool release];
  return archive;
}

void GSOpenStepTSFree(ts_archive *archive)
{
  GSOpenStepStreamDecoder *reader;
  if (!archive) return;
  reader = archive->pool;
  [reader releaseAllocations]; [reader release]; free(archive);
}
