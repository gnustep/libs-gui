/* Definition of class NSMagnificationGestureRecognizer
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

#ifndef _NSMagnificationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#define _NSMagnificationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSGestureRecognizer.h>
#import <Foundation/NSTimer.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_0, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
/**
 * NSMagnificationGestureRecognizer is a concrete subclass of NSGestureRecognizer
 * that recognizes magnification gestures, commonly known as pinch-to-zoom or
 * zoom gestures. This recognizer detects when the user performs a magnification
 * gesture using trackpad pinch gestures, scroll wheel events with modifier keys,
 * or mouse drag movements to indicate zooming intent.
 *
 * The recognizer monitors various input sources including trackpad magnification
 * events, Command+scroll wheel combinations, and distance-based mouse drag
 * gestures. When magnification input is detected, the recognizer transitions
 * from the possible state to began, then to changed for continued magnification,
 * and finally to ended when the magnification gesture completes.
 *
 * Key properties include magnification which provides the current magnification
 * factor as a floating-point value, and velocity which indicates the rate of
 * magnification change over time. Positive magnification values indicate zoom-in
 * operations while negative values represent zoom-out operations. The recognizer
 * accumulates magnification values throughout the gesture duration and calculates
 * velocity based on the total magnification change over elapsed time.
 */
@interface NSMagnificationGestureRecognizer : NSGestureRecognizer
{
@private
    CGFloat _magnification;
    CGFloat _velocity;
    NSPoint _initialLocation;
    CGFloat _initialMagnification;
    NSTimeInterval _initialTime;
    NSTimeInterval _currentTime;
    BOOL _magnificationStarted;
    CGFloat _cumulativeMagnification;
}

// Getting the Magnification Values
/**
 * Returns the current magnification factor for the gesture. This value
 * represents the incremental magnification change detected in the most
 * recent gesture update. Positive values indicate zoom-in magnification
 * while negative values indicate zoom-out magnification. The magnification
 * value is calculated from trackpad pinch gestures, scroll wheel events
 * with modifier keys, or mouse drag distance measurements. The value is
 * reset to zero when the gesture begins and updated continuously as the
 * magnification gesture progresses through its recognition cycle.
 */
- (CGFloat) magnification;

/**
 * Returns the velocity of the magnification gesture in magnification units
 * per second. This value indicates the rate at which the magnification is
 * changing over time, providing information about the speed and intensity
 * of the zoom gesture. Positive velocity values correspond to accelerating
 * zoom-in operations while negative values indicate accelerating zoom-out
 * operations. The velocity is calculated by dividing the cumulative
 * magnification change by the elapsed time since the gesture began. This
 * property is useful for implementing momentum-based zooming behaviors.
 */
- (CGFloat) velocity;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSMagnificationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE */

