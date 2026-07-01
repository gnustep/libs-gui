/*
   GSNibArchiveKeyedUnarchiver.m

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Copyright (C) 2026 Free Software Foundation, Inc.

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

#import "config.h"
#import <string.h>

#import <AppKit/NSGraphics.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "GNUstepGUI/GSNibArchiveKeyedUnarchiver.h"
#import "GNUstepGUI/GSNibLoading.h"

#define NIBARCHIVE_MAGIC "NIBArchive"
#define NIBARCHIVE_MAGIC_LENGTH 10

enum
{
  GSNibArchiveTypeInt8 = 0,
  GSNibArchiveTypeInt16 = 1,
  GSNibArchiveTypeInt32 = 2,
  GSNibArchiveTypeInt64 = 3,
  GSNibArchiveTypeBoolFalse = 4,
  GSNibArchiveTypeBoolTrue = 5,
  GSNibArchiveTypeFloat = 6,
  GSNibArchiveTypeDouble = 7,
  GSNibArchiveTypeData = 8,
  GSNibArchiveTypeNil = 9,
  GSNibArchiveTypeObjectRef = 10
};

static uint32_t
GSReadLE32(const uint8_t *bytes)
{
  return ((uint32_t)bytes[0])
    | (((uint32_t)bytes[1]) << 8)
    | (((uint32_t)bytes[2]) << 16)
    | (((uint32_t)bytes[3]) << 24);
}

static uint64_t
GSReadLE64(const uint8_t *bytes)
{
  return ((uint64_t)GSReadLE32(bytes))
    | (((uint64_t)GSReadLE32(bytes + 4)) << 32);
}

static BOOL
GSReadVarInt(const uint8_t *bytes, NSUInteger length, NSUInteger *offset,
  NSInteger *result)
{
  NSUInteger value = 0;
  NSUInteger max = ((NSUInteger)~0) >> 1;
  unsigned shift = 0;

  while (*offset < length && shift < (sizeof(NSUInteger) * 8))
    {
      uint8_t b = bytes[(*offset)++];
      NSUInteger bits = (NSUInteger)(b & 0x7f);

      if (bits > (max >> shift))
	{
	  return NO;
	}
      value |= bits << shift;
      if ((b & 0x80) != 0)
	{
	  *result = (NSInteger)value;
	  return YES;
	}
      shift += 7;
    }

  return NO;
}

static BOOL
GSCanReadBytes(NSUInteger offset, NSUInteger count, NSUInteger length)
{
  return offset <= length && count <= length - offset;
}

@interface GSNibArchiveObject : NSObject
{
@public
  NSInteger classNameIndex;
  NSInteger valuesIndex;
  NSInteger valueCount;
}
@end

@implementation GSNibArchiveObject
@end

@interface GSNibArchiveValue : NSObject
{
@public
  NSInteger keyIndex;
  uint8_t type;
  id object;
  uint32_t reference;
}
@end

@implementation GSNibArchiveValue
- (void) dealloc
{
  RELEASE(object);
  [super dealloc];
}
@end

@interface GSNibArchiveClassName : NSObject
{
@public
  NSString *name;
  NSArray *fallbackClassIndexes;
}
@end

@implementation GSNibArchiveClassName
- (void) dealloc
{
  RELEASE(name);
  RELEASE(fallbackClassIndexes);
  [super dealloc];
}
@end

@interface GSNibArchiveKeyedUnarchiver (Private)
- (BOOL) _parseData: (NSData *)data;
- (id) _decodeObjectAtIndex: (NSUInteger)index;
- (GSNibArchiveValue *) _valueForKey: (NSString *)key;
- (id) _objectForValue: (GSNibArchiveValue *)value;
- (NSNumber *) _numberForValue: (GSNibArchiveValue *)value;
- (double) _doubleForValue: (GSNibArchiveValue *)value;
- (NSPoint) _pointForValue: (GSNibArchiveValue *)value;
- (NSSize) _sizeForValue: (GSNibArchiveValue *)value;
- (NSRect) _rectForValue: (GSNibArchiveValue *)value;
- (void) _recordCustomClasses;
- (GSNibArchiveClassName *) _fallbackArchiveClassNameForClassName:
  (GSNibArchiveClassName *)archiveClass;
- (NSString *) _substituteClassForClassName: (NSString *)className;
- (id) _decodeArrayOfObjectsForKey: (NSString *)key;
- (id) _decodePropertyListForKey: (NSString *)key;
@end

@implementation GSNibArchiveKeyedUnarchiver
+ (BOOL) canReadData: (NSData *)data
{
  if ([data length] < NIBARCHIVE_MAGIC_LENGTH)
    {
      return NO;
    }

  return memcmp([data bytes], NIBARCHIVE_MAGIC, NIBARCHIVE_MAGIC_LENGTH) == 0;
}

- (id) initForReadingWithData: (NSData *)data
{
  if (data == nil || ![[self class] canReadData: data])
    {
      DESTROY(self);
      return nil;
    }

  _objectZone = NSDefaultMallocZone();
  ASSIGN(_data, data);
  _bytes = [_data bytes];
  _length = [_data length];
  _m_objects = [[NSMutableArray alloc] init];
  _keys = [[NSMutableArray alloc] init];
  _values = [[NSMutableArray alloc] init];
  _classNames = [[NSMutableArray alloc] init];
  _decodedObjects = [[NSMutableDictionary alloc] init];
  _classNameMap = [[NSMutableDictionary alloc] init];
  _customClasses = [[NSMutableDictionary alloc] init];
  _objectStack = [[NSMutableArray alloc] init];
  _cursorStack = [[NSMutableArray alloc] init];

  if ([self _parseData: data] == NO)
    {
      DESTROY(self);
      return nil;
    }
  [self _recordCustomClasses];

  return self;
}

- (void) dealloc
{
  DESTROY(_data);
  DESTROY(_m_objects);
  DESTROY(_keys);
  DESTROY(_values);
  DESTROY(_classNames);
  DESTROY(_decodedObjects);
  DESTROY(_classNameMap);
  DESTROY(_customClasses);
  DESTROY(_objectStack);
  DESTROY(_cursorStack);
  [super dealloc];
}

- (BOOL) allowsKeyedCoding
{
  return YES;
}

- (id) delegate
{
  return _na_delegate;
}

- (void) setDelegate: (id)delegate
{
  _na_delegate = delegate;
}

- (void) finishDecoding
{
  [_na_delegate unarchiverWillFinish: self];
  [_na_delegate unarchiverDidFinish: self];
}

- (void) setObjectZone: (NSZone *)zone
{
  _objectZone = zone;
}

- (NSZone *) objectZone
{
  return _objectZone;
}

- (Class) classForClassName: (NSString *)className
{
  return [_classNameMap objectForKey: className];
}

- (void) setClass: (Class)aClass forClassName: (NSString *)className
{
  if (className == nil)
    {
      return;
    }
  if (aClass == nil)
    {
      [_classNameMap removeObjectForKey: className];
    }
  else
    {
      [_classNameMap setObject: aClass forKey: className];
    }
}

- (NSDictionary *) customClasses
{
  return _customClasses;
}

- (void) _recordCustomClasses
{
  NSEnumerator *enumerator = [_classNames objectEnumerator];
  GSNibArchiveClassName *archiveClass;

  while ((archiveClass = [enumerator nextObject]) != nil)
    {
      GSNibArchiveClassName *fallbackClass;

      fallbackClass = [self _fallbackArchiveClassNameForClassName:
	archiveClass];
      if (fallbackClass != nil)
	{
	  NSDictionary *dict;

	  dict = [NSDictionary dictionaryWithObject: fallbackClass->name
					     forKey: @"parentClassName"];
	  [_customClasses setObject: dict forKey: archiveClass->name];
	}
    }
}

- (BOOL) _parseData: (NSData *)data
{
  uint32_t objectCount;
  uint32_t offsetObjects;
  uint32_t keyCount;
  uint32_t offsetKeys;
  uint32_t valueCount;
  uint32_t offsetValues;
  uint32_t classNameCount;
  uint32_t offsetClassNames;
  NSUInteger offset;
  NSUInteger i;

  if (_length < 50)
    {
      return NO;
    }

  objectCount = GSReadLE32(_bytes + 18);
  offsetObjects = GSReadLE32(_bytes + 22);
  keyCount = GSReadLE32(_bytes + 26);
  offsetKeys = GSReadLE32(_bytes + 30);
  valueCount = GSReadLE32(_bytes + 34);
  offsetValues = GSReadLE32(_bytes + 38);
  classNameCount = GSReadLE32(_bytes + 42);
  offsetClassNames = GSReadLE32(_bytes + 46);

  if (offsetObjects > _length || offsetKeys > _length
    || offsetValues > _length || offsetClassNames > _length)
    {
      return NO;
    }

  offset = offsetObjects;
  for (i = 0; i < objectCount; i++)
    {
      NSInteger classNameIndex;
      NSInteger valuesIndex;
      NSInteger count;
      GSNibArchiveObject *object;

      if (!GSReadVarInt(_bytes, _length, &offset, &classNameIndex)
	|| !GSReadVarInt(_bytes, _length, &offset, &valuesIndex)
	|| !GSReadVarInt(_bytes, _length, &offset, &count)
	|| classNameIndex < 0 || valuesIndex < 0 || count < 0
	|| (NSUInteger)classNameIndex >= classNameCount
	|| (NSUInteger)valuesIndex > valueCount
	|| (NSUInteger)count > valueCount - (NSUInteger)valuesIndex)
	{
	  return NO;
	}

      object = [[GSNibArchiveObject alloc] init];
      object->classNameIndex = classNameIndex;
      object->valuesIndex = valuesIndex;
      object->valueCount = count;
      [_m_objects addObject: object];
      RELEASE(object);
    }
  if (offset != offsetKeys)
    {
      return NO;
    }

  for (i = 0; i < keyCount; i++)
    {
      NSInteger stringLength;
      NSString *key;

      if (!GSReadVarInt(_bytes, _length, &offset, &stringLength)
	|| stringLength < 0
	|| !GSCanReadBytes(offset, (NSUInteger)stringLength, _length))
	{
	  return NO;
	}
      key = [[NSString alloc] initWithBytes: _bytes + offset
				     length: stringLength
				   encoding: NSUTF8StringEncoding];
      if (key == nil)
	{
	  return NO;
	}
      [_keys addObject: key];
      RELEASE(key);
      offset += stringLength;
    }
  if (offset != offsetValues)
    {
      return NO;
    }

  for (i = 0; i < valueCount; i++)
    {
      NSInteger keyIndex;
      GSNibArchiveValue *value;
      BOOL valid = YES;

      if (!GSReadVarInt(_bytes, _length, &offset, &keyIndex)
	|| keyIndex < 0 || (NSUInteger)keyIndex >= keyCount
	|| offset >= _length)
	{
	  return NO;
	}

      value = [[GSNibArchiveValue alloc] init];
      value->keyIndex = keyIndex;
      value->type = _bytes[offset++];

      switch (value->type)
	{
	  case GSNibArchiveTypeInt8:
	    if (!GSCanReadBytes(offset, 1, _length))
	      {
		valid = NO;
		break;
	      }
	    value->object = RETAIN([NSNumber numberWithChar: (int8_t)_bytes[offset]]);
	    offset += 1;
	    break;
	  case GSNibArchiveTypeInt16:
	    if (!GSCanReadBytes(offset, 2, _length))
	      {
		valid = NO;
		break;
	      }
	    value->object = RETAIN([NSNumber numberWithShort:
	      (int16_t)(_bytes[offset] | (_bytes[offset + 1] << 8))]);
	    offset += 2;
	    break;
	  case GSNibArchiveTypeInt32:
	    if (!GSCanReadBytes(offset, 4, _length))
	      {
		valid = NO;
		break;
	      }
	    value->object = RETAIN([NSNumber numberWithInt:
	      (int32_t)GSReadLE32(_bytes + offset)]);
	    offset += 4;
	    break;
	  case GSNibArchiveTypeInt64:
	    if (!GSCanReadBytes(offset, 8, _length))
	      {
		valid = NO;
		break;
	      }
	    value->object = RETAIN([NSNumber numberWithLongLong:
	      (int64_t)GSReadLE64(_bytes + offset)]);
	    offset += 8;
	    break;
	  case GSNibArchiveTypeBoolFalse:
	    value->object = RETAIN([NSNumber numberWithBool: NO]);
	    break;
	  case GSNibArchiveTypeBoolTrue:
	    value->object = RETAIN([NSNumber numberWithBool: YES]);
	    break;
	  case GSNibArchiveTypeFloat:
	    {
	      uint32_t bits;
	      float f;
	      if (!GSCanReadBytes(offset, 4, _length))
		{
		  valid = NO;
		  break;
		}
	      bits = GSReadLE32(_bytes + offset);
	      memcpy(&f, &bits, sizeof(f));
	      value->object = RETAIN([NSNumber numberWithFloat: f]);
	      offset += 4;
	    }
	    break;
	  case GSNibArchiveTypeDouble:
	    {
	      uint64_t bits;
	      double d;
	      if (!GSCanReadBytes(offset, 8, _length))
		{
		  valid = NO;
		  break;
		}
	      bits = GSReadLE64(_bytes + offset);
	      memcpy(&d, &bits, sizeof(d));
	      value->object = RETAIN([NSNumber numberWithDouble: d]);
	      offset += 8;
	    }
	    break;
	  case GSNibArchiveTypeData:
	    {
	      NSInteger dataLength;
	      if (!GSReadVarInt(_bytes, _length, &offset, &dataLength)
		|| dataLength < 0
		|| !GSCanReadBytes(offset, (NSUInteger)dataLength, _length))
		{
		  valid = NO;
		  break;
		}
	      value->object = [[NSData alloc] initWithBytes: _bytes + offset
						     length: dataLength];
	      offset += dataLength;
	    }
	    break;
	  case GSNibArchiveTypeNil:
	    break;
	  case GSNibArchiveTypeObjectRef:
	    if (!GSCanReadBytes(offset, 4, _length))
	      {
		valid = NO;
		break;
	      }
	    value->reference = GSReadLE32(_bytes + offset);
	    if (value->reference >= objectCount)
	      {
		valid = NO;
		break;
	      }
	    offset += 4;
	    break;
	  default:
	    valid = NO;
	    break;
	}

      if (valid == NO)
	{
	  RELEASE(value);
	  return NO;
	}
      [_values addObject: value];
      RELEASE(value);
    }
  if (offset != offsetClassNames)
    {
      return NO;
    }

  for (i = 0; i < classNameCount; i++)
    {
      NSInteger stringLength;
      NSInteger fallbackCount;
      NSMutableArray *fallbacks;
      GSNibArchiveClassName *className;

      if (!GSReadVarInt(_bytes, _length, &offset, &stringLength)
	|| !GSReadVarInt(_bytes, _length, &offset, &fallbackCount)
	|| stringLength <= 0 || fallbackCount < 0)
	{
	  return NO;
	}

      fallbacks = [NSMutableArray arrayWithCapacity: fallbackCount];
      while (fallbackCount-- > 0)
	{
	  int32_t fallbackIndex;

	  if (!GSCanReadBytes(offset, 4, _length))
	    {
	      return NO;
	    }
	  fallbackIndex = (int32_t)GSReadLE32(_bytes + offset);
	  if (fallbackIndex < 0 || (NSUInteger)fallbackIndex >= classNameCount)
	    {
	      return NO;
	    }
	  [fallbacks addObject: [NSNumber numberWithInt: fallbackIndex]];
	  offset += 4;
	}

      if (!GSCanReadBytes(offset, (NSUInteger)stringLength, _length)
	|| _bytes[offset + (NSUInteger)stringLength - 1] != '\0')
	{
	  return NO;
	}

      className = [[GSNibArchiveClassName alloc] init];
      className->name = [[NSString alloc] initWithBytes: _bytes + offset
						 length: stringLength - 1
					       encoding: NSUTF8StringEncoding];
      if (className->name == nil)
	{
	  RELEASE(className);
	  return NO;
	}
      className->fallbackClassIndexes = RETAIN(fallbacks);
      [_classNames addObject: className];
      RELEASE(className);
      offset += stringLength;
    }

  return YES;
}

- (NSString *) _keyForValue: (GSNibArchiveValue *)value
{
  return [_keys objectAtIndex: value->keyIndex];
}

- (GSNibArchiveObject *) _currentObject
{
  return [_objectStack lastObject];
}

- (GSNibArchiveValue *) _valueForKey: (NSString *)key
{
  GSNibArchiveObject *object = [self _currentObject];
  NSUInteger start;
  NSUInteger end;
  NSUInteger i;

  if (object == nil)
    {
      return nil;
    }

  start = object->valuesIndex;
  end = start + object->valueCount;
  for (i = start; i < end; i++)
    {
      GSNibArchiveValue *value = [_values objectAtIndex: i];
      if ([[self _keyForValue: value] isEqual: key])
	{
	  return value;
	}
    }

  return nil;
}

- (GSNibArchiveValue *) _nextSequentialValue
{
  GSNibArchiveObject *object = [self _currentObject];
  NSUInteger cursor;

  if (object == nil || [_cursorStack count] == 0)
    {
      return nil;
    }

  cursor = [[_cursorStack lastObject] unsignedIntegerValue];
  if (cursor >= (NSUInteger)object->valueCount)
    {
      return nil;
    }

  [_cursorStack removeLastObject];
  [_cursorStack addObject: [NSNumber numberWithUnsignedInteger: cursor + 1]];
  return [_values objectAtIndex: object->valuesIndex + cursor];
}

- (GSNibArchiveClassName *) _fallbackArchiveClassNameForClassName:
  (GSNibArchiveClassName *)archiveClass
{
  NSEnumerator *enumerator;
  NSNumber *fallbackIndex;

  enumerator = [archiveClass->fallbackClassIndexes objectEnumerator];
  while ((fallbackIndex = [enumerator nextObject]) != nil)
    {
      GSNibArchiveClassName *fallback;

      fallback = [_classNames objectAtIndex:
	[fallbackIndex unsignedIntegerValue]];
      if (NSClassFromString(fallback->name) != Nil
	|| [[self class] classForClassName: fallback->name] != Nil
	|| [self classForClassName: fallback->name] != Nil)
	{
	  return fallback;
	}
    }

  return nil;
}

- (NSString *) _substituteClassForClassName: (NSString *)className
{
  NSString *result = className;
  NSDictionary *dict = [_customClasses objectForKey: className];

  if (dict != nil)
    {
      result = [dict objectForKey: @"parentClassName"];
    }

  return result;
}

- (Class) _classForArchiveClassName: (GSNibArchiveClassName *)archiveClass
{
  NSString *className = archiveClass->name;
  Class class;

  if ([NSClassSwapper isInInterfaceBuilder] == YES)
    {
      className = [self _substituteClassForClassName: className];
    }

  class = [self classForClassName: className];

  if (class == Nil)
    {
      class = [[self class] classForClassName: className];
    }
  if (class == Nil)
    {
      class = NSClassFromString(className);
    }
  if (class == Nil)
    {
      NSEnumerator *enumerator = [archiveClass->fallbackClassIndexes objectEnumerator];
      NSNumber *fallbackIndex;

      while ((fallbackIndex = [enumerator nextObject]) != nil && class == Nil)
	{
	  GSNibArchiveClassName *fallback =
	    [_classNames objectAtIndex: [fallbackIndex unsignedIntegerValue]];
	  class = [self _classForArchiveClassName: fallback];
	}
    }
  if (class == Nil && _na_delegate != nil)
    {
      class = [_na_delegate unarchiver: self
			    cannotDecodeObjectOfClassName: className
		       originalClasses: nil];
    }

  return class;
}

- (id) _decodeObjectAtIndex: (NSUInteger)index
{
  NSNumber *key = [NSNumber numberWithUnsignedInteger: index];
  id object = [_decodedObjects objectForKey: key];
  GSNibArchiveObject *archiveObject;
  GSNibArchiveClassName *archiveClass;
  Class class;
  id result;

  if (object != nil)
    {
      return object;
    }

  archiveObject = [_m_objects objectAtIndex: index];
  archiveClass = [_classNames objectAtIndex: archiveObject->classNameIndex];
  class = [self _classForArchiveClassName: archiveClass];
  if (class == Nil)
    {
      [NSException raise: NSInvalidUnarchiveOperationException
		  format: @"[%@ -%@]: no class for name '%@'",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	archiveClass->name];
    }

  object = [class allocWithZone: _objectZone];
  [_decodedObjects setObject: object forKey: key];
  [_objectStack addObject: archiveObject];
  [_cursorStack addObject: [NSNumber numberWithUnsignedInteger: 0]];

  result = [object initWithCoder: self];

  [_cursorStack removeLastObject];
  [_objectStack removeLastObject];

  if (result != object)
    {
      [_na_delegate unarchiver: self
	     willReplaceObject: object
		    withObject: result];

      [_decodedObjects setObject: result forKey: key];

      RELEASE(object);
      object = RETAIN(result);
    }

  result = [object awakeAfterUsingCoder: self];
  if (result != object)
    {
      [_na_delegate unarchiver: self
	     willReplaceObject: object
		    withObject: result];

      [_decodedObjects setObject: result forKey: key];

      RELEASE(object);
      object = RETAIN(result);
    }

  if (_na_delegate != nil)
    {
      result = [_na_delegate unarchiver: self didDecodeObject: object];
      if (result != object)
	{
	  [_na_delegate unarchiver: self
		 willReplaceObject: object
			withObject: result];

	  [_decodedObjects setObject: result forKey: key];

	  RELEASE(object);
	  object = RETAIN(result);
	}
    }

  RELEASE(object);
  return [_decodedObjects objectForKey: key];
}

- (NSNumber *) _numberForValue: (GSNibArchiveValue *)value
{
  id object = [self _objectForValue: value];

  if (object == nil || [object isKindOfClass: [NSNumber class]])
    {
      return object;
    }

  [NSException raise: NSInvalidUnarchiveOperationException
	      format: @"[%@ -%@]: value for key(%@) is '%@'",
    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
    [self _keyForValue: value], object];
  return nil;
}

- (double) _doubleForValue: (GSNibArchiveValue *)value
{
  return [[self _numberForValue: value] doubleValue];
}

- (id) _objectForValue: (GSNibArchiveValue *)value
{
  if (value == nil)
    {
      return nil;
    }

  if (value->type == GSNibArchiveTypeObjectRef)
    {
      return [self _decodeObjectAtIndex: value->reference];
    }
  if (value->type == GSNibArchiveTypeNil)
    {
      return nil;
    }
  if (value->type == GSNibArchiveTypeData)
    {
      return value->object;
    }

  return value->object;
}

- (NSPoint) _pointForValue: (GSNibArchiveValue *)value
{
  id object = [self _objectForValue: value];
  NSPoint point = NSZeroPoint;

  if (object == nil)
    {
      return point;
    }
  if ([object isKindOfClass: [NSValue class]]
    && strcmp([object objCType], @encode(NSPoint)) == 0)
    {
      [object getValue: &point];
      return point;
    }

  [NSException raise: NSInvalidUnarchiveOperationException
	      format: @"[%@ -%@]: value for key(%@) is '%@'",
    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
    [self _keyForValue: value], object];
  return point;
}

- (NSSize) _sizeForValue: (GSNibArchiveValue *)value
{
  id object = [self _objectForValue: value];
  NSSize size = NSZeroSize;

  if (object == nil)
    {
      return size;
    }
  if ([object isKindOfClass: [NSValue class]]
    && strcmp([object objCType], @encode(NSSize)) == 0)
    {
      [object getValue: &size];
      return size;
    }

  [NSException raise: NSInvalidUnarchiveOperationException
	      format: @"[%@ -%@]: value for key(%@) is '%@'",
    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
    [self _keyForValue: value], object];
  return size;
}

- (NSRect) _rectForValue: (GSNibArchiveValue *)value
{
  id object = [self _objectForValue: value];
  NSRect rect = NSZeroRect;

  if (object == nil)
    {
      return rect;
    }
  if ([object isKindOfClass: [NSValue class]]
    && strcmp([object objCType], @encode(NSRect)) == 0)
    {
      [object getValue: &rect];
      return rect;
    }

  [NSException raise: NSInvalidUnarchiveOperationException
	      format: @"[%@ -%@]: value for key(%@) is '%@'",
    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
    [self _keyForValue: value], object];
  return rect;
}

- (BOOL) containsValueForKey: (NSString *)key
{
  if ([self _currentObject] == nil
    && ([key isEqual: @"IB.objectdata"] || [key isEqual: @"root"]))
    {
      return [_m_objects count] > 0;
    }

  return [self _valueForKey: key] != nil;
}

- (id) decodeObjectForKey: (NSString *)key
{
  if ([self _currentObject] == nil
    && ([key isEqual: @"IB.objectdata"] || [key isEqual: @"root"]))
    {
      return [_m_objects count] > 0 ? [self _decodeObjectAtIndex: 0] : nil;
    }

  return [self _objectForValue: [self _valueForKey: key]];
}

- (id) decodeObject
{
  return [self _objectForValue: [self _nextSequentialValue]];
}

- (BOOL) decodeBoolForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] boolValue];
}

- (double) decodeDoubleForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] doubleValue];
}

- (float) decodeFloatForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] floatValue];
}

- (int) decodeIntForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] intValue];
}

- (NSInteger) decodeIntegerForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] integerValue];
}

- (int32_t) decodeInt32ForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] intValue];
}

- (int64_t) decodeInt64ForKey: (NSString *)key
{
  return [[self _numberForValue: [self _valueForKey: key]] longLongValue];
}

- (NSPoint) decodePointForKey: (NSString *)key
{
  return [self _pointForValue: [self _valueForKey: key]];
}

- (NSSize) decodeSizeForKey: (NSString *)key
{
  return [self _sizeForValue: [self _valueForKey: key]];
}

- (NSRect) decodeRectForKey: (NSString *)key
{
  return [self _rectForValue: [self _valueForKey: key]];
}

- (const uint8_t *) decodeBytesForKey: (NSString *)key
		       returnedLength: (NSUInteger *)length
{
  GSNibArchiveValue *value = [self _valueForKey: key];

  if (value != nil && value->type == GSNibArchiveTypeData)
    {
      if (length != NULL)
	{
	  *length = [value->object length];
	}
      return [value->object bytes];
    }

  if (length != NULL)
    {
      *length = 0;
    }
  return NULL;
}

- (void) decodeValueOfObjCType: (const char *)type at: (void *)address
{
  GSNibArchiveValue *value;
  id object;

  if (type == NULL || address == NULL)
    {
      return;
    }

  value = [self _nextSequentialValue];
  object = [self _objectForValue: value];

  if (strcmp(type, @encode(NSPoint)) == 0)
    {
      NSPoint point;

      if ([object isKindOfClass: [NSValue class]]
	&& strcmp([object objCType], @encode(NSPoint)) == 0)
	{
	  [object getValue: &point];
	}
      else
	{
	  point.x = [self _doubleForValue: value];
	  point.y = [self _doubleForValue: [self _nextSequentialValue]];
	}
      *(NSPoint *)address = point;
      return;
    }
  if (strcmp(type, @encode(NSSize)) == 0)
    {
      NSSize size;

      if ([object isKindOfClass: [NSValue class]]
	&& strcmp([object objCType], @encode(NSSize)) == 0)
	{
	  [object getValue: &size];
	}
      else
	{
	  size.width = [self _doubleForValue: value];
	  size.height = [self _doubleForValue: [self _nextSequentialValue]];
	}
      *(NSSize *)address = size;
      return;
    }
  if (strcmp(type, @encode(NSRect)) == 0)
    {
      NSRect rect;

      if ([object isKindOfClass: [NSValue class]]
	&& strcmp([object objCType], @encode(NSRect)) == 0)
	{
	  [object getValue: &rect];
	}
      else
	{
	  rect.origin.x = [self _doubleForValue: value];
	  rect.origin.y = [self _doubleForValue: [self _nextSequentialValue]];
	  rect.size.width = [self _doubleForValue: [self _nextSequentialValue]];
	  rect.size.height = [self _doubleForValue: [self _nextSequentialValue]];
	}
      *(NSRect *)address = rect;
      return;
    }

  switch (*type)
    {
      case _C_ID:
      case _C_CLASS:
	*(id *)address = RETAIN(object);
	return;
      case _C_SEL:
	*(SEL *)address = NSSelectorFromString(object);
	return;
      case _C_CHR:
	*(char *)address = [object charValue];
	return;
      case _C_UCHR:
	*(unsigned char *)address = [object unsignedCharValue];
	return;
      case _C_SHT:
	*(short *)address = [object shortValue];
	return;
      case _C_USHT:
	*(unsigned short *)address = [object unsignedShortValue];
	return;
      case _C_INT:
	*(int *)address = [object intValue];
	return;
      case _C_UINT:
	*(unsigned int *)address = [object unsignedIntValue];
	return;
      case _C_LNG:
	*(long *)address = [object longValue];
	return;
      case _C_ULNG:
	*(unsigned long *)address = [object unsignedLongValue];
	return;
      case _C_LNG_LNG:
	*(long long *)address = [object longLongValue];
	return;
      case _C_ULNG_LNG:
	*(unsigned long long *)address = [object unsignedLongLongValue];
	return;
      case _C_FLT:
	*(float *)address = [object floatValue];
	return;
      case _C_DBL:
	*(double *)address = [object doubleValue];
	return;
#if defined(_C_BOOL) && (!defined(__GNUC__) || __GNUC__ > 2)
      case _C_BOOL:
	*(_Bool *)address = (_Bool)[object boolValue];
	return;
#endif
      default:
	[NSException raise: NSInvalidArgumentException
		    format: @"-[%@ %@]: unsupported type encoding ('%c')",
	  NSStringFromClass([self class]), NSStringFromSelector(_cmd), *type];
    }
}

- (id) _decodeArrayOfObjectsForKey: (NSString *)key
{
  id object = [self decodeObjectForKey: key];

  if (object == nil || [object isKindOfClass: [NSArray class]])
    {
      return object;
    }

  return nil;
}

- (id) _decodePropertyListForKey: (NSString *)key
{
  return [self decodeObjectForKey: key];
}

@end
