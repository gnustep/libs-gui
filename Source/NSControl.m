/** <title>NSControl</title>

   <abstract>The abstract control class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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

#include "gnustep/gui/config.h"

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include "AppKit/NSControl.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSCell.h"
#include "AppKit/NSActionCell.h"

/*
 * Class variables
 */
static Class usedCellClass;
static Class cellClass;
static Class actionCellClass;

@implementation NSControl

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSControl class])
    {
      [self setVersion: 1];
      cellClass = [NSCell class];
      usedCellClass = cellClass;
      actionCellClass = [NSActionCell class];
    }
}

/*
 * Setting the Control's Cell
 */
+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  usedCellClass = factoryId ? factoryId : cellClass;
}

/*
 * Instance methods
 */
- (id) initWithFrame: (NSRect)frameRect
{
  NSCell *cell = [[[self class] cellClass] new];

  [super initWithFrame: frameRect];
  [self setCell: cell];
  RELEASE(cell);
  //_tag = 0;

  return self;
}

- (void) dealloc
{
  RELEASE(_cell);
  [super dealloc];
}

/*
 * Setting the Control's Cell
 */
- (id) cell
{
  return _cell;
}

- (void) setCell: (NSCell *)aCell
{
  if (aCell != nil && [aCell isKindOfClass: cellClass] == NO)
    [NSException raise: NSInvalidArgumentException
		format: @"attempt to set non-cell object for control cell"];

  ASSIGN(_cell, aCell);
}

/*
 * Enabling and Disabling the Control
 */
- (BOOL) isEnabled
{
  return [[self selectedCell] isEnabled];
}

- (void) setEnabled: (BOOL)flag
{
  [[self selectedCell] setEnabled: flag];
  if (!flag)
    [self abortEditing];
  [self setNeedsDisplay: YES];
}

/*
 * Identifying the Selected Cell
 */
- (id) selectedCell
{
  return _cell;
}

- (int) selectedTag
{
  NSCell *selected = [self selectedCell];

  if (selected == nil)
    return -1;
  else
    return [selected tag];
}

/*
 * Setting the Control's Value
 */
- (double) doubleValue
{
  // The validation is performed by the NSActionCell
  return [[self selectedCell] doubleValue];
}

- (float) floatValue
{
  return [[self selectedCell] floatValue];
}

- (int) intValue
{
  return [[self selectedCell] intValue];
}

- (NSString *) stringValue
{
  return [[self selectedCell] stringValue];
}

- (id) objectValue
{
  return [[self selectedCell] objectValue];
}

- (void) setDoubleValue: (double)aDouble
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setDoubleValue: aDouble];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setFloatValue: (float)aFloat
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setFloatValue: aFloat];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setIntValue: (int)anInt
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setIntValue: anInt];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setStringValue: (NSString *)aString
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setStringValue: aString];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setObjectValue: (id)anObject
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setObjectValue: anObject];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setNeedsDisplay
{
  [super setNeedsDisplay: YES];
}

/*
 * Interacting with Other Controls
 */
