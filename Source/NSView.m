/* 
   NSView.m

   The view class which encapsulates all drawing functionality

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   Heavily changed and extended by Ovidiu Predescu <ovidiu@net-community.com>.
   Date: 1997
   
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
#include <AppKit/TrackingRectangle.h>
#include <AppKit/PSMatrix.h>

@implementation NSView

/* Class variables */
static NSMutableDictionary *gnustep_gui_nsview_thread_dict = nil;
static NSRecursiveLock *gnustep_gui_nsview_lock = nil;

+ (void)initialize
{
  if (self == [NSView class])
    {
      NSDebugLog(@"Initialize NSView class\n");

      // Initial version
      [self setVersion:1];

      // Allocate dictionary for maintaining
      // mapping of threads to focused views
      gnustep_gui_nsview_thread_dict = [NSMutableDictionary new];
      // Create lock for serializing access to dictionary
      gnustep_gui_nsview_lock = [[NSRecursiveLock alloc] init];
    }
}

//
// +++ Really each thread should have a stack!
//
+ (void)pushFocusView:(NSView *)focusView
{
  NSThread *current_thread = [NSThread currentThread];

  // Obtain lock so we can edit the dictionary
  [gnustep_gui_nsview_lock lock];

  // If no context then remove from dictionary
  if (!focusView)
    {
      [gnustep_gui_nsview_thread_dict removeObjectForKey: current_thread];
    }
  else
    {
      [gnustep_gui_nsview_thread_dict setObject: focusView 
				      forKey: current_thread];
    }

  [gnustep_gui_nsview_lock unlock];
}

+ (NSView *)popFocusView
{
  NSThread *current_thread = [NSThread currentThread];
  id v;

  // Obtain lock so we can edit the dictionary
  [gnustep_gui_nsview_lock lock];

  // Remove from dictionary
  v = [gnustep_gui_nsview_thread_dict objectForKey: current_thread];
  [gnustep_gui_nsview_thread_dict removeObjectForKey: current_thread];

  [gnustep_gui_nsview_lock unlock];
  return v;
}

+ (NSView *)focusView
{
  NSThread *current_thread = [NSThread currentThread];
  NSView *current_view = nil;

  // Get focused view for current thread
  [gnustep_gui_nsview_lock lock];

  // current_view is nil if no focused view
  current_view = [gnustep_gui_nsview_thread_dict objectForKey: current_thread];

  [gnustep_gui_nsview_lock unlock];

  return current_view;
}

- init
{
  return [self initWithFrame:NSZeroRect];
}

