/*
   NSView.m

   The view class which encapsulates all drawing functionality

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Ovidiu Predescu <ovidiu@net-community.com>.
   Date: 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: January 1999

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

#include <gnustep/gui/config.h>
#include <math.h>
#include <float.h>

#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/GSTrackingRect.h>
#include <AppKit/NSAffineTransform.h>


@implementation NSView

//
//  Class variables
//
static NSAffineTransform	*flip = nil;

static void	(*appImp)(NSAffineTransform*, SEL, NSAffineTransform*) = 0;
static SEL	appSel = @selector(appendTransform:);

static void	(*invalidateImp)(NSView*, SEL) = 0;
static SEL	invalidateSel = @selector(_invalidateCoordinates);

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSView class])
    {
      Class	matrixClass = [NSAffineTransform class];
      NSAffineTransformStruct	ats = { 1, 0, 0, -1, 0, 1 };

      appImp = (void (*)(NSAffineTransform*, SEL, NSAffineTransform*))
		[matrixClass instanceMethodForSelector: appSel];

      invalidateImp = (void (*)(NSView*, SEL))
		[self instanceMethodForSelector: invalidateSel];

      flip = [matrixClass new];
      [flip setTransformStruct: ats];

      NSDebugLLog(@"NSView", @"Initialize NSView class\n");
      [self setVersion: 1];
    }
}

/*
 * return the view at the top of graphics contexts stack
 * or nil if none is focused
 */
+ (NSView*) focusView
{
  return [[NSGraphicsContext currentContext] focusView];
}

//
// Instance methods
//
- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)frameRect
{
  [super init];				// super is NSResponder

  NSAssert(frameRect.size.width >= 0 && frameRect.size.height >= 0,
	@"illegal frame dimensions supplied");

  frame = frameRect;			// Set frame rectangle
  bounds.origin = NSZeroPoint;		// Set bounds rectangle
  bounds.size = frame.size;

  frameMatrix = [NSAffineTransform new];	// Map fromsuperview to frame
  boundsMatrix = [NSAffineTransform new];	// Map fromsuperview to bounds
  matrixToWindow = [NSAffineTransform new];	// Map to window coordinates
  matrixFromWindow = [NSAffineTransform new];	// Map from window coordinates
  [frameMatrix setFrameOrigin: frame.origin];

  sub_views = [NSMutableArray new];
  tracking_rects = [NSMutableArray new];
  cursor_rects = [NSMutableArray new];

  super_view = nil;
  window = nil;
  is_rotated_from_base = NO;
  is_rotated_or_scaled_from_base = NO;
  disable_autodisplay = NO;
  needs_display = YES;
  post_frame_changes = NO;
  autoresize_subviews = YES;
  autoresizingMask = NSViewNotSizable;
  coordinates_valid = NO;

  return self;
}

- (void) dealloc
{
  [matrixToWindow release];
  [matrixFromWindow release];
  [frameMatrix release];
  [boundsMatrix release];
  [sub_views release];
  [tracking_rects release];
  [cursor_rects release];

  [super dealloc];
}

- (void) addSubview: (NSView*)aView
{
  if ([self isDescendantOf: aView])
    {
      NSLog(@"Operation addSubview: creates a loop in the views tree!\n");
      return;
    }

  [aView retain];
  [aView removeFromSuperview];
  [aView viewWillMoveToWindow: window];
  [aView viewWillMoveToSuperview: self];
  [aView setNextResponder: self];
  [sub_views addObject: aView];
  [aView resetCursorRects];
  [aView setNeedsDisplay: YES];
  [aView release];
}

- (void) addSubview: (NSView*)aView
	 positioned: (NSWindowOrderingMode)place
	 relativeTo: (NSView*)otherView
{
  unsigned	index;

  if ([self isDescendantOf: aView])
    {
      NSLog(@"addSubview: positioned: relativeTo: will create a cycle "
		    @"in the views tree!\n");
      return;
    }

  if (aView == otherView)
    return;

  index = [sub_views indexOfObjectIdenticalTo: otherView];
  if (index == NSNotFound)
    {
      if (place == NSWindowBelow)
	index = 0;
      else
	index = [sub_views count];
    }
  [aView retain];
  [aView removeFromSuperview];
  [aView viewWillMoveToWindow: window];
  [aView viewWillMoveToSuperview: self];
  [aView setNextResponder: self];
  if (place == NSWindowBelow)
    [sub_views insertObject: aView atIndex: index];
  else
    [sub_views insertObject: aView atIndex: index+1];
  [aView resetCursorRects];
  [aView setNeedsDisplay: YES];
  [aView release];
}

- (NSView*) ancestorSharedWithView: (NSView*)aView
{
  if (self == aView)			// Are they the same view?
    return self;

  if ([self isDescendantOf: aView])	// Is self a descendant of view?
    return aView;

  if ([aView isDescendantOf: self])	// Is view a descendant of self?
    return self;

  // If neither are descendants of each other and either does not have a
  // superview then they cannot have a common ancestor

  if (![self superview])
    return nil;

  if (![aView superview])
    return nil;

  // Find the common ancestor of superviews
  return [[self superview] ancestorSharedWithView: [aView superview]];
}

- (BOOL) isDescendantOf: (NSView*)aView
{
  if (aView == self)
    return YES;

  if (!super_view)
    return NO;

  if (super_view == aView)
    return YES;

  return [super_view isDescendantOf: aView];
}

- (NSView*) opaqueAncestor
{
  if ([self isOpaque] || !super_view)
    return self;
  else
    return [super_view opaqueAncestor];
}

