/* 
   NSTextView.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: September 2000
   Reorganised and cleaned up code

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
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSColorPanel.h>

@implementation NSTextView

/* Class methods */

+ (void) initialize
{
  if ([self class] == [NSTextView class])
    {
      [self setVersion: 1];
      [self registerForServices];
    }
}

+ (void) registerForServices
{
  NSArray *types;
      
  types  = [NSArray arrayWithObjects: NSStringPboardType, NSRTFPboardType, NSRTFDPboardType, nil];
 
  [[NSApplication sharedApplication] registerServicesMenuSendTypes: types
						       returnTypes: types];
}

/* Initializing Methods */

- (id) initWithFrame: (NSRect)frameRect
       textContainer: (NSTextContainer*)aTextContainer
{
  self = [super initWithFrame: frameRect textContainer: aTextContainer];

  [self setEditable: YES];
  [self setUsesFontPanel: YES];
  [self setUsesRuler: YES];

  return self;
}

- (id) initWithFrame: (NSRect)frameRect
{
  return [super initWithFrame: frameRect];
}

- (void)dealloc
{
  RELEASE (_selectedTextAttributes);
  RELEASE (_markedTextAttributes);

  [super dealloc];
}

/* This should only be called by [NSTextContainer -setTextView:] */
- (void) setTextContainer: (NSTextContainer*)aTextContainer
{
  [super setTextContainer: aTextContainer];
}

- (NSTextContainer*) textContainer
{
  return _textContainer;
}

- (void) replaceTextContainer: (NSTextContainer*)aTextContainer
{
  // Notify layoutManager of change?

  /* Do not retain: text container is owning us. */
  _textContainer = aTextContainer;
}

- (void) setTextContainerInset: (NSSize)inset
{
  _textContainerInset = inset;
  [self invalidateTextContainerOrigin];
}

- (NSSize) textContainerInset
{
  return _textContainerInset;
}

- (NSPoint) textContainerOrigin
{
  return _textContainerOrigin;
}

- (void) invalidateTextContainerOrigin
{
  // recompute the textContainerOrigin
  // use bounds, inset, and used rect.
  /*
  NSRect bRect = [self bounds];
  NSRect uRect = [[self layoutManager] usedRectForTextContainer: _textContainer];

  if ([self isFlipped])
    _textContainerOrigin = ;
  else
    _textContainerOrigin = ;
  */
}

- (NSLayoutManager*) layoutManager
{
  return _layoutManager;
}

- (NSTextStorage*) textStorage
{
  return _textStorage;
}

- (void) setBackgroundColor: (NSColor*)aColor
{
  ASSIGN(_background_color, aColor);
}

- (NSColor*) backgroundColor
{
  return _background_color;
}

- (void) setAllowsUndo: (BOOL)flag
{
  _tf.allows_undo = flag;
}

- (BOOL) allowsUndo
{
  return _tf.allows_undo;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _tf.draws_background = flag;
}

- (BOOL) drawsBackground
{
  return _tf.draws_background;
}

- (void) setNeedsDisplayInRect: (NSRect)aRect
	 avoidAdditionalLayout: (BOOL)flag
{
  // FIXME: This is here until the layout manager is working
  [super setNeedsDisplayInRect: aRect];
}

/* We override NSView's setNeedsDisplayInRect: */

- (void) setNeedsDisplayInRect: (NSRect)aRect
{
  [self setNeedsDisplayInRect: aRect avoidAdditionalLayout: NO];
}

- (BOOL) shouldDrawInsertionPoint
{
  return [super shouldDrawInsertionPoint];
}

- (void) drawInsertionPointInRect: (NSRect)aRect
			    color: (NSColor*)aColor
			 turnedOn: (BOOL)flag
{
  [super drawInsertionPointInRect: aRect
	 color: aColor
	 turnedOn: flag];
}

- (void) setConstrainedFrameSize: (NSSize)desiredSize
{
  // some black magic here.
  [self setFrameSize: desiredSize];
}

- (void) cleanUpAfterDragOperation
{
  // release drag information
}

- (unsigned int) dragOperationForDraggingInfo: (id <NSDraggingInfo>)dragInfo 
					 type: (NSString *)type
{
  //FIXME
  return NSDragOperationNone;
}

- (void) setEditable: (BOOL)flag
{
  if (flag)
    _tf.is_selectable = flag;

  _tf.is_editable = flag;
}