- (id)initWithFrame:(NSRect)frameRect
{
  // Our super is NSResponder
  [super init];

	// Set frame rectangle
  frame = frameRect;

  // Set bounds rectangle
  bounds.origin = NSZeroPoint;
  bounds.size = frame.size;

  frameMatrix = [PSMatrix new];
  boundsMatrix = [PSMatrix new];
  [frameMatrix setFrameOrigin:frame.origin];

	// Initialize subview list
  sub_views = [NSMutableArray new];

  // Initialize tracking rectangle list
  tracking_rects = [NSMutableArray new];

  // Initialize cursor rect list
  cursor_rects = [NSMutableArray new];

  super_view = nil;
  window = nil;
  is_rotated_from_base = NO;
  is_rotated_or_scaled_from_base = NO;
  disable_autodisplay = NO;
  needs_display = YES;
  post_frame_changes = NO;
  autoresize_subviews = YES;

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

- (void)addSubview:(NSView *)aView
{
  // make sure we aren't making ourself a subview of ourself or we're not
  // creating a cycle in the views hierarchy
  if ([self isDescendantOf:aView])
    {
      NSLog(@"Operation addSubview: will create a cycle in the views tree!\n");
      return;
    }

  // Add to our subview list
  [aView viewWillMoveToWindow:window];
  [aView setSuperview:self];
  [aView setNextResponder:self];
  [sub_views addObject:(id)aView];
}

/* This method needs to be worked out!!! */
- (void)addSubview:(NSView *)aView
	positioned:(NSWindowOrderingMode)place
	relativeTo:(NSView *)otherView
{
  // make sure we aren't making ourself a subview of ourself or we're not
  // creating a cycle in the views hierarchy
  if ([self isDescendantOf:aView])
    {
      NSLog(@"Operation addSubview:positioned:relativeTo: will create a cycle "
	    @"in the views tree!\n");
      return;
    }

  // Add to our subview list
  [sub_views addObject:(id)aView];
  [aView setSuperview:self];

	// Make ourselves the next responder of the view
  [aView setNextResponder:self];

  // Tell the view what window it has moved to
  [aView viewWillMoveToWindow:window];
}

- (NSView *)ancestorSharedWithView:(NSView *)aView
{
  // Are they the same?
  if (self == aView)
    return self;

  // Is self a descendant of view?
  if ([self isDescendantOf: aView])
    return aView;

  // Is view a descendant of self?
  if ([aView isDescendantOf: self])
    return self;

  // If neither are descendants of each other
  // and either does not have a superview
  // then they cannot have a common ancestor
  if (![self superview])
    return nil;
  if (![aView superview])
    return nil;

  // Find the common ancestor of superviews
  return [[self superview] ancestorSharedWithView: [aView superview]];
}

- (BOOL)isDescendantOf:(NSView *)aView
{
  // Quick check
  if (aView == self) return YES;

  // No superview then this is end of the line
  if (!super_view) return NO;

  if (super_view == aView) return YES;

  return [super_view isDescendantOf:aView];
}

- (NSView *)opaqueAncestor
{
  if ([self isOpaque] || !super_view)
    return self;
  else
    return [super_view opaqueAncestor];
}

- (void)removeFromSuperview
{
  NSMutableArray *views;

  // No superview then just return
  if (!super_view) return;

  [self viewWillMoveToWindow:nil];

  /* Remove the view from the linked list of views maintained by the super view
     so that the view will not receive an unneeded display message. */
  [super_view _removeSubviewFromViewsThatNeedDisplay:self];

  views = [super_view subviews];
  [views removeObjectIdenticalTo:self];
  super_view = nil;
}

- (void)replaceSubview:(NSView *)oldView
		  with:(NSView *)newView
{
  if (!newView)
    return;

  if (!oldView)
    [self addSubview:newView];
  else {
    int index = [sub_views indexOfObjectIdenticalTo:oldView];

    if (index != NSNotFound) {
      [oldView viewWillMoveToWindow:nil];
      [oldView setSuperview:nil];
      [newView setNextResponder:nil];

      /* Remove the view from the linked list of views so that the old view
         will not receive an unneeded display message. */
      [self _removeSubviewFromViewsThatNeedDisplay:oldView];

      [sub_views replaceObjectAtIndex:index withObject:newView];

      [newView viewWillMoveToWindow:window];
      [newView setSuperview:self];
      [newView setNextResponder:self];
    }
  }
}

- (void)sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare 
			  context:(void *)context
{
  [sub_views sortUsingFunction:compare context:context];
}

- (NSWindow *)window
{
  // If we don't know our window then ask our super_view
  if (!window)
    window = [super_view window];

  return window;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
  int i, count;

  window = newWindow;

  // Pass new window down to subviews
  count = [sub_views count];
  for (i = 0; i < count; ++i)
    [[sub_views objectAtIndex:i] viewWillMoveToWindow:newWindow];

}

- (void)rotateByAngle:(float)angle
{
  [boundsMatrix rotateByAngle:angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)setFrame:(NSRect)frameRect
{
  NSSize old_size = bounds.size;

  frame = frameRect;
  bounds.size = frame.size;
  [frameMatrix setFrameOrigin:frame.origin];

  // Resize subviews
  [self resizeSubviewsWithOldSize: old_size];
  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewFrameDidChangeNotification object:self];
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
  frame.origin = newOrigin;
  [frameMatrix setFrameOrigin:frame.origin];

  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewFrameDidChangeNotification object:self];

}

- (void)setFrameSize:(NSSize)newSize
{
  NSSize old_size = bounds.size;

  frame.size = bounds.size = newSize;

  // Resize subviews
  [self resizeSubviewsWithOldSize: old_size];
  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewFrameDidChangeNotification object:self];
}

- (void)setFrameRotation:(float)angle
{
  [frameMatrix setFrameRotation:angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_frame_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewFrameDidChangeNotification object:self];
}

- (BOOL)isRotatedFromBase
{
  if (is_rotated_from_base)
    return is_rotated_from_base;
  else if (super_view)
    return [super_view isRotatedFromBase];
  else
    return NO;
}

