/* 
   NSTextView.m

   Copyright (C) 1996, 1998, 2000 Free Software Foundation, Inc.

   Much of the code here is derived from code which was originally in
   NSText.m.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996

   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998

   Author: Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2000, September 2000

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

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
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSColorPanel.h>

#define HUGE 1e7

/* not the same as NSMakeRange! */
static inline
NSRange MakeRangeFromAbs (unsigned a1, unsigned a2)
{
  if (a1 < a2)
    return NSMakeRange (a1, a2 - a1);
  else
    return NSMakeRange (a2, a1 - a2);
}

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(text##notif_name: )]) \
    [nc addObserver: _delegate \
           selector: @selector(text##notif_name: ) \
               name: NSText##notif_name##Notification \
             object: _notifObject]

/*
 * Synchronizing flags.  Used to manage synchronizing shared
 * attributes between textviews coupled with the same layout manager.
 * These synchronizing flags are only accessed when
 * _tvf.multiple_textviews == YES and this can only happen if we have
 * a non-nil NSLayoutManager - so we don't check. */

/* YES when in the process of synchronizing text view attributes.  
   Used to avoid recursive synchronizations. */
#define IS_SYNCHRONIZING_FLAGS _layoutManager->_isSynchronizingFlags 
/* YES when in the process of synchronizing delegates.
   Used to avoid recursive synchronizations. */ 
#define IS_SYNCHRONIZING_DELEGATES _layoutManager->_isSynchronizingDelegates

/*
 * Began editing flag.  There are quite some different ways in which
 * editing can be started.  Each time editing is started, we need to check 
 * with the delegate if it is OK to start editing - but we need to check 
 * only once.  So, we use a flag.  */

static BOOL noLayoutManagerException ()
{
  [NSException raise: NSGenericException
	       format: @"Can't edit a NSTextView without a layout manager!"];
  return YES;
}

/* YES when editing has already began.  If NO, then we need to ask to
   the delegate for permission to begin editing before allowing any
   change to be made.  We explicitly check for a layout manager, and
   raise an exception if not found. */
#define BEGAN_EDITING \
(_layoutManager ? _layoutManager->_beganEditing : noLayoutManagerException ())
#define SET_BEGAN_EDITING(X) \
if (_layoutManager != nil) _layoutManager->_beganEditing = X

/* The shared notification center */
static NSNotificationCenter *nc;

@interface NSTextView (GNUstepPrivate)
/*
 * these NSLayoutManager- like methods are here only informally
 */
- (unsigned) characterIndexForPoint: (NSPoint)point;
- (NSRect) rectForCharacterRange: (NSRange)aRange;

/*
 * various GNU extensions
 */
+ (NSDictionary*) defaultTypingAttributes;

//
// GNU utility methods
//
- (void) setAttributes: (NSDictionary *) attributes  range: (NSRange) aRange;
- (void) _illegalMovement: (int) notNumber;
@end

@implementation NSTextView

/* Class methods */

+ (void) initialize
{
  if ([self class] == [NSTextView class])
    {
      [self setVersion: 1];
      nc = [NSNotificationCenter defaultCenter];
      [self registerForServices];
    }
}

+ (void) registerForServices
{
  NSArray *types;
      
  types  = [NSArray arrayWithObjects: NSStringPboardType, 
		    NSRTFPboardType, NSRTFDPboardType, nil];
 
  [[NSApplication sharedApplication] registerServicesMenuSendTypes: types
						       returnTypes: types];
}

/* Initializing Methods */

- (NSTextContainer*) buildUpTextNetwork: (NSSize)aSize;
{
  NSTextContainer *textContainer;
  NSLayoutManager *layoutManager;
  NSTextStorage *textStorage;

  textStorage = [[NSTextStorage alloc] init];

  layoutManager = [[NSLayoutManager alloc] init];
  /*
    [textStorage addLayoutManager: layoutManager];
    RELEASE (layoutManager);
  */

  textContainer = [[NSTextContainer alloc] initWithContainerSize: aSize];
  [layoutManager addTextContainer: textContainer];
  RELEASE (textContainer);

  /* FIXME: The following two lines should go *before* */
  [textStorage addLayoutManager: layoutManager];
  RELEASE (layoutManager);

  /* The situation at this point is as follows: 

     textView (us) --RETAINs--> textStorage 
     textStorage   --RETAINs--> layoutManager 
     layoutManager --RETAINs--> textContainer */

  /* We keep a flag to remember that we are directly responsible for 
     managing the text objects. */
  _tvf.owns_text_network = YES;

  return textContainer;
}

/* Designated initializer */
- (id) initWithFrame: (NSRect)frameRect
       textContainer: (NSTextContainer*)aTextContainer
{
  [super initWithFrame: frameRect];

  [self setMinSize: NSMakeSize (0, 0)];
  [self setMaxSize: NSMakeSize (HUGE,HUGE)];

  _tf.is_field_editor = NO;
  _tf.is_editable = YES;
  _tf.is_selectable = YES;
  _tf.is_rich_text = NO;
  _tf.imports_graphics = NO;
  _tf.draws_background = YES;
  _tf.is_horizontally_resizable = NO;
  _tf.is_vertically_resizable = NO;
  _tf.uses_font_panel = YES;
  _tf.uses_ruler = YES;
  _tf.is_ruler_visible = NO;
  _original_selected_range.location = NSNotFound;
  ASSIGN (_caret_color, [NSColor blackColor]); 
  [self setTypingAttributes: [isa defaultTypingAttributes]];

  [self setBackgroundColor: [NSColor textBackgroundColor]];

  //[self setSelectedRange: NSMakeRange (0, 0)];

  [aTextContainer setTextView: self];

  [self setEditable: YES];
  [self setUsesFontPanel: YES];
  [self setUsesRuler: YES];

  return self;
}

- (id) initWithFrame: (NSRect)frameRect
{
  NSTextContainer *aTextContainer;

  aTextContainer = [self buildUpTextNetwork: frameRect.size];

  self = [self initWithFrame: frameRect  textContainer: aTextContainer];

  /* At this point the situation is as follows: 

     textView (us)  --RETAINs--> textStorage
     textStorage    --RETAINs--> layoutManager 
     layoutManager  --RETAINs--> textContainer 
     textContainter --RETAINs --> textView (us) */

  /* The text system should be destroyed when the textView (us) is
     released.  To get this result, we send a RELEASE message to us
     breaking the RETAIN cycle. */
  RELEASE (self);

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
   BOOL flag;

  [super encodeWithCoder: aCoder];

  flag = _tvf.smart_insert_delete;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tvf.allows_undo;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  NSTextContainer *aTextContainer; 
  BOOL flag;

  self = [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tvf.smart_insert_delete = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tvf.allows_undo = flag;
  
  /* build up the rest of the text system, which doesn't get stored 
     <doesn't even implement the Coding protocol>. */
  aTextContainer = [self buildUpTextNetwork: _frame.size];
  [aTextContainer setTextView: (NSTextView*)self];
  /* See initWithFrame: for comments on this RELEASE */
  RELEASE (self);

  return self;
}

- (void)dealloc
{
  if (_tvf.owns_text_network == YES)
    {
      /* Prevent recursive dealloc */
      if (_tvf.is_in_dealloc == YES)
	{
	  return;
	}
      _tvf.is_in_dealloc = YES;
      /* This releases all the text objects (us included) in fall */
      RELEASE (_textStorage);
    }

  RELEASE (_selectedTextAttributes);
  RELEASE (_markedTextAttributes);
  RELEASE (_caret_color);
  RELEASE (_typingAttributes);

  [super dealloc];
}

/* 
 * Implementation of methods declared in superclass but depending 
 * on the internals of the NSTextView
 */
- (void) replaceCharactersInRange: (NSRange)aRange
		       withString: (NSString *)aString
{
  if (aRange.location == NSNotFound)
    return;

  if ([self shouldChangeTextInRange: aRange  
	    replacementString: aString] == NO)
    return; 
 
  [_textStorage beginEditing];
  [_textStorage replaceCharactersInRange: aRange  withString: aString];
  [_textStorage endEditing];
  [self didChangeText];
}

- (NSData*) RTFDFromRange: (NSRange)aRange
{
  return [_textStorage RTFDFromRange: aRange  documentAttributes: nil];
}

- (NSData*) RTFFromRange: (NSRange)aRange
{
  return [_textStorage RTFFromRange: aRange  documentAttributes: nil];
}

- (NSString *) string
{
  return [_textStorage string];
}

/*
 * [NSText] Managing the Ruler
 */
- (void) toggleRuler: (id)sender
{
  [self setRulerVisible: !_tf.is_ruler_visible];
}

/*
 * [NSText] Managing the Selected Range
 */
- (NSRange) selectedRange
{
  return _selected_range;
}

- (void) setSelectedRange: (NSRange)range
{
  [self setSelectedRange: range  affinity: [self selectionAffinity]
	stillSelecting: NO];
}

/*
 * [NSText] Copy and Paste
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

/* Copy the current font to the font pasteboard */
- (void) copyFont: (id)sender
{
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSFontPboard];

  [self writeSelectionToPasteboard: pb  type: NSFontPboardType];
}

/* Copy the current ruler settings to the ruler pasteboard */
- (void) copyRuler: (id)sender
{
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSRulerPboard];

  [self writeSelectionToPasteboard: pb  type: NSRulerPboardType];
}

- (void) delete: (id)sender
{
  [self deleteForward: sender];
}

- (void) paste: (id)sender
{
  [self readSelectionFromPasteboard: [NSPasteboard generalPasteboard]];
}

- (void) pasteFont: (id)sender
{
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSFontPboard];

  [self readSelectionFromPasteboard: pb  type: NSFontPboardType];
}

