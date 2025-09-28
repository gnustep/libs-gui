/* Definition of class NSRotationGestureRecognizer
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

#ifndef _NSRotationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE
#define _NSRotationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSGestureRecognizer.h>
#import <Foundation/NSTimer.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSRotationGestureRecognizer : NSGestureRecognizer
{
@private
    CGFloat _rotation;
    CGFloat _velocity;
    NSPoint _initialLocation;
    NSPoint _currentLocation;
    CGFloat _initialAngle;
    CGFloat _currentAngle;
    NSTimeInterval _initialTime;
    NSTimeInterval _currentTime;
    BOOL _rotationStarted;
}

// Getting the Rotation Values
- (CGFloat) rotation;

- (CGFloat) velocity;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSRotationGestureRecognizer_h_GNUSTEP_GUI_INCLUDE */

