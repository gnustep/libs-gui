/*
   NSCell.m

   The abstract cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Modifications:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Rewrite:  Multiple authors
   Date: 1999
   Editing, formatters: Nicola Pero <nicola@brainstorm.co.uk>
   Date: 2000

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
#include <Foundation/NSGeometry.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>

#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSColor.h>
#include <AppKit/PSOperators.h>

static Class	colorClass;
static Class	cellClass;
static Class	fontClass;
static Class	imageClass;

static NSColor	*txtCol;
static NSColor	*dtxtCol;
static NSColor	*shadowCol;

@interface	NSCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n;
@end


@implementation	NSCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n
{
  ASSIGN(txtCol, [colorClass controlTextColor]);
  ASSIGN(dtxtCol, [colorClass disabledControlTextColor]);
  ASSIGN(shadowCol, [colorClass controlDarkShadowColor]);
}
@end


@implementation NSCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSCell class])
    {
      [self setVersion: 1];
      colorClass = [NSColor class];
      cellClass = [NSCell class];
      fontClass = [NSFont class];
      imageClass = [NSImage class];
      /*
       * Watch for changes to system colors, and simulate an initial change
       * in order to set up our defaults.
       */
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	   selector: @selector(_systemColorsChanged:)
	       name: NSSystemColorsDidChangeNotification
	     object: nil];
      [self _systemColorsChanged: nil];
    }
}

+ (NSMenu*)defaultMenu
{
  return nil;
}

+ (BOOL) prefersTrackingUntilMouseUp
{
  return NO;
}

/*
 * Instance methods
 */
- (id) init
{
  return [self initTextCell: @""];
}

- (id) initImageCell: (NSImage*)anImage
{
  _cell.type = NSImageCellType;
  _cell_image = RETAIN(anImage);
  _cell.image_position = NSImageOnly;
  _cell_font = RETAIN([fontClass userFontOfSize: 0]);
  // Implicitly set by allocation:
  //
  //_cell.is_disabled = NO;
  //_cell.state = 0;
  //_cell.is_highlighted = NO;
  //_cell.is_editable = NO;
  //_cell.is_bordered = NO;
  //_cell.is_bezeled = NO;
  //_cell.is_scrollable = NO;
  //_cell.is_selectable = NO;
  //_cell.is_continuous = NO;
  //_cell.float_autorange = NO;
  //_cell_float_left = 0;
  //_cell_float_right = 0;
  _action_mask = NSLeftMouseUpMask;

  return self;
}

- (id) initTextCell: (NSString*)aString
{
  _cell.type = NSTextCellType;
  _cell_font = RETAIN([fontClass userFontOfSize: 0]);
  _contents = RETAIN(aString);
  // In NSControl's doc they say this is the default
  _cell.text_align = NSNaturalTextAlignment;
  // Implicitly set by allocation:
  //
  //_cell_image = nil;
  //_cell.image_position = NSNoImage;
  //_cell.is_disabled = NO;
  //_cell.state = 0;
  //_cell.is_highlighted = NO;
  //_cell.is_editable = NO;
  //_cell.is_bordered = NO;
  //_cell.is_bezeled = NO;
  //_cell.is_scrollable = NO;
  //_cell.is_selectable = NO;
  //_cell.is_continuous = NO;
  _cell.float_autorange = YES;
  _cell_float_right = 6;
  //_cell_float_left = 0;
  _action_mask = NSLeftMouseUpMask;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE (_contents);
  TEST_RELEASE (_cell_image);
  TEST_RELEASE (_cell_font);
  TEST_RELEASE (_represented_object);
  TEST_RELEASE (_objectValue);
  TEST_RELEASE (_formatter);

  [super dealloc];
}

/*
 * Setting the NSCell's Value
 */
- (id) objectValue
{
  if (_cell.has_valid_object_value)
    {
      return _objectValue;
    }
  else
    {
      return nil;
    }
}

- (BOOL) hasValidObjectValue
{
  return _cell.has_valid_object_value;
}

- (double) doubleValue
{
  return [_contents doubleValue];
}

- (float) floatValue
{
  return [_contents floatValue];
}

- (int) intValue
{
  return [_contents intValue];
}

- (NSString*) stringValue
{
  return _contents;
}