- (void) pasteRuler: (id)sender
{
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSRulerPboard];

  [self readSelectionFromPasteboard: pb  type: NSRulerPboardType];
}

/*
 * [NSText] Managing Fonts
 */
- (NSFont*) font
{
  if ([_textStorage length] > 0)
    {
      NSFont	*font;

      font = [_textStorage attribute: NSFontAttributeName
			     atIndex: 0
		      effectiveRange: NULL];
      if (font != nil)
	{
	  return font;
	}
    }

  return [_typingAttributes objectForKey: NSFontAttributeName];
}

- (void) changeFont: (id)sender
{
  NSRange foundRange;
  int maxSelRange;
  NSRange aRange= [self rangeForUserCharacterAttributeChange];
  NSRange searchRange = aRange;
  NSFont *font;

  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange  replacementString: nil])
    return;

  [_textStorage beginEditing];
  for (maxSelRange = NSMaxRange (aRange);
       searchRange.location < maxSelRange;
       searchRange = NSMakeRange (NSMaxRange (foundRange),
				  maxSelRange - NSMaxRange (foundRange)))
    {
      font = [_textStorage attribute: NSFontAttributeName
			   atIndex: searchRange.location
			   longestEffectiveRange: &foundRange
			   inRange: searchRange];
      if (font != nil)
	{
	  [self setFont: [sender convertFont: font]  ofRange: foundRange];
	}
    }
  [_textStorage endEditing];
  [self didChangeText];
  /* Set typing attributes */
  font = [_typingAttributes objectForKey: NSFontAttributeName];
  if (font != nil)
    {
      [_typingAttributes setObject: [sender convertFont: font] 
			 forKey: NSFontAttributeName];
    }
}

- (void) setFont: (NSFont*)font
{
  if (font == nil)
    {
      return;
    }
  
  [self setFont: font  ofRange: NSMakeRange (0, [_textStorage length])];
  [_typingAttributes setObject: font  forKey: NSFontAttributeName];
}

- (void) setFont: (NSFont*)font  ofRange: (NSRange)aRange
{
  if (font != nil)
    {
      if (![self shouldChangeTextInRange: aRange  replacementString: nil])
	return;

      [_textStorage beginEditing];
      [_textStorage addAttribute: NSFontAttributeName  value: font
		    range: aRange];
      [_textStorage endEditing];
      [self didChangeText];
    }
}

/*
 * [NSText] Managing Alignment
 */
- (NSTextAlignment) alignment
{
  unsigned location = 0;
  NSParagraphStyle *aStyle;

  if (_tf.is_rich_text)
    {
      location = [self rangeForUserParagraphAttributeChange].location;
    }
  
  if (location != NSNotFound)
    {
      aStyle = [_textStorage attribute: NSParagraphStyleAttributeName
			     atIndex: location
			     effectiveRange: NULL];
      if (aStyle != nil)
	{
	  return [aStyle alignment]; 
	}
    }

  /* Get alignment from typing attributes */
  return [[_typingAttributes objectForKey: NSParagraphStyleAttributeName] 
	   alignment];
}

- (void) setAlignment: (NSTextAlignment)mode
{
  [self setAlignment: mode  range: NSMakeRange (0, [_textStorage length])];
}

