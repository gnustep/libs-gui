/*
 * NSAnimation.m
 *
 * Created by Dr. H. Nikolaus Schaller on Sat Mar 06 2006.
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

#include <AppKit/NSAnimation.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>
#include <Foundation/NSRunLoop.h>

// needed by NSViewAnimation
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>

#include <Foundation/NSDebug.h>

/*
 * NSAnimation class
 */

NSString *NSAnimationProgressMarkNotification
  = @"NSAnimationProgressMarkNotification";

#define	GSI_ARRAY_NO_RETAIN
#define	GSI_ARRAY_NO_RELEASE
#define	GSIArrayItem NSAnimationProgress

#include <math.h>
#include <GNUstepBase/GSIArray.h>

// 'reasonable value' ?
#define GS_ANIMATION_DEFAULT_FRAME_RATE 25.0

_NSAnimationCurveDesc __gs_animationCurveDesc[] =
{
  // easeInOut : endGrad = startGrad & startGrad <= 1/3
  { 0.0,1.0,  1.0/3,1.0/3 ,  {{2.0,2.0/3,2.0/3,2.0}} },
  // easeIn    : endGrad = 1/startGrad & startGrad >= 1/6
  { 0.0,1.0,  0.25,4.0 ,  {{4.0,3.0,2.0,1.0}} },
  // easeOut   : endGrad = 1/startGrad & startGrad <= 6
  { 0.0,1.0,  4.0 ,0.25,  {{1.0,2.0,3.0,4.0}} },
  // linear (not used)
  { 0.0,1.0,  1.0 ,1.0 ,  {{1.0,1.0,1.0,1.0}} },
  // speedInOut: endGrad = startGrad & startGrad >=3
  { 0.0,1.0,  3.0 ,3.0 ,  {{2.0/3,2.0,2.0,2.0/3}} }
};

_NSAnimationCurveDesc *_gs_animationCurveDesc
  = __gs_animationCurveDesc;

@interface NSAnimation(PrivateNotificationCallbacks)
- (void) _gs_startAnimationReachesProgressMark: (NSNotification*)notification;
- (void) _gs_stopAnimationReachesProgressMark: (NSNotification*)notification;
@end

@interface NSAnimation(Private)
- (void) _gs_didReachProgressMark: (NSAnimationProgress)progress;
- (_NSAnimationCurveDesc*) _gs_curveDesc;
- (NSAnimationProgress) _gs_curveShift;
@end

static INLINE NSComparisonResult
nsanimation_progressMarkSorter( NSAnimationProgress first,NSAnimationProgress second)
{
  float diff = first - second;
  return (NSComparisonResult) (diff / fabs(diff));
}

@implementation NSAnimation

+ (void) initialize
{
  unsigned i;
  for(i=0;i<5;i++) // compute Bezier curve parameters...
    _gs_animationValueForCurve(&_gs_animationCurveDesc[i],0.0,0.0);
}

- (void) addProgressMark: (NSAnimationProgress)progress
{
  if(progress < 0.0) progress = 0.0;
  if(progress > 1.0) progress = 1.0;

  if(GSIArrayCount(_progressMarks) == 0)
  { // First mark
    GSIArrayAddItem(_progressMarks,progress);
    NSDebugFLLog(@"NSAnimationMark",@"%@ Insert 1st mark for %f (next:#%d)",self,progress,_nextMark);
    _nextMark = (progress >= [self currentProgress])? 0 : 1;
  }
  else 
  {
    unsigned index;
    index = GSIArrayInsertionPosition(_progressMarks,progress,&nsanimation_progressMarkSorter);
    if(_nextMark < GSIArrayCount(_progressMarks)) 
      if(index <= _nextMark && progress < GSIArrayItemAtIndex(_progressMarks,_nextMark))
       	_nextMark++;
    GSIArrayInsertItem(_progressMarks,progress,index);
    NSDebugFLLog(@"NSAnimationMark",@"%@ Insert mark #%d/%d for %f (next:#%d)",self,index,GSIArrayCount(_progressMarks),progress,_nextMark);
  }
  _isCachedProgressMarkNumbersValid = NO;
}

- (NSAnimationBlockingMode) animationBlockingMode
{
  return _blockingMode;
}

- (NSAnimationCurve) animationCurve
{
  return _curve;
}

