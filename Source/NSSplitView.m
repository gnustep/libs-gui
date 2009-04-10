/** <title>NSSplitView</title>

   <abstract>Allows multiple views to share a region in a window</abstract>

   Copyright (C) 1996, 1998, 1999, 2000, 2001, 2004, 2008 Free Software Foundation, Inc.

   Author: Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: November 1998
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: January 1999
   Author: Nicola Pero <nicola.pero@meta-innovation.com>
   Date: 2000, 2001, 2008

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSDecimalNumber.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSSplitView.h"
#include "AppKit/NSWindow.h"

static NSNotificationCenter *nc = nil;

@implementation NSSplitView

+ (void) initialize
{
  nc = [NSNotificationCenter defaultCenter];
}

/*
 * Instance methods
 */
- (id) initWithFrame: (NSRect)frameRect
{
  if ((self = [super initWithFrame: frameRect]) != nil)
    {
      _dividerWidth = [self dividerThickness];
      _draggedBarWidth = 8; // default bigger than dividerThickness
      _isVertical = NO;
      ASSIGN(_dividerColor, [NSColor controlShadowColor]);
      ASSIGN(_backgroundColor, [NSColor controlBackgroundColor]);
      ASSIGN(_dimpleImage, [NSImage imageNamed: @"common_Dimple"]); 

      _never_displayed_before = YES;
      _autoresizes_subviews = NO;
      _is_pane_splitter = YES;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_backgroundColor);
  RELEASE(_dividerColor);
  RELEASE(_dimpleImage);
  TEST_RELEASE(_autosaveName);

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }

  [super dealloc];
}

