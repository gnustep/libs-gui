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

+ (void)initialize
{
  [super initialize];

  if([self class] == [NSTextView class])
    {
      [self setVersion:1];
      [self registerForServices];
    }
}

+ (void)registerForServices
{
  // Talk to Richard about how to do this properly.
}

/* Initializing Methods */

- (id)initWithFrame:(NSRect)frameRect
      textContainer:(NSTextContainer *)aTextContainer
{
  self = [super initWithFrame:frameRect];

  [self setTextContainer:aTextContainer];
  [self setEditable:YES];

  return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
  textStorage = [[NSTextStorage alloc] init];

  layoutManager = [[NSLayoutManager alloc] init];

  [textStorage addLayoutManager:layoutManager];
  [layoutManager release];

  textContainer = [[NSTextContainer alloc] initWithContainerSize:frameRect.size];
  [layoutManager addTextContainer:textContainer];
  [textContainer release];

  return [self initWithFrame:frameRect textContainer:textContainer];
}

- (void)setTextContainer:(NSTextContainer *)aTextContainer
{
  ASSIGN(textContainer, aTextContainer);
}

- (NSTextContainer *)textContainer
{
  return textContainer;
}

- (void)replaceTextContainer:(NSTextContainer *)aTextContainer
{
  // Notify layoutManager of change?

  ASSIGN(textContainer, aTextContainer);
}

- (void)setTextContainerInset:(NSSize)inset
{
  textContainerInset = inset;
}

- (NSSize)textContainerInset
{
  return textContainerInset;
}

- (NSPoint)textContainerOrigin
{
  // use bounds, inset, and used rect.
  NSRect bRect = [self bounds];

  return NSZeroPoint;
}

- (void)invalidateTextContainerOrigin
{
  tv_resetTextContainerOrigin = YES;
}

- (NSLayoutManager *)layoutManager
{
  return [textContainer layoutManager];
}

- (NSTextStorage *)textStorage
{
  return textStorage;
}

- (void)setBackgroundColor:(NSColor *)aColor
{
  ASSIGN(tv_backGroundColor, aColor);
}

- (NSColor *)backgroundColor
{
  return tv_backGroundColor;
}

- (void)setDrawsBackground:(BOOL)flag
{
  tv_drawsBackground = flag;
}

- (BOOL)drawsBackground
{
  return tv_drawsBackground;
}

- (void)setNeedsDisplayInRect:(NSRect)aRect
        avoidAdditionalLayout:(BOOL)flag
{
/*
  NSRange glyphsToDraw = [layoutManager
glyphRangeForTextContainer:textContainer];

  [self lockFocus];
  [layoutManager drawGlyphsForGlyphRange:glyphsToDraw
                        atPoint:[self frame].origin];
  [self unlockFocus];
*/
}

/* We override NSView's setNeedsDisplayInRect: */

- (void)setNeedsDisplayInRect:(NSRect)aRect
{
  [self setNeedsDisplayInRect:aRect avoidAdditionalLayout:NO];
}

- (BOOL)shouldDrawInsertionPoint
{
  return tv_shouldDrawInsertionPoint;
}

- (void)drawInsertionPointInRect:(NSRect)aRect
			   color:(NSColor *)aColor
			turnedOn:(BOOL)flag
{
  [self lockFocus];

  NSLog(@"drawInsertionPointInRect: (%f, %f)", aRect.size.width,
aRect.size.height);

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
  [[self window] flushWindow];
}

- (void)setConstrainedFrameSize:(NSSize)desiredSize
{
  // some black magic here.
  [self setFrameSize:desiredSize];
}

- (void)cleanUpAfterDragOperation
{
  // release drag information
}

- (void)setEditable:(BOOL)flag
{
  if (flag)
    tv_selectable = flag;

  tv_editable = flag;
}

- (BOOL)isEditable
{
  return tv_editable;
}

