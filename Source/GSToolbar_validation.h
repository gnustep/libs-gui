/* 
   GSToolbar_validation.h

   Toolbar validation mechanism
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: February 2004
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/Foundation.h>
@class NSWindow, NSView;

/* 
 * Validation support
 * 
 * Validation support is architectured around a shared validation center, which
 * is our public interface to handle the validation, behind the scene each
 * window has an associated validation object created when an observer is added
 * to the validation center.
 * A validation object calls the _validate: method on the observer when the
 * mouse is inside the observed window and only in the case this window is
 * updated or in the case the mouse stays inside more than four seconds, then
 * the action will be reiterated every four seconds until the mouse exits.
 * A validation object owns a window to observe, a tracking rect attached to
 * the window root view to know when the mouse is inside, a timer to be able to
 * send the _validate: message periodically, and one ore more observers, then it
 * is necessary to supply with each registered observer an associated window to
 * observe.
 * In the case, an object would observe several windows, the _validate: has a
 * parameter observedWindow to let us know where the message is coming from.
 * Because we cannot know surely when a validation object is deallocated, a
 * method named clean has been added which permits to invalidate a validation
 * object which must not be used anymore, not calling it would let segmentation
 * faults occurs.
 */

@interface GSValidationObject : NSObject
{
  NSWindow *_window;
  NSView *_trackingRectView;
  NSTrackingRectTag _trackingRect;
  NSMutableArray *_observers;
  NSTimer *_validationTimer;
  BOOL _inside;
  BOOL _validating;
}

- (NSMutableArray *) observers;
- (void) setObservers: (NSMutableArray *)observers;
- (NSWindow *) window;
- (void) setWindow: (NSWindow *)window;
- (void) validate;
- (void) scheduledValidate;
- (void) clean;

@end

@interface GSValidationCenter : NSObject
{
  NSMutableArray *_vobjs;
}

+ (GSValidationCenter *) sharedValidationCenter;

- (NSArray *) observersWindow: (NSWindow *)window;
- (void) addObserver: (id)observer window: (NSWindow *)window;
- (void) removeObserver: (id)observer window: (NSWindow *)window;

@end
