/*                                                    -*-objc-*-
   NSTextView.h

   Copyright (C) 1999, 2000 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: September 2000
   Reformatted and cleaned up.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2000

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

#ifndef _GNUstep_H_NSTextView
#define _GNUstep_H_NSTextView

#include <AppKit/NSText.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSRulerMarker.h>

@class NSTextContainer;
@class NSTextStorage;
@class NSLayoutManager;

// these definitions should migrate to NSTextView when implemented
typedef enum _NSSelectionGranularity {	
  NSSelectByCharacter	= 0,
  NSSelectByWord	= 1,
  NSSelectByParagraph	= 2,
} NSSelectionGranularity;

#ifndef NO_GNUSTEP
typedef enum _NSSelectionAffinity {	
  NSSelectionAffinityUpstream	= 0,
  NSSelectionAffinityDownstream	= 1,
} NSSelectionAffinity;
#endif

@interface NSTextView : NSText //<NSTextInput>
{
  struct GSTextViewFlagsType {
    /* owns_text_network is YES if we have created the whole network
       of text classes (and thus we are responsible to release them
       when we are released).
       
       owns_text_network in NO if the text network was assembled by
       hand, and the text storage owns everything - thus we need to
       release nothing.  */
    unsigned owns_text_network: 1;
    /* is_in_dealloc is always NO except when we own text network and
       are deallocating */
    unsigned is_in_dealloc: 1;
    unsigned allows_undo: 1;
    unsigned smart_insert_delete: 1;
    /* multiple_textviews is YES if more than one NSTextView are
       sharing this layout manager.  In this case, we need to keep the
       views in sync. */
    unsigned multiple_textviews: 1;
    /* YES if delegate responds to
       `shouldChangeTextInRange:replacementString:' */
    unsigned delegate_responds_to_should_change: 1;
    /* YES if delegate responds to
       `textView:willChangeSelectionFromCharacterRange:toCharacterRange:' */
    unsigned delegate_responds_to_will_change_sel: 1;
  } _tvf;
  
  /* The following is the object used when posting notifications.  
     It is usually `self' - but in the case of multiple textviews 
     it is the firstTextView returned by the layout manager - which 
     might or might not be `self'.  This must *not* be retained. */
  NSTextView *_notifObject;

  /* content */
  NSTextStorage	*_textStorage;
  NSTextContainer *_textContainer;

  /* manages layout information */
  NSLayoutManager *_layoutManager;  

  /* container position */
  NSSize _textContainerInset;
  NSPoint _textContainerOrigin;

  /* These selection ivars should be shared with the other textviews -
     ie, should be stored in the layout manager */
  NSMutableDictionary *_typingAttributes;
  NSRange _selected_range;
  NSRange _original_selected_range;
  NSColor *_caret_color;
  int _spellCheckerDocumentTag;
  
  NSDictionary *_selectedTextAttributes;
  NSDictionary *_markedTextAttributes;
  NSSelectionGranularity _selectionGranularity;

  /* Column-stable cursor up/down */
  NSPoint _currentCursor;
}

/**************************** Initializing ****************************/

+(void) registerForServices;
// This is sent each time a view is initialized.  If you subclass you 
//should ensure that you only register once.

- (id)initWithFrame:(NSRect)frameRect 
      textContainer:(NSTextContainer *)container;
// Designated Initializer. container may be nil.

- (id)initWithFrame:(NSRect)frameRect;
// This variant will create the text network (textStorage, layoutManager, 
// and a container).

/***************** Get/Set the container and other stuff *****************/

-(NSTextContainer*) textContainer;
-(void)setTextContainer:(NSTextContainer*) container;
// The set method should not be called directly, but you might want to
// override it. Gets or sets the text container for this view.
// Setting the text container marks the view as needing display.  The
// text container calls the set method from its setTextView: method.

- (void)replaceTextContainer:(NSTextContainer *)newContainer;
// This method should be used instead of the primitive
// -setTextContainer: if you need to replace a view's text container
// with a new one leaving the rest of the web intact.  This method
// deals with all the work of making sure the view doesn't get
// deallocated and removing the old container from the layoutManager
// and replacing it with the new one.

