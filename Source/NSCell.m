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
#include <AppKit/NSView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSMenu.h>
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
  ASSIGN (txtCol, [colorClass controlTextColor]);
  ASSIGN (dtxtCol, [colorClass disabledControlTextColor]);
  ASSIGN (shadowCol, [colorClass controlDarkShadowColor]);
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
  _cell_image = RETAIN (anImage);
  _cell.image_position = NSImageOnly;
  _font = RETAIN ([fontClass userFontOfSize: 0]);

  // Implicitly set by allocation:
  //
  //_font = nil;
  //_cell.contents_is_attributed_string = NO;
  //_cell.is_highlighted = NO;
  //_cell.is_disabled = NO;
  //_cell.is_editable = NO;
  //_cell.is_rich_text = NO;
  //_cell.imports_graphics = NO;
  //_cell.shows_first_responder = NO;
  //_cell.refuses_first_responder = NO;
  //_cell.sends_action_on_end_editing = NO;
  //_cell.is_bordered = NO;
  //_cell.is_bezeled = NO;
  //_cell.is_scrollable = NO;
  //_cell.is_selectable = NO;
  //_cell.is_continuous = NO;
  //_cell.state = 0;
  _action_mask = NSLeftMouseUpMask;

  return self;
}

- (id) initTextCell: (NSString*)aString
{
  _cell.type = NSTextCellType;
  _contents = RETAIN (aString);
  _font = RETAIN ([fontClass userFontOfSize: 0]);

  // Implicitly set by allocation:
  //
  //_cell.contents_is_attributed_string = NO;
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
  _action_mask = NSLeftMouseUpMask;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE (_contents);
  TEST_RELEASE (_cell_image);
  TEST_RELEASE (_font);
  TEST_RELEASE (_represented_object);
  TEST_RELEASE (_objectValue);
  TEST_RELEASE (_formatter);
  TEST_RELEASE (_menu);

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
  if (_cell.contents_is_attributed_string == NO)
    {
      return [_contents doubleValue];
    }
  else
    {
      return [[(NSAttributedString *)_contents string] doubleValue];
    }
}

- (float) floatValue
{
  if (_cell.contents_is_attributed_string == NO)
    {
      return [_contents floatValue];
    }
  else
    {
      return [[(NSAttributedString *)_contents string] floatValue];      
    }
}

- (int) intValue
{
  if (_cell.contents_is_attributed_string == NO)
    {
      return [_contents intValue];
    }
  else
    {
      return [[(NSAttributedString *)_contents string] intValue];
    }
}

- (NSString*) stringValue
{
  if (_cell.contents_is_attributed_string == NO)
    {
      return _contents;
    }
  else
    {
      return [(NSAttributedString *)_contents string];
    }
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
  _cell.contents_is_attributed_string = NO;
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
  _cell.contents_is_attributed_string = NO;

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
    switch (aParameter)
      {
	case NSCellDisabled: return _cell.is_disabled;
	case NSCellState: return _cell.state;
	case NSCellEditable: return _cell.is_editable;
	case NSCellHighlighted: return _cell.is_highlighted;
	case NSCellIsBordered: return _cell.is_bordered;
	case NSCellAllowsMixedState: return _cell.allows_mixed_state; 

/*	
	case NSPushInCell: return _cell.;
	case NSChangeGrayCell: return _cell.;
	case NSCellLightsByContents: return _cell.;
	case NSCellLightsByGray: return _cell.;
	case NSChangeBackgroundCell: return _cell.;
	case NSCellLightsByBackground: return _cell.;
	case NSCellChangesContents: return _cell.;  
	case NSCellIsInsetButton: return _cell.;
*/
	case NSCellHasOverlappingImage: 
	  return _cell.image_position == NSImageOverlaps;
	case NSCellHasImageHorizontal: 
	  {
	    return (_cell.image_position == NSImageRight) 
	      || (_cell.image_position == NSImageLeft);
	  }
	case NSCellHasImageOnLeftOrBottom: 
	  {
	    return (_cell.image_position == NSImageBelow) 
	      || (_cell.image_position == NSImageLeft);
	  }
      }

  return 0;
}

