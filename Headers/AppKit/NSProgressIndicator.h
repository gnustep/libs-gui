/*
 * NSProgressIndicator.h
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:  Gerrit van Dyk <gerritvd@decimax.com>
 * Date: 1999
 *
 * This file is part of the GNUstep GUI Library.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; see the file COPYING.LIB.
 * If not, see <http://www.gnu.org/licenses/> or write to the
 * Free Software Foundation, 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef _GNUstep_H_NSProgressIndicator
#define _GNUstep_H_NSProgressIndicator
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSView.h>

/*
 * For NSControlTint
 */
#import <AppKit/NSColor.h>

/*
 * For NSControlSize
 */
#import <AppKit/NSCell.h>

@class NSTimer;
@class NSThread;

/**
 * Preferred thickness values for different sizes and appearances.
 */
typedef enum _NSProgressIndicatorThickness
  {
    NSProgressIndicatorPreferredThickness = 14,
    NSProgressIndicatorPreferredSmallThickness = 10,
    NSProgressIndicatorPreferredLargeThickness = 18,
    NSProgressIndicatorPreferredAquaThickness = 12
  } NSProgressIndicatorThickness;

/**
 * Available progress indicator styles.
 */
typedef enum _NSProgressIndicatorStyle
  {
    NSProgressIndicatorBarStyle = 0,
    NSProgressIndicatorStyleBar = NSProgressIndicatorBarStyle,
    NSProgressIndicatorSpinningStyle = 1,
    NSProgressIndicatorStyleSpinning = NSProgressIndicatorSpinningStyle
  } NSProgressIndicatorStyle;

APPKIT_EXPORT_CLASS
/**
 * NSProgressIndicator displays task progress either as a bar or a spinner.
 *
 * Supports determinate (min/max/value) and indeterminate (animated) modes,
 * with optional threaded animation and standard control sizing/tinting.
 */
@interface NSProgressIndicator : NSView
{
  double _doubleValue;
  double _minValue;
  double _maxValue;
  NSTimeInterval _animationDelay;
  NSProgressIndicatorStyle _style;
  BOOL _isIndeterminate;
  BOOL _isBezeled;
  BOOL _usesThreadedAnimation;
  BOOL _isDisplayedWhenStopped;
  NSControlTint _controlTint;
  NSControlSize _controlSize;
  @private
    BOOL _isVertical;
  BOOL _isRunning;
  int _count;
  NSTimer *_timer;
  id _reserved;
}

/**
 * Animating the progress indicator.
 */
#if OS_API_VERSION(GS_API_LATEST, MAC_OS_X_VERSION_10_5)
/**
 * Advances the indeterminate animation by one frame.
 */
- (void)animate:(id)sender;

/**
 * Time interval between animation frames in seconds.
 */
- (NSTimeInterval)animationDelay;

/**
 * Sets the time interval between animation frames in seconds.
 */
- (void)setAnimationDelay:(NSTimeInterval)delay;
#endif

/**
 * Starts indeterminate animation.
 */
- (void)startAnimation:(id)sender;

/**
 * Stops indeterminate animation.
 */
- (void)stopAnimation:(id)sender;

/**
 * Indicates whether animation runs on a background thread.
 */
- (BOOL)usesThreadedAnimation;

/**
 * Enables or disables background-thread animation.
 */
- (void)setUsesThreadedAnimation:(BOOL)flag;

/**
 * Advancing the progress bar in determinate mode.
 */
/**
 * Increments the current value by the specified delta.
 */
- (void)incrementBy:(double)delta;

/**
 * Current progress value.
 */
- (double)doubleValue;

/**
 * Sets the current progress value.
 */
- (void)setDoubleValue:(double)aValue;

/**
 * Minimum progress value.
 */
- (double)minValue;

/**
 * Sets the minimum progress value.
 */
- (void)setMinValue:(double)newMinimum;

/**
 * Maximum progress value.
 */
- (double)maxValue;

/**
 * Sets the maximum progress value.
 */
- (void)setMaxValue:(double)newMaximum;

/**
 * Setting the appearance.
 */
/**
 * Indicates whether a bezel is drawn.
 */
- (BOOL)isBezeled;

/**
 * Enables or disables the bezel.
 */
- (void)setBezeled:(BOOL)flag;

/**
 * Indicates whether the indicator is indeterminate.
 */
- (BOOL)isIndeterminate;

/**
 * Sets whether the indicator is indeterminate.
 */
- (void)setIndeterminate:(BOOL)flag;

/**
 * Standard control layout.
 */
/**
 * Returns the control size used by the indicator.
 */
- (NSControlSize)controlSize;

/**
 * Sets the control size used by the indicator.
 */
- (void)setControlSize:(NSControlSize)size;

/**
 * Returns the control tint used by the indicator.
 */
- (NSControlTint)controlTint;

/**
 * Sets the control tint used by the indicator.
 */
- (void)setControlTint:(NSControlTint)tint;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_2, GS_API_LATEST)
/**
 * Indicates whether the indicator remains visible when stopped.
 */
- (BOOL)isDisplayedWhenStopped;

/**
 * Shows or hides the indicator when it is stopped.
 */
- (void)setDisplayedWhenStopped:(BOOL)flag;

/**
 * Sets the visual style (bar or spinning).
 */
- (void)setStyle:(NSProgressIndicatorStyle)style;

/**
 * Returns the visual style (bar or spinning).
 */
- (NSProgressIndicatorStyle)style;

/**
 * Adjusts the receiver’s size to fit the current style and control size.
 */
- (void)sizeToFit;
#endif

@end

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * GNUstep extensions.
 */
@interface NSProgressIndicator (GNUstepExtensions)

/**
 * Enables vertical progress bar orientation.
 *
 * If vertical is true, progress grows from bottom to top; otherwise left to right.
 */
  - (BOOL)isVertical;

/**
 * Sets vertical orientation.
 */
- (void)setVertical:(BOOL)flag;

@end
#endif

#endif /* _GNUstep_H_NSProgressIndicator */