- (void)setTextContainerInset:(NSSize)inset;
- (NSSize)textContainerInset;
// The textContianerInset determines the padding that the view
// provides around the container.  The container's origin will be
// inset by this amount from the bounds point {0,0} and padding will
// be left to the right and below the container of the same amount.
// This inset affects the view sizing in response to new layout and is
// used by the rectangular text containers when they track the view's
// frame dimensions.

- (NSPoint)textContainerOrigin;
- (void)invalidateTextContainerOrigin;
// The container's origin in the view is determined from the current
// usage of the container, the container inset, and the view size.
// textContainerOrigin returns this point.
// invalidateTextContainerOrigin is sent automatically whenever
// something changes that causes the origin to possibly move.  You
// usually do not need to call invalidate yourself.

- (NSLayoutManager *) layoutManager;
- (NSTextStorage *) textStorage;
// Convenience methods

/************************* Key binding entry-point *************************/

- (void) insertText: (NSString *)insertString;
// This method is the funnel point for text insertion after keys pass
// through the key binder.

/*************************** Sizing methods ***************************/

- (void) setConstrainedFrameSize: (NSSize)desiredSize;
// Sets the frame size of the view to desiredSize constrained within
// min and max size.

/***************** New miscellaneous API above and beyond NSText *****************/

- (void) changeColor: (id)sender;
// Called from NSColorPanel to set the text colour of the selection

- (void) alignJustified: (id)sender;
- (void) setAlignment: (NSTextAlignment)alignment  range: (NSRange)range;
// These complete the set of range: type set methods. to be equivalent
// to the set of non-range taking varieties.

- (void) pasteAsPlainText: (id)sender;
- (void) pasteAsRichText: (id)sender;
// These methods are like paste: (from NSResponder) but they restrict
// the acceptable type of the pasted data.  They are suitable as menu
// actions for appropriate "Paste As" submenu commands.

/*************************** New Font menu commands ***************************/

- (void) turnOffKerning: (id)sender;
- (void) tightenKerning: (id)sender;
- (void) loosenKerning: (id)sender;
- (void) useStandardKerning: (id)sender;
- (void) turnOffLigatures: (id)sender;
- (void) useStandardLigatures: (id)sender;
- (void) useAllLigatures: (id)sender;
- (void) raiseBaseline: (id)sender;
- (void) lowerBaseline: (id)sender;

/*************************** Ruler support ***************************/

- (void) setRulerVisible: (BOOL)flag;


- (void) rulerView: (NSRulerView *)ruler 
     didMoveMarker: (NSRulerMarker *)marker;
- (void) rulerView: (NSRulerView *)ruler 
   didRemoveMarker: (NSRulerMarker *)marker;
- (void) rulerView: (NSRulerView *)ruler 
      didAddMarker: (NSRulerMarker *)marker;
- (BOOL) rulerView: (NSRulerView *)ruler 
  shouldMoveMarker: (NSRulerMarker *)marker;
- (BOOL) rulerView: (NSRulerView *)ruler 
   shouldAddMarker: (NSRulerMarker *)marker;
- (float) rulerView: (NSRulerView *)ruler 
     willMoveMarker: (NSRulerMarker *)marker 
	 toLocation: (float)location;
- (BOOL) rulerView: (NSRulerView *)ruler 
shouldRemoveMarker: (NSRulerMarker *)marker;
- (float) rulerView: (NSRulerView *)ruler 
      willAddMarker: (NSRulerMarker *)marker 
	atLocation: (float)location;
- (void) rulerView: (NSRulerView *)ruler 
   handleMouseDown: (NSEvent *)event;

/*************************** Fine display control ***************************/

- (void) setNeedsDisplayInRect: (NSRect)rect
	 avoidAdditionalLayout: (BOOL)flag;

- (BOOL) shouldDrawInsertionPoint;
- (void) drawInsertionPointInRect: (NSRect)rect  color: (NSColor *)color 
			 turnedOn: (BOOL)flag;
- (void) cleanUpAfterDragOperation;

