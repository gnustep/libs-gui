/* 
   NSScroller.m

   The scroller class

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

#include <Foundation/NSCoder.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSActionCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>

//
// Class variables
//
static float gnustep_gui_scroller_width = 18;
id gnustep_gui_nsscroller_class = nil;

@implementation NSScroller

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSScroller class])
    {
      // Initial version
      [self setVersion:1];

      // Set our cell class to NSButtonCell
      [self setCellClass:[NSActionCell class]];
    }
}

//
// Initializing the NSScroller Factory 
//
+ (Class)cellClass
{
  return gnustep_gui_nsscroller_class;
}

+ (void)setCellClass:(Class)classId
{
  gnustep_gui_nsscroller_class = classId;
}

//
// Laying out the NSScroller 
//
+ (float)scrollerWidth
{
  return gnustep_gui_scroller_width;
}

//
// Instance methods
//
- initWithFrame:(NSRect)frameRect
{
  // Determine if its horizontal or vertical
  // then adjust the width to the standard
  if (frameRect.size.width > frameRect.size.height)
    {
      is_horizontal = YES;
      frameRect.size.height = gnustep_gui_scroller_width;
    }
  else
    {
      is_horizontal = NO;
      frameRect.size.width = gnustep_gui_scroller_width;
    }

  [super initWithFrame:frameRect];

  // set our cell
  [self setCell:[[gnustep_gui_nsscroller_class new] autorelease]];
  [self selectCell: cell];

  arrows_position = NSScrollerArrowsMaxEnd;
  knob_proportion = 0.1;
  hit_part = NSScrollerNoPart;
  [self setFloatValue: 0];

  return self;
}

//
// Laying out the NSScroller 
//
- (NSScrollArrowPosition)arrowsPosition
{
  return arrows_position;
}

- (void)checkSpaceForParts
{}

- (NSRect)rectForPart:(NSScrollerPart)partCode
{
  return NSZeroRect;
}

- (void)setArrowsPosition:(NSScrollArrowPosition)where
{
  arrows_position = where;
}

- (NSUsableScrollerParts)usableParts
{
  return NSNoScrollerParts;
}

//
// Setting the NSScroller's Values
//
- (float)knobProportion
{
  return knob_proportion;
}

- (void)setFloatValue:(float)aFloat
       knobProportion:(float)ratio
{
  knob_proportion = ratio;
  [cell setFloatValue: aFloat];
}

- (void)setFloatValue:(float)aFloat
{
  if (aFloat < 0)
    aFloat = 0;
  if (aFloat > 1)
    aFloat = 1;
  [self setNeedsDisplay];
  [super setFloatValue: aFloat];
}

//
// Displaying 
//
- (void)drawRect:(NSRect)rect
{
  // xxx We can add some smarts here so that only the parts
  // which intersect with the rect get drawn.

  [self drawParts];
}

- (void)drawArrow:(NSScrollerArrow)whichButton
	highlight:(BOOL)flag
{}

- (void)drawKnob
{}

- (void)drawParts
{
  // Draw the bar
  [self drawBar];

  // Cache the arrow images
  if (arrows_position != NSScrollerArrowsNone)
    {
      if (!increment_arrow)
	{
	  if (is_horizontal)
	    increment_arrow = [NSImage imageNamed: @"common_ArrowLeft"];
	  else
	    increment_arrow = [NSImage imageNamed: @"common_ArrowUp"];
	}
      if (!decrement_arrow)
	{
	  if (is_horizontal)
	    decrement_arrow = [NSImage imageNamed: @"common_ArrowRight"];
	  else
	    decrement_arrow = [NSImage imageNamed: @"common_ArrowDown"];
	}

      // Draw the arrows
      [self drawArrow: NSScrollerIncrementArrow highlight: NO];
      [self drawArrow: NSScrollerDecrementArrow highlight: NO];
    }

  // Draw the knob
  if (!knob_dimple)
    knob_dimple = [NSImage imageNamed: @"common_Dimple"];
  [self drawKnob];
  [[self window] flushWindow];
}

- (void)highlight:(BOOL)flag
{}

//
// Handling Events 
//
- (NSScrollerPart)hitPart
{
  return hit_part;
}

- (NSScrollerPart)testPart:(NSPoint)thePoint
{
  NSScrollerPart the_part = NSScrollerNoPart;
  NSRect partRect;

  // Test hit on arrow buttons
  if (arrows_position != NSScrollerArrowsNone)
    {
      partRect = [self boundsOfScrollerPart: NSScrollerIncrementLine];
      if ([self mouse: thePoint inRect: partRect])
	the_part = NSScrollerIncrementLine;
      else
	{
	  partRect = [self boundsOfScrollerPart: NSScrollerDecrementLine];
	  if ([self mouse: thePoint inRect: partRect])
	    the_part = NSScrollerDecrementLine;
	}
    }

  // If not on the arrow buttons
  // then test the know area
  if (the_part == NSScrollerNoPart)
    {
      partRect = [self boundsOfScrollerPart: NSScrollerKnob];
      if ([self mouse: thePoint inRect: partRect])
	the_part = NSScrollerKnob;
      else
	{
	  partRect = [self boundsOfScrollerPart: NSScrollerKnobSlot];
	  if ([self mouse: thePoint inRect: partRect])
	    the_part = NSScrollerKnobSlot;
	}
    }

  return the_part;
}

- (void)trackKnob:(NSEvent *)theEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];
  BOOL mouseUp, done;
  NSEvent *e;

  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
    NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow] 
			fromView: nil];
  NSPoint last_point;
  NSRect knobRect = [self boundsOfScrollerPart: NSScrollerKnob];
  NSRect barRect = [self boundsOfScrollerPart: NSScrollerKnobSlot];
  float pos;

  [self lockFocus];

  // capture mouse
  [[self window] captureMouse: self];

  done = NO;
  e = theEvent;
  mouseUp = NO;
  while (!done)
    {
      last_point = point;
      e = [theApp nextEventMatchingMask:event_mask untilDate:nil 
		  inMode:nil dequeue:YES];
      point = [self convertPoint: [e locationInWindow] fromView: nil];

      if (is_horizontal)
	{
	  pos = (point.x - barRect.origin.x - (knobRect.size.width/2))
	    / (barRect.size.width - knobRect.size.width);
	  if (pos < 0) pos = 0;
	  if (pos > 1) pos = 1;
	  [[self cell] setFloatValue: pos];
	  [self drawBar];
	  [self drawKnob];
	  [[self window] flushWindow];
	}
      else
	{
	  pos = (point.y - barRect.origin.y - (knobRect.size.height/2)) 
	    / (barRect.size.height - knobRect.size.height);
	  if (pos < 0) pos = 0;
	  if (pos > 1) pos = 1;
	  [[self cell] setFloatValue: pos];
	  [self drawBar];
	  [self drawKnob];
	  [[self window] flushWindow];
	}

      // Did the mouse go up?
      if ([e type] == NSLeftMouseUp)
	{
	  mouseUp = YES;
	  done = YES;
	}
    }

  // Release mouse
  [[self window] releaseMouse: self];

  // Update the display
  [self drawParts];
  [self unlockFocus];
  [[self window] flushWindow];

  // Have the target perform the action
  [self sendAction:[self action] to:[self target]];
}

- (void)trackScrollButtons:(NSEvent *)theEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];
  BOOL done;
  NSEvent *e;
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
    NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;
  NSRect partRect = [self boundsOfScrollerPart: hit_part];
  NSPoint point = [self convertPoint: [theEvent locationInWindow] 
			fromView: nil];
  NSPoint last_point;
  NSScrollerArrow arrow;
  BOOL arrow_highlighted = NO;

  // Find out which arrow button
  switch (hit_part)
    {
    case NSScrollerDecrementPage:
    case NSScrollerDecrementLine:
      arrow = NSScrollerDecrementArrow;
      break;
    case NSScrollerIncrementPage:
    case NSScrollerIncrementLine:
    default:
      arrow = NSScrollerIncrementArrow;
      break;
    }

  [self lockFocus];

  // capture mouse
  [[self window] captureMouse: self];

  // If point is in arrow then highlight it
  if ([self mouse: point inRect: partRect])
    {
      [self drawArrow: arrow highlight: YES];
      [[self window] flushWindow];
      arrow_highlighted = YES;
    }
  else
    return;

  // Get next mouse events until a mouse up is obtained
  done = NO;
  while (!done)
    {
      last_point = point;
      e = [theApp nextEventMatchingMask:event_mask untilDate:nil 
		  inMode:nil dequeue:YES];

      point = [self convertPoint: [e locationInWindow] fromView: nil];

      // Point is not in arrow
      if (![self mouse: point inRect: partRect])
	{
	  // unhighlight arrow if highlighted
	  if (arrow_highlighted)
	    {
	      [self drawArrow: arrow highlight: NO];
	      [[self window] flushWindow];
	      arrow_highlighted = NO;
	    }
	}
      else
	{
	  // Point is in cell
	  // highlight cell if not highlighted
	  if (!arrow_highlighted)
	    {
	      [self drawArrow: arrow highlight: YES];
	      [[self window] flushWindow];
	      arrow_highlighted = YES;
	    }
	}

      // Did the mouse go up?
      if ([e type] == NSLeftMouseUp)
	done = YES;
    }

  // Release mouse
  [[self window] releaseMouse: self];

  // If the mouse went up in the button
  if ([self mouse: point inRect: partRect])
    {
      // unhighlight arrow
      [self drawArrow: arrow highlight: NO];
      [[self window] flushWindow];
    }

  // Update the display
  [self drawParts];
  [self unlockFocus];
  [[self window] flushWindow];

  // Have the target perform the action
  if ([self mouse: point inRect: partRect])
    [self sendAction:[self action] to:[self target]];
}

//
// Handling Events and Action Messages 
//
- (void)mouseDown:(NSEvent *)theEvent
{
  NSScrollerPart area;
  NSPoint p = [self convertPoint: [theEvent locationInWindow] fromView: nil];

  NSDebugLog(@"NSScroller mouseDown\n");

  // If we are not enabled then ignore the mouse
  if (![self isEnabled])
    return;

  // Test where the mouse down is
  area = [self testPart: p];

  // If we didn't hit anywhere on the scroller then ignore
  if (area == NSScrollerNoPart)
    return;

  // Do we have the ALT key held down?
  if ([theEvent modifierFlags] & NSAlternateKeyMask)
    {
      if (area == NSScrollerDecrementLine)
	area = NSScrollerDecrementPage;
      if (area == NSScrollerIncrementLine)
	area = NSScrollerIncrementPage;
    }
  
  // We must have hit a real part so record it
  hit_part = area;

  // Track the knob if that's where it hit
  if ((hit_part == NSScrollerKnob) || (hit_part == NSScrollerKnobSlot))
    [self trackKnob: theEvent];

  // Track the scroll buttons if that's where it hit
  if ((hit_part == NSScrollerDecrementPage) || 
      (hit_part == NSScrollerDecrementLine) ||
      (hit_part == NSScrollerIncrementPage) ||
      (hit_part == NSScrollerIncrementLine))
    [self trackScrollButtons: theEvent];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_horizontal];
  [aCoder encodeValueOfObjCType: @encode(float) at: &knob_proportion];
  [aCoder encodeValueOfObjCType: @encode(NSScrollerPart) at: &hit_part];
  [aCoder encodeValueOfObjCType: @encode(NSScrollArrowPosition)
	  at: &arrows_position];
  /* xxx What about the images? */
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_horizontal];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &knob_proportion];
  [aDecoder decodeValueOfObjCType: @encode(NSScrollerPart) at: &hit_part];
  [aDecoder decodeValueOfObjCType: @encode(NSScrollArrowPosition)
	    at: &arrows_position];
  /* xxx What about the images? */

  return self;
}

@end

//
// Methods implemented by the backend
//
@implementation NSScroller (GNUstepBackend)

- (void)drawBar
{}

- (NSRect)boundsOfScrollerPart:(NSScrollerPart)part
{
  return NSZeroRect;
}

- (BOOL)isPointInIncrementArrow:(NSPoint)aPoint
{
  return NO;
}

- (BOOL)isPointInDecrementArrow:(NSPoint)aPoint
{
  return NO;
}

- (BOOL)isPointInKnob:(NSPoint)aPoint
{
  return NO;
}

- (BOOL)isPointInBar:(NSPoint)aPoint
{
  return NO;
}

@end
