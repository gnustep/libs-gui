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

#include <gnustep/gui/NSCell.h>
#include <gnustep/gui/NSApplication.h>
#include <gnustep/gui/NSButton.h>

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
- init
{
  [super init];
  cell_type = NSNullCellType;
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
  return self;
}

- (id)initImageCell:(NSImage *)anImage
{
  [super init];

  // Not an image class --then forget it
  if (![anImage isKindOfClass:[NSImage class]])
    return nil;

  support = anImage;
  cell_type = NSImageCellType;
  image_position = NSImageOnly;
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
  return self;
}

- (id)initTextCell:(NSString *)aString
{
  [super init];

  // Not a string class --then forget it
  //if (![aString isKindOfClass:[NSString class]])
  //	return nil;

  support = [NSFont userFontOfSize:12];
  contents = aString;
  cell_type = NSTextCellType;
  text_align = NSLeftTextAlignment;
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
  cell_float_autorange = YES;
  cell_float_left = 0;
  cell_float_right = 6;
  return self;
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
  if (cell_type == NSImageCellType)
    return support;
  else
    return nil;
}

- (void)setImage:(NSImage *)anImage
{
  // Not an image class --then forget it
  if (![anImage isKindOfClass:[NSImage class]])
    return;

	// Only set the image if we are an image cell
  if (cell_type == NSImageCellType)
    support = anImage;
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
  return [NSString stringWithCString: [contents cString]];
}

- (void)setDoubleValue:(double)aDouble
{
  char c[256];
  unsigned int w = cell_float_left + cell_float_right;

  // Default printf formatting
  if (cell_float_left == 0)
    sprintf(c, "%f", aDouble);
  else
    if (cell_float_autorange)
      sprintf(c, "%*f", w, aDouble);
    else
      sprintf(c, "%*.*f", w, cell_float_right, aDouble);

  contents = [NSString stringWithCString:c];
}

- (void)setFloatValue:(float)aFloat
{
  char c[256];
  unsigned int w = cell_float_left + cell_float_right;

  // Default printf formatting
  if (cell_float_left == 0)
    sprintf(c, "%f", aFloat);
  else
    if (cell_float_autorange)
      sprintf(c, "%*f", w, aFloat);
    else
      sprintf(c, "%*.*f", w, cell_float_right, aFloat);

  contents = [NSString stringWithCString:c];
}

- (void)setIntValue:(int)anInt
{
  char c[256];
  sprintf(c, "%d", anInt);
  contents = [NSString stringWithCString:c];
}

- (void)setStringValue:(NSString *)aString
{
  if (!aString)
    contents = @"";
  else
    contents = [NSString stringWithCString: [aString cString]];
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
  if ([support isKindOfClass:[NSFont class]])
    return support;
  else
    return nil;
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

	// Only set the font if we are a text cell
  if ([support isKindOfClass:[NSFont class]])
    support = fontObject;
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
  return NO;
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

- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView
{}

- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{}

- (void)highlight:(BOOL)lit
	withFrame:(NSRect)cellFrame
	   inView:(NSView *)controlView
{
    cell_highlighted = lit;
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
  return 0;
}

- (void)setAction:(SEL)aSelector
{}

- (void)setContinuous:(BOOL)flag
{
  cell_continuous = flag;
}

- (void)setTarget:(id)anObject
{}

- (id)target
{
  return nil;
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
{}

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
    NSEvent *e;
    unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
      NSMouseMovedMask | NSLeftMouseDraggedMask |
      NSRightMouseDraggedMask;
    NSPoint location = [theEvent locationInWindow];
    NSPoint point = [controlView convertPoint: location fromView: nil];
    NSPoint last_point;
    BOOL done;
    NSRect r;
    BOOL untilMU, mouseWentUp;

    NSDebugLog(@"NSCell start tracking\n");
    NSDebugLog(@"NSCell tracking in rect %f %f %f %f\n", 
	       cellFrame.origin.x, cellFrame.origin.y,
	       cellFrame.size.width, cellFrame.size.height);
    NSDebugLog(@"NSCell initial point %f %f\n", point.x, point.y);

    if (![self startTrackingAt: point inView: controlView])
	return NO;

    // If point is in cellFrame then highlight the cell
    if ([controlView mouse: point inRect: cellFrame])
	[self highlight:YES withFrame:cellFrame inView:controlView];
    else
	return NO;

    // Get next mouse events until a mouse up is obtained
    NSDebugLog(@"NSCell get mouse events\n");
    mouseWentUp = NO;
    done = NO;
    while (!done)
	{
	    last_point = point;
	    e = [theApp nextEventMatchingMask:event_mask untilDate:nil 
			inMode:nil dequeue:YES];
	    location = [e locationInWindow];
	    point = [controlView convertPoint: location fromView: nil];
	    NSDebugLog(@"NSCell location %f %f\n", location.x, location.y);
	    NSDebugLog(@"NSCell point %f %f\n", point.x, point.y);

	    if (![controlView mouse: point inRect: cellFrame])
		{
		    NSDebugLog(@"NSCell point not in cell frame\n");
		    // If point not in cell then unhighlight cell
		    [self highlight: NO withFrame: cellFrame 
			  inView: controlView];
		    
		    // Do we now return or keep tracking
		    if ((![[self class] prefersTrackingUntilMouseUp]) 
			|| (!flag))
			{
			    NSDebugLog(@"NSCell return immediately\n");
			    done = YES;
			    continue;
			}
		}

	    // should we continue tracking?
	    if (![self continueTracking: last_point at: point
		      inView: controlView])
		{
		    NSDebugLog(@"NSCell stop tracking\n");
		    done = YES;
		    continue;
		}

	    // Did the mouse go up?
	    if ([e type] == NSLeftMouseUp)
		{
		    NSDebugLog(@"NSCell mouse went up\n");
		    mouseWentUp = YES;
		    done = YES;
		}
	}

    // Tell ourselves to stop tracking
    [self stopTracking: last_point at: point
	  inView: controlView mouseIsUp: mouseWentUp];

    // Return YES only if the mouse went up within the cell
    if ((mouseWentUp) &&
	([controlView mouse: point inRect: cellFrame]))
	{
	    NSDebugLog(@"NSCell mouse went up in cell\n");
	    return YES;
	}

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
  return nil;
}

- (void)setRepresentedObject:(id)anObject
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: contents];
  [aCoder encodeObject: support];
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
  [aCoder encodeObjectReference: control_view withName: @"Control view"];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  contents = [aDecoder decodeObject];
  support = [aDecoder decodeObject];
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
  [aDecoder decodeObjectAt: &control_view withName: NULL];

  return self;
}

@end