- (void) clearStartAnimation
{
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSAnimationProgressMarkNotification
	    object: _startAnimation];
  _startAnimation = nil;
}

- (void) clearStopAnimation
{
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSAnimationProgressMarkNotification
	    object: _stopAnimation];
  _stopAnimation = nil;
}

- (NSAnimationProgress) currentProgress
{
  return _currentProgress;
}

- (float) currentValue
{
  float value;
  id delegate;
  delegate = GS_GC_UNHIDE(_delegate);

  if(_delegate_animationValueForProgress) // method is cached (the animation is running)
  {
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationValueForProgress] (cached)",self);
    value = (*_delegate_animationValueForProgress)(delegate,@selector(animation:valueForProgress:),self,_currentProgress);
  }
  else // method is not cached (the animation did not start yet)
    if( _delegate != nil
      && [delegate respondsToSelector: @selector(animation:valueForProgress:)] )
    {
      NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationValueForProgress]",self);
      value = [GS_GC_UNHIDE(_delegate) animation: self valueForProgress: _currentProgress];
    }
  else // default -- FIXME
/*    switch(_curve)
    {
      case NSAnimationEaseInOut:
      case NSAnimationEaseIn:
      case NSAnimationEaseOut:
      case NSAnimationSpeedInOut:*/
	value = _gs_animationValueForCurve( &_curveDesc,_currentProgress,_curveProgressShift );
/*	break;
      case NSAnimationLinear:
	value = _currentProgress; break;
    }*/
  return value;
}

- (id) delegate
{
  return (_delegate == nil)? nil : GS_GC_UNHIDE(_delegate);
}

- (NSTimeInterval) duration
{
  return _duration;
}

- (float) frameRate
{
  return _frameRate;
}

- (id) initWithDuration: (NSTimeInterval)duration
	 animationCurve: (NSAnimationCurve)curve
{
  if ((self = [super init]))
  {
    _duration = duration;
    _frameRate = GS_ANIMATION_DEFAULT_FRAME_RATE;
    _curve = curve;
    _curveDesc = _gs_animationCurveDesc[_curve];
    _curveProgressShift = 0.0;

    _currentProgress = 0.0;
    _progressMarks = NSZoneMalloc([self zone], sizeof(GSIArray_t));
    GSIArrayInitWithZoneAndCapacity(_progressMarks, [self zone], 16);
    _cachedProgressMarkNumbers = NULL;
    _cachedProgressMarkNumberCount = 0;
    _isCachedProgressMarkNumbersValid = NO;
    _nextMark = 0;

    _startAnimation = _stopAnimation = nil;
    _startMark = _stopMark = 0.0;
    
    _blockingMode = NSAnimationBlocking;
    _animator = nil;
    _isANewAnimatorNeeded = YES;

    _delegate = nil;
    _delegate_animationDidReachProgressMark =
      (void (*)(id,SEL,NSAnimation*,NSAnimationProgress)) NULL;
    _delegate_animationValueForProgress =
      (float (*)(id,SEL,NSAnimation*,NSAnimationProgress)) NULL;
    _delegate_animationDidEnd =
      (void (*)(id,SEL,NSAnimation*)) NULL;
    _delegate_animationDidStop =
      (void (*)(id,SEL,NSAnimation*)) NULL;
    _delegate_animationShouldStart =
      (BOOL (*)(id,SEL,NSAnimation*)) NULL;
  }
  return self;
}

- (id) copyWithZone: (NSZone*)zone
{
  return [self notImplemented: _cmd];
}

- (void) dealloc
{
  GSIArrayEmpty(_progressMarks);
  NSZoneFree([self zone], _progressMarks);
  if(_cachedProgressMarkNumbers != NULL)
  {
    unsigned i;
    for( i=0; i<_cachedProgressMarkNumberCount; i++)
      RELEASE(_cachedProgressMarkNumbers[i]);
    NSZoneFree([self zone], _cachedProgressMarkNumbers);
  }

  if( _startAnimation != nil || _stopAnimation != nil)
    [[NSNotificationCenter defaultCenter] removeObserver:self];

  TEST_RELEASE(_animator);

  [super dealloc];
}

- (BOOL) isAnimating
{
  return (_animator != nil)? [_animator isAnimationRunning] : NO;
}

