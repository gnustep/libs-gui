/*
   NSProgressIndicator.m

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindow.h>
// #import <AppKit/NSDPSContext.h>

@interface NSProgressIndicator(PrivateMethods)
- (void)_update;
@end

@implementation NSProgressIndicator

- (id)initWithFrame:(NSRect)frameRect
{
   self = [super initWithFrame:frameRect];
   isIndeterminate = NO;	// This should be changed to YES, to conform
   isBezeled = YES;
   isVertical = NO;
   usesThreadedAnimation = NO;
   animationDelay = 5.0 / 60.0;	// 1 fifth a a second
   doubleValue = 0.0;
   minValue = 0.0;
   maxValue = 100.0;
   return self;
}

- (void)dealloc
{
   // Nothing to dealloc at this stage
   [super dealloc];
}

- (void)animate:(id)sender
{
   // Not implemented
}

- (NSTimeInterval)animationDelay { return animationDelay; }
- (void)setAnimimationDelay:(NSTimeInterval)delay
{
   animationDelay = delay;
}

- (void)startAnimation:(id)sender
{
   // Not implemented
}

- (void)stopAnimation:(id)sender
{
   // Not implemented
}

- (BOOL)usesThreadedAnimation
{
   return usesThreadedAnimation;
}

- (void)setUsesThreadedAnimation:(BOOL)flag
{
   usesThreadedAnimation = flag;
   // This method should be expanded to enable threading
}

- (void)incrementBy:(double)delta
{
   doubleValue += delta;
   [self setNeedsDisplay:YES];
   [self _update];
}

- (double)doubleValue { return doubleValue; }
- (void)setDoubleValue:(double)aValue
{
   if (doubleValue != aValue)
   {
      doubleValue = aValue;
      [self setNeedsDisplay:YES];
      [self _update];
   }
}

- (double)minValue { return minValue; }
- (void)setMinValue:(double)newMinimum
{
   if (minValue != newMinimum)
   {
      minValue = newMinimum;
      [self setNeedsDisplay:YES];
      [self _update];
   }
}

- (double)maxValue { return maxValue; }
- (void)setMaxValue:(double)newMaximum
{
   if (maxValue != newMaximum)
   {
      maxValue = newMaximum;
      [self setNeedsDisplay:YES];
      [self _update];
   }
}

- (BOOL)isBezeled { return isBezeled; }
- (void)setBezeled:(BOOL)flag
{
   if (isBezeled != flag)
   {
      isBezeled = flag;
      [self setNeedsDisplay:YES];
      [self _update];
   }
}

- (BOOL)isIndeterminate { return isIndeterminate; }
- (void)setIndeterminate:(BOOL)flag
{
   isIndeterminate = flag;
   isIndeterminate = NO;	// Just for now
   // Maybe we need more functionality here when we implement indeterminate
}

- (void)drawRect:(NSRect)rect
{
   NSRect	r;

   // Draw the Bezel
   if (isBezeled)
      NSDrawGrayBezel(bounds,rect);

   // Calc the inside rect to be drawn
   if (isBezeled)
   {
      r = NSMakeRect(NSMinX(bounds) + 2.0,
		     NSMinY(bounds) + 2.0,
		     NSWidth(bounds) - 4.0,
		     NSHeight(bounds) - 4.0);
   }
   else
      r = bounds;

   if (isIndeterminate)		// Draw indeterminate
   {
      // Do nothing at this stage
   }
   else				// Draw determinate 
   {
      if (doubleValue > minValue)
      {
	 if (isVertical)
	    r.size.height =
	       NSHeight(r) * (doubleValue / (maxValue - minValue));
	 else
	    r.size.width =
	       NSWidth(r) * (doubleValue / (maxValue - minValue));
	 r = NSIntersectionRect(r,rect);
	 if (!NSIsEmptyRect(r))
	 {
	    [[NSColor blueColor] set];
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
   [newInd setIndeterminate:isIndeterminate];
   [newInd setBezeled:isBezeled];
   [newInd setUsesThreadedAnimation:usesThreadedAnimation];
   [newInd setAnimimationDelay:animationDelay];
   [newInd setDoubleValue:doubleValue];
   [newInd setMinValue:minValue];
   [newInd setMaxValue:maxValue];
   [newInd setVertical:isVertical];
   return newInd;
}
*/

// NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
   [super encodeWithCoder:aCoder];
   [aCoder encodeValueOfObjCType: @encode(BOOL) at:&isIndeterminate];
   [aCoder encodeValueOfObjCType: @encode(BOOL) at:&isBezeled];
   [aCoder encodeValueOfObjCType: @encode(BOOL) at:&usesThreadedAnimation];
   [aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at:&animationDelay];
   [aCoder encodeValueOfObjCType: @encode(double) at:&doubleValue];
   [aCoder encodeValueOfObjCType: @encode(double) at:&minValue];
   [aCoder encodeValueOfObjCType: @encode(double) at:&maxValue];
   [aCoder encodeValueOfObjCType: @encode(BOOL) at:&isVertical];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
   self = [super initWithCoder:aDecoder];
   [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&isIndeterminate];
   [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&isBezeled];
   [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&usesThreadedAnimation];
   [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval)
	     at:&animationDelay];
   [aDecoder decodeValueOfObjCType: @encode(double) at:&doubleValue];
   [aDecoder decodeValueOfObjCType: @encode(double) at:&minValue];
   [aDecoder decodeValueOfObjCType: @encode(double) at:&maxValue];
   [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&isVertical];
   return self;
}

@end

@implementation NSProgressIndicator (GNUstepExtensions)

- (BOOL)isVertical { return isVertical; }
- (void)setVertical:(BOOL)flag
{
   if (isVertical != flag)
   {
      isVertical = flag;
      [self setNeedsDisplay:YES];
      [self _update];
   }
}

@end

@implementation NSProgressIndicator(PrivateMethods)

- (void)_update
{
   if (window != nil)
      if ([window isVisible])
      {
	 [window display];
	 [GSCurrentContext() flush];
      }
}

@end