- (void) setObjectValue: (id)object 
{
  id newContents;
  
  ASSIGN (_objectValue, object);
  
  newContents = [_formatter stringForObjectValue: _objectValue];
  if (newContents != nil)
    {
      _cell.has_valid_object_value = YES;
    }
  else
    {
      if ((_formatter == nil) 
	  && ([object isKindOfClass: [NSString class]] == YES))
	{
	  newContents = _objectValue;
	  _cell.has_valid_object_value = YES;
	}
      else
	{
	  newContents = [_objectValue description];
	  _cell.has_valid_object_value = NO;
	}
    }
  
  ASSIGN (_contents, newContents);
}

- (void) setDoubleValue: (double)aDouble
{
  NSNumber *number;

  // NB: GNUstep can set a double value for an image cell

  number = [NSNumber numberWithDouble: aDouble];
  [self setObjectValue: number];
}

- (void) setFloatValue: (float)aFloat
{
  NSNumber *number;

  // NB: GNUstep can set a float value for an image cell. 
  // NSSliderCell is an example of it! 

  number = [NSNumber numberWithFloat: aFloat];
  [self setObjectValue: number];
}

- (void) setIntValue: (int)anInt
{
  NSNumber *number;

  // NB: GNUstep can set an int value for an image cell. 

  number = [NSNumber numberWithInt: anInt];
  [self setObjectValue: number];
}

- (void) setStringValue: (NSString*)aString
{
  NSString *string = aString;

  _cell.type = NSTextCellType;

  if (string == nil)
    {
      string = @"";
    }

  if (_formatter == nil)
    {
      ASSIGN (_contents, string);
      _cell.has_valid_object_value = NO;
    }
  else
    {
      id newObjectValue;
      
      if ([_formatter getObjectValue: &newObjectValue 
		      forString: string 
		      errorDescription: NULL] == YES)
	{
	  [self setObjectValue: newObjectValue];
	}
      else
	{
	  _cell.has_valid_object_value = NO;
	  ASSIGN (_contents, string);
	}
    }
}

/*
 * Setting Parameters
 */
- (int) cellAttribute: (NSCellAttribute)aParameter
{
  return 0;
}

- (void) setCellAttribute: (NSCellAttribute)aParameter to: (int)value
{
  // TOFO
}

/*
 * Setting the NSCell's Type
 */
- (void) setType: (NSCellType)aType
{

  if (_cell.type == aType)
    return;
  
  _cell.type = aType;
  switch (_cell.type)
    {
      case NSTextCellType:
	ASSIGN (_cell_font, [fontClass userFontOfSize: 0]);
	ASSIGN (_contents, @"title");
	break;
      case NSImageCellType:
	TEST_RELEASE (_cell_image);
	_cell_image = nil;
	break;
    }
}

- (NSCellType) type
{
  return _cell.type;
}

/*
 * Enabling and Disabling the NSCell
 */
- (BOOL) isEnabled
{
  return !_cell.is_disabled;
}

- (void) setEnabled: (BOOL)flag
{
  _cell.is_disabled = !flag;
}

/*
 * Modifying Graphic Attributes
 */
- (BOOL) isBezeled
{
  return _cell.is_bezeled;
}

- (BOOL) isBordered
{
  return _cell.is_bordered;
}

- (BOOL) isOpaque
{
  return NO;
}

- (void) setBezeled: (BOOL)flag
{
  _cell.is_bezeled = flag;
  if (_cell.is_bezeled)
    _cell.is_bordered = NO;
}

- (void) setBordered: (BOOL)flag
{
  _cell.is_bordered = flag;
  if (_cell.is_bordered)
    _cell.is_bezeled = NO;
}

/*
 * Setting the NSCell's State
 */
- (void) setState: (int)value
{
  /* We do exactly as in macosx when value is not NSOnState,
   * NSOffState, NSMixedState, even if their behaviour (value < 0 ==>
   * NSMixedState) is a bit strange.  We could decide to do
   * differently in the future, so please use always symbolic
   * constants when calling this method, this way your code won't be
   * broken by changes. */
  if (value > 0)
    _cell.state = NSOnState;
  else if (value == 0 || (_cell.allows_mixed_state == NO))
    _cell.state = NSOffState;
  else 
    _cell.state = NSMixedState;
}

- (int) state
{
  return _cell.state;
}

- (BOOL) allowsMixedState
{
  return _cell.allows_mixed_state;
}