- (BOOL) isEditable
{
  return _tf.is_editable;
}

- (void) setSelectable: (BOOL)flag
{
  _tf.is_selectable = flag;
}

- (BOOL) isSelectable
{
  return _tf.is_selectable;
}

- (void) setFieldEditor: (BOOL)flag
{
  _tf.is_field_editor = flag;
}

- (BOOL) isFieldEditor
{
  return _tf.is_field_editor;
}

- (void) setRichText: (BOOL)flag
{
  if (!flag)
    _tf.imports_graphics = flag;

  _tf.is_rich_text = flag;
  [self updateDragTypeRegistration];
}

- (BOOL) isRichText
{
  return _tf.is_rich_text;
}

- (void) setImportsGraphics: (BOOL)flag
{
  if (flag)
    _tf.is_rich_text = flag;

  _tf.imports_graphics = flag;
  [self updateDragTypeRegistration];
}

- (BOOL) importsGraphics
{
  return _tf.imports_graphics;
}

- (void) setUsesFontPanel: (BOOL)flag
{
  _tf.uses_font_panel = flag;
}

- (BOOL) usesFontPanel
{
  return _tf.uses_font_panel;
}

- (void) setUsesRuler: (BOOL)flag
{
  _tf.uses_ruler = flag;
}

- (BOOL) usesRuler
{
  return _tf.uses_ruler;
}

- (void) setRulerVisible: (BOOL)flag
{
  [super setRulerVisible: flag];
}

- (BOOL) isRulerVisible
{
  return _tf.is_ruler_visible;
}

- (void) setSelectedRange: (NSRange)charRange
{
/*
  NSLog(@"setSelectedRange (%d, %d)", charRange.location, charRange.length);
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextViewDidChangeSelectionNotification
    object: self];
  _selected_range = charRange;
*/
  [super setSelectedRange: charRange];
  [self setSelectionGranularity: NSSelectByCharacter];

  // Also removes the marking from
  // marked text if the new selection is greater than the marked region.
}

- (NSRange) selectedRange
{
  return _selected_range;
}

- (void) setSelectedRange: (NSRange)charRange
		 affinity: (NSSelectionAffinity)affinity
	   stillSelecting: (BOOL)flag
{
  // Use affinity to determine the insertion point

  if (flag)
    {
      _selected_range = charRange;
      [self setSelectionGranularity: NSSelectByCharacter];
    }
  else
      [self setSelectedRange: charRange];
}

- (NSSelectionAffinity) selectionAffinity
{
  return _selectionAffinity;
}

- (void) setSelectionGranularity: (NSSelectionGranularity)granularity
{
  _selectionGranularity = granularity;
}

- (NSSelectionGranularity) selectionGranularity
{
  return _selectionGranularity;
}

- (void) setInsertionPointColor: (NSColor*)aColor
{
  ASSIGN(_caret_color, aColor);
}

- (NSColor*) insertionPointColor
{
  return _caret_color;
}

- (void) updateInsertionPointStateAndRestartTimer: (BOOL)flag
{
  // _caretLocation =

  // restart blinking timer.
}

- (void) setSelectedTextAttributes: (NSDictionary*)attributes
{
  ASSIGN(_selectedTextAttributes, attributes);
}

- (NSDictionary*) selectedTextAttributes
{
  return _selectedTextAttributes;
}

- (NSRange) markedRange
{
  // calculate

  return NSMakeRange(NSNotFound, 0);
}

- (void) setMarkedTextAttributes: (NSDictionary*)attributes
{
  ASSIGN(_markedTextAttributes, attributes);
}

- (NSDictionary*) markedTextAttributes
{
  return _markedTextAttributes;
}

- (NSString*) preferredPasteboardTypeFromArray: (NSArray*)availableTypes
		    restrictedToTypesFromArray: (NSArray*)allowedTypes
{
  return [super preferredPasteboardTypeFromArray: availableTypes
		restrictedToTypesFromArray: allowedTypes];
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
  return [super readSelectionFromPasteboard: pboard];
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

  return [super readSelectionFromPasteboard: pboard
		type: type];
}

- (NSArray*) readablePasteboardTypes
{
  // get default types, what are they?
  return [super readablePasteboardTypes];
}

- (NSArray*) writablePasteboardTypes
{
  // the selected text can be written to the pasteboard with which types.
  return [super writablePasteboardTypes];
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

  return [super writeSelectionToPasteboard: pboard
		type: type];
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
  return [super writeSelectionToPasteboard: pboard
		types: types];
}