- (void) alignCenter: (id)sender
{
  [self setAlignment: NSCenterTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

- (void) alignLeft: (id)sender
{
  [self setAlignment: NSLeftTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

- (void) alignRight: (id)sender
{
  [self setAlignment: NSRightTextAlignment
	range: [self rangeForUserParagraphAttributeChange]];
}

/*
 * [NSText] Managing Text Color
 */
- (NSColor*) textColor
{
  if ([_textStorage length] > 0)
    {
      NSColor	*color;

      color = [_textStorage attribute: NSForegroundColorAttributeName
			      atIndex: 0
		       effectiveRange: NULL];
      if (color != nil)
	{
	  return color;
	}
    }
  return [_typingAttributes objectForKey: NSForegroundColorAttributeName];
}

- (void) setTextColor: (NSColor*)color
{
  /* FIXME: This should work also for non rich text objects */
  NSRange fullRange = NSMakeRange (0, [_textStorage length]);

  [self setTextColor: color  range: fullRange];
}

- (void) setTextColor: (NSColor*)color  range: (NSRange)aRange
{
  /* FIXME: This should only work for rich text object */
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
      [_typingAttributes setObject: color 
			 forKey: NSForegroundColorAttributeName];
    }
  else
    {
      [_textStorage removeAttribute: NSForegroundColorAttributeName
		    range: aRange];
    }
  [_textStorage endEditing];
  [self didChangeText];
}

/*
 * [NSText] Text Attributes
 */
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

/*
 * [NSText] Reading and Writing RTFD files
 */
- (BOOL) readRTFDFromFile: (NSString*)path
{
  NSAttributedString *peek;

  peek = [[NSAttributedString alloc] initWithPath: path 
				     documentAttributes: NULL];
  if (peek != nil)
    {
      if (!_tf.is_rich_text)
	{
	  [self setRichText: YES];
	}
      [self replaceRange: NSMakeRange (0, [_textStorage length])
	    withAttributedString: peek];
      RELEASE(peek);
      return YES;
    }
  return NO;
}

- (BOOL) writeRTFDToFile: (NSString*)path  atomically: (BOOL)flag
{
  NSFileWrapper *wrapper;
  NSRange range = NSMakeRange (0, [_textStorage length]);
  
  wrapper = [_textStorage RTFDFileWrapperFromRange: range  
			  documentAttributes: nil];
  return [wrapper writeToFile: path  atomically: flag  updateFilenames: YES];
}

/*
 * [NSText] Managing size
 */
- (void) setHorizontallyResizable: (BOOL)flag
{
  /* Safety call */
  [_textContainer setWidthTracksTextView: !flag];

  [super setHorizontallyResizable: flag];
}

- (void) setVerticallyResizable: (BOOL)flag
{
  /* Safety call */
  [_textContainer setHeightTracksTextView: !flag];

  [super setVerticallyResizable: flag];
}

- (void) sizeToFit
{
  if (_tf.is_horizontally_resizable || _tf.is_vertically_resizable)
    {
      NSSize size;
      
      size = [_layoutManager usedRectForTextContainer: _textContainer].size;
      size.width  += 2 * _textContainerInset.width;
      size.height += 2 * _textContainerInset.height;

      [self setConstrainedFrameSize: size];
    }
}

/*
 * [NSText] Spelling
 */
- (void) checkSpelling: (id)sender
{
  NSSpellChecker *sp = [NSSpellChecker sharedSpellChecker];

  NSRange errorRange;

  errorRange = [sp checkSpellingOfString: [_textStorage string]
		   startingAt: NSMaxRange (_selected_range)];
  
  if (errorRange.length)
    {
      [self setSelectedRange: errorRange];
    }
  else
    {
      NSBeep();
    }
}

- (void) changeSpelling: (id)sender
{
  /* FIXME: Replace, not insert */
  [self insertText: [[(NSControl*)sender selectedCell] stringValue]];
}

- (void) ignoreSpelling: (id)sender
{
  NSSpellChecker *sp = [NSSpellChecker sharedSpellChecker];

  [sp ignoreWord: [[(NSControl*)sender selectedCell] stringValue]
      inSpellDocumentWithTag: [self spellCheckerDocumentTag]];
}

/*
 * [NSText] Scrolling
 */
- (void) scrollRangeToVisible: (NSRange)aRange
{
  // Don't try scrolling an ancestor clipview if we are field editor.
  // This makes things so much simpler and stabler for now.
  if (_tf.is_field_editor == NO)
    {
      [self scrollRectToVisible: [self rectForCharacterRange: aRange]];
    }
}

/*
 * [NSResponder] Handle enabling/disabling of services menu items.
 */
- (id) validRequestorForSendType: (NSString*)sendType
		      returnType: (NSString*)returnType
{
  BOOL sendOK = NO;
  BOOL returnOK = NO;

  if (sendType == nil)
    {
      sendOK = YES;
    }
  else if (_selected_range.length && [sendType isEqual: NSStringPboardType])
    {
      sendOK = YES;
    }

  if (returnType == nil)
    {
      returnOK = YES;
    }
  else if (_tf.is_editable && [returnType isEqual: NSStringPboardType])
    {
      returnOK = YES;
    }

  if (sendOK && returnOK)
    {
      return self;
    }

  return [super validRequestorForSendType: sendType  returnType: returnType];
}

/* 
 *  NSTextView's specific methods 
 */

- (void) _updateMultipleTextViews
{
  id oldNotifObject = _notifObject;

  if ([[_layoutManager textContainers] count] > 1)
    {
      _tvf.multiple_textviews = YES;
      _notifObject = [_layoutManager firstTextView];
    }
  else
    {
      _tvf.multiple_textviews = NO;
      _notifObject = self;
    }  

  if ((_delegate != nil) && (oldNotifObject != _notifObject))
    {
      [nc removeObserver: _delegate  name: nil  object: oldNotifObject];

      if ([_delegate respondsToSelector: 
		       @selector(shouldChangeTextInRange:replacementString:)])
	{
	  _tvf.delegate_responds_to_should_change = YES;
	}
      else
	{
	  _tvf.delegate_responds_to_should_change = NO;
	}

      /* SET_DELEGATE_NOTIFICATION defined at the beginning of file */

      /* NSText notifications */
      SET_DELEGATE_NOTIFICATION (DidBeginEditing);
      SET_DELEGATE_NOTIFICATION (DidChange);
      SET_DELEGATE_NOTIFICATION (DidEndEditing);
      /* NSTextView notifications */
      SET_DELEGATE_NOTIFICATION (ViewDidChangeSelection);
      SET_DELEGATE_NOTIFICATION (ViewWillChangeNotifyingTextView);
    }
}

/* This should only be called by [NSTextContainer -setTextView:] */
- (void) setTextContainer: (NSTextContainer*)aTextContainer
{
  _textContainer = aTextContainer;
  _layoutManager = [aTextContainer layoutManager];
  _textStorage = [_layoutManager textStorage];

  [self _updateMultipleTextViews];
}

- (void) replaceTextContainer: (NSTextContainer*)aTextContainer
{
  /* FIXME/TODO: Tell the layout manager the text container is changed
     keeping all the rest intact */

  /* Do not retain: text container is owning us. */
  _textContainer = aTextContainer;

  [self _updateMultipleTextViews];
}

- (NSTextContainer *) textContainer
{
  return _textContainer;
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
  NSRect usedRect;
  NSSize textContainerSize;

  usedRect = [_layoutManager usedRectForTextContainer: _textContainer];
  textContainerSize = [_textContainer containerSize];
  
  /* The `text container origin' is - I think - the origin of the used
     rect, but relative to our own coordinate system (used rect as
     returned by [NSLayoutManager -usedRectForTextContainer:] is
     instead relative to the text container coordinate system).  This
     information is used when we ask the layout manager to draw - the
     base point is precisely this `text container origin', which is
     the origin of the used rect in our own coordinate system. */
  
  /* First get the pure text container origin */
  _textContainerOrigin.x = NSMinX (_bounds);
  _textContainerOrigin.x += _textContainerInset.width;
  /* Then move to the used rect origin */
  _textContainerOrigin.x += usedRect.origin.x;
  
  /* First get the pure text container origin */
  _textContainerOrigin.y = NSMaxY (_bounds);
  _textContainerOrigin.y -= _textContainerInset.height;
  _textContainerOrigin.y -= textContainerSize.height;
  /* Then move to the used rect origin */
  _textContainerOrigin.y += usedRect.origin.y;
}

- (NSLayoutManager*) layoutManager
{
  return _layoutManager;
}

- (NSTextStorage*) textStorage
{
  return _textStorage;
}

- (void) setAllowsUndo: (BOOL)flag
{
  _tvf.allows_undo = flag;
}

- (BOOL) allowsUndo
{
  return _tvf.allows_undo;
}

- (void) setNeedsDisplayInRect: (NSRect)aRect
	 avoidAdditionalLayout: (BOOL)flag
{
  /* FIXME: This is here until the layout manager is working */
  /* This is very important */
  [super setNeedsDisplayInRect: aRect];
}

/* We override NSView's setNeedsDisplayInRect: */

- (void) setNeedsDisplayInRect: (NSRect)aRect
{
  [self setNeedsDisplayInRect: aRect  avoidAdditionalLayout: NO];
}

- (BOOL) shouldDrawInsertionPoint
{
  return (_selected_range.length == 0) && _tf.is_editable
    && [_window isKeyWindow];
}

/*
 * It only makes real sense to call this method with `flag == YES'.
 * If you want to delete the insertion point, what you want is rather
 * to redraw what was under the insertion point - which can't be done
 * here - you need to set the rect as needing redisplay (without
 * additional layout) instead.  NB: You need to flush the window after
 * calling this method if you want the insertion point to appear on
 * the screen immediately.  This could only be needed to implement
 * blinking insertion point - but even there, it could probably be
 * done without. */
- (void) drawInsertionPointInRect: (NSRect)rect
			    color: (NSColor*)color
			 turnedOn: (BOOL)flag
{
  if (_window == nil)
    {
      return;
    }

  if (flag)
    {
      if (color == nil)
	color = _caret_color;

      [color set];
      NSRectFill (rect);
    }
  else
    {
      [_background_color set];
      NSRectFill (rect);
    }
}

- (void) setConstrainedFrameSize: (NSSize)desiredSize
{
  NSSize newSize;

  if (_tf.is_horizontally_resizable)
    {
      newSize.width = desiredSize.width;
      newSize.width = MAX (newSize.width, _minSize.width);
      newSize.width = MIN (newSize.width, _maxSize.width);
    }
  else
    {
      newSize.width  = _frame.size.width;
    }

  if (_tf.is_vertically_resizable)
    {
      newSize.height = desiredSize.height;
      newSize.height = MAX (newSize.height, _minSize.height);
      newSize.height = MIN (newSize.height, _maxSize.height);
    }
  else
    {
      newSize.height = _frame.size.height;
    }
  
  if (NSEqualSizes (_frame.size, newSize) == NO)
    {
      [self setFrameSize: newSize];
    }
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

/* 
 * Code to share settings between multiple textviews
 *
 */

/* 
   _syncTextViewsCalling:withFlag: calls a set method on all text
   views sharing the same layout manager as this one.  It sets the
   IS_SYNCHRONIZING_FLAGS flag to YES to prevent recursive calls;
   calls the specified action on all the textviews (this one included)
   with the specified flag; sets back the IS_SYNCHRONIZING_FLAGS flag
   to NO; then returns.

   We need to explicitly call the methods - we can't copy the flags
   directly from one textview to another, to allow subclasses to
   override eg setEditable: to take some particular action when
   editing is turned on or off. */
- (void) _syncTextViewsByCalling: (SEL)action  withFlag: (BOOL)flag
{
  NSArray *array;
  int i, count;
  void (*msg)(id, SEL, BOOL);

  if (IS_SYNCHRONIZING_FLAGS == YES)
    {
      [NSException raise: NSGenericException
		   format: @"_syncTextViewsCalling:withFlag: "
		   @"called recursively"];
    }

  array = [_layoutManager textContainers];
  count = [array count];

  msg = (void (*)(id, SEL, BOOL))[self methodForSelector: action];

  if (!msg)
    {
      [NSException raise: NSGenericException
		   format: @"invalid selector in "
		   @"_syncTextViewsCalling:withFlag:"];
    }

  IS_SYNCHRONIZING_FLAGS = YES;

  for (i = 0; i < count; i++)
    {
      NSTextView *tv; 

      tv = [(NSTextContainer *)[array objectAtIndex: i] textView];
      (*msg) (tv, action, flag);
    }

  IS_SYNCHRONIZING_FLAGS = NO;
}

#define NSTEXTVIEW_SYNC(X) \
  if (_tvf.multiple_textviews && (IS_SYNCHRONIZING_FLAGS == NO)) \
    {  [self _syncTextViewsByCalling: X  withFlag: flag]; \
    return; }

/*
 * NB: You might override these methods in subclasses, as in the 
 * following example: 
 * - (void) setEditable: (BOOL)flag
 * {
 *   [super setEditable: flag];
 *   XXX your custom code here XXX
 * }
 * 
 * If you override them in this way, they are automatically
 * synchronized between multiple textviews - ie, when it is called on
 * one, it will be automatically called on all related textviews.
 * */

- (void) setEditable: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setEditable:));
  [super setEditable: flag];
  /* FIXME/TODO: Update/show the insertion point */
}

- (void) setFieldEditor: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setFieldEditor:));
  [self setHorizontallyResizable: NO];
  [self setVerticallyResizable: NO];
  [super setFieldEditor: flag];
}

