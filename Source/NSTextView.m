/* 
   NSTextView.m

   Copyright (C) 1999 Free Software Foundation, Inc.

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
#include <AppKit/NSMatrix.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>

@implementation NSTextView

/* Class methods */

+ (void) initialize
{
  [super initialize];

  if ([self class] == [NSTextView class])
    {
      [self setVersion: 1];
      [self registerForServices];
    }
}

+ (void) registerForServices
{
  NSArray	*r;
  NSArray	*s;
      
  /*
   * FIXME - should register for all types of data we support, not just string.
   */
  r  = [NSArray arrayWithObjects: NSStringPboardType, nil];
  s  = [NSArray arrayWithObjects: NSStringPboardType, nil];
 
  [[NSApplication sharedApplication] registerServicesMenuSendTypes: s
						       returnTypes: r];
}

/* Initializing Methods */

- (id) initWithFrame: (NSRect)frameRect
       textContainer: (NSTextContainer*)aTextContainer
{
  self = [super initWithFrame: frameRect];

  [self setTextContainer: aTextContainer];
  [self setEditable: YES];

  return self;
}

- (id) initWithFrame: (NSRect)frameRect
{
  NSTextContainer *aTextContainer = 
      [[NSTextContainer alloc] initWithContainerSize: frameRect.size];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

  [layoutManager addTextContainer: aTextContainer];
  RELEASE(aTextContainer);

  _textStorage = [[NSTextStorage alloc] init];
  [_textStorage addLayoutManager: layoutManager];
  RELEASE(layoutManager);

  return [self initWithFrame: frameRect textContainer: aTextContainer];
}

- (void) setTextContainer: (NSTextContainer*)aTextContainer
{
  ASSIGN(_textContainer, aTextContainer);
}

- (NSTextContainer*) textContainer
{
  return _textContainer;
}

- (void) replaceTextContainer: (NSTextContainer*)aTextContainer
{
  // Notify layoutManager of change?

  ASSIGN(_textContainer, aTextContainer);
}

- (void) setTextContainerInset: (NSSize)inset
{
  _textContainerInset = inset;
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
  NSRect bRect = [self bounds];
}

- (NSLayoutManager*) layoutManager
{
  return [_textContainer layoutManager];
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
  [self lockFocus];

  NSDebugLLog(@"NSText", 
    @"drawInsertionPointInRect: (%f, %f)", aRect.size.width, aRect.size.height);

  aRect.size.width = 1;

  if (flag)
    {
      [aColor set];
      NSRectFill(aRect);
    }
  else
    {
      [[self backgroundColor] set];
      NSRectFill(aRect);
    }

  [self unlockFocus];
  [_window flushWindow];
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
  _tf.is_ruler_visible = flag;
}

- (BOOL) isRulerVisible
{
  return _tf.is_ruler_visible;
}

- (void) setSelectedRange: (NSRange)charRange
{
  NSLog(@"setSelectedRange (%d, %d)", charRange.location, charRange.length);
/*
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextViewDidChangeSelectionNotification
    object: self];
*/
  _selected_range = charRange;
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
  NSDebugLLog(@"NSText", @"setSelectedRange stillSelecting.");

  _selected_range = charRange;
  [self setSelectionGranularity: NSSelectByCharacter];

  // FIXME, more.
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
  // No idea.
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

  return NO;
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

  return NO;
}

- (NSArray*) readablePasteboardTypes
{
  // get default types, what are they?
  return nil;
}

- (NSArray*) writablePasteboardTypes
{
  // the selected text can be written to the pasteboard with which types.
  return nil;
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

  return NO;
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

  return NO;
}

- (void) alignJustified: (id)sender
{
/*
  if (!_tf.is_rich_text)
    // if plain all text is jsutified.
  else
    // selected range is fully justified.
*/
}

- (void) changeColor: (id)sender
{
//  NSColor *aColor = [sender color];

  // sets the color for the selected range.
}

- (void) setAlignment: (NSTextAlignment)alignment
		range: (NSRange)aRange
{ 
/*
Sets the alignment of the paragraphs containing characters in aRange to
alignment. alignment is one of: 

      NSLeftTextAlignment
      NSRightTextAlignment 
      NSCenterTextAlignment 
      NSJustifiedTextAlignment 
      NSNaturalTextAlignment
*/
}

- (void) setTypingAttributes: (NSDictionary*)attributes
{
  // more?

  ASSIGN(_typingAttributes, attributes);
}

- (NSDictionary*) typingAttributes
{
  return _typingAttributes;
}

- (void) useStandardKerning: (id)sender
{
  // rekern for selected range if rich text, else rekern entire document.
}

- (void) lowerBaseline: (id)sender
{
/*
  if (_tf.is_rich_text)
    // lower baseline by one point for selected text
  else
    // lower baseline for entire document.
*/
}

- (void) raiseBaseline: (id)sender
{
/*
  if (_tf.is_rich_text)
    // raise baseline by one point for selected text
  else
    // raise baseline for entire document.
*/
}

- (void) turnOffKerning: (id)sender
{
/*
  if (_tf.is_rich_text)
    // turn off kerning in selection.
  else
    // turn off kerning document wide.
*/
}

- (void) loosenKerning: (id)sender
{
/*
  if (_tf.is_rich_text)
    // loosen kerning in selection.
  else
    // loosen kerning document wide.
*/
}

