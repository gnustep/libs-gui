/*
   NSText.m

   The RTFD text class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2000
   Reorganised and cleaned up code, added some action methods

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
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

// toDo: - caret blinking

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSData.h>

#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSText.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>

#include <AppKit/NSDragging.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSLayoutManager.h>


#define HUGE 1e7


static NSNotificationCenter *nc;

static	Class	abstract;
static	Class	concrete;

@interface NSText(GNUstepPrivate)
/*
 * these NSLayoutManager- like methods are here only informally
 */
- (unsigned) characterIndexForPoint: (NSPoint)point;
- (NSRect) rectForCharacterIndex: (unsigned)index;
- (NSRect) rectForCharacterRange: (NSRange)aRange;

/*
 * various GNU extensions
 */
+ (NSDictionary*) defaultTypingAttributes;

//
// GNU utility methods
//
- (void) setAttributes: (NSDictionary*) attributes range: (NSRange) aRange;
- (void) _illegalMovement: (int) notNumber;
- (void) deleteRange: (NSRange)aRange backspace: (BOOL)flag;

- (void) drawInsertionPointAtIndex: (unsigned)index
			     color: (NSColor*)color
			  turnedOn: (BOOL)flag;
@end

// not the same as NSMakeRange!
static inline
NSRange MakeRangeFromAbs (unsigned a1, unsigned a2)
{
  if (a1 < a2)
    return NSMakeRange(a1, a2 - a1);
  else
    return NSMakeRange(a2, a1 - a2);
}

@implementation NSText

//
// Class methods
//
+ (void)initialize
{
  if (self  == [NSText class])
    {
      NSArray  *types;

      // Initial version
      [self setVersion: 1];

      nc = [NSNotificationCenter defaultCenter];

      types  = [NSArray arrayWithObjects: NSStringPboardType, 
			NSRTFPboardType, NSRTFDPboardType, nil];

      [[NSApplication sharedApplication] registerServicesMenuSendTypes: types
					 returnTypes: types];

      abstract = self;
      concrete = [NSTextView class];
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  if (self == abstract)
    return NSAllocateObject (concrete, 0, zone);
  else
    return NSAllocateObject (self, 0, zone);
}

//
// Instance methods
//
//
// Initialization
//

- (id) init
{
  return [self initWithFrame: NSMakeRect (0, 0, 100, 100)];
}

- (void)dealloc
{
  RELEASE(_background_color);
  RELEASE(_caret_color);
  RELEASE(_typingAttributes);

  [super dealloc];
}

/*
 * Getting and Setting Contents
 */
- (void) replaceCharactersInRange: (NSRange)aRange  withRTF: (NSData *)rtfData
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] initWithRTF: rtfData 
				     documentAttributes: NULL];
  AUTORELEASE (attr);
  [self replaceRange: aRange  withAttributedString: attr];
}

- (void) replaceCharactersInRange: (NSRange)aRange  
			 withRTFD: (NSData *)rtfdData
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] initWithRTFD: rtfdData 
				     documentAttributes: NULL];
  AUTORELEASE (attr);
  [self replaceRange: aRange  withAttributedString: attr];
}

- (void) replaceCharactersInRange: (NSRange)aRange
		       withString: (NSString*)aString
{
  [self subclassResponsibility: _cmd];
}

- (void) setString: (NSString*)aString
{
  [self replaceCharactersInRange: NSMakeRange (0, [[self string] length])
	withString: aString];
}

- (NSString*) string
{
  // FIXME: This should remove all the attachement characters.
  return [_textStorage string];
}

// old methods
- (void) replaceRange: (NSRange)aRange withRTFD: (NSData*)rtfdData
{
  [self replaceCharactersInRange: aRange withRTFD: rtfdData];
}

- (void) replaceRange: (NSRange)aRange withRTF: (NSData*)rtfData
{
  [self replaceCharactersInRange: aRange withRTF: rtfData];
}

- (void) replaceRange: (NSRange)aRange withString: (NSString*)aString
{
  [self replaceCharactersInRange: aRange withString: aString];
}

- (void) setText: (NSString*)aString range: (NSRange)aRange
{
  [self replaceCharactersInRange: aRange withString: aString];
}

- (void) setText: (NSString*)string
{
  [self setString: string];
}

- (NSString*) text
{
  return [self string];
}

//
// Graphic attributes
//
- (NSColor*) backgroundColor
{
  return _background_color;
}

- (BOOL) drawsBackground
{
  return _tf.draws_background;
}

- (void) setBackgroundColor: (NSColor*)color
{
  ASSIGN (_background_color, color);
}

- (void) setDrawsBackground: (BOOL)flag
{
  _tf.draws_background = flag;
}

//
// Managing Global Characteristics
//
- (BOOL) importsGraphics
{
  return _tf.imports_graphics;
}

- (BOOL) isEditable
{
  return _tf.is_editable;
}

- (BOOL) isFieldEditor
{
  return _tf.is_field_editor;
}

- (BOOL) isRichText
{
  return _tf.is_rich_text;
}

- (BOOL) isSelectable
{
  return _tf.is_selectable;
}

- (void) setEditable: (BOOL)flag
{
  _tf.is_editable = flag;

  if (flag)
    {
      _tf.is_selectable = YES;
    }
}

- (void) setFieldEditor: (BOOL)flag
{
  _tf.is_field_editor = flag;
}

- (void) setImportsGraphics: (BOOL)flag
{
  _tf.imports_graphics = flag;

  if (flag == YES)
    {
      _tf.is_rich_text = YES;
    }
}

- (void) setRichText: (BOOL)flag
{
  _tf.is_rich_text  = flag;

  if (flag == NO)
    {
      _tf.imports_graphics = NO;
    }
}

- (void)setSelectable: (BOOL)flag
{
  _tf.is_selectable = flag;

  if (flag == NO)
    {
      _tf.is_editable = NO;
    }
}

//
// Using the font panel
//
- (BOOL) usesFontPanel
{
  return _tf.uses_font_panel;
}

- (void) setUsesFontPanel: (BOOL)flag
{
  _tf.uses_font_panel = flag;
}

//
// Managing the Ruler
//
- (BOOL) isRulerVisible
{
  return _tf.is_ruler_visible;
}

- (void) toggleRuler: (id)sender
{
  [self setRulerVisible: !_tf.is_ruler_visible];
}

//
// Managing the Selection
//
- (NSRange) selectedRange
{
  return _selected_range;
}

- (void) setSelectedRange: (NSRange)range
{
  NSRange oldRange = _selected_range;
  NSRange overlap;

  // Nothing to do, if the range is still the same
  if (NSEqualRanges(range, oldRange))
    return;

  //<!> ask delegate for selection validation

  _selected_range  = range;
  [self updateFontPanel];

#if 0
  [nc postNotificationName: NSTextViewDidChangeSelectionNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				NSStringFromRange (_selected_range),
			      NSOldSelectedCharacterRange, nil]];
#endif

  // display
  if (range.length)
    {
      // <!>disable caret timed entry
    }
  else	// no selection
    {
      if (_tf.is_rich_text)
	{
	  [self setTypingAttributes: [_textStorage attributesAtIndex: range.location
						   effectiveRange: NULL]];
	}
      // <!>enable caret timed entry
    }

  if (!_window)
    return;

  // Make the selected range visible
  [self scrollRangeToVisible: _selected_range]; 

  // Redisplay what has changed
  // This does an unhighlight of the old selected region
  overlap = NSIntersectionRange(oldRange, _selected_range);
  if (overlap.length)
    {
      // Try to optimize for overlapping ranges
      if (range.location != oldRange.location)
	  [self setNeedsDisplayInRect: 
		    [self rectForCharacterRange: 
			      MakeRangeFromAbs(MIN(range.location,
						   oldRange.location),
					       MAX(range.location,
						   oldRange.location))]];
      if (NSMaxRange(range) != NSMaxRange(oldRange))
	  [self setNeedsDisplayInRect: 
		    [self rectForCharacterRange: 
			      MakeRangeFromAbs(MIN(NSMaxRange(range),
						   NSMaxRange(oldRange)),
					       MAX(NSMaxRange(range),
						   NSMaxRange (oldRange)))]];
    }
  else
    {
      [self setNeedsDisplayInRect: [self rectForCharacterRange: range]];
      [self setNeedsDisplayInRect: [self rectForCharacterRange: oldRange]];
    }
}

/*
 * Copy and paste
 */
- (void) copy: (id)sender
{
  NSMutableArray *types = [NSMutableArray array];

  if (_tf.imports_graphics)
    [types addObject: NSRTFDPboardType];
  if (_tf.is_rich_text)
    [types addObject: NSRTFPboardType];

  [types addObject: NSStringPboardType];

  [self writeSelectionToPasteboard: [NSPasteboard generalPasteboard]
	types: types];
}

// Copy the current font to the font pasteboard
- (void) copyFont: (id)sender
{
  [self writeSelectionToPasteboard: [NSPasteboard pasteboardWithName: NSFontPboard]
	type: NSFontPboardType];
}

// Copy the current ruler settings to the ruler pasteboard
- (void) copyRuler: (id)sender
{
  [self writeSelectionToPasteboard: [NSPasteboard pasteboardWithName: NSRulerPboard]
	type: NSRulerPboardType];
}

- (void) delete: (id)sender
{
  [self deleteRange: _selected_range backspace: NO];
}

- (void) cut: (id)sender
{
  if (_selected_range.length)
    {
      [self copy: sender];
      [self delete: sender];
    }
}

- (void) paste: (id)sender
{
  [self readSelectionFromPasteboard: [NSPasteboard generalPasteboard]];
}

- (void) pasteFont: (id)sender
{
  [self readSelectionFromPasteboard:
	    [NSPasteboard pasteboardWithName: NSFontPboard]
	type: NSFontPboardType];
}

- (void) pasteRuler: (id)sender
{
  [self readSelectionFromPasteboard:
	    [NSPasteboard pasteboardWithName: NSRulerPboard]
	type: NSRulerPboardType];
}

- (void) selectAll: (id)sender
{
  [self setSelectedRange: NSMakeRange(0, [self textLength])];
}

/*
 * Managing Font
 */
- (NSFont*) font
{
  if ([_textStorage length])
    {
      NSFont *font = [_textStorage attribute: NSFontAttributeName
				   atIndex: 0
				   effectiveRange: NULL];
      if (font != nil)
	return font;
    }

  return [_typingAttributes objectForKey: NSFontAttributeName];
}

/*
 * This action method changes the font of the selection for a rich text object,
 * or of all text for a plain text object. If the receiver doesn't use the Font
 * Panel, however, this method does nothing.
 */
- (void) changeFont: (id)sender
{
  NSRange foundRange;
  int maxSelRange;
  NSRange aRange= [self rangeForUserCharacterAttributeChange];
  NSRange searchRange = aRange;
  NSFont *font;

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  for (maxSelRange = NSMaxRange(aRange);
       searchRange.location < maxSelRange;
       searchRange = NSMakeRange (NSMaxRange (foundRange),
				  maxSelRange - NSMaxRange(foundRange)))
    {
      font = [_textStorage attribute: NSFontAttributeName
			   atIndex: searchRange.location
			   longestEffectiveRange: &foundRange
			   inRange: searchRange];
      if (font != nil)
      {
	  [self setFont: [sender convertFont: font]
		ofRange: foundRange];
      }
    }
  [_textStorage endEditing];
  [self didChangeText];
  // Set typing attributes
  font = [_typingAttributes objectForKey: NSFontAttributeName];
  if (font != nil)
    {
      [_typingAttributes setObject: [sender convertFont: font] 
			 forKey: NSFontAttributeName];
    }
}

- (void) setFont: (NSFont*)font
{
  NSRange fullRange = NSMakeRange(0, [_textStorage length]);

  if (font == nil)
    return;

  [self setFont: font ofRange: fullRange];
  [_typingAttributes setObject: font forKey: NSFontAttributeName];
}

- (void) setFont: (NSFont*)font
	 ofRange: (NSRange)aRange
{
  if (font != nil)
    {
      if (![self shouldChangeTextInRange: aRange
		 replacementString: nil])
	return;
      [_textStorage beginEditing];
      [_textStorage addAttribute: NSFontAttributeName
		    value: font
		    range: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }
}

/*
 * Managing Alingment
 */
- (NSTextAlignment) alignment
{
  NSRange aRange = [self rangeForUserParagraphAttributeChange];
  NSParagraphStyle *aStyle;

  if (aRange.location != NSNotFound)
    {
      aStyle = [_textStorage attribute: NSParagraphStyleAttributeName
			     atIndex: aRange.location
			     effectiveRange: NULL];
      if (aStyle != nil)
	return [aStyle alignment]; 
    }

  // Get alignment from typing attributes
  return [[[self typingAttributes] 
	      objectForKey: NSParagraphStyleAttributeName] alignment];
}

- (void) setAlignment: (NSTextAlignment) mode
{
  [self setAlignment: mode
	range: NSMakeRange(0, [_textStorage length])];
}

- (void) alignCenter: (id) sender
{
  [self setAlignment: NSCenterTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

- (void) alignLeft: (id) sender
{
  [self setAlignment: NSLeftTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

- (void) alignRight: (id) sender
{
  [self setAlignment: NSRightTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

/*
 * Text colour
 */

- (NSColor*) textColor
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location != NSNotFound)
    return [_textStorage attribute: NSForegroundColorAttributeName
			 atIndex: aRange.location
			 effectiveRange: NULL];
  else 
    return [_typingAttributes objectForKey: NSForegroundColorAttributeName];
}

- (void) setTextColor: (NSColor*) color
		range: (NSRange) aRange
{
  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  if (color != nil)
    {
      [_textStorage addAttribute: NSForegroundColorAttributeName
		    value: color
		    range: aRange];
      [_typingAttributes setObject: color forKey: NSForegroundColorAttributeName];
    }
  else
    {
      [_textStorage removeAttribute: NSForegroundColorAttributeName
		    range: aRange];
    }
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) setColor: (NSColor*) color
	  ofRange: (NSRange) aRange
{
  [self setTextColor: color range: aRange];
}

- (void) setTextColor: (NSColor*) color
{
  NSRange fullRange = NSMakeRange(0, [_textStorage length]);

  [self setTextColor: color range: fullRange];
}

//
// Text attributes
//
- (void) subscript: (id)sender
{
  NSNumber *value = [_typingAttributes 
		       objectForKey: NSSuperscriptAttributeName];
  int sValue;
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (aRange.length)
    {
      if (![self shouldChangeTextInRange: aRange
		 replacementString: nil])
	return;
      [_textStorage beginEditing];
      [_textStorage subscriptRange: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }

  // Set the typing attributes
  if (value != nil)
    sValue = [value intValue] - 1;
  else
    sValue = -1;
  [_typingAttributes setObject: [NSNumber numberWithInt: sValue]
		     forKey: NSSuperscriptAttributeName];
}

- (void) superscript: (id)sender
{
  NSNumber *value = [_typingAttributes 
		       objectForKey: NSSuperscriptAttributeName];
  int sValue;
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (aRange.length)
    {
      if (![self shouldChangeTextInRange: aRange
		 replacementString: nil])
	return;
      [_textStorage beginEditing];
      [_textStorage superscriptRange: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }

  // Set the typing attributes
  if (value != nil)
    sValue = [value intValue] + 1;
  else
    sValue = 1;
  [_typingAttributes setObject: [NSNumber numberWithInt: sValue]
		     forKey: NSSuperscriptAttributeName];
}

- (void) unscript: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (aRange.length)
    {
      if (![self shouldChangeTextInRange: aRange
		 replacementString: nil])
	return;
      [_textStorage beginEditing];
      [_textStorage unscriptRange: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }

  // Set the typing attributes
  [_typingAttributes removeObjectForKey: NSSuperscriptAttributeName];
}

- (void) underline: (id)sender
{
  BOOL doUnderline = YES;
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if ([[_textStorage attribute: NSUnderlineStyleAttributeName
		     atIndex: aRange.location
		     effectiveRange: NULL] intValue])
    doUnderline = NO;

  if (aRange.length)
    {
      if (![self shouldChangeTextInRange: aRange
		 replacementString: nil])
	return;
      [_textStorage beginEditing];
      [_textStorage addAttribute: NSUnderlineStyleAttributeName
		    value: [NSNumber numberWithInt: doUnderline]
		    range: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }

  [_typingAttributes
      setObject: [NSNumber numberWithInt: doUnderline]
      forKey: NSUnderlineStyleAttributeName];
}

//
// Reading and Writing RTFD Files
//
- (BOOL) readRTFDFromFile: (NSString*)path
{
  NSAttributedString *peek = [[NSAttributedString alloc] 
				 initWithPath: path
				 documentAttributes: NULL];

  if (peek != nil)
    {
      if (!_tf.is_rich_text)
	{
	  [self setRichText: YES];
	}
      [self replaceRange: NSMakeRange (0, [self textLength])
	    withAttributedString: peek];
      RELEASE(peek);
      return YES;
    }
  return NO;
}

- (BOOL) writeRTFDToFile: (NSString*)path atomically: (BOOL)flag
{
  NSFileWrapper *wrapper = [_textStorage RTFDFileWrapperFromRange:
					   NSMakeRange(0, [_textStorage length])
					 documentAttributes: nil];
  return [wrapper writeToFile: path atomically: flag updateFilenames: YES];
}

- (NSData*) RTFDFromRange: (NSRange) aRange
{
  return [_textStorage RTFDFromRange: aRange
		       documentAttributes: nil];
}

- (NSData*) RTFFromRange: (NSRange) aRange
{
  return [_textStorage RTFFromRange: aRange
		       documentAttributes: nil];
}

//
// Sizing the Frame Rectangle
//
- (BOOL) isHorizontallyResizable
{
  return _tf.is_horizontally_resizable;
}

- (BOOL) isVerticallyResizable
{
  return _tf.is_vertically_resizable;
}

- (NSSize) maxSize
{
  return _maxSize;
}

- (NSSize) minSize
{
  return _minSize;
}

- (void)setHorizontallyResizable: (BOOL)flag
{
  // FIXME:  All the container resizing is here preliminary until we get 
  // clipview resizing working without it
  NSSize containerSize = [_textContainer containerSize];

  if (flag)
    containerSize.width = HUGE;
  else
    containerSize.width = _frame.size.width - 2.0 * [self textContainerInset].width;

  [_textContainer setContainerSize: containerSize];
  [_textContainer setWidthTracksTextView: !flag];
  _tf.is_horizontally_resizable = flag;
}

- (void) setVerticallyResizable: (BOOL)flag
{
  // FIXME:  All the container resizing is here preliminary until we get 
  // clipview resizing working without it
  NSSize containerSize = [_textContainer containerSize];

  if (flag)
    containerSize.height = HUGE;
  else
    containerSize.height = _frame.size.height - 2.0 * [self textContainerInset].height;

  [_textContainer setContainerSize: containerSize];
  [_textContainer setHeightTracksTextView: !flag];
  _tf.is_vertically_resizable = flag;
}

- (void)setMaxSize: (NSSize)newMaxSize
{
  _maxSize = newMaxSize;
}

- (void)setMinSize: (NSSize)newMinSize
{
  _minSize = newMinSize;
}

- (void) sizeToFit
{
  // if we are a field editor we don't have to handle the size.
  if ([self isFieldEditor])
    return;
  else
    {
      NSSize oldSize = _frame.size;
      float newWidth = oldSize.width;
      float newHeight = oldSize.height;
      NSRect textRect = [_layoutManager usedRectForTextContainer: [self textContainer]];
      NSSize newSize;

      if (_tf.is_horizontally_resizable)
	{
	  newWidth = textRect.size.width;
	}
      if (_tf.is_vertically_resizable)
	{
	  newHeight = textRect.size.height;
	}

      newSize = NSMakeSize(MIN(_maxSize.width, MAX(newWidth, _minSize.width)),
			   MIN(_maxSize.height, MAX(newHeight, _minSize.height)));
      if (!NSEqualSizes(oldSize, newSize))
	{
	  [self setFrameSize: newSize];
	}
    }
}

//
// Spelling
//

- (void) checkSpelling: (id)sender
{
  NSRange errorRange
    = [[NSSpellChecker sharedSpellChecker]
	checkSpellingOfString: [self string]
	startingAt: NSMaxRange (_selected_range)];

  if (errorRange.length)
    [self setSelectedRange: errorRange];
  else
    NSBeep();
}

- (void) showGuessPanel: (id)sender
{
  [[[NSSpellChecker sharedSpellChecker] spellingPanel] orderFront: self];
}

//
// Scrolling
//

- (void) scrollRangeToVisible: (NSRange) aRange
{
  // Don't try scrolling an ancestor clipview if we are field editor.
  // This makes things so much simpler and stabler for now.
  if (_tf.is_field_editor == NO)
    {
      [self scrollRectToVisible: [self rectForCharacterRange: 
					   _selected_range]];
    }
}


/*
 * Managing the Delegate
 */
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id) anObject
{
  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  ASSIGN(_delegate, anObject);

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(text##notif_name:)]) \
    [nc addObserver: _delegate \
          selector: @selector(text##notif_name:) \
              name: NSText##notif_name##Notification \
            object: self]

  SET_DELEGATE_NOTIFICATION(DidBeginEditing);
  SET_DELEGATE_NOTIFICATION(DidChange);
  SET_DELEGATE_NOTIFICATION(DidEndEditing);
}

//
// Handling Events
//
- (void) mouseDown: (NSEvent*)theEvent
{
  NSSelectionGranularity granularity = NSSelectByCharacter;
  NSRange chosenRange, proposedRange;
  NSPoint point, startPoint;
  NSEvent *currentEvent;
  unsigned startIndex;

  // If not selectable than don't recognize the mouse down
  if (!_tf.is_selectable)
    return;

  // Only try to make first responder if editable, otherwise the 
  // delegate will stop it in becomeFirstResponder.
  if (_tf.is_editable && ![_window makeFirstResponder: self])
    return;

  switch ([theEvent clickCount])
    {
    case 1: granularity = NSSelectByCharacter;
      break;
    case 2: granularity = NSSelectByWord;
      break;
    case 3: granularity = NSSelectByParagraph;
      break;
    }

  startPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  startIndex = [self characterIndexForPoint: startPoint];

  proposedRange = NSMakeRange(startIndex, 0);
  chosenRange = [self selectionRangeForProposedRange: proposedRange
		      granularity: granularity];

  [self setSelectedRange: chosenRange];
  // Do an imidiate redisplay for visual feedback
  [_window flushWindow];

  //<!> make this non - blocking (or make use of timed entries)
  // run modal loop
  for (currentEvent = [_window
			nextEventMatchingMask:
			  (NSLeftMouseDraggedMask|NSLeftMouseUpMask)];
       [currentEvent type] != NSLeftMouseUp;
       (currentEvent = [_window
			 nextEventMatchingMask:
			   (NSLeftMouseDraggedMask|NSLeftMouseUpMask)]))
    {
      BOOL didScroll = [self autoscroll: currentEvent];
      point = [self convertPoint: [currentEvent locationInWindow]
		    fromView: nil];
      proposedRange = MakeRangeFromAbs ([self characterIndexForPoint: point],
					startIndex);
      // Add one more character as selected, as zero length is cursor.
      proposedRange.length++;
 
      chosenRange = [self selectionRangeForProposedRange: proposedRange
			  granularity: granularity];

      [self setSelectedRange: chosenRange];

      if (didScroll)
	[self setNeedsDisplay: YES];
      // Do an imidiate redisplay for visual feedback
      [_window flushWindow];
    }

  NSDebugLog(@"chosenRange. location  = %d, length  = %d\n",
	     (int)chosenRange.location, (int)chosenRange.length);
  // remember for column stable cursor up/down
  _currentCursor = [self rectForCharacterIndex: chosenRange.location].origin;
}

- (void) keyDown: (NSEvent*)theEvent
{
  // If not editable, don't recognize the key down
  if (!_tf.is_editable)
    {
      [super keyDown: theEvent];
    }
  else
    {
      [self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
    }
}

- (void) insertNewline: (id) sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSReturnTextMovement];
      return;
    }

  [self insertText: [[self class] newlineString]];
}

- (void) insertTab: (id) sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSTabTextMovement];
      return;
    }

  [self insertText: @"\t"];
}

- (void) insertBacktab: (id) sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSBacktabTextMovement];
      return;
    }

  //[self insertText: @"\t"];
}

- (void) deleteForward: (id) sender
{
  if (_selected_range.location != [self textLength])
    {
      /* Not at the end of text -- delete following character */
      [self deleteRange:
	      [self selectionRangeForProposedRange:
		      NSMakeRange (_selected_range.location, 1)
		    granularity: NSSelectByCharacter]
	    backspace: NO];
    }
  else
    {
      /* end of text: behave the same way as NSBackspaceKey */
      [self deleteBackward: sender];
    }
}

- (void) deleteBackward: (id) sender
{
  [self deleteRange: _selected_range backspace: YES];
}

//<!> choose granularity according to keyboard modifier flags
- (void) moveUp: (id) sender
{
  unsigned cursorIndex;
  NSPoint cursorPoint;
  NSRange newRange;

  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSUpTextMovement];
      return;
    }

  /* Do nothing if we are at beginning of text */
  if (_selected_range.location == 0)
    return;

  if (_selected_range.length)
    {
      _currentCursor = [self rectForCharacterIndex:
			       _selected_range.location].origin;
    }
  cursorIndex = _selected_range.location;
  cursorPoint = [self rectForCharacterIndex: cursorIndex].origin;
  cursorIndex = [self characterIndexForPoint:
			NSMakePoint (_currentCursor.x + 0.001,
				     MAX (0, cursorPoint.y - 0.001))];

  newRange.location = cursorIndex;
  newRange.length = 0;
  [self setSelectedRange: newRange];
}

- (void) moveDown: (id) sender
{
  unsigned cursorIndex;
  NSRect cursorRect;
  NSRange newRange;

  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSDownTextMovement];
      return;
    }

  /* Do nothing if we are at end of text */
  if (_selected_range.location == [self textLength])
    return;

  if (_selected_range.length != 0)
    {
      _currentCursor = [self rectForCharacterIndex:
			       NSMaxRange (_selected_range)].origin;
    }
  cursorIndex = _selected_range.location;
  cursorRect = [self rectForCharacterIndex: cursorIndex];
  cursorIndex = [self characterIndexForPoint:
			  NSMakePoint(_currentCursor.x + 0.001,
				      NSMaxY (cursorRect) + 0.001)];

  newRange.location = cursorIndex;
  newRange.length = 0;
  [self setSelectedRange: newRange];
}

- (void) moveLeft: (id) sender
{
  NSRange newSelectedRange;

  /* Do nothing if we are at beginning of text with no selection */
  if (_selected_range.location == 0 && _selected_range.length == 0)
    { 
      if (_tf.is_field_editor)
        {
	  [self _illegalMovement: NSLeftTextMovement];
	}
      return;
    }

  if (_selected_range.location == 0)
    newSelectedRange.location = 0;
  else
    newSelectedRange.location = _selected_range.location - 1;
  newSelectedRange.length = 0;

  [self setSelectedRange: newSelectedRange];

  _currentCursor.x = [self rectForCharacterIndex:
			   _selected_range.location].origin.x;
}

