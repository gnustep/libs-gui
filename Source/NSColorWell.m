/** <title>NSColorWell</title>

   <abstract>Control for selecting and display a single color value.</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: May 1998
   
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

#include "config.h"
#include "AppKit/NSActionCell.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSColorPanel.h"
#include "AppKit/NSColorWell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSDragging.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSTheme.h"
#include <Foundation/NSDebug.h>
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

/**<p>Activates the NSColorWell and displays the NSColorPanel with the current
   NSColorWell's color. The NSColorWell can take color from the NSColorPanel.
   If exclusive is YES other NSColorWells are desacivated
   (through notifications).</p><p>See Also: -deactivate</p>
 */
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

  [nc addObserver: self
         selector: @selector(_takeColorFromPanel:)
             name: NSColorPanelColorChangedNotification
           object: nil];

  _is_active = YES;

  [colorPanel setColor: _the_color];
  [colorPanel orderFront: self];

  [self setNeedsDisplay: YES];
}

/**<p> Returns the current NSColor of the NSColorWell.</p>
   <p> See Also: -setColor:</p>
 */
- (NSColor *) color
{
  return _the_color;
}

/** <p>Deactivates the NSColorWell and marks self for display.
    It is usally call from an observer, when another NSColorWell is 
    activate.</p><p>See Also: -activate:</p>
 */
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

- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)sender
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
      [[GSTheme theme] drawButton: aRect withClip: clipRect];

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
      [[GSTheme theme] drawGrayBezel: aRect withClip: clipRect];
      aRect = NSInsetRect(aRect, 2.0, 2.0);
    }

  [self drawWellInside: NSIntersectionRect(aRect, clipRect)];
}

/**<p>Draws the NSColorWell inside the rectangle <var>insideRect</var>.</p>
   <p>See Also: [NSColor-drawSwatchInRect:]</p>
 */
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
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _the_color forKey: @"NSColor"];
      // [aCoder encodeBool: _is_active forKey: @"NSEnabled"];
      [aCoder encodeBool: _is_bordered forKey: @"NSIsBordered"];
      [aCoder encodeConditionalObject: _target forKey: @"NSTarget"];
      [aCoder encodeConditionalObject: NSStringFromSelector(_action) forKey: @"NSAction"];
    }
  else
    {
      [aCoder encodeObject: _the_color];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_active];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];
      [aCoder encodeConditionalObject: _target];
      [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (self != nil)
    {
      if ([aDecoder allowsKeyedCoding])
	{
	  NSString *action;

	  ASSIGN(_the_color, [aDecoder decodeObjectForKey: @"NSColor"]);
	  // _is_active =  [aDecoder decodeBoolForKey: @"NSEnabled"];
	  _is_bordered = [aDecoder decodeBoolForKey: @"NSIsBordered"];
	  _target = [aDecoder decodeObjectForKey: @"NSTarget"];
	  action = [aDecoder decodeObjectForKey: @"NSAction"];
	  _action = NSSelectorFromString(action);
	  [self registerForDraggedTypes:
		  [NSArray arrayWithObjects: NSColorPboardType, nil]];
	}
      else
	{
	  [aDecoder decodeValueOfObjCType: @encode(id) at: &_the_color];
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_active];
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_bordered];
	  [aDecoder decodeValueOfObjCType: @encode(id) at: &_target];
	  // Undo RETAIN by decoder
	  TEST_RELEASE(_target);
	  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
	  [self registerForDraggedTypes:
		  [NSArray arrayWithObjects: NSColorPboardType, nil]];
	}
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

/** <p>Returns whether the NSColorWell is active. By default a NSColorWell
    is not active.</p>
    <p>See Also: -activate: -deactivate</p>
 */
- (BOOL) isActive
{
  return _is_active;
}

/** <p>Returns whether the NSColorWell has border. By default a NSColorWell
    has border.</p><p>See Also: -setBordered:</p>
 */
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
  //
  // OPENSTEP 4.2 and OSX behavior indicates that the colorwell doesn't
  // work when the widget is marked as disabled.
  //
  if ([self isEnabled])
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
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
         
  NSDebugLLog(@"NSColorWell", @"%@: performDragOperation", self);
  [self setColor: [NSColor colorFromPasteboard: pb]];
  /* When our color is changed by having a new color dropped on us,
   * we send our action.
   */
  [self sendAction: _action to: _target];
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

/**<p>Sets whether the NSColorWell has border and marks self for display.
   By default a NSColorWell has border.</p><p>See Also: -isBordered</p>
 */
- (void) setBordered: (BOOL)bordered
{
  _is_bordered = bordered;
  [self setNeedsDisplay: YES];
}

/** <p>Sets the NSColorWell to color and marks self for display.<br />
 * Sets the NSColorPanel if active.<br />
 * Does NOT notify target of color change.
 * </p>
 * <p>See Also: -color</p>
 */
- (void) setColor: (NSColor *)color
{
  ASSIGN(_the_color, color);
  [self setNeedsDisplay: YES];
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
}

- (void) setTarget: (id)target
{
  _target = target;
}

/** <p>Sets the NSColorWell's color to the sender color.</p>
 *  <p>See Also: -setColor: </p>
 */
- (void) takeColorFrom: (id)sender
{
  if ([sender respondsToSelector: @selector(color)])
    {
      [self setColor: [sender color]];
    }
}

- (void) _takeColorFromPanel: (NSNotification *) notification
{
  id sender = [notification object];

  if ([sender respondsToSelector: @selector(color)])
    {
      NSColor	*c = [(id)sender color];

      /* Don't use -setColor: as that would send a message back to the
       * panel telling it to se its color again.
       * Instead we assign the color and mark for redisplay directly.
       * NB. For MacOS-X compatibility, we only send the action if the
       * coor has actually changed.
       */
      if (c != nil && [c isEqual: _the_color] == NO)
	{
	  ASSIGN(_the_color, [(id)sender color]);
	  [self setNeedsDisplay: YES];
	  /* When our color is changed from the color panel, we should
	   * send our action.
	   */
	  [self sendAction: _action to: _target];
	}
    }
}

- (id) target
{
  return _target;
}

@end