- (void) setAllowsMixedState: (BOOL)flag
{
  _cell.allows_mixed_state = flag;
}

- (int) nextState
{
  switch (_cell.state)
    {
      case NSOnState:
	return NSOffState;
      case NSOffState:
	if (_cell.allows_mixed_state)
	  {
	    return NSMixedState;
	  }
	else
	  {
	    return NSOnState;
	  }
      case NSMixedState:
      default:
	return NSOnState;
    }
}

- (void) setNextState
{
  [self setState: [self nextState]];
}

/*
 * Modifying Text Attributes
 */
- (NSTextAlignment) alignment
{
  return _cell.text_align;
}

- (NSFont*) font
{
  return _cell_font;
}

- (BOOL) isEditable
{
  return _cell.is_editable;
}

- (BOOL) isSelectable
{
  return _cell.is_selectable || _cell.is_editable;
}

- (BOOL) isScrollable
{
  return _cell.is_scrollable;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  _cell.text_align = mode;
}

- (void) setEditable: (BOOL)flag
{
  /*
   *	The cell_editable flag is also checked to see if the cell is selectable
   *	so turning edit on also turns selectability on (until edit is turned
   *	off again).
   */
  _cell.is_editable = flag;
}

- (void) setFont: (NSFont*)fontObject
{
  NSAssert(fontObject == nil || [fontObject isKindOfClass: fontClass],
    NSInvalidArgumentException);

  ASSIGN(_cell_font, fontObject);
}

- (void) setSelectable: (BOOL)flag
{
  _cell.is_selectable = flag;

  /*
   *	Making a cell unselectable also makes it uneditable until a
   *	setEditable re-enables it.
   */
  if (!flag)
    _cell.is_editable = NO;
}

- (void) setScrollable: (BOOL)flag
{
  _cell.is_scrollable = flag;
}

- (void) setWraps: (BOOL)flag
{
  _cell.wraps = flag;  
  if (flag)
    _cell.is_scrollable = NO;
}

- (BOOL) wraps
{
  return _cell.wraps;
}

- (void) setAttributedStringValue: (NSAttributedString*)attribStr
{
  //TODO
}

- (NSAttributedString*) attributedStringValue
{
  //TODO
  return nil;
}

- (void) setAllowsEditingTextAttributes: (BOOL)flag
{
  //TODO
}

- (BOOL) allowsEditingTextAttributes
{
  //TODO
  return NO;
}

- (void) setImportsGraphics: (BOOL)flag
{
  //TODO
}

- (BOOL) importsGraphics
{
  //TODO
  return NO;
}

- (NSText*) setUpFieldEditorAttributes: (NSText*)textObject
{
  if (_cell.is_disabled)
    [textObject setTextColor: dtxtCol];
  else
    [textObject setTextColor: txtCol];
  
  [textObject setFont: _cell_font];
  [textObject setAlignment: _cell.text_align];
  [textObject setEditable: _cell.is_editable];
  [textObject setSelectable: _cell.is_selectable || _cell.is_editable];
  return textObject;
}

/*
 * Target and Action
 */
- (SEL) action
{
  return NULL;
}

- (void) setAction: (SEL)aSelector
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set an action in an NSCell"];
}

- (void) setTarget: (id)anObject
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set a target in an NSCell"];
}

- (id) target
{
  return nil;
}

- (BOOL) isContinuous
{
  return _cell.is_continuous;
}

- (void) setContinuous: (BOOL)flag
{
  _cell.is_continuous = flag;
  [self sendActionOn: (NSLeftMouseUpMask|NSPeriodicMask)];
}

- (int) sendActionOn: (int)mask
{
  unsigned int previousMask = _action_mask;

  _action_mask = mask;

  return previousMask;
}

/*
 * Setting the Image
 */
- (NSImage*) image
{
  if (_cell.type == NSImageCellType)
    {
      return _cell_image;
    }
  else
    return nil;
}

- (void) setImage: (NSImage*)anImage
{
  if (anImage) 
    {
      NSAssert ([anImage isKindOfClass: imageClass],
		NSInvalidArgumentException);
    }
  
  _cell.type = NSImageCellType;    
  
  ASSIGN(_cell_image, anImage);
}

/*
 * Assigning a Tag
 */
- (void) setTag: (int)anInt
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set a tag in an NSCell"];
}

