/*
    NSInputManagerPriv.h

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

#ifndef _GNUstep_NSInputManagerPriv_h
#define _GNUstep_NSInputManagerPriv_h

#include <AppKit/NSEvent.h>
#include <AppKit/NSInputManager.h>

@class NSArray;
@class NSString;
@class NSDictionary;


@interface NSInputManager (KeyEventHandling)
- (void)interpretKeyEvents: (NSArray *)eventArray;
@end /* @interface NSInputManager (KeyEventHandling) */


#if defined USE_INPUT_MANAGER_UTILITIES

typedef enum _IMState {
    IMNotFound = -1,
    IMPending = 0,
    IMFound
} IMQueryResult;


@interface IMCharacter : NSObject <NSCopying>
{
  unichar	character;
  unsigned int	modifiers;
}

- (id)initWithCharacter: (unichar)c
	      modifiers: (unsigned int)flags;
- (id)characterWithCharacter: (unichar)c
		   modifiers: (unsigned int)flags;

- (void)setCharacter: (unichar)c;
- (unichar)character;

- (void)setModifiers: (unsigned int)flags;
- (unsigned int)modifiers;
@end /* @interface IMCharacter : NSObject <NSCopying> */


@interface IMKeyBindingTable : NSObject
{
  NSDictionary	*bindings;	    /* key - IMCharacter, value - SEL */
  NSDictionary	*branch;	
}

- (id)initWithKeyBindingDictionary: (NSDictionary *)bindings;

- (IMQueryResult)getSelectorForCharacter: (IMCharacter *)c
				selector: (SEL *)sel;
@end /* @interface IMKeyBindingTable */


/* AlphaShift */
static inline void
setAlphaShiftKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearAlphaShiftKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isAlphaShiftKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Shift */
static inline void
setShiftKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearShiftKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isShiftKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Control */
static inline void
setControlKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearControlKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isControlKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Alternate */
static inline void
setAlternateKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearAlternateKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isAlternateKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Command */
static inline void
setCommandKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearCommandKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isCommandKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* NumericPad */
static inline void
setNumericPadKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearNumericPadKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isNumericPadKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Help */
static inline void
setHelpKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearHelpKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isHelpKeyOn(unsigned int modifiers) __attribute__((always_inline));

/* Function */
static inline void
setFunctionKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline void
clearFunctionKeyMask(unsigned int *modifiers) __attribute__((always_inline));
static inline BOOL
isFunctionKeyOn(unsigned int modifiers) __attribute__((always_inline));


/* Templates for defining the static inline functions */
#define defineIsOnProc(KeyName) \
static inline BOOL is ## KeyName ## KeyOn(unsigned int modifiers) \
{ \
    return modifiers & NS ## KeyName ## KeyMask; \
}

#define defineSetMaskProc(KeyName) \
static inline void set ## KeyName ## KeyMask(unsigned int *modifiers) \
{ \
    *modifiers |= NS ## KeyName ## KeyMask; \
}

#define defineClearMaskProc(KeyName) \
static inline void clear ## KeyName ## KeyMask(unsigned int *modifiers) \
{ \
    *modifiers &= ~NS ## KeyName ## KeyMask; \
}


/* Implementations of the static inline functions */
defineIsOnProc(AlphaShift)
defineSetMaskProc(AlphaShift)
defineClearMaskProc(AlphaShift)

defineIsOnProc(Shift)
defineSetMaskProc(Shift)
defineClearMaskProc(Shift)

defineIsOnProc(Control)
defineSetMaskProc(Control)
defineClearMaskProc(Control)

defineIsOnProc(Alternate)
defineSetMaskProc(Alternate)
defineClearMaskProc(Alternate)

defineIsOnProc(Command)
defineSetMaskProc(Command)
defineClearMaskProc(Command)

defineIsOnProc(NumericPad)
defineSetMaskProc(NumericPad)
defineClearMaskProc(NumericPad)

defineIsOnProc(Help)
defineSetMaskProc(Help)
defineClearMaskProc(Help)

defineIsOnProc(Function)
defineSetMaskProc(Function)
defineClearMaskProc(Function)

#endif /* #if defined USE_INPUT_MANAGER_UTILITIES */


#endif /* _GNUstep_NSInputManager_h */
