/*
    NSInputManagerPriv.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date:   March, 2004

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
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#if !defined USE_INPUT_MANAGER_UTILITIES
#define USE_INPUT_MANAGER_UTILITIES
#endif
#include "NSInputManagerPriv.h"


#define NumberOf(array) (sizeof(array)/sizeof(array[0]))


typedef struct _IMRecord {
    NSString	    *key;
    unsigned int    value;
} IMRecord;


static NSString *_plain	  = @"1234567890-=qwertyuiop[]asdfghjkl;'\\zxcvbnm,./";
static NSString *_shifted = @"!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:\"|ZXCVBNM<>?";

static IMRecord _functionKeyTable[] = {
    { @"UpArrow",	    NSUpArrowFunctionKey },
    { @"DownArrow",	    NSDownArrowFunctionKey },
    { @"LeftArrow",	    NSLeftArrowFunctionKey },
    { @"RightArrow",	    NSRightArrowFunctionKey },
    { @"F1",		    NSF1FunctionKey },
    { @"F2",		    NSF2FunctionKey },
    { @"F3",		    NSF3FunctionKey },
    { @"F4",		    NSF4FunctionKey },
    { @"F5",		    NSF5FunctionKey },
    { @"F6",		    NSF6FunctionKey },
    { @"F7",		    NSF7FunctionKey },
    { @"F8",		    NSF8FunctionKey },
    { @"F9",		    NSF9FunctionKey },
    { @"F10",		    NSF10FunctionKey },
    { @"F11",		    NSF11FunctionKey },
    { @"F12",		    NSF12FunctionKey },
    { @"F13",		    NSF13FunctionKey },
    { @"F14",		    NSF14FunctionKey },
    { @"F15",		    NSF15FunctionKey },
    { @"F16",		    NSF16FunctionKey },
    { @"F17",		    NSF17FunctionKey },
    { @"F18",		    NSF18FunctionKey },
    { @"F19",		    NSF19FunctionKey },
    { @"F20",		    NSF20FunctionKey },
    { @"F21",		    NSF21FunctionKey },
    { @"F22",		    NSF22FunctionKey },
    { @"F23",		    NSF23FunctionKey },
    { @"F24",		    NSF24FunctionKey },
    { @"F25",		    NSF25FunctionKey },
    { @"F26",		    NSF26FunctionKey },
    { @"F27",		    NSF27FunctionKey },
    { @"F28",		    NSF28FunctionKey },
    { @"F29",		    NSF29FunctionKey },
    { @"F30",		    NSF30FunctionKey },
    { @"F31",		    NSF31FunctionKey },
    { @"F32",		    NSF32FunctionKey },
    { @"F33",		    NSF33FunctionKey },
    { @"F34",		    NSF34FunctionKey },
    { @"F35",		    NSF35FunctionKey },
    { @"Insert",	    NSInsertFunctionKey },
    { @"Delete",	    NSDeleteFunctionKey },
    { @"Home",		    NSHomeFunctionKey },
    { @"Begin",		    NSBeginFunctionKey },
    { @"End",		    NSEndFunctionKey },
    { @"PageUp",	    NSPageUpFunctionKey },
    { @"PageDown",	    NSPageDownFunctionKey },
    { @"PrintScreen",	    NSPrintScreenFunctionKey },
    { @"ScrollLock",	    NSScrollLockFunctionKey },
    { @"Pause",		    NSPauseFunctionKey },
    { @"SysReq",	    NSSysReqFunctionKey },
    { @"Break",		    NSBreakFunctionKey },
    { @"Reset",		    NSResetFunctionKey },
    { @"Stop",		    NSStopFunctionKey },
    { @"Menu",		    NSMenuFunctionKey },
    { @"User",		    NSUserFunctionKey },
    { @"System",	    NSSystemFunctionKey },
    { @"Print",		    NSPrintFunctionKey },
    { @"ClearLine",	    NSClearLineFunctionKey },
    { @"ClearDisplay",	    NSClearDisplayFunctionKey },
    { @"InsertLine",	    NSInsertLineFunctionKey },
    { @"DeleteLine",	    NSDeleteLineFunctionKey },
    { @"InsertChar",	    NSInsertCharFunctionKey },
    { @"DeleteChar",	    NSDeleteCharFunctionKey },
    { @"Prev",		    NSPrevFunctionKey },
    { @"Next",		    NSNextFunctionKey },
    { @"Select",	    NSSelectFunctionKey },
    { @"Execute",	    NSExecuteFunctionKey },
    { @"Undo",		    NSUndoFunctionKey },
    { @"Redo",		    NSRedoFunctionKey },
    { @"Find",		    NSFindFunctionKey },
    { @"Help",		    NSHelpFunctionKey },
    { @"Mode",		    NSModeSwitchFunctionKey },
};

static IMRecord _maskTable[] = {
    { @"AlphaShiftKey",	    NSAlphaShiftKeyMask },
    { @"ShiftKey",	    NSShiftKeyMask },
    { @"ControlKey",	    NSControlKeyMask },
    { @"AlternateKey",	    NSAlternateKeyMask },
    { @"CommandKey",	    NSCommandKeyMask },
    { @"NumericPadKey",	    NSNumericPadKeyMask },
    { @"HelpKey",	    NSHelpKeyMask },
    { @"FunctionKey",	    NSFunctionKeyMask },
};


@implementation NSInputManager (KeyEventHandling)

- (void)interpretSingleKeyEvent: (NSEvent *)event
{
  NSString	*chars		= [event characters];
  unsigned int  charsLen	= 0;
  NSString	*noModChars	= nil;
  unsigned int	noModCharsLen	= 0;
  unsigned int	modifierFlags	= 0;
  IMCharacter	*c		= [[IMCharacter alloc] init];
  SEL		sel		= (SEL)0;
  unsigned int	i;
  IMQueryResult	result;

  if ([self wantsToInterpretAllKeystrokes])
    {
      [self insertText: chars];
      return;
    }

  charsLen	= [chars length];
  noModChars	= [event charactersIgnoringModifiers];
  noModCharsLen	= [noModChars length];
  modifierFlags = [event modifierFlags];

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

  for (i = 0; i < noModCharsLen; i++)
    {
      [c setCharacter: [noModChars characterAtIndex: i]];
      [c setModifiers: modifierFlags];

      result = [keyBindingTable getSelectorFromCharacter: c
						selector: &sel];
      switch (result)
	{
	case IMNotFound:
	  if ([c isNotModified] || [c isShiftedOnly])
	    {
	      [self insertText: [c stringValue]];
	    }
	  break;

	case IMFound:
	  if (sel)
	    {
	      [self doCommandBySelector: sel];
	    }
	  break;

	case IMPending:
	  /* Do nothing */
	  break;
	}
    }
}