- (void)setSelectable:(BOOL)flag
{
  tv_selectable = flag;
}

- (BOOL)isSelectable
{
  return tv_selectable;
}

- (void)setFieldEditor:(BOOL)flag
{
  tv_fieldEditor = flag;
}

- (BOOL)isFieldEditor
{
  return tv_fieldEditor;
}

- (void)setRichText:(BOOL)flag
{
  if (!flag)
    tv_acceptDraggedFiles = flag;

  tv_richText = flag;
}

- (BOOL)isRichText
{
  return tv_richText;
}

- (void)setImportsGraphics:(BOOL)flag
{
  if (flag)
    tv_richText = flag;

  tv_acceptDraggedFiles = flag;
}

- (BOOL)importsGraphics
{
  return tv_acceptDraggedFiles;
}

- (void)setUsesFontPanel:(BOOL)flag
{
  tv_usesFontPanel = flag;
}

- (BOOL)usesFontPanel
{
  return tv_usesFontPanel;
}

- (void)setUsesRuler:(BOOL)flag
{
  tv_usesRuler = flag;
}

- (BOOL)usesRuler
{
  return tv_usesRuler;
}

- (void)setRulerVisible:(BOOL)flag
{
  tv_rulerVisible = flag;
}

- (BOOL)isRulerVisible
{
  return tv_rulerVisible;
}

- (void)setSelectedRange:(NSRange)charRange
{
  NSLog(@"setSelectedRange (%d, %d)", charRange.location, charRange.length);
/*
  [[NSNotificationCenter defaultCenter]
    postNotificationName:NSTextViewDidChangeSelectionNotification
    object:self];
*/
  tv_selectedRange = charRange;
  [self setSelectionGranularity:NSSelectByCharacter];

  // Also removes the marking from
  // marked text if the new selection is greater than the marked region.
}

- (NSRange)selectedRange
{
  return tv_selectedRange;
}

- (void)setSelectedRange:(NSRange)charRange
		affinity:(NSSelectionAffinity)affinity
	  stillSelecting:(BOOL)flag
{
  NSLog(@"setSelectedRange stillSelecting.");

  tv_selectedRange = charRange;
  [self setSelectionGranularity:NSSelectByCharacter];

  // FIXME, more.
}

- (NSSelectionAffinity)selectionAffinity
{
  return tv_selectionAffinity;
}

- (void)setSelectionGranularity:(NSSelectionGranularity)granularity
{
  tv_selectionGranularity = granularity;
}

- (NSSelectionGranularity)selectionGranularity
{
  return tv_selectionGranularity;
}

- (void)setInsertionPointColor:(NSColor *)aColor
{
  ASSIGN(tv_caretColor, aColor);
}

- (NSColor *)insertionPointColor
{
  return tv_caretColor;
}

- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
  // tv_caretLocation =

  // restart blinking timer.
}

- (void)setSelectedTextAttributes:(NSDictionary *)attributes
{
  ASSIGN(tv_selectedTextAttributes, attributes);
}

- (NSDictionary *)selectedTextAttributes
{
  return tv_selectedTextAttributes;
}

- (NSRange)markedRange
{
  // calculate

  return NSMakeRange(NSNotFound, 0);
}

- (void)setMarkedTextAttributes:(NSDictionary *)attributes
{
  ASSIGN(tv_markedTextAttributes, attributes);
}

- (NSDictionary *)markedTextAttributes
{
  return tv_markedTextAttributes;
}

