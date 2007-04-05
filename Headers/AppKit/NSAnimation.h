/*
 * NSAnimation.h
 *
 * Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
 * Copyright (c) 2007 Free Software Foundation, Inc.
 *
 * Author: Xavier Glattard (xgl) <xavier.glattard@online.fr>
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

#ifndef _GNUstep_H_NSAnimation_
#define _GNUstep_H_NSAnimation_

#include <GNUstepBase/GSVersionMacros.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)

#include <Foundation/NSObject.h>
#include <AppKit/AppKitDefines.h>
#include <GNUstepGUI/GSAnimator.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

// Bezier curve parameters
typedef struct __GSBezierDesc
{
  float p[4]; // control points
  BOOL areCoefficientsComputed;
  float a[4]; // coefficients
} _GSBezierDesc;

static inline void 
_GSBezierComputeCoefficients( _GSBezierDesc *b )
{
  b->a[0] =     b->p[0];
  b->a[1] =-3.0*b->p[0]+3.0*b->p[1];
  b->a[2] = 3.0*b->p[0]-6.0*b->p[1]+3.0*b->p[2];
  b->a[3] =-    b->p[0]+3.0*b->p[1]-3.0*b->p[2]+b->p[3];
  b->areCoefficientsComputed = YES;
}

static inline float 
_GSBezierEval( _GSBezierDesc *b, float t )
{
  if(!b->areCoefficientsComputed)
    _GSBezierComputeCoefficients(b);
  return b->a[0]+t*(b->a[1]+t*(b->a[2]+t*b->a[3]));
}

static inline float 
_GSBezierDerivEval( _GSBezierDesc *b, float t )
{
  if(!b->areCoefficientsComputed)
    _GSBezierComputeCoefficients(b);
  return b->a[1]+t*(2.0*b->a[2]+t*3.0*b->a[3]);
}

// Rational Bezier curve parameters
typedef struct __GSRationalBezierDesc
{
  float w[4]; // weights
  float p[4]; // control points
  BOOL areBezierDescComputed;
  _GSBezierDesc n; // numerator
  _GSBezierDesc d; // denumerator
} _GSRationalBezierDesc;

static inline void 
_GSRationalBezierComputeBezierDesc( _GSRationalBezierDesc *rb )
{
  unsigned i;
  for(i=0;i<4;i++)
    rb->n.p[i] = (rb->d.p[i] = rb->w[i]) * rb->p[i];
  _GSBezierComputeCoefficients(&rb->n);
  _GSBezierComputeCoefficients(&rb->d);
  rb->areBezierDescComputed = YES;
}
 
static inline float
_GSRationalBezierEval( _GSRationalBezierDesc *rb, float t)
{
  if(!rb->areBezierDescComputed)
    _GSRationalBezierComputeBezierDesc(rb);
  return _GSBezierEval(&(rb->n),t)/_GSBezierEval(&(rb->d),t);
}

static inline float
_GSRationalBezierDerivEval( _GSRationalBezierDesc *rb, float t)
{
  if(!rb->areBezierDescComputed)
    _GSRationalBezierComputeBezierDesc(rb);
  float h = _GSBezierEval(&(rb->d),t);
  return ( _GSBezierDerivEval(&(rb->n),t) * h 
         - _GSBezierEval     (&(rb->n),t) * _GSBezierDerivEval(&(rb->d),t) )
    / (h*h);
}

typedef struct __NSAnimationCurveDesc
{
  float s,e; // start & end values
  float sg,eg; // start & end gradients 
  _GSRationalBezierDesc rb;
  BOOL isRBezierComputed;
} _NSAnimationCurveDesc;

extern
_NSAnimationCurveDesc *_gs_animationCurveDesc;

static inline float
_gs_animationValueForCurve( _NSAnimationCurveDesc *c, float t, float t0 )
{
  if(!c->isRBezierComputed)
  {
    c->rb.p[0] = c->s;
    c->rb.p[1] = c->s + (c->sg*c->rb.w[0])/(3*c->rb.w[1]);
    c->rb.p[2] = c->e - (c->eg*c->rb.w[3])/(3*c->rb.w[2]);
    c->rb.p[3] = c->e;
    _GSRationalBezierComputeBezierDesc(&c->rb);
    c->isRBezierComputed = YES;
  }
  return _GSRationalBezierEval( &(c->rb),(t-t0)/(1.0-t0) );
}

@class NSString;
@class NSArray;
@class NSNumber;

/** These constants describe the curve of an animation—that is, the relative speed of an animation from start to finish. */
typedef enum _NSAnimationCurve
{
  NSAnimationEaseInOut = 0, // default
  NSAnimationEaseIn,
  NSAnimationEaseOut,
  NSAnimationLinear,
  NSAnimationSpeedInOut // GNUstep only
} NSAnimationCurve;

