/* 
   NSView.m

   The view class which encapsulates all drawing functionality

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/NSView.h>
#include <gnustep/gui/NSWindow.h>
#include <gnustep/base/NSCoder.h>
#include <gnustep/base/NSDictionary.h>
#include <gnustep/base/NSThread.h>
#include <gnustep/base/NSLock.h>

//
// Class variables
//
NSMutableDictionary *gnustep_gui_nsview_thread_dict;
NSRecursiveLock *gnustep_gui_nsview_lock;

// NSView notifications
NSString *NSViewFrameChangedNotification;
NSString *NSViewFocusChangedNotification;

@implementation NSView

//
// Class methods
//
//
// Initialization
//
+ (void)initialize
{
  if (self == [NSView class])
    {
      NSDebugLog(@"Initialize NSView class\n");

      // Initial version
      [self setVersion:1];

      // Allocate dictionary for maintaining
      // mapping of threads to focused views
      gnustep_gui_nsview_thread_dict = [NSMutableDictionary dictionary];
      // Create lock for serializing access to dictionary
      gnustep_gui_nsview_lock = [[NSRecursiveLock alloc] init];
    }
}

//
// Focusing
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

  // Obtain lock so we can edit the dictionary
  [gnustep_gui_nsview_lock lock];

  // Remove from dictionary
  [gnustep_gui_nsview_thread_dict removeObjectForKey: current_thread];

  [gnustep_gui_nsview_lock unlock];
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

//
// Instance methods
//
//
// Initializing NSView Objects 
//
- init
{
  return [self initWithFrame:NSZeroRect];
}

// The default initializer
- (id)initWithFrame:(NSRect)frameRect
{
  // Our super is NSResponder
  [super init];

	// Set frame rectangle
  frame = frameRect;

  // Set bounds rectangle
  bounds.origin = NSZeroPoint;
  bounds.size = frame.size;

	// Initialize subview list
  sub_views = [NSMutableArray array];

  // Initialize tracking rectangle list
  tracking_rects = [NSMutableArray array];

  super_view = nil;
  window = nil;
  is_flipped = NO;
  is_rotated_from_base = NO;
  is_rotated_or_scaled_from_base = NO;
  opaque = NO;
  disable_autodisplay = NO;
  needs_display = YES;
  post_frame_changes = NO;
  autoresize_subviews = YES;

  return self;
}

- (void)dealloc
{
  int i, j;

  //NSArray doesn't know -removeAllObjects yet
  //[sub_views removeAllObjects];
  j = [sub_views count];
  for (i = 0;i < j; ++i)
    [[sub_views objectAtIndex:i] release];

  // no need -array is autoreleased
  //[sub_views release];

  // Free the tracking rectangles
  j = [tracking_rects count];
  for (i = 0;i < j; ++i)
    [[tracking_rects objectAtIndex:i] release];

  [super dealloc];
}

//
// Managing the NSView Hierarchy 
//
- (void)addSubview:(NSView *)aView
{
  // Not a NSView --then forget it
  // xxx but NSView will really be the backend class
  // so how do we check that its really a subclass of NSView
  // and not of the backend class?
#if 0
  if (![aView isKindOfClass:[NSView class]])
    {
      return;
    }
#endif

  // make sure we aren't making ourself a subview of ourself
  if (self == aView)
    {
      NSLog(@"Attempt to make view a subview of itself\n");
      return;
    }

  // retain the object
  [aView retain];

  // Add to our subview list
  [sub_views addObject:(id)aView];
  [aView setSuperview:self];
  [aView setNextResponder:self];
  [aView viewWillMoveToWindow:window];
}

- (void)addSubview:(NSView *)aView
	positioned:(NSWindowOrderingMode)place
	relativeTo:(NSView *)otherView
{
  // Not a NSView --then forget it
  // xxx but NSView will really be the backend class
  // so how do we check that its really a subclass of NSView
  // and not of the backend class?
#if 0
  if (![aView isKindOfClass:[NSView class]]) return;
#endif

  // retain the object
  [aView retain];

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
  NSView *v = nil;
  BOOL found = NO;

  return v;
}

- (BOOL)isDescendantOf:(NSView *)aView
{
  int i, j;
  NSView *v;
  BOOL found = NO;

  // Not a NSView --then forget it
  // xxx but NSView will really be the backend class
  // so how do we check that its really a subclass of NSView
  // and not of the backend class?
#if o
  if (![aView isKindOfClass:[NSView class]]) return NO;
#endif

  // Quick check
  if (aView == self) return YES;

  // No superview then this is end of the line
  if (!super_view) return NO;

  if (super_view == aView) return YES;

  return [super_view isDescendantOf:aView];
}

- (NSView *)opaqueAncestor
{
  return nil;
}

- (void)removeFromSuperview
{
  int i, j;
  NSMutableArray *v;

  // No superview then just return
  if (!super_view) return;

  v = [super_view subviews];
  j = [v count];
  for (i = 0;i < j; ++i)
    {
      if ([v objectAtIndex:i] == self)
	[v removeObjectAtIndex:i];
    }
}

- (void)replaceSubview:(NSView *)oldView
		  with:(NSView *)newView
{
  int i, j;
  NSView *v;

  // Not a NSView --then forget it
  // xxx but NSView will really be the backend class
  // so how do we check that its really a subclass of NSView
  // and not of the backend class?
#if 0
  if (![newView isKindOfClass:[NSView class]]) return;
#endif

  j = [sub_views count];
  for (i = 0;i < j; ++i)
    {
      v = [sub_views objectAtIndex:i];
      if (v == oldView)
	{
	  // Found it then replace
	  [sub_views replaceObjectAtIndex:i withObject:newView];
	  // release it as well
	  [v release];
	  // and retain the new view
	  [newView retain];
	}
      else
	// Didn't find then pass down view hierarchy
	[v replaceSubview:oldView with:newView];
    }
}

- (void)sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare 
			  context:(void *)context
{}

- (NSMutableArray *)subviews
{
  return sub_views;
}

- (NSView *)superview
{
  return super_view;
}

- (void)setSuperview:(NSView *)superview
{
  // Not a NSView --then forget it
  // xxx but NSView will really be the backend class
  // so how do we check that its really a subclass of NSView
  // and not of the backend class?
#if 0
  if (![superview isKindOfClass:[NSView class]]) return;
#endif

  super_view = superview;
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
  int i, j;

  // not a window --then forget it
  // if (![newWindow isKindOfClass:[NSWindow class]]) return;

  window = newWindow;

  // Pass new window down to subviews
  j = [sub_views count];
  for (i = 0;i < j; ++i)
    [[sub_views objectAtIndex:i] viewWillMoveToWindow:newWindow];

}

//
// Modifying the Frame Rectangle 
//
- (float)frameRotation
{
  return 0;
}

- (NSRect)frame
{
  return frame;
}

- (void)rotateByAngle:(float)angle
{}

- (void)setFrame:(NSRect)frameRect
{
  NSSize old_size = bounds.size;

  frame = frameRect;
  bounds.size = frame.size;

  // Resize subviews
  [self resizeSubviewsWithOldSize: old_size];
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
  frame.origin = newOrigin;
}

- (void)setFrameRotation:(float)angle
{}

- (void)setFrameSize:(NSSize)newSize
{
  NSSize old_size = bounds.size;

  frame.size = newSize;
  bounds.size = newSize;

  // Resize subviews
  [self resizeSubviewsWithOldSize: old_size];
}

//
// Modifying the Coordinate System 
//

- (float)boundsRotation
{
  return 0;
}

- (NSRect)bounds
{
  return bounds;
}

- (BOOL)isFlipped
{
  return is_flipped;
}

- (BOOL)isRotatedFromBase
{
  return is_rotated_from_base;
}

- (BOOL)isRotatedOrScaledFromBase
{
  return is_rotated_or_scaled_from_base;
}

- (void)scaleUnitSquareToSize:(NSSize)newSize
{}

- (void)setBounds:(NSRect)aRect
{
  bounds = aRect;
}

- (void)setBoundsOrigin:(NSPoint)newOrigin
{
  bounds.origin = newOrigin;
}

- (void)setBoundsRotation:(float)angle
{}

- (void)setBoundsSize:(NSSize)newSize
{
  bounds.size = newSize;
}

- (void)translateOriginToPoint:(NSPoint)point
{}

//
// Converting Coordinates 
//
- (NSRect)convertRectToWindow:(NSRect)r
{
  NSRect f, t, a;
  id s;

  a = r;
  f = [self frame];
  s = [self superview];
  // climb up the superview chain
  while (s)
    {
      t = [s frame];
      // translate frame
      f.origin.x += t.origin.x;
      f.origin.y += t.origin.y;
      s = [s superview];
    }
  a.origin.x += f.origin.x;
  a.origin.y += f.origin.y;

  return a;
}

- (NSPoint)convertPointToWindow:(NSPoint)p
{
  NSRect f, t;
  NSPoint a;
  id s;

  a = p;
  f = [self frame];
  s = [self superview];
  // climb up the superview chain
  while (s)
    {
      t = [s frame];
      // translate frame
      f.origin.x += t.origin.x;
      f.origin.y += t.origin.y;
      s = [s superview];
    }
  a.x += f.origin.x;
  a.y += f.origin.y;

  return a;
}

- (NSRect)centerScanRect:(NSRect)aRect
{
  return NSZeroRect;
}

- (NSPoint)convertPoint:(NSPoint)aPoint
	       fromView:(NSView *)aView
{
  NSPoint p, q;
  NSRect r;

  // Must belong to the same window
  if (([self window] != [aView window]) && (aView))
    return NSZeroPoint;

  // if aView is nil
  // then converting from window
  // so convert from the content from the content view of the window
  if (aView == nil)
    return [self convertPoint: aPoint fromView:[[self window] contentView]];

  // Convert the point to window coordinates
  p = [aView convertPointToWindow: aPoint];

  // Convert out origin to window coordinates
  q = [self convertPointToWindow: bounds.origin];

  NSDebugLog(@"point convert: %f %f %f %f\n", p.x, p.y, q.x, q.y);

  // now translate
  p.x -= q.x;
  p.y -= q.y;

  return p;
}

- (NSPoint)convertPoint:(NSPoint)aPoint
		 toView:(NSView *)aView
{
  NSPoint p, q;
  NSRect r;

  // Must belong to the same window
  if (([self window] != [aView window]) && (aView))
    return NSZeroPoint;

  // if aView is nil
  // then converting to window
  if (aView == nil)
    return [self convertPointToWindow: aPoint];

  // convert everything to window coordinates
  p = [self convertPointToWindow: aPoint];
  r = [aView bounds];
  q = [aView convertPointToWindow: r.origin];
  NSDebugLog(@"point convert: %f %f %f %f\n", p.x, p.y, q.x, q.y);

  // now translate
  p.x -= q.x;
  p.y -= q.y;

  return p;
}

- (NSRect)convertRect:(NSRect)aRect
	     fromView:(NSView *)aView
{
  NSRect r;

  // Must belong to the same window
  if (([self window] != [aView window]) && (aView))
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
  if (([self window] != [aView window]) && (aView))
    return NSZeroRect;

  r = aRect;
  r.origin = [self convertPoint:r.origin toView:aView];
  r.size = [self convertSize:r.size toView:aView];
  return r;
}

- (NSSize)convertSize:(NSSize)aSize
	     fromView:(NSView *)aView
{
  // Size would only change under scaling
  return aSize;
}

- (NSSize)convertSize:(NSSize)aSize
	       toView:(NSView *)aView
{
  // Size would only change under scaling
  return aSize;
}

//
// Notifying Ancestor Views 
//
- (BOOL)postsFrameChangedNotifications
{
  return post_frame_changes;
}

- (void)setPostsFrameChangedNotifications:(BOOL)flag
{
  post_frame_changes = flag;
}


//
// Resizing Subviews 
//
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

- (BOOL)autoresizesSubviews
{
  return autoresize_subviews;
}

- (void)setAutoresizingMask:(unsigned int)mask
{}

- (unsigned int)autoresizingMask
{
  return 0;
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{}

//
// Graphics State Objects 
//
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

//
// Focusing 
//
- (void)lockFocus
{
  [[self class] pushFocusView: self];
}

- (void)unlockFocus
{
  [[self class] popFocusView];
}

//
// Displaying 
//
- (BOOL)canDraw
{
  return YES;
}

- (void)display
{
  int i, j;

  [self lockFocus];
  [self drawRect:bounds];
  [self unlockFocus];
	
  // Tell subviews to display
  j = [sub_views count];
  for (i = 0;i < j; ++i)
    [(NSView *)[sub_views objectAtIndex:i] display];
}

- (void)displayIfNeeded
{
  if ((needs_display) && (opaque))
    [self display];
}

- (void)displayIfNeededIgnoringOpacity
{
  if (needs_display)
    [self display];
}

- (void)displayRect:(NSRect)aRect
{}

- (void)displayRectIgnoringOpacity:(NSRect)aRect
{}

- (void)drawRect:(NSRect)rect
{
}

- (NSRect)visibleRect
{
  return bounds;
}

- (BOOL)isOpaque
{
  return opaque;
}

- (BOOL)needsDisplay
{
  return needs_display;
}

- (void)setNeedsDisplay:(BOOL)flag
{
  needs_display = flag;
}

- (void)setNeedsDisplayInRect:(NSRect)invalidRect
{
  needs_display = YES;
}

- (BOOL)shouldDrawColor
{
  return YES;
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
- (void)addCursorRect:(NSRect)aRect
	       cursor:(NSCursor *)anObject
{}

- (void)discardCursorRects
{}

- (void)removeCursorRect:(NSRect)aRect
		  cursor:(NSCursor *)anObject
{}

- (void)resetCursorRects
{}

//
// Assigning a Tag 
//
- (int)tag
{
  return -1;
}

- (id)viewWithTag:(int)aTag
{
  int i, j;

  j = [sub_views count];
  for (i = 0;i < j; ++i)
    {
      if ([[sub_views objectAtIndex:i] tag] == aTag)
	return [sub_views objectAtIndex:i];
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
  int i, j;
  NSView *v = nil, *w;

  // If not within our bounds then immediately return
  if (![self mouse:aPoint inRect:bounds]) return nil;

  // Check our sub_views
  j = [sub_views count];
  for (i = 0;i < j; ++i)
    {
      w = [sub_views objectAtIndex:i];
      p = [self convertPoint:aPoint toView:w];
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
	  [m release];
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

  m = [[TrackingRectangle alloc] initWithRect:aRect tag:t owner:anObject
				 userData:data inside:flag];
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
  [aCoder encodeObjectReference: super_view withName: @"Superview"];
  [aCoder encodeObject: sub_views];
  [aCoder encodeObjectReference: window withName: @"Window"];
  [aCoder encodeObject: tracking_rects];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_flipped];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_rotated_from_base];
  [aCoder encodeValueOfObjCType:@encode(BOOL) 
	  at: &is_rotated_or_scaled_from_base];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &opaque];
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
  [aDecoder decodeObjectAt: &super_view withName: NULL];
  sub_views = [aDecoder decodeObject];
  [aDecoder decodeObjectAt: &window withName: NULL];
  tracking_rects = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_flipped];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_rotated_from_base];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) 
	  at: &is_rotated_or_scaled_from_base];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &opaque];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &needs_display];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &disable_autodisplay];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &post_frame_changes];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &autoresize_subviews];
  NSDebugLog(@"NSView: finish decoding\n");

  return self;
}

@end
