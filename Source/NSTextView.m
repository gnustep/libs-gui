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

/* MINOR FIXME: The following two should really be kept in the
   NSLayoutManager object to avoid interferences between different
   sets of NSTextViews linked to different NSLayoutManagers.  But this
   bug should show very rarely. */
 
/* YES when in the process of synchronizing text view attributes.  
   It is used to avoid recursive synchronizations. */
static BOOL isSynchronizingFlags = NO;
static BOOL isSynchronizingDelegate = NO;

/* The shared notification center */
static NSNotificationCenter *nc;

@interface NSTextView (GNUstepPrivate)
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
- (void) setAttributes: (NSDictionary *) attributes  range: (NSRange) aRange;
- (void) _illegalMovement: (int) notNumber;
- (void) deleteRange: (NSRange)aRange  backspace: (BOOL)flag;

- (void) drawInsertionPointAtIndex: (unsigned)index
			     color: (NSColor *)color
			  turnedOn: (BOOL)flag;
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

  [self setMinSize: frameRect.size];
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
  ASSIGN (_caret_color, [NSColor blackColor]); 
  [self setTypingAttributes: [isa defaultTypingAttributes]];

  [self setBackgroundColor: [NSColor textBackgroundColor]];

  //[self setSelectedRange: NSMakeRange (0, 0)];

  [aTextContainer setTextView: self];
  [aTextContainer setWidthTracksTextView: YES];
  [aTextContainer setHeightTracksTextView: YES];

  // FIXME: ?? frame was given as an argument so we shouldn't resize.
  [self sizeToFit];

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
		       withString: (NSString*)aString
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
/*
  NSLog(@"setSelectedRange (%d, %d)", charRange.location, charRange.length);
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextViewDidChangeSelectionNotification
    object: self];
  _selected_range = charRange;
*/
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
	   NSDictionary *dict;

	   dict = [_textStorage attributesAtIndex: range.location
				effectiveRange: NULL];
	   [self setTypingAttributes: dict];
	}
      // <!>enable caret timed entry
    }

  if (!_window)
    return;

  // Make the selected range visible
  [self scrollRangeToVisible: range]; 

  // Redisplay what has changed
  // This does an unhighlight of the old selected region
  overlap = NSIntersectionRange (oldRange, range);
  if (overlap.length)
    {
      // Try to optimize for overlapping ranges
      if (range.location != oldRange.location)
	{
	  NSRange r;
	  r = MakeRangeFromAbs (MIN (range.location, oldRange.location),
				MAX (range.location, oldRange.location));
	  [self setNeedsDisplayInRect: [self rectForCharacterRange: r]];
	}
      if (NSMaxRange (range) != NSMaxRange (oldRange))
	{
	  NSRange r = MakeRangeFromAbs (MIN (NSMaxRange (range), 
					     NSMaxRange (oldRange)),
					MAX (NSMaxRange (range),
					     NSMaxRange (oldRange)));
	  [self setNeedsDisplayInRect: [self rectForCharacterRange: r]];
	}
    }
  else
    {
      [self setNeedsDisplayInRect: [self rectForCharacterRange: range]];
      [self setNeedsDisplayInRect: [self rectForCharacterRange: oldRange]];
    }

  [self setSelectionGranularity: NSSelectByCharacter];
  // Also removes the marking from
  // marked text if the new selection is greater than the marked region.
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
  [self deleteRange: _selected_range  backspace: NO];
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
      NSFont *font = [_textStorage attribute: NSFontAttributeName
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
  if (font == nil)
    {
      return;
    }
  
  [self setFont: font  ofRange: NSMakeRange (0, [self textLength])];
  [_typingAttributes setObject: font forKey: NSFontAttributeName];
}