- (NSArray*) progressMarks
{
  unsigned count = GSIArrayCount(_progressMarks);

  if(!_isCachedProgressMarkNumbersValid)
  {
    unsigned i;

    if(_cachedProgressMarkNumbers != NULL)
    {   
      for( i=0; i<_cachedProgressMarkNumberCount; i++)
	RELEASE(_cachedProgressMarkNumbers[i]);
      _cachedProgressMarkNumbers =
	(NSNumber**)NSZoneRealloc([self zone], _cachedProgressMarkNumbers,count*sizeof(NSNumber*));
    }
    else
    {
      _cachedProgressMarkNumbers =
        (NSNumber**)NSZoneMalloc([self zone], count*sizeof(NSNumber*));
    }
    for( i=0; i<count; i++)
    {
      _cachedProgressMarkNumbers[i] =
	[NSNumber numberWithFloat: GSIArrayItemAtIndex(_progressMarks,i)];
    }
    _cachedProgressMarkNumberCount = count;
    _isCachedProgressMarkNumbersValid = YES;
  }
  return [NSArray arrayWithObjects: _cachedProgressMarkNumbers
			     count: count];
}

- (void) removeProgressMark: (NSAnimationProgress)progress
{
  unsigned index = GSIArraySearch(_progressMarks,progress,nsanimation_progressMarkSorter);
  if( index < GSIArrayCount(_progressMarks)
      && progress == GSIArrayItemAtIndex(_progressMarks,index) )
  {
    GSIArrayRemoveItemAtIndex(_progressMarks,index);
    _isCachedProgressMarkNumbersValid = NO;
    if(_nextMark > index) _nextMark--;
    NSDebugFLLog(@"NSAnimationMark",@"%@ Remove mark #%d for (next:#%d)",self,index,progress,_nextMark);
  }
  else
    NSWarnFLog(@"%@ Unexistent progress mark",self);
}

- (NSArray*) runLoopModesForAnimating
{
  return nil;
}

- (void) setAnimationBlockingMode: (NSAnimationBlockingMode)mode
{
  _isANewAnimatorNeeded |= (_blockingMode != mode);
  _blockingMode = mode;
}

- (void) setAnimationCurve: (NSAnimationCurve)curve
{
  if(_currentProgress <= 0.0f || _currentProgress >= 1.0f)
  {
    _curveDesc = _gs_animationCurveDesc[curve];
  }
  else
  { // FIXME ??
    _GSRationalBezierDesc newrb;

    _GSRationalBezierDesc *rb1 = &(_curveDesc.rb);
    float t1 = (_currentProgress - _curveProgressShift) / (1.0 - _curveProgressShift);
    _GSRationalBezierDesc *rb2 = &(_gs_animationCurveDesc[curve].rb);
    float t2 = _currentProgress;
    float K;
    newrb.p[0] = _GSRationalBezierEval( rb1,   t1        );
    newrb.w[0] = _GSBezierEval        (&rb1->d,t1        );
    newrb.w[1] = 
      rb1->w[1]
      + t1*( 2*( rb1->w[2]           - rb1->w[1] )
	    + t1*(rb1->w[1]           - 2*rb1->w[2]           + rb1->w[3]           ));
    newrb.p[1] = (
      rb1->w[1]*rb1->p[1]
      + t1*( 2*( rb1->w[2]*rb1->p[2] - rb1->w[1]*rb1->p[1] )
  	    + t1*(rb1->w[1]*rb1->p[1] - 2*rb1->w[2]*rb1->p[2] + rb1->w[3]*rb1->p[3] ))
      ) / newrb.w[1];
    newrb.w[2] = rb2->w[2]           + t2*(rb2->w[3]           - rb2->w[2]          );
    newrb.p[2] = (
	         rb2->w[2]*rb2->p[2] + t2*(rb2->w[3]*rb2->p[3] - rb2->w[2]*rb2->p[2])
	) / newrb.w[2];

    // 3rd point is moved to the right by scaling : w3*p3 = w1*p1 + (w1*p1 - w0*p0) 
    K = ( 2*newrb.w[1]*newrb.p[1]-newrb.w[0]*newrb.p[0] ) / (newrb.w[2]*newrb.p[2]);
    newrb.p[3] = rb2->p[3];
    newrb.w[3] = rb2->w[3] * K;
    newrb.w[2] = newrb.w[2]* K;

    _GSRationalBezierComputeBezierDesc(&newrb);
#if 0
    NSLog(@"prgrss = %f shift = %f",_currentProgress,_curveProgressShift);
    switch(curve)
    { case 0:NSLog(@"EaseInOut t=%f - %f",t1,t2);break;
      case 1:NSLog(@"EaseIn    t=%f - %f",t1,t2);break;
      case 2:NSLog(@"EaseOut   t=%f - %f",t1,t2);break;
      case 3:NSLog(@"Linear    t=%f - %f",t1,t2);break;
      default:NSLog(@"???");
    }
    NSLog(@"a=%f b=%f c=%f d=%f",newrb.p[0],newrb.p[1],newrb.p[2],newrb.p[3]);
    NSLog(@"  %f   %f   %f   %f",newrb.w[0],newrb.w[1],newrb.w[2],newrb.w[3]);
#endif
    _curveProgressShift = _currentProgress;
    _curveDesc.rb = newrb;
    _curveDesc.isRBezierComputed = YES;
  }
  _curve = curve;
}