- (void) moveRight: (id) sender
{
  NSRange newSelectedRange;
  unsigned int length = [self textLength];

  /* Do nothing if we are at end of text */
  if (_selected_range.location == length)
    { 
      if (_tf.is_field_editor)
        {
	  [self _illegalMovement: NSRightTextMovement];
	}
      return;
    }

  newSelectedRange.location = MIN(NSMaxRange(_selected_range) + 1, length);
  newSelectedRange.length = 0;

  [self setSelectedRange: newSelectedRange];

  _currentCursor.x = [self rectForCharacterIndex:
			   _selected_range.location].origin.x;
}

- (BOOL) acceptsFirstResponder
{
  if ([self isSelectable])
    return YES;
  else
    return NO;
}

- (BOOL) resignFirstResponder
{
  if (([self isEditable])
      && ([_delegate respondsToSelector: @selector(textShouldEndEditing:)])
      && ([_delegate textShouldEndEditing: self] == NO))
    return NO;

  // Add any clean-up stuff here

  if ([self shouldDrawInsertionPoint])
    {
      [self lockFocus];
      [self drawInsertionPointAtIndex: _selected_range.location
	    color: nil turnedOn: NO];
      [self unlockFocus];
      //<!> stop timed entry
    }

  [nc postNotificationName: NSTextDidEndEditingNotification  object: self];
  return YES;
}

- (BOOL) becomeFirstResponder
{
  if ([self isSelectable] == NO)
    return NO;

  if (([_delegate respondsToSelector: @selector(textShouldBeginEditing:)])
      && ([_delegate textShouldBeginEditing: self] == NO))
    return NO;

  // Add any initialization stuff here.

  //if ([self shouldDrawInsertionPoint])
  //  {
  //   [self lockFocus];
  //   [self drawInsertionPointAtIndex: _selected_range.location
  //      color: _caret_color turnedOn: YES];
  //   [self unlockFocus];
  //   //<!> restart timed entry
  //  }
  [nc postNotificationName: NSTextDidBeginEditingNotification  object: self];
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  NSRange drawnRange = [_layoutManager glyphRangeForBoundingRect: rect 
				       inTextContainer: [self textContainer]];
  if (_tf.draws_background)
    {
      [_layoutManager drawBackgroundForGlyphRange: drawnRange 
		      atPoint: [self textContainerOrigin]];
    }

  [_layoutManager drawGlyphsForGlyphRange: drawnRange 
		  atPoint: [self textContainerOrigin]];

  if ([self shouldDrawInsertionPoint] && 
      (NSLocationInRange(_selected_range.location, drawnRange) ||
       _selected_range.location == NSMaxRange(drawnRange)))
    {
      [self drawInsertionPointAtIndex: _selected_range.location
	    color: _caret_color
	    turnedOn: YES];
    }
}

// text lays out from top to bottom
- (BOOL) isFlipped
{
  return YES;
}

- (BOOL) isOpaque
{
  if (_tf.draws_background == NO
      || _background_color == nil
      || [_background_color alphaComponent] < 1.0)
    return NO;
  else
    return YES;
}


/*
 *     Handle enabling/disabling of services menu items.
 */
- (id) validRequestorForSendType: (NSString*) sendType
		      returnType: (NSString*) returnType
{
  if ((!sendType || (_selected_range.length && 
		     [sendType isEqual: NSStringPboardType]))
      && (!returnType || ([self isEditable] && 
			  [returnType isEqual: NSStringPboardType])))
    {
      return self;
    }

  return [super validRequestorForSendType: sendType
		returnType: returnType];

}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  BOOL flag;
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _delegate];

  flag = _tf.is_field_editor;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_editable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_selectable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_rich_text;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.imports_graphics;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.draws_background;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_horizontally_resizable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_vertically_resizable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.uses_font_panel;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.uses_ruler;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_ruler_visible;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];

  [aCoder encodeObject: _typingAttributes];
  [aCoder encodeObject: _background_color];
  [aCoder encodeValueOfObjCType: @encode(NSRange) at: &_selected_range];
  [aCoder encodeObject: _caret_color];
  [aCoder encodeValueOfObjCType: @encode(NSSize) at: &_minSize];
  [aCoder encodeValueOfObjCType: @encode(NSSize) at: &_maxSize];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  BOOL flag;

  [super initWithCoder: aDecoder];

  _delegate  = [aDecoder decodeObject];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_field_editor = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_editable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_selectable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_rich_text = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.imports_graphics = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.draws_background = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_horizontally_resizable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_vertically_resizable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.uses_font_panel = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.uses_ruler = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_ruler_visible = flag;

  _typingAttributes  = [aDecoder decodeObject];
  _background_color  = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(NSRange) at: &_selected_range];
  _caret_color  = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(NSSize) at: &_minSize];
  [aDecoder decodeValueOfObjCType: @encode(NSSize) at: &_maxSize];

  return self;
}

//
// NSChangeSpelling protocol
//

- (void) changeSpelling: (id)sender
{
  [self insertText: [[(NSControl*)sender selectedCell] stringValue]];
}

//
// NSIgnoreMisspelledWords protocol
//
- (void) ignoreSpelling: (id)sender
{
  NSSpellChecker *sp = [NSSpellChecker sharedSpellChecker];

  [sp ignoreWord: [[(NSControl*)sender selectedCell] stringValue]
      inSpellDocumentWithTag: [self spellCheckerDocumentTag]];
}
@end

@implementation NSText(GNUstepExtension)

+ (NSString*) newlineString
{
  return @"\n";
}

- (void) replaceRange: (NSRange) aRange
 withAttributedString: (NSAttributedString*) attrString
{
  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	     replacementString: [attrString string]])
    return;

  [_textStorage beginEditing];
  if (_tf.is_rich_text)
    [_textStorage replaceCharactersInRange: aRange
		  withAttributedString: attrString];
  else
    [_textStorage replaceCharactersInRange: aRange
		  withString: [attrString string]];
  [_textStorage endEditing];
  [self didChangeText];
}

