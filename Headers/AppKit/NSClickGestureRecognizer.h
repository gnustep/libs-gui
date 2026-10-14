/* Definition of class NSClickGestureRecognizer
   Copyright (C) 2019 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Thu Dec  5 12:54:21 EST 2019

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _NSClickGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#define _NSClickGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSGestureRecognizer.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSClickGestureRecognizer : NSGestureRecognizer
{
  /** The mouse button mask that triggers this gesture (default: left mouse button) */
  NSUInteger _buttonMask;
  /** The number of clicks required to trigger this gesture (default: 1) */
  NSUInteger _numberOfClicksRequired;
  /** The number of touches required for the gesture (default: 1) */
  NSUInteger _numberOfTouchesRequired;
}

/**
 * Returns the mouse button mask that triggers this gesture.
 * The default value is 1 (left mouse button).
 * Returns: The mouse button mask for this gesture
 */
- (NSUInteger)buttonMask;

/**
 * Sets the mouse button mask that triggers this gesture.
 * Use NSLeftMouseDownMask, NSRightMouseDownMask, etc.
 * mask: The mouse button mask to set
 */
- (void)setButtonMask:(NSUInteger)mask;

/**
 * Returns the number of clicks required to trigger this gesture.
 * The default value is 1 (single click).
 * Returns: The number of clicks required
 */
- (NSUInteger)numberOfClicksRequired;

/**
 * Sets the number of clicks required to trigger this gesture.
 * clicks: The number of clicks required (must be >= 1)
 */
- (void)setNumberOfClicksRequired:(NSUInteger)clicks;

/**
 * Returns the number of touches required for this gesture.
 * The default value is 1.
 * Returns: The number of touches required
 */
- (NSUInteger)numberOfTouchesRequired;

/**
 * Sets the number of touches required for this gesture.
 * touches: The number of touches required (must be >= 1)
 */
- (void)setNumberOfTouchesRequired:(NSUInteger)touches;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSClickGestureRecognizer_h_GNUSTEP_GUI_INCLUDE */