- (void) setCellAttribute: (NSCellAttribute)aParameter  to: (int)value
{
  switch (aParameter)
    {
    case NSCellDisabled:
      {
	_cell.is_disabled = value;
	break;
      }
    case NSCellState:
      {
	_cell.state = value;
	break;
      }
    case NSCellEditable:
      {
	_cell.is_editable = value;
	break;
      }
    case NSCellHighlighted:
      {
	_cell.is_highlighted = value;
	break;
      }
    case NSCellHasOverlappingImage:
      {
	if (value)
	  {
	    _cell.image_position = NSImageOverlaps;
	  }
	else
	  {
	    if (_cell.image_position == NSImageOverlaps)
	      {
		_cell.image_position = NSImageLeft;
	      }
	  }
	break;
      }
    case NSCellHasImageHorizontal:
      {
	if (value)
	  {
	    if (_cell.image_position != NSImageLeft
		&& _cell.image_position != NSImageRight)
	      {
		_cell.image_position = NSImageLeft;
	      }
	  }
	else
	  {
	    if (_cell.image_position == NSImageLeft)
	      {
		_cell.image_position = NSImageAbove;
	      }
	    else if (_cell.image_position == NSImageRight)
	      {
		_cell.image_position = NSImageBelow;
	      }
	  }
	break;
      }
    case NSCellHasImageOnLeftOrBottom:
      {
	if (value)
	  {
	    if (_cell.image_position == NSImageAbove)
	      {
		_cell.image_position = NSImageBelow;
	      }
	    else
	      {
		_cell.image_position = NSImageLeft;
	      }
	  }
	else
	  {
	    if (_cell.image_position == NSImageBelow)
	      {
		_cell.image_position = NSImageAbove;
	      }
	    else
	      {
		_cell.image_position = NSImageRight;
	      }
	  }
	break;
      }
      /*
    case NSCellChangesContents:
      _cell. = value;
      break;
    case NSCellIsInsetButton:
      _cell. = value;
      break;
*/
    case NSCellIsBordered:
      {
	_cell.is_bordered = value;
	break;
      }
    case NSCellAllowsMixedState:
      {
	_cell.allows_mixed_state = value;
	break;
      }
    }
}

/*
 * Setting the NSCell's Type
 */