- (int) tag
{
  return -1;
}

/*
 * Formatting Data
 */
- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned int)leftDigits
			  right: (unsigned int)rightDigits
{
  _cell.float_autorange = autoRange;
  _cell_float_left = leftDigits;
  _cell_float_right = rightDigits;
}

- (void) setFormatter: (NSFormatter*)newFormatter 
{
  ASSIGN (_formatter, newFormatter);
}

- (id) formatter
{
  return _formatter;
}

- (int) entryType
{
  return _cell.entry_type;
}

- (void) setEntryType: (int)aType
{
  [self setType: NSTextCellType];
  _cell.entry_type = aType;
}

- (BOOL) isEntryAcceptable: (NSString*)aString
{
  // TODO
  return YES;
}

/*
 * Menu
 */
- (void) setMenu: (NSMenu*)aMenu 
{
  //TODO
}

- (NSMenu*) menu
{
  //TODO
  return nil;
}

- (NSMenu*) menuForEvent: (NSEvent*)anEvent 
		  inRect: (NSRect)cellFrame 
		  ofView: (NSView*)aView
{
  // TODO
  return [self menu];
}

/*
 * Comparing to Another NSCell
 */
- (NSComparisonResult) compare: (id)otherCell
{
  if ([otherCell isKindOfClass: cellClass] == NO)
    {
      [NSException raise: NSBadComparisonException
		   format: @"NSCell comparison with non-NSCell"];
    }
  if (_cell.type != NSTextCellType
      || ((NSCell*)otherCell)->_cell.type != NSTextCellType)
    {
      [NSException raise: NSBadComparisonException
		   format: @"Comparison between non-text cells"];
    }
  return [_contents compare: ((NSCell*)otherCell)->_contents];
}

/*
 * respond to keyboard
 */
- (BOOL) acceptsFirstResponder
{
  return !_cell.is_disabled && ([self refusesFirstResponder] == NO);
}

- (void) setShowsFirstResponder: (BOOL)flag 
{
}

- (BOOL) showsFirstResponder
{
  return NO;
}

- (void) setTitleWithMnemonic: (NSString*)aString
{
  // Provided for compatibility only
}

- (NSString*) mnemonic
{
  // provided for compatibility only
  return @"";
}

- (void) setMnemonicLocation: (unsigned int)location 
{
  // Provided for compatibility only
}

- (unsigned int) mnemonicLocation
{
  // Provided for compatibiliy only
  return NSNotFound;
}

- (BOOL) refusesFirstResponder
{
  // Approximate compatibility behaviour
  return _cell.is_disabled;
}

- (void) setRefusesFirstResponder: (BOOL)flag
{
  // Approximate compatibility behaviour
  _cell.is_disabled = flag;
}

