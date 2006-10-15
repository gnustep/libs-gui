/** <title>NSProgressIndicator</title>

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSTimer.h>
#include "AppKit/NSProgressIndicator.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSTheme.h"
#include "GNUstepGUI/GSNibCompatibility.h"

@implementation NSProgressIndicator

static NSColor *fillColour = nil;
#define maxCount 1
//static NSImage *images[maxCount];

+ (void) initialize
{
  if (self == [NSProgressIndicator class])
    {
      [self setVersion: 1];
      // FIXME: Should come from defaults and should be reset when defaults change
      // FIXME: Should probably get the color from the color extension list (see NSToolbar)
      fillColour = RETAIN([NSColor controlShadowColor]);
      // FIXME: Load the images and set maxCount
    }
}
 
- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  _isIndeterminate = YES;
  _isBezeled = YES;
  _isVertical = NO;
  _usesThreadedAnimation = NO;
  _animationDelay = 5.0 / 60.0;	// 1 twelfth a a second
  _doubleValue = 0.0;
  _minValue = 0.0;
  _maxValue = 100.0;
  return self;
}

- (void)dealloc
{
  TEST_RELEASE(_timer);
  [super dealloc];
}

- (void)animate:(id)sender
{
  if (!_isIndeterminate)
    return;

  _count++;
  if (_count == maxCount)
    _count = 0;

  [self setNeedsDisplay:YES];
}

- (NSTimeInterval)animationDelay { return _animationDelay; }
- (void)setAnimationDelay:(NSTimeInterval)delay
{
  _animationDelay = delay;
}

- (void)startAnimation:(id)sender
{
  if (!_isIndeterminate)
    return;

  if (!_usesThreadedAnimation)
    {
      ASSIGN(_timer, [NSTimer scheduledTimerWithTimeInterval: _animationDelay 
			      target: self 
			      selector: @selector(animate:)
			      userInfo: nil
			      repeats: YES]);
    }
  else
    {
      // Not implemented
    }

  _isRunning = YES;
}

- (void)stopAnimation:(id)sender
{
  if (!_isIndeterminate || !_isRunning)
    return;

  if (!_usesThreadedAnimation)
    {
      [_timer invalidate];
      DESTROY(_timer);
    }
  else
    {
      // Not implemented
    }

  _isRunning = NO;
}

- (BOOL)usesThreadedAnimation
{
  return _usesThreadedAnimation;
}

- (void)setUsesThreadedAnimation:(BOOL)flag
{
  if (_usesThreadedAnimation != flag)
    {
      BOOL wasRunning = _isRunning;

      if (wasRunning)
	[self stopAnimation: self];

      _usesThreadedAnimation = flag;

      if (wasRunning)
	[self startAnimation: self];
    }
}

- (void)incrementBy:(double)delta
{
  _doubleValue += delta;
  [self setNeedsDisplay:YES];
}

- (double)doubleValue { return _doubleValue; }
- (void)setDoubleValue:(double)aValue
{
  if (_doubleValue != aValue)
    {
      _doubleValue = aValue;
      [self setNeedsDisplay:YES];
    }
}

- (double)minValue { return _minValue; }
- (void)setMinValue:(double)newMinimum
{
  if (_minValue != newMinimum)
    {
      _minValue = newMinimum;
      [self setNeedsDisplay:YES];
    }
}

- (double)maxValue { return _maxValue; }
- (void)setMaxValue:(double)newMaximum
{
  if (_maxValue != newMaximum)
    {
      _maxValue = newMaximum;
      [self setNeedsDisplay:YES];
    }
}

- (BOOL)isBezeled { return _isBezeled; }
- (void)setBezeled:(BOOL)flag
{
  if (_isBezeled != flag)
    {
      _isBezeled = flag;
      [self setNeedsDisplay:YES];
    }
}

- (BOOL)isIndeterminate { return _isIndeterminate; }
- (void)setIndeterminate:(BOOL)flag
{
  _isIndeterminate = flag;
   // Maybe we need more functionality here when we implement indeterminate
  if (flag == NO && _isRunning)
    [self stopAnimation: self];
}

- (NSControlSize)controlSize
{
  // FIXME
  return NSRegularControlSize;
}

- (void)setControlSize:(NSControlSize)size
{
  // FIXME 
}

- (NSControlTint)controlTint
{
  // FIXME
  return NSDefaultControlTint;
}

- (void)setControlTint:(NSControlTint)tint
{
  // FIXME 
}

- (void)drawRect:(NSRect)rect
{
   NSRect	r;

   // Draw the Bezel
   if (_isBezeled)
     {
       // Calc the inside rect to be drawn
       r = [[GSTheme theme] drawGrayBezel: _bounds withClip: rect];
     }
   else
     r = _bounds;

   if (_isIndeterminate)		// Draw indeterminate
     {
       // FIXME: Do nothing at this stage
     }
   else				// Draw determinate 
     {
       if (_doubleValue > _minValue)
         {
	   double val;
	   
	   if (_doubleValue > _maxValue)
	     val = _maxValue - _minValue;
	   else 
	     val = _doubleValue - _minValue;

	   if (_isVertical)
	     r.size.height = NSHeight(r) * (val / (_maxValue - _minValue));
	   else
	     r.size.width = NSWidth(r) * (val / (_maxValue - _minValue));
	   r = NSIntersectionRect(r,rect);
	   if (!NSIsEmptyRect(r))
	     {
	       [fillColour set];
	       NSRectFill(r);
	     }
	 }
     }
}

// It does not seem that Gnustep has a copyWithZone: on NSView, it is private
// under openstep

// NSCopying
/* - (id)copyWithZone:(NSZone *)zone
{
   NSProgressIndicator	*newInd;

   newInd = [super copyWithZone:zone];
   [newInd setIndeterminate:_isIndeterminate];
   [newInd setBezeled:_isBezeled];
   [newInd setUsesThreadedAnimation:_usesThreadedAnimation];
   [newInd setAnimimationDelay:_animationDelay];
   [newInd setDoubleValue:_doubleValue];
   [newInd setMinValue:_minValue];
   [newInd setMaxValue:_maxValue];
   [newInd setVertical:_isVertical];
   return newInd;
}
*/

// NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
   [super encodeWithCoder:aCoder];
   if ([aCoder allowsKeyedCoding])
     {
       unsigned long flags = 0;
       id matrix = AUTORELEASE([[NSPSMatrix alloc] init]);

       [aCoder encodeDouble: _minValue forKey: @"NSMinValue"];
       [aCoder encodeDouble: _maxValue forKey: @"NSMaxValue"];
       [aCoder encodeObject: matrix forKey: @"NSDrawMatrix"];

       // add flag values.
       flags |= (_isIndeterminate)? 2 : 0;

       //
       // Hard coded... this value forces it to be a regular-sized, 
       // bar type progress indicator since this is the only type
       // gnustep supports. 
       //
       flags |= 8200; 
       [aCoder encodeInt: flags forKey: @"NSpiFlags"];

       // things which Gorm encodes, but IB doesn't care about.
       [aCoder encodeDouble: _doubleValue forKey: @"GSDoubleValue"];
       [aCoder encodeBool: _isBezeled forKey: @"GSIsBezeled"];
       [aCoder encodeBool: _isVertical forKey: @"GSIsVertical"];
       [aCoder encodeBool: _usesThreadedAnimation forKey: @"GSUsesThreadAnimation"];
       [aCoder encodeDouble: _animationDelay forKey: @"GSAnimationDelay"];
     }
   else
     {
       [aCoder encodeValueOfObjCType: @encode(BOOL) at:&_isIndeterminate];
       [aCoder encodeValueOfObjCType: @encode(BOOL) at:&_isBezeled];
       [aCoder encodeValueOfObjCType: @encode(BOOL) at:&_usesThreadedAnimation];
       [aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at:&_animationDelay];
       [aCoder encodeValueOfObjCType: @encode(double) at:&_doubleValue];
       [aCoder encodeValueOfObjCType: @encode(double) at:&_minValue];
       [aCoder encodeValueOfObjCType: @encode(double) at:&_maxValue];
       [aCoder encodeValueOfObjCType: @encode(BOOL) at:&_isVertical];
     }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if ([aDecoder allowsKeyedCoding])
    {
      // id matrix = [aDecoder decodeObjectForKey: @"NSDrawMatrix"];
      if ([aDecoder containsValueForKey: @"NSMaxValue"])
        {
	  int max = [aDecoder decodeDoubleForKey: @"NSMaxValue"];

	  [self setMaxValue: max];
	}
      if ([aDecoder containsValueForKey: @"NSMinValue"])
        {
	  int min = [aDecoder decodeDoubleForKey: @"NSMinValue"];

	  [self setMinValue: min];
	}
      if ([aDecoder containsValueForKey: @"NSpiFlags"])
        {
	  int flags = [aDecoder decodeIntForKey: @"NSpiFlags"];

	  _isIndeterminate = ((flags & 2) == 2);
	  // ignore the rest, since they are not pertinent to GNUstep.
	}

      // things which Gorm encodes, but IB doesn't care about.
      if ([aDecoder containsValueForKey: @"GSDoubleValue"])
	{
	  _doubleValue = [aDecoder decodeDoubleForKey: @"GSDoubleValue"];
	}
      if ([aDecoder containsValueForKey: @"GSIsBezeled"])
	{
	  _isBezeled = [aDecoder decodeBoolForKey: @"GSIsBezeled"];
	}
      if ([aDecoder containsValueForKey: @"GSIsVertical"])
	{
	  _isVertical = [aDecoder decodeBoolForKey: @"GSIsVertical"];
	}
      if ([aDecoder containsValueForKey: @"GSUsesThreadAnimation"])
	{
	  _usesThreadedAnimation = [aDecoder decodeBoolForKey: @"GSUsesThreadAnimation"];
	}      
      if ([aDecoder containsValueForKey: @"GSAnimationDelay"])
	{
	  _animationDelay = [aDecoder decodeDoubleForKey: @"GSAnimationDelay"];
	}
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isIndeterminate];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isBezeled];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_usesThreadedAnimation];
      [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval)
		                   at:&_animationDelay];
      [aDecoder decodeValueOfObjCType: @encode(double) at:&_doubleValue];
      [aDecoder decodeValueOfObjCType: @encode(double) at:&_minValue];
      [aDecoder decodeValueOfObjCType: @encode(double) at:&_maxValue];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isVertical];
    }
   return self;
}

@end

@implementation NSProgressIndicator (GNUstepExtensions)

- (BOOL)isVertical { return _isVertical; }
- (void)setVertical:(BOOL)flag
{
  if (_isVertical != flag)
    {
      _isVertical = flag;
      [self setNeedsDisplay:YES];
    }
}

@end