- (void) setType: (NSCellType)aType
{
  if (_cell.type == aType)
    {
      return;
    }
  
  _cell.type = aType;
  switch (_cell.type)
    {
      case NSTextCellType:
	{
	  ASSIGN (_contents, @"title");
	  _cell.contents_is_attributed_string = NO;
	  /* Doc says we have to reset the font too. */
	  ASSIGN (_font, [fontClass userFontOfSize: 0]);
	  break;
	}
      case NSImageCellType:
	{
	  TEST_RELEASE (_cell_image);
	  _cell_image = nil;
	  break;
	}
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
    {
      _cell.is_bordered = NO;
    }
}

- (void) setBordered: (BOOL)flag
{
  _cell.is_bordered = flag;
  if (_cell.is_bordered)
    {
      _cell.is_bezeled = NO;
    }
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
  if (value > 0 || (value < 0 && _cell.allows_mixed_state == NO))
    {
      _cell.state = NSOnState;
    }
  else if (value == 0)
    {
      _cell.state = NSOffState;
    }
  else 
    {
      _cell.state = NSMixedState;
    }
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
  if (!flag && _cell.state == NSMixedState)
    {
      [self setNextState];
    }
}

- (int) nextState
{
  switch (_cell.state)
    {
      case NSOnState:
	{
	  return NSOffState;
	}
      case NSOffState:
	{
	  if (_cell.allows_mixed_state)
	    {
	      return NSMixedState;
	    }
	  else
	    {
	      return NSOnState;
	    }
	}
      case NSMixedState:
      default:
	{
	  return NSOnState;
	}
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
  return _font;
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
   * The cell_editable flag is also checked to see if the cell is
   * selectable so turning edit on also turns selectability on (until
   * edit is turned off again).  
   */
  _cell.is_editable = flag;
}

- (void) setFont: (NSFont*)fontObject
{
  ASSIGN (_font, fontObject);
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
    {
      _cell.is_scrollable = NO;
    }
}

- (BOOL) wraps
{
  return _cell.wraps;
}

- (void) setAttributedStringValue: (NSAttributedString*)attribStr
{
  /* Hmm.  FIXME.  Not sure what to do here. */
  if (_formatter != nil)
    {
      id newObjectValue;
      
      if ([_formatter getObjectValue: &newObjectValue 
		      forString: [attribStr string] 
		      errorDescription: NULL] == YES)
	{
	  [self setObjectValue: newObjectValue];
	  /* What about the attributed string ?  We are loosing it. */
	  return;
	}
    }

  /* In all other cases */
  ASSIGN (_contents, attribStr);
  _cell.has_valid_object_value = NO;
  _cell.contents_is_attributed_string = YES;
}

- (NSAttributedString*) attributedStringValue
{
  if (_formatter != nil)
    {
      NSDictionary *attributes;
      NSAttributedString *attrStr;

      attributes = AUTORELEASE ([self _nonAutoreleasedTypingAttributes]);
      attrStr = [_formatter attributedStringForObjectValue: _objectValue 
			    withDefaultAttributes: attributes];

      if (attrStr != nil)
	{
	  return attrStr;
	}
    }

  /* In all other cases */
  if (_cell.contents_is_attributed_string)
    {
      return (NSAttributedString *)_contents;
    }
  else
    {
      NSDictionary *dict;
      NSAttributedString *attrStr;

      dict = AUTORELEASE ([self _nonAutoreleasedTypingAttributes]);
      attrStr = [[NSAttributedString alloc] initWithString: _contents 
					    attributes: dict];
      return AUTORELEASE (attrStr);
    }
}

- (void) setAllowsEditingTextAttributes: (BOOL)flag
{
  _cell.is_rich_text = flag;
  if (!flag)
    _cell.imports_graphics = NO;
}

- (BOOL) allowsEditingTextAttributes
{
  return _cell.is_rich_text;
}

- (void) setImportsGraphics: (BOOL)flag
{
  _cell.imports_graphics = flag;
  if (flag)
    _cell.is_rich_text = YES;
}

- (BOOL) importsGraphics
{
  return _cell.imports_graphics;
}

- (NSText*) setUpFieldEditorAttributes: (NSText*)textObject
{
  [textObject setTextColor: [self textColor]];
  if (_cell.contents_is_attributed_string == NO)
    {
      /* TODO: Manage scrollable attribute */
      [textObject setFont: _font];
      [textObject setAlignment: _cell.text_align];
    }
  else
    {
      /* FIXME/TODO.  What do we do if we are an attributed string.  
	 Think about what happens when the user ends editing. 
	 Allows editing text attributes... Formatter... TODO. */
    }
  [textObject setEditable: _cell.is_editable];
  [textObject setSelectable: _cell.is_selectable || _cell.is_editable];
  [textObject setRichText: _cell.is_rich_text];
  [textObject setImportsGraphics: _cell.imports_graphics];
  [textObject setSelectedRange: NSMakeRange(0, 0)];

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
  
  ASSIGN (_cell_image, anImage);
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
  // TODO: Pass this on to the formatter to handle
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
  // TODO: This should select a suitable formatter
  _cell.entry_type = aType;
}

- (BOOL) isEntryAcceptable: (NSString*)aString
{
  if (_formatter != nil)
    {
      id newObjectValue;
      
      return [_formatter getObjectValue: &newObjectValue 
			 forString: aString 
			 errorDescription: NULL];
    }
  else 
    {
      return YES;
    }
}

/*
 * Menu
 */
- (void) setMenu: (NSMenu*)aMenu 
{
  ASSIGN (_menu, aMenu);
}

- (NSMenu*) menu
{
  return _menu;
}

- (NSMenu*) menuForEvent: (NSEvent*)anEvent 
		  inRect: (NSRect)cellFrame 
		  ofView: (NSView*)aView
{
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
  return _cell.is_disabled == NO && _cell.refuses_first_responder == NO;
}

- (void) setShowsFirstResponder: (BOOL)flag 
{
  _cell.shows_first_responder = flag;
}

- (BOOL) showsFirstResponder
{
  return _cell.shows_first_responder;
}

- (void) setTitleWithMnemonic: (NSString*)aString
{
  unsigned int location = [aString rangeOfString: @"&"].location;

  [self setStringValue: [aString stringByReplacingString: @"&"
				 withString: @""]];
  // TODO: We should underline this character
  [self setMnemonicLocation: location];
}

- (NSString*) mnemonic
{
  unsigned int location = [self mnemonicLocation];
  NSString *c;

  if (_cell.contents_is_attributed_string)
    {
      c = [(NSAttributedString *)_contents string];
    }
  else
    {
      c = _contents;
    }

  if ((location == NSNotFound) || location >= [c length])
    return @"";

  return [c substringWithRange: NSMakeRange (location, 1)];
}

- (void) setMnemonicLocation: (unsigned int)location 
{
  _mnemonic_location = location;
}

- (unsigned int) mnemonicLocation
{
  return _mnemonic_location;
}

/* Apple Compatibility method - do not use - please test whether the
   cell is enabled or disabled instead. */
- (BOOL) refusesFirstResponder
{
  return _cell.refuses_first_responder;
}

/* Apple Compatibility method - do not use - please disable the cell
   instead. */
- (void) setRefusesFirstResponder: (BOOL)flag
{
  _cell.refuses_first_responder = flag;
}

- (void) performClick: (id)sender
{
  SEL action = [self action];
  NSView *cv = [self controlView];

  if(_cell.is_disabled == YES)
    return;

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
  /* Ahm - not nice - the RETAIN here could cause retain cycles - anyway. */
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
  return _mouse_down_flags;
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

  _mouse_down_flags = [theEvent modifierFlags];
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

  if (mouseWentUp)
    {
      [self setNextState];
      if ((_action_mask & NSLeftMouseUpMask))
	[(NSControl*)controlView sendAction: action to: target];
    }

  // Return YES only if the mouse went up within the cell
  if (mouseWentUp && (flag || [controlView mouse: point inRect: cellFrame]))
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
	  if (_cell.contents_is_attributed_string)
	    {
	      s = [(NSAttributedString *)_contents size];
	    }
	  else
	    {
	      if ((_contents != nil) 
		  && ([_contents isEqualToString: @""] == NO))
		{
		  s = [self _sizeText: _contents];
		}
	      else 
		{
		  s = [self _sizeText: @"A"];
		}
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
	if (_cell.contents_is_attributed_string)
	  {
	    [self _drawAttributedText: (NSAttributedString *)_contents  
		  inFrame: cellFrame];
	  }
	else
	  {
	    [self _drawText: _contents inFrame: cellFrame];
	  }
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
	    [_cell_image compositeToPoint: position operation: NSCompositeSourceOver];
	  }
	 break;

      case NSNullCellType:
         break;
    }

  if (_cell.shows_first_responder)
    NSDottedFrameRect(cellFrame);

  // NB: We don't do any highlighting to make it easier for subclasses
  // to reuse this code while doing their own custom highlighting and
  // prettyfying
  [controlView unlockFocus];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSDebugLog (@"NSCell drawWithFrame: inView: ");

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame) || ![controlView window])
    return;

  // draw the border if needed
  if (_cell.is_bordered)
    {
      [controlView lockFocus];
      [shadowCol set];
      NSFrameRect(cellFrame);
      [controlView unlockFocus];
    }
  else if (_cell.is_bezeled)
    {
      [controlView lockFocus];
      NSDrawWhiteBezel(cellFrame, NSZeroRect);
      [controlView unlockFocus];
    }

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
  if (!controlView || !textObject || (_cell.type != NSTextCellType))
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
      if (_cell.contents_is_attributed_string == NO)
	{
	  [textObject setText: _contents];
	}
      else
	{
	  /* FIXME/TODO make sure this is correct. */
	  [textObject setText: [(NSAttributedString *)_contents string]];
	}
    }
  
  [textObject setDelegate: anObject];
  [[controlView window] makeFirstResponder: textObject];

  if ([theEvent type] == NSLeftMouseDown)
    {
      [textObject mouseDown: theEvent];
    }

  [textObject display];
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
  if (!controlView || !textObject || (_cell.type != NSTextCellType))
    return;

  [textObject setFrame: [self titleRectForBounds: aRect]];
  [controlView addSubview: textObject];
  if (_cell.contents_is_attributed_string == NO)
    {
      [textObject setText: _contents];
    }
  else
    {
      /* FIXME/TODO make sure this is correct. */
      [textObject setText: [(NSAttributedString *)_contents string]];
    }
  [textObject setSelectedRange: NSMakeRange (selStart, selLength)];
  [textObject setDelegate: anObject];
  [[controlView window] makeFirstResponder: textObject];
  [textObject display];
}

