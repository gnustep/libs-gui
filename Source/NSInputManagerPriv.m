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
#include <Foundation/NSValue.h>
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
  NSArray	    *selArray	    = nil;
  GSTIMQueryResult  result;
  int		    i;

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
					   selectors: &selArray];

  NSDebugMLLog(@"NSInputManager", @"<-- %@", aChar);
  if (selArray && [selArray count] > 0)
    {
      NSMutableArray *selStrArray = [NSMutableArray array];
      for (i = 0; i < [selArray count]; i++)
	{
	  sel = (SEL)[[selArray objectAtIndex: i] unsignedLongValue];
	  if (sel)
	    {
	      [selStrArray addObject: NSStringFromSelector(sel)];
	    }
	}
      if ([selStrArray count] > 0)
	{
	  NSDebugMLLog(@"NSInputManager", @"--> %@", selStrArray);
	}
      else
	{
	  NSDebugMLLog(@"NSInputManager", @"--> non-NSResponder selector");
	}
    }
  else
    {
      NSDebugMLLog(@"NSInputManager", @"--> %@", aChar);
    }

  switch (result)
    {
    case GSTIMNotFound:
      [self insertText: chars];
      [pendingCharacters removeAllObjects];
      break;

    case GSTIMFound:
      [pendingCharacters addObject: chars];
      if (selArray && [selArray count] > 0)
	{
	  int numSelectors;

	  /* Check if the key binding tables returned an array of non-nil
	     selectors. */
	  numSelectors = 0;
	  for (i = 0; i < [selArray count]; i++)
	    {
	      sel = (SEL)[[selArray objectAtIndex: i] unsignedLongValue];
	      if (sel)
		{
		  ++numSelectors;
		}
	    }
	  /* If all the elements of the array are non-nil, invoke the
	     selectors; otherwise, send the corresponding key strokes
	     to the server in the form of raw characters. */
	  if (numSelectors == [selArray count])
	    {
	      for (i = 0; i < [selArray count]; i++)
		{
		  sel = (SEL)[[selArray objectAtIndex: i] unsignedLongValue];
		  [self doCommandBySelector: sel];
		}
	    }
	  else
	    {
	      for (i = 0; i < [pendingCharacters count]; i++)
		{
		  [self insertText: [pendingCharacters objectAtIndex: i]];
		}
	    }
	}
      [pendingCharacters removeAllObjects];
      break;

    case GSTIMPending:
      [pendingCharacters addObject: chars];
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