- (void) setFont: (NSFont*)font  ofRange: (NSRange)aRange
{
  if (font != nil)
    {
      if (![self shouldChangeTextInRange: aRange  replacementString: nil])
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
 * [NSText] Managing Alignment
 */
- (NSTextAlignment) alignment
{
  /* FIXME */
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

- (void) setAlignment: (NSTextAlignment)mode
{
  [self setAlignment: mode  range: NSMakeRange (0, [self textLength])];
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
  /* FIXME */
  NSRange aRange = [self rangeForUserCharacterAttributeChange];

  if (aRange.location != NSNotFound)
    return [_textStorage attribute: NSForegroundColorAttributeName
			 atIndex: aRange.location
			 effectiveRange: NULL];
  else 
    return [_typingAttributes objectForKey: NSForegroundColorAttributeName];
}

- (void) setTextColor: (NSColor*)color
{
  /* FIXME: This should work also for non rich text objects */
  NSRange fullRange = NSMakeRange (0, [self textLength]);

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

- (BOOL) writeRTFDToFile: (NSString*)path  atomically: (BOOL)flag
{
  NSFileWrapper *wrapper;
  NSRange range = NSMakeRange (0, [self textLength]);
  
  wrapper = [_textStorage RTFDFileWrapperFromRange: range  
			  documentAttributes: nil];
  return [wrapper writeToFile: path  atomically: flag  updateFilenames: YES];
}

/*
 * [NSText] Managing size
 */
/* FIXME: Remove this method! */
- (void) setHorizontallyResizable: (BOOL)flag
{
  NSSize containerSize = [_textContainer containerSize];

  if (flag)
    containerSize.width = HUGE;
  else
    containerSize.width = _frame.size.width - 2.0 * [self textContainerInset].width;

  [_textContainer setContainerSize: containerSize];
  [_textContainer setWidthTracksTextView: !flag];

  [super setHorizontallyResizable: flag];
}

/* FIXME: Remove this method! */
- (void) setVerticallyResizable: (BOOL)flag
{
  NSSize containerSize = [_textContainer containerSize];

  if (flag)
    containerSize.height = HUGE;
  else
    containerSize.height = _frame.size.height - 2.0 * [self textContainerInset].height;

  [_textContainer setContainerSize: containerSize];
  [_textContainer setHeightTracksTextView: !flag];

  [super setVerticallyResizable: flag];
}

- (void) sizeToFit
{
  // if we are a field editor we don't have to handle the size.
  if (_tf.is_field_editor)
    return;
  else
    {
      NSSize oldSize = _frame.size;
      float newWidth = oldSize.width;
      float newHeight = oldSize.height;
      NSRect textRect = [_layoutManager usedRectForTextContainer: 
					  _textContainer];
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

  // FIXME: Hack to get the layout change
  [_textContainer setContainerSize: _frame.size];
}

- (void) replaceTextContainer: (NSTextContainer*)aTextContainer
{
  // Notify layoutManager of change?

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
  // FIXME: This is here until the layout manager is working
  [super setNeedsDisplayInRect: aRect];
}

/* We override NSView's setNeedsDisplayInRect: */

- (void) setNeedsDisplayInRect: (NSRect)aRect
{
  [self setNeedsDisplayInRect: aRect  avoidAdditionalLayout: NO];
}

- (BOOL) shouldDrawInsertionPoint
{
  return (_selected_range.length == 0) && _tf.is_editable;
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
      [_background_color set];
      NSRectFill(rect);
      // FIXME: We should redisplay the character the cursor was on.
      //[self setNeedsDisplayInRect: rect];
    }

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
   isSynchronizingFlags flag to YES to prevent recursive calls; calls the
   specified action on all the textviews (this one included) with the
   specified flag; sets back the isSynchronizingFlags flag to NO; then
   returns.

   We need to explicitly call the methods - we can't copy the flags
   directly from one textview to another, to allow subclasses to
   override eg setEditable: to take some particular action when
   editing is turned on or off. */
- (void) _syncTextViewsByCalling: (SEL)action  withFlag: (BOOL)flag
{
  NSArray *array;
  int i, count;
  void (*msg)(id, SEL, BOOL);

  if (isSynchronizingFlags == YES)
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

  isSynchronizingFlags = YES;

  for (i = 0; i < count; i++)
    {
      NSTextView *tv; 

      tv = [(NSTextContainer *)[array objectAtIndex: i] textView];
      (*msg) (tv, action, flag);
    }

  isSynchronizingFlags = NO;
}

#define NSTEXTVIEW_SYNC(X) \
  if (_tvf.multiple_textviews && (isSynchronizingFlags == NO)) \
    {  [self _syncTextViewsByCalling: @selector(##X##)  withFlag: flag]; \
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
  NSTEXTVIEW_SYNC (setEditable:);
  [super setEditable: flag];
  /* FIXME/TODO: Update/show the insertion point */
}

- (void) setFieldEditor: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setFieldEditor:);
  [super setFieldEditor: flag];
}

- (void) setSelectable: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setSelectable:);
  [super setSelectable: flag];
}

- (void) setRichText: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setRichText:);

  [super setRichText: flag];
  [self updateDragTypeRegistration];
  /* FIXME/TODO: Also convert text to plain text or to rich text */
}

- (void) setImportsGraphics: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setImportsGraphics:);

  [super setImportsGraphics: flag];
  [self updateDragTypeRegistration];
}

