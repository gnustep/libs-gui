/*
 * GSAnimator.h
 *
 * Author: Xavier Glattard (xgl) <xavier.glattard@online.fr>
 *
 * Copyright (c) 2007 Free Software Foundation, Inc.
 *
 * This file used to be part of the mySTEP Library.
 * This file now is part of the GNUstep GUI Library.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; see the file COPYING.LIB.
 * If not, write to the Free Software Foundation,
 * 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */ 

#ifndef _GNUstep_H_GSAnimator_
#define _GNUstep_H_GSAnimator_

@class NSRunLoop;
@class NSEvent;
@class NSTimer;
@class NSThread;

#include <Foundation/NSObject.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSTimer.h>

/**
 * Protocol that needs to be adopted by classes that want to
 * be animated by a GSAnimator.
 */
@protocol GSAnimation
/** Returns the run-loop modes useed to run the animation timer in. */
- (NSArray*) runLoopModesForAnimating;
/** Call back method indicating that the GSAnimator did start the
 * animation loop. */
- (void) animatorDidStart;
/** Call back method indicating that the GSAnimator did stop the
 * animation loop. */
- (void) animatorDidStop;
/** Call back method called for each animation loop. */
- (void) animatorStep: (NSTimeInterval) elapsedTime;
@end

typedef enum
{
  GSTimerBasedAnimation,
  GSPerformerBasedAnimation,
  // Cocoa compatible animation modes :
  GSBlockingCocoaAnimation,
  GSNonblockingCocoaAnimation,
  GSNonblockingCocoaThreadedAnimation
} GSAnimationBlockingMode;

/**
 * GSAnimator is the front of a class cluster. Instances of a subclass of 
 * GSAnimator manages the timing of an animation.
 */
@interface GSAnimator : NSObject
{
  id<GSAnimation> _animation; // The Object to be animated
  NSDate *_startTime;         // The time the animation did started
  BOOL _running;              // Indicates that the animator is looping

  NSTimeInterval _elapsed;    // Elapsed time since the animator started
  NSTimeInterval _lastFrame;  // The time of the last animation loop
  unsigned int _frameCount;   // The number of loops since the start

  NSRunLoop *_runLoop;        // The run-loop used for looping
  
  NSTimer *_timer;            // Timer used for looping
  NSTimeInterval _timerInterval;
}

/** Returns a GSAnimator object initialized with the specified object
 * to be animated. */
+ (GSAnimator*) animatorWithAnimation: (id<GSAnimation>)anAnimation
                                 mode: (GSAnimationBlockingMode)aMode
                            frameRate: (float)fps;

/** Returns a GSAnimator object allocated in the given NSZone and 
 * initialized with the specified object to be animated. */
+ (GSAnimator*) animatorWithAnimation: (id<GSAnimation>)anAnimation
                                 mode: (GSAnimationBlockingMode)aMode
                            frameRate: (float)fps
			         zone: (NSZone*)aZone;

/** Returns a GSAnimator object initialized with the specified object
 * to be animated. */
- (GSAnimator*) initWithAnimation: (id<GSAnimation>)anAnimation
                        frameRate: (float)aFrameRate
                          runLoop: (NSRunLoop*)aRunLoop;
- (GSAnimator*) initWithAnimation: (id<GSAnimation>)anAnimation;

- (unsigned int) frameCount;
- (void) resetCounters;
- (float) frameRate;
- (NSRunLoop*) runLoopForAnimating;
- (NSArray*) runLoopModesForAnimating;

- (void) startAnimation;
- (void) stopAnimation;
- (BOOL) isAnimationRunning;
- (void) startStopAnimation;

- (void) stepAnimation;

- (void) animationLoopEvent: (NSEvent*)e;
@end

#endif /* _GNUstep_H_GSAnimator_ */