- (void)interpretKeyEvents: (NSArray *)eventArray
{
  id		obj;
  NSEnumerator	*objEnum    = [eventArray objectEnumerator];

  while ((obj = [objEnum nextObject]) != nil)
    {
      [self interpretSingleKeyEvent: obj];
    }
}

@end /* @implementation NSInputManager (KeyEventHandling) */


@implementation IMCharacter

+ (id)characterWithCharacter: (unichar)c
		   modifiers: (unsigned int)flags
{
  return [[[[self class] alloc] initWithCharacter: c
					modifiers: flags] autorelease];
}


- (id)init
{
  return [self initWithCharacter: 0
		       modifiers: 0];
}


- (id)initWithCharacter: (unichar)c
	      modifiers: (unsigned int)flags
{
  if ((self = [super init]) != nil)
    {
      [self setCharacter: c];
      [self setModifiers: flags];
    }
  return self;
}


- (void)setCharacter: (unichar)c
{
  character = c;
}


- (unichar)character
{
  return character;
}


- (void)setModifiers: (unsigned int)flags
{
  modifiers = flags;
}


- (unsigned int)modifiers
{
  return modifiers;
}


- (id)copyWithZone: (NSZone *)zone
{
  return [[[self class] allocWithZone: zone]
	    initWithCharacter: [self character]
		    modifiers: [self modifiers]];
}


