/*
 * NSAnimation.h
 *
 * Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
 * Copyright (c) 2005 DSITRI.
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

#ifndef _NSAnimation_h_GNUstep_
#define _NSAnimation_h_GNUstep_

#include <Foundation/Foundation.h>

typedef enum _NSAnimationCurve
{
  NSAnimationEaseInOut = 0, // default
  NSAnimationEaseIn,
  NSAnimationEaseOut,
  NSAnimationLinear
} NSAnimationCurve;

typedef enum _NSAnimationBlockingMode
{
  NSAnimationBlocking,
  NSAnimationNonblocking,
  NSAnimationNonblockingThreaded
} NSAnimationBlockingMode;

typedef float NSAnimationProgress;

extern NSString *NSAnimationProgressMarkNotification;

@interface NSAnimation : NSObject < NSCopying, NSCoding >
{
  NSAnimationBlockingMode _animationBlockingMode;
  NSAnimationCurve _animationCurve;
  NSAnimationProgress _currentProgress;
  NSMutableArray *_progressMarks;
  id _delegate;
  NSTimeInterval _duration;
  float _currentValue;
  float _frameRate;
  BOOL _isAnimating; // ?or the NSThread *
}

- (void) addProgressMark: (NSAnimationProgress) progress;
- (NSAnimationBlockingMode) animationBlockingMode;
- (NSAnimationCurve) animationCurve;
- (void) clearStartAnimation;
- (void) clearStopAnimation;
- (NSAnimationProgress) currentProgress;
- (float) currentValue;
- (id) delegate;
- (NSTimeInterval) duration;
- (float) frameRate;
- (id) initWithDuration: (NSTimeInterval) duration animationCurve:
  (NSAnimationCurve) curve;
- (BOOL) isAnimating;
- (NSArray *) progressMarks;
- (void) removeProgressMark: (NSAnimationProgress) progress;
- (NSArray *) runLoopModesForAnimating;
- (void) setAnimationBlockingMode: (NSAnimationBlockingMode) mode;
- (void) setAnimationCurve: (NSAnimationCurve) curve;
- (void) setCurrentProgress: (NSAnimationProgress) progress;
- (void) setDelegate: (id) delegate;
- (void) setDuration: (NSTimeInterval) duration;
- (void) setFrameRate: (float) fps;
- (void) setProgressMarks: (NSArray *) progress;
- (void) startAnimation;
- (void) startWhenAnimation: (NSAnimation *) animation reachesProgress:
  (NSAnimationProgress) start;
- (void) stopAnimation;
- (void) stopWhenAnimation: (NSAnimation *) animation reachesProgress:
  (NSAnimationProgress) stop;

@end


@interface NSObject (NSAnimation)

- (void) animation: (NSAnimation *) animation didReachProgressMark:
  (NSAnimationProgress) progress;
- (float) animation: (NSAnimation *) animation valueForProgress:
  (NSAnimationProgress) progress;
- (void) animationDidEnd: (NSAnimation *) animation;
- (void) animationDidStop: (NSAnimation *) animation;
- (BOOL) animationShouldStart: (NSAnimation *) animation;

@end


extern NSString *NSViewAnimationTargetKey;
extern NSString *NSViewAnimationStartFrameKey;
extern NSString *NSViewAnimationEndFrameKey;
extern NSString *NSViewAnimationEffectKey;
extern NSString *NSViewAnimationFadeInEffect;
extern NSString *NSViewAnimationFadeOutEffect;

@interface NSViewAnimation : NSAnimation
{
  NSArray *_viewAnimations;
}

- (id) initWithViewAnimations: (NSArray *) animations;
- (void) setWithViewAnimations: (NSArray *) animations;
- (NSArray *) viewAnimations;

@end

#endif /* _NSAnimation_h_GNUstep_ */