- (void) setCurrentProgress: (NSAnimationProgress)progress
{
  BOOL needSearchNextMark = NO;
  NSAnimationProgress markedProgress;

  if(progress < 0.0) progress = 0.0;
  if(progress > 1.0) progress = 1.0;

  // NOTE: In the case of a forward jump the marks between the
  //       previous progress value and the new (excluded) progress 
  //       value are never reached.
  //       In the case of a backward jump (rewind) the marks will 
  //       be reached again !
  if(_nextMark < GSIArrayCount(_progressMarks))
  {
    markedProgress = GSIArrayItemAtIndex(_progressMarks,_nextMark);
    if(markedProgress == progress)
      [self _gs_didReachProgressMark: markedProgress];
    else
    {
      // the following should never happens if the progress
      // is reached during the normal run of the animation
      // (method called from animatorStep)
      if(markedProgress < progress) // forward jump ?
	needSearchNextMark = YES;
    }
  }
  needSearchNextMark |= progress < _currentProgress; // rewind ?

  if(needSearchNextMark)
  {
    _nextMark = GSIArrayInsertionPosition(_progressMarks,progress,&nsanimation_progressMarkSorter);

    if(_nextMark < GSIArrayCount(_progressMarks))
      NSDebugFLLog(@"NSAnimationMark",@"%@ Next mark #%d for %f",
	  self,_nextMark, GSIArrayItemAtIndex(_progressMarks,_nextMark));
  }

  NSDebugFLLog(@"NSAnimation",@"%@ Progress = %f",self,progress);
  _currentProgress = progress;

  if(progress >= 1.0 && _animator != nil)
    [_animator stopAnimation];
}

- (void) setDelegate: (id)delegate
{
  _delegate = (delegate == nil)? nil : GS_GC_HIDE(delegate);
}

- (void) setDuration: (NSTimeInterval)duration
{
  _duration = duration;
}

- (void) setFrameRate: (float)fps
{
  if(fps<0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"%@ Framerate must be >= 0.0 (passed: %f)",self,fps];
  _isANewAnimatorNeeded |= (_frameRate != fps);
  _frameRate = fps;
}

- (void) setProgressMarks: (NSArray*)marks
{
  GSIArrayEmpty(_progressMarks);
  if(marks != nil)
  {
    unsigned i, count=[marks count];
    for(i=0;i<count;i++)
      [self addProgressMark:[(NSNumber*)[marks objectAtIndex:i] floatValue]];
  }
  _isCachedProgressMarkNumbersValid = NO;
}