- (unsigned) textLength
{
  return [_textStorage length];
}

- (void) sizeToFit: (id)sender
{
  [self sizeToFit];
}

@end

@implementation NSText(NSTextView)

- (void) setRulerVisible: (BOOL)flag
{
  NSScrollView *sv = [self enclosingScrollView];

  _tf.is_ruler_visible = flag;
  if (sv != nil)
    [sv setRulersVisible: _tf.is_ruler_visible];
}

- (int) spellCheckerDocumentTag
{
  if (!_spellCheckerDocumentTag)
    _spellCheckerDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];

  return _spellCheckerDocumentTag;
}

- (BOOL) shouldChangeTextInRange: (NSRange)affectedCharRange
	       replacementString: (NSString*)replacementString
{
  return YES;
}

- (void) didChangeText
{
  [nc postNotificationName: NSTextDidChangeNotification  object: self];
}

// central text inserting method
- (void) insertText: (NSString*) insertString
{
  NSRange insertRange = [self rangeForUserTextChange];

  if (insertRange.location == NSNotFound)
    return;

  if (_tf.is_rich_text)
    {
      [self replaceRange: insertRange
	    withAttributedString: AUTORELEASE([[NSAttributedString alloc]
				     initWithString: insertString
				     attributes: [self typingAttributes]])];
    }
  else
    {
      [self replaceCharactersInRange: insertRange
	    withString: insertString];
    }

  // move cursor <!> [self selectionRangeForProposedRange: ]
  [self setSelectedRange:
	  NSMakeRange (insertRange.location + [insertString length], 0)];

  // remember x for row - stable cursor movements
  _currentCursor = [self rectForCharacterIndex:
			   _selected_range.location].origin;
}

- (void) setTypingAttributes: (NSDictionary*) dict
{
  if (dict == nil)
    dict = [isa defaultTypingAttributes];

  if (![dict isKindOfClass: [NSMutableDictionary class]])
    {
      RELEASE(_typingAttributes);
      _typingAttributes = [[NSMutableDictionary alloc] initWithDictionary: dict];
    }
  else
    ASSIGN(_typingAttributes, (NSMutableDictionary*)dict);
}

- (NSDictionary*) typingAttributes
{
  return [NSDictionary dictionaryWithDictionary: _typingAttributes];
}

- (void) updateFontPanel
{
  // update fontPanel only if told so
  if (_tf.uses_font_panel)
    {
      NSRange longestRange;
      NSFont *currentFont = [_textStorage attribute: NSFontAttributeName
				  atIndex: _selected_range.location
				  longestEffectiveRange: &longestRange
				  inRange: _selected_range];

      [[NSFontManager sharedFontManager] 
	  setSelectedFont: currentFont
	  isMultiple: !NSEqualRanges(longestRange, _selected_range)];
    }
}

- (BOOL) shouldDrawInsertionPoint
{
  return (_selected_range.length == 0) && [self isEditable];
}

- (void) drawInsertionPointInRect: (NSRect)rect
			    color: (NSColor*)color
			 turnedOn: (BOOL)flag
{
  if (!_window)
    return;

  if (flag)
    {
      if (color == nil)
	color = _caret_color;

      [color set];
      NSRectFill(rect);
    }
  else
    {
      [[self backgroundColor] set];
      NSRectFill(rect);
      // FIXME: We should redisplay the character the cursor was on.
      //[self setNeedsDisplayInRect: rect];
    }

  [_window flushWindow];
}

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedCharRange
			       granularity: (NSSelectionGranularity)granularity
{
  unsigned index;
  NSRange aRange;
  NSRange newRange;
  NSString *string = [self string];
  unsigned length = [string length];

  if (proposedCharRange.location >= length)
    {
      proposedCharRange.location = length;
      proposedCharRange.length = 0;
      return proposedCharRange;
    }

  if (NSMaxRange(proposedCharRange) > length)
    {
      proposedCharRange.length = length - proposedCharRange.location;
    }

  if (length == 0)
    {
      return proposedCharRange;
    }

  switch (granularity)
    {
    case NSSelectByWord:
      /* FIXME: The following code (or the routines it calls) does the
	 wrong thing when you double-click on the space between two
	 words */
      if ((proposedCharRange.location + 1) < length)
	{
	  index = [_textStorage nextWordFromIndex: 
				  (proposedCharRange.location + 1)
				forward: NO];
	}
      else
	{
	  /* Exception: end of text */
	  index = [_textStorage nextWordFromIndex: proposedCharRange.location
				forward: NO];
	}
      newRange.location = index;
      index = [_textStorage nextWordFromIndex: NSMaxRange (proposedCharRange)
                                      forward: YES];
      if (index <= newRange.location)
	{
	  newRange.length = 0;
	}
      else
	{
	  if (index == length)
	    {
	      /* We are at the end of text ! */
	      newRange.length = index - newRange.location;
	    }
	  else 
	    {
	      /* FIXME: The following will not work if there is more than a 
		 single character between the two words ! */
	      newRange.length = index - 1 - newRange.location;
	    }
	}
      return newRange;

    case NSSelectByParagraph:
      return [string lineRangeForRange: proposedCharRange];

    case NSSelectByCharacter:
    default:
      if (proposedCharRange.length == 0)
	return proposedCharRange;

      /* Expand the beginning character */
      index = proposedCharRange.location;
      newRange = [string rangeOfComposedCharacterSequenceAtIndex: index];
      /* If the proposedCharRange is empty we only ajust the beginning */
      if (proposedCharRange.length == 0)
	{
	  return newRange;
	}
      /* Expand the finishing character */
      index = NSMaxRange (proposedCharRange) - 1;
      aRange = [string rangeOfComposedCharacterSequenceAtIndex: index];
      newRange.length = NSMaxRange(aRange) - newRange.location;
      return newRange;
    }
}

- (NSRange) rangeForUserCharacterAttributeChange
{
  if (!_tf.is_editable || !_tf.uses_font_panel)
    return NSMakeRange(NSNotFound, 0);

  if (_tf.is_rich_text)
    // This expects the selection to be already corrected to characters
    return _selected_range;
  else
    return NSMakeRange(0, [_textStorage length]);
}

- (NSRange) rangeForUserParagraphAttributeChange
{
  if (!_tf.is_editable || !_tf.uses_ruler)
    return NSMakeRange(NSNotFound, 0);

  if (_tf.is_rich_text)
    return [self selectionRangeForProposedRange: _selected_range
		granularity: NSSelectByParagraph];
  else
    return NSMakeRange(0, [_textStorage length]);
}

