/* 
   NSColorWell.m

   NSControl for selecting and display a single color value.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: May 1998
   
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
#include <AppKit/NSActionCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSWindow.h>
#include <Foundation/NSNotification.h>

static NSString *GSColorWellDidBecomeExclusiveNotification =
                    @"GSColorWellDidBecomeExclusiveNotification";

@implementation NSColorWell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSColorWell class])
    {
      [self setVersion: 1];
    }
}

/*
 * Instance methods
 */

- (BOOL) acceptsFirstMouse: (NSEvent *)event
{
  return YES;
}

- (SEL) action
{
  return _action;
}

- (void) activate: (BOOL)exclusive
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSColorPanel		*colorPanel = [NSColorPanel sharedColorPanel];

  if (exclusive == YES)
    {
      [nc postNotificationName: GSColorWellDidBecomeExclusiveNotification
                        object: self];
    }

  [nc addObserver: self
         selector: @selector(deactivate)
             name: GSColorWellDidBecomeExclusiveNotification
           object: nil];

  _is_active = YES;

  [colorPanel setColor: _the_color];
  [colorPanel orderFront: self];

  [self setNeedsDisplay: YES];
}

- (NSColor *) color
{
  return _the_color;
}

- (void) deactivate
{
  _is_active = NO;

  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [self setNeedsDisplay: YES];
}

- (void) dealloc
{
  if (_is_active == YES)
    {
      [self deactivate];
    }
  TEST_RELEASE(_the_color);
  [self unregisterDraggedTypes];
  [super dealloc];
}

- (unsigned int) draggingEntered: (id <NSDraggingInfo>)sender
{
  NSPasteboard *pb;
  NSDragOperation sourceDragMask;
       
  NSDebugLLog(@"NSColorWell", @"%@: draggingEntered", self);
  sourceDragMask = [sender draggingSourceOperationMask];
  pb = [sender draggingPasteboard];
 
  if ([[pb types] indexOfObject: NSColorPboardType] != NSNotFound)
    {
      if (sourceDragMask & NSDragOperationCopy)
        {
          return NSDragOperationCopy;
        }
    }
 
  return NSDragOperationNone;
} 

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationCopy;
}

- (void) drawRect: (NSRect)clipRect
{
  NSRect aRect = _bounds;
  
  if (NSIntersectsRect(aRect, clipRect) == NO)
    {
      return;
    }

  if (_is_bordered == YES)
    {
      /*
       * Draw border.
       */
      NSDrawButton(aRect, clipRect);

      /*
       * Fill in control color.
       */
      aRect = NSInsetRect(aRect, 2.0, 2.0);
      if (_is_active == YES)
	{
	  [[NSColor selectedControlColor] set];
	}
      else
	{
	  [[NSColor controlColor] set];
	}
      NSRectFill(NSIntersectionRect(aRect, clipRect));

      /*
       * Set an inset rect for the color area
       */
      _wellRect = NSInsetRect(_bounds, 8.0, 8.0);
    }
  else
    {
      _wellRect = _bounds;
    }

  aRect = _wellRect;

  /*
   * OpenStep 4.2 behavior is to omit the inner border for
   * non-enabled NSColorWell objects.
   */
  if ([self isEnabled])
    {
      /*
       * Draw inner frame.
       */
      NSDrawGrayBezel(aRect, clipRect);
      aRect = NSInsetRect(aRect, 2.0, 2.0);
    }

  [self drawWellInside: NSIntersectionRect(aRect, clipRect)];
}

- (void) drawWellInside: (NSRect)insideRect
{
  if (NSIsEmptyRect(insideRect))
    {
      return;
    }
  [_the_color drawSwatchInRect: insideRect];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: _the_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_active];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (self != nil)
    {
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_the_color];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_active];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_target];
      // Undo RETAIN by decoder
      TEST_RELEASE(_target);
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
    }
  return self;
}

- (id) initWithFrame: (NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if (self != nil)
    {
      _is_bordered = YES;
      _is_active = NO;
      _the_color = RETAIN([NSColor blackColor]);

      [self registerForDraggedTypes:
	[NSArray arrayWithObjects: NSColorPboardType, nil]];
    }
  return self;
}

- (BOOL) isActive
{
  return _is_active;
}

- (BOOL) isBordered
{
  return _is_bordered;
}

- (BOOL) isOpaque
{
  return _is_bordered;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint point = [self convertPoint: [theEvent locationInWindow]
                            fromView: nil];

  if ([self mouse: point inRect: _wellRect])
    {
      [NSColorPanel dragColor: _the_color
                    withEvent: theEvent
                     fromView: self];
    }
  else if (_is_active == NO)
    {
      [self activate: YES];
    }
  else
    {
      [self deactivate];
    }
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
         
  NSDebugLLog(@"NSColorWell", @"%@: performDragOperation", self);
  [self setColor: [NSColor colorFromPasteboard: pb]];
  return YES;
}
 
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  return YES;
}
 
- (void) setAction: (SEL)action
{
  _action = action;
}

- (void) setBordered: (BOOL)bordered
{
  _is_bordered = bordered;
  [self setNeedsDisplay: YES];
}

- (void) setColor: (NSColor *)color
{
  ASSIGN(_the_color, color);
  /*
   * Experimentation with NeXTstep shows that when the color of an active
   * colorwell is set, the color of the shared color panel is set too,
   * though this does not raise the color panel, only the event of
   * activation does that.
   */
  if ([self isActive])
    {
      NSColorPanel	*colorPanel = [NSColorPanel sharedColorPanel];

      [colorPanel setColor: _the_color];
    }
  // Notify our target of colour change
  [self sendAction: _action to: _target];
  [self setNeedsDisplay: YES];
}

- (void) setTarget: (id)target
{
  _target = target;
}

- (void) takeColorFrom: (id)sender
{
  if ([sender respondsToSelector: @selector(color)])
    {
      [self setColor: [sender color]];
    }
}

- (id) target
{
  return _target;
}

@end

