/*
    GSTIMKeyBindingTable.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date: April 2004

    This file is part of the GNUstep GUI Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include "AppKit/NSEvent.h"
#include "GSTIMKeyStroke.h"
#include "GSTIMKeyBindingTable.h"

@implementation GSTIMKeyBindingTable

- (id)initWithKeyBindingDictionary: (NSDictionary *)bindingDictionary
{
  if ((self = [super init]) != nil)
    {
      NSMutableDictionary *draft = [[NSMutableDictionary alloc] init];
      [self compileBindings: draft
		 withSource: bindingDictionary];
      [self setBindings: draft];
      [draft release], draft = nil;
    }
  return self;
}


- (void)setBindings: (NSDictionary *)newBindings
{
  [newBindings retain];
  [bindings release];
  bindings = newBindings;
}


- (NSDictionary *)bindings
{
  return bindings;
}


- (GSTIMKeyStroke *)compileForKeyStroke: (NSString *)aStroke
{
  GSTIMKeyStroke    *compiledKey = [GSTIMKeyStroke characterWithCharacter: 0
								modifiers: 0];
  NSMutableString   *key = nil;
  NSRange	    range;

  if ([aStroke length] == 1)
    {
      if ([GSTIMKeyStroke shouldNeedShiftKeyMaskForCharacter:
	                    [key characterAtIndex: 0]])
	{
	  [compiledKey setShiftKeyMask];
	}
      else
	{
	  [compiledKey clearShiftKeyMask];
	}

      if ([aStroke isEqualToString: @"\177"])
	{
	  /* N.B.: NSTextView regards Delete as a function key. */
	  [compiledKey setFunctionKeyMask];
	  [compiledKey setCharacter: NSDeleteFunctionKey];
	}
      else
	{
	  [compiledKey setCharacter: [aStroke characterAtIndex: 0]];
	}

      return compiledKey;
    }

  key = [aStroke mutableCopy];
  while (1)
    {
      NSString *original = [key copy];

      range = [key rangeOfString: @"~"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setAlternateKeyMask];
	  [key deleteCharactersInRange: range];
	}

      range = [key rangeOfString: @"^"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setControlKeyMask];
	  [key deleteCharactersInRange: range];
	}

      range = [key rangeOfString: @"$"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setShiftKeyMask];
	  [key deleteCharactersInRange: range];
	}

      range = [key rangeOfString: @"#"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setNumericPadKeyMask];
	  [key deleteCharactersInRange: range];
	}

      if ([key isEqualToString: original])
	{
	  [original release], original = nil;
	  break;
	}
      [original release], original = nil;
    }
  if ([GSTIMKeyStroke isFunctionKeyName: key])
    {
      [compiledKey setFunctionKeyMask];
      [compiledKey setCharacter:
		     [GSTIMKeyStroke characterCodeFromKeyName: key]];
    }
  else if ([key length] == 1)
    {
      if ([GSTIMKeyStroke shouldNeedShiftKeyMaskForCharacter:
	                    [key characterAtIndex: 0]])
	{
	  [compiledKey setShiftKeyMask];
	}
      else
	{
	  [compiledKey clearShiftKeyMask];
	}

      [compiledKey setCharacter: [key characterAtIndex: 0]];
    }
  else
    {
      NSLog(@"%@: syntax error: %@", key);
    }
  [key release], key = nil;

  return compiledKey;
}


- (void)compileBindings: (NSMutableDictionary *)draft
	     withSource: (NSDictionary *)source
{
  NSEnumerator	    *keyEnum = [source keyEnumerator];
  id		    stroke = nil;
  id		    obj = nil;
  GSTIMKeyStroke    *compiledKey = nil;

  while ((stroke = [keyEnum nextObject]) != nil)
    {
      if ([stroke isKindOfClass: [NSString class]] == NO)
	{
	  continue;
	}
      if ((compiledKey = [self compileForKeyStroke: stroke]) == nil)
	{
	  continue;
	}
      obj = [source objectForKey: stroke];

      if ([obj isKindOfClass: [NSString class]])
	{
	  NSNumber *sel = [[NSNumber alloc] initWithUnsignedLong:
				(unsigned long)NSSelectorFromString(obj)];
	  if (sel)
	    {
	      [draft setObject: sel
			forKey: compiledKey];
	      [sel release], sel = nil;
	    }
	}
      else if ([obj isKindOfClass: [NSDictionary class]])
	{
	  NSMutableDictionary *subDraft = [[NSMutableDictionary alloc] init];
	  [self compileBindings: subDraft
		     withSource: obj];
	  [draft setObject: subDraft
		    forKey: compiledKey];
	  [subDraft release], subDraft = nil;
	}
    }
}


- (GSTIMQueryResult)getSelectorFromCharacter: (GSTIMKeyStroke *)character
				    selector: (SEL *)selector
{
  GSTIMQueryResult  result	= GSTIMNotFound;
  NSEnumerator	    *keyEnum    = nil;
  id		    key		= nil;
  id		    obj		= nil;

  if (branch == nil)
    {
      branch = bindings;
    }

  keyEnum = [branch keyEnumerator];
  for (obj = nil; (key = [keyEnum nextObject]) != nil; obj = nil)
    {
      if ([key isEqual: character])
	{
	  obj = [branch objectForKey: key];
	  break;
	}
    }
  if (obj == nil)
    {
      *selector = (SEL)0;
      branch = nil;
      result = GSTIMNotFound;
    }
  else if ([obj isKindOfClass: [NSDictionary class]])
    {
      *selector = (SEL)0;
      branch = obj;
      result = GSTIMPending;
    }
  else if ([obj isKindOfClass: [NSNumber class]])
    {
      *selector = (SEL)[obj unsignedLongValue];
      branch = nil;
      result = GSTIMFound;
    }

  return result;
}


- (void)dealloc
{
  [bindings release];
  /* Don't release 'branch' because it is a pointer to either 'bindings'
     or a nested dictionary within it. */
  [super dealloc];
}

@end