- (void) setSelectable: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setSelectable:));
  [super setSelectable: flag];
}

- (void) setRichText: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setRichText:));

  [super setRichText: flag];
  [self updateDragTypeRegistration];
  /* FIXME/TODO: Also convert text to plain text or to rich text */
}

- (void) setImportsGraphics: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setImportsGraphics:));

  [super setImportsGraphics: flag];
  [self updateDragTypeRegistration];
}

- (void) setUsesRuler: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setUsesRuler:));
  _tf.uses_ruler = flag;
}

- (BOOL) usesRuler
{
  return _tf.uses_ruler;
}

- (void) setUsesFontPanel: (BOOL)flag
{
  NSTEXTVIEW_SYNC (@selector(setUsesFontPanel:));
  [super setUsesFontPanel: flag];
}

- (void) setRulerVisible: (BOOL)flag
{
  NSScrollView *sv;

  NSTEXTVIEW_SYNC (@selector(setRulerVisible:));

  sv = [self enclosingScrollView];
  _tf.is_ruler_visible = flag;
  if (sv != nil)
    {
      [sv setRulersVisible: _tf.is_ruler_visible];
    }
}

#undef NSTEXTVIEW_SYNC

/* NB: Only NSSelectionAffinityDownstream works */
- (void) setSelectedRange: (NSRange)range
		 affinity: (NSSelectionAffinity)affinity
	   stillSelecting: (BOOL)flag
{
  /* The `official' (the last one the delegate approved of) selected
     range before this one. */
  NSRange oldRange;
  /* If the user was interactively changing the selection, the last
     displayed selection could have been a temporary selection,
     different from the last official one: */
  NSRange oldDisplayedRange = _selected_range;

  if (flag == YES)
    {
      /* Store the original range before the interactive selection
         process begin.  That's because we will need to ask the delegate 
	 if it's all right for him to do the change, and then notify 
	 him we did.  In both cases, we need to post the original selection 
	 together with the new one. */
      if (_original_selected_range.location == NSNotFound)
	{
	  _original_selected_range = _selected_range;
	}
    }
  else 
    {
      /* Retrieve the original range */
      if (_original_selected_range.location != NSNotFound)
	{
	  oldRange = _original_selected_range;
	  _original_selected_range.location = NSNotFound;
	}
      else
	{
	  oldRange = _selected_range;
	}
      
      /* Ask delegate to modify the range */
      if (_tvf.delegate_responds_to_will_change_sel)
	{
	  range = [_delegate textView: _notifObject
			     willChangeSelectionFromCharacterRange: oldRange
			     toCharacterRange: range];
	}
    }

  /* Set the new selected range */
  _selected_range = range;

  /* FIXME: when and if to restart timer <and where to stop it before> */
  [self updateInsertionPointStateAndRestartTimer: !flag];

  if (flag == NO)
    {
      [self updateFontPanel];
      
      /* Insertion Point */
      if (range.length)
	{
	  /* <!>disable caret timed entry */
	}
      else  /* no selection, only insertion point */
	{
	  if (_tf.is_rich_text)
	    {
	      NSDictionary *dict;
	      
	      if (range.location > 0)
		{
		  /* If the insertion point is after a bold word, for
		     example, we need to use bold for further
		     insertions - this is why we take the attributes
		     from range.location - 1. */
		  dict = [_textStorage attributesAtIndex: (range.location - 1)
				       effectiveRange: NULL];
		}
	      else
		{
		  /* Unless we are at the beginning of text - we use the 
		     first valid attributes then */
		  dict = [_textStorage attributesAtIndex: range.location
				       effectiveRange: NULL];
		}
	      [self setTypingAttributes: dict];
	    }
	}
    }

  if (_window != nil)
    {
      NSRange overlap;

      if (flag == NO)
	{
	  /* Make the selected range visible */
	  [self scrollRangeToVisible: range]; 
	}

      /* Try to optimize for overlapping ranges */
      overlap = NSIntersectionRange (oldRange, range);
      if (overlap.length)
	{
	  if (range.location != oldDisplayedRange.location)
	    {
	      NSRange r;
	      r = MakeRangeFromAbs (MIN (range.location, 
					 oldDisplayedRange.location),
				    MAX (range.location, 
					 oldDisplayedRange.location));
	      [self setNeedsDisplayInRect: [self rectForCharacterRange: r]
		    avoidAdditionalLayout: YES];
	    }
	  if (NSMaxRange (range) != NSMaxRange (oldDisplayedRange))
	    {
	      NSRange r;

	      r = MakeRangeFromAbs (MIN (NSMaxRange (range), 
					 NSMaxRange (oldDisplayedRange)),
				    MAX (NSMaxRange (range),
					 NSMaxRange (oldDisplayedRange)));
	      [self setNeedsDisplayInRect: [self rectForCharacterRange: r]
		    avoidAdditionalLayout: YES];
	    }
	}
      else
	{
	  [self setNeedsDisplayInRect: [self rectForCharacterRange: range]
		avoidAdditionalLayout: YES];
	  [self setNeedsDisplayInRect: [self rectForCharacterRange: 
					       oldDisplayedRange]
		avoidAdditionalLayout: YES];
	}
    }
  
  [self setSelectionGranularity: NSSelectByCharacter];
  
  /* TODO: Remove the marking from marked text if the new selection is
     greater than the marked region. */
  
  if (flag == NO)
    {
      NSDictionary *userInfo;

      userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				 [NSValue valueWithBytes: &oldRange 
					  objCType: @encode(NSRange)],
			       NSOldSelectedCharacterRange, nil];
       
      [nc postNotificationName: NSTextViewDidChangeSelectionNotification
	  object: _notifObject  userInfo: userInfo];
    }
}