- (BOOL)isEqual: (id)anObject
{
  if ([anObject isKindOfClass: [IMCharacter class]])
    {
      return ([anObject character] == [self character]) &&
	     ([anObject modifiers] == [self modifiers]);
    }
  return NO;
}


- (NSComparisonResult)compare: (id)another
{
  unsigned long val1 = ([self modifiers] << (sizeof(unichar) * 8))
			& [self character];
  unsigned long val2 = ([another modifiers] << (sizeof(unichar) * 8))
			& [another character];
  if (val2 > val1)
    {
      return NSOrderedDescending;
    }
  else if (val2 < val1)
    {
      return NSOrderedAscending;
    }
  else
    {
      return NSOrderedSame;
    }
}


- (NSString *)description
{
  return [NSString stringWithFormat: @"%@ %@",
	                             [self convertCharacterToString],
				     [self convertModifiersToString]];
}


- (BOOL)isAlphaShiftKeyOn
{
  return modifiers & NSAlphaShiftKeyMask;
}


- (void)setAlphaShiftKeyMask
{
  modifiers |= NSAlphaShiftKeyMask;
}


- (void)clearAlphaShiftKeyMask
{
  modifiers &= ~NSAlphaShiftKeyMask;
}


- (BOOL)isShiftKeyOn
{
  return modifiers & NSShiftKeyMask;
}


- (void)setShiftKeyMask
{
  modifiers |= NSShiftKeyMask;
}


- (void)clearShiftKeyMask
{
  modifiers &= ~NSShiftKeyMask;
}


- (BOOL)isControlKeyOn
{
  return modifiers & NSControlKeyMask;
}


- (void)setControlKeyMask
{
  modifiers |= NSControlKeyMask;
}


- (void)clearControlKeyMask
{
  modifiers &= ~NSControlKeyMask;
}


- (BOOL)isAlternateKeyOn
{
  return modifiers & NSAlternateKeyMask;
}


- (void)setAlternateKeyMask
{
  modifiers |= NSAlternateKeyMask;
}


- (void)clearAlternateKeyMask
{
  modifiers &= ~NSAlternateKeyMask;
}


- (BOOL)isCommandKeyOn
{
  return modifiers & NSCommandKeyMask;
}


- (void)setCommandKeyMask
{
  modifiers |= NSCommandKeyMask;
}


- (void)clearCommandKeyMask
{
  modifiers &= ~NSCommandKeyMask;
}


- (BOOL)isNumericPadKeyOn
{
  return modifiers & NSNumericPadKeyMask;
}


- (void)setNumericPadKeyMask
{
  modifiers |= NSNumericPadKeyMask;
}


- (void)clearNumericPadKeyMask
{
  modifiers &= ~NSNumericPadKeyMask;
}


- (BOOL)isHelpKeyOn
{
  return modifiers & NSHelpKeyMask;
}


- (void)setHelpKeyMask
{
  modifiers |= NSHelpKeyMask;
}


- (void)clearHelpKeyMask
{
  modifiers &= ~NSHelpKeyMask;
}


- (BOOL)isFunctionKeyOn
{
  return modifiers & NSFunctionKeyMask;
}


- (void)setFunctionKeyMask
{
  modifiers |= NSFunctionKeyMask;
}


- (void)clearFunctionKeyMask
{
  modifiers &= ~NSFunctionKeyMask;
}


- (BOOL)isNotModified
{
  return modifiers == 0;
}