/** These constants indicate the blocking mode of an NSAnimation object when it is running. */
typedef enum _NSAnimationBlockingMode
{
  NSAnimationBlocking		 = GSBlockingCocoaAnimation,
  NSAnimationNonblocking	 = GSNonblockingCocoaAnimation,
  NSAnimationNonblockingThreaded = GSNonblockingCocoaThreadedAnimation
} NSAnimationBlockingMode;

typedef float NSAnimationProgress;

/** Posted when the current progress of a running animation reaches one of its progress marks. */
APPKIT_EXPORT NSString *NSAnimationProgressMarkNotification;

/**
 * Objects of the NSAnimation class manage the timing and progress of
 * animations in the user interface. The class also lets you link together
 * multiple animations so that when one animation ends another one starts.
 * It does not provide any drawing support for animation and does not directly
 * deal with views, targets, or actions.
 */
@interface NSAnimation : NSObject < NSCopying, NSCoding, GSAnimation >
{
  NSTimeInterval _duration;		  // Duration of the animation
  float _frameRate;			  // Wanted frame rate
  NSAnimationCurve _curve;		  // Id of progres->value function
  _NSAnimationCurveDesc _curveDesc;       // The curve as a rat. Bezier
  NSAnimationProgress _curveProgressShift;// Shift used for switching
					  //   from a curve to an other
  NSAnimationProgress _currentProgress;   // Progress of the animation

  /* GSIArray<NSAnimationProgress> */ void *_progressMarks; // Array
  unsigned int _nextMark;                 // The next mark to be reached
                                          //   = count if no next mark
  NSNumber **_cachedProgressMarkNumbers;  // Cached values used by
  unsigned _cachedProgressMarkNumberCount;//   [-progressMarks]
  BOOL _isCachedProgressMarkNumbersValid;

  NSAnimation *_startAnimation, *_stopAnimation; // Animations used as
  NSAnimationProgress _startMark, _stopMark;     // trigger, and marks

  NSAnimationBlockingMode _blockingMode;  // Blocking mode
  GSAnimator *_animator;                  // The animator
  BOOL _isANewAnimatorNeeded;              // Some parameters have changed...

  id _delegate; // The delegate, and the cached delegation methods...
  void  (*_delegate_animationDidReachProgressMark)(id,SEL,NSAnimation*,NSAnimationProgress);
  float (*_delegate_animationValueForProgress    )(id,SEL,NSAnimation*,NSAnimationProgress);
  void  (*_delegate_animationDidEnd              )(id,SEL,NSAnimation*);
  void  (*_delegate_animationDidStop             )(id,SEL,NSAnimation*);
  BOOL  (*_delegate_animationShouldStart         )(id,SEL,NSAnimation*);
}

/** Adds the progress mark to the receiver. */
- (void) addProgressMark: (NSAnimationProgress)progress;

/** Returns the blocking mode the receiver is next scheduled to run under. */
- (NSAnimationBlockingMode) animationBlockingMode;

/** Returns the animation curve the receiver is running under. */
- (NSAnimationCurve) animationCurve;

/** Clears linkage to another animation that causes the receiver to start. */
- (void) clearStartAnimation;

/** Clears linkage to another animation that causes the receiver to stop. */
- (void) clearStopAnimation;

/** Returns the current progress of the receiver. */
- (NSAnimationProgress) currentProgress;

/** Returns the current value of the effect based on the current progress. */
- (float) currentValue;

/** Returns the delegate of the receiver. */
- (id) delegate;

/** Returns the duration of the animation, in seconds. */
- (NSTimeInterval) duration;

/** Returns the frame rate of the animation. */
- (float) frameRate;

/** Returns an NSAnimation object initialized with the specified duration and animation-curve values. */
- (id) initWithDuration: (NSTimeInterval)duration
         animationCurve: (NSAnimationCurve)curve;

