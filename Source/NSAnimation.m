/*
 * NSAnimation.m
 *
 * Created by Dr. H. Nikolaus Schaller on Sat Mar 06 2006.
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

#include <AppKit/NSAnimation.h>

NSString *NSAnimationProgressMarkNotification
  = @"NSAnimationProgressMarkNotification";

NSString *NSViewAnimationTargetKey = @"NSViewAnimationTargetKey";
NSString *NSViewAnimationStartFrameKey = @"NSViewAnimationStartFrameKey";
NSString *NSViewAnimationEndFrameKey = @"NSViewAnimationEndFrameKey";
NSString *NSViewAnimationEffectKey = @"NSViewAnimationEffectKey";
NSString *NSViewAnimationFadeInEffect = @"NSViewAnimationFadeInEffect";
NSString *NSViewAnimationFadeOutEffect = @"NSViewAnimationFadeOutEffect";

@implementation NSAnimation

- (void) addProgressMark: (NSAnimationProgress) progress
{
  [self notImplemented: _cmd];
}

- (NSAnimationBlockingMode) animationBlockingMode
{
  return _animationBlockingMode;
}

- (NSAnimationCurve) animationCurve
{
  return _animationCurve;
}

- (void) clearStartAnimation
{
  [self notImplemented: _cmd];
}

- (void) clearStopAnimation
{
  [self notImplemented: _cmd];
}

- (NSAnimationProgress) currentProgress
{
  return _currentProgress;
}

- (float) currentValue
{
  return _currentValue;
}

- (id) delegate
{
  return _delegate;
}

- (NSTimeInterval) duration
{
  return _duration;
}

- (float) frameRate
{
  return _frameRate;
}

- (id) initWithDuration: (NSTimeInterval) duration animationCurve:
  (NSAnimationCurve) curve
{
  if ((self = [super init]))
    {
      _duration = duration;
      _animationCurve = curve;
    }
  return self;
}

- (id) copyWithZone: (NSZone *) zone
{
  return [self notImplemented: _cmd];
}

- (void) dealloc
{
  [_progressMarks release];
  [super dealloc];
}

- (BOOL) isAnimating
{
  return _isAnimating;
}

- (NSArray *) progressMarks
{
  return _progressMarks;
}

- (void) removeProgressMark: (NSAnimationProgress) progress
{
  [self notImplemented: _cmd];
}

- (NSArray *) runLoopModesForAnimating
{
  return nil;
}

- (void) setAnimationBlockingMode: (NSAnimationBlockingMode) mode
{
  _animationBlockingMode = mode;
}

- (void) setAnimationCurve: (NSAnimationCurve) curve
{
  _animationCurve = curve;
}

- (void) setCurrentProgress: (NSAnimationProgress) progress
{
  _currentProgress = progress;
}

- (void) setDelegate: (id) delegate
{
  _delegate = delegate;
}

- (void) setDuration: (NSTimeInterval) duration
{
  _duration = duration;
}

- (void) setFrameRate: (float) fps
{
  _frameRate = fps;
}

- (void) setProgressMarks: (NSArray *) progress
{
  ASSIGN(_progressMarks, progress) ;
}

- (void) _animate
{
  [self notImplemented: _cmd];
  // call delegate
  // estimate delay to keep fps
  // create new timer
}

- (void) startAnimation
{
  _isAnimating = YES;
  [self _animate];
}

- (void) startWhenAnimation: (NSAnimation *) animation reachesProgress:
  (NSAnimationProgress) start
{
  [self notImplemented: _cmd];
}

- (void) stopAnimation
{
  [self notImplemented: _cmd];
  // remove any timer
  _isAnimating = NO;
}

- (void) stopWhenAnimation: (NSAnimation *) animation reachesProgress:
  (NSAnimationProgress) stop
{
  [self notImplemented: _cmd];
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [self notImplemented: _cmd];
}

- (id) initWithCoder: (NSCoder *) coder
{
  return [self notImplemented: _cmd];
}

@end

@implementation NSViewAnimation

- (id) initWithViewAnimations: (NSArray *) animations
{
  if ((self = [super init]))
    {
      _viewAnimations = [animations retain];
    }
  return self;
}

- (void) dealloc
{
  [_viewAnimations release];
  [super dealloc];
}

- (void) setWithViewAnimations: (NSArray *) animations
{
  ASSIGN(_viewAnimations, animations) ;
}

- (NSArray *) viewAnimations
{
  return _viewAnimations;
}

@end