- (void) removeFromSuperviewWithoutNeedingDisplay
{
  NSMutableArray	*views;

  /*
   * We MUST make sure that coordinates are invalidated even if we have
   * no superview - cos they may have been rebuilt since we lost the
   * superview and the fact that this method has been invoked probably
   * means we are about to be placed in a new view where the coordinate
   * system will be different.
   */
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);

  if (!super_view)      // if no superview then just return
    return;

  if ([window firstResponder] == self)
    [window makeFirstResponder: window];
  views = [super_view subviews];
  window = nil;
  super_view = nil;
  [views removeObjectIdenticalTo: self];
}

- (void) removeFromSuperview
{
  NSMutableArray	*views;
  NSWindow		*win;

  /*
   * We MUST make sure that coordinates are invalidated even if we have
   * no superview - cos they may have been rebuilt since we lost the
   * superview and the fact that this method has been invoked probably
   * means we are about to be placed in a new view where the coordinate
   * system will be different.
   */
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);

  if (!super_view)	// if no superview then just return
    return;

  if ([window firstResponder] == self)
    [window makeFirstResponder: window];
  views = [super_view subviews];
  [super_view setNeedsDisplayInRect: frame];
  win = window;
  window = nil;
  super_view = nil;

  [views removeObjectIdenticalTo: self];
}

- (void) replaceSubview: (NSView*)oldView with: (NSView*)newView
{
  if (!newView)
    return;

  /*
   * NB. we implement the replacement in full rather than calling addSubview:
   * since classes like NSBox override these methods but expect to be able to
   * call [super replaceSubview: with: ] safely.
   */
  if (!oldView)
    {
      [newView retain];
      [newView removeFromSuperview];
      [newView viewWillMoveToWindow: window];
      [newView viewWillMoveToSuperview: self];
      [newView setNextResponder: self];
      [sub_views addObject: newView];
      [newView resetCursorRects];
      [newView setNeedsDisplay: YES];
      [newView release];
    }
  else if (oldView != newView
    && [sub_views indexOfObjectIdenticalTo: oldView] != NSNotFound)
    {
      unsigned index;

      [newView retain];
      [newView removeFromSuperview];
      index = [sub_views indexOfObjectIdenticalTo: oldView];
      [oldView removeFromSuperview];
      [newView viewWillMoveToWindow: window];
      [newView viewWillMoveToSuperview: self];
      [newView setNextResponder: self];
      [sub_views addObject: newView];
      [newView resetCursorRects];
      [newView setNeedsDisplay: YES];
      [newView release];
    }
}

- (void) sortSubviewsUsingFunction: (int (*)(id ,id ,void*))compare
			   context: (void*)context
{
  [sub_views sortUsingFunction: compare context: context];
}

- (void) viewWillMoveToSuperview: (NSView*)newSuper
{
  super_view = newSuper;
}

- (void) viewWillMoveToWindow: (NSWindow*)newWindow
{
  unsigned	count;

  window = newWindow;

  count = [sub_views count];
  if (count > 0)
    {
      unsigned	i;
      NSView*	array[count];

      [sub_views getObjects: array];
      for (i = 0; i < count; ++i)
	[array[i] viewWillMoveToWindow: newWindow];
    }
}

- (void) rotateByAngle: (float)angle
{
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  [boundsMatrix rotateByAngle: angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		  postNotificationName: NSViewBoundsDidChangeNotification
				object: self];
}

- (void) setFrame: (NSRect)frameRect
{
  NSSize old_size = frame.size;

  NSAssert(frameRect.size.width >= 0 && frameRect.size.height >= 0,
	@"illegal frame dimensions supplied");

  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  frame = frameRect;
  bounds.size = frame.size;
  [frameMatrix setFrameOrigin: frame.origin];

  [self resizeSubviewsWithOldSize: old_size];	// Resize the subviews
  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewFrameDidChangeNotification
				  object: self];
}

- (void) setFrameOrigin: (NSPoint)newOrigin
{
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  frame.origin = newOrigin;
  [frameMatrix setFrameOrigin: frame.origin];

  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewFrameDidChangeNotification
				  object: self];
}

- (void) setFrameSize: (NSSize)newSize
{
  NSSize old_size = frame.size;

  NSAssert(newSize.width >= 0 && newSize.height >= 0,
	@"illegal frame dimensions supplied");
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  frame.size = bounds.size = newSize;

  [self resizeSubviewsWithOldSize: old_size];		// Resize the subviews
  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewFrameDidChangeNotification
				  object: self];
}

- (void) setFrameRotation: (float)angle
{
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  [frameMatrix setFrameRotation: angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewFrameDidChangeNotification
				  object: self];
}

- (BOOL) isRotatedFromBase
{
  if (is_rotated_from_base)
    return is_rotated_from_base;
  else if (super_view)
    return [super_view isRotatedFromBase];
  else
    return NO;
}

- (BOOL) isRotatedOrScaledFromBase
{
  if (is_rotated_or_scaled_from_base)
    return is_rotated_or_scaled_from_base;
  else if (super_view)
    return [super_view isRotatedOrScaledFromBase];
  else
    return NO;
}