- (void) performClick: (id)sender
{
  SEL action = [self action];
  NSView *cv = [self controlView];

  if (cv)
    {  
      NSRect   cvBounds = [cv bounds];
      NSWindow *cvWin = [cv window];
      
      [self highlight: YES withFrame: cvBounds inView: cv];
      [cvWin flushWindow];
      
      // Wait approx 1/10 seconds
      [[NSRunLoop currentRunLoop] 
	runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
      
      [self highlight: NO withFrame: cvBounds inView: cv];
      [cvWin flushWindow];
      
      if (action)
	{
	  NS_DURING
	    {
	      [(NSControl*)cv sendAction: action to: [self target]];
	    }
	  NS_HANDLER
	    {
	      [localException raise];
	    }
	  NS_ENDHANDLER
	}
    }
  else  // We have no control view.  The best we can do is the following. 
    {
      if (action)
	{
	  NS_DURING
	    {
	      [[NSApplication sharedApplication] sendAction: action
						 to: [self target]
						 from: self];
	    }
	  NS_HANDLER
	    {
	      [localException raise];
	    }
	  NS_ENDHANDLER
	}
    }
}

/*
 * Deriving values from other objects (not necessarily cells)
 */
- (void) takeObjectValueFrom: (id)sender
{
  [self setObjectValue: [sender objectValue]];
}

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

/*
 * Using the NSCell to Represent an Object
 */
- (id) representedObject
{
  return _represented_object;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN (_represented_object, anObject);
}

/*
 * Tracking the Mouse
 */
- (BOOL) continueTracking: (NSPoint)lastPoint
		       at: (NSPoint)currentPoint
		   inView: (NSView*)controlView
{
  return YES;
}

- (int) mouseDownFlags
{ 
  //FIXME: Should be set on mouse down
  return 0;
}

- (void) getPeriodicDelay: (float*)delay interval: (float*)interval
{
  *delay = 0.1;
  *interval = 0.1;
}

- (BOOL) startTrackingAt: (NSPoint)startPoint inView: (NSView*)controlView
{
  // If the point is in the view then yes start tracking
  if ([controlView mouse: startPoint inRect: [controlView bounds]])
    return YES;
  else
    return NO;
}

- (void) stopTracking: (NSPoint)lastPoint
		   at: (NSPoint)stopPoint
	       inView: (NSView*)controlView
	    mouseIsUp: (BOOL)flag
{
}

- (BOOL) trackMouse: (NSEvent*)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView*)controlView
       untilMouseUp: (BOOL)flag
{
  NSApplication	*theApp = [NSApplication sharedApplication];
  unsigned	event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask
    | NSMouseMovedMask | NSLeftMouseDraggedMask | NSMiddleMouseDraggedMask
    | NSRightMouseDraggedMask;
  NSPoint	location = [theEvent locationInWindow];
  NSPoint	point = [controlView convertPoint: location fromView: nil];
  float		delay;
  float		interval;
  id		target = [self target];
  SEL		action = [self action];
  NSPoint	last_point = point;
  BOOL		done;
  BOOL		mouseWentUp;

  NSDebugLog(@"NSCell start tracking\n");
  NSDebugLog(@"NSCell tracking in rect %f %f %f %f\n",
		      cellFrame.origin.x, cellFrame.origin.y,
		      cellFrame.size.width, cellFrame.size.height);
  NSDebugLog(@"NSCell initial point %f %f\n", point.x, point.y);

  if (![self startTrackingAt: point inView: controlView])
    return NO;

  if (![controlView mouse: point inRect: cellFrame])
    return NO;	// point is not in cell

  if ((_action_mask & NSLeftMouseDownMask) 
      && [theEvent type] == NSLeftMouseDown)
    [(NSControl*)controlView sendAction: action to: target];

  if (_cell.is_continuous)
    {
      [self getPeriodicDelay: &delay interval: &interval];
      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod: interval];
      event_mask |= NSPeriodicMask;
    }

  NSDebugLog(@"NSCell get mouse events\n");
  mouseWentUp = NO;
  done = NO;
  while (!done)
    {
      NSEventType	eventType;
      BOOL		pointIsInCell;
      unsigned		periodCount = 0;

      theEvent = [theApp nextEventMatchingMask: event_mask
				     untilDate: nil
				        inMode: NSEventTrackingRunLoopMode
				       dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic || periodCount == 4)
	{
	  last_point = point;
	  if (eventType == NSPeriodic)
	    {
	      NSWindow	*w = [controlView window];

	      /*
	       * Too many periodic events in succession - 
	       * update the mouse location and reset the counter.
	       */
	      location = [w mouseLocationOutsideOfEventStream];
	      periodCount = 0;
	    }
	  else
	    {
	      location = [theEvent locationInWindow];
	    }
	  point = [controlView convertPoint: location fromView: nil];
	  NSDebugLog(@"NSCell location %f %f\n", location.x, location.y);
	  NSDebugLog(@"NSCell point %f %f\n", point.x, point.y);
	}
      else
	{
	  periodCount++;
	  NSDebugLog (@"got a periodic event");
	}

      if (![controlView mouse: point inRect: cellFrame])
	{
	  NSDebugLog(@"NSCell point not in cell frame\n");

	  pointIsInCell = NO;	
	  if (flag == NO) 
	    {
	      NSDebugLog(@"NSCell return immediately\n");
	      done = YES;
	    }
	}
      else
	{
	  pointIsInCell = YES;
	}

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
          [self setState: !_cell.state];
	  if ((_action_mask & NSLeftMouseUpMask))
	    [(NSControl*)controlView sendAction: action to: target];
	}
      else
	{
	  if (pointIsInCell && ((eventType == NSLeftMouseDragged
			  && (_action_mask & NSLeftMouseDraggedMask))
			  || ((eventType == NSPeriodic)
			  && (_action_mask & NSPeriodicMask))))
	    [(NSControl*)controlView sendAction: action to: target];
	}
    }

  // Hook called when stop tracking
  [self stopTracking: last_point
		  at: point
	      inView: controlView
	   mouseIsUp: mouseWentUp];

  if (_cell.is_continuous)
    [NSEvent stopPeriodicEvents];

  // Return YES only if the mouse went up within the cell
  if (mouseWentUp && [controlView mouse: point inRect: cellFrame])
    {
      NSDebugLog(@"NSCell mouse went up in cell\n");
      return YES;
    }

  NSDebugLog(@"NSCell mouse did not go up in cell\n");
  return NO;				// Otherwise return NO
}

