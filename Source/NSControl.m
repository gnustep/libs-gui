/*
   NSControl.m

   The abstract control class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
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

#include <Foundation/NSException.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>

/*
 * Class variables
 */
static Class cellClass;

@implementation NSControl

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSControl class])
    {
      NSDebugLog(@"Initialize NSControl class\n");
      [self setVersion: 1];
      cellClass = [NSCell class];
    }
}

/*
 * Setting the Control's Cell
 */
+ (Class) cellClass
{
  return cellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  cellClass = factoryId ? factoryId : [NSCell class];
}

/*
 * Instance methods
 */
- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];
  [self setCell: AUTORELEASE([cellClass new])];
  tag = 0;

  return self;
}

- (void) dealloc
{
  RELEASE(cell);
  [super dealloc];
}

/*
 * Creating copies
 */
- (id) copyWithZone: (NSZone*)zone
{
  id		c = NSCopyObject(self, 0, zone);
  NSCell	*o = [cell copy];

  [c setCell: o];
  RELEASE(o);
  return c;
}

/*
 * Setting the Control's Cell
 */
- (id) cell
{
  return cell;
}

- (void) setCell: (NSCell *)aCell
{
  if (aCell != nil && [aCell isKindOfClass: [NSCell class]] == NO)
    [NSException raise: NSInvalidArgumentException
		format: @"attempt to set non-cell object for control cell"];

  [cell setControlView: nil];
  [aCell setControlView: self];

  ASSIGN(cell, aCell);
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
}

/*
 * Identifying the Selected Cell
 */
- (id) selectedCell
{
  if ([cell state])
    return cell;
  else
    return nil;
}

- (int) selectedTag
{
  return [[self selectedCell] tag];
}

/*
 * Setting the Control's Value
 */
- (double) doubleValue
{
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

- (void) setDoubleValue: (double)aDouble
{
  [[self selectedCell] setDoubleValue: aDouble];
  [self setNeedsDisplay: YES];
}

- (void) setFloatValue: (float)aFloat
{
  [[self selectedCell] setFloatValue: aFloat];
  [self setNeedsDisplay: YES];
}

- (void) setIntValue: (int)anInt
{
  [[self selectedCell] setIntValue: anInt];
  [self setNeedsDisplay: YES];
}

- (void) setNeedsDisplay
{
  [super setNeedsDisplay: YES];
}

- (void) setStringValue: (NSString *)aString
{
  [[self selectedCell] setStringValue: aString];
  [self setNeedsDisplay: YES];
}

- (NSString *) stringValue
{
  return [[self selectedCell] stringValue];
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
  if (cell)
    return [cell alignment];
  else
    return NSLeftTextAlignment;
}

- (NSFont *) font
{
  if (cell)
    return [cell font];
  else
    return nil;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  if (cell)
    {
      [cell setAlignment: mode];
      [self setNeedsDisplay: YES];
    }
}

- (void) setFont: (NSFont *)fontObject
{
  if (cell)
    [cell setFont: fontObject];
}

- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned)leftDigits
			  right: (unsigned)rightDigits
{
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
}					// FIX ME

/*
 * Resizing the Control
 */
- (void) calcSize
{
}					// FIX ME

- (void) sizeToFit
{
}

/*
 * Displaying the Control and Cell
 */
- (void) drawRect: (NSRect)aRect
{
  [self drawCell: cell];
}

- (void) drawCell: (NSCell *)aCell
{
  if (cell == aCell)
    {
      [cell drawWithFrame: bounds inView: self];
    }
}

- (void) drawCellInside: (NSCell *)aCell
{
  if (cell == aCell)
    {
      [cell drawInteriorWithFrame: bounds inView: self];
    }
}

- (void) selectCell: (NSCell *)aCell
{
  if (cell == aCell)
    [cell setState: 1];
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
  return [cell action];
}

- (BOOL) isContinuous
{
  return [cell isContinuous];
}

- (BOOL) sendAction: (SEL)theAction to: (id)theTarget
{
  NSApplication *theApp = [NSApplication sharedApplication];

  if (theAction)
    return [theApp sendAction: theAction to: theTarget from: self];
  else
    return NO;
}

- (int) sendActionOn: (int)mask
{
  return [cell sendActionOn: mask];
}

- (void) setAction: (SEL)aSelector
{
  [cell setAction: aSelector];
}

- (void) setContinuous: (BOOL)flag
{
  [cell setContinuous: flag];
}

- (void) setTarget: (id)anObject
{
  [cell setTarget: anObject];
}

- (id) target
{
  return [cell target];
}

/*
 * Assigning a Tag
 */
- (void) setTag: (int)anInt
{
  tag = anInt;
}

- (int) tag
{
  return tag;
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
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
			    NSMouseMovedMask | NSLeftMouseDraggedMask |
			    NSRightMouseDraggedMask;

  NSDebugLog(@"NSControl mouseDown\n");

  if (![self isEnabled])
    return;

  if ([cell isContinuous])
    oldActionMask = [cell sendActionOn: 0];
  else
    oldActionMask = [cell sendActionOn: NSPeriodicMask];

  [window _captureMouse: self];

  [self lockFocus];

  e = theEvent;
  while (!done) 		// loop until mouse goes up
    {
      location = [e locationInWindow];
      location = [self convertPoint: location fromView: nil];
      // ask the cell to track the mouse only
      // if the mouse is within the cell
      if ((location.x >= 0) && (location.x < bounds.size.width) &&
		      (location.y >= 0 && location.y < bounds.size.height))
	{
	  [cell highlight: YES withFrame: bounds inView: self];
	  [window flushWindow];
	  if ([cell trackMouse: e
			inRect: bounds
			ofView: self
		  untilMouseUp: YES])
	    done = mouseUp = YES;
	  else
	    {
	      [cell highlight: NO withFrame: bounds inView: self];
	      [window flushWindow];
	    }
	}

      if (done)
	break;

      NSDebugLog(@"NSControl process another event\n");
      e = [theApp nextEventMatchingMask: event_mask
			      untilDate: nil
				 inMode: NSEventTrackingRunLoopMode
				dequeue: YES];
      if ([e type] == NSLeftMouseUp)
	done = YES;
    }

  [window _releaseMouse: self];

  if (mouseUp)
    {
//      	[cell setState: ![cell state]];
      [cell highlight: NO withFrame: bounds inView: self];
      [window flushWindow];
    }
  [self unlockFocus];
  [cell sendActionOn: oldActionMask];

  if (mouseUp)
    [self sendAction: [self action] to: [self target]];
}

- (BOOL) ignoresMultiClick
{
  return NO;
}

- (void) setIgnoresMultiClick: (BOOL)flag
{
}

/*
 * Methods Implemented by the Delegate
 */
- (BOOL) control: (NSControl *)control
		textShouldBeginEditing: (NSText *)fieldEditor
{
  return NO;
}

- (BOOL) control: (NSControl *)control
		textShouldEndEditing: (NSText *)fieldEditor
{
  return NO;
}

- (void) controlTextDidBeginEditing: (NSNotification *)aNotification
{
}

- (void) controlTextDidEndEditing: (NSNotification *)aNotification
{
}

- (void) controlTextDidChange: (NSNotification *)aNotification
{
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(int) at: &tag];
  [aCoder encodeObject: cell];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(int) at: &tag];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell];

  return self;
}

@end
