/* Definition of class NSPressGestureRecognizer
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

#ifndef _NSPressGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#define _NSPressGestureRecognizer_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSGestureRecognizer.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

@class NSTimer;

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
/**
 * NSPressGestureRecognizer is a concrete subclass of NSGestureRecognizer
 * that recognizes press and hold gestures. A press gesture occurs when the
 * user presses down on the view and holds for a specified minimum duration
 * without moving beyond an allowable movement threshold. This recognizer is
 * commonly used to trigger contextual menus, begin drag operations, or
 * activate special editing modes in user interface elements.
 *
 * The recognizer monitors mouse down events and starts an internal timer
 * when a press begins. If the user maintains the press for the minimum
 * duration without moving beyond the allowable movement threshold, the
 * gesture is recognized and transitions to the began state. The gesture
 * continues in the changed state as long as the press is maintained within
 * the movement bounds, and transitions to ended when the user releases.
 *
 * Key configuration properties include minimumPressDuration which defaults
 * to 0.5 seconds, allowableMovement which defaults to 10 points, and
 * numberOfTouchesRequired which defaults to 1. The recognizer fails if
 * the user moves beyond the allowable distance or releases before the
 * minimum duration is reached.
 */
@interface NSPressGestureRecognizer : NSGestureRecognizer
{
@private
    NSTimeInterval _minimumPressDuration;
    CGFloat _allowableMovement;
    NSUInteger _numberOfTouchesRequired;
    NSTimer *_pressTimer;
    NSPoint _initialLocation;
    BOOL _pressDetected;
}

// Configuring the Press Gesture
/**
 * Returns the minimum duration in seconds that a press must be held
 * before the gesture is recognized. This value determines how long
 * the user must maintain contact with the view before the press
 * gesture transitions from the possible state to the began state.
 * The default value is 0.5 seconds, providing a balance between
 * responsiveness and preventing accidental activations.
 */
- (NSTimeInterval) minimumPressDuration;

/**
 * Sets the minimum duration in seconds that a press must be held
 * before the gesture is recognized. Values less than 0 are clamped
 * to 0. Setting a shorter duration makes the gesture more responsive
 * but may increase accidental activations. Setting a longer duration
 * makes the gesture more deliberate but may feel less responsive to
 * users. The duration is measured from the initial mouse down event.
 */
- (void) setMinimumPressDuration: (NSTimeInterval)duration;

/**
 * Returns the maximum distance in points that the user can move
 * during the press without causing the gesture to fail. This
 * tolerance accounts for natural hand tremor and slight movements
 * during a press gesture. The distance is calculated as the
 * Euclidean distance from the initial press location to the
 * current location. The default value is 10 points.
 */
- (CGFloat) allowableMovement;

/**
 * Sets the maximum distance in points that the user can move during
 * the press without causing the gesture to fail. Values less than 0
 * are clamped to 0. A smaller value makes the gesture more strict
 * about movement but may be difficult to use. A larger value is more
 * forgiving but may allow unintended movements to be recognized as
 * valid press gestures. Movement is measured from the initial location.
 */
- (void) setAllowableMovement: (CGFloat)movement;

/**
 * Returns the number of touches or mouse clicks required for the
 * press gesture to be recognized. For mouse-based systems, this
 * typically remains 1 since multiple simultaneous mouse presses
 * are not common. The default value is 1, meaning a single press
 * is required to trigger the gesture recognition process.
 */
- (NSUInteger) numberOfTouchesRequired;

/**
 * Sets the number of touches or mouse clicks required for the press
 * gesture to be recognized. Values of 0 are clamped to 1 to ensure
 * at least one touch is required. This property is primarily useful
 * for touch-based interfaces where multiple finger presses might
 * be desired. For traditional mouse interfaces, this should remain
 * at the default value of 1 for optimal user experience.
 */
- (void) setNumberOfTouchesRequired: (NSUInteger)numberOfTouches;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSPressGestureRecognizer_h_GNUSTEP_GUI_INCLUDE */

