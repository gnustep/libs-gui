/*
    GSTIMKeyStroke.m

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

#include <Foundation/NSString.h>
#include "AppKit/NSEvent.h"
#include "AppKit/NSText.h"
#include "GSTIMKeyStroke.h"

#define NumberOf(array)	(sizeof(array)/sizeof(array[0]))

typedef struct _GSTIMRecord {
    NSString	    *key;
    unsigned int    value;
} GSTIMRecord;


static NSString *normalKeys =
  @"1234567890-=qwertyuiop[]asdfghjkl;'\\zxcvbnm,./";
static NSString *shiftedKeys =
  @"!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:\"|ZXCVBNM<>?";


static GSTIMRecord keyMaskTable[] = {
    {	@"AlphaShift",		    NSAlphaShiftKeyMask		    },
    {	@"Shift",		    NSShiftKeyMask		    },
    {	@"Control",		    NSControlKeyMask		    },
    {	@"Alternate",		    NSAlternateKeyMask		    },
    {	@"Command",		    NSCommandKeyMask		    },
    {	@"NumericPad",		    NSNumericPadKeyMask		    },
    {	@"Help",		    NSHelpKeyMask		    },
    {	@"Function",		    NSFunctionKeyMask		    },
};

static GSTIMRecord functionKeyTable[] = {
    {	@"UpArrow",		    NSUpArrowFunctionKey	    },
    {	@"DownArrow",		    NSDownArrowFunctionKey	    },
    {	@"LeftArrow",		    NSLeftArrowFunctionKey	    },
    {	@"RightArrow",		    NSRightArrowFunctionKey	    },
    {	@"F1",			    NSF1FunctionKey		    },
    {	@"F2",			    NSF2FunctionKey		    },
    {	@"F3",			    NSF3FunctionKey		    },
    {	@"F4",			    NSF4FunctionKey		    },
    {	@"F5",			    NSF5FunctionKey		    },
    {	@"F6",			    NSF6FunctionKey		    },
    {	@"F7",			    NSF7FunctionKey		    },
    {	@"F8",			    NSF8FunctionKey		    },
    {	@"F9",			    NSF9FunctionKey		    },
    {	@"F10",			    NSF10FunctionKey		    },
    {	@"F11",			    NSF11FunctionKey		    },
    {	@"F12",			    NSF12FunctionKey		    },
    {	@"F13",			    NSF13FunctionKey		    },
    {	@"F14",			    NSF14FunctionKey		    },
    {	@"F15",			    NSF15FunctionKey		    },
    {	@"F16",			    NSF16FunctionKey		    },
    {	@"F17",			    NSF17FunctionKey		    },
    {	@"F18",			    NSF18FunctionKey		    },
    {	@"F19",			    NSF19FunctionKey		    },
    {	@"F20",			    NSF20FunctionKey		    },
    {	@"F21",			    NSF21FunctionKey		    },
    {	@"F22",			    NSF22FunctionKey		    },
    {	@"F23",			    NSF23FunctionKey		    },
    {	@"F24",			    NSF24FunctionKey		    },
    {	@"F25",			    NSF25FunctionKey		    },
    {	@"F26",			    NSF26FunctionKey		    },
    {	@"F27",			    NSF27FunctionKey		    },
    {	@"F28",			    NSF28FunctionKey		    },
    {	@"F29",			    NSF29FunctionKey		    },
    {	@"F30",			    NSF30FunctionKey		    },
    {	@"F31",			    NSF31FunctionKey		    },
    {	@"F32",			    NSF32FunctionKey		    },
    {	@"F33",			    NSF33FunctionKey		    },
    {	@"F34",			    NSF34FunctionKey		    },
    {	@"F35",			    NSF35FunctionKey		    },
    {	@"Insert",		    NSInsertFunctionKey		    },
    {	@"Delete",		    NSDeleteFunctionKey		    },
    {	@"Home",		    NSHomeFunctionKey		    },
    {	@"Begin",		    NSBeginFunctionKey		    },
    {	@"End",			    NSEndFunctionKey		    },
    {	@"PageUp",		    NSPageUpFunctionKey		    },
    {	@"PageDown",		    NSPageDownFunctionKey	    },
    {	@"PrintScreen",		    NSPrintScreenFunctionKey	    },
    {	@"ScrollLock",		    NSScrollLockFunctionKey	    },
    {	@"Pause",		    NSPauseFunctionKey		    },
    {	@"SysReq",		    NSSysReqFunctionKey		    },
    {	@"Break",		    NSBreakFunctionKey		    },
    {	@"Reset",		    NSResetFunctionKey		    },
    {	@"Stop",		    NSStopFunctionKey		    },
    {	@"Menu",		    NSMenuFunctionKey		    },
    {	@"User",		    NSUserFunctionKey		    },
    {	@"System",		    NSSystemFunctionKey		    },
    {	@"Print",		    NSPrintFunctionKey		    },
    {	@"ClearLine",		    NSClearLineFunctionKey	    },
    {	@"ClearDisplay",	    NSClearDisplayFunctionKey	    },
    {	@"InsertLine",		    NSInsertLineFunctionKey	    },
    {	@"DeleteLine",		    NSDeleteLineFunctionKey	    },
    {	@"InsertChar",		    NSInsertCharFunctionKey	    },
    {	@"DeleteChar",		    NSDeleteCharFunctionKey	    },
    {	@"Prev",		    NSPrevFunctionKey		    },
    {	@"Next",		    NSNextFunctionKey		    },
    {	@"Select",		    NSSelectFunctionKey		    },
    {	@"Execute",		    NSExecuteFunctionKey	    },
    {	@"Undo",		    NSUndoFunctionKey		    },
    {	@"Redo",		    NSRedoFunctionKey		    },
    {	@"Find",		    NSFindFunctionKey		    },
    {	@"Help",		    NSHelpFunctionKey		    },
    {	@"ModeSwitch",		    NSModeSwitchFunctionKey	    },
};

static GSTIMRecord controlCharacterTable[] = {
    {	@"ParagraphSeparator",	    NSParagraphSeparatorCharacter   },
    {	@"LineSeparator",	    NSLineSeparatorCharacter	    },
    {	@"Tab",			    NSTabCharacter		    },
    {	@"FormFeed",		    NSFormFeedCharacter		    },
    {	@"Newline",		    NSNewlineCharacter		    },
    {	@"CarriageReturn",	    NSCarriageReturnCharacter	    },
    {	@"Enter",		    NSEnterCharacter		    },
    {	@"Backspace",		    NSBackspaceCharacter	    },
    {	@"BackTab",		    NSBackTabCharacter		    },
    {	@"Delete",		    NSDeleteCharacter		    },
};


@implementation GSTIMKeyStroke

+ (unichar)characterCodeFromKeyName: (NSString *)name
{
  unsigned int i;

  for (i = 0; i < NumberOf(functionKeyTable); i++)
    {
      if ([name isEqualToString: functionKeyTable[i].key])
	{
	  return functionKeyTable[i].value;
	}
    }
  for (i = 0; i < NumberOf(controlCharacterTable); i++)
    {
      if ([name isEqualToString: controlCharacterTable[i].key])
	{
	  return controlCharacterTable[i].value;
	}
    }
  return [name characterAtIndex: 0];
}


+ (NSString *)keyNameFromCharacterCode: (unichar)code
{
  unsigned int	i;

  for (i = 0; i < NumberOf(functionKeyTable); i++)
    {
      if (code == functionKeyTable[i].value)
	{
	  return functionKeyTable[i].key;
	}
    }
  for (i = 0; i < NumberOf(controlCharacterTable); i++)
    {
      if (code == controlCharacterTable[i].value)
	{
	  return controlCharacterTable[i].key;
	}
    }
  switch (code)
    {
    case 0x0001:    return @"NUL";
    case 0x0002:    return @"SOH";
    case 0x0003:    return @"STX";	/* NSEnterCharacter */
    case 0x0004:    return @"ETX";
    case 0x0005:    return @"ENQ";
    case 0x0006:    return @"ACK";
    case 0x0007:    return @"BEL";
    case 0x0008:    return @"BS";	/* NSBackspaceCharacter */
    case 0x0009:    return @"HT";	/* NSTabCharacter */
    case 0x000a:    return @"LF";	/* NSNewlineCharacter */
    case 0x000b:    return @"VT";
    case 0x000c:    return @"FF";	/* NSFormFeedCharacter */
    case 0x000d:    return @"CR";	/* NSCarriageReturnCharacter */
    case 0x000e:    return @"SO";
    case 0x000f:    return @"SI";
    case 0x0010:    return @"DLE";
    case 0x0011:    return @"DC1";
    case 0x0012:    return @"DC2";
    case 0x0013:    return @"DC3";
    case 0x0014:    return @"DC4";
    case 0x0015:    return @"NAK";
    case 0x0016:    return @"SYN";
    case 0x0017:    return @"ETB";
    case 0x0018:    return @"CAN";
    case 0x0019:    return @"EM";	/* NSBackTabCharacter */
    case 0x001a:    return @"SUB";
    case 0x001b:    return @"ESC";
    case 0x001c:    return @"FS";
    case 0x001d:    return @"GS";
    case 0x001e:    return @"RS";
    case 0x001f:    return @"US";
    case 0x0020:    return @"SPACE";
    case 0x007f:    return @"DEL";	/* NSDeleteCharacter */
    }
  return [NSString stringWithCharacters: &code
				 length: 1];
}