- (void) _autosaveSubviewProportions
{
  if (_autosaveName != nil) 
    {
      NSUserDefaults *defaults;
      NSString *splitViewKey;
      NSMutableDictionary *config;
      NSArray *subs = [self subviews];
      unsigned count = [subs count];
      NSView *views[count];

      defaults = [NSUserDefaults standardUserDefaults];
      splitViewKey = [NSString stringWithFormat: @"NSSplitView Dividers %@", 
                               _autosaveName];
      config = [NSMutableDictionary new];

      [subs getObjects: views];

      /* Compute the proportions and store them.  */
      if (count > 0)
        {
          int i;
          float oldTotal = 0.0;
          NSRect frames[count];
          
          for (i = 0; i < count; i++)
            {
              frames[i] = [views[i] frame];
              if (_isVertical == NO)
                {
                  oldTotal +=  NSHeight(frames[i]);
                }
              else
                {
                  oldTotal +=  NSWidth(frames[i]);
                }
            }

          for (i = 0; i < (count - 1); i++)
            {
              double proportion;
              
              if (_isVertical == NO)
                {
                  proportion = (NSHeight(frames[i]))/oldTotal;
                }
              else
                {
                  proportion = (NSWidth(frames[i]))/oldTotal;              
                }
              
              [config setObject: [NSNumber numberWithDouble: proportion]
                      forKey: [NSNumber numberWithInt: i]];
            }
        }
      
      [defaults setObject: config  forKey: splitViewKey];
      [defaults synchronize];
      RELEASE (config);
    }
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSApplication *app = [NSApplication sharedApplication];
  static NSRect oldRect; //only one can be dragged at a time
  static BOOL lit = NO;
  NSPoint p, op;
  NSEvent *e;
  NSRect r, r1, bigRect, vis;
  id v = nil, prev = nil;
  float minCoord, maxCoord;
  NSArray *subs = [self subviews];
  int offset = 0, i, count = [subs count];
  float divVertical, divHorizontal;
  NSDate *farAway = [NSDate distantFuture];
  NSDate *longTimeAgo = [NSDate distantPast];
  unsigned int eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  /* YES if delegate implements splitView:constrainSplitPosition:ofSubviewAt:*/
  BOOL delegateConstrains = NO;
  SEL constrainSel = @selector(splitView:constrainSplitPosition:ofSubviewAt:);
  typedef float (*floatIMP)(id, SEL, id, float, int);
  floatIMP constrainImp = NULL;

  /*  if there are less the two subviews, there is nothing to do */
  if (count < 2)
    {
      return;
    }

  /* Silence compiler warnings.  */
  r1 = NSZeroRect;
  bigRect = NSZeroRect;

  vis = [self visibleRect];

  /* find out which divider it is */
  p = [theEvent locationInWindow];
  p = [self convertPoint: p fromView: nil];
  for (i = 0; i < count; i++)
    {
      v = [subs objectAtIndex: i];
      r = [v frame];
      /* if the click is inside of a subview, return.  this should
         happen only if a subview has leaked a mouse down to next
         responder
         */
      if (NSPointInRect(p, r))
        {
          NSDebugLLog(@"NSSplitView",
            @"NSSplitView got mouseDown in subview area");
          return;
        }
      if (_isVertical == NO)
        {
          if (NSMinY(r) >= p.y)
            {
              offset = i - 1;

              /* get the enclosing rect for the two views */
              if (prev != nil)
                {
                  r = [prev frame];
                }
              else
                {
                  /*
                   * This happens if user pressed exactly on the
                   * top of the top subview
                   */
                  return;
                }
              if (v != nil)
                {
                  r1 = [v frame];
                }
              bigRect = r;
              bigRect = NSUnionRect(r1 , bigRect);
              break;
            }
          prev = v;
        }
      else
        {
          if (NSMinX(r) >= p.x)
            {
              offset = i - 1;

              /* get the enclosing rect for the two views */
              if (prev != nil)
                {
                  r = [prev frame];
                }
              else
                {
                  /*
                   * This happens if user pressed exactly on the
                   * left of the left subview
                   */
                  return;
                }
              if (v != nil)
                {
                  r1 = [v frame];
                }
              bigRect = r;
              bigRect = NSUnionRect(r1 , bigRect);
              break;
            }
          prev = v;
        }
    }

  /* Check if the delegate wants to constrain the spliview divider to
     certain positions */
  if (_delegate 
      && [_delegate 
           respondsToSelector:
             @selector(splitView:constrainSplitPosition:ofSubviewAt:)])
    {
      delegateConstrains = YES;
    }
  

  if (_isVertical == NO)
    {
      divVertical = _dividerWidth;
      divHorizontal = NSWidth(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinY(bigRect) + divVertical;
      maxCoord = NSHeight(bigRect) + NSMinY(bigRect) - divVertical;
    }
  else
    {
      divHorizontal = _dividerWidth;
      divVertical = NSHeight(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinX(bigRect) + divHorizontal;
      maxCoord = NSWidth(bigRect) + NSMinX(bigRect) - divHorizontal;
    }

  /* find out what the dragging limit is */
  if (_delegate)
    {
      float delMin = minCoord, delMax = maxCoord;

      if ([_delegate respondsToSelector:
                     @selector(splitView:constrainMinCoordinate:maxCoordinate:ofSubviewAt:)])
        {
          [_delegate splitView: self
                     constrainMinCoordinate: &delMin
                     maxCoordinate: &delMax
                     ofSubviewAt: offset];
        }
      else 
        {
          if ([_delegate respondsToSelector:
                         @selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
            {
              delMin = [_delegate splitView: self
                                  constrainMinCoordinate: minCoord
                                  ofSubviewAt: offset];
            }
          if ([_delegate respondsToSelector:
                         @selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
            {
              delMax = [_delegate splitView: self
                                  constrainMaxCoordinate: maxCoord
                                  ofSubviewAt: offset];
            }
        }

      /* we are still constrained by the original bounds */
      if (delMin > minCoord)
        {
          minCoord = delMin;
        }
      if (delMax < maxCoord)
        {
          maxCoord = delMax;
        }
    }

  oldRect = NSZeroRect;
  [self lockFocus];

  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  [_dividerColor set];
  r.size.width = divHorizontal;
  r.size.height = divVertical;
  e = [app nextEventMatchingMask: eventMask
                       untilDate: farAway
                          inMode: NSEventTrackingRunLoopMode
                         dequeue: YES];

  if (delegateConstrains)
    {
      constrainImp = (floatIMP)[_delegate methodForSelector: constrainSel];
    }
    
  // Save the old position
  op = p;

  // user is moving the knob loop until left mouse up
  while ([e type] != NSLeftMouseUp)
    {
      p = [self convertPoint: [e locationInWindow] fromView: nil];
      if (delegateConstrains)
        {
          if (_isVertical)
            {
              p.x = (*constrainImp)(_delegate, constrainSel, self,
                                    p.x, offset);
            }
          else
            {
              p.y = (*constrainImp)(_delegate, constrainSel, self,
                                    p.y, offset);
            }
        }
      
      if (_isVertical == NO)
        {
          if (p.y < minCoord)
            {
              p.y = minCoord;
            }
          if (p.y > maxCoord)
            {
              p.y = maxCoord;
            }
          r.origin.y = p.y - (divVertical/2.);
          r.origin.x = NSMinX(vis);
        }
      else
        {
          if (p.x < minCoord)
            {
              p.x = minCoord;
            }
          if (p.x > maxCoord)
            {
              p.x = maxCoord;
            }
          r.origin.x = p.x - (divHorizontal/2.);
          r.origin.y = NSMinY(vis);
        }
      if (NSEqualRects(r, oldRect) == NO)
        {
          NSDebugLLog(@"NSSplitView", @"drawing divider at %@\n",
                      NSStringFromRect(r));
          [_dividerColor set];
        
            
          if (lit == YES)
            {
              if (_isVertical == NO)
                {
                  if ((NSMinY(r) > NSMaxY(oldRect)) 
                      || (NSMaxY(r) < NSMinY(oldRect)))
                    // the two rects don't intersect
                    {
                      NSHighlightRect(oldRect);
                      NSHighlightRect(r);
                    }
                  else
                    // the two rects intersect
                    {
                      if (NSMinY(r) > NSMinY(oldRect))
                        {
                          NSRect onRect, offRect;
                          onRect.size.width = r.size.width;
                          onRect.origin.x = r.origin.x;
                          offRect.size.width = r.size.width;
                          offRect.origin.x = r.origin.x;

                          offRect.origin.y = NSMinY(oldRect);
                          offRect.size.height = 
                            NSMinY(r) - NSMinY(oldRect);

                          onRect.origin.y = NSMaxY(oldRect);
                          onRect.size.height = 
                            NSMaxY(r) - NSMaxY(oldRect);

                          NSHighlightRect(onRect);
                          NSHighlightRect(offRect);

                          //NSLog(@"on : %@", NSStringFromRect(onRect));
                          //NSLog(@"off : %@", NSStringFromRect(offRect));
                          //NSLog(@"old : %@", NSStringFromRect(oldRect));
                          //NSLog(@"r : %@", NSStringFromRect(r));
                        }
                      else
                        {
                          NSRect onRect, offRect;
                          onRect.size.width = r.size.width;
                          onRect.origin.x = r.origin.x;
                          offRect.size.width = r.size.width;
                          offRect.origin.x = r.origin.x;

                          offRect.origin.y = NSMaxY(r);
                          offRect.size.height = 
                            NSMaxY(oldRect) - NSMaxY(r);

                          onRect.origin.y = NSMinY(r);
                          onRect.size.height = 
                            NSMinY(oldRect) - NSMinY(r);

                          NSHighlightRect(onRect);
                          NSHighlightRect(offRect);

                          //NSLog(@"on : %@", NSStringFromRect(onRect));
                          //NSLog(@"off : %@", NSStringFromRect(offRect));
                          //NSLog(@"old : %@", NSStringFromRect(oldRect));
                          //NSLog(@"r : %@", NSStringFromRect(r));
                        }
                    }
                }
              else
                {
                  if ((NSMinX(r) > NSMaxX(oldRect)) 
                      || (NSMaxX(r) < NSMinX(oldRect)))
                    // the two rects don't intersect
                    {
                      NSHighlightRect(oldRect);
                      NSHighlightRect(r);
                    }
                  else
                    // the two rects intersect
                    {
                      if (NSMinX(r) > NSMinX(oldRect))
                        {
                          NSRect onRect, offRect;
                          onRect.size.height = r.size.height;
                          onRect.origin.y = r.origin.y;
                          offRect.size.height = r.size.height;
                          offRect.origin.y = r.origin.y;

                          offRect.origin.x = NSMinX(oldRect);
                          offRect.size.width = 
                            NSMinX(r) - NSMinX(oldRect);

                          onRect.origin.x = NSMaxX(oldRect);
                          onRect.size.width = 
                            NSMaxX(r) - NSMaxX(oldRect);

                          NSHighlightRect(onRect);
                          NSHighlightRect(offRect);
                        }
                      else
                        {
                          NSRect onRect, offRect;
                          onRect.size.height = r.size.height;
                          onRect.origin.y = r.origin.y;
                          offRect.size.height = r.size.height;
                          offRect.origin.y = r.origin.y;

                          offRect.origin.x = NSMaxX(r);
                          offRect.size.width = 
                            NSMaxX(oldRect) - NSMaxX(r);

                          onRect.origin.x = NSMinX(r);
                          onRect.size.width = 
                            NSMinX(oldRect) - NSMinX(r);

                          NSHighlightRect(onRect);
                          NSHighlightRect(offRect);
                        }
                    }

                }
            }
          else
            {
              NSHighlightRect(r);
            }
          [_window flushWindow];
          /*
          if (lit == YES)
            {
              NSHighlightRect(oldRect);
              lit = NO;
            }
          NSHighlightRect(r);
          */
          lit = YES;
          oldRect = r;
        }

      {
        NSEvent *ee;

        e = [app nextEventMatchingMask: eventMask
                  untilDate: farAway
                  inMode: NSEventTrackingRunLoopMode
                  dequeue: YES];

        if ((ee = [app nextEventMatchingMask: NSLeftMouseUpMask
                       untilDate: longTimeAgo
                       inMode: NSEventTrackingRunLoopMode
                       dequeue: YES]) != nil)
          {
            [app discardEventsMatchingMask:NSLeftMouseDraggedMask
                 beforeEvent:ee];
            e = ee;
          }
        else
          {
            ee = e;
            do
              {
                e = ee;
                ee = [app nextEventMatchingMask: NSLeftMouseDraggedMask
                          untilDate: longTimeAgo
                          inMode: NSEventTrackingRunLoopMode
                          dequeue: YES];
              }
            while (ee != nil);
          }
      }
      
    }

  if (lit == YES)
    {
      [_dividerColor set];
      NSHighlightRect(oldRect);
      lit = NO;
    }

  [self unlockFocus];

  // Divider position hasn't changed don't try to resize subviews  
  if (_isVertical == YES && p.x == op.x)
    {
      [self setNeedsDisplay: YES];
      return;
    }
  else if (_isVertical == NO && p.y == op.y)   
    {
      [self setNeedsDisplay: YES];
      return;
    }

  [nc postNotificationName: NSSplitViewWillResizeSubviewsNotification
                    object: self];

  /* resize the subviews accordingly */
  r = [prev frame];
  if (_isVertical == NO)
    {
      r.size.height = p.y - NSMinY(bigRect) - (divVertical/2.);
      if (NSHeight(r) < 1.)
        {
          r.size.height = 1.;
        }
    }
  else
    {
      r.size.width = p.x - NSMinX(bigRect) - (divHorizontal/2.);
      if (NSWidth(r) < 1.)
        {
          r.size.width = 1.;
        }
    }
  [prev setFrame: r];
  NSDebugLLog(@"NSSplitView", @"drawing PREV at x: %d, y: %d, w: %d, h: %d\n",
             (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),(int)NSHeight(r));

  r1 = [v frame];
  if (_isVertical == NO)
    {
      r1.origin.y = p.y + (divVertical/2.);
      if (NSMinY(r1) < 0.)
        {
          r1.origin.y = 0.;
        }
      r1.size.height = NSHeight(bigRect) - NSHeight(r) - divVertical;
      if (NSHeight(r) < 1.)
        {
          r.size.height = 1.;
        }
    }
  else
    {
      r1.origin.x = p.x + (divHorizontal/2.);
      if (NSMinX(r1) < 0.)
        {
          r1.origin.x = 0.;
        }
      r1.size.width = NSWidth(bigRect) - NSWidth(r) - divHorizontal;
      if (NSWidth(r1) < 1.)
        {
          r1.size.width = 1.;
        }
    }
  [v setFrame: r1];
  NSDebugLLog(@"NSSplitView", @"drawing LAST at x: %d, y: %d, w: %d, h: %d\n",
             (int)NSMinX(r1),(int)NSMinY(r1),(int)NSWidth(r1),
             (int)NSHeight(r1));

  [_window invalidateCursorRectsForView: self];

  [nc postNotificationName: NSSplitViewDidResizeSubviewsNotification
                    object: self];

  [self _autosaveSubviewProportions];

  [self setNeedsDisplay: YES];

  //[self display];
}

- (void) _adjustSubviews: (NSSize)oldSize
{
  SEL delegateMethod = @selector (splitView:resizeSubviewsWithOldSize:);
  
  if (_delegate != nil  && [_delegate respondsToSelector: delegateMethod])     
    {
      [_delegate splitView: self resizeSubviewsWithOldSize: oldSize];
    }
  else
    {
      [self adjustSubviews];
    }
}

- (void) adjustSubviews
{
  /* Try to load the autosaved view proportions, if any; if there are
   * no autosaved view proportions, then manually adjust subviews
   * proportionally to their current sizes.
   */
  NSArray *subs = [self subviews];
  unsigned count = [subs count];
  NSView *views[count];
  NSSize newSize;
  NSPoint newPoint;
  unsigned i;
  BOOL autoloading = NO;
  double proportions[count];

  if (count == 0)
    return;

  [nc postNotificationName: NSSplitViewWillResizeSubviewsNotification
      object: self];

  /* Try loading the autosaved view proportions.  We store the
   * proportions between the size of each view and the size of the
   * whole area occupied by the views.  */
  if (_autosaveName != nil) 
    { 
      NSUserDefaults *defaults;
      NSDictionary *config;
      NSString *splitViewKey;
      
      defaults  = [NSUserDefaults standardUserDefaults];
      splitViewKey = [NSString stringWithFormat: @"NSSplitView Dividers %@", 
                               _autosaveName];
      config = [defaults objectForKey: splitViewKey];
      if (config != nil) 
        {
          autoloading = YES;
          /* Please note that we don't save the 'proportion' of the
           * last view; it will be set up to take exactly the
           * remaining available space.  */
          for (i = 0; i < (count - 1); i++)
            {
              NSNumber *proportion = [config objectForKey: [NSNumber numberWithInt: i]];

              if (proportion == nil)
                {
                  /* If any autosaved proportion is missing, do not do
                   * any autoloading.
                   */
                  autoloading = NO;
                  break;
                }
              else
                {
                  proportions[i] = [proportion doubleValue];
                }
            }
        }
    }

  [subs getObjects: views];

  /* If we haven't managed to load any saved view proportions, compute
   * default proportions using the current view sizes.  */
  if (autoloading == NO)
    {
      float oldTotal = 0.0;
      NSRect frames[count];
      
      for (i = 0; i < count; i++)
        {
          frames[i] = [views[i] frame];
          if (_isVertical == NO)
            {
              oldTotal +=  NSHeight(frames[i]);
            }
          else
            {
              oldTotal +=  NSWidth(frames[i]);
            }
        }

      for (i = 0; i < (count - 1); i++)
        {
          if (_isVertical == NO)
            {
              proportions[i] = (NSHeight(frames[i]))/oldTotal;
            }
          else
            {
              proportions[i] = (NSWidth(frames[i]))/oldTotal;              
            }
        }
    }

  if (_isVertical == NO)
    {
      float newTotal = NSHeight(_bounds) - _dividerWidth*(count - 1);
      float running = 0.0;

      for (i = 0; i < count; i++)
        {
          float newHeight;
          
          if (i < (count - 1))
            {
              newHeight = proportions[i] * newTotal;
            }
          else
            {
              /* Size the last view to take exactly the remaining
               * space.  */
              newHeight = NSHeight(_bounds) - running;
            }
          newSize = NSMakeSize(NSWidth(_bounds), newHeight);
          newPoint = NSMakePoint(0.0, running);
          running += newHeight + _dividerWidth;
          [views[i] setFrameSize: newSize];
          [views[i] setFrameOrigin: newPoint];
        }
    }
  else
    {
      float newTotal = NSWidth(_bounds) - _dividerWidth*(count - 1);
      float running = 0.0;

      for (i = 0; i < count; i++)
        {
          float newWidth;
          
          if (i < (count - 1))
            {
              newWidth = proportions[i] * newTotal;
            }
          else
            {
              newWidth = NSWidth(_bounds) - running;
            }
          newSize = NSMakeSize(newWidth, NSHeight(_bounds));
          newPoint = NSMakePoint(running, 0.0);
          running += newWidth + _dividerWidth;
          [views[i] setFrameSize: newSize];
          [views[i] setFrameOrigin: newPoint];
        }
    }

  [self setNeedsDisplay: YES];
    
  [nc postNotificationName: NSSplitViewDidResizeSubviewsNotification
      object: self];

  /* Do not autosave if we just autoloaded - there's no point as it
   * would be the same information we just loaded. ;-)  */
  if (autoloading == NO)
    {
      [self _autosaveSubviewProportions];
    }
}

- (CGFloat) dividerThickness 
{
  /*
   * You need to override this method in subclasses to change the
   * dividerThickness (or, without need for subclassing, invoke
   * setDimpleImage:resetDividerThickness:YES below)
   */
  return 6;
}

static inline NSPoint centerSizeInRect(NSSize innerSize, NSRect outerRect)
{
  NSPoint p;
  p.x = MAX(NSMidX(outerRect) - (innerSize.width/2.),0.);
  p.y = MAX(NSMidY(outerRect) - (innerSize.height/2.),0.);
  return p;
}

- (void) drawDividerInRect: (NSRect)aRect
{
  NSPoint dimpleOrigin;
  NSSize dimpleSize;

  /* focus is already on self */
  if (!_dimpleImage)
    {
      return;
    }

  dimpleSize = [_dimpleImage size];

  dimpleOrigin = centerSizeInRect(dimpleSize, aRect);
  /*
   * Images are always drawn with their bottom-left corner at the origin
   * so we must adjust the position to take account of a flipped view.
   */
  if (_rFlags.flipped_view)
    {
      dimpleOrigin.y += dimpleSize.height;
    }
  [_dimpleImage compositeToPoint: dimpleOrigin 
                operation: NSCompositeSourceOver];
}

/* Vertical splitview has a vertical split bar */
- (void) setVertical: (BOOL)flag
{
  _isVertical = flag;
}

- (BOOL) isVertical
{
  return _isVertical;
}

- (BOOL) isSubviewCollapsed: (NSView *)subview
{
  return NSIsEmptyRect([subview frame]);
}

- (BOOL) isPaneSplitter
{
  return _is_pane_splitter;
}

- (void) setIsPaneSplitter: (BOOL)flag
{
  _is_pane_splitter = flag;
}

- (NSString *) autosaveName
{
  return _autosaveName;
}

- (void) setAutosaveName: (NSString *)autosaveName
{
  ASSIGN(_autosaveName, autosaveName);
}

- (CGFloat) maxPossiblePositionOfDividerAtIndex: (NSInteger)dividerIndex
{
  NSArray *subs = [self subviews];
  unsigned count = [subs count];
  NSView *view;

  if ((dividerIndex >= count - 1) || (dividerIndex < 0))
    {
      if (_isVertical)
        {
          return NSMaxX([self bounds]);
        }
      else
        {
          return NSMaxY([self bounds]);
        }
    }

  view = [subs objectAtIndex: dividerIndex + 1];
  if (_isVertical)
    {
      return NSMaxX([view frame]);
    }
  else
    {
      return NSMaxY([view frame]);
    }
}

- (CGFloat) minPossiblePositionOfDividerAtIndex: (NSInteger)dividerIndex
{
  NSArray *subs = [self subviews];
  unsigned count = [subs count];
  NSView *view;

  if ((dividerIndex >= count - 1) || (dividerIndex < 0))
    {
      if (_isVertical)
        {
          return NSMinX([self bounds]);
        }
      else
        {
          return NSMinY([self bounds]);
        }
    }

  view = [subs objectAtIndex: dividerIndex];
  if (_isVertical)
    {
      return NSMinX([view frame]);
    }
  else
    {
      return NSMinY([view frame]);
    }
}

- (void) setPosition: (CGFloat)position 
    ofDividerAtIndex: (NSInteger)dividerIndex
{
  NSArray *subs = [self subviews];
  unsigned count = [subs count];
  CGFloat old_position;
  NSView *prev;
  NSView *next;
  NSRect r, r1;

  if ((dividerIndex >= count - 1) || (dividerIndex < 0))
    {
      return;
    }

  if (_delegate && 
      [_delegate respondsToSelector: 
                     @selector(splitView:constrainSplitPosition:ofSubviewAt:)])
    {
       position = [_delegate splitView: self
                             constrainSplitPosition: position
                             ofSubviewAt: dividerIndex]; 
    }

  // FIXME
  [nc postNotificationName: NSSplitViewWillResizeSubviewsNotification
                    object: self];

  prev = [subs objectAtIndex: dividerIndex];
  next = [subs objectAtIndex: dividerIndex + 1];
  r = [prev frame];
  r1 = [next frame];
  // Compute the old split position
  if (_isVertical == NO)
    {
      old_position = (NSMaxY(r) + NSMinY(r1)) / 2;
    }
  else
    {
      old_position = (NSMaxX(r) + NSMinX(r1)) / 2;
    }

  // Compute new rectangles
  if (_isVertical == NO)
    {
      r.size.height += position - old_position;
      if (NSHeight(r) < 1.)
        {
          r.size.height = 1.;
        }
    }
  else
    {
      r.size.width += position - old_position;
      if (NSWidth(r) < 1.)
        {
          r.size.width = 1.;
        }
    }

  if (_isVertical == NO)
    {
      r1.origin.y += position - old_position;
      r1.size.height -= position - old_position;
      if (NSHeight(r) < 1.)
        {
          r.size.height = 1.;
        }
    }
  else
    {
      r1.origin.x += position - old_position;
      r1.size.width -= position - old_position;
      if (NSWidth(r1) < 1.)
        {
          r1.size.width = 1.;
        }
    }

  /* resize the subviews accordingly */
  [prev setFrame: r];
  [next setFrame: r1];
}


/* Overridden Methods */
- (void) drawRect: (NSRect)r
{
  NSArray *subs = [self subviews];
  int i, count = [subs count];
  id v;
  NSRect divRect;

  if ([self isOpaque])
    {
      [_backgroundColor set];
      NSRectFill(r);
    }

  /* draw the dimples */
  for (i = 0; i < (count-1); i++)
    {
      v = [subs objectAtIndex: i];
      divRect = [v frame];
      if (_isVertical == NO)
        {
          divRect.origin.y = NSMaxY (divRect);
          divRect.size.height = _dividerWidth;
        }
      else
        {
          divRect.origin.x = NSMaxX (divRect);
          divRect.size.width = _dividerWidth;
        }
      [self drawDividerInRect: divRect];
    }
}

- (BOOL) isFlipped
{
  return YES;
}

- (BOOL) isOpaque
{
  return YES;
}

- (void) resizeSubviewsWithOldSize: (NSSize) oldSize
{
  [self _adjustSubviews: oldSize];
  [_window invalidateCursorRectsForView: self];
}

- (void) displayRectIgnoringOpacity: (NSRect)aRect
                          inContext: (NSGraphicsContext *)context
{
  if (_window == nil)
    {
      return;
    }
  
  if (_never_displayed_before == YES)
    {
      _never_displayed_before = NO;
      [self _adjustSubviews: _frame.size];
    }

  [super displayRectIgnoringOpacity: aRect inContext: context];
}

- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  if (_delegate)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
    }
  _delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(splitView##notif_name:)]) \
    [nc addObserver: _delegate \
           selector: @selector(splitView##notif_name:) \
               name: NSSplitView##notif_name##Notification \
             object: self]

  SET_DELEGATE_NOTIFICATION(DidResizeSubviews);
  SET_DELEGATE_NOTIFICATION(WillResizeSubviews);
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  if([aCoder allowsKeyedCoding])
    {
      [aCoder encodeBool: _isVertical forKey: @"NSIsVertical"];
      [aCoder encodeObject: _autosaveName forKey: @"NSAutosaveName"];
    }
  else
    {
      /*
       *        Encode objects we don't own.
       */
      [aCoder encodeConditionalObject: _delegate];
      
      /*
       *        Encode the objects we do own.
       */
      [aCoder encodeObject: _dimpleImage];
      [aCoder encodeObject: _backgroundColor];
      [aCoder encodeObject: _dividerColor];
      
      /*
       *        Encode the rest of the ivar data.
       */
      [aCoder encodeValueOfObjCType: @encode(int) at: &_draggedBarWidth];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isVertical];
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super initWithCoder: aDecoder];
 
  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSIsVertical"])
        {
          [self setVertical: [aDecoder decodeBoolForKey: @"NSIsVertical"]];
        }

      if ([aDecoder containsValueForKey: @"NSAutosaveName"])
        {
          [self setAutosaveName: [aDecoder decodeObjectForKey: @"NSAutosaveName"]];
        }

      _dividerWidth = [self dividerThickness];
      _draggedBarWidth = 8; // default bigger than dividerThickness
      ASSIGN(_dividerColor, [NSColor controlShadowColor]);
      ASSIGN(_backgroundColor, [NSColor controlBackgroundColor]);
      ASSIGN(_dimpleImage, [NSImage imageNamed: @"common_Dimple"]); 
      _never_displayed_before = YES;
      _is_pane_splitter = YES;
      [self setAutoresizesSubviews: YES];
    }
  else
    {
      // Decode objects that we don't retain.
      [self setDelegate: [aDecoder decodeObject]];

      // Decode objects that we do retain.
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_dimpleImage];
      if (_dimpleImage == nil)
        ASSIGN(_dimpleImage, [NSImage imageNamed: @"common_Dimple"]);

      [aDecoder decodeValueOfObjCType: @encode(id) at: &_backgroundColor];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_dividerColor];

      // Decode non-object data.
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_draggedBarWidth];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isVertical];

      _dividerWidth = [self dividerThickness];
      _never_displayed_before = YES;
    }

  return self;
}

@end

@implementation NSSplitView (GNUstepExtra)

/*
 * FIXME: Perhaps the following two should be removed and _dividerWidth 
 * should be used also for dragging?
 */
- (CGFloat) draggedBarWidth
{
  //defaults to 8
  return _draggedBarWidth;
}

- (void) setDraggedBarWidth: (CGFloat)newWidth
{
  _draggedBarWidth = newWidth;
}

- (void) setDimpleImage: (NSImage*)anImage resetDividerThickness: (BOOL)flag
{
  ASSIGN(_dimpleImage, anImage);

  if (flag)
    {
      NSSize s = NSMakeSize(6., 6.);

      if (_dimpleImage)
        s = [_dimpleImage size];
      if (_isVertical)
        _dividerWidth = s.width;
      else
        _dividerWidth = s.height;
    }
}

- (NSImage*) dimpleImage
{
  return _dimpleImage;
}

- (NSColor*) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN(_backgroundColor, aColor);
}

- (NSColor*) dividerColor
{
  return _dividerColor;
}

- (void) setDividerColor: (NSColor*) aColor
{
  ASSIGN(_dividerColor, aColor);
}

@end