- (void) scaleUnitSquareToSize: (NSSize)newSize
{
  float	sx;
  float	sy;

  NSAssert(newSize.width > 0 && newSize.height > 0, @"illegal size supplied");

  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);

  bounds.size.width = frame.size.width / newSize.width;
  bounds.size.height = frame.size.height / newSize.height;

  is_rotated_or_scaled_from_base = YES;

  if (bounds.size.width == 0)
    {
      if (frame.size.width == 0)
	sx = 1;
      else
	sx = FLT_MAX;
    }
  else
    {
      sx = frame.size.width / bounds.size.width;
    }

  if (bounds.size.height == 0)
    {
      if (frame.size.height == 0)
	sy = 1;
      else
	sy = FLT_MAX;
    }
  else
    {
      sy = frame.size.height / bounds.size.height;
    }

  [boundsMatrix scaleBy: sx : sy];

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (void) setBounds: (NSRect)aRect
{
  float sx, sy;

  NSAssert(aRect.size.width >= 0 && aRect.size.height >= 0,
	@"illegal bounds dimensions supplied");

  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);

  bounds = aRect;
  [boundsMatrix setFrameOrigin: NSMakePoint(-bounds.origin.x,-bounds.origin.y)];

  if (bounds.size.width == 0)
    {
      if (frame.size.width == 0)
	sx = 1;
      else
	sx = FLT_MAX;
    }
  else
    {
      sx = frame.size.width / bounds.size.width;
    }

  if (bounds.size.height == 0)
    {
      if (frame.size.height == 0)
	sy = 1;
      else
	sy = FLT_MAX;
    }
  else
    {
      sy = frame.size.height / bounds.size.height;
    }

  [boundsMatrix scaleTo: sx : sy];

  if (sx != 1 || sy != 1)
    is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (void) setBoundsOrigin: (NSPoint)newOrigin
{
  bounds.origin = newOrigin;

  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  [boundsMatrix setFrameOrigin: NSMakePoint(-newOrigin.x, -newOrigin.y)];

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (void) setBoundsSize: (NSSize)newSize
{
  float sx, sy;

  NSAssert(newSize.width >= 0 && newSize.height >= 0,
	@"illegal bounds dimensions supplied");

  if (coordinates_valid)
    {
      (*invalidateImp)(self, invalidateSel);
    }
  if (newSize.width == 0)
    {
      NSLog(@"[NSView -setBoundsSize:] zero width supplied");
    }
  if (newSize.height == 0)
    {
      NSLog(@"[NSView -setBoundsSize:] zero height supplied");
    }

  bounds.size = newSize;

  if (bounds.size.width == 0)
    {
      if (frame.size.width == 0)
	sx = 1;
      else
	sx = FLT_MAX;
    }
  else
    {
      sx = frame.size.width / bounds.size.width;
    }

  if (bounds.size.height == 0)
    {
      if (frame.size.height == 0)
	sy = 1;
      else
	sy = FLT_MAX;
    }
  else
    {
      sy = frame.size.height / bounds.size.height;
    }

  [boundsMatrix scaleTo: sx : sy];

  if (sx != 1 || sy != 1)
    is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (void) setBoundsRotation: (float)angle
{
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  [boundsMatrix setFrameRotation: angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (void) translateOriginToPoint: (NSPoint)point
{
  if (coordinates_valid)
    (*invalidateImp)(self, invalidateSel);
  [boundsMatrix translateToPoint: point];

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
		    postNotificationName: NSViewBoundsDidChangeNotification
				  object: self];
}

- (NSRect) centerScanRect: (NSRect)aRect
{
  NSAffineTransform	*matrix;

  /*
   *	Hmm - we assume that the windows coordinate system is centered on the
   *	pixels of the screen - this may not be correct of course.
   *	Plus - this is all pretty meaningless is we are not in a window!
   */
  matrix = [self _matrixToWindow];
  aRect.origin = [matrix pointInMatrixSpace: aRect.origin];
  aRect.size = [matrix sizeInMatrixSpace: aRect.size];

  aRect.origin.x = floor(aRect.origin.x);
  aRect.origin.y = floor(aRect.origin.y);
  aRect.size.width = floor(aRect.size.width);
  aRect.size.height = floor(aRect.size.height);

  matrix = [self _matrixFromWindow];
  aRect.origin = [matrix pointInMatrixSpace: aRect.origin];
  aRect.size = [matrix sizeInMatrixSpace: aRect.size];

  return aRect;
}

- (NSPoint) convertPoint: (NSPoint)aPoint fromView: (NSView*)aView
{
  NSPoint	new;
  NSAffineTransform	*matrix;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aPoint;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  matrix = [aView _matrixToWindow];
  new = [matrix pointInMatrixSpace: aPoint];

  if (coordinates_valid)
    matrix = matrixFromWindow;
  else
    matrix = [self _matrixFromWindow];
  new = [matrix pointInMatrixSpace: new];

  return new;
}

- (NSPoint) convertPoint: (NSPoint)aPoint toView: (NSView*)aView
{
  NSPoint	new;
  NSAffineTransform	*matrix;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aPoint;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  if (coordinates_valid)
    matrix = matrixToWindow;
  else
    matrix = [self _matrixToWindow];
  new = [matrix pointInMatrixSpace: aPoint];

  matrix = [aView _matrixFromWindow];
  new = [matrix pointInMatrixSpace: new];

  return new;
}

- (NSRect) convertRect: (NSRect)aRect fromView: (NSView*)aView
{
  NSAffineTransform	*matrix;
  NSRect	r;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aRect;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  matrix = [aView _matrixToWindow];
  r.origin = [matrix pointInMatrixSpace: aRect.origin];
  r.size = [matrix sizeInMatrixSpace: aRect.size];

  if (coordinates_valid)
    matrix = matrixFromWindow;
  else
    matrix = [self _matrixFromWindow];
  r.origin = [matrix pointInMatrixSpace: r.origin];
  r.size = [matrix sizeInMatrixSpace: r.size];

  if ([aView isFlipped] != [self isFlipped])
    r.origin.y -= r.size.height;

  return r;
}

- (NSRect) convertRect: (NSRect)aRect toView: (NSView*)aView
{
  NSAffineTransform	*matrix;
  NSRect	r;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aRect;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  if (coordinates_valid)
    matrix = matrixToWindow;
  else
    matrix = [self _matrixToWindow];
  r.origin = [matrix pointInMatrixSpace: aRect.origin];
  r.size = [matrix sizeInMatrixSpace: aRect.size];

  matrix = [aView _matrixFromWindow];
  r.origin = [matrix pointInMatrixSpace: r.origin];
  r.size = [matrix sizeInMatrixSpace: r.size];

  if ([aView isFlipped] != [self isFlipped])
    r.origin.y -= r.size.height;

  return r;
}

- (NSSize) convertSize: (NSSize)aSize fromView: (NSView*)aView
{
  NSSize	new;
  NSAffineTransform	*matrix;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aSize;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  matrix = [aView _matrixToWindow];
  new = [matrix sizeInMatrixSpace: aSize];

  if (coordinates_valid)
    matrix = matrixFromWindow;
  else
    matrix = [self _matrixFromWindow];
  new = [matrix sizeInMatrixSpace: new];

  return new;
}

- (NSSize) convertSize: (NSSize)aSize toView: (NSView*)aView
{
  NSSize	new;
  NSAffineTransform	*matrix;

  if (!aView)
    aView = [window contentView];
  if (aView == self)
    return aSize;
  NSAssert(window == [aView window], NSInvalidArgumentException);

  if (coordinates_valid)
    matrix = matrixToWindow;
  else
    matrix = [self _matrixToWindow];
  new = [matrix sizeInMatrixSpace: aSize];

  matrix = [aView _matrixFromWindow];
  new = [matrix sizeInMatrixSpace: new];

  return new;
}

- (void) setPostsFrameChangedNotifications: (BOOL)flag
{
  post_frame_changes = flag;
}

- (void) setPostsBoundsChangedNotifications: (BOOL)flag
{
  post_bounds_changes = flag;
}

// resize subviews only if we are supposed to and we have never been rotated
- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  id e, o;

  if ([self autoresizesSubviews] == NO || is_rotated_from_base == YES)
    return;

  e = [sub_views objectEnumerator];
  o = [e nextObject];
  while (o)
    {
      [o resizeWithOldSuperviewSize: oldSize];        // Resize the subview
      o = [e nextObject];
    }
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  float change, changePerOption;
  int options = 0;
  NSSize old_size = frame.size;
  NSSize superViewFrameSize = [super_view frame].size;
  BOOL changedOrigin = NO;
  BOOL changedSize = NO;

  // do nothing if view is not resizable
  if (autoresizingMask == NSViewNotSizable)
    return;

  // determine if and how the X axis can be resized
  if (autoresizingMask & NSViewWidthSizable)
    options++;
  if (autoresizingMask & NSViewMinXMargin)
    options++;
  if (autoresizingMask & NSViewMaxXMargin)
    options++;

  // adjust the X axis if any X options are set in the mask
  if (options >= 1)
    {
      change = superViewFrameSize.width - oldSize.width;
      changePerOption = floor(change/options);

      if (autoresizingMask & NSViewWidthSizable)
	{
	  float oldFrameWidth = frame.size.width;

	  frame.size.width += changePerOption;
	  if (is_rotated_or_scaled_from_base)
	    {
	      bounds.size.width *= frame.size.width/oldFrameWidth;
	      bounds.size.width = floor(bounds.size.width);
	    }
	  else
	    bounds.size.width += changePerOption;
	  changedSize = YES;
	}
      if (autoresizingMask & NSViewMinXMargin)
	{
	  frame.origin.x += changePerOption;
	  changedOrigin = YES;
	}
    }

  // determine if and how the Y axis can be resized
  options = 0;
  if (autoresizingMask & NSViewHeightSizable)
    options++;
  if (autoresizingMask & NSViewMinYMargin)
    options++;
  if (autoresizingMask & NSViewMaxYMargin)
    options++;

  // adjust the Y axis if any Y options are set in the mask
  if (options >= 1)
    {
      change = superViewFrameSize.height - oldSize.height;
      changePerOption = floor(change/options);

      if (autoresizingMask & NSViewHeightSizable)
	{
	  float oldFrameHeight = frame.size.height;

	  frame.size.height += changePerOption;
	  if (is_rotated_or_scaled_from_base)
	    {
	      bounds.size.height *= frame.size.height/oldFrameHeight;
	      bounds.size.height = floor(bounds.size.height);
	    }
	  else
	    bounds.size.height += changePerOption;
	  changedSize = YES;
	}
      if (autoresizingMask & (NSViewMaxYMargin | NSViewMinYMargin))
	{
	  if ([super_view isFlipped] == YES)
	    {
	      if (autoresizingMask & NSViewMaxYMargin)
		{
		  frame.origin.y += changePerOption;
		  changedOrigin = YES;
		}
	    }
	  else
	    {
	      if (autoresizingMask & NSViewMinYMargin)
		{
		  frame.origin.y += changePerOption;
		  changedOrigin = YES;
		}
	    }
	}
    }

  if (changedOrigin)
    [frameMatrix setFrameOrigin: frame.origin];

  if (changedSize && is_rotated_or_scaled_from_base)
    {
      float sx;
      float sy;

      if (bounds.size.width == 0)
	{
	  if (frame.size.width == 0)
	    sx = 1;
	  else
	    sx = FLT_MAX;
	}
      else
	{
	  sx = frame.size.width / bounds.size.width;
	}

      if (bounds.size.height == 0)
	{
	  if (frame.size.height == 0)
	    sy = 1;
	  else
	    sy = FLT_MAX;
	}
      else
	{
	  sy = frame.size.height / bounds.size.height;
	}

      [boundsMatrix scaleTo: sx : sy];
    }

  if (changedSize || changedOrigin)
    {
      if (coordinates_valid)
	(*invalidateImp)(self, invalidateSel);
      [self resizeSubviewsWithOldSize: old_size];
    }
}

- (void) allocateGState
{
  // implemented by the back end
}

- (void) releaseGState
{
  // implemented by the back end
}

- (int) gState
{
  return 0;
}

- (void) renewGState
{
}

- (void) setUpGState
{
}

- (void) lockFocus
{
  [[NSGraphicsContext currentContext] lockFocusView: self];
}

- (void) unlockFocus
{
  [[NSGraphicsContext currentContext] unlockFocusView: self];
}

- (BOOL) canDraw
{			// not implemented per OS spec FIX ME
  if (window)
    return YES;
  else
    return NO;
}

- (void)display											
{
  if (!window)
    return;

  [self displayRect: bounds];
}

- (void) displayIfNeeded
{
  if (needs_display)
    {
      if ([self isOpaque])
	{
	  [self displayIfNeededIgnoringOpacity];
	}
      else
	{
	  NSView	*firstOpaque = [self opaqueAncestor];
	  NSRect	rect = bounds;

	  rect = [firstOpaque convertRect: rect fromView: self];
	  [firstOpaque displayIfNeededInRectIgnoringOpacity: rect];
	}
    }
}

- (void) displayIfNeededIgnoringOpacity
{
  if (needs_display)
    {
      [self displayIfNeededInRectIgnoringOpacity: bounds];
    }
}

- (void) displayIfNeededInRect: (NSRect)aRect
{
  if (needs_display)
    {
      if ([self isOpaque])
	{
	  [self displayIfNeededInRectIgnoringOpacity: aRect];
	}
      else
	{
	  NSView	*firstOpaque = [self opaqueAncestor];
	  NSRect	rect;

	  rect = [firstOpaque convertRect: aRect fromView: self];
	  [firstOpaque displayIfNeededInRectIgnoringOpacity: rect];
	}
    }
}

- (void) displayIfNeededInRectIgnoringOpacity: (NSRect)aRect
{
  if (!window)
    return;

  if (needs_display)
    {
      unsigned	i, count;
      BOOL	stillNeedsDisplay = NO;
      NSRect	redrawRect;

      if (coordinates_valid == NO)
	[self _rebuildCoordinates];
      aRect = NSIntersectionRect(aRect, visibleRect);

      redrawRect = NSIntersectionRect(aRect, invalidRect);
      if (NSIsEmptyRect(redrawRect) == NO)
	{
	  [self lockFocus];
	  [self drawRect: redrawRect];
	  [self unlockFocus];
	}

      count = [sub_views count];
      if (count > 0)
	{
	  NSView*	array[count];

	  [sub_views getObjects: array];

	  for (i = 0; i < count; i++)
	    {
	      NSRect isect;
	      NSView *subview = array[i];
	      NSRect subviewFrame = subview->frame;

	      if ([subview->frameMatrix isRotated])
		{
		  [subview->frameMatrix boundingRectFor: subviewFrame
						 result: &subviewFrame];
		}

	      /*
	       * Having drawn ourself into the rect, we must make sure that
	       * subviews overlapping the area are redrawn.
	       */
	      isect = NSIntersectionRect(redrawRect, subviewFrame);
	      if (NSIsEmptyRect(isect) == NO)
		{
		  isect = [subview convertRect: isect
				      fromView: self];
		  /*
		   * hack the ivars of the subview directly for speed.
		   */
		  subview->needs_display = YES;
		  subview->invalidRect = NSUnionRect(subview->invalidRect,
			isect);
		}

	      if (subview->needs_display)
		{
		  isect = NSIntersectionRect(aRect, subviewFrame);
		  if (NSIsEmptyRect(isect) == NO)
		    {
		      isect = [subview convertRect: isect
					  fromView: self];
		      [subview displayIfNeededInRectIgnoringOpacity: isect];
		    }
		  if (subview->needs_display)
		    {
		      stillNeedsDisplay = YES;
		    }
		}
	    }
	}

      /*
       * If our invalid rectangle is entirely contained with the area we
       * have just redisplayed, then we set the invalid rectangle to zero
       */
      redrawRect = NSUnionRect(invalidRect, aRect);
      if (NSEqualRects(aRect, redrawRect) == YES)
	{
	  invalidRect = NSZeroRect;
	  needs_display = stillNeedsDisplay;
	}
      else
	needs_display = YES;

      [window flushWindow];
    }
}

- (void) displayRect: (NSRect)rect
{
  if ([self isOpaque])
    {
      [self displayRectIgnoringOpacity: rect];
    }
  else
    {
      NSView *firstOpaque = [self opaqueAncestor];

      rect = [firstOpaque convertRect: rect fromView: self];
      [firstOpaque displayRectIgnoringOpacity: rect];
    }
}

- (void) displayRectIgnoringOpacity: (NSRect)aRect
{
  unsigned	i, count;
  NSRect	rect;
  BOOL		stillNeedsDisplay = NO;

  if (!window)
    return;

  if (coordinates_valid == NO)
    [self _rebuildCoordinates];

  [self lockFocus];
  [self drawRect: aRect];
  [self unlockFocus];

  count = [sub_views count];

  if (count > 0)
    {
      NSView*	array[count];

      [sub_views getObjects: array];

      for (i = 0; i < count; ++i)
	{
	  NSView	*subview = array[i];
	  NSRect	subviewFrame = subview->frame;
	  NSRect	intersection;

	  if ([subview->frameMatrix isRotated])
	    [subview->frameMatrix boundingRectFor: subviewFrame
					   result: &subviewFrame];

	  intersection = NSIntersectionRect(aRect, subviewFrame);
	  if (NSIsEmptyRect(intersection) == NO)
	    {
	      intersection = [subview convertRect: intersection fromView: self];
	      [subview displayRectIgnoringOpacity: intersection];
	    }
	  if (subview->needs_display)
	    {
	      stillNeedsDisplay = YES;
	    }
	}
    }

  /*
   *	If the rect we displayed contains the invalidRect
   *	for the view then we can empty invalidRect.
   */
  rect = NSUnionRect(invalidRect, aRect);
  if (NSEqualRects(rect, aRect) == YES)
    {
      invalidRect = NSZeroRect;
    }
  else
    {
      stillNeedsDisplay = YES;
    }
  needs_display = stillNeedsDisplay;
  [window flushWindow];
}

- (void)drawRect: (NSRect)rect
{}

- (NSRect) visibleRect
{
  if (coordinates_valid == NO)
    [self _rebuildCoordinates];
  if (needs_display)
    invalidRect = NSIntersectionRect(invalidRect, visibleRect);
  return visibleRect;
}

- (void) setNeedsDisplay: (BOOL)flag
{
  if (flag)
    {
      [self setNeedsDisplayInRect: bounds];
    }
  else
    {
      needs_display = NO;
      invalidRect = NSZeroRect;
    }
}

- (void) setNeedsDisplayInRect: (NSRect)rect
{
  /*
   *	Limit to bounds, combine with old invalidRect, and then check to see
   *	if the result is the same as the old invalidRect - if it isn't then
   *	set the new invalidRect.
   */
  rect = NSIntersectionRect(rect, bounds);
  rect = NSUnionRect(invalidRect, rect);
  if (NSEqualRects(rect, invalidRect) == NO)
    {
      NSView	*firstOpaque = [self opaqueAncestor];
      NSView	*currentView = super_view;

      needs_display = YES;
      invalidRect = rect;
      if (firstOpaque == self)
	{
	  [window setViewsNeedDisplay: YES];
	}
      else
	{
	  rect = [firstOpaque convertRect: invalidRect fromView: self];
	  [firstOpaque setNeedsDisplayInRect: rect];
	}

      while (currentView)
	{
	  currentView->needs_display = YES;
	  currentView = currentView->super_view;
	}
    }
}

//
// Scrolling
//
- (NSRect)adjustScroll: (NSRect)newVisible
{
  return NSZeroRect;
}

- (BOOL)autoscroll: (NSEvent*)theEvent
{
  if (super_view)
    return [super_view autoscroll: theEvent];

  return NO;
}

- (void) reflectScrolledClipView: (NSClipView*)aClipView
{}

- (void) scrollClipView: (NSClipView*)aClipView toPoint: (NSPoint)aPoint
{}

- (void) scrollPoint: (NSPoint)aPoint
{}

- (void) scrollRect: (NSRect)aRect by: (NSSize)delta
{}

- (BOOL) scrollRectToVisible: (NSRect)aRect
{
  return NO;
}

//
// Managing the Cursor
//
// We utilize the tracking rectangle class
// to also maintain the cursor rects
//
- (void) addCursorRect: (NSRect)aRect cursor: (NSCursor*)anObject
{
  GSTrackingRect	*m;

  m = [[[GSTrackingRect alloc] initWithRect: aRect
					tag: 0
				      owner: anObject
				   userData: NULL
				     inside: YES] autorelease];
  [cursor_rects addObject: m];
}

- (void) discardCursorRects
{
  [cursor_rects removeAllObjects];
}

- (void) removeCursorRect: (NSRect)aRect cursor: (NSCursor*)anObject
{
  id e = [cursor_rects objectEnumerator];
  GSTrackingRect	*o;
  NSCursor		*c;

  o = [e nextObject];				// Base remove test
  while (o)					// upon cursor object
    {
      c = [o owner];
      if (c == anObject)
	{
	  [cursor_rects removeObject: o];
	  break;
	}
      else
	o = [e nextObject];
    }
}

- (void) resetCursorRects
{}

- (id) viewWithTag: (int)aTag
{
  unsigned i, count;

  count = [sub_views count];
  if (count > 0)
    {
      NSView*	array[count];

      [sub_views getObjects: array];

      for (i = 0; i < count; ++i)
	{
	  NSView *view = array[i];

	  if ([view tag] == aTag)
	    return view;
	}
    }

  return nil;
}

//
// Aiding Event Handling
//
- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return NO;
}

- (NSView*) hitTest: (NSPoint)aPoint
{
  NSPoint p;
  unsigned count;
  NSView *v = nil, *w;

  // If not within our frame then immediately return
  if (![self mouse: aPoint inRect: frame])
    return nil;

  p = [self convertPoint: aPoint fromView: super_view];

  count = [sub_views count];			// Check our sub_views
  if (count > 0)
    {
      NSView*	array[count];

      [sub_views getObjects: array];

      while (count > 0)
	{
	  w = array[--count];
	  v = [w hitTest: p];
	  if (v)
	    break;
	}
    }
  if (v)		// mouse is either in the subview or within self
    return v;
  else
    return self;
}

- (BOOL) mouse: (NSPoint)aPoint inRect: (NSRect)aRect
{
  if (aPoint.x < aRect.origin.x)
    return NO;
  if (aPoint.y < aRect.origin.y)
    return NO;
  if (aPoint.x > (aRect.origin.x + aRect.size.width))
    return NO;
  if (aPoint.y > (aRect.origin.y + aRect.size.height))
    return NO;

  return YES;
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  return NO;
}

- (void) removeTrackingRect: (NSTrackingRectTag)tag
{
  unsigned i, j;
  GSTrackingRect	*m;

  j = [tracking_rects count];
  for (i = 0;i < j; ++i)
    {
      m = (GSTrackingRect*)[tracking_rects objectAtIndex: i];
      if ([m tag] == tag)
	{
	  [tracking_rects removeObjectAtIndex: i];

	  return;
	}
    }
}

- (BOOL) shouldDelayWindowOrderingForEvent: (NSEvent*)anEvent
{
  return NO;
}

- (NSTrackingRectTag) addTrackingRect: (NSRect)aRect
				owner: (id)anObject
			     userData: (void*)data
			 assumeInside: (BOOL)flag
{
  NSTrackingRectTag t;
  unsigned i, j;
  GSTrackingRect	*m;

  t = 0;
  j = [tracking_rects count];
  for (i = 0; i < j; ++i)
    {
      m = (GSTrackingRect*)[tracking_rects objectAtIndex: i];
      if ([m tag] > t)
	t = [m tag];
    }
  ++t;

  m = [[[GSTrackingRect alloc] initWithRect: aRect
				        tag: t
				      owner: anObject
				   userData: data
				     inside: flag] autorelease];
  [tracking_rects addObject: m];

  return t;
}

- (NSArray*) trackingRectangles
{
  return tracking_rects;
}

//
// Dragging
//
- (BOOL) dragFile: (NSString*)filename
	 fromRect: (NSRect)rect
       	slideBack: (BOOL)slideFlag
	    event: (NSEvent*)event
{
  return NO;
}

- (void) dragImage: (NSImage*)anImage
	        at: (NSPoint)viewLocation
	    offset: (NSSize)initialOffset
	     event: (NSEvent*)event
        pasteboard: (NSPasteboard*)pboard
	    source: (id)sourceObject
	 slideBack: (BOOL)slideFlag
{}

- (void) registerForDraggedTypes: (NSArray*)newTypes
{}

- (void) unregisterDraggedTypes
{}

//
// Printing
//
- (NSData*) dataWithEPSInsideRect: (NSRect)aRect
{
  return nil;
}

- (void) fax: (id)sender
{
}

- (void) print: (id)sender
{
}

- (void) writeEPSInsideRect: (NSRect)rect
	       toPasteboard: (NSPasteboard*)pasteboard
{
}

//
// Pagination
//
- (void) adjustPageHeightNew: (float*)newBottom
			 top: (float)oldTop
		      bottom: (float)oldBottom
		       limit: (float)bottomLimit
{
}

- (void) adjustPageWidthNew: (float*)newRight
		       left: (float)oldLeft
		      right: (float)oldRight
		      limit: (float)rightLimit
{
}

- (float) heightAdjustLimit
{
  return 0;
}

- (BOOL) knowsPagesFirst: (int*)firstPageNum last: (int*)lastPageNum
{
  return NO;
}

- (NSPoint) locationOfPrintRect: (NSRect)aRect
{
  return NSZeroPoint;
}

- (NSRect) rectForPage: (int)page
{
  return NSZeroRect;
}

- (float) widthAdjustLimit
{
  return 0;
}

//
// Writing Conforming PostScript
//
- (void) beginPage: (int)ordinalNum
	     label: (NSString*)aString
	      bBox: (NSRect)pageRect
	     fonts: (NSString*)fontNames
{
}

- (void) beginPageSetupRect: (NSRect)aRect placement: (NSPoint)location
{
}

- (void) beginPrologueBBox: (NSRect)boundingBox
	      creationDate: (NSString*)dateCreated
		 createdBy: (NSString*)anApplication
		     fonts: (NSString*)fontNames
		   forWhom: (NSString*)user
		     pages: (int)numPages
		     title: (NSString*)aTitle
{
}

- (void) addToPageSetup
{
}

- (void) beginSetup
{
}				// not implemented

- (void) beginTrailer
{
}

- (void) drawPageBorderWithSize: (NSSize)borderSize
{
}

- (void) drawSheetBorderWithSize: (NSSize)borderSize
{
}

- (void) endHeaderComments
{
}

- (void) endPrologue
{
}

- (void) endSetup
{
}

- (void) endPageSetup
{
}

- (void) endPage
{
}

- (void) endTrailer
{
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  NSDebugLLog(@"NSView", @"NSView: start encoding\n");
  [aCoder encodeRect: frame];
  [aCoder encodeRect: bounds];
  [aCoder encodeConditionalObject: super_view];
  [aCoder encodeObject: sub_views];
  [aCoder encodeConditionalObject: window];
  [aCoder encodeObject: tracking_rects];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_rotated_from_base];
  [aCoder encodeValueOfObjCType: @encode(BOOL)
	  at: &is_rotated_or_scaled_from_base];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &needs_display];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &disable_autodisplay];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &post_frame_changes];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &autoresize_subviews];
  NSDebugLLog(@"NSView", @"NSView: finish encoding\n");
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  NSDebugLLog(@"NSView", @"NSView: start decoding\n");
  frame = [aDecoder decodeRect];
  bounds = [aDecoder decodeRect];
  super_view = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &sub_views];
  window = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &tracking_rects];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_rotated_from_base];
  [aDecoder decodeValueOfObjCType: @encode(BOOL)
	  at: &is_rotated_or_scaled_from_base];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &needs_display];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &disable_autodisplay];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &post_frame_changes];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &autoresize_subviews];
  NSDebugLLog(@"NSView", @"NSView: finish decoding\n");

  return self;
}