+ (id)characterWithCharacter: (unichar)aChar
		   modifiers: (unsigned int)flags
{
  GSTIMKeyStroke *ch = [[GSTIMKeyStroke alloc] initWithCharacter: aChar
						       modifiers: flags];
  return AUTORELEASE(ch);
}


+ (unsigned int)modifierFromName: (NSString *)name
{
  unsigned int i;

  for (i = 0; i < NumberOf(keyMaskTable); i++)
    {
      if ([name isEqualToString: keyMaskTable[i].key])
	{
	  return keyMaskTable[i].value;
	}
    }
  return 0;
}


+ (NSString *)nameFromModifier: (unsigned int)aFlag
{
  unsigned int i;

  for (i = 0; i < NumberOf(keyMaskTable); i++)
    {
      if (aFlag == keyMaskTable[i].value)
	{
	  return keyMaskTable[i].key;
	}
    }
  return @"";
}


+ (unsigned int)modifiersFromNames: (NSArray *)names
{
  NSEnumerator	*objEnum = [names objectEnumerator];
  id		obj;
  unsigned int	flags;
  unsigned int	i;

  flags = 0;
  while ((obj = [objEnum nextObject]) != nil)
    {
      if ([obj isKindOfClass: [NSString class]] == NO)
	{
	  continue;
	}
      for (i = 0; i < NumberOf(keyMaskTable); i++)
	{
	  if ([obj isEqualToString: keyMaskTable[i].key])
	    {
	      flags |= keyMaskTable[i].value;
	    }
	}
    }
  return flags;
}


