/* Definition of class NSCollectionViewTransitionLayout
   Copyright (C) 2021 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 30-05-2021

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSCollectionViewTransitionLayout_h_GNUSTEP_GUI_INCLUDE
#define _NSCollectionViewTransitionLayout_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSCollectionViewLayout.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_11, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

typedef NSString* NSCollectionViewTransitionLayoutAnimatedKey;

APPKIT_EXPORT_CLASS
/**
 * NSCollectionViewTransitionLayout manages the animated transition between
 * two collection view layouts. This specialized layout coordinates the
 * interpolation of item positions, sizes, and other attributes during
 * layout transitions, providing smooth visual continuity when switching
 * between different layout configurations. It maintains references to both
 * the current and target layouts, managing the transition progress and
 * providing customizable animation parameters for complex layout changes.
 */
@interface NSCollectionViewTransitionLayout : NSCollectionViewLayout
{
  CGFloat _transitionProgress;
  NSCollectionViewLayout *_currentLayout;
  NSCollectionViewLayout *_nextLayout;
}

/**
 * Returns the current progress of the layout transition as a value between
 * 0.0 and 1.0. A progress of 0.0 indicates the transition is at the
 * beginning, showing the current layout, while 1.0 indicates completion,
 * fully displaying the next layout. Intermediate values represent partial
 * transitions with interpolated attributes between the two layouts.
 */
- (CGFloat) transitionProgress;
/**
 * Sets the progress of the layout transition to control the interpolation
 * between current and next layouts. The progress value should be between
 * 0.0 and 1.0, where 0.0 represents the starting layout state and 1.0
 * represents the final layout state. Setting this value triggers attribute
 * recalculation and visual updates for all affected items.
 */
- (void) setTransitionProgress: (CGFloat)transitionProgress;

/**
 * Returns the layout that serves as the starting point for the transition.
 * The current layout defines the initial positions, sizes, and attributes
 * of collection view items before the transition begins. During the
 * transition, attributes are interpolated between this layout and the
 * next layout based on the current transition progress.
 */
- (NSCollectionViewLayout *) currentLayout;
/**
 * Returns the layout that serves as the target endpoint for the transition.
 * The next layout defines the final positions, sizes, and attributes that
 * collection view items will have when the transition completes. The
 * transition interpolates between the current layout and this target
 * layout based on the transition progress value.
 */
- (NSCollectionViewLayout *) nextLayout;

// Designated initializer
/**
 * Initializes a transition layout with the specified current and next
 * layouts. This designated initializer creates a transition layout that
 * will manage the animated transition between the two provided layouts.
 * The current layout represents the starting state, while the next layout
 * represents the target state. The transition layout handles attribute
 * interpolation and progress management between these two endpoints.
 */
- (instancetype) initWithCurrentLayout: (NSCollectionViewLayout *)currentLayout
                            nextLayout: (NSCollectionViewLayout *)nextLayout;

/**
 * Updates the interpolation value for the specified animated key during
 * the layout transition. Animated keys represent custom parameters that
 * can be interpolated independently during transitions, allowing for
 * fine-grained control over specific aspects of the layout animation
 * beyond the standard position and size interpolations.
 */
- (void) updateValue: (CGFloat)value forAnimatedKey: (NSCollectionViewTransitionLayoutAnimatedKey)key;
/**
 * Returns the current interpolation value for the specified animated key.
 * Animated keys provide custom animation parameters that can be queried
 * during layout transitions to create sophisticated animation effects.
 * These values are typically interpolated based on the overall transition
 * progress but can be customized for specific animation requirements.
 */
- (CGFloat) valueForAnimatedKey: (NSCollectionViewTransitionLayoutAnimatedKey)key;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSCollectionViewTransitionLayout_h_GNUSTEP_GUI_INCLUDE */

