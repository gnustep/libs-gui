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
#include <Foundation/NSDebug.h>
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


/* Private method. */
- (NSString *)convertToMachineReadableForm: (NSString *)aStroke
{
  NSString *stroke = [NSString stringWithString: @""];

  while (1)
    {
      if ([aStroke hasPrefix: @"Shift-"])
	{
	  stroke = [stroke stringByAppendingString: @"$"];
	  aStroke = [aStroke substringFromIndex: [@"Shift-" length]];
	}
      else if ([aStroke hasPrefix: @"Alternate-"])
	{
	  stroke = [stroke stringByAppendingString: @"~"];
	  aStroke = [aStroke substringFromIndex: [@"Alternate-" length]];
	}
      else if ([aStroke hasPrefix: @"Control-"])
	{
	  stroke = [stroke stringByAppendingString: @"^"];
	  aStroke = [aStroke substringFromIndex: [@"Control-" length]];
	}
      else if ([aStroke hasPrefix: @"NumericPad-"])
	{
	  stroke = [stroke stringByAppendingString: @"#"];
	  aStroke = [aStroke substringFromIndex: [@"NumericPad-" length]];
	}
      else if ([aStroke hasPrefix: @"Tab"])
	{
	  stroke = [stroke stringByAppendingString: @"\011"];
	  aStroke = [aStroke substringFromIndex: [@"Tab" length]];
	}
      else if ([aStroke hasPrefix: @"FormFeed"])
	{
	  stroke = [stroke stringByAppendingString: @"\014"];
	  aStroke = [aStroke substringFromIndex: [@"FormFeed" length]];
	}
      else if ([aStroke hasPrefix: @"Newline"])
	{
	  stroke = [stroke stringByAppendingString: @"\012"];
	  aStroke = [aStroke substringFromIndex: [@"Newline" length]];
	}
      else if ([aStroke hasPrefix: @"CarriageReturn"])
	{
	  stroke = [stroke stringByAppendingString: @"\015"];
	  aStroke = [aStroke substringFromIndex: [@"CarriageReturn" length]];
	}
      else if ([aStroke hasPrefix: @"Enter"])
	{
	  /* Convert it into a carriage return */
	  stroke = [stroke stringByAppendingString: @"\015"];
	  aStroke = [aStroke substringFromIndex: [@"Enter" length]];
	}
      else if ([aStroke hasPrefix: @"Backspace"])
	{
	  stroke = [stroke stringByAppendingString: @"\010"];
	  aStroke = [aStroke substringFromIndex: [@"Backspace" length]];
	}
      else if ([aStroke hasPrefix: @"BackTab"])
	{
	  stroke = [stroke stringByAppendingString: @"\031"];
	  aStroke = [aStroke substringFromIndex: [@"BackTab" length]];
	}
      else if ([aStroke hasPrefix: @"Delete"])
	{
	  stroke = [stroke stringByAppendingString: @"\177"];
	  aStroke = [aStroke substringFromIndex: [@"Delete" length]];
	}
      else if ([aStroke hasPrefix: @"Escape"])
	{
	  stroke = [stroke stringByAppendingString: @"\033"];
	  aStroke = [aStroke substringFromIndex: [@"Escape" length]];
	}
      else
	{
	  break;
	}
    }
  stroke = [stroke stringByAppendingString: aStroke];

  return stroke;
}


- (GSTIMKeyStroke *)compileForKeyStroke: (NSString *)aStroke
{
  GSTIMKeyStroke    *compiledKey = [GSTIMKeyStroke characterWithCharacter: 0
								modifiers: 0];
  NSMutableString   *stroke = nil;
  NSRange	    range;

  stroke = [[self convertToMachineReadableForm: aStroke] mutableCopy];
  while (1)
    {
      NSString *original = [stroke copy];

      range = [stroke rangeOfString: @"~"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setAlternateKeyMask];
	  [stroke deleteCharactersInRange: range];
	}

      range = [stroke rangeOfString: @"^"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setControlKeyMask];
	  [stroke deleteCharactersInRange: range];
	}

      range = [stroke rangeOfString: @"$"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setShiftKeyMask];
	  [stroke deleteCharactersInRange: range];
	}

      range = [stroke rangeOfString: @"#"];
      if (range.location != NSNotFound)
	{
	  [compiledKey setNumericPadKeyMask];
	  [stroke deleteCharactersInRange: range];
	}

      if ([stroke isEqualToString: original])
	{
	  [original release], original = nil;
	  break;
	}
      [original release], original = nil;
    }
  if ([GSTIMKeyStroke isFunctionKeyName: stroke])
    {
      [compiledKey setFunctionKeyMask];
      [compiledKey setCharacter:
		     [GSTIMKeyStroke characterCodeFromKeyName: stroke]];
    }
  else if ([stroke length] == 1)
    {
      unichar c = [stroke characterAtIndex: 0];

      [compiledKey setCharacter: c];

      if ([GSTIMKeyStroke shouldNeedShiftKeyMaskForCharacter: c])
	{
	  [compiledKey setShiftKeyMask];
	}

      /* The character constant \177 (Delete) needs an exceptional treatment. */
      if ([stroke isEqualToString: @"\177"])
	{
	  [compiledKey setFunctionKeyMask];
	  [compiledKey setCharacter: NSDeleteFunctionKey];
	}
    }
  else
    {
      NSLog(@"%@: syntax error: %@", aStroke);
    }
  [stroke release], stroke = nil;

  return compiledKey;
}


- (void)compileBindings: (NSMutableDictionary *)draft
	     withSource: (NSDictionary *)source
{
  NSEnumerator	    *keyEnum = [source keyEnumerator];
  id		    stroke = nil;
  id		    obj = nil;
  GSTIMKeyStroke    *compiledKey = nil;
  unsigned long	    selVal;
  NSNumber	    *selHolder;

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
	  selVal = (unsigned long)NSSelectorFromString(obj);
	  selHolder = [NSNumber numberWithUnsignedLong: selVal];
	  if (selHolder)
	    {
	      [draft setObject: [NSArray arrayWithObject: selHolder]
			forKey: compiledKey];
	    }
	}
      else if ([obj isKindOfClass: [NSArray class]])
	{
	  NSEnumerator	    *selStrEnum = [obj objectEnumerator];
	  NSMutableArray    *selArray = [NSMutableArray array];
	  id		    selStr;

	  while ((selStr = [selStrEnum nextObject]) != nil)
	    {
	      if ([selStr isKindOfClass: [NSString class]] == NO)
		{
		  continue;
		}

	      selVal = (unsigned long)NSSelectorFromString(selStr);
	      selHolder = [NSNumber numberWithUnsignedLong: selVal];
	      if (selHolder)
		{
		  [selArray addObject: selHolder];
		}
	    }
	  if ([selArray count] > 0)
	    {
	      [draft setObject: selArray
			forKey: compiledKey];
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

/* 'selectors' returns an NSArray whose elements are NSNumbers each of
    which contains a SEL., or it returns nil. */
- (GSTIMQueryResult)getSelectorFromCharacter: (GSTIMKeyStroke *)character
				   selectors: (NSArray **)selectors
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
      *selectors = nil;
      branch = nil;
      result = GSTIMNotFound;
    }
  else if ([obj isKindOfClass: [NSDictionary class]])
    {
      *selectors = nil;
      branch = obj;
      result = GSTIMPending;
    }
  else if ([obj isKindOfClass: [NSArray class]])
    {
      *selectors = [[obj mutableCopy] autorelease];
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