- (void) alignJustified: (id)sender
{
  [self setAlignment: NSJustifiedTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];   
}

- (void) changeColor: (id)sender
{
  NSColor *aColor = (NSColor*)[sender color];
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  // sets the color for the selected range.
  [self setTextColor: aColor
	range: aRange];
}

- (void) setAlignment: (NSTextAlignment)alignment
		range: (NSRange)aRange
{ 
  [super setAlignment: alignment
	 range: aRange];
}

- (void) setTypingAttributes: (NSDictionary*)attributes
{
  [super setTypingAttributes: attributes];
}

- (NSDictionary*) typingAttributes
{
  return [super typingAttributes];
}

- (void) useStandardKerning: (id)sender
{
  // rekern for selected range if rich text, else rekern entire document.
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;
  
  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage removeAttribute: NSKernAttributeName
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) lowerBaseline: (id)sender
{
  id value;
  float sValue;
  NSRange effRange;
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  // We take the value form the first character and use it for the whole range
  value = [_textStorage attribute: NSBaselineOffsetAttributeName
			atIndex: aRange.location
			effectiveRange: &effRange];

  if (value != nil)
    sValue = [value floatValue] + 1.0;
  else
    sValue = 1.0;

  [_textStorage addAttribute: NSBaselineOffsetAttributeName
		value: [NSNumber numberWithFloat: sValue]
		range: aRange];
}

- (void) raiseBaseline: (id)sender
{
  id value;
  float sValue;
  NSRange effRange;
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  // We take the value form the first character and use it for the whole range
  value = [_textStorage attribute: NSBaselineOffsetAttributeName
			atIndex: aRange.location
			effectiveRange: &effRange];

  if (value != nil)
    sValue = [value floatValue] - 1.0;
  else
    sValue = -1.0;

  [_textStorage addAttribute: NSBaselineOffsetAttributeName
		value: [NSNumber numberWithFloat: sValue]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) turnOffKerning: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;
  
  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage addAttribute: NSKernAttributeName
		value: [NSNumber numberWithFloat: 0.0]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) loosenKerning: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  // FIXME: Should use the current kerning and work relative to point size
  [_textStorage addAttribute: NSKernAttributeName
		value: [NSNumber numberWithFloat: 1.0]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) tightenKerning: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  // FIXME: Should use the current kerning and work relative to point size
  [_textStorage addAttribute: NSKernAttributeName
		value: [NSNumber numberWithFloat: -1.0]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) useStandardLigatures: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage addAttribute: NSLigatureAttributeName
		value: [NSNumber numberWithInt: 1]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) turnOffLigatures: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage addAttribute: NSLigatureAttributeName
		value: [NSNumber numberWithInt: 0]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) useAllLigatures: (id)sender
{
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	    replacementString: nil])
    return;
  [_textStorage beginEditing];
  [_textStorage addAttribute: NSLigatureAttributeName
		value: [NSNumber numberWithInt: 2]
		range: aRange];
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) clickedOnLink: (id)link
	       atIndex: (unsigned int)charIndex
{

/* Notifies the delegate that the user clicked in a link at the specified
charIndex. The delegate may take any appropriate actions to handle the
click in its textView: clickedOnLink: atIndex: method. */
  if (_delegate != nil && 
      [_delegate respondsToSelector: @selector(textView:clickedOnLink:atIndex:)])
      [_delegate textView: self clickedOnLink: link atIndex: charIndex];
}

/*
The text is inserted at the insertion point if there is one, otherwise
replacing the selection.
*/

- (void) pasteAsPlainText: (id)sender
{
  [self readSelectionFromPasteboard: [NSPasteboard generalPasteboard]
				type: NSStringPboardType];
}

- (void) pasteAsRichText: (id)sender
{
  [self readSelectionFromPasteboard: [NSPasteboard generalPasteboard]
				type: NSRTFPboardType];
}

- (void) updateFontPanel
{
  [super updateFontPanel];
}

- (void) updateRuler
{
  // ruler!
}

- (NSArray*) acceptableDragTypes
{
  return [self readablePasteboardTypes];
}

