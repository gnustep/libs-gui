/* 
   NSSplitView.h

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
   
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
#import <Foundation/Foundation.h>
#import <Foundation/NSRunLoop.h>
#import <AppKit/AppKit.h>
#include <string.h>
#include <math.h>


/* Backend protocol - methods that must be implemented by the backend to
   complete the class */
@protocol NSSplitViewBackend
- (void) _fillRect: (NSRect)rect;
@end

@implementation NSSplitView

/* API Methods */

- (void)mouseDown:(NSEvent *)theEvent 
{
  static NSRect oldRect; //only one can be dragged at a time
  NSPoint p;
  NSEvent *e;
  NSRect r, r1, bigRect, vis;
  id v, prev=nil;
  float minCoord,maxCoord;
  NSArray *subs=[self subviews];
  int offset=0,i,count=[subs count];
  float divVertical, divHorizontal, div=[self dividerThickness];
  NSColor *divColor=[self dividerColor];
  NSDate *farAway=[NSDate distantFuture];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
    | NSLeftMouseDraggedMask | NSMouseMovedMask
    | NSPeriodicMask;

  /* 	if there are less the two subviews, there is nothing
	to do
	*/
  if(count<2) return;

  [[self window] setAcceptsMouseMovedEvents:YES];
  vis = [self visibleRect];

  /* find out which divider it is */
  p=[theEvent locationInWindow];
  p = [self convertPoint:p fromView:nil];
  for(i=0;i<count;i++)
    {	
      v=[subs objectAtIndex:i];
      r=[v frame];
      /* if the click is inside of a subview, return.
	 this should never happen */
      if([self isVertical])
        {
	  if((p.y>NSMinY(r)) && (p.y<NSMaxY(r)))
	    goto RETURN_LABEL;
	  if(NSMaxY(r)>p.y)
            {	
	      offset=i;

	      /* get the enclosing rect for the two views */
	      if(prev) r=[prev frame];
	      else r = NSZeroRect;
	      if(v) r1=[v frame];
	      bigRect=r;
	      bigRect=NSUnionRect(r1 , bigRect);
	      break;
            }
	  prev=v;
        }
      else
        {
	  if((p.x>NSMinX(r)) && (p.x<NSMaxX(r)))
	    goto RETURN_LABEL;
	  if((NSMinX(r)+NSWidth(r))>p.x)
            {	
	      offset=i;

	      /* get the enclosing rect for the two views */
	      if(prev) r=[prev frame];
	      else r = NSZeroRect;
	      if(v) r1=[v frame];
	      bigRect=r;
	      bigRect=NSUnionRect(r1 , bigRect);
	      break;
            }
	  prev=v;
        }
    }
  if([self isVertical])
    {
      divVertical=div;
      divHorizontal=NSWidth([self frame]);
      /* set the default limits on the dragging */
      minCoord=NSMinY(bigRect)+divVertical;
      maxCoord=NSHeight(bigRect)+NSMinY(bigRect)-divVertical;
    }
  else
    {
      divHorizontal=div;
      divVertical=NSHeight([self frame]);
      /* set the default limits on the dragging */
      minCoord=NSMinX(bigRect)+divHorizontal;
      maxCoord=NSWidth(bigRect)+NSMinX(bigRect)-divHorizontal;
    }


  /* find out what the dragging limit is */
  if(delegate && [delegate respondsToSelector:@selector
			   (splitView:constrainMinCoordinate:maxCoordinate:ofSubviewAt:)])
    {	
      if([self isVertical])
        {
	  float delMinY=minCoord, delMaxY=maxCoord;
	  [delegate splitView:self
		    constrainMinCoordinate:&delMinY
		    maxCoordinate:&delMaxY
		    ofSubviewAt:offset];
	  /* we are still constrained by the original bounds */
	  if(delMinY>minCoord) minCoord=delMinY;
	  if(delMaxY<maxCoord) maxCoord=delMaxY; 
        }
      else
        {
	  float delMinX=minCoord, delMaxX=maxCoord;
	  [delegate splitView:self
		    constrainMinCoordinate:&delMinX
		    maxCoordinate:&delMaxX
		    ofSubviewAt:offset];
	  /* we are still constrained by the original bounds */
	  if(delMinX>minCoord) minCoord=delMinX;
	  if(delMaxX<maxCoord) maxCoord=delMaxX; 
        }
    }



  oldRect = NSZeroRect;
  [self lockFocus];

  /* FIXME: Are these really needed? */
  [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
  [[NSRunLoop currentRunLoop] limitDateForMode:NSEventTrackingRunLoopMode];
	
  [divColor set];
  r.size.width = divHorizontal;
  r.size.height = divVertical;
  e=[[NSApplication sharedApplication]
      nextEventMatchingMask:eventMask
      untilDate:farAway inMode:NSEventTrackingRunLoopMode dequeue:YES];

  while([e type] != NSLeftMouseUp)
    { 	
      [self displayRect:oldRect];
      if ([e type] != NSPeriodic)
	{
	  p=[e locationInWindow];
	  p = [self convertPoint:p fromView:nil];
	}
      if([self isVertical])
        {
	  if(p.y<minCoord) p.y=minCoord;
	  if(p.y>maxCoord) p.y=maxCoord;
	  r.origin.y = p.y-(divVertical/2.);
	  r.origin.x = NSMinX(vis);
        }
      else
        {
	  if(p.x<minCoord) p.x=minCoord;
	  if(p.x>maxCoord) p.x=maxCoord;
	  r.origin.x = p.x-(divHorizontal/2.);
	  r.origin.y = NSMinY(vis);
        }
      NSDebugLog(@"drawing divider at x:%d, y:%d, w:%d, h:%d\n",
		 (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),
		 (int)NSHeight(r));
      [self _fillRect: r];
      [[NSDPSContext currentContext] flush];
      oldRect=r;
      e=[[NSApplication sharedApplication] 
	  nextEventMatchingMask:eventMask
	  untilDate:farAway inMode:NSEventTrackingRunLoopMode dequeue:YES];
    }

  [self unlockFocus];
  [NSEvent stopPeriodicEvents];

  /* resize the subviews accordingly */
  r = [prev frame];
  if([self isVertical])
    {
      r.size.height=p.y-NSMinY(bigRect)-(divVertical/2.);
      if(NSHeight(r) < 1.) r.size.height=1.;
    }
  else
    {
      r.size.width=p.x-NSMinX(bigRect)-(divHorizontal/2.);
      if(NSWidth(r) < 1.) r.size.width=1.;
    }
  [prev setFrame:r];
  NSDebugLog(@"drawing PREV at x:%d, y:%d, w:%d, h:%d\n",
	     (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),(int)NSHeight(r));

  r1 = [v frame];
  if([self isVertical])
    {
      r1.origin.y=p.y+(divVertical/2.);
      if(NSMinY(r1) < 0.) r1.origin.y=0.;
      r1.size.height=NSHeight(bigRect)-NSHeight(r)-divVertical;
      if(NSHeight(r) < 1.) r.size.height=1.;
    }
  else
    {
      r1.origin.x=p.x+(divHorizontal/2.);
      if(NSMinX(r1) < 0.) r1.origin.x=0.;
      r1.size.width=NSWidth(bigRect)-NSWidth(r)-divHorizontal;
      if(NSWidth(r1) < 1.) r1.size.width=1.;
    }
  [v setFrame:r1];
  NSDebugLog(@"drawing LAST at x:%d, y:%d, w:%d, h:%d\n",
	     (int)NSMinX(r1),(int)NSMinY(r1),(int)NSWidth(r1),
	     (int)NSHeight(r1));

  [[self window] invalidateCursorRectsForView:self];	

RETURN_LABEL:
  [[self window] setAcceptsMouseMovedEvents:NO];
  [self setNeedsDisplay:YES];
}

- (void)adjustSubviews
{
  NSRect fr=[self frame];
  NSSize newSize;
  NSPoint newPoint;
  float total=0.;

  if(delegate && [delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
    {	
      [delegate splitView:self resizeSubviewsWithOldSize:fr.size];
    }
  else
    {	/* split the area up evenly */
      NSArray *subs=[self subviews];
      int i, div, count=[subs count];
      id v;
      int w,h;
      NSRect r, bd=[self bounds];

      div=(int)([self dividerThickness]*(count-1));
      w=(int)ceil((NSWidth(bd)-div)/count);
      h=(int)ceil((NSHeight(bd)-div)/count);
      for(i=0;i<count;i++)
        {	
	  v=[subs objectAtIndex:i];
	  r = [v frame];
	  /* bounds check */
	  if([self isVertical])
            {
	      newSize=NSMakeSize(NSWidth(bd), h);
	      /* make sure nothing spills over */
	      while((total+newSize.height)>(NSHeight(bd)-div))
                {
		  newSize.height-=1.;
                }
	      total+=newSize.height;

	      newPoint=NSMakePoint(0,(float)ceil(i ?
						 (i*([self dividerThickness]+h)) : 0));
	      if(newSize.height<1) newSize.height=1.;
	      if(newPoint.y<1) newPoint.y=1.;
            }
	  else
            {
	      newSize=NSMakeSize(w, NSHeight(bd));
	      /* make sure nothing spills over */
	      while((total+newSize.width)>(NSWidth(bd)-div))
                {
		  newSize.width-=1.;
                }
	      total+=newSize.width;

	      newPoint=NSMakePoint((float)ceil(i ?
					       (i*([self dividerThickness]+w)) : 0), 0);
	      if(newSize.width<1) newSize.width=1.;
	      if(newPoint.x<1) newPoint.x=1.;
            }
	  [v setFrameSize: newSize];
	  [v setFrameOrigin: newPoint];
        }
    }
  [[NSNotificationCenter defaultCenter]
    postNotificationName:NSSplitViewDidResizeSubviewsNotification object:self];
}

- (void)addSubview:(NSView *)aView
	positioned:(NSWindowOrderingMode)place
	relativeTo:(NSView *)otherView
{	
  [super addSubview:aView positioned:place relativeTo:otherView];

  /* register the subviews up for notification */
  //[[NSNotificationCenter defaultCenter] addObserver:aView
  //    selector:@selector(splitViewDidResizeSubviews:)
  //    name:NSSplitViewDidResizeSubviewsNotification object:self];    
  [self adjustSubviews];
}

- (void)addSubview:aView
{
  [super addSubview:aView];
  [self adjustSubviews];
}

- (float)dividerThickness //defaults to 8
{
  return dividerWidth;
}

- (void)setDividerThickNess:(float)newWidth
{
  dividerWidth=newWidth;
}

- (float)draggedBarWidth //defaults to 8
{
  return draggedBarWidth;
}

- (void)setDraggedBarWidth:(float)newWidth
{
  draggedBarWidth=newWidth;
}

NSPoint centerSizeInRect(NSSize innerSize, NSRect outerRect)
{
  NSPoint p;
  p.x=MAX(NSMidX(outerRect)-(innerSize.width/2.),0.);
  p.y=MAX(NSMidY(outerRect)-(innerSize.height/2.),0.);
  return p;
}

NSPoint centerRectInRect(NSRect innerRect, NSRect outerRect)
{
  return centerSizeInRect(innerRect.size,outerRect);
}

- (void)drawDividerInRect:(NSRect)aRect
{
  NSPoint dimpleOrigin;
  NSSize dimpleSize;

  /* focus is already on self */
  if(!dimpleImage) return;
  dimpleSize=[dimpleImage size];

  /* composite into the center of the given rect. Since NSImages
     are always flipped, we adjust for it here */
  dimpleOrigin=centerSizeInRect(dimpleSize,aRect);
  if([self isFlipped]) dimpleOrigin.y+=dimpleSize.height;
  [dimpleImage compositeToPoint:dimpleOrigin operation:NSCompositeSourceOver];
}

- (void)setVertical:(BOOL)flag	/* Vertical splitview has a vertical split bar */
{
  isVertical=flag;
}

- (BOOL)isVertical
{
  return isVertical;
}

- (void)setDimpleImage:(NSImage *)anImage resetDividerThickness:(BOOL)flag
{
  if(dimpleImage==anImage) return;
  [dimpleImage release];
  dimpleImage=[anImage retain];

  if(flag)
    {
      NSSize s={8.,8.};
      if(dimpleImage) s=[dimpleImage size];
      [self setDividerThickNess: isVertical ? s.height : s.width];
    }
}

- (void)drawRect:(NSRect)r
{
  NSArray *subs=[self subviews];
  int i, count=[subs count];
  id v;
  NSRect divRect;

  if([self isOpaque])
    {
      [[self backgroundColor] set];
	  NSRectFill(r);
//      [self _fillRect: [self bounds]];
    }

  /* draw the dimples */
  {
    for(i=0;i<(count-1);i++)
      {	
	v=[subs objectAtIndex:i];
	divRect=[v frame];
	if([self isVertical])
	  {
	    divRect.origin.y=NSMaxY(divRect);
	    divRect.size.height=[self dividerThickness];
	  }
	else
	  {
	    divRect.origin.x=NSMaxX(divRect);
	    divRect.size.width=[self dividerThickness];
	  }
	[self drawDividerInRect:divRect];
      }
  }
}

- (NSImage *)dimpleImage
{
  return dimpleImage;
}

/* Overridden Methods */
- (BOOL)isFlipped
{
  return NO;
}

- (BOOL)isOpaque
{
  return YES;
}

- initWithFrame:(NSRect)frameRect
{	
  if((self=[super initWithFrame:frameRect])!=nil)
    {
      dividerWidth=8;
      draggedBarWidth=8;
      isVertical=NO;
      [self seDividerColor:[NSColor darkGrayColor]];
      [self setBackgroundColor:[NSColor lightGrayColor]];
      [self setDimpleImage:
	     [NSImage imageNamed:@"common_Dimple.tiff"] resetDividerThickness:YES];
    }
  return self;
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{	
  [super resizeWithOldSuperviewSize:oldSize];
  [self adjustSubviews];
  [[self window] invalidateCursorRectsForView:self];
}

- delegate
{	
  return delegate;
}

- (void)setDelegate:anObject
{	
  if(delegate==anObject) return;
  [delegate release];
  delegate=[anObject retain];
}

- (NSColor *)dividerColor
{	
  return dividerColor;
}

- (void)seDividerColor:(NSColor *)aColor
{	
  if(dividerColor==aColor) return;
  [dividerColor release];
  dividerColor=[aColor retain];
}

- (NSColor *)backgroundColor
{	
  return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)aColor
{	
  if(backgroundColor==aColor) return;
  [backgroundColor release];
  backgroundColor=[aColor retain];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  //  NSDebugLog(@"NSSplitView: start encoding\n");
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:delegate];
  [aCoder encodeObject:splitCursor];
  [aCoder encodeObject:dimpleImage];
  [aCoder encodeObject:backgroundColor];
  [aCoder encodeObject:dividerColor];
  [aCoder encodeValueOfObjCType:@encode(int) at: &dividerWidth];
  [aCoder encodeValueOfObjCType:@encode(int) at: &draggedBarWidth];
  [aCoder encodeValueOfObjCType:@encode(BOOL) at: &isVertical];
  //  NSDebugLog(@"NSView: finish encoding\n");
}

- initWithCoder:aDecoder
{
  self=[super initWithCoder:aDecoder];

  //  NSDebugLog(@"NSSplitView: start decoding\n");
  delegate=[aDecoder decodeObject];
  splitCursor=[aDecoder decodeObject];
  dimpleImage=[aDecoder decodeObject];
  backgroundColor=[aDecoder decodeObject];
  dividerColor=[aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType:@encode(int) at: &dividerWidth];
  [aDecoder decodeValueOfObjCType:@encode(int) at: &draggedBarWidth];
  [aDecoder decodeValueOfObjCType:@encode(BOOL) at: &isVertical];
  //  NSDebugLog(@"NSView: finish decoding\n");
  return self;
}

- (void)dealloc
{
  [backgroundColor release];
  [dividerColor release];
  [dimpleImage release];
  [super dealloc];
}

@end
