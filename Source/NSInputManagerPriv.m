/*
    NSInputManagerPriv.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date:   March 2004

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

#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>
#include "AppKit/NSEvent.h"
#include "GSTIMKeyBindingTable.h"
#include "GSTIMKeyStroke.h"
#include "NSInputManagerPriv.h"


@implementation NSInputManager (KeyEventHandling)

- (void)interpretSingleKeyEvent: (NSEvent *)event
{
  NSString	    *chars	    = [event characters];
  unsigned int	    charsLen	    = 0;
  NSString	    *noModChars	    = nil;
  unsigned int	    noModCharsLen   = 0;
  unsigned int	    modifierFlags   = 0;
  GSTIMKeyStroke    *aChar	    = nil;
  SEL		    sel		    = (SEL)0;
  GSTIMQueryResult  result;

  if ([self wantsToInterpretAllKeystrokes])
    {
      [self insertText: chars];
      return;
    }

  charsLen	= [chars length];
  noModChars	= [event charactersIgnoringModifiers];
  noModCharsLen	= [noModChars length];
  modifierFlags = [event modifierFlags];
  aChar		= [[[GSTIMKeyStroke alloc] init] autorelease];

  /* TODO: Special treatment for localized characters: They are actually
     modified in -back, nonetheless, -charactersIgnoringModifiers returns 0.
     So they look as if they were a control key sequence.

     This will be deprecated when a customized input server is put in
     place. */
  if (charsLen > 0 && noModCharsLen == 0)
    {
      [self insertText: chars];
      return;
    }

  /* NB: The following code heavily depends on the implementation
     detail of NSEvent of the type KeyDown.  The current implementation
     (gui/back-0.9.1) seemingly contains only a single character per
     event.  (If there were more than a signle characer, we couldn't
     rely on -modifierFlags because it wouldn't tell which character
     was actually modified.) */ 
  [aChar setCharacter: [noModChars characterAtIndex: 0]];
  [aChar setModifiers: modifierFlags];

  result = [keyBindingTable getSelectorFromCharacter: aChar 
					    selector: &sel];

  NSDebugMLLog(@"NSInputManager", @"<-- %@", aChar);
  if (sel)
    {
      NSDebugMLLog(@"NSInputManager", @"--> %@", NSStringFromSelector(sel));
    }
  else
    {
      NSDebugMLLog(@"NSInputManager", @"--> %@", aChar);
    }

  switch (result)
    {
    case GSTIMNotFound:
      [self insertText: chars];
      break;

    case GSTIMFound:
      if (sel)
	{
	  [self doCommandBySelector: sel];
	}
      else
	{
	  /* This implies that the key binding is the one specified by the
	     current server.  Pass the raw character to it and let it
	     handle the character. */
	  [self insertText: chars];
	}
      break;

    case GSTIMPending:
      /* Do nothing, waiting for a next event. */
      break;
    }
}


#define SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP


- (void)interpretKeyEvents: (NSArray *)eventArray
{
#if defined SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP
  static NSTimeInterval	prev	    = 0.0;
  static NSString	*prevChars  = nil;
  NSTimeInterval	now	    = 0.0;
  NSString		*curChars   = nil;
  static unsigned int	count	    = 0;
  /* Adjust the following two constants so that most of the users feel
     the resulting cursor movements look natural.  (Or fix the crawling
     re-drawing of NSTextView's cursor movement, which is primarily
     responsible for this hack. ) */
  const NSTimeInterval	interval    = 50.0;
  static const int	skips	    = 80;
#endif /* SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP */
  NSEnumerator		*objEnum    = nil;
  id			obj	    = nil;

  objEnum = [eventArray objectEnumerator];
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isKindOfClass: [NSEvent class]] == NO ||
	  [obj type] != NSKeyDown)
	{
	  continue;
	}
#if defined SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP
      now = [obj timestamp];
      curChars = [obj characters];
      if (now - prev <= interval && [curChars isEqualToString: prevChars])
	{
	  if (count++ % skips)
	    {
	      continue;
	    }
	}
      prev = [obj timestamp];
      [prevChars release];
      prevChars = [curChars copy];
#endif /* SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP */
      [self interpretSingleKeyEvent: obj];
    }
}


#undef SKIP_MOST_OF_REPEATED_EVENTS_TO_EASE_SUDDEN_CURSOR_JUMP

@end /* @implementation NSInputManager (KeyEventHandling) */


#if 0
@implementation IMKeyBindingTable

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


- (GSTIMKeyStroke *)compileForKey: (NSString *)aKey
{
  GSTIMKeyStroke    *compiledKey = [GSTIMKeyStroke characterWithCharacter: 0
								modifiers: 0];
  NSMutableString   *key = nil;
  NSRange	    range;

  if ([aKey length] == 1)
    {
      range = [_plain rangeOfString: aKey];
      if (range.location != NSNotFound)
	{
	  [compiledKey clearShiftKeyMask];
	}

      range = [_shifted rangeOfString: aKey];
      if (range.location != NSNotFound)
	{
	  [compiledKey setShiftKeyMask];
	}

      if ([aKey isEqualToString: @"\177"])
	{
	  /* N.B.: NSTextView regards Delete as a function key. */
	  [compiledKey setFunctionKeyMask];
	  [compiledKey setCharacter: NSDeleteFunctionKey];
	}
      else
	{
	  [compiledKey setCharacter: [aKey characterAtIndex: 0]];
	}

      return compiledKey;
    }

  key = [aKey mutableCopy];
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
  id		    key = nil;
  id		    obj = nil;
  GSTIMKeyStroke    *compiledKey = nil;

  while ((key = [keyEnum nextObject]) != nil)
    {
      if ([key isKindOfClass: [NSString class]] == NO)
	{
	  continue;
	}
      if ((compiledKey = [self compileForKey: key]) == nil)
	{
	  continue;
	}
      obj = [source objectForKey: key];

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


- (IMQueryResult)getSelectorFromCharacter: (GSTIMKeyStroke *)character
				 selector: (SEL *)selector
{
  IMQueryResult	result	    = IMNotFound;
  NSEnumerator	*keyEnum    = nil;
  id		key	    = nil;
  id		obj	    = nil;

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
      result = IMNotFound;
    }
  else if ([obj isKindOfClass: [NSDictionary class]])
    {
      *selector = (SEL)0;
      branch = obj;
      result = IMPending;
    }
  else if ([obj isKindOfClass: [NSNumber class]])
    {
      *selector = (SEL)[obj unsignedLongValue];
      branch = nil;
      result = IMFound;
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

@end /* @implementation IMKeyBindingTable */
#endif
