/*
   NSCell.m

   The abstract cell class

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
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSColor.h>
#include <AppKit/PSOperators.h>



@implementation NSCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSCell class])
    [self setVersion:1];
}

+ (BOOL) prefersTrackingUntilMouseUp
{
  return NO;
}

//
// Instance methods
//
- _init
{
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
  return [self initTextCell: @""];
}

- (id) initImageCell: (NSImage*)anImage
{
  [super init];

  [self _init];

  NSAssert(anImage == nil || [anImage isKindOfClass: [NSImage class]],
	NSInvalidArgumentException);

  cell_type = NSImageCellType;
  cell_image = [anImage retain];
  image_position = NSImageOnly;
  cell_font = [[NSFont userFontOfSize: 0] retain];

  return self;
}

- (id) initTextCell: (NSString*)aString
{
  [super init];

  [self _init];

  cell_font = [[NSFont userFontOfSize: 0] retain];
  contents = [aString retain];
  cell_type = NSTextCellType;
  text_align = NSCenterTextAlignment;
  cell_float_autorange = YES;
  cell_float_right = 6;

  return self;
}

- (void) dealloc
{
  if (contents)
    [contents release];
  if (cell_image)
    [cell_image release];
  [cell_font release];
  if (represented_object)
    [represented_object release];

  [super dealloc];
}

//
// Determining Component Sizes
//
- (void) calcDrawInfo: (NSRect)aRect
{
}

- (NSSize) cellSize
{
  return NSZeroSize;
}

- (NSSize) cellSizeForBounds: (NSRect)aRect
{
  return NSZeroSize;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  return NSZeroRect;
}

- (NSRect) imageRectForBounds: (NSRect)theRect
{
  return NSZeroRect;
}

- (NSRect) titleRectForBounds: (NSRect)theRect
{
  return NSZeroRect;
}

//
// Setting the NSCell's Type
//
- (void) setType: (NSCellType)aType
{
  cell_type = aType;
}

- (NSCellType) type
{
  return cell_type;
}

//
// Setting the NSCell's State
//
- (void) setState: (int)value
{
  cell_state = value;
}

- (int) state
{
  return cell_state;
}

//
// Enabling and Disabling the NSCell
//
- (BOOL) isEnabled
{
  return cell_enabled;
}

- (void) setEnabled: (BOOL)flag
{
  cell_enabled = flag;
}

//
// Determining the first responder
//
- (BOOL) acceptsFirstResponder
{
  return cell_enabled;
}

//
// Setting the Image
//
- (NSImage*) image
{
  return cell_image;
}

- (void) setImage: (NSImage*)anImage
{
  NSAssert(anImage == nil || [anImage isKindOfClass: [NSImage class]],
	NSInvalidArgumentException);

  ASSIGN(cell_image, anImage);
  [self setType: NSImageCellType];
}

//
// Setting the NSCell's Value
//
- (double) doubleValue
{
  return [contents doubleValue];
}

- (float) floatValue
{
  return [contents floatValue];
}

- (int) intValue
{
  return [contents intValue];
}

- (NSString*) stringValue
{
  return contents;
}

- (void) setDoubleValue: (double)aDouble
{
  NSString* number_string = [[NSNumber numberWithDouble: aDouble] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setFloatValue: (float)aFloat
{
  NSString* number_string = [[NSNumber numberWithFloat: aFloat] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setIntValue: (int)anInt
{
  NSString* number_string = [[NSNumber numberWithInt: anInt] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setStringValue: (NSString *)aString
{
  NSString* _string;

  if (!aString)
    _string = @"";
  else
    _string = [aString copy];

  if (contents)
    RELEASE(contents);
  contents = _string;
}

//
// Interacting with Other NSCells
//
- (void) takeDoubleValueFrom: (id)sender
{
  [self setDoubleValue: [sender doubleValue]];
}

- (void) takeFloatValueFrom: (id)sender
{
  [self setFloatValue: [sender floatValue]];
}

- (void) takeIntValueFrom: (id)sender
{
  [self setIntValue: [sender intValue]];
}

- (void) takeStringValueFrom: (id)sender
{
  [self setStringValue: [sender stringValue]];
}

//
// Modifying Text Attributes
//
- (NSTextAlignment) alignment
{
  return text_align;
}

- (NSFont*) font
{
  return cell_font;
}

- (BOOL) isEditable
{
  return cell_editable;
}

- (BOOL) isSelectable
{
  return cell_selectable || cell_editable;
}

- (BOOL) isScrollable
{
  return cell_scrollable;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  text_align = mode;
}

- (void) setEditable: (BOOL)flag
{
  /*
   *	The cell_editable flag is also checked to see if the cell is selectable
   *	so turning edit on also turns selectability on (until edit is turned
   *	off again).
   */
  cell_editable = flag;
}

