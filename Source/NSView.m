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
static NSString *viewThreadKey = @"NSViewThreadKey";

//
// Class methods
//
+ (void)initialize
{
    if (self == [NSView class])
        {
        NSDebugLog(@"Initialize NSView class\n");
        [self setVersion:1];                                // Initial version
        }
}

+ (NSView *)focusView
{
NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
NSMutableArray *stack = [dict objectForKey: viewThreadKey];
NSView *current_view = nil;
                                                        // return the view at
    if (stack)                                          // the top of thread's
        {                                               // focus stack or nil
        unsigned count = [stack count];                 // if none is focused
                                                        
        if (count > 0)
            current_view = [stack objectAtIndex: --count];
        }

    return current_view;
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
    [super init];                                       // super is NSResponder
    
    frame = frameRect;                                  // Set frame rectangle
    bounds.origin = NSZeroPoint;                        // Set bounds rectangle
    bounds.size = frame.size;
    
    frameMatrix = [PSMatrix new];                       // init PS matrix for
    boundsMatrix = [PSMatrix new];                      // frame and bounds
    [frameMatrix setFrameOrigin:frame.origin];
                                                        // initialize lists of:
    sub_views = [NSMutableArray new];                   // subviews
    tracking_rects = [NSMutableArray new];              // tracking rectangles
    cursor_rects = [NSMutableArray new];                // cursor rectangles
                                                        
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

- (void)addSubview:(NSView *)aView
{                                                   // make sure we are not 
    if ([self isDescendantOf:aView])                // making self a subview of 
        {                                           // self
        NSLog(@"Operation addSubview: creates a loop in the views tree!\n");
        return;
        }
  
    [aView viewWillMoveToWindow:window];            
    [aView setSuperview:self];                      
    [aView setNextResponder:self];
    [sub_views addObject:(id)aView];                // Add to our subview list
}

- (void)addSubview:(NSView *)aView                  // may not be per OS spec
        positioned:(NSWindowOrderingMode)place      // FIX ME
        relativeTo:(NSView *)otherView
{                                                   // make sure we aren't 
                                                    // making self a subview of 
    if ([self isDescendantOf:aView])                // self thereby creating a
        {                                           // loop in the heirarchy
        NSLog(@"addSubview:positioned:relativeTo: will create a cycle "
                @"in the views tree!\n");
        return;
        }
                                                    
    [sub_views addObject:(id)aView];                // Add to our subview list
    [aView setSuperview:self];
                                                    // Make ourselves the next 
    [aView setNextResponder:self];                  // responder of the view

    [aView viewWillMoveToWindow:window];            // Tell the view what 
}                                                   // window it has moved to

- (NSView *)ancestorSharedWithView:(NSView *)aView
{
    if (self == aView)                              // Are they the same view?
        return self;
  
    if ([self isDescendantOf: aView])               // Is self a descendant of 
        return aView;                               // view?

    if ([aView isDescendantOf: self])               // Is view a descendant of 
        return self;                                // self?
                                    
    if (![self superview])          // If neither are descendants of each other
        return nil;                 // and either does not have a superview
    if (![aView superview])         // then they cannot have a common ancestor
        return nil;
                                    // Find the common ancestor of superviews
    return [[self superview] ancestorSharedWithView: [aView superview]];
}

- (BOOL)isDescendantOf:(NSView *)aView
{
    if (aView == self)                              // Quick check
        return YES;

    if (!super_view)                                // No superview then this 
        return NO;                                  // is end of the line

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

- (void)removeFromSuperview
{
NSMutableArray *views;
  
    if (!super_view)                                    // if no superview then
        return;                                         // just return

    [self viewWillMoveToWindow:nil];

    views = [super_view subviews];
    [views removeObjectIdenticalTo:self];
    super_view = nil;
}

- (void)replaceSubview:(NSView *)oldView with:(NSView *)newView
{
    if (!newView)
        return;

    if (!oldView)
        [self addSubview:newView];
    else 
        {
        int index = [sub_views indexOfObjectIdenticalTo:oldView];

        if (index != NSNotFound) 
            {
            [oldView viewWillMoveToWindow:nil];
            [oldView setSuperview:nil];
            [newView setNextResponder:nil];

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

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
int i, count;

    window = newWindow;
  
    count = [sub_views count];                          // Pass new window down
    for (i = 0; i < count; ++i)                         // to subviews
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
NSSize old_size = bounds.size;

    frame = frameRect;
    bounds.size = frame.size;
    [frameMatrix setFrameOrigin:frame.origin];
    
    [self resizeSubviewsWithOldSize: old_size];         // Resize the subviews
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
NSSize old_size = bounds.size;

    frame.size = bounds.size = newSize;
  
    [self resizeSubviewsWithOldSize: old_size];         // Resize the subviews
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

- (void)setBoundsOrigin:(NSPoint)newOrigin          // translate bounds origin
{                                                   // in opposite direction so
    bounds.origin = newOrigin;                      // that newOrigin becomes 
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

- (PSMatrix*)_concatenateMatricesInReverseOrderFromPath:(NSArray*)viewsPath
{
int i, count = [viewsPath count];
PSMatrix* matrix = [[PSMatrix new] autorelease];

    for (i = count - 1; i >= 0; i--) 
        {
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

    while (view && view != _superview) 
        {
        [array addObject:view];
        view = view->super_view;
        }

    return array;
}

- (NSPoint)convertPoint:(NSPoint)aPoint fromView:(NSView*)aView
{
NSPoint new;
PSMatrix* matrix;

    if (!aView)
        aView = [window contentView];

    if ([self isDescendantOf:aView]) 
        {
        NSArray* path = [self _pathBetweenSubview:self toSuperview:aView];

        matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
        [matrix inverse];
        new = [matrix pointInMatrixSpace:aPoint];
        }
    else 
        if ([aView isDescendantOf:self]) 
            {
            NSArray* path = [self _pathBetweenSubview:aView toSuperview:self];

            matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
            new = [matrix pointInMatrixSpace:aPoint];
            }           // The views are not in the same hierarchy of views.
        else            // Convert the point to window from the other's view 
            {           // coordinates and then to our view coordinates.
            new = [aView convertPoint:aPoint toView:nil];
            new = [self convertPoint:new fromView:nil];
            }

    return new;
}

- (NSPoint)convertPoint:(NSPoint)aPoint toView:(NSView *)aView
{
    if (!aView)
        aView = [window contentView];

    return [aView convertPoint:aPoint fromView:self];
}

- (NSRect)convertRect:(NSRect)aRect fromView:(NSView *)aView
{
NSRect r;

    if (aView && window != [aView window])              // Must belong to the 
        return NSZeroRect;                              // same window

    r = aRect;
    r.origin = [self convertPoint:r.origin fromView:aView];
    r.size = [self convertSize:r.size fromView:aView];

    return r;
}

- (NSRect)convertRect:(NSRect)aRect toView:(NSView *)aView
{
NSRect r;

    if (aView && window != [aView window])              // Must belong to the 
        return NSZeroRect;                              // same window

    r = aRect;
    r.origin = [self convertPoint:r.origin toView:aView];
    r.size = [self convertSize:r.size toView:aView];

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
            }           // The views are not in the same hierarchy of views.
        else            // Convert the point to window from the other's view
            {           // coordinates and then to our view coordinates.
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

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize     // resize subviews only
{                                                       // if we are supposed
  id e, o;                                              // to and we have never
                                                        // been rotated
  if (![self autoresizesSubviews] && !is_rotated_from_base)
    return;

  e = [sub_views objectEnumerator];
  o = [e nextObject];
  while (o)
    {
      [o resizeWithOldSuperviewSize: oldSize];          // resize it's subviews
      o = [e nextObject];
    }
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  float changex;
  float changey;
  NSSize old_size = bounds.size;
  BOOL  changedOrigin = NO;
  BOOL  changedSize = NO;

  if (autoresizingMask == NSViewNotSizable)
    return;

  changex = [super_view bounds].size.width - oldSize.width;
  changey = [super_view bounds].size.height - oldSize.height;

                                                    // adjust the X axis
//  fprintf (stderr, "NSView resizeWithOldSuperviewSize: \n");
//  fprintf (stderr, "Change x,y (%1.2f, %1.2f)\n", changex, changey);
//  fprintf (stderr,
//            "NSView: old origin (%1.2f, %1.2f), size (%1.2f, %1.2f)\n",
//            frame.origin.x, frame.origin.y,
//            frame.size.width, frame.size.height);

  if (changex)
    {
      if (autoresizingMask & NSViewWidthSizable)
        {
          float change;

          if (autoresizingMask & NSViewMinXMargin)
            {
              if (autoresizingMask & NSViewMaxXMargin)
                {
                  change = changex/3.0;
                }
              else
                {
                  change = changex/2.0;
                }
              frame.origin.x += change;
              changedOrigin = YES;
            }
          else if (autoresizingMask & NSViewMaxXMargin)
            {
              change = changex/2.0;
            }
          else
            {
              change = changex;
            }
          bounds.size.width *= (frame.size.width + change);
          bounds.size.width /= frame.size.width;
          frame.size.width += change;
          changedSize = YES;
        }
      else if (autoresizingMask & NSViewMinXMargin)
        {
          if (autoresizingMask & NSViewMaxXMargin)
            {
              frame.origin.x += changex/2.0;
            }
          else
            {
              frame.origin.x += changex;
            }
          changedOrigin = YES;
        }
    }

  if (changey)
    {
      if (autoresizingMask & NSViewHeightSizable)
        {
          float change;

          if (autoresizingMask & NSViewMinYMargin)
            {
              if (autoresizingMask & NSViewMaxYMargin)
                {
                  change = changey/3.0;
                }
              else
                {
                  change = changey/2.0;
                }
              frame.origin.y += change;
              changedOrigin = YES;
            }
          else if (autoresizingMask & NSViewMaxYMargin)
            {
              change = changey/2.0;
            }
          else
            {
              change = changey;
            }
          bounds.size.height *= (frame.size.height + change);
          bounds.size.height /= frame.size.height;
          frame.size.height += change;
          changedSize = YES;
        }
      else if (autoresizingMask & NSViewMinYMargin)
        {
          if (autoresizingMask & NSViewMaxYMargin)
            {
              frame.origin.y += changey/2.0;
            }
          else
            {
              frame.origin.y += changey;
            }
          changedOrigin = YES;
        }
    }

//  fprintf (stderr,
//            "NSView: new origin (%1.2f, %1.2f), size (%1.2f, %1.2f)\n",
//            frame.origin.x, frame.origin.y,
//            frame.size.width, frame.size.height);

/* FIXME
 * The lines containing 'floor()' ensure that the frame sizes are an integer
 * number of points.  This is wrong - but makes for more efficient drawing
 * on systems where 1pixel == 1point and all coordinates are integer point
 * sizes.  If and when we can draw efficiently without this 'feature' the
 * lines should be removed.
 */
  if (changedOrigin)
    {
      frame.origin.x = floor(frame.origin.x);
      frame.origin.y = floor(frame.origin.y);
      [frameMatrix setFrameOrigin: frame.origin];
    }
  if (changedSize)
    {
      float sx;
      float sy;

      frame.size.width = floor(frame.size.width);
      frame.size.height = floor(frame.size.height);
      bounds.size.width = floor(bounds.size.width);
      bounds.size.height = floor(bounds.size.height);
      sx = frame.size.width / bounds.size.width;
      sy = frame.size.height / bounds.size.height;
      [boundsMatrix scaleTo: sx : sy];
    }
  if (changedSize || changedOrigin)
    {
      [self resizeSubviewsWithOldSize: old_size];
    }
}

- (void)allocateGState                  {}              // implemented by the
- (void)releaseGState                   {}              // back end
- (int)gState                           { return 0; }
- (void)renewGState                     {}
- (void)setUpGState                     {}
- (void)lockFocus                       { [self subclassResponsibility:_cmd]; }
- (void)unlockFocus                     { [self subclassResponsibility:_cmd]; }

- (BOOL)canDraw                             
{                                                       // not implemented per
    if (window)                                         // OS spec FIX ME
        return YES; 
    else
        return NO;
}

- (void)display                                         // not per spec FIX ME
{
    if (!window)                                                // do nothing if not in
        return;                                         // a window's heirarchy
                                                        
    [self displayRect:[self visibleRect]];              // display visible rect
}                                                       

- (void)displayIfNeeded                                 // if self is opaque
{                                                       // display if needed
    if ([self isOpaque])                                // else back up to a    
        [self displayIfNeededIgnoringOpacity];          // view which is and
    else                                                // begin drawing there
        {
        if (needs_display)
            {   
            if (invalidRect.size.width > 0 && invalidRect.size.height > 0)
                {
                NSView *firstOpaque = [self opaqueAncestor];
                NSRect rect = invalidRect;              // convert rect into
                                                        // coordinates of the   
                                                        // first opaque view
                rect = [firstOpaque convertRect:rect fromView:self];
                [firstOpaque displayIfNeededInRectIgnoringOpacity:rect];
                }
            needs_display = NO;                             
            }
        }
}

- (void)displayIfNeededInRect:(NSRect)aRect
{                                                       
}               

- (void)displayIfNeededInRectIgnoringOpacity:(NSRect)aRect
{                                                       // display self and all
int i = 0, count;                                       // of our sub views if
                                                        // any part of self has
    for (count = [sub_views count]; i < count; ++i)     // been marked to be in
        {                                               // need of display with
        NSView* subview = [sub_views objectAtIndex:i];  // setNeedsDisplay or
                                                        // stNeedsDisplayInRect
        if (subview->needs_display)                     
            {                                           
            NSRect rect = subview->invalidRect;
            if (rect.size.width > 0 && rect.size.height > 0)
                [subview displayRect:rect];             // display invalid rect
            else
                [subview displayIfNeededIgnoringOpacity];               
            }                                           // subview must contain
        }                                               // a view in need of
}                                                       // display

- (void)displayIfNeededIgnoringOpacity                    
{                                                       
int i = 0, count;                                       // display self and all
                                                        // of our sub views if
    if (!window)                                                // any part of self has
        return;                                         // been marked to be in
                                                        // need of display with
    if (needs_display)                                  // setNeedsDisplay or
        {                                               // stNeedsDisplayInRect
        if (invalidRect.size.width > 0 && invalidRect.size.height > 0)
            {                                           
            [self lockFocus];                           // self has an invalid
            [self drawRect:invalidRect];                // rect that needs to
            [self unlockFocus];                         // be displayed

            for (count = [sub_views count]; i < count; ++i)     
                {                           // cycle thru subviews displaying       
                NSRect intersection;        // any that intersect invalidRect
                NSView* subview = [sub_views objectAtIndex:i];  
                NSRect subviewFrame = subview->frame;
                                            // If subview is rotated compute 
                                            // it's bounding rect and use this 
                                            // instead of the subview's frame. 
                if ([subview->frameMatrix isRotated])
                    [subview->frameMatrix boundingRectFor:subviewFrame 
                                          result:&subviewFrame];

                                                    // Display the subview if
                                                    // it intersects "rect". 
                intersection = NSIntersectionRect (invalidRect, subviewFrame);
                if (intersection.origin.x || intersection.origin.y || 
                        intersection.size.width || intersection.size.height) 
                    {                   // Convert the intersection rectangle
                                        // to the subview's coordinates 
                    intersection = [subview convertRect:intersection 
                                            fromView:self];
                    [subview displayRect:intersection];
                    }                           // subview does not intersect 
                else                            // invalidRect but it may be
                    if (subview->needs_display) // marked as needing display    
                        [subview displayIfNeededIgnoringOpacity];
                }
            invalidRect = NSZeroRect;                   
            }                                           // self does not need
        else                                            // display but a sub
            {                                           // view might 
            for (count = [sub_views count]; i < count; ++i)     
                {                                               
                NSView* subview = [sub_views objectAtIndex:i];  
                                                        // a subview contains a
                if (subview->needs_display)             // view needing display     
                    [subview displayIfNeededIgnoringOpacity];               
                }                                               
            }

        needs_display = NO;                             
        }
}                                                       
                                                        
- (void)displayRect:(NSRect)rect                        // not per spec FIX ME
{
int i, count;

    if (!boundsMatrix || !frameMatrix)
        NSLog (@"warning: %@ %p does not have it's PS matrices configured!",
                NSStringFromClass(isa), self);

    needs_display = NO;
    invalidRect = NSZeroRect;                           // Reset invalid rect

    [self lockFocus];
    [self drawRect:rect];
    [self unlockFocus];                                 // display any subviews
                                                        // that intersect rect
    for (i = 0, count = [sub_views count]; i < count; ++i) 
        {
        NSView* subview = [sub_views objectAtIndex:i];
        NSRect subviewFrame = subview->frame;
        NSRect intersection;            // If the subview is rotated compute 
                                        // its bounding rectangle and use this 
                                        // one instead of the subview's frame. 
        if ([subview->frameMatrix isRotated])
            [subview->frameMatrix boundingRectFor:subviewFrame 
                                  result:&subviewFrame];

                                                    // Display the subview if
                                                    // it intersects "rect". 
        intersection = NSIntersectionRect (rect, subviewFrame);
        if (intersection.origin.x || intersection.origin.y || 
                intersection.size.width || intersection.size.height) 
            {                           // Convert the intersection rectangle
                                        // to the subview's coordinates 
            intersection = [subview convertRect:intersection fromView:self];
            [subview displayRect:intersection];
            }
        }

    [window flushWindow];
}

- (void)displayRectIgnoringOpacity:(NSRect)aRect
{}

- (void)drawRect:(NSRect)rect
{}

- (NSRect)visibleRect
{                                                       // if no super view 
    if (!super_view)                                    // bounds is visible
        return bounds;
    else                                                // return intersection
        {                                               // between bounds and
        NSRect superviewsVisibleRect;                   // super view's visible
                                                        // rect
        superviewsVisibleRect = [self convertRect:[super_view visibleRect] 
                                      fromView:super_view];

        return NSIntersectionRect(superviewsVisibleRect, bounds);
        }
}

- (void)setNeedsDisplay:(BOOL)flag
{
    needs_display = flag;
    if (needs_display)                          
        {
        NSView *firstOpaque = [self opaqueAncestor];
        NSView* currentView = super_view;   
        NSRect rect;                                    // convert rect into
                                                        // coordinates of the   
                                                        // first opaque view
        rect = [firstOpaque convertRect:bounds fromView:self];
        [firstOpaque setNeedsDisplayInRect:rect];
                         
        invalidRect = bounds;
        [window setViewsNeedDisplay:YES];

        while (currentView)                             // set needs display     
            {                                           // flag all the way up
            currentView->needs_display = YES;           // the view heirarchy
            currentView = currentView->super_view;           
            }
        }
    else
        invalidRect = NSZeroRect;       
}

- (void)setNeedsDisplayInRect:(NSRect)rect              // not per spec FIX ME
{                                                       // assumes opaque view
NSView* currentView = super_view;
        
    needs_display = YES;
    invalidRect = NSUnionRect (invalidRect, rect);
    [window setViewsNeedDisplay:YES];

    while (currentView)                                 // set needs display     
        {                                               // flag all the way up
        currentView->needs_display = YES;               // the view heirarchy
        currentView = currentView->super_view;           
        }

//  fprintf (stderr,
//  "setNeedsDisplayInRect: rect origin (%1.2f, %1.2f), size (%1.2f, %1.2f)\n",
//              rect.origin.x, rect.origin.y, 
//              rect.size.width, rect.size.height);
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
  
    o = [e nextObject];                                 // Base remove test 
    while (o)                                           // upon cursor object
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
    if (![self mouse:aPoint inRect:frame])          // then immediately return
        return nil;

    p = [self convertPoint:aPoint fromView:super_view];
  
    count = [sub_views count];                      // Check our sub_views
    for (i = count - 1; i >= 0; i--)
        {
        w = [sub_views objectAtIndex:i];
        v = [w hitTest:p];
        if (v) 
            break;
        }
  
    if (v)                                          // mouse is either in the 
        return v;                                   // subview or within self
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

- (void)dragImage:(NSImage *)anImage                    // initiate a dragging
               at:(NSPoint)viewLocation                 // session (backend)
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

- (void)fax:(id)sender                      {}
- (void)print:(id)sender                    {}
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

- (void)beginSetup                      {}              // not implemented
- (void)beginTrailer                    {}
- (void)drawPageBorderWithSize:(NSSize)borderSize       {}
- (void)drawSheetBorderWithSize:(NSSize)borderSize      {}
- (void)endHeaderComments               {}
- (void)endPrologue                     {}
- (void)endSetup                        {}
- (void)endPageSetup                    {}
- (void)endPage                         {}
- (void)endTrailer                      {}

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
- (void)setAutoresizesSubviews:(BOOL)flag       { autoresize_subviews = flag; }
- (void)setAutoresizingMask:(unsigned int)mask  { autoresizingMask = mask; }

- (NSWindow *)window                            { return window; }
- (BOOL)autoresizesSubviews                     { return autoresize_subviews; }
- (unsigned int)autoresizingMask                { return autoresizingMask; }
- (NSMutableArray *)subviews                    { return sub_views; }
- (NSView *)superview                           { return super_view; }
- (void)setSuperview:(NSView *)superview        { super_view = superview; }
- (BOOL)shouldDrawColor                         { return YES; }
- (BOOL)isOpaque                                { return NO; }
- (BOOL)needsDisplay                            { return needs_display; }
- (int)tag                                      { return -1; }
- (NSArray *)cursorRectangles                   { return cursor_rects; }
- (BOOL)isFlipped                               { return NO; }
- (NSRect)bounds                                { return bounds; }
- (NSRect)frame                                 { return frame; }
- (float)boundsRotation             { return [boundsMatrix rotationAngle]; }
- (float)frameRotation              { return [frameMatrix rotationAngle]; }
- (PSMatrix*)_boundsMatrix                      { return boundsMatrix; }
- (PSMatrix*)_frameMatrix                       { return frameMatrix; }
- (BOOL)postsFrameChangedNotifications          { return post_frame_changes; }
- (BOOL)postsBoundsChangedNotifications         { return post_bounds_changes; }

@end