//
// Accessor methods
//
- (void) setAutoresizesSubviews: (BOOL)flag
{
  autoresize_subviews = flag;
}

- (void) setAutoresizingMask: (unsigned int)mask
{
  autoresizingMask = mask;
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) autoresizesSubviews
{
  return autoresize_subviews;
}

- (unsigned int) autoresizingMask
{
  return autoresizingMask;
}

- (NSMutableArray*) subviews
{
  return sub_views;
}

- (NSView*) superview
{
  return super_view;
}

- (BOOL) shouldDrawColor
{
  return YES;
}

- (BOOL) isOpaque
{
  return NO;
}

- (BOOL) needsDisplay
{
  return needs_display;
}

- (int) tag
{
  return -1;
}

- (NSArray*) cursorRectangles
{
  return cursor_rects;
}

- (BOOL) isFlipped
{
  return NO;
}

- (NSRect) bounds
{
  return bounds;
}

- (NSRect) frame
{
  return frame;
}

- (float) boundsRotation
{
  return [boundsMatrix rotationAngle];
}

- (float) frameRotation
{
  return [frameMatrix rotationAngle];
}

- (BOOL) postsFrameChangedNotifications
{
  return post_frame_changes;
}

- (BOOL) postsBoundsChangedNotifications
{
  return post_bounds_changes;
}


