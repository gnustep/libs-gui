/*
   NSScroller.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   A completely rewritten version of the original source by Scott Christley.
   Date: July 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <gnustep/gui/config.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSRunLoop.h>

#include <AppKit/NSScroller.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>

#define ASSIGN(a, b) \
  [b retain]; \
  [a release]; \
  a = b;

@implementation NSScroller

/* Class variables */

/* These button cells are used by all scroller instances to draw the scroller
   buttons and the knob. */
static NSButtonCell* upCell = nil;
static NSButtonCell* downCell = nil;
static NSButtonCell* leftCell = nil;
static NSButtonCell* rightCell = nil;
static NSButtonCell* knobCell = nil;

+ (void)initialize
{
  if (self == [NSScroller class]) {
    /* The current version */
    [self setVersion:1];
  }
}

+ (float)scrollerWidth				{ return 18; }
- (NSScrollArrowPosition)arrowsPosition		{ return _arrowsPosition; }
- (NSUsableScrollerParts)usableParts		{ return _usableParts; }
- (float)knobProportion				{ return _knobProportion; }
- (NSScrollerPart)hitPart			{ return _hitPart; }
- (float)floatValue				{ return _floatValue; }
- (void)setAction:(SEL)action			{ _action = action; }
- (SEL)action					{ return _action; }
- (void)setTarget:(id)target			{ ASSIGN(_target, target); }
- (id)target					{ return _target; }

- initWithFrame:(NSRect)frameRect
{
  /* Determine if its horizontal or vertical
     then adjust the width to the standard */
  if (frameRect.size.width > frameRect.size.height) {
    _isHorizontal = YES;
    frameRect.size.height = [isa scrollerWidth];
  }
  else {
    _isHorizontal = NO;
    frameRect.size.width = [isa scrollerWidth];
  }

  [super initWithFrame:frameRect];

  if (_isHorizontal)
    _arrowsPosition = NSScrollerArrowsMinEnd;
  else
    _arrowsPosition = NSScrollerArrowsMaxEnd;

  _hitPart = NSScrollerNoPart;
  [self drawParts];
  [self setEnabled:NO];
  [self checkSpaceForParts];

  return self;
}

- init
{
  return [self initWithFrame:NSZeroRect];
}