- (void) setFont: (NSFont *)fontObject
{
  NSAssert(fontObject == nil || [fontObject isKindOfClass: [NSFont class]],
	NSInvalidArgumentException);

  ASSIGN(cell_font, fontObject);
}

- (void) setSelectable: (BOOL)flag
{
  cell_selectable = flag;

  /*
   *	Making a cell unselectable also makes it uneditable until a
   *	setEditable re-enables it.
   */
  if (!flag)
    cell_editable = NO;
}

- (void) setScrollable: (BOOL)flag
{
  cell_scrollable = flag;
}

- (void) setWraps: (BOOL)flag
{
}

- (BOOL) wraps
{
  return NO;
}

//
// Editing Text
//
- (NSText*) setUpFieldEditorAttributes: (NSText*)textObject
{
  return nil;
}

- (void) editWithFrame: (NSRect)aRect
		inView: (NSView *)controlView
		editor: (NSText *)textObject
	      delegate: (id)anObject
		 event: (NSEvent *)theEvent
{
  if (cell_type != NSTextCellType)
    return;

  [controlView lockFocus];
  [[controlView window] makeFirstResponder: textObject];

  [textObject setText: [self stringValue]];
  [textObject setDelegate: anObject];
  [controlView addSubview: textObject];
  [textObject setFrame: aRect];
  NSEraseRect(aRect);
  [textObject display];
  [controlView unlockFocus];
}

/*
 * editing is complete, remove the text obj acting as the field
 * editor from window's view heirarchy, set our contents from it
 */
- (void) endEditing: (NSText*)textObject
{
  [textObject setDelegate: nil];
  [textObject removeFromSuperview];
  [self setStringValue: [textObject text]];
}

- (void) selectWithFrame: (NSRect)aRect
		  inView: (NSView *)controlView
		  editor: (NSText *)textObject
		delegate: (id)anObject
		   start: (int)selStart
		  length: (int)selLength
{														// preliminary FIX ME
  if (!controlView || !textObject || !cell_font ||
			(cell_type != NSTextCellType))
    return;

  [[controlView window] makeFirstResponder: textObject];

  [textObject setFrame: aRect];
  [textObject setText: [self stringValue]];
  [textObject setDelegate: anObject];
  [controlView addSubview: textObject];
  NSEraseRect(aRect);
  [textObject display];
}

//
// Validating Input
//
- (int) entryType
{
  return entry_type;
}

- (BOOL) isEntryAcceptable: (NSString*)aString
{
  return YES;
}

- (void) setEntryType: (int)aType
{
  entry_type = aType;
}

//
// Formatting Data
//
- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned int)leftDigits
			  right: (unsigned int)rightDigits
{
  cell_float_autorange = autoRange;
  cell_float_left = leftDigits;
  cell_float_right = rightDigits;
}

//
// Modifying Graphic Attributes
//
- (BOOL) isBezeled
{
  return cell_bezeled;
}

- (BOOL) isBordered
{
  return cell_bordered;
}

- (BOOL) isOpaque
{
  return NO;
}

- (void) setBezeled: (BOOL)flag
{
  cell_bezeled = flag;
}

- (void) setBordered: (BOOL)flag
{
  cell_bordered = flag;
}

//
// Setting Parameters
//
- (int) cellAttribute: (NSCellAttribute)aParameter
{
  return 0;
}

- (void) setCellAttribute: (NSCellAttribute)aParameter to: (int)value
{
}

//
// Displaying
//
- (NSView*) controlView
{
  return control_view;
}

- (void) setControlView: (NSView*)view
{
  control_view = view;
}

- (NSColor*) textColor
{
  if ([self isEnabled])
    return [NSColor blackColor];
  else
    return [NSColor darkGrayColor];
}