- (void) startAnimation
{
  if([self isAnimating])
    return;

  NSDebugFLLog(@"NSAnimationStart",@"%@",self);

  unsigned i;
  for(i=0;i<GSIArrayCount(_progressMarks);i++)
    NSDebugFLLog(@"NSAnimationMark",@"%@ Mark #%d : %f",self,i,GSIArrayItemAtIndex(_progressMarks,i));

  if([self currentProgress] >= 1.0) 
  {
    [self setCurrentProgress: 0.0];
    _nextMark = 0;
  }

  _curveDesc = _gs_animationCurveDesc[_curve];
  _curveProgressShift = 0.0;

  if(_delegate != nil)
  {
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ Cache delegation methods",self);
    // delegation methods are cached while the animation is running
    id delegate;
    delegate = GS_GC_UNHIDE(_delegate);
    _delegate_animationDidReachProgressMark =
      ([delegate respondsToSelector: @selector(animation:didReachProgressMark:)]) ?
      (void (*)(id,SEL,NSAnimation*,NSAnimationProgress))
      [delegate methodForSelector: @selector(animation:didReachProgressMark:)]
      : NULL;
    _delegate_animationValueForProgress =
      ([delegate respondsToSelector: @selector(animation:valueForProgress:)]) ?
      (float (*)(id,SEL,NSAnimation*,NSAnimationProgress))
      [delegate methodForSelector: @selector(animation:valueForProgress:)]
      : NULL;
    _delegate_animationDidEnd =
      ([delegate respondsToSelector: @selector(animationDidEnd:)]) ?
      (void (*)(id,SEL,NSAnimation*))
      [delegate methodForSelector: @selector(animationDidEnd:)]
      : NULL;
    _delegate_animationDidStop =
      ([delegate respondsToSelector: @selector(animationDidStop:)]) ?
      (void (*)(id,SEL,NSAnimation*))
      [delegate methodForSelector: @selector(animationDidStop:)]
      : NULL;
    _delegate_animationShouldStart =
      ([delegate respondsToSelector: @selector(animationShouldStart:)]) ?
      (BOOL (*)(id,SEL,NSAnimation*))
      [delegate methodForSelector: @selector(animationShouldStart:)]
      : NULL;
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ Delegation methods : %x %x %x %x %x", self,
	_delegate_animationDidReachProgressMark,
	_delegate_animationValueForProgress,
        _delegate_animationDidEnd,
	_delegate_animationDidStop,
	_delegate_animationShouldStart);
  }
  else
  {
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ No delegate : clear delegation methods",self);
    _delegate_animationDidReachProgressMark =
      (void (*)(id,SEL,NSAnimation*,NSAnimationProgress)) NULL;
    _delegate_animationValueForProgress =
      (float (*)(id,SEL,NSAnimation*,NSAnimationProgress)) NULL;
    _delegate_animationDidEnd =
      (void (*)(id,SEL,NSAnimation*)) NULL;
    _delegate_animationDidStop =
      (void (*)(id,SEL,NSAnimation*)) NULL;
    _delegate_animationShouldStart =
      (BOOL (*)(id,SEL,NSAnimation*)) NULL;
  }
  
  if(_animator==nil || _isANewAnimatorNeeded)
  {
    TEST_RELEASE(_animator);
    _animator = [GSAnimator
      animatorWithAnimation: self
		       mode: _blockingMode 
		  frameRate: _frameRate
		       zone: [self zone]];
    NSAssert(_animator,@"Can not create a GSAnimator");
    RETAIN(_animator);
    NSDebugFLLog(@"NSAnimationAnimator",@"%@ New GSAnimator: %@", self,[_animator class]);
  }

  NSDebugFLLog(@"NSAnimationAnimator",@"%@ Start animator %@...",self,_animator);
  [_animator startAnimation];
}

- (void) startWhenAnimation: (NSAnimation*)animation
	    reachesProgress: (NSAnimationProgress)start
{
  _startAnimation = animation;
  _startMark = start;

  [_startAnimation addProgressMark: _startMark];
  NSDebugFLLog(@"NSAnimationMark",@"%@ register for progress %f",self,start);
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(_gs_startAnimationReachesProgressMark:)
	   name: NSAnimationProgressMarkNotification
	 object: _startAnimation];
}

- (void) stopAnimation
{
  if([self isAnimating])
    [_animator stopAnimation];
}

- (void) stopWhenAnimation: (NSAnimation*)animation
	   reachesProgress: (NSAnimationProgress)stop
{
  _stopAnimation = animation;
  _stopMark = stop;

  [_stopAnimation addProgressMark: _stopMark];
  NSDebugFLLog(@"NSAnimationMark",@"%@ register for progress %f",self,stop);
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(_gs_stopAnimationReachesProgressMark:)
	   name: NSAnimationProgressMarkNotification
	 object: _stopAnimation];
}

- (void) encodeWithCoder: (NSCoder*)coder
{
  [self notImplemented: _cmd];
}

- (id) initWithCoder: (NSCoder*)coder
{
  return [self notImplemented: _cmd];
}

/*
 * protocol GSAnimation (callbacks)
 */