- (void)drawParts
{
  /* Create the class variable button cells if they are not already created */
  if (knobCell)
    return;

  upCell = [NSButtonCell new];
  [upCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
  [upCell setImage:[NSImage imageNamed:@"common_ArrowUp"]];
  [upCell setAlternateImage:[NSImage imageNamed:@"common_ArrowUpH"]];
  [upCell setImagePosition:NSImageOnly];
  [upCell setContinuous:YES];
  [upCell setPeriodicDelay:0.05 interval:0.05];

  downCell = [NSButtonCell new];
  [downCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
  [downCell setImage:[NSImage imageNamed:@"common_ArrowDown"]];
  [downCell setAlternateImage:[NSImage imageNamed:@"common_ArrowDownH"]];
  [downCell setImagePosition:NSImageOnly];
  [downCell setContinuous:YES];
  [downCell setPeriodicDelay:0.05 interval:0.05];

  leftCell = [NSButtonCell new];
  [leftCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
  [leftCell setImage:[NSImage imageNamed:@"common_ArrowLeft"]];
  [leftCell setAlternateImage:[NSImage imageNamed:@"common_ArrowLeftH"]];
  [leftCell setImagePosition:NSImageOnly];
  [leftCell setContinuous:YES];
  [leftCell setPeriodicDelay:0.05 interval:0.05];

  rightCell = [NSButtonCell new];
  [rightCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
  [rightCell setImage:[NSImage imageNamed:@"common_ArrowRight"]];
  [rightCell setAlternateImage:[NSImage imageNamed:@"common_ArrowRightH"]];
  [rightCell setImagePosition:NSImageOnly];
  [rightCell setContinuous:YES];
  [rightCell setPeriodicDelay:0.05 interval:0.05];

  knobCell = [NSButtonCell new];
  [knobCell setButtonType:NSMomentaryChangeButton];
  [knobCell setImage:[NSImage imageNamed:@"common_Dimple"]];
  [knobCell setImagePosition:NSImageOnly];
}

- (void)_setTargetAndActionToCells
{
  [upCell setTarget:_target];
  [upCell setAction:_action];

  [downCell setTarget:_target];
  [downCell setAction:_action];

  [leftCell setTarget:_target];
  [leftCell setAction:_action];

  [rightCell setTarget:_target];
  [rightCell setAction:_action];

  [knobCell setTarget:_target];
  [knobCell setAction:_action];
}

- (void)checkSpaceForParts
{
  NSSize frameSize = [self frame].size;
  float size = (_isHorizontal ? frameSize.width : frameSize.height);
  float scrollerWidth = [isa scrollerWidth];

  if (size > 3 * scrollerWidth + 2)
    _usableParts = NSAllScrollerParts;
  else if (size > 2 * scrollerWidth + 1)
    _usableParts = NSOnlyScrollerArrows;
  else if (size > scrollerWidth)
    _usableParts = NSNoScrollerParts;
}

- (void)setEnabled:(BOOL)flag
{
  if (_isEnabled == flag)
    return;

  _isEnabled = flag;
#if 1
  [self setNeedsDisplay:YES];
#else
  [self display];
#endif
}

- (void)setArrowsPosition:(NSScrollArrowPosition)where
{
  if (_arrowsPosition == where)
    return;

  _arrowsPosition = where;
#if 1
  [self setNeedsDisplay:YES];
#else
  [self display];
#endif
}

- (void)setFloatValue:(float)aFloat
{
  if (aFloat < 0)
    _floatValue = 0;
  else if (aFloat > 1)
    _floatValue = 1;
  else
    _floatValue = aFloat;

  [self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void)setFloatValue:(float)aFloat
       knobProportion:(float)ratio
{
  if (ratio < 0)
    _knobProportion = 0;
  else if (ratio > 1)
    _knobProportion = 1;
  else
    _knobProportion = ratio;

  [self setFloatValue:aFloat];
}

- (void)setFrame:(NSRect)frameRect
{
  /* Determine if its horizontal or vertical
     then adjust the width to the standard */
  if (frameRect.size.width > frameRect.size.height) {
    _isHorizontal = YES;
    frameRect.size.height = [isa scrollerWidth];
  }
  else {
    _isHorizontal = NO;
    frameRect.size.width = [isa scrollerWidth];
  }

  [super setFrame:frameRect];

  if (_isHorizontal)
    _arrowsPosition = NSScrollerArrowsMinEnd;
  else
    _arrowsPosition = NSScrollerArrowsMaxEnd;

  _hitPart = NSScrollerNoPart;
  [self checkSpaceForParts];
}

- (void)setFrameSize:(NSSize)size
{
  [super setFrameSize:size];
  [self checkSpaceForParts];
#if 1
  [self setNeedsDisplay:YES];
#else
  [self display];
  [[self window] flushWindow];
#endif
}

- (NSScrollerPart)testPart:(NSPoint)thePoint
{
  NSRect rect;

  if (thePoint.x < 0 || thePoint.x > frame.size.width
      || thePoint.y < 0 || thePoint.y > frame.size.height)
    return NSScrollerNoPart;

  rect = [self rectForPart:NSScrollerDecrementLine];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerDecrementLine;

  rect = [self rectForPart:NSScrollerIncrementLine];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerIncrementLine;

  rect = [self rectForPart:NSScrollerKnob];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerKnob;

  rect = [self rectForPart:NSScrollerKnobSlot];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerKnobSlot;

  rect = [self rectForPart:NSScrollerDecrementPage];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerDecrementPage;

  rect = [self rectForPart:NSScrollerIncrementPage];
  if ([self mouse:thePoint inRect:rect])
    return NSScrollerIncrementPage;

  return NSScrollerNoPart;
}

- (float)_floatValueForMousePoint:(NSPoint)point
{
  NSRect knobRect = [self rectForPart:NSScrollerKnob];
  NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];
  float floatValue = 0;
  float position;

  if (_isHorizontal) {
    /* Adjust the point to lie inside the knob slot */
    if (point.x < slotRect.origin.x + knobRect.size.width / 2)
      position = slotRect.origin.x + knobRect.size.width / 2;
    else if (point.x > slotRect.origin.x + slotRect.size.width
			    - knobRect.size.width / 2)
      position = slotRect.origin.x + slotRect.size.width
		    - knobRect.size.width / 2;
    else
      position = point.x;

    /* Compute the float value considering the knob size */
    floatValue = (position - (slotRect.origin.x + knobRect.size.width / 2))
		  / (slotRect.size.width - knobRect.size.width);
  }
  else {
    /* Adjust the point to lie inside the knob slot */
    if (point.y < slotRect.origin.y + knobRect.size.height / 2)
      position = slotRect.origin.y + knobRect.size.height / 2;
    else if (point.y > slotRect.origin.y + slotRect.size.height
			    - knobRect.size.height / 2)
      position = slotRect.origin.y + slotRect.size.height
			    - knobRect.size.height / 2;
    else
      position = point.y;

    /* Compute the float value */
    floatValue = (position - (slotRect.origin.y + knobRect.size.height/2))
		  / (slotRect.size.height - knobRect.size.height);
    floatValue = 1 - floatValue;
  }

  return floatValue;
}

- (void)mouseDown:(NSEvent*)theEvent
{
  NSPoint location = [self convertPoint:[theEvent locationInWindow]
			   fromView:nil];

  [self lockFocus];
  _hitPart = [self testPart:location];
  [self _setTargetAndActionToCells];

  switch (_hitPart) {
    case NSScrollerIncrementLine:
    case NSScrollerDecrementLine:
    case NSScrollerIncrementPage:
    case NSScrollerDecrementPage:
      [self trackScrollButtons:theEvent];
      break;

    case NSScrollerKnob:
      [self trackKnob:theEvent];
      break;

    case NSScrollerKnobSlot: {
      float floatValue = [self _floatValueForMousePoint:location];

      [self setFloatValue:floatValue];
      [self sendAction:_action to:_target];
#if 0
      [self drawKnobSlot];
      [self drawKnob];
      [[self window] flushWindow];
#endif
      [self trackKnob:theEvent];
      break;
    }

    case NSScrollerNoPart:
      break;
  }

  _hitPart = NSScrollerNoPart;
  [self unlockFocus];
}

- (void)trackKnob:(NSEvent*)theEvent
{
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			   | NSLeftMouseDraggedMask | NSMouseMovedMask
			   | NSPeriodicMask;
  NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  NSRect knobRect = [self rectForPart:NSScrollerKnob];
  NSEventType eventType = [theEvent type];
  float oldFloatValue = _floatValue;

  _hitPart = NSScrollerKnob;
  [NSEvent startPeriodicEventsAfterDelay:0.05 withPeriod:0.05];
  [[NSRunLoop currentRunLoop] limitDateForMode:NSEventTrackingRunLoopMode];

  while (eventType != NSLeftMouseUp) {
    theEvent = [[NSApplication sharedApplication]
		 nextEventMatchingMask:eventMask
		 untilDate:[NSDate distantFuture] 
		 inMode:NSEventTrackingRunLoopMode
		 dequeue:YES];
    eventType = [theEvent type];

    if (eventType != NSPeriodic)
      point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    else if (point.x != knobRect.origin.x || point.y != knobRect.origin.y) {
      float floatValue = [self _floatValueForMousePoint:point];

      if (floatValue != oldFloatValue) {
	[self setFloatValue:floatValue];
#if 1
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
#else
	[self drawKnobSlot];
	[self drawKnob];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	[[self window] flushWindow];
#endif
	[self sendAction:_action to:_target];
	oldFloatValue = floatValue;
      }
      knobRect.origin = point;
    }
  }

  [NSEvent stopPeriodicEvents];
}

- (void)trackScrollButtons:(NSEvent*)theEvent
{
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
			   | NSLeftMouseDraggedMask | NSMouseMovedMask;
  NSPoint location;
  NSEventType eventType;
  BOOL shouldReturn = NO;
  id theCell = nil;

  NSDebugLog (@"trackScrollButtons");
  do {
    NSRect rect = [self rectForPart:_hitPart];

    switch (_hitPart) {
      case NSScrollerIncrementLine:
      case NSScrollerIncrementPage:
	theCell = (_isHorizontal ? rightCell : upCell);
	break;

      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
	theCell = (_isHorizontal ? leftCell : downCell);
	break;

      default:
	theCell = nil;
	break;
    }

    if (theCell) {
	  [theCell highlight:YES withFrame:rect inView:self];	// highlight cell
	  [self setNeedsDisplayInRect:rect];		
      NSDebugLog (@"tracking cell %x", theCell);
      /* Track the mouse until mouse goes up */
      shouldReturn = [theCell trackMouse:theEvent
			      inRect:rect
			      ofView:self
			      untilMouseUp:NO];

      /* Now unhighlight the cell */
      [theCell highlight:NO withFrame:rect inView:self];
#if 1
      [self setNeedsDisplayInRect:rect];
#else
      [theCell drawWithFrame:rect inView:self];
      [self setNeedsDisplayInRect:rect];
      [[self window] flushWindow];
#endif
    }

    if (shouldReturn)
      break;

    theEvent = [[NSApplication sharedApplication]
		 nextEventMatchingMask:eventMask
		 untilDate:[NSDate distantFuture] 
		 inMode:NSEventTrackingRunLoopMode
		 dequeue:YES];
    eventType = [theEvent type];
    location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _hitPart = [self testPart:location];
  } while (eventType != NSLeftMouseUp);
  NSDebugLog (@"return from trackScrollButtons");
}

- (BOOL)sendAction:(SEL)action to:(id)target
{
  [target performSelector:action withObject:self];
  return YES;
}

- (void)encodeWithCoder:aCoder
{}

- initWithCoder:aDecoder
{
  return self;
}

- (void)drawRect:(NSRect)rect
{
  NSDebugLog (@"NSScroller drawRect: ((%f, %f), (%f, %f))",
	rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  /* Draw the scroller buttons */
  [self drawArrow:NSScrollerDecrementArrow highlight:NO];
  [self drawArrow:NSScrollerIncrementArrow highlight:NO];

  /* Draw the knob slot */
  [self drawKnobSlot];

  /* Draw the knob */
  [self drawKnob];
}

- (void)drawArrow:(NSScrollerArrow)whichButton
	highlight:(BOOL)flag
{
  NSRect rect = [self rectForPart:(whichButton == NSScrollerIncrementArrow
					? NSScrollerIncrementLine
					: NSScrollerDecrementLine)];
  id theCell = nil;

  NSDebugLog (@"position of %s cell is (%f, %f)",
	 (whichButton == NSScrollerIncrementArrow ? "increment" : "decrement"),
	 rect.origin.x, rect.origin.y);

  switch (whichButton) {
    case NSScrollerDecrementArrow:
      theCell = (_isHorizontal ? leftCell : downCell);
      break;
    case NSScrollerIncrementArrow:
      theCell = (_isHorizontal ? rightCell : upCell);
      break;
  }

  [theCell drawWithFrame:rect inView:self];
}

- (void)drawKnob
{
  NSRect rect = [self rectForPart:NSScrollerKnob];
  [knobCell drawWithFrame:rect inView:self];
}

/* The following methods should be implemented in the backend */

- (NSRect)rectForPart:(NSScrollerPart)partCode
{
  return NSZeroRect;
}

- (void)drawKnobSlot
{}

@end