- (BOOL)isRotatedOrScaledFromBase
{
  if (is_rotated_or_scaled_from_base)
    return is_rotated_or_scaled_from_base;
  else if (super_view)
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
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)setBounds:(NSRect)aRect
{
  float sx, sy;

  bounds = aRect;
  [boundsMatrix setFrameOrigin:
		  NSMakePoint(-bounds.origin.x, -bounds.origin.y)];
  sx = frame.size.width / bounds.size.width;
  sy = frame.size.height / bounds.size.height;
  [boundsMatrix scaleTo:sx :sy];

  if (sx != 1 || sy != 1)
    is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)setBoundsOrigin:(NSPoint)newOrigin
{
  bounds.origin = newOrigin;
  /* We have to translate the origin of the bounds in the oposite direction
     so that the newOrigin becomes the origin when viewed. */
  [boundsMatrix setFrameOrigin:NSMakePoint(-newOrigin.x, -newOrigin.y)];

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)setBoundsSize:(NSSize)newSize
{
  float sx, sy;

  bounds.size = newSize;
  sx = frame.size.width / bounds.size.width;
  sy = frame.size.height / bounds.size.height;
  [boundsMatrix scaleTo:sx :sy];

  if (sx != 1 || sy != 1)
    is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)setBoundsRotation:(float)angle
{
  [boundsMatrix setFrameRotation:angle];
  is_rotated_from_base = is_rotated_or_scaled_from_base = YES;

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (void)translateOriginToPoint:(NSPoint)point
{
  [boundsMatrix translateToPoint:point];

  if (post_bounds_changes)
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

- (NSRect)centerScanRect:(NSRect)aRect
{
  return NSZeroRect;
}

- (PSMatrix*)_concatenateMatricesInReverseOrderFromPath:(NSArray*)viewsPath
{
  int i, count = [viewsPath count];
  PSMatrix* matrix = [[PSMatrix new] autorelease];

  for (i = count - 1; i >= 0; i--) {
    NSView* view = [viewsPath objectAtIndex:i];

    [matrix concatenateWith:view->frameMatrix];
    [matrix concatenateWith:view->boundsMatrix];
  }

  return matrix;
}

- (NSArray*)_pathBetweenSubview:(NSView*)subview
  toSuperview:(NSView*)_superview
{
  NSMutableArray* array = [NSMutableArray array];
  NSView* view = subview;

  while (view && view != _superview) {
    [array addObject:view];
    view = view->super_view;
  }

  return array;
}

- (NSPoint)convertPoint:(NSPoint)aPoint
	       fromView:(NSView*)aView
{
  NSPoint new;
  PSMatrix* matrix;

  if (!aView)
    aView = [[self window] contentView];

  if ([self isDescendantOf:aView]) {
    NSArray* path = [self _pathBetweenSubview:self toSuperview:aView];

    matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
    [matrix inverse];
    new = [matrix pointInMatrixSpace:aPoint];
  }
  else if ([aView isDescendantOf:self]) {
    NSArray* path = [self _pathBetweenSubview:aView toSuperview:self];

    matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
    new = [matrix pointInMatrixSpace:aPoint];
  }
  else {
    /* The views are not on the same hierarchy of views. Convert the point to
       window from the other's view coordinates and then to our view
       coordinates. */
    new = [aView convertPoint:aPoint toView:nil];
    new = [self convertPoint:new fromView:nil];
  }
  return new;
}

- (NSPoint)convertPoint:(NSPoint)aPoint
		 toView:(NSView *)aView
{
  if (!aView)
    aView = [[self window] contentView];

  return [aView convertPoint:aPoint fromView:self];
}

- (NSRect)convertRect:(NSRect)aRect
	     fromView:(NSView *)aView
{
  NSRect r;

  // Must belong to the same window
  if (aView && [self window] != [aView window])
    return NSZeroRect;

  r = aRect;
  r.origin = [self convertPoint:r.origin fromView:aView];
  r.size = [self convertSize:r.size fromView:aView];
  return r;
}

- (NSRect)convertRect:(NSRect)aRect
	       toView:(NSView *)aView
{
  NSRect r;

  // Must belong to the same window
  if (aView && [self window] != [aView window])
    return NSZeroRect;

  r = aRect;
  r.origin = [self convertPoint:r.origin toView:aView];
  r.size = [self convertSize:r.size toView:aView];
  return r;
}

- (PSMatrix*)_concatenateBoundsMatricesInReverseOrderFromPath:(NSArray*)viewsPath
{
  int i, count = [viewsPath count];
  PSMatrix* matrix = [[PSMatrix new] autorelease];

  for (i = count - 1; i >= 0; i--) {
    NSView* view = [viewsPath objectAtIndex:i];

    [matrix concatenateWith:view->boundsMatrix];
  }

  return matrix;
}

- (NSSize)convertSize:(NSSize)aSize
	     fromView:(NSView *)aView
{
  NSSize new;
  PSMatrix* matrix;

  if (!aView)
    aView = [[self window] contentView];

  if ([self isDescendantOf:aView]) {
    NSArray* path = [self _pathBetweenSubview:self toSuperview:aView];

    matrix = [self _concatenateBoundsMatricesInReverseOrderFromPath:path];
    [matrix inverse];
    new = [matrix sizeInMatrixSpace:aSize];
  }
  else if ([aView isDescendantOf:self]) {
    NSArray* path = [self _pathBetweenSubview:aView toSuperview:self];

    matrix = [self _concatenateBoundsMatricesInReverseOrderFromPath:path];
    new = [matrix sizeInMatrixSpace:aSize];
  }
  else {
    /* The views are not on the same hierarchy of views. Convert the point to
       window from the other's view coordinates and then to our view
       coordinates. */
    new = [aView convertSize:aSize toView:nil];
    new = [self convertSize:new fromView:nil];
  }
  return new;
}

- (NSSize)convertSize:(NSSize)aSize
	       toView:(NSView *)aView
{
  if (!aView)
    aView = [[self window] contentView];

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

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
  id e, o;

  // Are we suppose to resize our subviews?
  if (![self autoresizesSubviews])
    return;

  e = [sub_views objectEnumerator];
  o = [e nextObject];
  while (o)
    {
      NSRect b = [o bounds];
      NSSize old_size = b.size;

      // Resize the subview
      // Then tell it to resize its subviews
      [o resizeWithOldSuperviewSize: oldSize];
      [o resizeSubviewsWithOldSize: old_size];
      o = [e nextObject];
    }
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
  autoresize_subviews = flag;
}

- (void)setAutoresizingMask:(unsigned int)mask
{
  autoresizingMask = mask;
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{}

- (void)allocateGState
{}

- (void)releaseGState
{}

- (int)gState
{
  return 0;
}

- (void)renewGState
{}

- (void)setUpGState
{}

- (void)lockFocus
{
  NSView *s = [self superview];

  // lock our superview
  if (s)
    [s lockFocus];

  // push ourselves
  [[self class] pushFocusView: self];
}

- (void)unlockFocus
{
  NSView *s = [self superview];

  // unlock our superview
  if (s)
    [s unlockFocus];

  // pop ourselves
  [[self class] popFocusView];
}

- (BOOL)canDraw
{
  // TODO
  return YES;
}

- (void)_setNeedsFlush
{
  [window _setNeedsFlush];
}

- (void)display
{
  invalidatedRectangle = NSZeroRect;
  [self displayRect:bounds];
}

- (void)displayIfNeeded
{
  if (needs_display) {
    NSRect rect = invalidatedRectangle;

    invalidatedRectangle = NSZeroRect;
    [self displayRect:rect];
  }
}

- (void)displayIfNeededIgnoringOpacity
{
  if (needs_display) {
    NSRect rect = invalidatedRectangle;

    invalidatedRectangle = NSZeroRect;
    [self displayRect:rect];
  }
}

- (void)displayRect:(NSRect)rect
{
  int i, count;

  if (!boundsMatrix || !frameMatrix)
    NSLog (@"warning: %@ %p has not have the PS matrices setup!",
	  NSStringFromClass(isa), self);

  needs_display = NO;

  [self lockFocus];
  [self drawRect:rect];
  [window _setNeedsFlush];
//  [window _view:self needsFlushInRect:rect];
  [self unlockFocus];

  // Tell subviews to display
  for (i = 0, count = [sub_views count]; i < count; ++i) {
    NSView* subview = [sub_views objectAtIndex:i];
    NSRect subviewFrame = subview->frame;
    NSRect intersection;

    /* If the subview is rotated compute its bounding rectangle and use this
       one instead of the subview's frame. */
    if ([subview->frameMatrix isRotated])
      [subview->frameMatrix boundingRectFor:subviewFrame result:&subviewFrame];

    /* Determine if the subview's frame intersects "rect"
       so that we can display the subview. */
    intersection = NSIntersectionRect (rect, subviewFrame);
    if (intersection.origin.x || intersection.origin.y
	|| intersection.size.width || intersection.size.height) {
      /* Convert the intersection rectangle to the subview's coordinates */
      intersection = [subview convertRect:intersection fromView:self];
      [subview displayRect:intersection];
    }
  }
}

- (void)displayRectIgnoringOpacity:(NSRect)aRect
{}

- (void)drawRect:(NSRect)rect
{}

- (NSRect)visibleRect
{
  if (!super_view)
    return bounds;
  else {
    NSRect superviewsVisibleRect
	= [self convertRect:[super_view visibleRect] fromView:super_view];

    return NSIntersectionRect (superviewsVisibleRect, bounds);
  }
}

- (void)_addSubviewForNeedingDisplay:(NSView*)view
{
  NSView* currentView;

  /* Add view in the list of sibling subviews that need display. First
     check if view is not already there. */
  currentView = _subviewsThatNeedDisplay;
  while (currentView) {
    if (currentView == view)
      return;
    currentView = currentView->_nextSiblingSubviewThatNeedsDisplay;
  }

  /* view is not in the list of subviews that need display; add it.
     To do this concatenate the "view"'s list of siblings to the list of
     subviews. Find the last element in the "view"'s list of siblings and
     assign to its _nextSiblingSubviewThatNeedsDisplay ivar the first element
     of the subviews that need display list in self.
   */
  currentView = view;
  while (currentView->_nextSiblingSubviewThatNeedsDisplay)
    currentView = currentView->_nextSiblingSubviewThatNeedsDisplay;

  currentView->_nextSiblingSubviewThatNeedsDisplay = _subviewsThatNeedDisplay;
  _subviewsThatNeedDisplay = view;

  /* Now add recursively do the same algorithm with self. This way we'll create
     a subtree of views that need display inside the views hierarchy. */
  if (super_view)
    [super_view _addSubviewForNeedingDisplay:self];
}

- (void)_removeSubviewFromViewsThatNeedDisplay:(NSView*)view
{
  // If no subviews need to be displayed then
  // then view must not be among them
  if (!_subviewsThatNeedDisplay)
    return;

  /* Remove view from the list of subviews that need display */
  if (_subviewsThatNeedDisplay == view)
    {
      _subviewsThatNeedDisplay = view->_nextSiblingSubviewThatNeedsDisplay;
      [view _recursivelyResetNeedsDisplayInAllViews];
    }
  else {
    NSView* currentView;

    for (currentView = _subviewsThatNeedDisplay;
	 currentView && currentView->_nextSiblingSubviewThatNeedsDisplay;
	 currentView = currentView->_nextSiblingSubviewThatNeedsDisplay)
      if (currentView->_nextSiblingSubviewThatNeedsDisplay == view)
	{
	  currentView->_nextSiblingSubviewThatNeedsDisplay
	    = view->_nextSiblingSubviewThatNeedsDisplay;
	  [view _recursivelyResetNeedsDisplayInAllViews];
	  break;
	}
  }
}

- (void)setNeedsDisplay:(BOOL)flag
{
  needs_display = flag;
  if (needs_display) {
//    NSLog (@"NSView setNeedsDisplay:");
    invalidatedRectangle = bounds;
    [window _setNeedsDisplay];

    if (super_view)
      [super_view _addSubviewForNeedingDisplay:self];
  }
}

- (void)setNeedsDisplayInRect:(NSRect)rect
{
//  NSLog (@"NSView setNeedsDisplayInRect:");
  needs_display = YES;
  invalidatedRectangle = NSUnionRect (invalidatedRectangle, rect);
  [window _setNeedsDisplay];

    if (super_view)
      [super_view _addSubviewForNeedingDisplay:self];
}

- (void)_recursivelyResetNeedsDisplayInAllViews
{
  NSView* currentView = _subviewsThatNeedDisplay;
  NSView* nextView;

  while (currentView) {
    nextView = currentView->_nextSiblingSubviewThatNeedsDisplay;
    [currentView _recursivelyResetNeedsDisplayInAllViews];
    currentView->_nextSiblingSubviewThatNeedsDisplay = NULL;
    currentView = nextView;
  }
  _subviewsThatNeedDisplay = NULL;
  _nextSiblingSubviewThatNeedsDisplay = NULL;
}

- (void)_unconditionallyResetNeedsDisplayInAllViews
{
  int i, count;

  _subviewsThatNeedDisplay = NULL;
  _nextSiblingSubviewThatNeedsDisplay = NULL;

  if (!sub_views || !(count = [sub_views count]))
    return;

  for (i = 0; i < count; i++)
    [[sub_views objectAtIndex:i] _unconditionallyResetNeedsDisplayInAllViews];
}

- (void)_displayNeededViews
{
  NSView* subview;

  if (needs_display)
    [self displayIfNeeded];

  subview = _subviewsThatNeedDisplay;
  while (subview) {
    [subview _displayNeededViews];
    subview = subview->_nextSiblingSubviewThatNeedsDisplay;
  }
}

- (void)_collectInvalidatedRectanglesInArray:(NSMutableArray*)array
  originMatrix:(PSMatrix*)originMatrix
  sizeMatrix:(PSMatrix*)sizeMatrix
{
  PSMatrix* copyOfOriginMatrix;
  PSMatrix* copyOfSizeMatrix;
  NSView* subview = _subviewsThatNeedDisplay;

  copyOfOriginMatrix = [originMatrix copy];
  copyOfSizeMatrix = [sizeMatrix copy];
  [copyOfOriginMatrix concatenateWith:frameMatrix];
  [copyOfOriginMatrix concatenateWith:boundsMatrix];
  [copyOfSizeMatrix concatenateWith:boundsMatrix];

//  NSLog (@"_collectInvalidatedRectanglesInArray");

  while (subview) {
    NSRect subviewFrame;
    NSRect intersection;

    if (subview->needs_display) {
      subviewFrame = subview->invalidatedRectangle;

      /* Compute the origin of the invalidated rectangle into receiver's
	 coordinates. */
      subviewFrame = [self convertRect:subviewFrame fromView:subview];

      /* If the subview is rotated compute its bounding rectangle and use this
	  one instead of the invalidated rectangle. */
      if ([subview->frameMatrix isRotated])
	[subview->frameMatrix boundingRectFor:subviewFrame
			      result:&subviewFrame];

      /* Determine if the subview's invalidated frame rectangle intersects
	 our bounds to find out if the subview gets displayed. */
      intersection = NSIntersectionRect (bounds, subviewFrame);
      if (intersection.origin.x || intersection.origin.y
	  || intersection.size.width || intersection.size.height) {
	NSDebugLog (@"intersection (%@) = ((%6.2f, %6.2f), (%6.2f, %6.2f))",
	    NSStringFromClass(isa),
	    intersection.origin.x, intersection.origin.y,
	    intersection.size.width, intersection.size.height);
	/* Convert the intersection rectangle to the window coordinates */
	intersection.origin
	    = [copyOfOriginMatrix pointInMatrixSpace:intersection.origin];
	intersection.size
	    = [copyOfSizeMatrix sizeInMatrixSpace:intersection.size];

	[array addObject:[NSValue valueWithRect:intersection]];
	NSDebugLog (@"intersection in window coords = ((%6.2f, %6.2f), (%6.2f, %6.2f))",
	    intersection.origin.x, intersection.origin.y,
	    intersection.size.width, intersection.size.height);
      }
    }
    else {
      [subview _collectInvalidatedRectanglesInArray:array
		originMatrix:copyOfOriginMatrix
		sizeMatrix:copyOfSizeMatrix];
    }

    subview = subview->_nextSiblingSubviewThatNeedsDisplay;
  }

  [copyOfOriginMatrix release];
  [copyOfSizeMatrix release];
}

- (NSRect)_boundingRectFor:(NSRect)rect
{
  NSRect new;

  [frameMatrix boundingRectFor:rect result:&new];
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

- (void)scrollClipView:(NSClipView *)aClipView
	       toPoint:(NSPoint)aPoint
{}

- (void)scrollPoint:(NSPoint)aPoint
{}

- (void)scrollRect:(NSRect)aRect
		by:(NSSize)delta
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
- (void)addCursorRect:(NSRect)aRect
	       cursor:(NSCursor *)anObject
{
  TrackingRectangle *m;

  m = [[[TrackingRectangle alloc] initWithRect: aRect tag: 0 owner: anObject
				 userData: NULL inside: YES]
		autorelease];
  [cursor_rects addObject:m];
}

- (void)discardCursorRects
{
  [cursor_rects removeAllObjects];
}

- (void)removeCursorRect:(NSRect)aRect
		  cursor:(NSCursor *)anObject
{
  id e = [cursor_rects objectEnumerator];
  TrackingRectangle *o;
  NSCursor *c;

  // Base remove test upon cursor object
  o = [e nextObject];
  while (o) {
    c = [o owner];
    if (c == anObject) {
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

  // If not within our frame then immediately return
  if (![self mouse:aPoint inRect:frame])
    return nil;

  p = [self convertPoint:aPoint fromView:super_view];

  // Check our sub_views
  count = [sub_views count];
  for (i = count - 1; i >= 0; i--)
    {
      w = [sub_views objectAtIndex:i];
      v = [w hitTest:p];
      if (v) break;
    }

  // It is either the subview or ourself
  if (v)
    {
      return v;
    }
  else
    {
      return self;
    }
}

- (BOOL)mouse:(NSPoint)aPoint
       inRect:(NSRect)aRect
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
  TrackingRectangle *m;

  j = [tracking_rects count];
  for (i = 0;i < j; ++i)
    {
      m = (TrackingRectangle *)[tracking_rects objectAtIndex:i];
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
  TrackingRectangle *m;

  t = 0;
  j = [tracking_rects count];
  for (i = 0;i < j; ++i)
    {
      m = (TrackingRectangle *)[tracking_rects objectAtIndex:i];
      if ([m tag] > t)
	t = [m tag];
    }
  ++t;

  m = [[[TrackingRectangle alloc] initWithRect:aRect tag:t owner:anObject
				 userData:data inside:flag]
		autorelease];
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

- (void)dragImage:(NSImage *)anImage
	       at:(NSPoint)viewLocation
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

- (void)fax:(id)sender
{}

- (void)print:(id)sender
{}

- (void)writeEPSInsideRect:(NSRect)rect
	      toPasteboard:(NSPasteboard *)pasteboard
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

- (BOOL)knowsPagesFirst:(int *)firstPageNum
		   last:(int *)lastPageNum
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
- (void)addToPageSetup
{}

- (void)beginPage:(int)ordinalNum
	    label:(NSString *)aString
	     bBox:(NSRect)pageRect
	    fonts:(NSString *)fontNames
{}

- (void)beginPageSetupRect:(NSRect)aRect
		 placement:(NSPoint)location
{}

- (void)beginPrologueBBox:(NSRect)boundingBox
	     creationDate:(NSString *)dateCreated
		createdBy:(NSString *)anApplication
		    fonts:(NSString *)fontNames
		  forWhom:(NSString *)user
		    pages:(int)numPages
		    title:(NSString *)aTitle
{}

- (void)beginSetup
{}

- (void)beginTrailer
{}

- (void)drawPageBorderWithSize:(NSSize)borderSize
{}

- (void)drawSheetBorderWithSize:(NSSize)borderSize
{}

- (void)endHeaderComments
{}

- (void)endPrologue
{}

- (void)endSetup
{}

- (void)endPageSetup
{}

- (void)endPage
{}

- (void)endTrailer
{}

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

/* Accessor methods */
- (NSMutableArray *)subviews			{ return sub_views; }
- (NSView *)superview				{ return super_view; }
- (void)setSuperview:(NSView *)superview	{ super_view = superview; }
- (NSRect)frame					{ return frame; }
- (float)frameRotation			{ return [frameMatrix rotationAngle]; }
- (BOOL)shouldDrawColor				{ return YES; }
- (BOOL)isOpaque				{ return NO; }
- (BOOL)needsDisplay				{ return needs_display; }
- (BOOL)autoresizesSubviews			{ return autoresize_subviews; }
- (unsigned int)autoresizingMask		{ return autoresizingMask; }
- (int)tag					{ return -1; }
- (NSArray *)cursorRectangles			{ return cursor_rects; }
- (float)boundsRotation		{ return [boundsMatrix rotationAngle]; }
- (NSRect)bounds				{ return bounds; }
- (BOOL)isFlipped				{ return NO; }
- (BOOL)postsFrameChangedNotifications		{ return post_frame_changes; }
- (BOOL)postsBoundsChangedNotifications		{ return post_bounds_changes; }
- (PSMatrix*)_frameMatrix			{ return frameMatrix; }
- (PSMatrix*)_boundsMatrix			{ return boundsMatrix; }

@end