- (void) tightenKerning: (id)sender
{
/*
  if (_tf.is_rich_text)
    // tighten kerning in selection.
  else
    // tighten kerning document wide.
*/
}

- (void) useStandardLigatures: (id)sender
{
  // well.
}

- (void) turnOffLigatures: (id)sender
{
  // sure.
}

- (void) useAllLigatures: (id)sender
{
  // as you say.
}

- (void) clickedOnLink: (id)link
	       atIndex: (unsigned int)charIndex
{

/* Notifies the delegate that the user clicked in a link at the specified
charIndex. The delegate may take any appropriate actions to handle the
click in its textView: clickedOnLink: atIndex: method.Notifies the delegate
that the user clicked in a link at the specified charIndex. The delegate
may take any appropriate actions to handle the click in its
textView: clickedOnLink: atIndex: method. */
 
}

/*
The text is inserted at the insertion point if there is one, otherwise
replacing the selection.
*/

- (void) pasteAsPlainText: (id)sender
{
  [self insertText: [sender string]];
}

- (void) pasteAsRichText: (id)sender
{
  [self insertText: [sender string]];
}

- (void) updateFontPanel
{
  // [fontPanel setFont: [self fontFromRange]];
}

- (void) updateRuler
{
  // ruler!
}

- (NSArray*) acceptableDragTypes
{
  return nil;
}

- (void) updateDragTypeRegistration
{
}

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedSelRange
			       granularity: (NSSelectionGranularity)granularity
{
  NSRange retRange;

  switch (granularity)
    {
      case NSSelectByParagraph: 
        // we need to: 1, find how far to end of paragraph; 2, increase
        // range.
      case NSSelectByWord: 
        // we need to: 1, find how far to end of word; 2, increase range.
      case NSSelectByCharacter: 
      default: 
        retRange = proposedSelRange;
    }

  return retRange;
}

- (NSRange) rangeForUserCharacterAttributeChange
{
  if (!_tf.is_editable || !_tf.uses_font_panel)
    return NSMakeRange(NSNotFound, 0);

  if (_tf.is_rich_text)
    return _selected_range;
  else
    return NSMakeRange(NSNotFound, 0); // should be entire contents.
}

- (NSRange) rangeForUserParagraphAttributeChange
{
  if (!_tf.is_editable)
    return NSMakeRange(NSNotFound, 0);

  if (_tf.is_rich_text)
    return [self selectionRangeForProposedRange: _selected_range
		granularity: NSSelectByParagraph];
  else
    return NSMakeRange(NSNotFound, 0); // should be entire contents.
}

- (NSRange) rangeForUserTextChange
{
  if (!_tf.is_editable || !_tf.uses_ruler)
    return NSMakeRange(NSNotFound, 0);

  return _selected_range;
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

  return NO;
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

- (void) smartInsertForString: (NSString*)aString
	       replacingRange: (NSRange)charRange
		 beforeString: (NSString*)beforeString 
		  afterString: (NSString*)afterString
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
  return YES;
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
  return YES;
}

- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType
{
/*
Returns self if sendType specifies a type of data the text view can put on
the pasteboard and returnType contains a type of data the text view can
read from the pasteboard; otherwise returns nil.
*/

 return nil;
}

- (int) spellCheckerDocumentTag
{
/*
  if (!_spellCheckerDocumentTag)
    _spellCheckerDocumentTag = [[NSSpellingServer sharedServer] uniqueSpellDocumentTag];
*/
  return _spellCheckerDocumentTag;
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

- (void) setString: (NSString*)string
{
  NSAttributedString	*aString;

  aString = [NSAttributedString alloc];
  aString = [aString initWithString: string
			 attributes: [self typingAttributes]];
  AUTORELEASE(aString);

//  [_textStorage replaceRange: NSMakeRange(0, [string length])
//	withString: aString];

  [_textStorage setAttributedString: aString];

//replaceCharactersInRange: NSMakeRange(0, [string length])
//                   withAttributedString: aString];

//  [_textStorage insertAttributedString: aString atIndex: 0];
}

- (void) setText: (NSString*)string
{
  [self setString: string];
}

- (void) insertText: (NSString*)aString
{
  NSDebugLLog(@"NSText", @"%@", aString);

  if (![aString isKindOfClass: [NSAttributedString class]])
    aString = [[NSAttributedString alloc] initWithString: aString
		attributes: [self typingAttributes]];

  [_textStorage replaceCharactersInRange: [self selectedRange]
       withAttributedString: (NSAttributedString*)aString];

  [self sizeToFit];                       // ScrollView interaction

  [self setSelectedRange: NSMakeRange([self 
    selectedRange].location+[aString length],0)];

  [self display];
  [_window update]; 

  NSLog(@"%@", [_textStorage string]);
  /*
   * broadcast notification
   */
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextDidChangeNotification
    object: self];
}

- (void) sizeToFit
{
  NSLog(@"sizeToFit called.\n");
}

- (void) drawRect: (NSRect)aRect
{
  NSRange	glyphRange;
  NSLayoutManager *layoutManager = [self layoutManager];

  if (_background_color != nil)
    {
      [_background_color set];
      NSRectFill(aRect);
    }
  glyphRange = [layoutManager glyphRangeForTextContainer: _textContainer];
  if (glyphRange.length > 0)
    {
      [layoutManager drawGlyphsForGlyphRange: glyphRange
				     atPoint: [self frame].origin];
    }
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