/*
 * Managing the Cursor
 */
- (void) resetCursorRect: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (_cell.type == NSTextCellType && _cell.is_disabled == NO
    && (_cell.is_selectable == YES || _cell.is_editable == YES))
    {
      static NSCursor	*c = nil;
      NSRect	r;

      if (c == nil)
	{
	  c = RETAIN([NSCursor IBeamCursor]);
	}
      r = NSIntersectionRect(cellFrame, [controlView visibleRect]);
      /*
       * Here we depend on an undocumented feature of NSCursor which may or
       * may not exist in OPENSTEP or MacOS-X ...
       * If we add a cursor rect to a view and don't set it to be set on
       * either entry to or exit from the view, we push it on entry and
       * pop it from the cursor stack on exit.
       */
      [controlView addCursorRect: r cursor: c];
    }
}

/*
 * Handling Keyboard Alternatives
 */
- (NSString*) keyEquivalent
{
  return @"";
}

/*
 * Determining Component Sizes
 */
- (void) calcDrawInfo: (NSRect)aRect
{
}

- (NSSize) cellSize
{
  NSSize borderSize, s;
  
  // Get border size
  if (_cell.is_bordered)
    borderSize = _sizeForBorderType (NSLineBorder);
  else if (_cell.is_bezeled)
    borderSize = _sizeForBorderType (NSBezelBorder);
  else
    borderSize = NSZeroSize;

  // Add spacing between border and inside 
  if (_cell.is_bordered || _cell.is_bezeled)
    {
      borderSize.height += 1;
      borderSize.width  += 3;
    }

  // Get Content Size
  switch (_cell.type)
    {
      case NSTextCellType:
	{
	  if ((_contents != nil) && ([_contents isEqualToString: @""] == NO))
	    {
	      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						   _cell_font, 
						 NSFontAttributeName,
						 nil];
	      s = [_contents sizeWithAttributes: dict];
	    }
	  else 
	    {
	      s.width = [_cell_font widthOfString: @"A"];
	      s.height = [_cell_font pointSize] - [_cell_font descender];
	    }
	}
	break;

      case NSImageCellType:
	if (_cell_image == nil)
	  {
	    s = NSZeroSize;
	  }
	else
	  {
	    s = [_cell_image size];
	  }
	break;

      case NSNullCellType:
	//  macosx instead returns a 'very big size' here; we return NSZeroSize
	s = NSZeroSize;
	break;
    }

  // Add in border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;
  
  return s;
}

- (NSSize) cellSizeForBounds: (NSRect)aRect
{
  if (_cell.type == NSTextCellType)
    {
      // TODO: Resize the text to fit
    }

  return [self cellSize];
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // Get border size
  if (_cell.is_bordered)
    borderSize = _sizeForBorderType (NSLineBorder);
  else if (_cell.is_bezeled)
    borderSize = _sizeForBorderType (NSBezelBorder);
  else
    borderSize = NSZeroSize;

  return NSInsetRect(theRect, borderSize.width, borderSize.height);
}

- (NSRect) imageRectForBounds: (NSRect)theRect
{
  return [self drawingRectForBounds: theRect];
}

- (NSRect) titleRectForBounds: (NSRect)theRect
{
  if (_cell.type == NSTextCellType)
    {
      NSRect frame = [self drawingRectForBounds: theRect];
      
      // Add spacing between border and inside 
      if (_cell.is_bordered || _cell.is_bezeled)
	{
	  frame.origin.x += 3;
	  frame.size.width -= 6;
	  frame.origin.y += 1;
	  frame.size.height -= 2;
	}
      return frame;
    }
  else
    {
      return theRect;
    }
}