- (NSSelectionAffinity) selectionAffinity 
{ 
  return NSSelectionAffinityDownstream;
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
  ASSIGN (_caret_color, aColor);
}

- (NSColor*) insertionPointColor
{
  return _caret_color;
}

- (void) updateInsertionPointStateAndRestartTimer: (BOOL)flag
{
  /* Update insertion point rect */
  NSRange charRange;
  NSRange glyphRange;
  unsigned glyphIndex;
  NSRect rect;

  /* Simple case - no insertion point */
  if ((_selected_range.length > 0) || _selected_range.location == NSNotFound)
    {
      _insertionPointRect = NSZeroRect;
      
      /* FIXME: horizontal position of insertion point */
      _originalInsertPoint = 0;
      return;
    }

  charRange = NSMakeRange (_selected_range.location, 1);
  glyphRange = [_layoutManager glyphRangeForCharacterRange: charRange 
			       actualCharacterRange: NULL];
  glyphIndex = glyphRange.location;
  
  rect = [_layoutManager lineFragmentRectForGlyphAtIndex: glyphIndex 
			 effectiveRange: NULL];
  
  if ([self selectionAffinity] != NSSelectionAffinityUpstream)
    {
      /* Standard case - draw the insertion point just before the
	 associated glyph index */
      NSPoint loc = [_layoutManager locationForGlyphAtIndex: glyphIndex];
      
      rect.origin.x += loc.x;      
    }
  else /* _affinity == NSSelectionAffinityUpstream - non standard */
    {
      /* FIXME - THIS DOES NOT WORK - as a consequence,
         NSSelectionAffinityUpstream DOES NOT WORK */

      /* Check - if the previous glyph is on another line */
      
      /* FIXME: Don't know how to do this check, this is a hack and
         DOES NOT WORK - clearly this code should be inside the layout
         manager anyway */
      NSRect rect2;
      
      rect2 = [_layoutManager lineFragmentRectForGlyphAtIndex: glyphIndex - 1
			      effectiveRange: NULL];
      if (NSMinY (rect2) < NSMinY (rect))
	{
	  /* Then we need to draw the insertion point just after the
             previous glyph - DOES NOT WORK */
	  glyphRange = NSMakeRange (glyphIndex - 1, 1);
	  rect = [_layoutManager boundingRectForGlyphRange: glyphRange
				 inTextContainer:_textContainer];
	  rect.origin.x = NSMaxX (rect) - 1;
	}
      else /* Else, standard case again */
	{
	  NSPoint loc = [_layoutManager locationForGlyphAtIndex: glyphIndex];
	  rect.origin.x += loc.x;	  
	}
    }

  rect.size.width = 1;
  
  if (rect.size.height == 0)
    {
      rect.size.height = 12;
    }  

  _insertionPointRect = rect;

  
  /* Remember horizontal position of insertion point */
  _originalInsertPoint = _insertionPointRect.origin.x;

  if (flag)
    {
      /* TODO: Restart blinking timer */
    }
}

- (void) setSelectedTextAttributes: (NSDictionary *)attributes
{
  ASSIGN (_selectedTextAttributes, attributes);
}

- (NSDictionary *) selectedTextAttributes
{
  return _selectedTextAttributes;
}

- (NSRange) markedRange
{
  // calculate

  return NSMakeRange (NSNotFound, 0);
}

- (void) setMarkedTextAttributes: (NSDictionary*)attributes
{
  ASSIGN (_markedTextAttributes, attributes);
}

- (NSDictionary*) markedTextAttributes
{
  return _markedTextAttributes;
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
  [self setTextColor: aColor  range: aRange];
}

- (void) setAlignment: (NSTextAlignment)alignment  range: (NSRange)aRange
{ 
  NSParagraphStyle *style;
  NSMutableParagraphStyle *mstyle;
  
  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange  replacementString: nil])
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
				     attributes: _typingAttributes])];
    }
  else
    {      
      [self replaceCharactersInRange: insertRange
	    withString: insertString];
    }

  // move cursor <!> [self selectionRangeForProposedRange: ]
  [self setSelectedRange:
	  NSMakeRange (insertRange.location + [insertString length], 0)];
}

- (void) setTypingAttributes: (NSDictionary*)dict
{
  if (dict == nil)
    {
      dict = [isa defaultTypingAttributes];
    }

  if ([dict isKindOfClass: [NSMutableDictionary class]] == NO)
    {
      RELEASE (_typingAttributes);
      _typingAttributes = [[NSMutableDictionary alloc] 
			    initWithDictionary: dict];
    }
  else
    {
      ASSIGN (_typingAttributes, (NSMutableDictionary*)dict);
    }
  [self updateFontPanel];
  [self updateRuler];
}