- (void) updateDragTypeRegistration
{
  // FIXME: Should change registration for all our text views
  if (_tf.is_editable && _tf.is_rich_text)
    [self registerForDraggedTypes: [self acceptableDragTypes]];
  else
    [self unregisterDraggedTypes];
}

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedSelRange
			       granularity: (NSSelectionGranularity)granularity
{
  return [super selectionRangeForProposedRange: proposedSelRange
		granularity: granularity];
}

- (NSRange) rangeForUserCharacterAttributeChange
{
  return [super rangeForUserCharacterAttributeChange];
}

- (NSRange) rangeForUserParagraphAttributeChange
{
  return [super rangeForUserParagraphAttributeChange];
}

- (NSRange) rangeForUserTextChange
{
  return [super rangeForUserTextChange];
}


- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType
{
/*
Returns self if sendType specifies a type of data the text view can put on
the pasteboard and returnType contains a type of data the text view can
read from the pasteboard; otherwise returns nil.
*/

 return [super validRequestorForSendType: sendType
		returnType: returnType];
}

- (int) spellCheckerDocumentTag
{
  return [super spellCheckerDocumentTag];
}

- (void) insertText: (NSString*)aString
{
  [super insertText: aString];
}

- (void) sizeToFit
{
  [super sizeToFit];
}

- (BOOL) shouldChangeTextInRange: (NSRange)affectedCharRange
	       replacementString: (NSString*)replacementString
{
/*
This method checks with the delegate as needed using
textShouldBeginEditing: and
textView: shouldChangeTextInRange: replacementString: , returning YES to
allow the change, and NO to prohibit it.

This method must be invoked at the start of any sequence of user-initiated
editing changes. If your subclass of NSTextView implements new methods
that modify the text, make sure to invoke this method to determine whether
the change should be made. If the change is allowed, complete the change
by invoking the didChangeText method. See Notifying About Changes to the
Text in the class description for more information. If you can't determine
the affected range or replacement string before beginning changes, pass
(NSNotFound, 0) and nil for these values. */

  return YES;
}

- (void) didChangeText
{
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextDidChangeNotification object: self];
}

- (void) setSmartInsertDeleteEnabled: (BOOL)flag
{
  _tf.smart_insert_delete = flag;
}

- (BOOL) smartInsertDeleteEnabled
{
  return _tf.smart_insert_delete;
}

- (NSRange) smartDeleteRangeForProposedRange: (NSRange)proposedCharRange
{
  // FIXME.
  return proposedCharRange;
}

- (NSString *)smartInsertAfterStringForString: (NSString *)aString 
			       replacingRange: (NSRange)charRange
{
  // FIXME.
  return nil;
}

- (NSString *)smartInsertBeforeStringForString: (NSString *)aString 
				replacingRange: (NSRange)charRange
{
  // FIXME.
  return nil;
}

- (void) smartInsertForString: (NSString*)aString
	       replacingRange: (NSRange)charRange
		 beforeString: (NSString**)beforeString 
		  afterString: (NSString**)afterString
{

/* Determines whether whitespace needs to be added around aString to
preserve proper spacing and punctuation when it's inserted into the
receiver's text over charRange. Returns by reference in beforeString and
afterString any whitespace that should be added, unless either or both is
nil. Both are returned as nil if aString is nil or if smart insertion and
deletion is disabled.

As part of its implementation, this method calls
smartInsertAfterStringForString: replacingRange: and
smartInsertBeforeStringForString: replacingRange: .To change this method's
behavior, override those two methods instead of this one.

NSTextView uses this method as necessary. You can also use it in
implementing your own methods that insert text. To do so, invoke this
method with the proper arguments, then insert beforeString, aString, and
afterString in order over charRange. */
  if (beforeString)
    *beforeString = [self smartInsertBeforeStringForString: aString 
			  replacingRange: charRange];

  if (afterString)
    *afterString = [self smartInsertAfterStringForString: aString 
			 replacingRange: charRange];
}

- (BOOL) resignFirstResponder
{
/*
  if (nextRsponder == NSTextView_in_NSLayoutManager)
    return YES;
  else
    {
      if (![self textShouldEndEditing])
	return NO;
      else
	{
  	  [[NSNotificationCenter defaultCenter]
    	    postNotificationName: NSTextDidEndEditingNotification object: self];
	  // [self hideSelection];
	  return YES;
	}
    }
*/
  return [super resignFirstResponder];
}

- (BOOL) becomeFirstResponder
{
/*
  if (!nextRsponder == NSTextView_in_NSLayoutManager)
    {
      //draw selection
      //update the insertion point
    }
*/
  return [super becomeFirstResponder];
}

