/* 
   NSCell.m

   The abstract cell class

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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSEvent.h>

@implementation NSCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Tracking the Mouse 
//
+ (BOOL)prefersTrackingUntilMouseUp
{
  return NO;
}

//
// Instance methods
//

//
// Initializing an NSCell 
//
- _init
{
  self = [super init];
  cell_type = NSNullCellType;
  cell_image = nil;
  cell_font = nil;
  image_position = NSNoImage;
  cell_state = NO;
  cell_highlighted = NO;
  cell_enabled = YES;
  cell_editable = NO;
  cell_bordered = NO;
  cell_bezeled = NO;
  cell_scrollable = NO;
  cell_selectable = NO;
  cell_continuous = NO;
  cell_float_autorange = NO;
  cell_float_left = 0;
  cell_float_right = 0;
  action_mask = NSLeftMouseUpMask;
  return self;
}

- init
{
  return [self initTextCell:@""];
}

- (id)initImageCell:(NSImage *)anImage
{
  [super init];

  [self _init];

  // Not an image class --then forget it
  if (![anImage isKindOfClass:[NSImage class]])
    return nil;

  cell_type = NSImageCellType;
  cell_image = [anImage retain];
  image_position = NSImageOnly;
  cell_font = [[NSFont userFontOfSize:0] retain];
  return self;
}

- (id)initTextCell:(NSString *)aString
{
  [super init];

  [self _init];

  cell_font = [[NSFont userFontOfSize:0] retain];
  contents = [aString retain];
  cell_type = NSTextCellType;
  text_align = NSCenterTextAlignment;
  cell_image = nil;
  image_position = NSNoImage;
  cell_float_autorange = YES;
  cell_float_left = 0;
  cell_float_right = 6;
  return self;
}

- (void)dealloc
{
  [contents release];
  [cell_image release];
  [cell_font release];
  [represented_object release];
  [super dealloc];
}

//
// Determining Component Sizes 
//
- (void)calcDrawInfo:(NSRect)aRect
{}

- (NSSize)cellSize
{
  return NSZeroSize;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect
{
  return NSZeroSize;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
  return NSZeroRect;
}

- (NSRect)imageRectForBounds:(NSRect)theRect
{
  return NSZeroRect;
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
  return NSZeroRect;
}

//
// Setting the NSCell's Type 
//
- (void)setType:(NSCellType)aType
{
  cell_type = aType;
}

- (NSCellType)type
{
  return cell_type;
}

//
// Setting the NSCell's State 
//
- (void)setState:(int)value
{
  cell_state = value;
}

- (int)state
{
  return cell_state;
}

//
// Enabling and Disabling the NSCell 
//
- (BOOL)isEnabled
{
  return cell_enabled;
}

- (void)setEnabled:(BOOL)flag
{
  cell_enabled = flag;
}

//
// Setting the Image 
//
- (NSImage *)image
{
  return cell_image;
}

- (void)setImage:(NSImage *)anImage
{
  // Not an image class --then forget it
  if (![anImage isKindOfClass:[NSImage class]])
    return;

  // Only set the image if we are an image cell
  [anImage retain];
  [cell_image release];
  cell_image = anImage;
  [self setType:NSImageCellType];
}

//
// Setting the NSCell's Value 
//
- (double)doubleValue
{
  return [contents doubleValue];
}

- (float)floatValue;
{
  return [contents floatValue];
}

- (int)intValue
{
  return [contents intValue];
}

- (NSString *)stringValue
{
  return contents;
}

- (void)setDoubleValue:(double)aDouble
{
  NSNumber* number = [NSNumber numberWithDouble:aDouble];

  [contents release];
  contents = [[number stringValue] retain];
}

- (void)setFloatValue:(float)aFloat
{
  NSNumber* number = [NSNumber numberWithFloat:aFloat];

  [contents release];
  contents = [[number stringValue] retain];
}

- (void)setIntValue:(int)anInt
{
  NSNumber* number = [NSNumber numberWithInt:anInt];

  [contents release];
  contents = [[number stringValue] retain];
}

- (void)setStringValue:(NSString *)aString
{
  aString = [aString copy];
  [contents release];
  if (!aString)
    contents = @"";
  else
    contents = aString;
}

//
// Interacting with Other NSCells 
//
- (void)takeDoubleValueFrom:(id)sender
{
  [self setDoubleValue:[sender doubleValue]];
}

- (void)takeFloatValueFrom:(id)sender
{
  [self setFloatValue:[sender floatValue]];
}

- (void)takeIntValueFrom:(id)sender
{
  [self setIntValue:[sender intValue]];
}

- (void)takeStringValueFrom:(id)sender
{
  [self setStringValue:[sender stringValue]];
}

//
// Modifying Text Attributes 
//
- (NSTextAlignment)alignment
{
  return text_align;
}

- (NSFont *)font
{
  return cell_font;
}

- (BOOL)isEditable
{
  return cell_editable;
}

- (BOOL)isSelectable
{
  return cell_selectable;
}

- (BOOL)isScrollable
{
  return cell_scrollable;
}

- (void)setAlignment:(NSTextAlignment)mode
{
  text_align = mode;
}

- (void)setEditable:(BOOL)flag
{
  cell_editable = flag;
  // If its editable then its selectable
  if (flag)
    cell_selectable = flag;
}

- (void)setFont:(NSFont *)fontObject
{
  // Not a font --then forget it
  if (![fontObject isKindOfClass:[NSFont class]])
    return;

  [fontObject retain];
  [cell_font release];
  cell_font = fontObject;
}

- (void)setSelectable:(BOOL)flag
{
  cell_selectable = flag;
  // If its not selectable then its not editable
  if (!flag)
    cell_editable = NO;
}

- (void)setScrollable:(BOOL)flag
{
  cell_scrollable = flag;
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject
{
  return nil;
}

- (void)setWraps:(BOOL)flag
{}

- (BOOL)wraps
{
  return NO;
}

//
// Editing Text 
//
- (void)editWithFrame:(NSRect)aRect 
			inView:(NSView *)controlView	
			editor:(NSText *)textObject	
			delegate:(id)anObject	
			event:(NSEvent *)theEvent
{}

- (void)endEditing:(NSText *)textObject
{}

- (void)selectWithFrame:(NSRect)aRect
			inView:(NSView *)controlView	 
			editor:(NSText *)textObject	 
			delegate:(id)anObject	 
			start:(int)selStart	 
			length:(int)selLength
{}

//
// Validating Input 
//
- (int)entryType
{
  return entry_type;
}

- (BOOL)isEntryAcceptable:(NSString *)aString
{
  return YES;
}

- (void)setEntryType:(int)aType
{
  entry_type = aType;
}

//
// Formatting Data 
//
- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned int)leftDigits
			 right:(unsigned int)rightDigits
{
  cell_float_autorange = autoRange;
  cell_float_left = leftDigits;
  cell_float_right = rightDigits;
}

//
// Modifying Graphic Attributes 
//
- (BOOL)isBezeled
{
  return cell_bezeled;
}

- (BOOL)isBordered
{
  return cell_bordered;
}

- (BOOL)isOpaque
{
  return cell_bezeled;
}

- (void)setBezeled:(BOOL)flag
{
  cell_bezeled = flag;
}

- (void)setBordered:(BOOL)flag
{
  cell_bordered = flag;
}

//
// Setting Parameters 
//
- (int)cellAttribute:(NSCellAttribute)aParameter
{
  return 0;
}

- (void)setCellAttribute:(NSCellAttribute)aParameter
		      to:(int)value
{}

//
// Displaying 
//
- (NSView *)controlView
{
  return control_view;
}

- (void)setControlView:(NSView*)view
{
  control_view = view;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView
{}

- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{
  /* Mark the cell's frame rectangle as needing flush */
  [[controlView window] _view:controlView needsFlushInRect:cellFrame];
}