- (NSDictionary*) typingAttributes
{
  return [NSDictionary dictionaryWithDictionary: _typingAttributes];
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

/* Notifies the delegate that the user clicked in a link at the
   specified charIndex. The delegate may take any appropriate actions
   to handle the click in its textView: clickedOnLink: atIndex:
   method. */
  if (_delegate != nil && 
      [_delegate respondsToSelector: 
		   @selector(textView:clickedOnLink:atIndex:)])
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
  /* Update fontPanel only if told so */
  if (_tf.uses_font_panel)
    {
      NSRange longestRange;
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSFont *currentFont;

      if (_selected_range.length > 0) /* Multiple chars selection */
	{
	  currentFont = [_textStorage attribute: NSFontAttributeName
				      atIndex: _selected_range.location
				      longestEffectiveRange: &longestRange
				      inRange: _selected_range];
	  [fm setSelectedFont: currentFont
	      isMultiple: !NSEqualRanges (longestRange, _selected_range)];
	}
      else /* Just Insertion Point. */ 
	{
	  currentFont = [_typingAttributes objectForKey: NSFontAttributeName];
	  [fm setSelectedFont: currentFont  isMultiple: NO];
	}
    }
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

- (BOOL) shouldChangeTextInRange: (NSRange)affectedCharRange
	       replacementString: (NSString*)replacementString
{
  if (BEGAN_EDITING == NO)
    {
      if (([_delegate respondsToSelector: @selector(textShouldBeginEditing:)])
	  && ([_delegate textShouldBeginEditing: _notifObject] == NO))
	return NO;
      
      SET_BEGAN_EDITING (YES);
      
      [nc postNotificationName: NSTextDidBeginEditingNotification  
	  object: _notifObject];
    }

  if (_tvf.delegate_responds_to_should_change)
    {
      return [_delegate shouldChangeTextInRange: affectedCharRange 
			replacementString: replacementString];
    }

  return YES;
}

- (void) didChangeText
{
  [nc postNotificationName: NSTextDidChangeNotification  
      object: _notifObject];
}

- (void) setSmartInsertDeleteEnabled: (BOOL)flag
{
  _tvf.smart_insert_delete = flag;
}

- (BOOL) smartInsertDeleteEnabled
{
  return _tvf.smart_insert_delete;
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

/*
 * Handling Events
 */
- (void) mouseDown: (NSEvent*)theEvent
{
  NSSelectionAffinity affinity = [self selectionAffinity];
  NSSelectionGranularity granularity = NSSelectByCharacter;
  NSRange chosenRange, proposedRange;
  NSPoint point, startPoint;
  NSEvent *currentEvent;
  unsigned startIndex;
  unsigned mask;

  /* If non selectable then ignore the mouse down. */
  if (_tf.is_selectable == NO)
    {
      return;
    }

  /* Otherwise, NSWindow has already made us first responder (if
     possible) */

  startPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  startIndex = [self characterIndexForPoint: startPoint];

  if (_tf.imports_graphics == YES)
    {
      NSTextAttachment *attachment;
      
      // Check if the click was on an attachment cell
      attachment = [_textStorage attribute: NSAttachmentAttributeName
				 atIndex: startIndex
				 effectiveRange: NULL];

      if (attachment != nil)
        { 
	  id <NSTextAttachmentCell> cell = [attachment attachmentCell];
	  // FIXME: Where to get the cellFrame?
	  NSRect cellFrame = NSMakeRect(0, 0, 0, 0);
	  
	  if ((cell != nil) &&
	      ([cell wantsToTrackMouseForEvent: theEvent 
		     inRect: cellFrame
		     ofView: self
		     atCharacterIndex: startIndex] == YES) &&
	      ([cell trackMouse: theEvent 
		     inRect: cellFrame 
		     ofView: self
		     atCharacterIndex: startIndex
		     untilMouseUp: NO] == YES))
	      return;
	}
    }

  if ([theEvent modifierFlags] & NSShiftKeyMask)
    {
      /* Shift-click is for extending an existing selection using 
	 the existing granularity */
      granularity = _selectionGranularity;
      /* Compute the new selection */
      proposedRange = NSMakeRange (startIndex, 0);
      proposedRange = NSUnionRange (_selected_range, proposedRange);
      proposedRange = [self selectionRangeForProposedRange: proposedRange
			    granularity: granularity];
      /* Merge it with the old one */
      proposedRange = NSUnionRange (_selected_range, proposedRange);
      /* Now decide what happens if the user shift-drags.  The range 
	 will be based in startIndex, so we need to adjust it. */
      if (startIndex <= _selected_range.location) 
	{
	  startIndex = NSMaxRange (proposedRange);
	}
      else 
	{
	  startIndex = proposedRange.location;
	}
    }
  else /* No shift */
    {
      switch ([theEvent clickCount])
	{
	case 1: granularity = NSSelectByCharacter;
	  break;
	case 2: granularity = NSSelectByWord;
	  break;
	case 3: granularity = NSSelectByParagraph;
	  break;
	}
      proposedRange = NSMakeRange (startIndex, 0);
    }

  chosenRange = [self selectionRangeForProposedRange: proposedRange
		      granularity: granularity];
  [self setSelectedRange: chosenRange  affinity: affinity  
	stillSelecting: YES];

  /* Do an immediate redisplay for visual feedback */
  [_window flushWindow]; /* FIXME: This doesn't work while it should ! */

  /* Enter modal loop tracking the mouse */
  
  mask = NSLeftMouseDraggedMask | NSLeftMouseUpMask;
  
  for (currentEvent = [_window nextEventMatchingMask: mask];
       [currentEvent type] != NSLeftMouseUp;
       currentEvent = [_window nextEventMatchingMask: mask])
    {
      BOOL didScroll = [self autoscroll: currentEvent];

      point = [self convertPoint: [currentEvent locationInWindow]
		    fromView: nil];
      proposedRange = MakeRangeFromAbs ([self characterIndexForPoint: point],
					startIndex);
      chosenRange = [self selectionRangeForProposedRange: proposedRange
			  granularity: granularity];
      [self setSelectedRange: chosenRange  affinity: affinity  
	    stillSelecting: YES];

      if (didScroll)
	{
	  /* FIXME: Only redisplay where needed, and avoid relayout */
	  [self setNeedsDisplay: YES];
	}
      
      /* Do an immediate redisplay for visual feedback */
      [_window flushWindow];
    }

  NSDebugLog(@"chosenRange. location  = %d, length  = %d\n",
	     (int)chosenRange.location, (int)chosenRange.length);

  [self setSelectedRange: chosenRange  affinity: affinity  
	stillSelecting: NO];

  /* Ahm - this shouldn't really be needed but... */
  [_window flushWindow];

  /* Remember granularity till a new selection destroys the memory */
  [self setSelectionGranularity: granularity];
}

- (void) keyDown: (NSEvent*)theEvent
{
  // If not editable, don't recognize the key down
  if (_tf.is_editable == NO)
    {
      [super keyDown: theEvent];
    }
  else
    {
      [self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
    }
}

- (void) insertNewline: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSReturnTextMovement];
      return;
    }

  [self insertText: @"\n"];
}

- (void) insertTab: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSTabTextMovement];
      return;
    }

  [self insertText: @"\t"];
}

- (void) insertBacktab: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSBacktabTextMovement];
      return;
    }

  //[self insertText: @"\t"];
}

- (void) deleteForward: (id)sender
{
  NSRange range = [self rangeForUserTextChange];
  
  if (range.location == NSNotFound)
    {
      return;
    }
  
  /* Manage case of insertion point - implicitly means to delete following 
     character */
  if (range.length == 0)
    {
      if (range.location != [_textStorage length])
	{
	  /* Not at the end of text -- delete following character */
	  range.length = 1;
	}
      else
	{
	  /* At the end of text - TODO: Make beeping or not beeping
	     configurable vie User Defaults */
	  NSBeep ();
	  return;
	}
    }
  
  if (![self shouldChangeTextInRange: range  replacementString: @""])
    {
      return;
    }

  [_textStorage beginEditing];
  [_textStorage deleteCharactersInRange: range];
  [_textStorage endEditing];
  [self didChangeText];

  /* The new selected range is just the insertion point at the beginning 
     of deleted range */
  [self setSelectedRange: NSMakeRange (range.location, 0)];
}

- (void) deleteBackward: (id)sender
{
  NSRange range = [self rangeForUserTextChange];
  
  if (range.location == NSNotFound)
    {
      return;
    }
  
  /* Manage case of insertion point - implicitly means to delete
     previous character */
  if (range.length == 0)
    {
      if (range.location != 0)
	{
	  /* Not at the beginning of text -- delete previous character */
	  range.location -= 1;
	  range.length = 1;
	}
      else
	{
	  /* At the beginning of text - TODO: Make beeping or not
	     beeping configurable vie User Defaults */
	  NSBeep ();
	  return;
	}
    }
  
  if (![self shouldChangeTextInRange: range  replacementString: @""])
    {
      return;
    }

  [_textStorage beginEditing];
  [_textStorage deleteCharactersInRange: range];
  [_textStorage endEditing];
  [self didChangeText];

  /* The new selected range is just the insertion point at the beginning 
     of deleted range */
  [self setSelectedRange: NSMakeRange (range.location, 0)];
}

- (void) moveUp: (id)sender
{
  float originalInsertionPoint;
  float startingY;
  unsigned newLocation;

  if (_tf.is_field_editor)
    return;
  
  /* Do nothing if we are at beginning of text */
  if (_selected_range.location == 0)
    {
      return;
    }
  
  /* Read from memory the horizontal position we aim to move the cursor 
     at on the next line */
  originalInsertionPoint = _originalInsertPoint;

  /* Ask the layout manager to compute where to go */
  startingY = NSMidY (_insertionPointRect);
  newLocation = [_layoutManager 
		  _charIndexForInsertionPointMovingFromY: startingY
		  bestX: originalInsertionPoint
		  up: YES 
		  textContainer: _textContainer];

  /* Move the insertion point */
  [self setSelectedRange: NSMakeRange (newLocation, 0)];

  /* Restore the _originalInsertPoint (which was changed
     by setSelectedRange:) because we don't want it to change between
     moveUp:/moveDown: operations. */
  _originalInsertPoint = originalInsertionPoint;
}