- (NSString *)preferredPasteboardTypeFromArray:(NSArray *)availableTypes
		    restrictedToTypesFromArray:(NSArray *)allowedTypes
{
  // No idea.
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
/*
Reads the text view's preferred type of data from the pasteboard specified
by the pboard parameter. This method
invokes the preferredPasteboardTypeFromArray:restrictedToTypesFromArray:
method to determine the text view's
preferred type of data and then reads the data using the
readSelectionFromPasteboard:type: method. Returns YES if the
data was successfully read.
*/

  return NO;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
			       type:(NSString *)type 
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

- (NSArray *)readablePasteboardTypes
{
  // get default types, what are they?
}

- (NSArray *)writablePasteboardTypes
{
  // the selected text can be written to the pasteboard with which types.
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
			      type:(NSString *)type
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

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
			     types:(NSArray *)types
{

/* Writes the current selection to pboard under each type in the types
array. Returns YES if the data for any single type was written
successfully.

You should not need to override this method. You might need to invoke this
method if you are implementing a new type of pasteboard to handle services
other than copy/paste or dragging. */

  return NO;
}

- (void)alignJustified:(id)sender
{
/*
  if (!tv_richText)
    // if plain all text is jsutified.
  else
    // selected range is fully justified.
*/
}

- (void)changeColor:(id)sender
{
//  NSColor *aColor = [sender color];

  // sets the color for the selected range.
}

- (void)setAlignment:(NSTextAlignment)alignment
	       range:(NSRange)aRange
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

- (void)setTypingAttributes:(NSDictionary *)attributes
{
  // more?

  ASSIGN(tv_typingAttributes, attributes);
}

- (NSDictionary *)typingAttributes
{
  return tv_typingAttributes;
}

- (void)useStandardKerning:(id)sender
{
  // rekern for selected range if rich text, else rekern entire document.
}

- (void)lowerBaseline:(id)sender
{
/*
  if (tv_richText)
    // lower baseline by one point for selected text
  else
    // lower baseline for entire document.
*/
}

- (void)raiseBaseline:(id)sender
{
/*
  if (tv_richText)
    // raise baseline by one point for selected text
  else
    // raise baseline for entire document.
*/
}

- (void)turnOffKerning:(id)sender
{
/*
  if (tv_richText)
    // turn off kerning in selection.
  else
    // turn off kerning document wide.
*/
}

- (void)loosenKerning:(id)sender
{
/*
  if (tv_richText)
    // loosen kerning in selection.
  else
    // loosen kerning document wide.
*/
}

- (void)tightenKerning:(id)sender
{
/*
  if (tv_richText)
    // tighten kerning in selection.
  else
    // tighten kerning document wide.
*/
}

- (void)useStandardLigatures:(id)sender
{
  // well.
}

- (void)turnOffLigatures:(id)sender
{
  // sure.
}

- (void)useAllLigatures:(id)sender
{
  // as you say.
}

- (void)clickedOnLink:(id)link
	      atIndex:(unsigned int)charIndex
{

/* Notifies the delegate that the user clicked in a link at the specified
charIndex. The delegate may take any appropriate actions to handle the
click in its textView:clickedOnLink:atIndex: method.Notifies the delegate
that the user clicked in a link at the specified charIndex. The delegate
may take any appropriate actions to handle the click in its
textView:clickedOnLink:atIndex: method. */
 
}

/*
The text is inserted at the insertion point if there is one, otherwise
replacing the selection.
*/

- (void)pasteAsPlainText:(id)sender
{
  [self insertText:[sender string]];
}

- (void)pasteAsRichText:(id)sender
{
  [self insertText:[sender string]];
}

- (void)updateFontPanel
{
  // [fontPanel setFont:[self fontFromRange]];
}

- (void)updateRuler
{
  // ruler!
}

- (NSArray *)acceptableDragTypes
{
}

- (void)updateDragTypeRegistration
{
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange
			      granularity:(NSSelectionGranularity)granularity
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

- (NSRange)rangeForUserCharacterAttributeChange
{
  if (!tv_editable || !tv_usesFontPanel)
    return NSMakeRange(NSNotFound, 0);

  if (tv_richText)
    return tv_selectedRange;
  else
    return NSMakeRange(NSNotFound, 0); // should be entire contents.
}

- (NSRange)rangeForUserParagraphAttributeChange
{
  if (!tv_editable)
    return NSMakeRange(NSNotFound, 0);

  if (tv_richText)
    return [self selectionRangeForProposedRange:tv_selectedRange
		granularity:NSSelectByParagraph];
  else
    return NSMakeRange(NSNotFound, 0); // should be entire contents.
}

- (NSRange)rangeForUserTextChange
{
  if (!tv_editable || !tv_usesRuler)
    return NSMakeRange(NSNotFound, 0);

  return tv_selectedRange;
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange
	      replacementString:(NSString *)replacementString
{
/*
This method checks with the delegate as needed using
textShouldBeginEditing: and
textView:shouldChangeTextInRange:replacementString:, returning YES to
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

- (void)didChangeText
{
  [[NSNotificationCenter defaultCenter]
    postNotificationName:NSTextDidChangeNotification object:self];
}

- (void)setSmartInsertDeleteEnabled:(BOOL)flag
{
  tv_smartInsertDelete = flag;
}

- (BOOL)smartInsertDeleteEnabled
{
  return tv_smartInsertDelete;
}

- (NSRange)smartDeleteRangeForProposedRange:(NSRange)proposedCharRange
{
// FIXME.
  return proposedCharRange;
}

- (void)smartInsertForString:(NSString *)aString
              replacingRange:(NSRange)charRange
		beforeString:(NSString *)beforeString 
		 afterString:(NSString *)afterString
{

/* Determines whether whitespace needs to be added around aString to
preserve proper spacing and punctuation when it's inserted into the
receiver's text over charRange. Returns by reference in beforeString and
afterString any whitespace that should be added, unless either or both is
nil. Both are returned as nil if aString is nil or if smart insertion and
deletion is disabled.

As part of its implementation, this method calls
smartInsertAfterStringForString:replacingRange: and
smartInsertBeforeStringForString:replacingRange:.To change this method's
behavior, override those two methods instead of this one.

NSTextView uses this method as necessary. You can also use it in
implementing your own methods that insert text. To do so, invoke this
method with the proper arguments, then insert beforeString, aString, and
afterString in order over charRange. */

}

- (BOOL)resignFirstResponder
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
    	    postNotificationName:NSTextDidEndEditingNotification object:self];
	  // [self hideSelection];
	  return YES;
	}
    }
*/
  return YES;
}