/*************************** Pasteboard management ***************************/
- (NSString *) preferredPasteboardTypeFromArray: (NSArray *)availableTypes 
                    restrictedToTypesFromArray: (NSArray *)allowedTypes;
- (BOOL) readSelectionFromPasteboard: (NSPasteboard *)pboard;
- (BOOL) readSelectionFromPasteboard: (NSPasteboard *)pboard 
				type: (NSString *)type;
- (NSArray *) readablePasteboardTypes;
- (NSArray *) writablePasteboardTypes;
- (BOOL) writeSelectionToPasteboard: (NSPasteboard *)pboard 
			       type: (NSString *)type;
- (BOOL) writeSelectionToPasteboard: (NSPasteboard *)pboard 
			      types: (NSArray *)types;

/*************************** Especially for subclassers ***************************/

- (void) updateRuler;
- (void) updateFontPanel;

- (NSArray *) acceptableDragTypes;
- (void) updateDragTypeRegistration;

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedCharRange 
			       granularity: (NSSelectionGranularity)gr;

@end

@interface NSTextView (NSSharing)

// The methods in this category deal with settings that need to be
// shared by all the GNUTextViews of a single NSLayoutManager.  Many
// of these methods are overrides of NSText or NSResponder methods.

/*************************** Selected/Marked range ***************************/

- (void) setSelectedRange: (NSRange)charRange 
		 affinity: (NSSelectionAffinity)affinity 
	   stillSelecting: (BOOL)stillSelectingFlag;
- (NSSelectionAffinity) selectionAffinity;
- (NSSelectionGranularity) selectionGranularity;
- (void) setSelectionGranularity: (NSSelectionGranularity)granularity;

- (void) setSelectedTextAttributes: (NSDictionary *)attributeDictionary;
- (NSDictionary *) selectedTextAttributes;

- (void) setInsertionPointColor: (NSColor *)color;
- (NSColor *) insertionPointColor;

- (void) updateInsertionPointStateAndRestartTimer: (BOOL)restartFlag;

- (NSRange) markedRange;

- (void) setMarkedTextAttributes: (NSDictionary *)attributeDictionary;
- (NSDictionary *) markedTextAttributes;

/*************************** Other GNUTextView methods ***************************/

- (void) setRulerVisible: (BOOL)flag;
- (BOOL) usesRuler;
- (void) setUsesRuler: (BOOL)flag;

- (int) spellCheckerDocumentTag;

- (NSDictionary *) typingAttributes;
- (void) setTypingAttributes: (NSDictionary *)attrs;

- (BOOL) shouldChangeTextInRange: (NSRange)affectedCharRange 
	       replacementString: (NSString *)replacementString;
- (void) didChangeText;

- (NSRange) rangeForUserTextChange;
- (NSRange) rangeForUserCharacterAttributeChange;
- (NSRange) rangeForUserParagraphAttributeChange;

- (BOOL) allowsUndo;
- (void) setAllowsUndo: (BOOL)flag;

/*************************** NSText methods ***************************/

- (BOOL) isSelectable;
- (void) setSelectable:(BOOL)flag;
- (BOOL) isEditable;
- (void) setEditable:(BOOL)flag;
- (BOOL) isRichText;
- (void) setRichText:(BOOL)flag;
- (BOOL) importsGraphics;
- (void) setImportsGraphics:(BOOL)flag;
- (id) delegate;
- (void) setDelegate:(id)anObject;
- (BOOL) isFieldEditor;
- (void) setFieldEditor:(BOOL)flag;
- (BOOL) usesFontPanel;
- (void) setUsesFontPanel:(BOOL)flag;
- (BOOL) isRulerVisible;
- (void) setBackgroundColor:(NSColor *)color;
- (NSColor *) backgroundColor;
- (void) setDrawsBackground:(BOOL)flag;
- (BOOL) drawsBackground;

- (NSRange) selectedRange;
- (void) setSelectedRange:(NSRange)charRange;

/*************************** NSResponder methods ***************************/