/*
 * Displaying
 */
- (NSView*) controlView
{
  return nil;
}

// TODO: Remove this hack without breaking NSTextFieldCell
- (NSColor*) textColor
{
  if (_cell.is_disabled)
    return dtxtCol;
  else
    return txtCol;
}

- (void) _drawText: (NSString*) title inFrame: (NSRect) cellFrame
{
  NSColor	*textColor;
  NSDictionary	*attributes;
  NSSize        titleSize;

  if (!title)
    return;

  textColor = [self textColor];

  if (!_cell_font)
    {
      [NSException raise: NSInvalidArgumentException
		   format: 
		     @"Request to draw a text cell but no font specified!"];
    }

  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			       _cell_font, NSFontAttributeName,
			     textColor, NSForegroundColorAttributeName,
			     nil];
  
  titleSize = [title sizeWithAttributes: attributes];

  // Determine y position of text

  /* Important: text should always be vertically centered without
   * considering descender [as if descender did not exist].
   * This is particularly important for single line texts.
   * Please make sure the output remains always correct.
   */
  cellFrame.origin.y = NSMidY (cellFrame) - titleSize.height/2; 
  cellFrame.size.height = titleSize.height;

  // Determine the x position of text
  switch (_cell.text_align)
    {
      // ignore the justified and natural alignments
      case NSLeftTextAlignment:
      case NSJustifiedTextAlignment:
      case NSNaturalTextAlignment:
	break;
      case NSRightTextAlignment:
        if (titleSize.width < NSWidth (cellFrame))
          {
            float shift = NSWidth (cellFrame) - titleSize.width;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
	break;
      case NSCenterTextAlignment:
        if (titleSize.width < NSWidth (cellFrame))
          {
            float shift = (NSWidth (cellFrame) - titleSize.width) / 2;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
    }

  [title drawInRect: cellFrame  withAttributes: attributes];
}

/*
 * This drawing is minimal and with no background,
 * to make it easier for subclass to customize drawing. 
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (![controlView window])
    return;

  cellFrame = [self drawingRectForBounds: cellFrame];

  //FIXME: Check if this is also neccessary for images,
  // Add spacing between border and inside 
  if (_cell.is_bordered || _cell.is_bezeled)
    {
      cellFrame.origin.x += 3;
      cellFrame.size.width -= 6;
      cellFrame.origin.y += 1;
      cellFrame.size.height -= 2;
    }

  [controlView lockFocus];

  switch (_cell.type)
    {
      case NSTextCellType:
	 [self _drawText: _contents inFrame: cellFrame];
	 break;

      case NSImageCellType:
	if (_cell_image)
	  {
	    NSSize size;
	    NSPoint position;

	    size = [_cell_image size];
	    position.x = MAX(NSMidX(cellFrame) - (size.width/2.),0.);
	    position.y = MAX(NSMidY(cellFrame) - (size.height/2.),0.);
	    /*
	     * Images are always drawn with their bottom-left corner
	     * at the origin so we must adjust the position to take
	     * account of a flipped view.
	     */
	    if ([controlView isFlipped])
	      position.y += size.height;
	    [_cell_image compositeToPoint: position operation: NSCompositeCopy];
	  }
	 break;

      case NSNullCellType:
         break;
    }
  [controlView unlockFocus];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSDebugLog (@"NSCell drawWithFrame: inView: ");

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame) || ![controlView window])
    return;

  [controlView lockFocus];

  // draw the border if needed
  if (_cell.is_bordered)
    {
      [shadowCol set];
      NSFrameRect(cellFrame);
    }
  else if (_cell.is_bezeled)
    {
      NSDrawWhiteBezel(cellFrame, NSZeroRect);
    }

  [controlView unlockFocus];
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (BOOL) isHighlighted
{
  return _cell.is_highlighted;
}

- (void) highlight: (BOOL)lit
	 withFrame: (NSRect)cellFrame
	    inView: (NSView*)controlView
{
  if (_cell.is_highlighted != lit)
    {
      _cell.is_highlighted = lit;
      /*
       * NB: This has a visible effect only if subclasses override
       * drawWithFrame:inView: to draw something special when the
       * cell is highlighted. 
       * NSCell simply draws border+text/image and makes no highlighting, 
       * for easier subclassing.
       */
     [self drawWithFrame: cellFrame inView: controlView];
    }
}