- (void) setUsesRuler: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setUsesRuler:);
  _tf.uses_ruler = flag;
}

- (BOOL) usesRuler
{
  return _tf.uses_ruler;
}

- (void) setUsesFontPanel: (BOOL)flag
{
  NSTEXTVIEW_SYNC (setUsesFontPanel:);
  [super setUsesFontPanel: flag];
}

- (void) setRulerVisible: (BOOL)flag
{
  NSScrollView *sv;

  NSTEXTVIEW_SYNC (setRulerVisible:);

  sv = [self enclosingScrollView];
  _tf.is_ruler_visible = flag;
  if (sv != nil)
    {
      [sv setRulersVisible: _tf.is_ruler_visible];
    }
}

#undef NSTEXTVIEW_SYNC

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
  // update fontPanel only if told so
  if (_tf.uses_font_panel)
    {
      NSRange longestRange;
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSFont *currentFont;

      currentFont = [_textStorage attribute: NSFontAttributeName
				  atIndex: _selected_range.location
				  longestEffectiveRange: &longestRange
				  inRange: _selected_range];
      [fm setSelectedFont: currentFont
	  isMultiple: !NSEqualRanges (longestRange, _selected_range)];
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
  unsigned location = _selected_range.location;

  if (location != [self textLength])
    {
      /* Not at the end of text -- delete following character */
      NSRange delRange = NSMakeRange (location, 1);

      delRange = [self selectionRangeForProposedRange: delRange
		       granularity: NSSelectByCharacter];
      [self deleteRange: delRange  backspace: NO];
    }
  else
    {
      /* end of text: behave the same way as NSBackspaceKey */
      [self deleteBackward: sender];
    }
}

- (void) deleteBackward: (id)sender
{
  [self deleteRange: _selected_range backspace: YES];
}

//<!> choose granularity according to keyboard modifier flags
- (void) moveUp: (id)sender
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

- (void) moveDown: (id)sender
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

- (void) moveLeft: (id)sender
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