- (void) moveDown: (id)sender
{
  float originalInsertionPoint;
  float startingY;
  unsigned newLocation;

  if (_tf.is_field_editor)
    return;

  /* Do nothing if we are at end of text */
  if (_selected_range.location == [_textStorage length])
    {
      return;
    }

  /* Read from memory the horizontal position we aim to move the cursor 
     at on the next line */
  originalInsertionPoint = _originalInsertPoint;

  /* Ask the layout manager to compute where to go */
  startingY = NSMidY (_insertionPointRect);
  newLocation = [_layoutManager 
		  _charIndexForInsertionPointMovingFromY: startingY
		  bestX: originalInsertionPoint
		  up: NO
		  textContainer: _textContainer];

  /* Move the insertion point */
  [self setSelectedRange: NSMakeRange (newLocation, 0)];

  /* Restore the _originalInsertPoint (which was changed
     by setSelectedRange:) because we don't want it to change between
     moveUp:/moveDown: operations. */
  _originalInsertPoint = originalInsertionPoint;
}

- (void) moveLeft: (id)sender
{
  unsigned newLocation;

  /* Do nothing if we are at beginning of text with no selection */
  if (_selected_range.location == 0 && _selected_range.length == 0)
    return;

  if (_selected_range.location == 0)
    {
      newLocation = 0;
    }
  else
    {
      newLocation = _selected_range.location - 1;
    }

  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}

- (void) moveRight: (id)sender
{
  unsigned int length = [_textStorage length];
  unsigned newLocation;

  /* Do nothing if we are at end of text */
  if (_selected_range.location == length)
    return;

  newLocation = MIN (NSMaxRange (_selected_range) + 1, length);

  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}


- (BOOL) acceptsFirstResponder
{
  if (_tf.is_selectable)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (BOOL) resignFirstResponder
{
  if (_tvf.multiple_textviews == YES)
    {
      id futureFirstResponder;
      NSArray *textContainers;
      int i, count;
      
      futureFirstResponder = [_window _futureFirstResponder];
      textContainers = [_layoutManager textContainers];
      count = [textContainers count];
      for (i = 0; i < count; i++)
	{
	  NSTextContainer *container;
	  NSTextView *view;
	  
	  container = (NSTextContainer *)[textContainers objectAtIndex: i];
	  view = [container textView];

	  if (view == futureFirstResponder)
	    {
	      /* NB: We do not reset the BEGAN_EDITING flag so that no
		 spurious notification is generated. */
	      return YES;
	    }
	}
    }
  
  /* NB: Possible change: ask always - not only if editable - but we
     need to change NSTextField etc to allow this. */
  if ((_tf.is_editable)
      && ([_delegate respondsToSelector: @selector(textShouldEndEditing:)])
      && ([_delegate textShouldEndEditing: self] == NO))
    {
      return NO;
    }
  
  /* Add any clean-up stuff here */

  if ([self shouldDrawInsertionPoint])
    {
      [self setNeedsDisplayInRect: _insertionPointRect  
	    avoidAdditionalLayout: YES];
      //<!> stop timed entry
    }

  SET_BEGAN_EDITING (NO);

  /* NB: According to the doc (and to the tradition), we post this
     notification even if no real editing was actually done (only
     selection of text) [Note: in this case, no editing was started,
     so the notification does not come after a
     NSTextDidBeginEditingNotification!].  The notification only means
     that we are resigning first responder status.  This makes sense
     because many objects inside the gui need this notification anyway
     - typically, it is needed to remove a field editor (editable or
     not) when the user presses TAB to move to the next view.  Anyway
     yes, the notification name is misleading. */
  [nc postNotificationName: NSTextDidEndEditingNotification  
      object: _notifObject];
  return YES;
}

- (BOOL) becomeFirstResponder
{
  if (_tf.is_selectable == NO)
    {
      return NO;
    }

  /* NB: Notifications (NSTextBeginEditingNotification etc) are managed 
     on the first time the user tries to edit us. */

  /* Draw selection, update insertion point */

  //if ([self shouldDrawInsertionPoint])
  //  {
  //   [self lockFocus];
  //   [self drawInsertionPointAtIndex: _selected_range.location
  //      color: _caret_color turnedOn: YES];
  //   [self unlockFocus];
  //   //<!> restart timed entry
  //  }

  return YES;
}

- (void) becomeKeyWindow
{
  [self setNeedsDisplayInRect: _insertionPointRect  
	avoidAdditionalLayout: YES];
  //<!> start timed entry
}

- (void) resignKeyWindow
{
  [self setNeedsDisplayInRect: _insertionPointRect  
	avoidAdditionalLayout: YES];
  //<!> stop timed entry
}

- (void) drawRect: (NSRect)rect
{
  /* TODO: Only do relayout if needed */
  NSRange drawnRange = [_layoutManager glyphRangeForBoundingRect: rect 
				       inTextContainer: _textContainer];
  if (_tf.draws_background)
    {
      [_layoutManager drawBackgroundForGlyphRange: drawnRange 
		      atPoint: _textContainerOrigin];
    }

  [_layoutManager drawGlyphsForGlyphRange: drawnRange 
		  atPoint: _textContainerOrigin];

  if ([self shouldDrawInsertionPoint])
    {
      unsigned location = _selected_range.location;

      if (NSLocationInRange (location, drawnRange) 
	  || location == NSMaxRange (drawnRange))
	{
	  [self drawInsertionPointInRect: _insertionPointRect  
		color: _caret_color  
		turnedOn: YES];
	}
    }
}

/*
 * Ruler Views
 */
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

- (void) setDelegate: (id)anObject
{
  SEL selector;
  
  /* Code to allow sharing the delegate */
  if (_tvf.multiple_textviews && (IS_SYNCHRONIZING_DELEGATES == NO))
    {
      /* Invoke setDelegate: on all the textviews which share this
         delegate. */
      NSArray *array;
      int i, count;

      IS_SYNCHRONIZING_DELEGATES = YES;

      array = [_layoutManager textContainers];
      count = [array count];

      for (i = 0; i < count; i++)
	{
	  NSTextView *view;

	  view = [(NSTextContainer *)[array objectAtIndex: i] textView];
	  [view setDelegate: anObject];
	}
      
      IS_SYNCHRONIZING_DELEGATES = NO;
    }

  /* Now the real code to set the delegate */

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: _notifObject];
    }

  [super setDelegate: anObject];

  selector = @selector(shouldChangeTextInRange:replacementString:);
  if ([_delegate respondsToSelector: selector])
    {
      _tvf.delegate_responds_to_should_change = YES;
    }
  else
    {
      _tvf.delegate_responds_to_should_change = NO;
    }

  selector = @selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:);
  if ([_delegate respondsToSelector: selector])
    {
      _tvf.delegate_responds_to_will_change_sel = YES;
    }
  else
    {
      _tvf.delegate_responds_to_will_change_sel = NO;
    }
  
  /* SET_DELEGATE_NOTIFICATION defined at the beginning of file */

  /* NSText notifications */
  SET_DELEGATE_NOTIFICATION (DidBeginEditing);
  SET_DELEGATE_NOTIFICATION (DidChange);
  SET_DELEGATE_NOTIFICATION (DidEndEditing);

  /* NSTextView notifications */
  SET_DELEGATE_NOTIFICATION (ViewDidChangeSelection);
  SET_DELEGATE_NOTIFICATION (ViewWillChangeNotifyingTextView);
}