- (BOOL) sendsActionOnEndEditing 
{
  return _cell.sends_action_on_end_editing;
}

- (void) setSendsActionOnEndEditing: (BOOL)flag
{
  _cell.sends_action_on_end_editing = flag;
}

/*
 * Copying
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSCell *c = (NSCell*)NSCopyObject (self, 0, zone);

  /* Hmmm. */
  c->_contents = [_contents copyWithZone: zone];
  /* Because of performance issues (and because so the doc says) only
     pointers to the objects are copied.  We need to RETAIN them all
     though. */
  TEST_RETAIN (_font);
  TEST_RETAIN (_objectValue);
  TEST_RETAIN (_menu);
  TEST_RETAIN (_cell_image);
  TEST_RETAIN (_formatter);
  TEST_RETAIN (_represented_object);

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
  [aCoder encodeObject: _font];
  [aCoder encodeObject: _objectValue];
  flag = _cell.contents_is_attributed_string;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_highlighted;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_disabled;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_editable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.is_rich_text;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.imports_graphics;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.shows_first_responder;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.refuses_first_responder;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.sends_action_on_end_editing;
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
  flag = _cell.allows_mixed_state;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _cell.wraps;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  tmp_int = _cell.text_align;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.type;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.image_position;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.entry_type;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  tmp_int = _cell.state;
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_mnemonic_location];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_mouse_down_flags];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_action_mask];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_formatter];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_menu];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_represented_object];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL flag;
  unsigned int tmp_int;

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_contents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_font];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_objectValue];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.contents_is_attributed_string = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_highlighted = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_disabled = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_editable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.is_rich_text = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.imports_graphics = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.shows_first_responder = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.refuses_first_responder = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.sends_action_on_end_editing = flag;
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
  _cell.allows_mixed_state = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _cell.wraps = flag;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.text_align = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.type = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.image_position = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.entry_type = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &tmp_int];
  _cell.state = tmp_int;
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) 
	    at: &_mnemonic_location];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) 
	    at: &_mouse_down_flags];
  [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &_action_mask];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_formatter];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_menu];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_represented_object];

  if (_formatter != nil)
    {
      NSString *contents;

      contents = [_formatter stringForObjectValue: _objectValue];
      if (contents != nil)
	{
	  _cell.has_valid_object_value = YES;
	  ASSIGN (_contents, contents);
	  _cell.contents_is_attributed_string = NO;
	}
    }
  
  return self;
}
@end

