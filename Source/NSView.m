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
#include <AppKit/PSMatrix.h>



@implementation NSView

//
//  Class variables
//
static NSString	*viewThreadKey = @"NSViewThreadKey";

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSView class])
		{
		NSDebugLog(@"Initialize NSView class\n");
		[self setVersion:1];								// Initial version
		}
}

/*
 * return the view at the top of thread's focus stack
 * or nil if none is focused
 */
+ (NSView *) focusView
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  NSMutableArray *stack = [dict objectForKey: viewThreadKey];
  NSView *current_view = nil;

  if (stack)
    {
      unsigned count = [stack count];

      if (count > 0)
        current_view = [stack objectAtIndex: --count];
    }

  return current_view;
}


+ (void) pushFocusView: (NSView *)focusView
{
  if (focusView)
    {
      NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
      NSMutableArray *stack = [dict objectForKey: viewThreadKey];

      if (stack == nil)
        {
          stack = [[NSMutableArray alloc] initWithCapacity: 4];
          [dict setObject: stack forKey: viewThreadKey];
          [stack release];
        }
      [stack addObject: focusView];
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt to push a 'nil' focus view on to stack."];
    }
}


/*
 *	Remove the top focusView for the current thread from the stack
 *	and return the new focusView (or nil if the stack is now empty).
 */
+ (NSView *)popFocusView
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  NSMutableArray *stack = [dict objectForKey: viewThreadKey];
  NSView *v = nil;

  if (stack)
    {
      unsigned count = [stack count];

      if (count > 0)
        {
          [stack removeObjectAtIndex: --count];
        }
      if (count > 0)
        {
          v = [stack objectAtIndex: --count];
        }
    }
  return v;
}

//
// Instance methods
//
- init
{
	return [self initWithFrame:NSZeroRect];
}

- (id)initWithFrame:(NSRect)frameRect
{
	[super init];										// super is NSResponder

	frame = frameRect;									// Set frame rectangle
	bounds.origin = NSZeroPoint;						// Set bounds rectangle
	bounds.size = frame.size;

	frameMatrix = [PSMatrix new];						// init PS matrix for
	boundsMatrix = [PSMatrix new];						// frame and bounds
	[frameMatrix setFrameOrigin:frame.origin];
														// initialize lists of:
	sub_views = [NSMutableArray new];					// subviews
	tracking_rects = [NSMutableArray new];				// tracking rectangles
	cursor_rects = [NSMutableArray new];				// cursor rectangles

	super_view = nil;
	window = nil;
	is_rotated_from_base = NO;
	is_rotated_or_scaled_from_base = NO;
	disable_autodisplay = NO;
	needs_display = YES;
	post_frame_changes = NO;
	autoresize_subviews = YES;
	autoresizingMask = NSViewNotSizable;

	return self;
}