- (BOOL)isShiftedOnly
{
  return [self isShiftKeyOn] || [self isAlphaShiftKeyOn];
}


/* Unprintable characters are converted into its names. */
- (NSString *)convertCharacterToString
{
  unsigned int	i;

  for (i = 0; i < NumberOf(_functionKeyTable); i++)
    {
      if (character == _functionKeyTable[i].value)
	{
	  return _functionKeyTable[i].key;
	}
    }
  switch (character)
    {
    case 001:	return @"NUL";
    case 002:	return @"SOH";
    case 003:	return @"STX";
    case 004:	return @"ETX";
    case 005:	return @"ENQ";
    case 006:	return @"ACK";
    case 007:	return @"BEL";
    case 010:	return @"BS";
    case 011:	return @"HT";
    case 012:	return @"LF";
    case 013:	return @"VT";
    case 014:	return @"FF";
    case 015:	return @"CR";
    case 016:	return @"SO";
    case 017:	return @"SI";
    case 020:	return @"DLE";
    case 021:	return @"DC1";
    case 022:	return @"DC2";
    case 023:	return @"DC3";
    case 024:	return @"DC4";
    case 025:	return @"NAK";
    case 026:	return @"SYN";
    case 027:	return @"ETB";
    case 030:	return @"CAN";
    case 031:	return @"EM";
    case 032:	return @"SUB";
    case 033:	return @"ESC";
    case 034:	return @"FS";
    case 035:	return @"GS";
    case 036:	return @"RS";
    case 037:	return @"US";
    case 040:	return @"SPACE";
    case 0177:	return @"DEL";
    }
  return [NSString stringWithCharacters: &character
				 length: 1];
}


- (NSString *)convertModifiersToString
{
  NSMutableArray    *array = [NSMutableArray array];
  unsigned int	    i;

  for (i = 0; i < NumberOf(_maskTable); i++)
    {
      if (modifiers & _maskTable[i].value)
	{
	  [array addObject: _maskTable[i].key];
	}
    }
  return [array description];
}


- (NSString *)stringValue
{
  return [NSString stringWithCharacters: &character
				 length: 1];
}

@end /* @implementation IMCharacter */


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


- (IMCharacter *)compileForKey: (NSString *)aKey
{
  IMCharacter	    *compiledKey = [IMCharacter characterWithCharacter: 0
							     modifiers: 0];
  NSMutableString   *key = nil;
  NSRange	    range;
  unsigned int	    i;

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

      /* Why does NSTextView handle Delete so specially? */
      if ([aKey isEqualToString: @"\177"])
	{
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
  for (i = 0; i < NumberOf(_functionKeyTable); i++)
    {
      if (key && [key isEqualToString: _functionKeyTable[i].key])
	{
	  [compiledKey setFunctionKeyMask];
	  [compiledKey setCharacter: _functionKeyTable[i].value];
	  break;
	}
    }
  if (i == NumberOf(_functionKeyTable) && [key length] == 1)
    {
      range = [_plain rangeOfString: key];
      if (range.location != NSNotFound)
	{
	  [compiledKey clearShiftKeyMask];
	}

      range = [_shifted rangeOfString: key];
      if (range.location != NSNotFound)
	{
	  [compiledKey setShiftKeyMask];
	}

      [compiledKey setCharacter: [key characterAtIndex: 0]];
    }
  [key release], key = nil;

  return compiledKey;
}


- (void)compileBindings: (NSMutableDictionary *)draft
	     withSource: (NSDictionary *)source
{
  NSEnumerator	*keyEnum = [source keyEnumerator];
  id		key = nil;
  id		obj = nil;
  IMCharacter	*compiledKey = nil;

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


- (IMQueryResult)getSelectorFromCharacter: (IMCharacter *)character
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
     or a dictionary inside 'branch'. */
  [super dealloc];
}

@end /* @implementation IMKeyBindingTable */