- (NSRange) rangeForUserTextChange
{
  if (!_tf.is_editable)
    return NSMakeRange(NSNotFound, 0);
  
  // This expects the selection to be already corrected to characters
  return _selected_range;
}

- (void) setAlignment: (NSTextAlignment)alignment
		range: (NSRange)aRange
{ 
  NSParagraphStyle *style;
  NSMutableParagraphStyle *mstyle;
  
  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage setAlignment: alignment
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];

  // Set the typing attributes
  style = [_typingAttributes objectForKey: NSParagraphStyleAttributeName];
  if (style == nil)
    style = [NSParagraphStyle defaultParagraphStyle];

  mstyle = [style mutableCopy];

  [mstyle setAlignment: alignment];
  // FIXME: Should use setTypingAttributes
  [_typingAttributes setObject: mstyle forKey: NSParagraphStyleAttributeName];
  RELEASE (mstyle);
}

- (NSString*) preferredPasteboardTypeFromArray: (NSArray*)availableTypes
		    restrictedToTypesFromArray: (NSArray*)allowedTypes
{
  NSEnumerator *enumerator;
  NSString *type;

  if (availableTypes == nil)
    return nil;

  if (allowedTypes == nil)
    return [availableTypes objectAtIndex: 0];
    
  enumerator = [allowedTypes objectEnumerator];
  while ((type = [enumerator nextObject]) != nil)
    {
      if ([availableTypes containsObject: type])
        {
	  return type;
        }
    }
  return nil;  
}

- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pboard
{
/*
Reads the text view's preferred type of data from the pasteboard specified
by the pboard parameter. This method
invokes the preferredPasteboardTypeFromArray: restrictedToTypesFromArray: 
method to determine the text view's
preferred type of data and then reads the data using the
readSelectionFromPasteboard: type: method. Returns YES if the
data was successfully read.
*/
  NSString *type = [self preferredPasteboardTypeFromArray: [pboard types]
			 restrictedToTypesFromArray: [self readablePasteboardTypes]];
  
  if (type == nil)
    return NO;

  return [self readSelectionFromPasteboard: pboard
	       type: type];
}

- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pboard
				type: (NSString*)type 
{
/*
Reads data of the given type from pboard. The new data is placed at the
current insertion point, replacing the current selection if one exists.
Returns YES if the data was successfully read.

You should override this method to read pasteboard types other than the
default types. Use the rangeForUserTextChange method to obtain the range
of characters (if any) to be replaced by the new data.
*/

  if ([type isEqualToString: NSStringPboardType])
    {
      [self insertText: [pboard stringForType: NSStringPboardType]];
      return YES;
    } 

  if ([self isRichText])
    {
      if ([type isEqualToString: NSRTFPboardType])
	{
	  [self replaceCharactersInRange: [self rangeForUserTextChange]
		withRTF: [pboard dataForType: NSRTFPboardType]];
	  return YES;
	}
    }

  if (_tf.imports_graphics)
    {
      if ([type isEqualToString: NSRTFDPboardType])
	{
	  [self replaceCharactersInRange: [self rangeForUserTextChange]
		withRTFD: [pboard dataForType: NSRTFDPboardType]];
	  return YES;
	}
      // FIXME: Should also support: NSTIFFPboardType
      if ([type isEqualToString: NSFileContentsPboardType])
	{
	  NSTextAttachment *attachment = [[NSTextAttachment alloc] 
					      initWithFileWrapper: 
						  [pboard readFileWrapper]];

	  [self replaceRange: [self rangeForUserTextChange]
		withAttributedString: 
		    [NSAttributedString attributedStringWithAttachment: attachment]];
	  RELEASE(attachment);
	  return YES;
	}
    }

  // color accepting
  if ([type isEqualToString: NSColorPboardType])
    {
      NSColor *color = [NSColor colorFromPasteboard: pboard];
      NSRange aRange = [self rangeForUserCharacterAttributeChange];

      if (aRange.location != NSNotFound)
	[self setTextColor: color range: aRange];

      return YES;
    }

  // font pasting
  if ([type isEqualToString: NSFontPboardType])
    {
      // FIXME - This should use a serializer. To get that working a helper object 
      // is needed that implements the NSObjCTypeSerializationCallBack protocol.
      // We should add this later, currently the NSArchiver is used.
      // Thanks to Richard, for pointing this out.
      NSData *data = [pboard dataForType: NSFontPboardType];
      NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData: data];

      if (dict != nil)
	{
	  [self setAttributes: dict 
		range: [self rangeForUserCharacterAttributeChange]];
	  return YES;
	}
      return NO;
    }

  // ruler pasting
  if ([type isEqualToString: NSRulerPboardType])
    {
      // FIXME: see NSFontPboardType above
      NSData *data = [pboard dataForType: NSRulerPboardType];
      NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData: data];

      if (dict != nil)
	{
	  [self setAttributes: dict 
		range: [self rangeForUserParagraphAttributeChange]];
	  return YES;
	}
      return NO;
    }
 
  return NO;
}

- (NSArray*) readablePasteboardTypes
{
  // get default types, what are they?
  NSMutableArray *ret = [NSMutableArray arrayWithObjects: NSRulerPboardType,
					NSColorPboardType, NSFontPboardType, nil];

  if (_tf.imports_graphics)
    {
      [ret addObject: NSRTFDPboardType];
      //[ret addObject: NSTIFFPboardType];
      [ret addObject: NSFileContentsPboardType];
    }
  if (_tf.is_rich_text)
    [ret addObject: NSRTFPboardType];

  [ret addObject: NSStringPboardType];

  return ret;
}