- (void)highlight:(BOOL)lit
	withFrame:(NSRect)cellFrame
	   inView:(NSView *)controlView
{
  cell_highlighted = lit;

  /* Mark the cell's frame rectangle as needing flush */
  [[controlView window] _view:controlView needsFlushInRect:cellFrame];
}

- (BOOL)isHighlighted
{
  return cell_highlighted;
}

//
// Target and Action 
//
- (SEL)action
{
  return NULL;
}

- (BOOL)isContinuous
{
  return cell_continuous;
}

- (int)sendActionOn:(int)mask
{
  unsigned int previousMask = action_mask;

  action_mask = mask;

  return previousMask;
}

- (void)setAction:(SEL)aSelector
{}

- (void)setContinuous:(BOOL)flag
{
  cell_continuous = flag;
  [self sendActionOn:(NSLeftMouseUpMask|NSPeriodicMask)];
}

- (void)setTarget:(id)anObject
{}

- (id)target
{
  return nil;
}

- (void)performClick:(id)sender
{
}

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt
{}

- (int)tag
{
  return -1;
}

//
// Handling Keyboard Alternatives 
//
- (NSString *)keyEquivalent
{
  return nil;
}

//
// Tracking the Mouse 
//
- (BOOL)continueTracking:(NSPoint)lastPoint
		      at:(NSPoint)currentPoint
		  inView:(NSView *)controlView
{
    return YES;
}