- (void) moveRight: (id)sender
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
  if (_tf.is_selectable)
    return YES;
  else
    return NO;
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
  if ((_tf.is_editable)
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
  if (_tf.is_selectable == NO)
    return NO;

    /*
      if (!nextRsponder == NSTextView_in_NSLayoutManager)
      {
      //draw selection
      //update the insertion point
      }
    */
  
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
	  [self drawInsertionPointAtIndex: location  color: _caret_color
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
  /* Code to allow sharing the delegate */
  if (_tvf.multiple_textviews && (isSynchronizingDelegate == NO))
    {
      /* Invoke setDelegate: on all the textviews which share this
         delegate. */
      NSArray *array;
      int i, count;

      isSynchronizingDelegate = YES;

      array = [_layoutManager textContainers];
      count = [array count];

      for (i = 0; i < count; i++)
	{
	  NSTextView *view;

	  view = [(NSTextContainer *)[array objectAtIndex: i] textView];
	  [view setDelegate: anObject];
	}
      
      isSynchronizingDelegate = NO;
    }

  /* Now the real code to set the delegate */

  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: _notifObject];
    }

  [super setDelegate: anObject];

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

      if (aRange.location != NSNotFound)
	[self setTextColor: color  range: aRange];

      return YES;
    }

  // font pasting
  if ([type isEqualToString: NSFontPboardType])
    {
      // FIXME - This should use a serializer. To get that working a
      // helper object is needed that implements the
      // NSObjCTypeSerializationCallBack protocol.  We should add this
      // later, currently the NSArchiver is used.  Thanks to Richard,
      // for pointing this out.
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
	  NSDictionary *dict;

	  dict = [_textStorage fontAttributesInRange: _selected_range];
	  if (dict != nil)
	    {
	      // FIXME - This should use a serializer. To get that
	      // working a helper object is needed that implements the
	      // NSObjCTypeSerializationCallBack protocol.  We should
	      // add this later, currently the NSArchiver is used.
	      // Thanks to Richard, for pointing this out.
	      [pboard setData: [NSArchiver archivedDataWithRootObject: dict]
		      forType: NSFontPboardType];
	      ret = YES;
	    }
	}

      if ([type isEqualToString: NSRulerPboardType])
        {
	  NSDictionary *dict;

	  dict = [_textStorage rulerAttributesInRange: _selected_range];
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

@end

@implementation NSTextView (GNUstepPrivate)

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
      [_textStorage addAttribute: type  value: val  range: aRange];
    }
  [_textStorage endEditing];
  [self didChangeText];
}

- (void) _illegalMovement: (int)textMovement
{
  // This is similar to [self resignFirstResponder],
  // with the difference that in the notification we need
  // to put the NSTextMovement, which resignFirstResponder
  // does not.  Also, if we are ending editing, we are going
  // to be removed, so it's useless to update any drawing.
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

// central text deletion/backspace method
// (takes care of optimized redraw/ cursor positioning)
- (void) deleteRange: (NSRange) aRange  backspace: (BOOL) flag
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

  if (![self shouldChangeTextInRange: deleteRange  replacementString: @""])
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
  unsigned glyphIndex;

  glyphIndex = [_layoutManager glyphIndexForPoint: point 
			       inTextContainer: _textContainer];

  return [_layoutManager characterIndexForGlyphAtIndex: glyphIndex];
}

- (NSRect) rectForCharacterIndex: (unsigned)index
{
  NSRange charRange;
  NSRange glyphRange;
  unsigned glyphIndex;
  NSRect rect;
  NSPoint loc;

  charRange = NSMakeRange (index, 1);
  glyphRange = [_layoutManager glyphRangeForCharacterRange: charRange 
			       actualCharacterRange: NULL];
  glyphIndex = glyphRange.location;

  rect = [_layoutManager lineFragmentRectForGlyphAtIndex: glyphIndex 
			 effectiveRange: NULL];
  loc = [_layoutManager locationForGlyphAtIndex: glyphIndex];

  rect.origin.x += loc.x;
  rect.size.width -= loc.x;

  return rect;
}

- (NSRect) rectForCharacterRange: (NSRange) aRange
{
  NSRange glyphRange;

  glyphRange = [_layoutManager glyphRangeForCharacterRange: aRange 
			       actualCharacterRange: NULL];

  return [_layoutManager boundingRectForGlyphRange: glyphRange 
			 inTextContainer: _textContainer];
}

- (void) drawInsertionPointAtIndex: (unsigned) index
			     color: (NSColor*) color
			  turnedOn: (BOOL) flag
{
  NSRect drawRect  = [self rectForCharacterIndex: index];

  drawRect.size.width = 1;
  if (drawRect.size.height == 0)
    drawRect.size.height = 12;

  [self drawInsertionPointInRect: drawRect  color: color  turnedOn: flag];
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