- (void) takeDoubleValueFrom: (id)sender
{
  [[self selectedCell] takeDoubleValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeFloatValueFrom: (id)sender
{
  [[self selectedCell] takeFloatValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeIntValueFrom: (id)sender
{
  [[self selectedCell] takeIntValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeObjectValueFrom: (id)sender
{
  [[self selectedCell] takeObjectValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeStringValueFrom: (id)sender
{
  [[self selectedCell] takeStringValueFrom: sender];
  [self setNeedsDisplay: YES];
}

/*
 * Formatting Text
 */
- (NSTextAlignment) alignment
{
  if (_cell)
    return [_cell alignment];
  else
    return NSNaturalTextAlignment;
}

- (NSFont *) font
{
  if (_cell)
    return [_cell font];
  else
    return nil;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  if (_cell)
    {
      [self abortEditing];

      [_cell setAlignment: mode];
      if (![_cell isKindOfClass: actionCellClass])
	[self setNeedsDisplay: YES];
    }
}

- (void) setFont: (NSFont *)fontObject
{
  if (_cell)
    {
      NSText *editor = [self currentEditor];
      
      [_cell setFont: fontObject];
      if (editor != nil)
	[editor setFont: fontObject];
    }
}

- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned)leftDigits
			  right: (unsigned)rightDigits
{
  [self abortEditing];

  [_cell setFloatingPointFormat: autoRange  left: leftDigits
	 right: rightDigits];
  if (![_cell isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

/*
 * Managing the Field Editor
 */
- (BOOL) abortEditing
{
  return NO;
}

- (NSText *) currentEditor
{
  return nil;
}

- (void) validateEditing
{
}			

/*
 * Resizing the Control
 */
- (void) calcSize
{
}

- (void) sizeToFit
{
  [self setFrameSize: [_cell cellSize]];
}

/*
 * Displaying the Control and Cell
 */
- (BOOL) isOpaque
{
  return [_cell isOpaque];
}

- (void) drawRect: (NSRect)aRect
{
  [self drawCell: _cell];
}

- (void) drawCell: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell drawWithFrame: _bounds inView: self];
    }
}

- (void) drawCellInside: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell drawInteriorWithFrame: _bounds 
	    inView: self];
    }
}

- (void) selectCell: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell setState: 1];
      [self setNeedsDisplay: YES];
    }
}

- (void) updateCell: (NSCell *)aCell
{
  [self setNeedsDisplay: YES];
}

- (void) updateCellInside: (NSCell *)aCell
{
  [self setNeedsDisplay: YES];
}

/*
 * Target and Action
 */
- (SEL) action
{
  return [_cell action];
}

- (BOOL) isContinuous
{
  return [_cell isContinuous];
}

- (BOOL) sendAction: (SEL)theAction to: (id)theTarget
{
  if (theAction)
    return [NSApp sendAction: theAction to: theTarget from: self];
  else
    return NO;
}

- (int) sendActionOn: (int)mask
{
  return [_cell sendActionOn: mask];
}

- (void) setAction: (SEL)aSelector
{
  [_cell setAction: aSelector];
}

- (void) setContinuous: (BOOL)flag
{
  [_cell setContinuous: flag];
}

- (void) setTarget: (id)anObject
{
  [_cell setTarget: anObject];
}

- (id) target
{
  return [_cell target];
}

/*
 * Assigning a Tag
 */
- (void) setTag: (int)anInt
{
  _tag = anInt;
}

- (int) tag
{
  return _tag;
}

/*
 * Activation
 */
- (void) performClick: (id)sender
{
  [_cell performClick: sender];
}

- (BOOL)refusesFirstResponder
{
  return [[self selectedCell] refusesFirstResponder];
}

- (void)setRefusesFirstResponder:(BOOL)flag
{
  [[self selectedCell] setRefusesFirstResponder: flag];
}

- (BOOL) acceptsFirstResponder
{
  return [[self selectedCell] acceptsFirstResponder];
}

/*
 * Tracking the Mouse
 */
- (void) mouseDown: (NSEvent *)theEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];
  BOOL mouseUp = NO, done = NO;
  NSEvent *e;
  int oldActionMask;
  NSPoint location;
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask
    | NSMouseMovedMask | NSLeftMouseDraggedMask | NSOtherMouseDraggedMask
    | NSRightMouseDraggedMask;

  if (![self isEnabled])
    return;

  if (_ignoresMultiClick && ([theEvent clickCount] > 1))
    {
      [super mouseDown: theEvent];
      return;
    }

  if ([_cell isContinuous])
    {
      oldActionMask = [_cell sendActionOn: NSPeriodicMask];
    }
  else
    {
      oldActionMask = [_cell sendActionOn: 0];
    }
  
  [_window _captureMouse: self];
  [self lockFocus];

  e = theEvent;
  while (!done) 		// loop until mouse goes up
    {
      location = [e locationInWindow];
      location = [self convertPoint: location fromView: nil];
      // ask the cell to track the mouse only
      // if the mouse is within the cell
      if ((location.x >= 0) && (location.x < _bounds.size.width) &&
		      (location.y >= 0 && location.y < _bounds.size.height))
	{
	  [_cell highlight: YES withFrame: _bounds inView: self];
	  [_window flushWindow];
	  if ([_cell trackMouse: e
		     inRect: _bounds
		     ofView: self
		     untilMouseUp: [[_cell class] prefersTrackingUntilMouseUp]])
	    done = mouseUp = YES;
	  else
	    {
	      [_cell highlight: NO withFrame: _bounds inView: self];
	      [_window flushWindow];
	    }
	}

      if (done)
	break;

      e = [theApp nextEventMatchingMask: event_mask
			      untilDate: nil
				 inMode: NSEventTrackingRunLoopMode
				dequeue: YES];
      if ([e type] == NSLeftMouseUp)
	done = YES;
    }

  [_window _releaseMouse: self];

  if (mouseUp)
    {
//      	[cell setState: ![cell state]];
      [_cell highlight: NO withFrame: _bounds inView: self];
      [_window flushWindow];
    }

  [self unlockFocus];

  [_cell sendActionOn: oldActionMask];

  if (mouseUp)
    [self sendAction: [self action] to: [self target]];
}

- (void) resetCursorRects
{
  [_cell resetCursorRect: _bounds inView: self];
}

- (BOOL) ignoresMultiClick
{
  return _ignoresMultiClick;
}

- (void) setIgnoresMultiClick: (BOOL)flag
{
  _ignoresMultiClick = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(int) at: &_tag];
  [aCoder encodeObject: _cell];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_ignoresMultiClick];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(int) at: &_tag];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_ignoresMultiClick];

  return self;
}

@end
