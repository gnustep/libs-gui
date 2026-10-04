/* Definition of class NSPanGestureRecognizer
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

#ifndef _NSPanGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#define _NSPanGestureRecognizer_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSGestureRecognizer.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSPanGestureRecognizer : NSGestureRecognizer
{
  /** The minimum number of touches required for the gesture (default: 1) */
  NSUInteger _minimumNumberOfTouches;
  /** The maximum number of touches allowed for the gesture (default: NSUIntegerMax) */
  NSUInteger _maximumNumberOfTouches;
  /** The current translation of the pan gesture relative to the initial touch point */
  NSPoint _translation;
  /** The velocity of the pan gesture in points per second */
  NSPoint _velocity;
  /** The starting location of the pan gesture */
  NSPoint _startLocation;
  /** The previous location for velocity calculation */
  NSPoint _previousLocation;
  /** The timestamp of the previous location update */
  NSTimeInterval _previousTime;
  /** Flag indicating whether the gesture is currently in progress */
  BOOL _isTracking;
  /** The button mask for which mouse button triggers the pan */
  NSUInteger _buttonMask;
}

/**
 * Returns the minimum number of touches required to trigger the pan gesture.
 * The default value is 1.
 * Returns: The minimum number of touches required
 */
- (NSUInteger)minimumNumberOfTouches;

/**
 * Sets the minimum number of touches required to trigger the pan gesture.
 * touches: The minimum number of touches (must be >= 1)
 */
- (void)setMinimumNumberOfTouches:(NSUInteger)touches;

/**
 * Returns the maximum number of touches allowed for the pan gesture.
 * The default value is NSUIntegerMax (unlimited).
 * Returns: The maximum number of touches allowed
 */
- (NSUInteger)maximumNumberOfTouches;

/**
 * Sets the maximum number of touches allowed for the pan gesture.
 * touches: The maximum number of touches (must be >= minimumNumberOfTouches)
 */
- (void)setMaximumNumberOfTouches:(NSUInteger)touches;

/**
 * Returns the translation of the pan gesture in the coordinate system of the specified view.
 * If view is nil, returns the translation in the gesture recognizer's view coordinates.
 * view: The view in whose coordinate system the translation should be returned
 * Returns: The translation as an NSPoint
 */
- (NSPoint)translationInView:(NSView *)view;

/**
 * Sets the translation value for the pan gesture in the coordinate system of the specified view.
 * This allows you to reset or adjust the translation during a pan.
 * translation: The new translation value
 * view: The view in whose coordinate system the translation is specified
 */
- (void)setTranslation:(NSPoint)translation inView:(NSView *)view;

/**
 * Returns the velocity of the pan gesture in the coordinate system of the specified view.
 * The velocity is measured in points per second.
 * view: The view in whose coordinate system the velocity should be returned
 * Returns: The velocity as an NSPoint with x and y components in points per second
 */
- (NSPoint)velocityInView:(NSView *)view;

/**
 * Returns the mouse button mask that triggers this pan gesture.
 * The default value is 1 (left mouse button).
 * Returns: The mouse button mask for this gesture
 */
- (NSUInteger)buttonMask;

/**
 * Sets the mouse button mask that triggers this pan gesture.
 * Use 1 for left button, 2 for right button, 4 for middle button, etc.
 * mask: The mouse button mask to set
 */
- (void)setButtonMask:(NSUInteger)mask;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSPanGestureRecognizer_h_GNUSTEP_GUI_INCLUDE */