/** Returns a Boolean value that indicates whether the receiver is currently animating. */
- (BOOL) isAnimating;

/** Returns the receiver’s progress marks. */
- (NSArray*) progressMarks;

/** Removes progress mark from the receiver. */
- (void) removeProgressMark: (NSAnimationProgress)progress;

/** Overridden to return the run-loop modes that the receiver uses to run the animation timer in. */
- (NSArray*) runLoopModesForAnimating;

/** Sets the blocking mode of the receiver. */
- (void) setAnimationBlockingMode: (NSAnimationBlockingMode)mode;

/** Sets the receiver’s animation curve. */
- (void) setAnimationCurve: (NSAnimationCurve)curve;

/** Sets the current progress of the receiver. */
- (void) setCurrentProgress: (NSAnimationProgress)progress;

/** Sets the delegate of the receiver. */
- (void) setDelegate: (id)delegate;

/** Sets the duration of the animation to a specified number of seconds. */
- (void) setDuration: (NSTimeInterval)duration;

/** Sets the frame rate of the receiver. */
- (void) setFrameRate: (float)fps;

/** Sets the receiver’s progress marks to the values specified in the passed-in array. */
- (void) setProgressMarks: (NSArray*)progress;

/** Starts the animation represented by the receiver. */
- (void) startAnimation;

/** Starts running the animation represented by the receiver when another animation reaches a specific progress mark. */
- (void) startWhenAnimation: (NSAnimation*)animation
            reachesProgress: (NSAnimationProgress)start;

/** Stops the animation represented by the receiver. */
- (void) stopAnimation;

/** Stops running the animation represented by the receiver when another animation reaches a specific progress mark. */
- (void) stopWhenAnimation: (NSAnimation*)animation
           reachesProgress: (NSAnimationProgress)stop;

@end

@interface NSAnimation (GNUstep)

/** Returns the current value of the frame counter */
- (unsigned int) frameCount;

/** Resets all stats */
- (void) resetCounters;

/** Returns the current the actual (mesured) frame rate value */
- (float) actualFrameRate;

@end

@interface NSObject (NSAnimation)

/** NSAnimation delegate method.
 * Sent to the delegate when an animation reaches a specific progress mark. */
- (void)     animation: (NSAnimation*)animation
  didReachProgressMark: (NSAnimationProgress)progress;

/** NSAnimation delegate method.
 * Requests a custom curve value for the current progress value. */
- (float) animation: (NSAnimation*)animation
   valueForProgress: (NSAnimationProgress)progress;

/** NSAnimation delegate method.
 * Sent to the delegate when the specified animation completes its run. */
- (void) animationDidEnd: (NSAnimation*)animation;

/** NSAnimation delegate method.
 * Sent to the delegate when the specified animation is stopped before it completes its run. */
- (void) animationDidStop: (NSAnimation*)animation;

/** NSAnimation delegate method.
 * Sent to the delegate just after an animation is started. */
- (BOOL) animationShouldStart: (NSAnimation*)animation;

@end

APPKIT_EXPORT NSString *NSViewAnimationTargetKey;
APPKIT_EXPORT NSString *NSViewAnimationStartFrameKey;
APPKIT_EXPORT NSString *NSViewAnimationEndFrameKey;
APPKIT_EXPORT NSString *NSViewAnimationEffectKey;

APPKIT_EXPORT NSString *NSViewAnimationFadeInEffect;
APPKIT_EXPORT NSString *NSViewAnimationFadeOutEffect;

/**
 * The NSViewAnimation class, a public subclass of NSAnimation,
 * offers a convenient way to animate multiple views and windows.
 * The animation effects you can achieve are limited to changes in
 * frame location and size, and to fade-in and fade-out effects.
 */
@interface NSViewAnimation : NSAnimation
{
  NSArray *_viewAnimations;
  NSMutableArray *_viewAnimationDesc;
}

/** Returns an NSViewAnimation object initialized with the supplied information. */
- (id) initWithViewAnimations: (NSArray*)animations;

/** Sets the dictionaries defining the objects to animate. */
- (void) setViewAnimations: (NSArray*)animations;

/** Returns the array of dictionaries defining the objects to animate. */
- (NSArray*) viewAnimations;

@end

#endif /* OS_API_VERSION */

#endif /* _GNUstep_H_NSAnimation_ */