- (BOOL) resignFirstResponder;
- (BOOL) becomeFirstResponder;
- (id) validRequestorForSendType:(NSString *)sendType 
		      returnType:(NSString *)returnType;

/*************************** Smart copy/paste/delete support ***************************/

- (BOOL) smartInsertDeleteEnabled;
- (void) setSmartInsertDeleteEnabled: (BOOL)flag;
- (NSRange) smartDeleteRangeForProposedRange: (NSRange)proposedCharRange;
- (void) smartInsertForString: (NSString *)aString
	       replacingRange: (NSRange)charRange
		 beforeString: (NSString **)beforeString
		  afterString: (NSString **)afterString;
@end

@interface NSTextView (GSTextViewUpdateMultipleViews)
/*
 * This queries the NSLayoutManager to see if it is using multiple
 * text views, and saves this information in a flag, and caches the
 * first text view object.  The NSLayoutManager needs to call this
 * method to update this information. */
- (void) _updateMultipleTextViews;
@end

// Note that all delegation messages come from the first textView

@interface NSObject (NSTextViewDelegate)

- (void) textView: (NSTextView *)textView 
    clickedOnCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)cellFrame;
- (void) textView: (NSTextView *)textView 
    clickedOnCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)cellFrame
	  atIndex: (unsigned)charIndex;

- (BOOL) textView: (NSTextView *)textView  clickedOnLink: (id)link;
- (BOOL) textView: (NSTextView *)textView 
    clickedOnLink: (id)link 
	  atIndex: (unsigned)charIndex;

- (void) textView: (NSTextView *)textView 
doubleClickedOnCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)cellFrame;
- (void) textView: (NSTextView *)textView 
doubleClickedOnCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)cellFrame
	  atIndex: (unsigned)charIndex;

- (void) textView: (NSTextView *)view 
      draggedCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)rect event:(NSEvent *)event;
- (void) textView: (NSTextView *)view 
      draggedCell: (id <NSTextAttachmentCell>)cell 
	   inRect: (NSRect)rect 
	    event: (NSEvent *)event
	  atIndex: (unsigned)charIndex;

- (NSRange) textView: (NSTextView *)textView 
willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange 
    toCharacterRange: (NSRange)newSelectedCharRange;

- (void) textViewDidChangeSelection: (NSNotification *)notification;

- (BOOL) textView: (NSTextView *)textView 
shouldChangeTextInRange: (NSRange)affectedCharRange 
replacementString: (NSString *)replacementString;
// If characters are changing, replacementString is what will replace
// the affectedCharRange.  If attributes only are changing,
// replacementString will be nil.

- (BOOL) textView: (NSTextView *)textView 
doCommandBySelector: (SEL)commandSelector;

- (NSUndoManager *) undoManagerForTextView: (NSTextView *)view;
@end

extern NSString *NSTextViewWillChangeNotifyingTextViewNotification;
// NSOldNotifyingTextView -> the old view, NSNewNotifyingTextView ->
// the new view.  The text view delegate is not automatically
// registered to receive this notification because the text machinery
// will automatically switch over the delegate to observe the new
// first text view as the first text view changes.

extern NSString *NSTextViewDidChangeSelectionNotification;
extern NSString *NSOldSelectedCharacterRange;

#endif /* _GNUstep_H_NSTextView */

#if 0
NSFontAttributeName; /* NSFont, default Helvetica 12 */
->  NSParagraphStyleAttributeName; /* NSParagraphStyle, default defaultParagraphStyle */
NSForegroundColorAttributeName; /* NSColor, default blackColor */
NSUnderlineStyleAttributeName; /* int, default 0: no underline */
NSSuperscriptAttributeName; /* int, default 0 */
NSBackgroundColorAttributeName; /* NSColor, default nil: no background */
->  NSAttachmentAttributeName; /* NSTextAttachment, default nil */
NSLigatureAttributeName; /* int, default 1: default ligatures, 0: no ligatures, 2: all ligatures */
NSBaselineOffsetAttributeName; /* float, in points; offset from baseline, default 0 */
NSKernAttributeName; /* float, amount to modify default kerning, if 0, kerning off */
#endif

