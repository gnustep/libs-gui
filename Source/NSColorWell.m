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

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorWell class])
    [self setVersion: 1];
}

// FIXME: This is a hack.  An NSColorWell shouldn't need an associated
// cell, but without one the setTarget: and setAction: methods get passed
// to an NSCell object by the superclass (NSControl).  NSCell raises an
// exception on these methods, but NSActionCell actually implements them.
+ (Class)cellClass
{
  return [NSActionCell class];
}

//
// Instance methods
//
- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];

  _is_bordered = YES;
  _is_active = NO;
  _the_color = RETAIN([NSColor blackColor]);

  [self registerForDraggedTypes:
      [NSArray arrayWithObjects: NSColorPboardType, nil]];

  return self;
}

- (void)dealloc
{
  if (_is_active)
    [self deactivate];

  TEST_RELEASE(_the_color);
  [self unregisterDraggedTypes];
  [super dealloc];
}

/*
 * Drawing
 */
- (void) drawRect: (NSRect)clipRect
{
  NSRect aRect = _bounds;
  
  if (NSIntersectsRect(aRect, clipRect) == NO)
    return;

  if (_is_bordered)
    {
      /*
       * Draw border.
       */
      NSDrawButton(aRect, clipRect);

      /*
       * Fill in control color.
       */
      aRect = NSInsetRect(aRect, 2.0, 2.0);
      if (_is_active)
        [[NSColor selectedControlColor] set];
      else
        [[NSColor controlColor] set];
      NSRectFill(NSIntersectionRect(aRect, clipRect));

      /*
       * Set an inset rect for the color area
       */
      _wellRect = NSInsetRect(_bounds, 8.0, 8.0);
    }
  else
    _wellRect = _bounds;

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
      NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];

      [self activate: YES];

      [[NSNotificationCenter defaultCenter]
          addObserver: self
             selector: @selector(deactivate)
                 name: NSWindowWillCloseNotification
               object: colorPanel];

      [colorPanel setColor: _the_color];
      [colorPanel orderFront: self];
    }
  else
    [self deactivate];
}

- (BOOL) isOpaque
{
  return _is_bordered;
}


//
// Activating 
//
- (void)activate: (BOOL)exclusive
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

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
  [self setNeedsDisplay: YES];
}

- (void)deactivate
{
  _is_active = NO;

  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [self setNeedsDisplay: YES];
}

- (BOOL)isActive
{
  return _is_active;
}

//
// Managing Color 
//
- (NSColor *) color
{
  return _the_color;
}

- (void) setColor: (NSColor *)color
{
  ASSIGN(_the_color, color);
  [self setNeedsDisplay: YES];
}

- (void) takeColorFrom: (id)sender
{
  if ([sender respondsToSelector: @selector(color)])
    {
      ASSIGN(_the_color, [sender color]);
    }
}

//
// Managing Borders 
//
- (BOOL) isBordered
{
  return _is_bordered;
}

- (void) setBordered: (BOOL)bordered
{
  _is_bordered = bordered;
  [self setNeedsDisplay: YES];
}

//
// NSDraggingSource
//
  
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationCopy;
}

//
// NSDraggingDestination
//
  
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

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  return YES;
}
 
- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
         
  NSDebugLLog(@"NSColorWell", @"%@: performDragOperation", self);
  [self setColor: [NSColor colorFromPasteboard: pb]];
  return YES;
}
 
//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: _the_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_active];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_the_color];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_active];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];

  return self;
}

@end