- (BOOL)becomeFirstResponder
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

- (id)validRequestorForSendType:(NSString *)sendType
		     returnType:(NSString *)returnType
{
/*
Returns self if sendType specifies a type of data the text view can put on
the pasteboard and returnType contains a type of data the text view can
read from the pasteboard; otherwise returns nil.
*/

 return nil;
}

- (int)spellCheckerDocumentTag
{
/*
  if (!tv_spellTag)
    tv_spellTag = [[NSSpellingServer sharedServer] uniqueSpellDocumentTag];
*/
  return tv_spellTag;
}

- (void)rulerView:(NSRulerView *)aRulerView
    didMoveMarker:(NSRulerMarker *)aMarker
{
/*
NSTextView checks for permission to make the change in its
rulerView:shouldMoveMarker: method, which invokes
shouldChangeTextInRange:replacementString: to send out the proper request
and notifications, and only invokes this
method if permission is granted.

  [self didChangeText];
*/
}

- (void)rulerView:(NSRulerView *)aRulerView
  didRemoveMarker:(NSRulerMarker *)aMarker
{
/*
NSTextView checks for permission to move or remove a tab stop in its
rulerView:shouldMoveMarker: method, which invokes
shouldChangeTextInRange:replacementString: to send out the proper request
and notifications, and only invokes this method if permission is granted.
*/
}

- (void)rulerView:(NSRulerView *)aRulerView
  handleMouseDown:(NSEvent *)theEvent
{
/*
This NSRulerView client method adds a left tab marker to the ruler, but a
subclass can override this method to provide other behavior, such as
creating guidelines. This method is invoked once with theEvent when the
user first clicks in the aRulerView's ruler area, as described in the
NSRulerView class specification.
*/
}

