/*
    GSTIMKeyStroke.h

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

#if !defined _GNUstep_GSTIMKeyStroke_h
#define _GNUstep_GSTIMKeyStroke_h

#include <Foundation/NSObject.h>

@interface GSTIMKeyStroke : NSObject <NSCopying>
{
  unichar	character;
  unsigned int	modifiers;
}

+ (unichar)characterCodeFromKeyName: (NSString *)name;
+ (NSString *)keyNameFromCharacterCode: (unichar)code;

+ (unsigned int)modifierFromName: (NSString *)name;
+ (NSString *)nameFromModifier: (unsigned int)aFlag;

+ (unsigned int)modifiersFromNames: (NSArray *)names;
+ (NSArray *)namesFromModifiers: (unsigned int)flags;

+ (BOOL)isFunctionKeyCode: (unichar)code;
+ (BOOL)isFunctionKeyName: (NSString *)name;

+ (BOOL)shouldNeedShiftKeyMaskForCharacter: (unichar)aChar;

+ (id)characterWithCharacter: (unichar)aChar
		   modifiers: (unsigned int)flags;

- (id)initWithCharacter: (unichar)aChar
	      modifiers: (unsigned int)flags;	/* Designated */

- (void)setCharacter: (unichar)aChar;
- (unichar)character;

- (void)setModifiers: (unsigned int)flags;
- (unsigned int)modifiers;

- (BOOL)isAlphaShiftKeyMaskOn;
- (void)setAlphaShiftKeyMask;
- (void)clearAlphaShiftKeyMask;

- (BOOL)isShiftKeyMaskOn;
- (void)setShiftKeyMask;
- (void)clearShiftKeyMask;

- (BOOL)isControlKeyMaskOn;
- (void)setControlKeyMask;
- (void)clearControlKeyMask;

- (BOOL)isAlternateKeyMaskOn;
- (void)setAlternateKeyMask;
- (void)clearAlternateKeyMask;

- (BOOL)isCommandKeyMaskOn;
- (void)setCommandKeyMask;
- (void)clearCommandKeyMask;

- (BOOL)isNumericPadKeyMaskOn;
- (void)setNumericPadKeyMask;
- (void)clearNumericPadKeyMask;

- (BOOL)isHelpKeyMaskOn;
- (void)setHelpKeyMask;
- (void)clearHelpKeyMask;

- (BOOL)isFunctionKeyMask;
- (void)setFunctionKeyMask;
- (void)clearFunctionKeyMask;

- (BOOL)isModified;
- (BOOL)isNotModified;

- (BOOL)isShifted;
- (BOOL)isNotShifted;
@end

#endif /* _GNUstep_GSTIMKeyStroke_h */