/*
 * Editing Text
 */
- (void) editWithFrame: (NSRect)aRect
		inView: (NSView*)controlView
		editor: (NSText*)textObject
	      delegate: (id)anObject
		 event: (NSEvent*)theEvent
{
  if (!controlView || !textObject || !_cell_font
    || (_cell.type != NSTextCellType))
    return;

  [textObject setFrame: [self titleRectForBounds: aRect]];
  [controlView addSubview: textObject];  

  if (_formatter != nil)
    {
      NSString *contents; 

      contents = [_formatter editingStringForObjectValue: _objectValue];
      if (contents == nil)
	{
	  contents = _contents;
	}
      [textObject setText: contents];
    }
  else
    {
      [textObject setText: _contents];
    }
  
  [textObject setDelegate: anObject];
  [[controlView window] makeFirstResponder: textObject];
  [textObject display];

  if ([theEvent type] == NSLeftMouseDown)
    {
      [textObject mouseDown: theEvent];
    }
}

- (void) endEditing: (NSText*)textObject
{
  [textObject setDelegate: nil];
  [textObject removeFromSuperview];
}

- (void) selectWithFrame: (NSRect)aRect
		  inView: (NSView*)controlView
		  editor: (NSText*)textObject
		delegate: (id)anObject
		   start: (int)selStart
		  length: (int)selLength
{
  if (!controlView || !textObject || !_cell_font
    || (_cell.type != NSTextCellType))
    return;

  [textObject setFrame: [self titleRectForBounds: aRect]];
  [controlView addSubview: textObject];
  [textObject setText: _contents];
  [textObject setSelectedRange: NSMakeRange (selStart, selLength)];
  [textObject setDelegate: anObject];
  [[controlView window] makeFirstResponder: textObject];
  [textObject display];
}

- (BOOL) sendsActionOnEndEditing 
{
  //TODO
  return NO;
}

- (void) setSendsActionOnEndEditing: (BOOL)flag
{
  //TODO
}

/*
 * Copying
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSCell	*c = [[isa allocWithZone: zone] init];

  c->_contents = [_contents copyWithZone: zone];
  ASSIGN (c->_cell_image, _cell_image);
  ASSIGN (c->_cell_font, _cell_font);
  ASSIGN (c->_objectValue, _objectValue); 
  c->_cell = _cell;   // This copies all the flags at once.
  c->_cell_float_left = _cell_float_left;
  c->_cell_float_right = _cell_float_right;
  c->_action_mask = _action_mask;
  /* Attention! This is not retained */
  c->_represented_object = _represented_object;

  /* Attention! The formatter is retained, *not* copied, 
     as per NSFormatter spec */
  c->_formatter = RETAIN (_formatter);

  return c;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL flag;
  unsigned int tmp_int;

  [aCoder encodeObject: _contents];
  [aCoder encodeObject: _cell_image];
  [aCoder encodeObject: _cell_font];
  [aCoder encodeObject: _objectValue];
  tmp_int = _cell.state;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  flag = _cell.is_highlighted;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_disabled;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_editable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_bordered;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_bezeled;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_scrollable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_selectable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_continuous;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.float_autorange;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.wraps;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.allows_mixed_state;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_cell_float_left];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_cell_float_right];
  tmp_int = _cell.image_position;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.type;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.text_align;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.entry_type;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_action_mask];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_formatter];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_represented_object];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL flag;
  unsigned int tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_contents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell_font];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_objectValue];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.state = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_highlighted = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_disabled = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_editable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_bordered = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_bezeled = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_scrollable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_selectable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_continuous = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.float_autorange = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.wraps = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.allows_mixed_state = flag;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) 
	    at: &_cell_float_left];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) 
	    at: &_cell_float_right];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.image_position = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.type = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.text_align = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.entry_type = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &_action_mask];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_formatter];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_represented_object];

  if (_formatter != nil)
    {
      NSString *contents;

      contents = [_formatter stringForObjectValue: _objectValue];
      if (contents != nil)
	{
	  _cell.has_valid_object_value = YES;
	  ASSIGN (_contents, contents);
	}
    }
  
  return self;
}

@end

/*
 * Global function which should go somewhere else
 */
inline NSSize 
_sizeForBorderType (NSBorderType aType)
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