- (void) animatorDidStart
{
  NSDebugFLLog(@"NSAnimationAnimator",@"%@",self);
  id delegate;
  delegate = GS_GC_UNHIDE(_delegate);

  if(_delegate_animationShouldStart) // method is cached (the animation is running)
  {
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationShouldStart] (cached)",self);
    _delegate_animationShouldStart(delegate,@selector(animationShouldStart:),self);
  }
  RETAIN(self);
}

- (void) animatorDidStop
{
  NSDebugFLLog(@"NSAnimationAnimator",@"%@ Progress = %f",self,_currentProgress);
  id delegate;
  delegate = GS_GC_UNHIDE(_delegate);
  if(_currentProgress < 1.0)
  {
    if(_delegate_animationDidStop) // method is cached (the animation is running)
    {
      NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationDidStop] (cached)",self);
      _delegate_animationDidStop(delegate,@selector(animationDidStop:),self);
    }
  }
  else
  {
    if(_delegate_animationDidEnd) // method is cached (the animation is running)
    {
      NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationDidEnd] (cached)",self);
      _delegate_animationDidEnd(delegate,@selector(animationDidEnd:),self);
    }
  }
  RELEASE(self);
}

- (void) animatorStep: (NSTimeInterval) elapsedTime;
{
  NSDebugFLLog(@"NSAnimationAnimator",@"%@ Elapsed time : %f",self,elapsedTime);
  NSAnimationProgress progress = (elapsedTime / _duration);

  { // have some marks been passed ?
    // NOTE: the case where progress == markedProgress is
    //       treated in [-setCurrentProgress]
    unsigned count = GSIArrayCount(_progressMarks);
    NSAnimationProgress markedProgress;
    while(
      _nextMark < count
      && progress > (markedProgress = GSIArrayItemAtIndex(_progressMarks,_nextMark)) ) // is a mark reached ?
    {
      [self _gs_didReachProgressMark: markedProgress];
    }
  }

  [self setCurrentProgress: progress];
}

@end //implementation NSAnimation

@implementation NSAnimation(PrivateNotificationCallbacks)

- (void) _gs_startAnimationReachesProgressMark: (NSNotification*)notification
{
  NSDebugFLLog(@"NSAnimationMark",@"%@",self);
  NSAnimation *animation = [notification object];
  if( animation == _startAnimation && [_startAnimation currentProgress] >= _startMark)
  {
//    [self clearStartAnimation];
    [self startAnimation];
  }
}

- (void) _gs_stopAnimationReachesProgressMark: (NSNotification*)notification
{
  NSDebugFLLog(@"NSAnimationMark",@"%@",self);
  NSAnimation *animation = [notification object];
  if( animation == _stopAnimation && [_stopAnimation currentProgress] >= _stopMark)
  {
//    [self clearStopAnimation];
    [self stopAnimation];
  }
}

@end // implementation NSAnimation(PrivateNotificationCallbacks)

@implementation NSAnimation(Private)

- (void) _gs_didReachProgressMark: (NSAnimationProgress) progress
{
  NSDebugFLLog(@"NSAnimationMark",@"%@ progress %f",self, progress);
  // calls delegate's method
  if(_delegate_animationDidReachProgressMark) // method is cached (the animation is running)
  {
    NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationdidReachProgressMark] (cached)",self);
    _delegate_animationDidReachProgressMark(GS_GC_UNHIDE(_delegate),@selector(animation:didReachProgressMark:),self,progress);
  }
  else // method is not cached (the animation did not start yet)
    if( _delegate != nil
      && [GS_GC_UNHIDE(_delegate) respondsToSelector: @selector(animation:didReachProgressMark:)] )
    {
      NSDebugFLLog(@"NSAnimationDelegate",@"%@ [delegate animationdidReachProgressMark]",self);
      [GS_GC_UNHIDE(_delegate) animation: self didReachProgressMark: progress];
    }

  // posts a notification
  NSDebugFLLog(@"NSAnimationNotification",@"%@ Post NSAnimationProgressMarkNotification : %f",self,progress);
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSAnimationProgressMarkNotification
		  object: self
		userInfo: [NSDictionary 
                            dictionaryWithObject: [NSNumber numberWithFloat: progress]
					  forKey: @"NSAnimationProgressMark"
			  ]
  ];

  // skips marks with the same progress value
  while(
    (++_nextMark) < GSIArrayCount(_progressMarks)
    && GSIArrayItemAtIndex(_progressMarks,_nextMark) == progress)
  ;
  NSDebugFLLog(@"NSAnimationMark",@"%@ Next mark #%d for %f",self,_nextMark,GSIArrayItemAtIndex(_progressMarks,_nextMark));

}