- (int)mouseDownFlags
{
  return 0;
}

- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval
{
  *delay = 0.05;
  *interval = 0.05;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint
		 inView:(NSView *)controlView
{
    // If the point is in the view then yes start tracking
    if ([controlView mouse: startPoint inRect: [controlView bounds]])
	return YES;
    else
	return NO;
}

- (void)stopTracking:(NSPoint)lastPoint
		  at:(NSPoint)stopPoint
	      inView:(NSView *)controlView
		  mouseIsUp:(BOOL)flag
{
}

- (BOOL)trackMouse:(NSEvent *)theEvent
	    inRect:(NSRect)cellFrame
	    ofView:(NSView *)controlView
      untilMouseUp:(BOOL)flag
{
  NSApplication *theApp = [NSApplication sharedApplication];
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
    NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;
  NSPoint location = [theEvent locationInWindow];
  NSPoint point = [controlView convertPoint: location fromView: nil];
  float delay, interval;
  id target = [self target];
  SEL action = [self action];
  NSPoint last_point;
  BOOL done;
  BOOL mouseWentUp;

  NSDebugLog(@"NSCell start tracking\n");
  NSDebugLog(@"NSCell tracking in rect %f %f %f %f\n", 
	      cellFrame.origin.x, cellFrame.origin.y,
	      cellFrame.size.width, cellFrame.size.height);
  NSDebugLog(@"NSCell initial point %f %f\n", point.x, point.y);

  if (![self startTrackingAt: point inView: controlView])
    return NO;

  if (![controlView mouse: point inRect: cellFrame]) 		 
    return NO;											// point is not in cell

  if ([theEvent type] == NSLeftMouseDown
      && (action_mask & NSLeftMouseDownMask))
    [(NSControl*)controlView sendAction:action to:target];

  if (cell_continuous) {
    [self getPeriodicDelay:&delay interval:&interval];
    [NSEvent startPeriodicEventsAfterDelay:delay withPeriod:interval];
    event_mask |= NSPeriodicMask;
  }

  // Get next mouse events until a mouse up is obtained
  NSDebugLog(@"NSCell get mouse events\n");
  mouseWentUp = NO;
  done = NO;
  while (!done) {
    NSEventType eventType;
    BOOL pointIsInCell;

    last_point = point;
    theEvent = [theApp nextEventMatchingMask:event_mask untilDate:nil 
		inMode:NSEventTrackingRunLoopMode dequeue:YES];
    eventType = [theEvent type];

    if (eventType != NSPeriodic) {
      location = [theEvent locationInWindow];
      point = [controlView convertPoint: location fromView: nil];
      NSDebugLog(@"NSCell location %f %f\n", location.x, location.y);
      NSDebugLog(@"NSCell point %f %f\n", point.x, point.y);
    }
    else
      NSDebugLog (@"got a periodic event");

    // Point is not in cell
    if (![controlView mouse: point inRect: cellFrame]) {
      NSDebugLog(@"NSCell point not in cell frame\n");

      pointIsInCell = NO;

      // Do we return now or keep tracking
      if (![[self class] prefersTrackingUntilMouseUp] && flag) {
	NSDebugLog(@"NSCell return immediately\n");
	done = YES;
      }
    }
    else 
      pointIsInCell = YES;							// Point is in cell

    // should we continue tracking?
    if (!done
	&& ![self continueTracking:last_point at:point inView:controlView]) {
      NSDebugLog(@"NSCell stop tracking\n");
      done = YES;
    }

    // Did the mouse go up?
    if (eventType == NSLeftMouseUp) {
      NSDebugLog(@"NSCell mouse went up\n");
      mouseWentUp = YES;
      done = YES;
     if ((action_mask & NSLeftMouseUpMask))
	[(NSControl*)controlView sendAction:action to:target];
    }
    else {
      if (pointIsInCell
	  && ((eventType == NSLeftMouseDragged
		&& (action_mask & NSLeftMouseDraggedMask))
	      || ((eventType == NSPeriodic)
		  && (action_mask & NSPeriodicMask))))
	[(NSControl*)controlView sendAction:action to:target];
    }

  }

  // Tell ourselves to stop tracking
  [self stopTracking:last_point at:point
	inView:controlView mouseIsUp:mouseWentUp];

  if (cell_continuous)
    [NSEvent stopPeriodicEvents];

  // Return YES only if the mouse went up within the cell
  if (mouseWentUp && [controlView mouse: point inRect: cellFrame]) {
    NSDebugLog(@"NSCell mouse went up in cell\n");
    return YES;
  }

#if 1
  [controlView setNeedsDisplayInRect:cellFrame];
#endif

  // Otherwise return NO
  NSDebugLog(@"NSCell mouse did not go up in cell\n");
  return NO;
}

//
// Managing the Cursor 
//
- (void)resetCursorRect:(NSRect)cellFrame
		 inView:(NSView *)controlView
{}

//
// Comparing to Another NSCell 
//
- (NSComparisonResult)compare:(id)otherCell
{
  return 0;
}

//
// Using the NSCell to Represent an Object
//
- (id)representedObject
{
  return represented_object;
}

- (void)setRepresentedObject:(id)anObject
{
  [anObject retain];
  [represented_object release];
  represented_object = anObject;
}

- (id)copyWithZone:(NSZone*)zone
{
  NSCell* c;

  c = [[isa allocWithZone: zone] init];

  [c setStringValue:contents];
  [c setImage:cell_image];
  [c setFont:cell_font];
  [c setState:cell_state];
  c->cell_highlighted = cell_highlighted;
  [c setEnabled:cell_enabled];
  [c setEditable:cell_editable];
  [c setBordered:cell_bordered];
  [c setBezeled:cell_bezeled];
  [c setScrollable:cell_scrollable];
  [c setSelectable:cell_selectable];
  [c setContinuous:cell_continuous];
  [c setFloatingPointFormat:cell_float_autorange
	left:cell_float_left
	right:cell_float_right];
  c->image_position = image_position;
  [c setType:cell_type];
  [c setAlignment:text_align];
  [c setEntryType:entry_type];
  c->control_view = control_view;
  c->cell_size = cell_size;
  [c setRepresentedObject:represented_object];

  return c;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [aCoder encodeObject: contents];
  [aCoder encodeObject: cell_image];
  [aCoder encodeObject: cell_font];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_state];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_highlighted];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_enabled];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_editable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_bordered];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_bezeled];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_scrollable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_selectable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_continuous];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_float_autorange];
  [aCoder encodeValueOfObjCType: "I" at: &cell_float_left];
  [aCoder encodeValueOfObjCType: "I" at: &cell_float_right];
  [aCoder encodeValueOfObjCType: "I" at: &image_position];
  [aCoder encodeValueOfObjCType: "i" at: &cell_type];
  [aCoder encodeValueOfObjCType: @encode(NSTextAlignment) at: &text_align];
  [aCoder encodeValueOfObjCType: "i" at: &entry_type];
  [aCoder encodeConditionalObject:control_view];
}

- initWithCoder:aDecoder
{
  contents = [aDecoder decodeObject];
  cell_image = [aDecoder decodeObject];
  cell_font = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_state];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_highlighted];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_enabled];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_editable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_bordered];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_bezeled];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_scrollable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_selectable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_continuous];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_float_autorange];
  [aDecoder decodeValueOfObjCType: "I" at: &cell_float_left];
  [aDecoder decodeValueOfObjCType: "I" at: &cell_float_right];
  [aDecoder decodeValueOfObjCType: "I" at: &image_position];
  [aDecoder decodeValueOfObjCType: "i" at: &cell_type];
  [aDecoder decodeValueOfObjCType: @encode(NSTextAlignment) at: &text_align];
  [aDecoder decodeValueOfObjCType: "i" at: &entry_type];
  control_view = [aDecoder decodeObject];
  return self;
}

@end

//
// Methods the backend should implement
//
@implementation NSCell (GNUstepBackend)

// Returns the size of a border
+ (NSSize)sizeForBorderType:(NSBorderType)aType
{
  return NSZeroSize;
}

@end
