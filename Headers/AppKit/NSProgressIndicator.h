/*
   NSProgressIndicator.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decimax.com>
   Date: 1999

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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSProgressIndicator
#define _GNUstep_H_NSProgressIndicator

#include <AppKit/NSView.h>

@class NSTimer;
@class NSThread;

/* For NSControlTint */
#include <AppKit/NSColor.h>

/* For NSControlSize */
#include <AppKit/NSCell.h>

#define NSProgressIndicatorPreferredThickness 14
#define NSProgressIndicatorPreferredSmallThickness 10
#define NSProgressIndicatorPreferredLargeThickness 18
#define NSProgressIndicatorPreferredAquaThickness 12

@interface NSProgressIndicator : NSView
{
  BOOL			_isIndeterminate;
  BOOL			_isBezeled;
  BOOL			_usesThreadedAnimation;
  NSTimeInterval	_animationDelay;
  double		_doubleValue;
  double		_minValue;
  double		_maxValue;
  BOOL			_isVertical;
@private
  BOOL                  _isRunning;
  int                   _count;  
  NSTimer              *_timer;
  NSThread             *_thread;
}

//
// Animating the progress indicator
//
- (void)animate:(id)sender;
- (NSTimeInterval)animationDelay;
- (void)setAnimationDelay:(NSTimeInterval)delay;
- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;
- (BOOL)usesThreadedAnimation;
- (void)setUsesThreadedAnimation:(BOOL)flag;

// 
// Advancing the progress bar
//
- (void)incrementBy:(double)delta;
- (double)doubleValue;
- (void)setDoubleValue:(double)aValue;
- (double)minValue;
- (void)setMinValue:(double)newMinimum;
- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

//
// Setting the appearance
//
- (BOOL)isBezeled;
- (void)setBezeled:(BOOL)flag;
- (BOOL)isIndeterminate;
- (void)setIndeterminate:(BOOL)flag;

//
// Standard control layout
//
- (NSControlSize)controlSize;
- (void)setControlSize:(NSControlSize)size;
- (NSControlTint)controlTint;
- (void)setControlTint:(NSControlTint)tint;

@end

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
@interface NSProgressIndicator (GNUstepExtensions)

/*
 * Enables Vertical ProgressBar
 *
 * If isVertical = YES, Progress is from the bottom to the top
 * If isVertical = NO, Progress is from the left to the right
 */
- (BOOL)isVertical;
- (void)setVertical:(BOOL)flag;

@end
#endif

#endif /* _GNUstep_H_NSProgressIndicator */
