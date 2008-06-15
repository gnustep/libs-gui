/*
   GSAnimator.m
 
   Author: Xavier Glattard (xgl) <xavier.glattard@online.fr>
 
   Copyright (c) 2007 Free Software Foundation, Inc.
  
   This file used to be part of the mySTEP Library.
   This file now is part of the GNUstep GUI Library.
 
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#include <Foundation/NSTimer.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSString.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSDebug.h>

#include <AppKit/NSEvent.h>
#include <GNUstepGUI/GSAnimator.h>


typedef enum {
  NullEvent,
  GSAnimationNextFrameEvent,
  GSAnimationEventTypeNumber
} GSAnimationEventType;

@interface GSAnimator (private)
- (void) _animationBegin;
- (void) _animationLoop;
- (void) _animationEnd;
@end

@interface GSTimerBasedAnimator : GSAnimator
{ }
@end

@interface GSPerformerBasedAnimator : GSAnimator
{ }
@end

@implementation GSAnimator

+ (GSAnimator*) animatorWithAnimation: (id<GSAnimation>)anAnimation
                            frameRate: (float)fps
                                 zone: (NSZone*)aZone
{
  GSAnimator *animator;
  animator = [[GSTimerBasedAnimator allocWithZone: aZone]
                 initWithAnimation: anAnimation
                 frameRate: fps];
  AUTORELEASE(animator);
  return animator;
}

+ (GSAnimator*) animatorWithAnimation: (id<GSAnimation>)anAnimation
                            frameRate: (float)fps
{
  return [self animatorWithAnimation: anAnimation
               frameRate: fps
               zone: NULL];
}

+ (GSAnimator*) animatorWithAnimation: (id<GSAnimation>)anAnimation
{
  return [self animatorWithAnimation: anAnimation
               frameRate: 0.0];
}

- (GSAnimator*) initWithAnimation: (id<GSAnimation>)anAnimation
                        frameRate: (float)fps
{
  if ((self = [super init]))
    {
      _running = NO;
      
      ASSIGN(_animation, anAnimation);
      ASSIGN(_runLoopModes, [NSArray arrayWithObject: NSDefaultRunLoopMode]);
      _timerInterval = (fps == 0.0) ? 0.0 : (1.0 / fps);

      [self resetCounters];
    }
  return self;
}

- (GSAnimator*) initWithAnimation: (id<GSAnimation>)anAnimation
{
  return [self initWithAnimation: anAnimation
               frameRate: 0.0];
}

- (void) dealloc
{
  [self stopAnimation];
  TEST_RELEASE(_animation);
  TEST_RELEASE(_startTime);
  TEST_RELEASE(_runLoopModes);
  [super dealloc];
}

- (unsigned int) frameCount
{
  return _frameCount;
}

- (void) resetCounters
{
  _elapsed = 0.0;
  _frameCount = 0;
  _lastFrame = [NSDate timeIntervalSinceReferenceDate];
}

- (float) frameRate 
{
  return ((float)[self frameCount]) / ((float)_elapsed);
}

- (NSArray*) runLoopModesForAnimating
{
  return _runLoopModes;
}

- (void) setRunLoopModesForAnimating: (NSArray*)modes
{
  ASSIGN(_runLoopModes, modes);
}

- (void) startAnimation
{
  if (!_running)
    {
      _running = YES;
      [self resetCounters];
      [_animation animatorDidStart];
      [self _animationBegin];
      [self _animationLoop];
      NSDebugFLLog(@"GSAnimator", @"%@ Started !", self);
    }
}

- (void) stopAnimation
{
  if (_running)
    {
      _running = NO;
      [self _animationEnd];
      [_animation animatorDidStop];
    }
}

- (void) startStopAnimation
{
  if (_running)
    [self stopAnimation];
  else
    [self startAnimation];
}

- (BOOL) isAnimationRunning
{
  return _running;
}

- (void) _animationBegin
{
  [self subclassResponsibility: _cmd];
}

- (void) _animationLoop
{
  [self subclassResponsibility: _cmd];
}

- (void) _animationEnd
{
  [self subclassResponsibility: _cmd];
}

- (void) stepAnimation
{
  NSTimeInterval thisFrame = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval sinceLastFrame = (thisFrame - _lastFrame);

  _elapsed += sinceLastFrame;
  _lastFrame = thisFrame;

  [_animation animatorStep: _elapsed];
  _frameCount++;
}

- (void) animationLoopEvent: (NSEvent*)e
{
  [self subclassResponsibility: _cmd];
}

@end

static NSTimer *_GSTimerBasedAnimator_timer = nil;
static NSMutableSet *_GSTimerBasedAnimator_animators = nil;
static GSTimerBasedAnimator *_GSTimerBasedAnimator_the_one_animator = nil;
static int _GSTimerBasedAnimator_animator_count = 0;

@implementation GSTimerBasedAnimator

+ (void) loopsAnimators
{
  switch (_GSTimerBasedAnimator_animator_count)
    {
    case 0:
      break;
    case 1:
      [_GSTimerBasedAnimator_the_one_animator _animationLoop];
      break;
    default:
      [[NSNotificationCenter defaultCenter]
        postNotificationName: @"GSTimerBasedAnimator_loop" object: self];
    }
}

+ (void) registerAnimator: (GSTimerBasedAnimator*)anAnimator
{
  NSTimer *newTimer = nil;

  if (anAnimator->_timerInterval == 0.0)
    {
      NSDebugFLLog(@"GSAnimator", @"%@ AFAP", anAnimator);
      [[NSNotificationCenter defaultCenter]
        addObserver: anAnimator
           selector: @selector(_animationLoop)
               name: @"GSTimerBasedAnimator_loop"
             object: self];
    
      if (!_GSTimerBasedAnimator_animator_count++)
        _GSTimerBasedAnimator_the_one_animator = anAnimator;

      if (nil == _GSTimerBasedAnimator_animators)
        _GSTimerBasedAnimator_animators = [[NSMutableSet alloc] initWithCapacity: 5];
      [_GSTimerBasedAnimator_animators addObject: anAnimator];
    
      if (nil == _GSTimerBasedAnimator_timer)
        {
          newTimer =
          _GSTimerBasedAnimator_timer = [NSTimer
            timerWithTimeInterval: 0.0
                           target: self
                         selector: @selector(loopsAnimators)
                         userInfo: nil
                          repeats: YES
                          ];
        }
    }
  else
    {
      NSDebugFLLog(@"GSAnimator", @"%@ Fixed frame rate", anAnimator);
      newTimer =
      anAnimator->_timer = [NSTimer
        timerWithTimeInterval: anAnimator->_timerInterval
                       target: anAnimator
                     selector: @selector(_animationLoop)
                     userInfo: nil
                      repeats: YES
                      ];
    }
  if (newTimer != nil)
    {
      unsigned i,c;

      TEST_RETAIN(newTimer);
      for (i = 0, c = [anAnimator->_runLoopModes count]; i < c; i++)
        [[NSRunLoop currentRunLoop]
         addTimer: newTimer
          forMode: [anAnimator->_runLoopModes objectAtIndex:i]];
      NSDebugFLLog (@"GSAnimator",@"%@ addTimer in %d mode(s)",anAnimator,c);
    }
}

+ (void) unregisterAnimator: (GSTimerBasedAnimator*)anAnimator
{
  if (anAnimator->_timerInterval == 0.0)
    {
      [[NSNotificationCenter defaultCenter]
        removeObserver: anAnimator
                  name: @"GSTimerBasedAnimator_loop"
                object: self];

      [_GSTimerBasedAnimator_animators removeObject: anAnimator];
        
      if (!--_GSTimerBasedAnimator_animator_count)
        {
          [_GSTimerBasedAnimator_timer invalidate];
          DESTROY(_GSTimerBasedAnimator_timer);
          _GSTimerBasedAnimator_the_one_animator = nil;
        }
      else
        if (_GSTimerBasedAnimator_the_one_animator == anAnimator)
          _GSTimerBasedAnimator_the_one_animator
            = [_GSTimerBasedAnimator_animators anyObject];
    }
  else
    {
      if (anAnimator->_timer != nil)
        {
          [anAnimator->_timer invalidate];
          DESTROY(anAnimator->_timer);
        }
    }
}

- (void) _animationBegin
{
  NSDebugFLLog(@"GSAnimator", @"%@", self);
  [[self class] registerAnimator: self];
}

- (void) _animationLoop
{
  NSDebugFLLog(@"GSAnimator", @"%@", self);
  [self stepAnimation];
}

- (void) _animationEnd
{
  NSDebugFLLog(@"GSAnimator", @"%@", self);
  [[self class] unregisterAnimator: self];
}

@end // implementation GSTimerBasedAnimator

static void _sendAnimationPerformer(GSAnimator *animator)
{
  [[NSRunLoop currentRunLoop]
    performSelector: @selector(_animationLoop)
       	     target: animator
           argument: nil
	            order: 1000000
	            modes: [animator runLoopModesForAnimating]
  ];
}

static void _cancelAnimationPerformer(GSAnimator *animator)
{
  [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget: animator];
}

@implementation GSPerformerBasedAnimator

- (void) _animationBegin
{
  [self _animationLoop];
}

- (void) _animationLoop
{
  [self stepAnimation];
  if (_running)
    _sendAnimationPerformer(self);
}

- (void) _animationEnd
{ 
  _cancelAnimationPerformer(self);
}

@end