/*
 *	Private methods.
 */


/*
 *	The [-_invalidateCoordinates] method marks the coordinate mapping
 *	matrices (matrixFromWindof and matrixToWindow) and the cached visible
 *	rectangle as invalid.  It recursively invalidates the coordinates for
 *	all subviews as well.
 *	This method must be called whenever the size, shape or position of
 *	the view is changed in any way.
 */
- (void) _invalidateCoordinates
{
  if (coordinates_valid == YES)
    {
      unsigned	count;

      coordinates_valid = NO;
      count = [sub_views count];
      if (count > 0)
	{
	  NSView*	array[count];
	  unsigned	i;

	  [sub_views getObjects: array];
	  for (i = 0; i < count; i++)
	    {
	      NSView	*sub = array[i];

	      if (sub->coordinates_valid == YES)
		(*invalidateImp)(sub, invalidateSel);
	    }
	}
    }
}

/*
 *	The [-_matrixFromWindow] method returns a matrix that can be used to
 *	map coordinates in the windows coordinate system to coordinates in the
 *	views coordinate system.  It rebuilds the mapping matrices and
 *	visible rectangle cache if necessary.
 *	All coordinate transformations use this matrix.
 */
- (NSAffineTransform*) _matrixFromWindow
{
  if (coordinates_valid == NO)
    [self _rebuildCoordinates];
  return matrixFromWindow;
}