- (void) _drawText: (NSString *) title inFrame: (NSRect) cellFrame
{
  NSColor *textColor;
  NSFont *font;
  float titleWidth;
  float titleHeight;
  NSDictionary	*dict;

  if (!title)
    return;

  textColor = [self textColor];

  font = [self font];
  if (!font)
    [NSException raise: NSInvalidArgumentException
        format: @"Request to draw a text cell but no font specified!"];
  titleWidth = [font widthOfString: title];
  titleHeight = [font pointSize];

  // Determine the y position of the text
  cellFrame.origin.y = NSMidY (cellFrame) - titleHeight / 2;
  cellFrame.size.height = titleHeight;

  // Determine the x position of text
  switch ([self alignment])
    {
      // ignore the justified and natural alignments
      case NSLeftTextAlignment:
      case NSJustifiedTextAlignment:
      case NSNaturalTextAlignment:
	break;
      case NSRightTextAlignment:
        if (titleWidth < NSWidth (cellFrame))
          {
            float shift = NSWidth (cellFrame) - titleWidth;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
	break;
      case NSCenterTextAlignment:
        if (titleWidth < NSWidth (cellFrame))
          {
            float shift = (NSWidth (cellFrame) - titleWidth) / 2;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
    }

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
		font, NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		nil];
  [title drawInRect: cellFrame withAttributes: dict];
}

// Draw image centered in frame.
- (void) _drawImage: (NSImage *) image inFrame: (NSRect) cellFrame
{
  NSSize size;
  NSPoint position;

  if (!image)
    return;

  size = [image size];
  position.x = NSMidX (cellFrame) - size.width / 2;
  position.y = NSMidY (cellFrame) - size.height / 2;
  [image compositeToPoint: position operation: NSCompositeCopy];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  cellFrame = NSInsetRect(cellFrame, xDist, yDist);

  // Clear the cell frame
  if ([self isOpaque])
    {
      [[NSColor lightGrayColor] set];
      NSRectFill(cellFrame);
    }

  switch ([self type])
    {
      case NSTextCellType:
           [self _drawText: [self stringValue] inFrame: cellFrame];
           break;
      case NSImageCellType:
           [self _drawImage: [self image] inFrame: cellFrame];
           break;
      case NSNullCellType:
          break;
    }
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSDebugLog (@"NSCell drawWithFrame: inView:");

  // Save last view drawn to
  [self setControlView: controlView];

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // draw the border if needed
  if ([self isBordered])
    {
      if ([self isBezeled])
        {
          NSDrawWhiteBezel(cellFrame, cellFrame);
        }
      else
        {
          NSFrameRect(cellFrame);
        }
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (BOOL) isHighlighted
{
  return cell_highlighted;
}

- (void) highlight: (BOOL)lit
	 withFrame: (NSRect)cellFrame
	    inView: (NSView*)controlView
{
  if (cell_highlighted != lit)
    {
      cell_highlighted = lit;
      [self drawWithFrame: cellFrame inView: controlView];
    }
}

//
// Target and Action
//
- (SEL) action
{
  return NULL;
}

- (void) setAction: (SEL)aSelector
{
}

- (BOOL) isContinuous
{
  return cell_continuous;
}

- (int) sendActionOn: (int)mask
{
  unsigned int previousMask = action_mask;

  action_mask = mask;

  return previousMask;
}

- (void) setContinuous: (BOOL)flag
{
  cell_continuous = flag;
  [self sendActionOn: (NSLeftMouseUpMask|NSPeriodicMask)];
}

- (void) setTarget: (id)anObject
{
}

- (id) target
{
  return nil;
}

- (void) performClick: (id)sender
{
  NSView	*cv = [self controlView];

  [self highlight: YES withFrame: [cv frame] inView: cv];
  if ([self action] && [self target])
    {
      NS_DURING
	{
	  [(NSControl*)cv sendAction: [self action] to: [self target]];
	}
      NS_HANDLER
	{
	  [self highlight: NO withFrame: [cv frame] inView: cv];
          [localException raise];
	}
      NS_ENDHANDLER
    }
  [self highlight: NO withFrame: [cv frame] inView: cv];
}

//
// Assigning a Tag
//
- (void) setTag: (int)anInt
{
}

- (int) tag
{
  return -1;
}

//
// Handling Keyboard Alternatives
//
- (NSString*) keyEquivalent
{
  return nil;
}

//
// Tracking the Mouse
//
- (BOOL) continueTracking: (NSPoint)lastPoint
		       at: (NSPoint)currentPoint
		   inView: (NSView *)controlView
{
  return YES;
}

- (int) mouseDownFlags
{
  return 0;
}

- (void) getPeriodicDelay: (float *)delay interval: (float *)interval
{
  *delay = 0.05;
  *interval = 0.05;
}

- (BOOL) startTrackingAt: (NSPoint)startPoint inView: (NSView *)controlView
{
  // If the point is in the view then yes start tracking
  if ([controlView mouse: startPoint inRect: [controlView bounds]])
    return YES;
  else
    return NO;
}

- (void) stopTracking: (NSPoint)lastPoint
		   at: (NSPoint)stopPoint
	       inView: (NSView *)controlView
	    mouseIsUp: (BOOL)flag
{
}

- (BOOL) trackMouse: (NSEvent *)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView
       untilMouseUp: (BOOL)flag
{
  NSApplication *theApp = [NSApplication sharedApplication];
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
			    NSMouseMovedMask | NSLeftMouseDraggedMask |
			    NSRightMouseDraggedMask;
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
    return NO;	// point is not in cell

  if ([theEvent type] == NSLeftMouseDown &&
			(action_mask & NSLeftMouseDownMask))
    [(NSControl*)controlView sendAction: action to:target];

  if (cell_continuous)
    {
      [self getPeriodicDelay: &delay interval:&interval];
      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod:interval];
      event_mask |= NSPeriodicMask;
    }

  NSDebugLog(@"NSCell get mouse events\n");
  mouseWentUp = NO;
  done = NO;
  while (!done)
    {
      NSEventType eventType;
      BOOL pointIsInCell;

      last_point = point;
      theEvent = [theApp nextEventMatchingMask: event_mask
				     untilDate: nil
				        inMode: NSEventTrackingRunLoopMode
				       dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic)
	{
	  location = [theEvent locationInWindow];
	  point = [controlView convertPoint: location fromView: nil];
	  NSDebugLog(@"NSCell location %f %f\n", location.x, location.y);
	  NSDebugLog(@"NSCell point %f %f\n", point.x, point.y);
	}
      else
	NSDebugLog (@"got a periodic event");
      if (![controlView mouse: point inRect: cellFrame])
	{
	  NSDebugLog(@"NSCell point not in cell frame\n");

	  pointIsInCell = NO;	// Do we return now or keep tracking?
	  if (![[self class] prefersTrackingUntilMouseUp] && flag)
	    {
	      NSDebugLog(@"NSCell return immediately\n");
	      done = YES;
	    }
	}
      else
	pointIsInCell = YES;

      if (!done && ![self continueTracking: last_point 	// should continue
					at: point 	// tracking?
				    inView: controlView])
	{
	  NSDebugLog(@"NSCell stop tracking\n");
	  done = YES;
	}
										      // Did the mouse go up?
      if (eventType == NSLeftMouseUp)
	{
	  NSDebugLog(@"NSCell mouse went up\n");
	  mouseWentUp = YES;
	  done = YES;
          [self setState:![self state]];
	  if ((action_mask & NSLeftMouseUpMask))
	    [(NSControl*)controlView sendAction: action to:target];
	}
      else
	{
	  if (pointIsInCell && ((eventType == NSLeftMouseDragged
			  && (action_mask & NSLeftMouseDraggedMask))
			  || ((eventType == NSPeriodic)
			  && (action_mask & NSPeriodicMask))))
	    [(NSControl*)controlView sendAction: action to:target];
	}
    }
  // Tell ourselves to stop tracking
  [self stopTracking: last_point
		  at: point
	      inView: controlView
	   mouseIsUp: mouseWentUp];

  if (cell_continuous)
    [NSEvent stopPeriodicEvents];
  // Return YES only if the mouse went up within the cell
  if (mouseWentUp && [controlView mouse: point inRect: cellFrame])
    {
      NSDebugLog(@"NSCell mouse went up in cell\n");
      return YES;
    }

#if 1
  [controlView setNeedsDisplayInRect: cellFrame];
#endif

  NSDebugLog(@"NSCell mouse did not go up in cell\n");
  return NO;				// Otherwise return NO
}

//
// Managing the Cursor
//
- (void) resetCursorRect: (NSRect)cellFrame inView: (NSView *)controlView
{
}

//
// Comparing to Another NSCell
//
- (NSComparisonResult) compare: (id)otherCell
{
  return 0;
}

//
// Using the NSCell to Represent an Object
//
- (id) representedObject
{
  return represented_object;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN(represented_object, anObject);
}

- (id) copyWithZone: (NSZone*)zone
{
  NSCell	*c = [[isa allocWithZone: zone] init];

  c->contents = [contents copyWithZone: zone];
  ASSIGN(c->cell_image, cell_image);
  ASSIGN(c->cell_font, cell_font);
  c->cell_state = cell_state;
  c->cell_highlighted = cell_highlighted;
  c->cell_enabled = cell_enabled;
  c->cell_editable = cell_editable;
  c->cell_bordered = cell_bordered;
  c->cell_bezeled = cell_bezeled;
  c->cell_scrollable = cell_scrollable;
  c->cell_selectable = cell_selectable;
  [c setContinuous: cell_continuous];
  c->cell_float_autorange = cell_float_autorange;
  c->cell_float_left = cell_float_left;
  c->cell_float_right = cell_float_right;
  c->image_position = image_position;
  c->cell_type = cell_type;
  c->text_align = text_align;
  c->entry_type = entry_type;
  c->control_view = control_view;
  c->cell_size = cell_size;
  [c setRepresentedObject: represented_object];

  return c;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
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
  [aCoder encodeConditionalObject: control_view];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &contents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell_font];
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

+ (NSSize)sizeForBorderType: (NSBorderType)aType
{
  // Returns the size of a border
  switch (aType)
    {
      case NSLineBorder:
        return NSMakeSize(1, 1);
      case NSGrooveBorder:
      case NSBezelBorder:
        return NSMakeSize(2, 2);
      case NSNoBorder:
      default:
        return NSZeroSize;
    }
}

@end