- (void) rulerView: (NSRulerView*)aRulerView
     didMoveMarker: (NSRulerMarker*)aMarker
{
/*
NSTextView checks for permission to make the change in its
rulerView: shouldMoveMarker: method, which invokes
shouldChangeTextInRange: replacementString: to send out the proper request
and notifications, and only invokes this
method if permission is granted.

  [self didChangeText];
*/
}

- (void) rulerView: (NSRulerView*)aRulerView
   didRemoveMarker: (NSRulerMarker*)aMarker
{
/*
NSTextView checks for permission to move or remove a tab stop in its
rulerView: shouldMoveMarker: method, which invokes
shouldChangeTextInRange: replacementString: to send out the proper request
and notifications, and only invokes this method if permission is granted.
*/
}

- (void)rulerView:(NSRulerView *)ruler 
     didAddMarker:(NSRulerMarker *)marker
{
}

- (void) rulerView: (NSRulerView*)aRulerView
   handleMouseDown: (NSEvent*)theEvent
{
/*
This NSRulerView client method adds a left tab marker to the ruler, but a
subclass can override this method to provide other behavior, such as
creating guidelines. This method is invoked once with theEvent when the
user first clicks in the aRulerView's ruler area, as described in the
NSRulerView class specification.
*/
}

- (BOOL) rulerView: (NSRulerView*)aRulerView
   shouldAddMarker: (NSRulerMarker*)aMarker
{

/* This NSRulerView client method controls whether a new tab stop can be
added. The receiver checks for permission to make the change by invoking
shouldChangeTextInRange: replacementString: and returning the return value
of that message. If the change is allowed, the receiver is then sent a
rulerView: didAddMarker: message. */

  return NO;
}

- (BOOL) rulerView: (NSRulerView*)aRulerView
  shouldMoveMarker: (NSRulerMarker*)aMarker
{

/* This NSRulerView client method controls whether an existing tab stop
can be moved. The receiver checks for permission to make the change by
invoking shouldChangeTextInRange: replacementString: and returning the
return value of that message. If the change is allowed, the receiver is
then sent a rulerView: didAddMarker: message. */

  return NO;
}

- (BOOL) rulerView: (NSRulerView*)aRulerView
shouldRemoveMarker: (NSRulerMarker*)aMarker
{

/* This NSRulerView client method controls whether an existing tab stop
can be removed. Returns YES if aMarker represents an NSTextTab, NO
otherwise. Because this method can be invoked repeatedly as the user drags
a ruler marker, it returns that value immediately. If the change is allows
and the user actually removes the marker, the receiver is also sent a
rulerView: didRemoveMarker: message. */

  return NO;
}

- (float) rulerView: (NSRulerView*)aRulerView
      willAddMarker: (NSRulerMarker*)aMarker 
	 atLocation: (float)location
{

/* This NSRulerView client method ensures that the proposed location of
aMarker lies within the appropriate bounds for the receiver's text
container, returning the modified location. */

  return 0.0;
}

- (float) rulerView: (NSRulerView*)aRulerView
     willMoveMarker: (NSRulerMarker*)aMarker 
	 toLocation: (float)location
{

/* This NSRulerView client method ensures that the proposed location of
aMarker lies within the appropriate bounds for the receiver's text
container, returning the modified location. */

  return 0.0;
}

- (void) setDelegate: (id) anObject
{
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [super setDelegate: anObject];
 
#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(textView##notif_name: )]) \
    [nc addObserver: _delegate \
           selector: @selector(textView##notif_name: ) \
               name: NSTextView##notif_name##Notification \
             object: self]
 
  SET_DELEGATE_NOTIFICATION(DidChangeSelection);
  SET_DELEGATE_NOTIFICATION(WillChangeNotifyingTextView);
}

@end

@implementation NSTextView(NSTextInput)
// This are all the NSTextInput methods that are not implemented on NSTextView
// or one of its super classes.

- (void)setMarkedText:(NSString *)aString selectedRange:(NSRange)selRange
{
}

- (BOOL)hasMarkedText
{
  return NO;
}

- (void)unmarkText
{
}

- (NSArray*)validAttributesForMarkedText
{
  return nil;
}

- (long)conversationIdentifier
{
  return 0;
}

- (NSRect)firstRectForCharacterRange:(NSRange)theRange
{
  return NSZeroRect;
}
@end