/*
 *	The [-_matrixToWindow] method returns a matrix that can be used to
 *	map coordinates in the views coordinate system to coordinates in the
 *	windows coordinate system.  It rebuilds the mapping matrices and
 *	visible rectangle cache if necessary.
 *	All coordinate transformations use this matrix.
 */
- (NSAffineTransform*) _matrixToWindow
{
  if (coordinates_valid == NO)
    [self _rebuildCoordinates];
  return matrixToWindow;
}

/*
 *	The [-_rebuildCoordinates] method rebuilds the coordinate mapping
 *	matrices (matrixFromWindof and matrixToWindow) and the cached visible
 *	rectangle if they have been invalidated.
 */
- (void) _rebuildCoordinates
{
  if (coordinates_valid == NO)
    {
      coordinates_valid = YES;
      if (!window)
	{
	  visibleRect = NSZeroRect;
	  [matrixToWindow makeIdentityMatrix];
	  [matrixFromWindow makeIdentityMatrix];
	}
      if (!super_view)
	{
	  visibleRect = bounds;
	  [matrixToWindow makeIdentityMatrix];
	  [matrixFromWindow makeIdentityMatrix];
	}
      else
	{
	  NSRect	superviewsVisibleRect;
	  BOOL		wasFlipped = [super_view isFlipped];
	  float		vals[6];
	  NSAffineTransform	*pMatrix = [super_view _matrixToWindow];

	  [pMatrix getMatrix: vals];
	  [matrixToWindow setMatrix: vals];
	  (*appImp)(matrixToWindow, appSel, frameMatrix);
	  if ([self isFlipped] != wasFlipped)
	    {
	      /*
	       * The flipping process must result in a coordinate system that
	       * exactly overlays the original.  To do that, we must translate
	       * the origin by the height of the view.
	       */
	      flip->matrix.ty = bounds.size.height;
	      (*appImp)(matrixToWindow, appSel, flip);
	    }
	  (*appImp)(matrixToWindow, appSel, boundsMatrix);
	  [matrixToWindow getMatrix: vals];
	  [matrixFromWindow setMatrix: vals];
	  [matrixFromWindow inverse];

	  superviewsVisibleRect = [self convertRect: [super_view visibleRect]
					   fromView: super_view];

	  visibleRect = NSIntersectionRect(superviewsVisibleRect, bounds);
	}
    }
}

@end