- (_NSAnimationCurveDesc*) _gs_curveDesc
{ return &self->_curveDesc; }

- (NSAnimationProgress) _gs_curveShift
{ return _curveProgressShift; }

@end // implementation NSAnimation(Private)

@implementation NSAnimation(GNUstep)

- (unsigned int) frameCount
{ return (_animator != nil)? [_animator frameCount] : 0; }

- (void) resetCounters
{ if(_animator != nil) [_animator resetCounters]; }

- (float) actualFrameRate;
{ return (_animator != nil)? [_animator frameRate] : 0.0; }

@end

/*
 * NSViewAnimation class
 */

NSString *NSViewAnimationTargetKey     = @"NSViewAnimationTargetKey";
NSString *NSViewAnimationStartFrameKey = @"NSViewAnimationStartFrameKey";
NSString *NSViewAnimationEndFrameKey   = @"NSViewAnimationEndFrameKey";
NSString *NSViewAnimationEffectKey     = @"NSViewAnimationEffectKey";

NSString *NSViewAnimationFadeInEffect  = @"NSViewAnimationFadeInEffect";
NSString *NSViewAnimationFadeOutEffect = @"NSViewAnimationFadeOutEffect";

@interface _GSViewAnimationBaseDesc : NSObject
{
  id _target;
  NSRect _startFrame;
  NSRect _endFrame;
  NSString* _effect;
}

- (id) initWithProperties: (NSDictionary*)properties;
- (void) setCurrentProgress: (float)progress;
- (void) setTargetFrame: (NSRect) frame;

@end

@interface _GSViewAnimationDesc : _GSViewAnimationBaseDesc
{
  BOOL _shouldHide;
  BOOL _shouldUnhide;
}
@end

@interface _GSWindowAnimationDesc : _GSViewAnimationBaseDesc
{
  float _startAlpha;
}
@end

@implementation _GSViewAnimationBaseDesc

- (id) initWithProperties: (NSDictionary*)properties
{
  if([self isMemberOfClass: [_GSViewAnimationBaseDesc class]])
  {
    NSZone* zone;
    id target;
    zone = [self zone];
    RELEASE(self);
    target = [properties objectForKey: NSViewAnimationTargetKey];
    if(target!=nil)
    {
      if([target isKindOfClass: [NSView class]])
        self = [[_GSViewAnimationDesc allocWithZone: zone]
		  initWithProperties : properties];
      else if([target isKindOfClass: [NSWindow class]])
        self = [(_GSWindowAnimationDesc*)[_GSWindowAnimationDesc allocWithZone: zone]
		  initWithProperties : properties];
      else
	[NSException
	   raise: NSInvalidArgumentException
          format: @"Invalid viewAnimation property :"
                  @"target is neither a NSView nor a NSWindow"];
    }
    else
      [NSException
         raise: NSInvalidArgumentException
        format: @"Invalid viewAnimation property :"
                @"target is nil"];
  }
  else
  { // called from a subclass
    if((self = [super init]))
    {
      NSValue* startValue;
      NSValue*   endValue;
      _target    = [properties objectForKey: NSViewAnimationTargetKey];
      startValue = [properties objectForKey: NSViewAnimationStartFrameKey];
      endValue   = [properties objectForKey: NSViewAnimationEndFrameKey];
      _effect    = [properties objectForKey: NSViewAnimationEffectKey];

      _startFrame = (startValue!=nil) ?
	[startValue rectValue]
	: [_target frame];
      _endFrame = (endValue!=nil) ?
	[endValue rectValue]
	: [_target frame];
    }
  }
  return self;
}

- (void) setCurrentProgress: (float) progress
{
  if(progress < 1.0f)
  {
    NSRect r;
    r.origin.x    = _startFrame.origin.x
      + progress*( _endFrame.origin.x - _startFrame.origin.x );
    r.origin.y    = _startFrame.origin.y
      + progress*( _endFrame.origin.y - _startFrame.origin.y );
    r.size.width  = _startFrame.size.width
      + progress*( _endFrame.size.width - _startFrame.size.width );
    r.size.height = _startFrame.size.height
      + progress*( _endFrame.size.height - _startFrame.size.height );

    [self setTargetFrame:r];

    if(_effect == NSViewAnimationFadeOutEffect)
      /* subclassResponsibility */;
    if(_effect == NSViewAnimationFadeInEffect)
      /* subclassResponsibility */;
 }
  else
  {
    [self setTargetFrame: _endFrame];
  }
}