- (void)dealloc
{
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

  if ([self isDescendantOf:aView])
    {
      NSLog(@"addSubview:positioned:relativeTo: will create a cycle "
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
}													// window it has moved to

- (NSView *)ancestorSharedWithView:(NSView *)aView
{
	if (self == aView)								// Are they the same view?
		return self;

	if ([self isDescendantOf: aView])				// Is self a descendant of
		return aView;								// view?

	if ([aView isDescendantOf: self])				// Is view a descendant of
		return self;								// self?

	if (![self superview])			// If neither are descendants of each other
		return nil;					// and either does not have a superview
	if (![aView superview])			// then they cannot have a common ancestor
		return nil;
									// Find the common ancestor of superviews
	return [[self superview] ancestorSharedWithView: [aView superview]];
}

- (BOOL)isDescendantOf:(NSView *)aView
{
	if (aView == self) 								// Quick check
		return YES;

	if (!super_view) 								// No superview then this
		return NO;									// is end of the line

	if (super_view == aView)
		return YES;

	return [super_view isDescendantOf:aView];
}

- (NSView *)opaqueAncestor
{
	if ([self isOpaque] || !super_view)
		return self;
	else
		return [super_view opaqueAncestor];
}

- (void) removeFromSuperviewWithoutNeedinfDisplay
{
  NSMutableArray *views;

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
  NSMutableArray *views;
  NSWindow *win;

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
   * call [super replaceSubview:with:] safely.
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

- (void)sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare
						  context:(void *)context
{
	[sub_views sortUsingFunction:compare context:context];
}

- (void) viewWillMoveToSuperview: (NSView*)newSuper
{
  super_view = newSuper;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
int i, count;

	window = newWindow;

	count = [sub_views count];							// Pass new window down
	for (i = 0; i < count; ++i)							// to subviews
		[[sub_views objectAtIndex:i] viewWillMoveToWindow:newWindow];
}

- (void)rotateByAngle:(float)angle
{
	[boundsMatrix rotateByAngle:angle];
	is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)setFrame:(NSRect)frameRect
{
NSSize old_size = frame.size;

	frame = frameRect;
	bounds.size = frame.size;
	[frameMatrix setFrameOrigin:frame.origin];

	[self resizeSubviewsWithOldSize: old_size];			// Resize the subviews
	if (post_frame_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewFrameDidChangeNotification
						object:self];
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
	frame.origin = newOrigin;
	[frameMatrix setFrameOrigin:frame.origin];

	if (post_frame_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewFrameDidChangeNotification
						object:self];
}

- (void)setFrameSize:(NSSize)newSize
{
NSSize old_size = frame.size;

	frame.size = bounds.size = newSize;

	[self resizeSubviewsWithOldSize: old_size];			// Resize the subviews
	if (post_frame_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewFrameDidChangeNotification
						object:self];
}

- (void)setFrameRotation:(float)angle
{
	[frameMatrix setFrameRotation:angle];
	is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

	if (post_frame_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewFrameDidChangeNotification
						object:self];
}

- (BOOL)isRotatedFromBase
{
	if (is_rotated_from_base)
		return is_rotated_from_base;
	else
		if (super_view)
			return [super_view isRotatedFromBase];
		else
			return NO;
}

- (BOOL)isRotatedOrScaledFromBase
{
	if (is_rotated_or_scaled_from_base)
		return is_rotated_or_scaled_from_base;
	else
		if (super_view)
			return [super_view isRotatedOrScaledFromBase];
		else
			return NO;
}

- (void)scaleUnitSquareToSize:(NSSize)newSize
{
	if (!newSize.width)
		newSize.width = 1;
	if (!newSize.height)
		newSize.height = 1;

	bounds.size.width = frame.size.width / newSize.width;
	bounds.size.height = frame.size.height / newSize.height;

	is_rotated_or_scaled_from_base = YES;

	[boundsMatrix scaleBy:frame.size.width / bounds.size.width
						 :frame.size.height / bounds.size.height];

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)setBounds:(NSRect)aRect
{
float sx, sy;

  if (aRect.size.width <= 0 || aRect.size.height <= 0)
    [NSException raise: NSInvalidArgumentException
		format: @"illegal bounds size supplied"];
	bounds = aRect;
	[boundsMatrix setFrameOrigin: NSMakePoint(-bounds.origin.x,
												-bounds.origin.y)];
	sx = frame.size.width / bounds.size.width;
	sy = frame.size.height / bounds.size.height;
	[boundsMatrix scaleTo:sx :sy];

	if (sx != 1 || sy != 1)
		is_rotated_or_scaled_from_base = YES;

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)setBoundsOrigin:(NSPoint)newOrigin			// translate bounds origin
{													// in opposite direction so
	bounds.origin = newOrigin;						// that newOrigin becomes
													// the origin when viewed.
	[boundsMatrix setFrameOrigin:NSMakePoint(-newOrigin.x, -newOrigin.y)];

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)setBoundsSize:(NSSize)newSize
{
float sx, sy;

  if (newSize.width <= 0 || newSize.height <= 0)
    [NSException raise: NSInvalidArgumentException
		format: @"illegal bounds size supplied"];
	bounds.size = newSize;
	sx = frame.size.width / bounds.size.width;
	sy = frame.size.height / bounds.size.height;
	[boundsMatrix scaleTo:sx :sy];

	if (sx != 1 || sy != 1)
		is_rotated_or_scaled_from_base = YES;

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)setBoundsRotation:(float)angle
{
	[boundsMatrix setFrameRotation:angle];
	is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (void)translateOriginToPoint:(NSPoint)point
{
	[boundsMatrix translateToPoint:point];

	if (post_bounds_changes)
		[[NSNotificationCenter defaultCenter]
						postNotificationName:NSViewBoundsDidChangeNotification
						object:self];
}

- (NSRect)centerScanRect:(NSRect)aRect
{
	return NSZeroRect;
}

- (PSMatrix*) _concatenateMatricesInReverseOrderFromPath: (NSArray*)viewsPath
{
  unsigned	i = [viewsPath count];
  PSMatrix	*matrix = [[PSMatrix new] autorelease];
  NSView	*parent;
  BOOL		wasFlipped;
  BOOL		isFlipped;

  if (i-- < 2)
    return matrix;
  parent = [viewsPath objectAtIndex: i];
  wasFlipped = [parent isFlipped];
  while (i-- > 0)
    {
      NSView	*view = [viewsPath objectAtIndex: i];

      [matrix concatenateWith: view->frameMatrix];
      isFlipped = [view isFlipped];
      if (isFlipped != wasFlipped)
	{
	  PSMatrix	*flip = nil;
	  float		vals[6] = { 1, 0, 0, -1, 0, 1 };

	  vals[5] = view->bounds.size.height;
	  flip = [PSMatrix matrixFrom: vals];
	  [matrix concatenateWith: flip];
	}
      [matrix concatenateWith: view->boundsMatrix];
      parent = view;
      wasFlipped = isFlipped;
    }

  return matrix;
}

- (NSMutableArray*) _pathBetweenSubview: (NSView*)subview
			    toSuperview: (NSView*)_superview
{
  NSMutableArray	*array = [NSMutableArray array];
  NSView		*view = subview;

  while (view && view != _superview)
    {
      [array addObject:view];
      view = view->super_view;
    }

  return array;
}

- (NSPoint) convertPoint: (NSPoint)aPoint fromView: (NSView*)aView
{
  NSPoint	new;
  PSMatrix	*matrix;

  if (!aView)
    aView = [window contentView];

  if ([self isDescendantOf: aView])
    {
      NSMutableArray	*path;

      path = [self _pathBetweenSubview: self toSuperview: aView];
      [path addObject: aView];
      matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
      [matrix inverse];
      new = [matrix pointInMatrixSpace:aPoint];
    }
  else if ([aView isDescendantOf: self])
    {
      NSMutableArray	*path;

      path = [self _pathBetweenSubview: aView toSuperview: self];
      [path addObject: self];
      matrix = [self _concatenateMatricesInReverseOrderFromPath: path];
      new = [matrix pointInMatrixSpace: aPoint];
    }
  else
    {
      new = [aView convertPoint: aPoint toView: nil];
      new = [self convertPoint: new fromView: nil];
    }

  return new;
}

- (NSPoint) convertPoint: (NSPoint)aPoint toView: (NSView*)aView
{
  if (!aView)
    aView = [window contentView];

  return [aView convertPoint: aPoint fromView: self];
}

- (NSRect) convertRect: (NSRect)aRect fromView: (NSView*)aView
{
  NSRect r;

  /* Must belong to the same window	*/
  if (aView && window != [aView window])
    return NSZeroRect;

  r = aRect;
  r.origin = [self convertPoint: r.origin fromView: aView];
  r.size = [self convertSize: r.size fromView: aView];
  if ([aView isFlipped] != [self isFlipped])
    r.origin.y -= r.size.height;

  return r;
}

- (NSRect) convertRect: (NSRect)aRect toView: (NSView*)aView
{
  NSRect r;

  /* Must belong to the same window	*/
  if (aView && window != [aView window])
    return NSZeroRect;

  r = aRect;
  r.origin = [self convertPoint: r.origin toView: aView];
  r.size = [self convertSize: r.size toView: aView];
  if ([aView isFlipped] != [self isFlipped])
    r.origin.y -= r.size.height;

  return r;
}

- (PSMatrix*)_concatenateBoundsMatricesInReverseOrderFromPath:(NSArray*)viewsPath
{
int i, count = [viewsPath count];
PSMatrix* matrix = [[PSMatrix new] autorelease];

	for (i = count - 1; i >= 0; i--)
		{
		NSView* view = [viewsPath objectAtIndex:i];

		[matrix concatenateWith:view->boundsMatrix];
		}

	return matrix;
}

- (NSSize)convertSize:(NSSize)aSize fromView:(NSView *)aView
{
NSSize new;
PSMatrix* matrix;

	if (!aView)
		aView = [window contentView];

	if ([self isDescendantOf:aView])
		{
		NSArray* path = [self _pathBetweenSubview:self toSuperview:aView];

		matrix = [self _concatenateBoundsMatricesInReverseOrderFromPath:path];
		[matrix inverse];
		new = [matrix sizeInMatrixSpace:aSize];
		}
	else
		if ([aView isDescendantOf:self])
			{
			NSArray* path = [self _pathBetweenSubview:aView toSuperview:self];

			matrix = [self
					  _concatenateBoundsMatricesInReverseOrderFromPath:path];
			new = [matrix sizeInMatrixSpace:aSize];
			}			// The views are not in the same hierarchy of views.
		else 			// Convert the point to window from the other's view
			{			// coordinates and then to our view coordinates.
			new = [aView convertSize:aSize toView:nil];
			new = [self convertSize:new fromView:nil];
			}

	return new;
}

- (NSSize)convertSize:(NSSize)aSize toView:(NSView *)aView
{
	if (!aView)
		aView = [window contentView];

	return [aView convertSize:aSize fromView:self];
}

- (void)setPostsFrameChangedNotifications:(BOOL)flag
{
	post_frame_changes = flag;
}

- (void)setPostsBoundsChangedNotifications:(BOOL)flag
{
	post_bounds_changes = flag;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize		// resize subviews only
{														// if we are supposed
id e, o;												// to and we have never
  														// been rotated
	if (![self autoresizesSubviews] && !is_rotated_from_base)
		return;

	e = [sub_views objectEnumerator];
	o = [e nextObject];
	while (o)
		{
		[o resizeWithOldSuperviewSize: oldSize];        // Resize the subview
		o = [e nextObject];
		}
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
float change, changePerOption;
int options = 0;
NSSize old_size = frame.size;
NSSize superViewFrameSize = [super_view frame].size;
BOOL changedOrigin = NO;
BOOL changedSize = NO;
														// do nothing if view
	if (autoresizingMask == NSViewNotSizable)			// is not resizable
		return;
														// determine if and how
	if (autoresizingMask & NSViewWidthSizable)			// the X axis can be
		options++;										// resized
	if (autoresizingMask & NSViewMinXMargin)
		options++;
	if (autoresizingMask & NSViewMaxXMargin)
		options++;
														// adjust the X axis if
	if (options >= 1)									// any X options are
		{												// set in the mask
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
														// determine if and how
	options = 0;										// the Y axis can be
	if (autoresizingMask & NSViewHeightSizable)			// resized
		options++;
	if (autoresizingMask & NSViewMinYMargin)
		options++;
	if (autoresizingMask & NSViewMaxYMargin)
		options++;
														// adjust the Y axis if
	if (options >= 1)									// any Y options are
		{												// set in the mask
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
		if (autoresizingMask & NSViewMinYMargin)
			{
			frame.origin.y += changePerOption;
			changedOrigin = YES;
			}
		}

	if (changedOrigin)
		[frameMatrix setFrameOrigin: frame.origin];

	if (changedSize && is_rotated_or_scaled_from_base)
		{
		float sx = frame.size.width / bounds.size.width;
		float sy = frame.size.height / bounds.size.height;

		[boundsMatrix scaleTo: sx : sy];
		}

	if (changedSize || changedOrigin)
		[self resizeSubviewsWithOldSize: old_size];
}

- (void)allocateGState					{}				// implemented by the
- (void)releaseGState					{}				// back end
- (int)gState							{ return 0; }
- (void)renewGState						{}
- (void)setUpGState						{}
- (void)lockFocus						{ [self subclassResponsibility:_cmd]; }
- (void)unlockFocus						{ [self subclassResponsibility:_cmd]; }

- (BOOL)canDraw
{														// not implemented per
	if (window) 											// OS spec FIX ME
		return YES;
	else
		return NO;
}

- (void) display
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
      NSRect	rect;

      rect = NSIntersectionRect(aRect, invalidRect);
      if (NSIsEmptyRect(rect) == NO)
	{
	  [self lockFocus];
	  [self drawRect: rect];
	  [self unlockFocus];

	  for (i = 0, count = [sub_views count]; i < count; i++)
	    {
	      NSRect intersection;
	      NSView *subview = [sub_views objectAtIndex: i];
	      NSRect subviewFrame = subview->frame;

	      if ([subview->frameMatrix isRotated])
		{
		  [subview->frameMatrix boundingRectFor: subviewFrame
						 result: &subviewFrame];
		}
	      intersection = NSIntersectionRect(rect, subviewFrame);
	      if (NSIsEmptyRect(intersection) == NO)
		{
		  intersection = [subview convertRect: intersection
					     fromView: self];
		  [subview displayRectIgnoringOpacity: intersection];
		}
	      else
		{
		  if (subview->needs_display)
		    {
		      [subview displayIfNeededIgnoringOpacity];
		    }
		}
	      if (subview->needs_display)
		{
		  stillNeedsDisplay = YES;
		}
	    }

	  /*
	   *	If the rect we displayed contains the invalidRect
	   *	for the view then we can clear the invalidRect,
	   *	otherwise, we still need to be displayed.
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
	}
      else
	{
	  /*
	   *	We don't have an invalidRect - so it must be one of our
	   *	subviews that actually needs the display.
	   */
	  for (i = 0, count = [sub_views count]; i < count; i++)
	    {
	      NSView	*subview = [sub_views objectAtIndex: i];

	      if (subview->needs_display)
		{
		  NSRect	subviewFrame = subview->frame;
		  NSRect	intersection;

		  if ([subview->frameMatrix isRotated])
		    {
		      [subview->frameMatrix boundingRectFor: subviewFrame
						     result: &subviewFrame];
		    }
		  intersection = NSIntersectionRect(aRect, subviewFrame);
		  if (NSIsEmptyRect(intersection) == NO)
		    {
		      intersection = [subview convertRect: intersection
						 fromView: self];
		      [subview displayRectIgnoringOpacity: intersection];
		    }
		  if (subview->needs_display)
		    {
		      stillNeedsDisplay = YES;
		    }
		}
	    }
	}
      needs_display = stillNeedsDisplay;
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

  if (!boundsMatrix || !frameMatrix)
    NSLog (@"warning: %@ %p does not have it's PS matrices configured!",
	  			NSStringFromClass(isa), self);

  [self lockFocus];
  [self drawRect: aRect];
  [self unlockFocus];

  for (i = 0, count = [sub_views count]; i < count; ++i)
    {
      NSView	*subview = [sub_views objectAtIndex: i];
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

- (void)drawRect:(NSRect)rect
{}

- (NSRect)visibleRect
{
  if (!super_view)
    return bounds;
  else
    {
      NSRect superviewsVisibleRect;

      superviewsVisibleRect = [self convertRect: [super_view visibleRect]
				       fromView: super_view];

      return NSIntersectionRect(superviewsVisibleRect, bounds);
    }
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

- (NSRect) _boundingRectFor: (NSRect)rect
{
  NSRect new;

  [frameMatrix boundingRectFor: rect result: &new];

  return new;
}

//
// Scrolling
//
- (NSRect)adjustScroll:(NSRect)newVisible
{
	return NSZeroRect;
}

- (BOOL)autoscroll:(NSEvent *)theEvent
{
	if (super_view)
		return [super_view autoscroll:theEvent];

	return NO;
}

- (void)reflectScrolledClipView:(NSClipView *)aClipView
{}

- (void)scrollClipView:(NSClipView *)aClipView toPoint:(NSPoint)aPoint
{}

- (void)scrollPoint:(NSPoint)aPoint
{}

- (void)scrollRect:(NSRect)aRect by:(NSSize)delta
{}

- (BOOL)scrollRectToVisible:(NSRect)aRect
{
	return NO;
}

//
// Managing the Cursor
//
// We utilize the tracking rectangle class
// to also maintain the cursor rects
//
- (void)addCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject
{
GSTrackingRect *m;

	m = [[[GSTrackingRect alloc] initWithRect: aRect
								 tag: 0
								 owner: anObject
								 userData: NULL
								 inside: YES] autorelease];
	[cursor_rects addObject:m];
}

- (void)discardCursorRects
{
	[cursor_rects removeAllObjects];
}

- (void)removeCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject
{
id e = [cursor_rects objectEnumerator];
GSTrackingRect *o;
NSCursor *c;

	o = [e nextObject];									// Base remove test
	while (o) 											// upon cursor object
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

- (void)resetCursorRects
{}

- (id)viewWithTag:(int)aTag
{
int i, count;

	count = [sub_views count];
	for (i = 0; i < count; ++i)
		{
		id view = [sub_views objectAtIndex:i];

		if ([view tag] == aTag)
			return view;
		}

	return nil;
}

//
// Aiding Event Handling
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return NO;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
NSPoint p;
int i, count;
NSView *v = nil, *w;
													// If not within our frame
	if (![self mouse:aPoint inRect:frame])			// then immediately return
		return nil;

	p = [self convertPoint:aPoint fromView:super_view];

	count = [sub_views count];						// Check our sub_views
	for (i = count - 1; i >= 0; i--)
		{
		w = [sub_views objectAtIndex:i];
		v = [w hitTest:p];
		if (v)
			break;
		}

	if (v)											// mouse is either in the
		return v;									// subview or within self
	else
		return self;
}

- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect
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

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	return NO;
}

- (void)removeTrackingRect:(NSTrackingRectTag)tag
{
int i, j;
GSTrackingRect *m;

	j = [tracking_rects count];
	for (i = 0;i < j; ++i)
		{
		m = (GSTrackingRect *)[tracking_rects objectAtIndex:i];
		if ([m tag] == tag)
			{
			[tracking_rects removeObjectAtIndex:i];

			return;
			}
		}
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent
{
	return NO;
}

- (NSTrackingRectTag)addTrackingRect:(NSRect)aRect
							   owner:(id)anObject
							   userData:(void *)data
							   assumeInside:(BOOL)flag
{
NSTrackingRectTag t;
int i, j;
GSTrackingRect *m;

	t = 0;
	j = [tracking_rects count];
	for (i = 0;i < j; ++i)
		{
		m = (GSTrackingRect *)[tracking_rects objectAtIndex:i];
		if ([m tag] > t)
			t = [m tag];
		}
	++t;

	m = [[[GSTrackingRect alloc] initWithRect:aRect
								 tag:t owner:anObject
								 userData:data
								 inside:flag] autorelease];
	[tracking_rects addObject:m];

	return t;
}

- (NSArray *)trackingRectangles
{
	return tracking_rects;
}

//
// Dragging
//
- (BOOL)dragFile:(NSString *)filename
		fromRect:(NSRect)rect
       	slideBack:(BOOL)slideFlag
	   	event:(NSEvent *)event
{
	return NO;
}

- (void)dragImage:(NSImage *)anImage					// initiate a dragging
			   at:(NSPoint)viewLocation					// session (backend)
			   offset:(NSSize)initialOffset
			   event:(NSEvent *)event
			   pasteboard:(NSPasteboard *)pboard
			   source:(id)sourceObject
			   slideBack:(BOOL)slideFlag
{}

- (void)registerForDraggedTypes:(NSArray *)newTypes
{}

- (void)unregisterDraggedTypes
{}

//
// Printing
//
- (NSData *)dataWithEPSInsideRect:(NSRect)aRect
{
	return nil;
}

- (void)fax:(id)sender						{}
- (void)print:(id)sender					{}
- (void)writeEPSInsideRect:(NSRect)rect toPasteboard:(NSPasteboard *)pasteboard
{}

//
// Pagination
//
- (void)adjustPageHeightNew:(float *)newBottom
						top:(float)oldTop
						bottom:(float)oldBottom
						limit:(float)bottomLimit
{}

- (void)adjustPageWidthNew:(float *)newRight
					  left:(float)oldLeft
					  right:(float)oldRight
					  limit:(float)rightLimit
{}

- (float)heightAdjustLimit
{
	return 0;
}

- (BOOL)knowsPagesFirst:(int *)firstPageNum last:(int *)lastPageNum
{
	return NO;
}

- (NSPoint)locationOfPrintRect:(NSRect)aRect
{
	return NSZeroPoint;
}

- (NSRect)rectForPage:(int)page
{
	return NSZeroRect;
}

- (float)widthAdjustLimit
{
	return 0;
}

//
// Writing Conforming PostScript
//
- (void)beginPage:(int)ordinalNum
			label:(NSString *)aString
			bBox:(NSRect)pageRect
			fonts:(NSString *)fontNames
{}

- (void)beginPageSetupRect:(NSRect)aRect placement:(NSPoint)location
{}

- (void)beginPrologueBBox:(NSRect)boundingBox
			 creationDate:(NSString *)dateCreated
			 createdBy:(NSString *)anApplication
		     fonts:(NSString *)fontNames
			 forWhom:(NSString *)user
		     pages:(int)numPages
		     title:(NSString *)aTitle
{}

- (void)addToPageSetup					{}
- (void)beginSetup						{}				// not implemented
- (void)beginTrailer					{}
- (void)drawPageBorderWithSize:(NSSize)borderSize		{}
- (void)drawSheetBorderWithSize:(NSSize)borderSize		{}
- (void)endHeaderComments				{}
- (void)endPrologue						{}
- (void)endSetup						{}
- (void)endPageSetup					{}
- (void)endPage							{}
- (void)endTrailer						{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  NSDebugLog(@"NSView: start encoding\n");
  [aCoder encodeRect: frame];
  [aCoder encodeRect: bounds];
  [aCoder encodeConditionalObject:super_view];
  [aCoder encodeObject: sub_views];
  [aCoder encodeConditionalObject:window];
  [aCoder encodeObject: tracking_rects];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_rotated_from_base];
  [aCoder encodeValueOfObjCType:@encode(BOOL)
	  at: &is_rotated_or_scaled_from_base];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &needs_display];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &disable_autodisplay];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &post_frame_changes];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &autoresize_subviews];
  NSDebugLog(@"NSView: finish encoding\n");
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  NSDebugLog(@"NSView: start decoding\n");
  frame = [aDecoder decodeRect];
  bounds = [aDecoder decodeRect];
  super_view = [aDecoder decodeObject];
  sub_views = [aDecoder decodeObject];
  window = [aDecoder decodeObject];
  tracking_rects = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_rotated_from_base];
  [aDecoder decodeValueOfObjCType:@encode(BOOL)
	  at: &is_rotated_or_scaled_from_base];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &needs_display];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &disable_autodisplay];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &post_frame_changes];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &autoresize_subviews];
  NSDebugLog(@"NSView: finish decoding\n");

  return self;
}