+ (NSArray *)namesFromModifiers: (unsigned int)flags;
{
  NSMutableArray    *array = [NSMutableArray array];
  unsigned int	    i;

  for (i = 0; i < NumberOf(keyMaskTable); i++)
    {
      if (flags & keyMaskTable[i].value)
	{
	  [array addObject: keyMaskTable[i].key];
	}
    }
  return array;
}


+ (BOOL)isFunctionKeyCode: (unichar)code
{
  unsigned int i;

  for (i = 0; i < NumberOf(functionKeyTable); i++)
    {
      if (code == functionKeyTable[i].value)
	{
	  return YES;
	}
    }
  return NO;
}


+ (BOOL)isFunctionKeyName: (NSString *)name
{
  unsigned int i;

  for (i = 0; i < NumberOf(functionKeyTable); i++)
    {
      if ([name isEqualToString: functionKeyTable[i].key])
	{
	  return YES;
	}
    }
  return NO;
}


+ (BOOL)shouldNeedShiftKeyMaskForCharacter: (unichar)aChar
{
  unsigned int i;
  unsigned int shiftedKeysLen = [shiftedKeys length];
  unsigned int normalKeysLen = [normalKeys length];

  for (i = 0; i < shiftedKeysLen; i++)
    {
      if (aChar == [shiftedKeys characterAtIndex: i])
	{
	  return YES;
	}
    }
  for (i = 0; i < normalKeysLen; i++)
    {
      if (aChar == [normalKeys characterAtIndex: i])
	{
	  return NO;
	}
    }
  /* Perhaps */
  return NO;
}



- (id)init
{
  return [self initWithCharacter: 0 modifiers: 0];
}


- (id)initWithCharacter: (unichar)aChar
	      modifiers: (unsigned int)flags
{
  if ((self = [super init]) != nil)
    {
      [self setCharacter: aChar];
      [self setModifiers: flags];
    }
  return self;
}


- (void)setCharacter: (unichar)aChar
{
  character = aChar;
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


- (BOOL)isAlphaShiftKeyMaskOn
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


- (BOOL)isShiftKeyMaskOn
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


- (BOOL)isControlKeyMaskOn
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


- (BOOL)isAlternateKeyMaskOn
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


- (BOOL)isCommandKeyMaskOn
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


- (BOOL)isNumericPadKeyMaskOn
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


- (BOOL)isHelpKeyMaskOn
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


- (BOOL)isFunctionKeyMask
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


- (BOOL)isModified
{
  return ![self isNotModified];
}


- (BOOL)isNotModified
{
  return modifiers == 0;
}


- (BOOL)isShifted
{
  return [self isShiftKeyMaskOn] || [self isAlphaShiftKeyMaskOn];
}


- (BOOL)isNotShifted
{
  return ![self isShifted];
}


- (id)copyWithZone: (NSZone *)zone
{
  return [[[self class] allocWithZone: zone]
			  initWithCharacter: [self character]
				  modifiers: [self modifiers]];
}


- (BOOL)isEqual: (id)anObject
{
  if ([anObject isKindOfClass: [GSTIMKeyStroke class]])
    {
      return ([anObject character] == [self character]) &&
	     ([anObject modifiers] == [self modifiers]);
    }
  return NO;
}


- (NSComparisonResult)compare: (id)anObject
{
  unsigned long v1;
  unsigned long v2;

  v1 = ([self modifiers] << (sizeof(unichar) * 8)) & [self character];
  v2 = ([anObject modifiers] << (sizeof(unichar) * 8)) & [anObject character];

  if (v2 > v1)
    {
      return NSOrderedDescending;
    }
  if (v2 < v1)
    {
      return NSOrderedAscending;
    }
  else
    {
      return NSOrderedSame;
    }
}


- (NSString *)stringValue
{
  return [NSString stringWithCharacters: &character
				 length: 1];
}

- (NSString *)description
{
  return [NSString stringWithFormat:
			@"%@ %@",
			[GSTIMKeyStroke namesFromModifiers: modifiers],
			[GSTIMKeyStroke keyNameFromCharacterCode: character]];
}

@end