- (void) setTargetFrame: (NSRect) frame;
{ [self subclassResponsibility: _cmd]; }

@end // implementation _GSViewAnimationDesc

@implementation _GSViewAnimationDesc

- (id) initWithProperties: (NSDictionary*)properties
{
  if((self = [super initWithProperties: properties]))
  {
    _shouldHide = ([properties objectForKey: NSViewAnimationEndFrameKey] == nil);
    _shouldUnhide = ( _effect == NSViewAnimationFadeInEffect
	           && [_target isHidden]
		   && !_shouldHide);
  }
  return self;
}

- (void) setCurrentProgress: (float) progress
{
  [super setCurrentProgress: progress];
  if(_effect == NSViewAnimationFadeOutEffect)
    /* ??? TODO */;
  if(_effect == NSViewAnimationFadeInEffect)
    /* ??? TODO */;

  if(progress>=1.0f)
  {
    if(_shouldHide)
      [_target setHidden:YES];
    else if(_shouldUnhide)
      [_target setHidden:NO];
  }
}

- (void) setTargetFrame: (NSRect) frame;
{ [_target setFrame:frame]; }

@end // implementation _GSViewAnimationDesc

@implementation _GSWindowAnimationDesc

- (id) initWithProperties: (NSDictionary*)properties
{
  if((self = [super initWithProperties: properties]))
  {
    _startAlpha = [_target alphaValue];
  }
  return self;
}

- (void) setCurrentProgress: (float) progress
{
  [super setCurrentProgress: progress];
  if(_effect == NSViewAnimationFadeOutEffect)
    [_target setAlphaValue: _startAlpha*(1.0f-progress)];
  if(_effect == NSViewAnimationFadeInEffect)
    [_target setAlphaValue: _startAlpha+(1.0f-_startAlpha)*progress];

  if(progress>=1.0f)
  {
    if(_effect == NSViewAnimationFadeOutEffect)
      [_target orderBack: self];
    if(_effect == NSViewAnimationFadeInEffect)
      [_target orderFront: self];
  }
}

- (void) setTargetFrame: (NSRect) frame;
{ [_target setFrame:frame display:YES]; }

@end // implementation _GSWindowAnimationDesc

@implementation NSViewAnimation

- (id) initWithViewAnimations: (NSArray*)animations
{
  self = [self initWithDuration: 0.5 animationCurve: NSAnimationEaseInOut];
  if (self)
  {
    [self setAnimationBlockingMode: NSAnimationNonblocking];
    _viewAnimations = [animations retain];
    _viewAnimationDesc = nil;
  }
  return self;
}

- (void) dealloc
{
  RELEASE(_viewAnimations);
  RELEASE(_viewAnimationDesc);
  [super dealloc];
}

- (void) setViewAnimations: (NSArray*)animations
{
  if(_viewAnimations != animations)
    DESTROY(_viewAnimationDesc);
  ASSIGN(_viewAnimations, animations) ;
}

- (NSArray*) viewAnimations
{
  return _viewAnimations;
}

- (void) startAnimation
{
  if(_viewAnimationDesc == nil)
  {
    unsigned i,c;
    c = [_viewAnimations count];
    _viewAnimationDesc = [NSMutableArray arrayWithCapacity: c];
    RETAIN(_viewAnimationDesc);
    for(i=0;i<c;i++)
      [_viewAnimationDesc
	addObject: [[_GSViewAnimationBaseDesc alloc]
                      initWithProperties: [_viewAnimations objectAtIndex:i]]
      ];
  }
  [super startAnimation];
}

- (void) stopAnimation
{
  [super stopAnimation];
  [self setCurrentProgress: 1.0];
}

- (void) setCurrentProgress: (NSAnimationProgress)progress
{
  unsigned i,c;
  float v;
  [super setCurrentProgress: progress];
  v = [self currentValue];
  if(_viewAnimationDesc != nil)
    for(i=0, c=[_viewAnimationDesc count];i<c;i++)
      [[_viewAnimationDesc objectAtIndex: i] setCurrentProgress: v];
}

@end // implementation NSViewAnimation

