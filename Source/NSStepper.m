/** <title>NSStepper</title>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: August 2001

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

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <AppKit/NSStepper.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSStepperCell.h>

//
// class variables
//
id _nsstepperCellClass = nil;

@implementation NSStepper

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSStepper class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSStepperCell class]];
    }
}

//
// Initializing the NSStepper Factory
//
+ (Class) cellClass
{
  return _nsstepperCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _nsstepperCellClass = classId;
}

//
// Instance methods
//

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

//
// Determining the first responder
//
- (BOOL) acceptsFirstResponder
{
  return [self isEnabled];
}

- (BOOL) becomeFirstResponder
{
  [_cell setShowsFirstResponder: YES];
  [self setNeedsDisplay: YES];

  return YES;
}

- (BOOL) resignFirstResponder
{
  [_cell setShowsFirstResponder: NO];
  [self setNeedsDisplay: YES];

  return YES;
}

- (void) keyDown: (NSEvent*)theEvent
{
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

- (double) maxValue
{
  return [_cell maxValue];
}

- (void) setMaxValue: (double)maxValue
{
  [_cell setMaxValue: maxValue];
}

- (double) minValue
{
  return [_cell minValue];
}

- (void) setMinValue: (double)minValue
{
  [_cell setMinValue: minValue];
}

- (double) increment
{
  return [_cell increment];
}

- (void) setIncrement: (double)increment
{
  [_cell setIncrement: increment];
}



- (BOOL)autorepeat
{
  return [_cell autorepeat];
}

- (void)setAutorepeat: (BOOL)autorepeat
{
  [_cell setAutorepeat: autorepeat];
}

- (BOOL)valueWraps
{
  return [_cell valueWraps];
}

- (void)setValueWraps: (BOOL)valueWraps
{
  [_cell setValueWraps: valueWraps];
}

- (void) mouseDown: (NSEvent *)event
{
  NSPoint point = [event locationInWindow];
  NSRect upRect;
  NSRect downRect;
  NSRect rect;
  BOOL isDirectionUp;
  BOOL autorepeat = [_cell autorepeat];

  if([_cell isEnabled] == NO)
    return;

  if([event type] != NSLeftMouseDown)
    return;

  upRect = [_cell upButtonRectWithFrame: _bounds];
  downRect = [_cell downButtonRectWithFrame: _bounds];
  point = [self convertPoint: point fromView: nil];
  
  
  if (NSMouseInRect(point, upRect, NO))
    {
      isDirectionUp = YES;
      rect = upRect;
    }
  else if (NSMouseInRect(point, downRect, NO))
    {
      isDirectionUp = NO;
      rect = downRect;
    }
  else
    {
      return;
    }

  {
    BOOL overButton = YES;
    int ignore = 3;
    unsigned int eventMask = NSLeftMouseUpMask 
      | NSLeftMouseDraggedMask
      | NSPeriodicMask;
      
    NSDate *farAway = [NSDate distantFuture];
    [_window flushWindow];
    [_cell highlight: YES
	   upButton: isDirectionUp
	   withFrame: _bounds
	   inView: self];
    [_window _captureMouse: self];

    if (autorepeat)
      {
	[NSEvent startPeriodicEventsAfterDelay: 0.5 withPeriod: 0.025];
	if (isDirectionUp)
	  [self _increment];
	else
	  [self _decrement];
	[_cell drawWithFrame:_bounds
	       inView:self];
	[_window flushWindow];
      }
    else
	[_window flushWindow];

    event = [NSApp nextEventMatchingMask: eventMask
		   untilDate: farAway
		   inMode: NSEventTrackingRunLoopMode
		   dequeue: YES];
    while([event type] != NSLeftMouseUp)
      {
	if ([event type] == NSPeriodic)
	  {
	    ignore ++;
	    if (ignore == 4) ignore = 0;
	    if (ignore == 0)
	      {
		if (isDirectionUp)
		  [self _increment];
		else
		  [self _decrement];
		[_cell drawWithFrame:_bounds
		       inView:self];
		[_window flushWindow];
	      }
	  }
	else if (NSMouseInRect(point, rect, NO) != overButton)
	  {
	    overButton = !overButton;
	    if (overButton && autorepeat)
	      {
		[NSEvent startPeriodicEventsAfterDelay: 0.5
			 withPeriod: 0.025];
		ignore = 3;
	      }
	    else
	      {
		[NSEvent stopPeriodicEvents];
	      }
	    [_cell highlight: overButton
		   upButton: isDirectionUp
		   withFrame: _bounds
		   inView: self];
	    [_window flushWindow];
	  }
	event = [NSApp nextEventMatchingMask: eventMask
		       untilDate: farAway
		       inMode: NSEventTrackingRunLoopMode
		       dequeue: YES];
	point = [self convertPoint: [event locationInWindow]
		      fromView: nil];
      }
    if (overButton && autorepeat)
      [NSEvent stopPeriodicEvents];
    if (overButton && !autorepeat)
      {
	if (isDirectionUp)
	  [self _increment];
	else
	  [self _decrement];
	[_cell drawWithFrame:_bounds
	       inView:self];
      }
      
    [_cell highlight: NO
	   upButton: isDirectionUp
	   withFrame: _bounds
	   inView: self];
    [_window flushWindow];
    [_window _releaseMouse: self];
  }
}

- (void)_increment
{
  double newValue;
  double maxValue = [_cell maxValue];
  double minValue = [_cell minValue];
  double increment = [_cell increment];
  newValue = [_cell doubleValue] + increment;
  if ([_cell valueWraps])
    {
      if (newValue > maxValue)
	[_cell setDoubleValue: 
		 newValue - maxValue + minValue - 1];
      else if (newValue < minValue)
	[_cell setDoubleValue: 
		 newValue + maxValue - minValue + 1];
      else
	[_cell setDoubleValue: newValue];
    }
  else
    {
      if (newValue > maxValue)
	[_cell setDoubleValue: maxValue];
      else if (newValue < minValue)
	[_cell setDoubleValue: minValue];
      else
	[_cell setDoubleValue: newValue];
    }
  [self sendAction: [self action] to: [self target]];
}

- (void)_decrement
{
  double newValue;
  double maxValue = [_cell maxValue];
  double minValue = [_cell minValue];
  double increment = [_cell increment];
  newValue = [_cell doubleValue] - increment;
  if ([_cell valueWraps])
    {
      if (newValue > maxValue)
	[_cell setDoubleValue: 
		 newValue - maxValue + minValue - 1];
      else if (newValue < minValue)
	[_cell setDoubleValue: 
		 newValue + maxValue - minValue + 1];
      else
	[_cell setDoubleValue: newValue];
    }
  else
    {
      if (newValue > maxValue)
	[_cell setDoubleValue: maxValue];
      else if (newValue < minValue)
	[_cell setDoubleValue: minValue];
      else
	[_cell setDoubleValue: newValue];
    }
  [self sendAction: [self action] to: [self target]];
}

@end