//
// Accessor methods
//
- (void)setAutoresizesSubviews:(BOOL)flag		{ autoresize_subviews = flag; }
- (void)setAutoresizingMask:(unsigned int)mask	{ autoresizingMask = mask; }

- (NSWindow *)window							{ return window; }
- (BOOL)autoresizesSubviews						{ return autoresize_subviews; }
- (unsigned int)autoresizingMask				{ return autoresizingMask; }
- (NSMutableArray *)subviews					{ return sub_views; }
- (NSView *)superview							{ return super_view; }
- (BOOL)shouldDrawColor							{ return YES; }
- (BOOL)isOpaque								{ return NO; }
- (BOOL)needsDisplay							{ return needs_display; }
- (int)tag										{ return -1; }
- (NSArray *)cursorRectangles					{ return cursor_rects; }
- (BOOL)isFlipped								{ return NO; }
- (NSRect)bounds								{ return bounds; }
- (NSRect)frame									{ return frame; }
- (float)boundsRotation				{ return [boundsMatrix rotationAngle]; }
- (float)frameRotation				{ return [frameMatrix rotationAngle]; }
- (PSMatrix*)_boundsMatrix						{ return boundsMatrix; }
- (PSMatrix*)_frameMatrix						{ return frameMatrix; }
- (BOOL)postsFrameChangedNotifications			{ return post_frame_changes; }
- (BOOL)postsBoundsChangedNotifications			{ return post_bounds_changes; }

@end