- (int) spellCheckerDocumentTag
{
  if (!_spellCheckerDocumentTag)
    _spellCheckerDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];

  return _spellCheckerDocumentTag;
}

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedCharRange
			       granularity: (NSSelectionGranularity)granul
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

  if (NSMaxRange (proposedCharRange) > length)
    {
      proposedCharRange.length = length - proposedCharRange.location;
    }

  if (length == 0)
    {
      return proposedCharRange;
    }

  switch (granul)
    {
    case NSSelectByWord:
      index = proposedCharRange.location;
      if (index >= length)
	{
	  index = length - 1;
	}
      newRange = [_textStorage doubleClickAtIndex: index];
      if (proposedCharRange.length > 1)
	{
	  index = NSMaxRange(proposedCharRange) - 1;
	  if (index >= length)
	    {
	      index = length - 1;
	    }
	  aRange = [_textStorage doubleClickAtIndex: index];
	  newRange = NSUnionRange(newRange, aRange);
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
    {
      return NSMakeRange (NSNotFound, 0);
    }

  if (_tf.is_rich_text)
    {
      // This expects the selection to be already corrected to characters
      return _selected_range;
    }
  else
    {
      return NSMakeRange (0, [_textStorage length]);
    }
}

- (NSRange) rangeForUserParagraphAttributeChange
{
  if (!_tf.is_editable || !_tf.uses_ruler)
    {
      return NSMakeRange (NSNotFound, 0);
    }

  if (_tf.is_rich_text)
    {
      return [self selectionRangeForProposedRange: _selected_range
		   granularity: NSSelectByParagraph];
    }
  else
    {
      return NSMakeRange (0, [_textStorage length]);
    }
}

- (NSRange) rangeForUserTextChange
{
  if (!_tf.is_editable)
    {
      return NSMakeRange (NSNotFound, 0);
    }  

  // This expects the selection to be already corrected to characters
  return _selected_range;
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
  Reads the text view's preferred type of data from the pasteboard
  specified by the pboard parameter. This method invokes the
  preferredPasteboardTypeFromArray: restrictedToTypesFromArray: method
  to determine the text view's preferred type of data and then reads
  the data using the readSelectionFromPasteboard: type:
  method. Returns YES if the data was successfully read.  */
  NSString *type;

  type = [self preferredPasteboardTypeFromArray: [pboard types]
	       restrictedToTypesFromArray: [self readablePasteboardTypes]];
  
  if (type == nil)
    return NO;
  
  return [self readSelectionFromPasteboard: pboard  type: type];
}

- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pboard
				type: (NSString*)type 
{
/*
  Reads data of the given type from pboard. The new data is placed at
  the current insertion point, replacing the current selection if one
  exists.  Returns YES if the data was successfully read.

  You should override this method to read pasteboard types other than
  the default types. Use the rangeForUserTextChange method to obtain
  the range of characters (if any) to be replaced by the new data.  */

  if ([type isEqualToString: NSStringPboardType])
    {
      [self insertText: [pboard stringForType: NSStringPboardType]];
      return YES;
    } 

  if (_tf.is_rich_text)
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
      NSMutableDictionary	*d = [[self typingAttributes] mutableCopy];

      [d setObject: color forKey: NSForegroundColorAttributeName];
      [self setTypingAttributes: d];
      RELEASE(d);

      if (aRange.location != NSNotFound)
	{
	  [self setTextColor: color range: aRange];
	}

      return YES;
    }

  // font pasting
  if ([type isEqualToString: NSFontPboardType])
    {
      NSData *data = [pboard dataForType: NSFontPboardType];
      NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData: data];

      if (dict != nil)
	{
	  NSRange aRange = [self rangeForUserCharacterAttributeChange];
	  NSMutableDictionary	*d;

	  if (aRange.location != NSNotFound)
	    {
	      [self setAttributes: dict range: aRange];
	    }
	  d = [[self typingAttributes] mutableCopy];
	  [d addEntriesFromDictionary: dict];
	  [self setTypingAttributes: d];
	  RELEASE(d);
	  return YES;
	}
      return NO;
    }

  // ruler pasting
  if ([type isEqualToString: NSRulerPboardType])
    {
      NSData *data = [pboard dataForType: NSRulerPboardType];
      NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData: data];

      if (dict != nil)
	{
	  NSRange aRange = [self rangeForUserParagraphAttributeChange];
	  NSMutableDictionary	*d;

	  if (aRange.location != NSNotFound)
	    {
	      [self setAttributes: dict range: aRange];
	    }
	  d = [[self typingAttributes] mutableCopy];
	  [d addEntriesFromDictionary: dict];
	  [self setTypingAttributes: d];
	  RELEASE(d);
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
    {
      return NO;
    }
  
  if (_selected_range.location == NSNotFound)
    {
      return NO;
    }

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
	  NSColor	*color;

	  color = [_textStorage attribute: NSForegroundColorAttributeName
				  atIndex: _selected_range.location
			   effectiveRange: 0];
	  if (color != nil)
	    {
	      [color writeToPasteboard:  pboard];
	      ret = YES;
	    }
	}

      if ([type isEqualToString: NSFontPboardType])
        {
	  NSDictionary	*dict;

	  dict = [_textStorage fontAttributesInRange: _selected_range];
	  if (dict != nil)
	    {
	      [pboard setData: [NSArchiver archivedDataWithRootObject: dict]
		      forType: NSFontPboardType];
	      ret = YES;
	    }
	}

      if ([type isEqualToString: NSRulerPboardType])
        {
	  NSDictionary	*dict;

	  dict = [_textStorage rulerAttributesInRange: _selected_range];
	  if (dict != nil)
	    {
	      [pboard setData: [NSArchiver archivedDataWithRootObject: dict]
		      forType: NSRulerPboardType];
	      ret = YES;
	    }
	}
    }

  return ret;
}

@end

@implementation NSTextView (GNUstepExtensions)

- (void) replaceRange: (NSRange)aRange
 withAttributedString: (NSAttributedString*)attrString
{
  if (aRange.location == NSNotFound)
    return;

  if (![self shouldChangeTextInRange: aRange
	     replacementString: [attrString string]])
    return;

  [_textStorage beginEditing];

  if (_tf.is_rich_text)
    {
      [_textStorage replaceCharactersInRange: aRange
		    withAttributedString: attrString];
    }
  else
    {
      [_textStorage replaceCharactersInRange: aRange
		    withString: [attrString string]];
    }
  
  [_textStorage endEditing];
  [self didChangeText];
}

- (unsigned) textLength
{
  return [_textStorage length];
}

@end

@implementation NSTextView (GNUstepPrivate)

+ (NSDictionary*) defaultTypingAttributes
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 [NSParagraphStyle defaultParagraphStyle], 
		         NSParagraphStyleAttributeName,
		         [NSFont userFontOfSize: 0], NSFontAttributeName,
		         [NSColor textColor], NSForegroundColorAttributeName,
		         nil];
}

- (void) setAttributes: (NSDictionary*)attributes  range: (NSRange)aRange
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
      [_textStorage addAttribute: type  value: val  range: aRange];
    }
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) _illegalMovement: (int)textMovement
{
  // This is similar to [self resignFirstResponder], with the
  // difference that in the notification we need to put the
  // NSTextMovement, which resignFirstResponder does not.  Also, if we
  // are ending editing, we are going to be removed, so it's useless
  // to update any drawing.
  NSNumber *number;
  NSDictionary *uiDictionary;
  
  if ((_tf.is_editable)
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

- (unsigned) characterIndexForPoint: (NSPoint)point
{
  unsigned	index;
  float		fraction;

  index = [_layoutManager glyphIndexForPoint: point 
			     inTextContainer: _textContainer
	      fractionOfDistanceThroughGlyph: &fraction];

  index = [_layoutManager characterIndexForGlyphAtIndex: index];
  if (fraction > 0.5)
    {
      index++;
    }
  return index;
}

- (NSRect) rectForCharacterRange: (NSRange)aRange
{
  NSRange glyphRange;

  glyphRange = [_layoutManager glyphRangeForCharacterRange: aRange 
			       actualCharacterRange: NULL];

  return [_layoutManager boundingRectForGlyphRange: glyphRange 
			 inTextContainer: _textContainer];
}
@end

@implementation NSTextView(NSTextInput)
// This are all the NSTextInput methods that are not implemented on NSTextView
// or one of its super classes.

- (void) setMarkedText:(NSString *)aString  selectedRange:(NSRange)selRange
{
}

- (BOOL) hasMarkedText
{
  return NO;
}

- (void) unmarkText
{
}

- (NSArray*) validAttributesForMarkedText
{
  return nil;
}

- (long) conversationIdentifier
{
  return 0;
}

- (NSRect) firstRectForCharacterRange: (NSRange)theRange
{
  return NSZeroRect;
}
@end