@implementation NSCell (PrivateMethods)

- (NSColor*) textColor
{
  if (_cell.is_disabled)
    return dtxtCol;
  else
    return txtCol;    
}

/* This method is an exception and returns a non-autoreleased
   dictionary, so that calling methods can deallocate it immediately
   using release.  Otherwise if many cells are drawn/their size
   computed, we pile up hundreds or thousands of these objects before they 
   are deallocated at the end of the run loop. */
- (NSDictionary*) _nonAutoreleasedTypingAttributes
{
  NSDictionary *attr;
  NSColor *color;
  NSMutableParagraphStyle *paragraphStyle;

  color = [self textColor];
  /* Note: there are only 6 possible paragraph styles for cells.  
     TODO: Create them once at the beginning, and reuse them for the whole 
     app lifetime. */
  paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

  if (_cell.wraps)
    {
      [paragraphStyle setLineBreakMode: NSLineBreakByWordWrapping];
    }
  else
    {
      [paragraphStyle setLineBreakMode: NSLineBreakByClipping];
    }   

  [paragraphStyle setAlignment: _cell.text_align];

  attr = [[NSDictionary alloc] initWithObjectsAndKeys: 
			       _font, NSFontAttributeName,
			       color, NSForegroundColorAttributeName,
			       paragraphStyle, NSParagraphStyleAttributeName,
			       nil];
  RELEASE (paragraphStyle);
  return attr;
}

- (NSSize) _sizeText: (NSString*)title
{
  NSSize size;
  NSDictionary *dict;

  if (title == nil)
    {
      return NSMakeSize (0,0);
    }

  dict = [self _nonAutoreleasedTypingAttributes];
  size = [title sizeWithAttributes: dict];
  RELEASE (dict);
  return size;
}

- (void) _drawAttributedText: (NSAttributedString *)title 
		     inFrame: (NSRect)cellFrame
{
  NSSize titleSize;

  if (title == nil)
    return;

  titleSize = [title size];

  // Determine y position of text

  /* Important: text should always be vertically centered without
   * considering descender [as if descender did not exist].
   * This is particularly important for single line texts.
   * Please make sure the output remains always correct.
   */
  cellFrame.origin.y = NSMidY (cellFrame) - titleSize.height/2; 
  cellFrame.size.height = titleSize.height;

  [title drawInRect: cellFrame];
}

- (void) _drawText: (NSString*)title  inFrame: (NSRect)cellFrame
{
  NSSize titleSize;
  NSDictionary *attributes;

  if (title == nil)
    return;

  attributes = [self _nonAutoreleasedTypingAttributes];
  titleSize = [title sizeWithAttributes: attributes];

  // Determine y position of text

  /* Important: text should always be vertically centered without
   * considering descender [as if descender did not exist].
   * This is particularly important for single line texts.
   * Please make sure the output remains always correct.
   */
  cellFrame.origin.y = NSMidY (cellFrame) - titleSize.height/2; 
  cellFrame.size.height = titleSize.height;

  [title drawInRect: cellFrame  withAttributes: attributes];
  RELEASE (attributes);
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