- (BOOL)rulerView:(NSRulerView *)aRulerView
  shouldAddMarker:(NSRulerMarker *)aMarker
{

/* This NSRulerView client method controls whether a new tab stop can be
added. The receiver checks for permission to make the change by invoking
shouldChangeTextInRange:replacementString: and returning the return value
of that message. If the change is allowed, the receiver is then sent a
rulerView:didAddMarker: message. */

  return NO;
}

- (BOOL)rulerView:(NSRulerView *)aRulerView
 shouldMoveMarker:(NSRulerMarker *)aMarker
{

/* This NSRulerView client method controls whether an existing tab stop
can be moved. The receiver checks for permission to make the change by
invoking shouldChangeTextInRange:replacementString: and returning the
return value of that message. If the change is allowed, the receiver is
then sent a rulerView:didAddMarker: message. */

  return NO;
}

- (BOOL)rulerView:(NSRulerView *)aRulerView
  shouldRemoveMarker:(NSRulerMarker *)aMarker
{

/* This NSRulerView client method controls whether an existing tab stop
can be removed. Returns YES if aMarker represents an NSTextTab, NO
otherwise. Because this method can be invoked repeatedly as the user drags
a ruler marker, it returns that value immediately. If the change is allows
and the user actually removes the marker, the receiver is also sent a
rulerView:didRemoveMarker: message. */

  return NO;
}

- (float)rulerView:(NSRulerView *)aRulerView
     willAddMarker:(NSRulerMarker *)aMarker 
        atLocation:(float)location
{

/* This NSRulerView client method ensures that the proposed location of
aMarker lies within the appropriate bounds for the receiver's text
container, returning the modified location. */

  return 0.0;
}

- (float)rulerView:(NSRulerView *)aRulerView
    willMoveMarker:(NSRulerMarker *)aMarker 
        toLocation:(float)location
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
  if ([delegate respondsToSelector: @selector(textView##notif_name:)]) \
    [nc addObserver: delegate \
           selector: @selector(textView##notif_name:) \
               name: NSTextView##notif_name##Notification \
             object: self]
 
  SET_DELEGATE_NOTIFICATION(DidChangeSelection);
  SET_DELEGATE_NOTIFICATION(WillChangeNotifyingTextView);
}

-(void) setString:(NSString *)string
{
  NSAttributedString *aString = [[[NSAttributedString alloc]
		initWithString: string
                attributes: [self typingAttributes]] autorelease];

//  [textStorage replaceRange:NSMakeRange(0, [string length])
//	withString:aString];

  [textStorage setAttributedString: aString];

//replaceCharactersInRange:NSMakeRange(0, [string length])
//                   withAttributedString: aString];

//  [textStorage insertAttributedString:aString atIndex:0];
}

-(void) setText:(NSString *)string {[self setString:string];}

- (void)insertText:(NSString *)aString
{
  NSLog(@"%@", aString);

  if (![aString isKindOfClass:[NSAttributedString class]])
    aString = [[NSAttributedString alloc] initWithString:aString
		attributes:[self typingAttributes]];

  [textStorage replaceCharactersInRange:[self selectedRange]
       withAttributedString:(NSAttributedString *)aString];

  [self setSelectedRange:NSMakeRange([self 
    selectedRange].location+[aString length],0)];

  NSLog(@"%@", [textStorage string]);
}

- (void)drawRect:(NSRect)aRect
{
  if(tv_backGroundColor)
    {
      [tv_backGroundColor set];
      NSRectFill (aRect);
    }

  [layoutManager drawGlyphsForGlyphRange:[layoutManager glyphRangeForTextContainer: textContainer]
	atPoint: [self frame].origin];
}

/*
- (void)mouseDown:(NSEvent *)aEvent
{
  NSLog(@"mouseDown:");
}
*/
@end