- (NSArray*) writablePasteboardTypes
{
  // the selected text can be written to the pasteboard with which types.
  return [self readablePasteboardTypes];
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
			       type: (NSString*)type
{
/*
Writes the current selection to pboard using the given type. Returns YES
if the data was successfully written. You can override this method to add
support for writing new types of data to the pasteboard. You should invoke
super's implementation of the method to handle any types of data your
overridden version does not.
*/

  return [self writeSelectionToPasteboard: pboard
	       types: [NSArray arrayWithObject: type]];
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
			      types: (NSArray*)types
{

/* Writes the current selection to pboard under each type in the types
array. Returns YES if the data for any single type was written
successfully.

You should not need to override this method. You might need to invoke this
method if you are implementing a new type of pasteboard to handle services
other than copy/paste or dragging. */
  BOOL ret = NO;
  NSEnumerator *enumerator;
  NSString *type;

  if (types == nil)
    return NO;

  [pboard declareTypes: types owner: self];
    
  enumerator = [types objectEnumerator];
  while ((type = [enumerator nextObject]) != nil)
    {
      if ([type isEqualToString: NSStringPboardType])
        {
	  ret = ret || [pboard setString: [[self string] substringWithRange: _selected_range] 
			       forType: NSStringPboardType];
	}

      if ([type isEqualToString: NSRTFPboardType])
        {
	  ret = ret || [pboard setData: [self RTFFromRange: _selected_range]
			       forType: NSRTFPboardType];
	}

      if ([type isEqualToString: NSRTFDPboardType])
        {
	  ret = ret || [pboard setData: [self RTFDFromRange: _selected_range]
			       forType: NSRTFDPboardType];
	}

      if ([type isEqualToString: NSColorPboardType])
        {
	  NSColor *color = [self textColor];

	  if (color != nil)
	    {
	      [color writeToPasteboard:  pboard];
	      ret = YES;
	    }
	}

      if ([type isEqualToString: NSFontPboardType])
        {
	  NSDictionary *dict = [_textStorage fontAttributesInRange: _selected_range];

	  if (dict != nil)
	    {
	      // FIXME - This should use a serializer. To get that working a helper object 
	      // is needed that implements the NSObjCTypeSerializationCallBack protocol.
	      // We should add this later, currently the NSArchiver is used.
	      // Thanks to Richard, for pointing this out.
	      [pboard setData: [NSArchiver archivedDataWithRootObject: dict]
		      forType: NSFontPboardType];
	      ret = YES;
	    }
	}

      if ([type isEqualToString: NSRulerPboardType])
        {
	  NSDictionary *dict = [_textStorage rulerAttributesInRange: _selected_range];

	  if (dict != nil)
	    {
	      //FIXME: see NSFontPboardType above
	      [pboard setData: [NSArchiver archivedDataWithRootObject: dict]
		      forType: NSRulerPboardType];
	      ret = YES;
	    }
	}
    }

  return ret;
}

@end

@implementation NSText(GNUstepPrivate)

+ (NSDictionary*) defaultTypingAttributes
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName,
			 [NSFont userFontOfSize: 0], NSFontAttributeName,
		         [NSColor textColor], NSForegroundColorAttributeName,
		         nil];
}

- (void) setAttributes: (NSDictionary*) attributes range: (NSRange) aRange
{
  NSString *type;
  id val;
  NSEnumerator *enumerator = [attributes keyEnumerator];

  if (aRange.location == NSNotFound)
    return;
  if (![self shouldChangeTextInRange: aRange
	     replacementString: nil])
    return;
	      
  [_textStorage beginEditing];
  while ((type = [enumerator nextObject]) != nil)
    {
      val = [attributes objectForKey: type];
      [_textStorage addAttribute: type
		    value: val
		    range: aRange];
    }
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) _illegalMovement: (int) textMovement
{
  // This is similar to [self resignFirstResponder],
  // with the difference that in the notification we need
  // to put the NSTextMovement, which resignFirstResponder
  // does not.  Also, if we are ending editing, we are going
  // to be removed, so it's useless to update any drawing.
  NSNumber *number;
  NSDictionary *uiDictionary;
  
  if (([self isEditable])
      && ([_delegate respondsToSelector:
		       @selector(textShouldEndEditing:)])
      && ([_delegate textShouldEndEditing: self] == NO))
    return;
  
  // Add any clean-up stuff here
  
  number = [NSNumber numberWithInt: textMovement];
  uiDictionary = [NSDictionary dictionaryWithObject: number
			       forKey: @"NSTextMovement"];
  [nc postNotificationName: NSTextDidEndEditingNotification
      object: self  userInfo: uiDictionary];
  return;
}

// begin: dragging of colors and files---------------
- (unsigned int) draggingEntered: (id <NSDraggingInfo>)sender
{
  return NSDragOperationGeneric;
}

- (unsigned int) draggingUpdated: (id <NSDraggingInfo>)sender
{
  return NSDragOperationGeneric;
}

- (void) draggingExited: (id <NSDraggingInfo>)sender
{
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  return [self readSelectionFromPasteboard: [sender draggingPasteboard]];
}

- (void) concludeDragOperation: (id <NSDraggingInfo>)sender
{
}
// end: drag accepting---------------------------------

// central text deletion/backspace method
// (takes care of optimized redraw/ cursor positioning)
- (void) deleteRange: (NSRange) aRange
	   backspace: (BOOL) flag
{
  NSRange deleteRange;

  if (aRange.location == NSNotFound)
    return;

  if (!aRange.length && !(flag && aRange.location))
    return;

  if (aRange.length)
    {
      deleteRange = aRange;
    }
  else
    {
      deleteRange = NSMakeRange (MAX (0, aRange.location - 1), 1);
    }

  if (![self shouldChangeTextInRange: deleteRange
	    replacementString: @""])
    return;
  [_textStorage beginEditing];
  [_textStorage deleteCharactersInRange: deleteRange];
  [_textStorage endEditing];
  [self didChangeText];

  // move cursor <!> [self selectionRangeForProposedRange: ]
  [self setSelectedRange: NSMakeRange (deleteRange.location, 0)];

  // remember x for row - stable cursor movements
  _currentCursor = [self rectForCharacterIndex:
			   _selected_range.location].origin;
}

- (unsigned) characterIndexForPoint: (NSPoint) point
{
  unsigned glyphIndex = [_layoutManager glyphIndexForPoint: point 
					inTextContainer: [self textContainer]];

  return [_layoutManager characterIndexForGlyphAtIndex: glyphIndex];
}

- (NSRect) rectForCharacterIndex: (unsigned) index
{
  NSRange glyphRange = [_layoutManager glyphRangeForCharacterRange: NSMakeRange(index, 1)
				       actualCharacterRange: NULL];
  unsigned glyphIndex = glyphRange.location;
  NSRect rect = [_layoutManager lineFragmentRectForGlyphAtIndex: glyphIndex 
				effectiveRange: NULL];
  NSPoint loc = [_layoutManager locationForGlyphAtIndex: glyphIndex];

  rect.origin.x += loc.x;
  rect.size.width -= loc.x;

  return rect;
}

- (NSRect) rectForCharacterRange: (NSRange) aRange
{
  NSRange glyphRange = [_layoutManager glyphRangeForCharacterRange: aRange 
				       actualCharacterRange: NULL];

  return [_layoutManager boundingRectForGlyphRange: glyphRange 
			 inTextContainer: [self textContainer]];
}

- (void) drawInsertionPointAtIndex: (unsigned) index
			     color: (NSColor*) color
			  turnedOn: (BOOL) flag
{
  NSRect drawRect  = [self rectForCharacterIndex: index];

  drawRect.size.width = 1;
  if (drawRect.size.height == 0)
    drawRect.size.height = 12;

  [self drawInsertionPointInRect: drawRect
	color: color
	turnedOn: flag];
}

@end
