/** <title>NSTextView</title>

   Copyright (C) 1996, 1998, 2000, 2001, 2002 Free Software Foundation, Inc.

   Originally moved here from NSTextView.m.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996

   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998

   Author: Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2000, September 2000

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: 2000, 2001, 2002

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: September 2002

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


#include <Foundation/NSNotification.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextView.h>


/**** User actions ****/

/* TODO: all these need to be cleaned up */

/*
These methods are for user actions, ie. they are normally called from
-doCommandBySelector: (which is called by the input manager) in response
to some key press or other user event.

User actions that modify the text must check that a modification is allowed
and make sure all necessary notifications are sent. This is done by sending
-shouldChangeTextInRange:replacementString: before making any changes, and
(if the change is allowed) -didChangeText after the changes have been made.

All actions from NSResponder that make sense for a text view  should be
implemented here, but this is _not_ the place to add new actions.


Not all user actions are here. Exceptions:

  -toggleRuler:

  -copy:
  -copyFont:
  -copyRuler:
  -paste:
  -pasteFont:
  -pasteRuler:
  -pasteAsPlainText:
  -pasteAsRichText:

  -checkSpelling:
  -showGuessPanel:

  -selectAll: (implemented in NSText)

  -toggleContinuousSpellChecking:


Not all methods that handle user-induced text modifications are here.
Exceptions:
  (TODO)

  -insertText:
  -changeColor:
  -changeFont: (action method?)
  drag&drop handling methods
  (others?)

All other methods that modify text are for programmatic changes and do not
send -shouldChangeTextInRange:replacementString: or -didChangeText.

*/


/** First some helpers **/

@interface NSTextView (user_action_helpers)

-(void) _illegalMovement: (int)textMovement;

@end


@implementation NSTextView (user_action_helpers)

-(void) _illegalMovement: (int)textMovement
{
  /* This is similar to [self resignFirstResponder], with the
     difference that in the notification we need to put the
     NSTextMovement, which resignFirstResponder does not.  Also, if we
     are ending editing, we are going to be removed, so it's useless
     to update any drawing.  Please note that this ends up calling
     resignFirstResponder anyway.  */
  NSNumber *number;
  NSDictionary *uiDictionary;

  if ((_tf.is_editable)
      && ([_delegate respondsToSelector:
		       @selector(textShouldEndEditing:)])
      && ([_delegate textShouldEndEditing: self] == NO))
    return;

  /* TODO: insertion point */

  number = [NSNumber numberWithInt: textMovement];
  uiDictionary = [NSDictionary dictionaryWithObject: number
			       forKey: @"NSTextMovement"];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSTextDidEndEditingNotification
		  object: self
		userInfo: uiDictionary];
  /* The TextField will get the notification, and drop our first responder
   * status if it's the case ... in that case, our -resignFirstResponder will
   * be called!  */
  return;
}

@end


@implementation NSTextView (user_actions)

-(void) subscript: (id)sender
{
  NSNumber *value = [_layoutManager->_typingAttributes 
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
  [_layoutManager->_typingAttributes setObject: [NSNumber numberWithInt: sValue]
		     forKey: NSSuperscriptAttributeName];
}

-(void) superscript: (id)sender
{
  NSNumber *value = [_layoutManager->_typingAttributes 
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
  [_layoutManager->_typingAttributes setObject: [NSNumber numberWithInt: sValue]
		     forKey: NSSuperscriptAttributeName];
}

-(void) unscript: (id)sender
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
  [_layoutManager->_typingAttributes removeObjectForKey: NSSuperscriptAttributeName];
}

-(void) underline: (id)sender
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

  [_layoutManager->_typingAttributes
      setObject: [NSNumber numberWithInt: doUnderline]
      forKey: NSUnderlineStyleAttributeName];
}

-(void) useStandardKerning: (id)sender
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

-(void) lowerBaseline: (id)sender
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

-(void) raiseBaseline: (id)sender
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

-(void) turnOffKerning: (id)sender
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

-(void) loosenKerning: (id)sender
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

-(void) tightenKerning: (id)sender
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

-(void) useStandardLigatures: (id)sender
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

-(void) turnOffLigatures: (id)sender
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

-(void) useAllLigatures: (id)sender
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

-(void) toggleTraditionalCharacterShape: (id)sender
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"toggleTraditionalCharacterShape:", "NSTextView");
}

-(void) insertNewline: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSReturnTextMovement];
      return;
    }

  [self insertText: @"\n"];
}

-(void) insertTab: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSTabTextMovement];
      return;
    }

  [self insertText: @"\t"];
}

-(void) insertBacktab: (id)sender
{
  if (_tf.is_field_editor)
    {
      [self _illegalMovement: NSBacktabTextMovement];
      return;
    }

  //[self insertText: @"\t"];
}

-(void) deleteForward: (id)sender
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

-(void) deleteBackward: (id)sender
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
	     beeping configurable via User Defaults */
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

-(void) moveUp: (id)sender
{
/*  float originalInsertionPoint;
  float savedOriginalInsertionPoint;
  float startingY;
  unsigned newLocation;*/

  if (_tf.is_field_editor) /* TODO: why? */
    return;

  /* Do nothing if we are at beginning of text */
  if (_layoutManager->_selected_range.location == 0)
    {
      return;
    }

#if 0 /* TODO */
  /* Read from memory the horizontal position we aim to move the cursor 
     at on the next line */
  savedOriginalInsertionPoint = _originalInsertPoint;
  originalInsertionPoint = _originalInsertPoint;

  /* Ask the layout manager to compute where to go */
  startingY = NSMidY (_insertionPointRect);

  /* consider textContainerInset */
  startingY -= _textContainerInset.height;
  originalInsertionPoint -= _textContainerInset.width;

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
  _originalInsertPoint = savedOriginalInsertionPoint;
#endif
}

-(void) moveDown: (id)sender
{
/*  float originalInsertionPoint;
  float savedOriginalInsertionPoint;
  float startingY;
  unsigned newLocation;*/

  if (_tf.is_field_editor)
    return;

  /* Do nothing if we are at end of text */
  if (_layoutManager->_selected_range.location == [_textStorage length])
    {
      return;
    }

#if 0 /* TODO */
  /* Read from memory the horizontal position we aim to move the cursor 
     at on the next line */
  savedOriginalInsertionPoint = _originalInsertPoint;
  originalInsertionPoint = _originalInsertPoint;

  /* Ask the layout manager to compute where to go */
  startingY = NSMidY (_insertionPointRect);

  /* consider textContainerInset */
  startingY -= _textContainerInset.height;
  originalInsertionPoint -= _textContainerInset.width;

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
  _originalInsertPoint = savedOriginalInsertionPoint;
#endif
}

-(void) moveLeft: (id)sender
{
  unsigned newLocation;

  /* Do nothing if we are at beginning of text with no selection */
  if (_layoutManager->_selected_range.location == 0 && _layoutManager->_selected_range.length == 0)
    return;

  if (_layoutManager->_selected_range.location == 0)
    {
      newLocation = 0;
    }
  else
    {
      newLocation = _layoutManager->_selected_range.location - 1;
    }

  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}

-(void) moveRight: (id)sender
{
  unsigned int length = [_textStorage length];
  unsigned newLocation;

  /* Do nothing if we are at end of text */
  if (_layoutManager->_selected_range.location == length)
    return;

  newLocation = MIN (NSMaxRange (_layoutManager->_selected_range) + 1, length);

  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}

-(void) moveBackwardAndModifySelection: (id)sender
{
  NSRange newRange;

  /* Do nothing if we are at beginning of text.  */
  if (_layoutManager->_selected_range.location == 0)
    {
      return;
    }

  /* Turn to select by character.  */
  [self setSelectionGranularity: NSSelectByCharacter];

  /* Extend the selection on the left.  */
  newRange = NSMakeRange (_layoutManager->_selected_range.location - 1, 
			  _layoutManager->_selected_range.length + 1);

  newRange = [self selectionRangeForProposedRange: newRange
		   granularity: NSSelectByCharacter];

  [self setSelectedRange: newRange];
}

-(void) moveForwardAndModifySelection: (id)sender
{
  unsigned int length = [_textStorage length];
  NSRange newRange;

  /* Do nothing if we are at end of text */
  if (_layoutManager->_selected_range.location == length)
    return;

  /* Turn to select by character.  */
  [self setSelectionGranularity: NSSelectByCharacter];

  /* Extend the selection on the right.  */
  newRange = NSMakeRange (_layoutManager->_selected_range.location, 
			  _layoutManager->_selected_range.length + 1);

  newRange = [self selectionRangeForProposedRange: newRange
		   granularity: NSSelectByCharacter];

  [self setSelectedRange: newRange];
}

-(void) moveWordBackward: (id)sender
{
  unsigned newLocation;
  
  newLocation = [_textStorage nextWordFromIndex: _layoutManager->_selected_range.location
			      forward: NO];
  
  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}

-(void) moveWordForward: (id)sender
{
  unsigned newLocation;
  
  newLocation = [_textStorage nextWordFromIndex: _layoutManager->_selected_range.location
			      forward: YES];
  
  [self setSelectedRange: NSMakeRange (newLocation, 0)];
}

-(void) moveWordBackwardAndModifySelection: (id)sender
{
  unsigned newLocation;
  NSRange newRange;

  [self setSelectionGranularity: NSSelectByWord];
  
  newLocation = [_textStorage nextWordFromIndex: _layoutManager->_selected_range.location
			      forward: NO];
  
  newRange = NSMakeRange (newLocation, 
			  NSMaxRange (_layoutManager->_selected_range) - newLocation);
  
  newRange = [self selectionRangeForProposedRange: newRange
		   granularity: NSSelectByCharacter];
  
  [self setSelectedRange: newRange];
}

-(void) moveWordForwardAndModifySelection: (id)sender
{
  unsigned newMaxRange;
  NSRange newRange;
  
  [self setSelectionGranularity: NSSelectByWord];

  newMaxRange = [_textStorage nextWordFromIndex: NSMaxRange (_layoutManager->_selected_range)
			      forward: YES];
  
  newRange = NSMakeRange (_layoutManager->_selected_range.location, 
			  newMaxRange - _layoutManager->_selected_range.location);
  
  newRange = [self selectionRangeForProposedRange: newRange
		   granularity: NSSelectByCharacter];

  [self setSelectedRange: newRange];
}

-(void) moveToBeginningOfDocument: (id)sender
{
  [self setSelectedRange: NSMakeRange (0, 0)];
}

-(void) moveToBeginningOfParagraph: (id)sender
{
  NSRange aRange;
  
  aRange = [[_textStorage string] lineRangeForRange: _layoutManager->_selected_range];
  [self setSelectedRange: NSMakeRange (aRange.location, 0)];
}

-(void) moveToBeginningOfLine: (id)sender
{
  NSRange aRange;
  NSRect ignored;
  
  /* We do nothing if we are at the beginning of the text.  */
  if (_layoutManager->_selected_range.location == 0)
    {
      return;
    }
  
  ignored = [_layoutManager lineFragmentRectForGlyphAtIndex: 
			      _layoutManager->_selected_range.location
			    effectiveRange: &aRange];

  [self setSelectedRange: NSMakeRange (aRange.location, 0)];
}

-(void) moveToEndOfDocument: (id)sender
{
  unsigned length = [_textStorage length];
  
  if (length > 0)
    {
      [self setSelectedRange: NSMakeRange (length, 0)];
    }
  else
    {
      [self setSelectedRange: NSMakeRange (0, 0)];
    }
}

-(void) moveToEndOfParagraph: (id)sender
{
  NSRange aRange;
  unsigned newLocation;
  unsigned maxRange;
  
  aRange = [[_textStorage string] lineRangeForRange: _layoutManager->_selected_range];
  maxRange = NSMaxRange (aRange);

  if (maxRange == 0)
    {
      /* Beginning of text is special only for technical reasons -
	 since maxRange is an unsigned, we can't safely subtract 1
	 from it if it is 0.  */
      newLocation = maxRange;
    }
  else if (maxRange == [_textStorage length])
    {
      /* End of text is special - we want the insertion point to
	 appear *after* the last character, which means as if before
	 the next (virtual) character after the end of text ... unless
	 the last character is a newline, and we are trying to go to
	 the end of the line which is displayed as the
	 one-before-the-last.  Please note (maxRange - 1) is a valid
	 char since the maxRange == 0 case has already been
	 eliminated.  */
      unichar u = [[_textStorage string] characterAtIndex: (maxRange - 1)];
      if (u == '\n'  ||  u == '\r')
	{
	  newLocation = maxRange - 1;
	}
      else
	{
	  newLocation = maxRange;
	}
    }
  else
    {
      /* Else, we want the insertion point to appear before the last
	 character in the paragraph range.  Normally the last
	 character in the paragraph range is a newline.  */
      newLocation = maxRange - 1;
    }

  if (newLocation < aRange.location)
    {
      newLocation = aRange.location;
    }

  [self setSelectedRange: NSMakeRange (newLocation, 0) ];
}

-(void) moveToEndOfLine: (id)sender
{
  NSRect ignored;
  NSRange line, glyphs;
  unsigned newLocation;
  unsigned maxRange;
  
  /* We do nothing if we are at the end of the text.  */
  if (_layoutManager->_selected_range.location == [_textStorage length])
    {
      return;
    }

  ignored = [_layoutManager lineFragmentRectForGlyphAtIndex: 
			      _layoutManager->_selected_range.location
			    effectiveRange: &glyphs];
  
  line = [_layoutManager characterRangeForGlyphRange: glyphs
			 actualGlyphRange: NULL];
  
  maxRange = NSMaxRange (line);

  if (maxRange == 0)
    {
      /* Beginning of text is special only for technical reasons -
	 since maxRange is an unsigned, we can't safely subtract 1
	 from it if it is 0.  */
      newLocation = maxRange;
    }
  else if (maxRange == [_textStorage length])
    {
      /* End of text is special - we want the insertion point to
	 appear *after* the last character, which means as if before
	 the next (virtual) character after the end of text ... unless
	 the last character is a newline, and we are trying to go to
	 the end of the line which is displayed as the
	 one-before-the-last.  (Please note that we do not check for
	 spaces - spaces are ok, we want to move after the last space)
	 Please note (maxRange - 1) is a valid char since the maxRange
	 == 0 case has already been eliminated.  */
      unichar u = [[_textStorage string] characterAtIndex: (maxRange - 1)];
      if (u == '\n'  ||  u == '\r')
	{
	  newLocation = maxRange - 1;
	}
      else
	{
	  newLocation = maxRange;
	}
    }
  else
    {
      /* Else, we want the insertion point to appear before the last
	 character in the line range.  Normally the last character in
	 the line range is a space or a newline.  */
      newLocation = maxRange - 1;
    }

  if (newLocation < line.location)
    {
      newLocation = line.location;
    }
  
  [self setSelectedRange: NSMakeRange (newLocation, 0) ];
}

/**
 * Tries to move the selection/insertion point down one page of the
 * visible rect in the receiver while trying to maintain the
 * horizontal position of the last vertical movement.
 * If the receiver is a field editor, this method returns immediatly. 
 */
-(void) pageDown: (id)sender
{
#if 0 /* TODO */
  float    cachedInsertPointX;
  float    scrollDelta;
  float    oldOriginY;
  float    newOriginY;
  unsigned glyphIDX;
  unsigned charIDX;
  NSPoint  iPoint;
 
  if (_tf.is_field_editor)
    return;
  
  /* 
   * Save the current horizontal position cache as we will implictly
   * change it later.
   */
//  cachedInsertPointX = _originalInsertPoint;

  /*
   * Scroll; also determine how far to move the insertion point.
   */
  oldOriginY = NSMinY([self visibleRect]);
  [[self enclosingScrollView] pageDown: sender];
  newOriginY = NSMinY([self visibleRect]);
  scrollDelta = newOriginY - oldOriginY;

  if (scrollDelta == 0)
    {
      /* TODO/FIXME: If no scroll was done, it means we are in the
       * last page of the document already - should we move the
       * insertion point to the last line when the user clicks
       * 'PageDown' in that case ?
       */
    }

  /*
   * Calculate new insertion point.
   */
  iPoint.x  = _originalInsertPoint        - _textContainerInset.width;
  iPoint.y  = NSMidY(_insertionPointRect) - _textContainerInset.height;
  iPoint.y += scrollDelta;

  /*
   * Ask the layout manager to compute where to go.
   */
  glyphIDX = [_layoutManager glyphIndexForPoint: iPoint
                            inTextContainer: _textContainer];
  charIDX  = [_layoutManager characterIndexForGlyphAtIndex: glyphIDX];

  /*
   * Move the insertion point (implicitly changing
   * _originalInsertPoint).
   */
  [self setSelectedRange: NSMakeRange(charIDX, 0)];

  /*
   * Restore the _originalInsertPoint because we do not want it to
   * change between moveUp:/moveDown:/pageUp:/pageDown: operations.  
   */
  _originalInsertPoint = cachedInsertPointX;
#endif
}

/**
 * Tries to move the selection/insertion point up one page of the
 * visible rect in the receiver while trying to maintain the
 * horizontal position of the last vertical movement.
 * If the receiver is a field editor, this method returns immediatly. 
 */
-(void) pageUp: (id)sender
{
#if 0 /* TODO */
  float    cachedInsertPointX;
  float    scrollDelta;
  float    oldOriginY;
  float    newOriginY;
  unsigned glyphIDX;
  unsigned charIDX;
  NSPoint  iPoint;

  if (_tf.is_field_editor)
    return;

  /* 
   * Save the current horizontal position cache as we will implictly
   * change it later.
   */
  cachedInsertPointX = _originalInsertPoint;

  /*
   * Scroll; also determine how far to move the insertion point.
   */
  oldOriginY = NSMinY([self visibleRect]);
  [[self enclosingScrollView] pageUp: sender];
  newOriginY = NSMinY([self visibleRect]);
  scrollDelta = newOriginY - oldOriginY;

  if (scrollDelta == 0)
    {
      /* TODO/FIXME: If no scroll was done, it means we are in the
       * first page of the document already - should we move the
       * insertion point to the first line when the user clicks
       * 'PageUp' in that case ?
       */
    }

  /*
   * Calculate new insertion point.
   */
  iPoint.x  = _originalInsertPoint        - _textContainerInset.width;
  iPoint.y  = NSMidY(_insertionPointRect) - _textContainerInset.height;
  iPoint.y += scrollDelta;

  /*
   * Ask the layout manager to compute where to go.
   */
  glyphIDX = [_layoutManager glyphIndexForPoint: iPoint
                             inTextContainer: _textContainer];
  charIDX  = [_layoutManager characterIndexForGlyphAtIndex: glyphIDX];

  /*
   * Move the insertion point (implicitly changing
   * _originalInsertPoint). 
   */
  [self setSelectedRange: NSMakeRange(charIDX, 0)];
  
  /*
   * Restore the _originalInsertPoint because we do not want it to
   * change between moveUp:/moveDown:/pageUp:/pageDown: operations.
   */
  _originalInsertPoint = cachedInsertPointX;
#endif
}

-(void) scrollLineDown: (id)sender
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"scrollLineDown:", "NSTextView");
}

-(void) scrollLineUp: (id)sender
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"scrollLineUp:", "NSTextView");
}

-(void) scrollPageDown: (id)sender
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"scrollPageDown:", "NSTextView");
}

-(void) scrollPageUp: (id)sender
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"scrollPageUp:", "NSTextView");
}


/* -selectAll: inherited from NSText  */

-(void) selectLine: (id)sender
{
  if ([_textStorage length] > 0)
    {
      NSRange aRange;
      NSRect ignored;
      
      ignored = [_layoutManager lineFragmentRectForGlyphAtIndex: 
				  _layoutManager->_selected_range.location
				effectiveRange: &aRange];
      
      [self setSelectedRange: aRange];
    }
}

/* The following method is bound to 'Control-t', and must work like
 * pressing 'Control-t' inside Emacs.  For example, say that I type
 * 'Nicoal' in a NSTextView.  Then, I press 'Control-t'.  This should
 * swap the last two characters which were inserted, thus swapping the
 * 'a' and the 'l', and changing the text to read 'Nicola'.  */
/*
TODO: description incorrect. should swap characters on either side of the
insertion point. (see also: miswart)
*/
-(void) transpose: (id)sender
{
  NSRange range;
  NSString *string;
  NSString *replacementString;
  unichar chars[2];
  unichar tmp;

  /* Do nothing if we are at beginning of text.  */
  if (_layoutManager->_selected_range.location < 2)
    {
      return;
    }

  range = NSMakeRange (_layoutManager->_selected_range.location - 2, 2);

  /* Get the two chars.  */
  string = [_textStorage string];
  chars[0] = [string characterAtIndex: (_layoutManager->_selected_range.location - 2)];
  chars[1] = [string characterAtIndex: (_layoutManager->_selected_range.location - 1)];

  /* Swap them.  */
  tmp = chars[0];
  chars[0] = chars[1];
  chars[1] = tmp;
  
  /* Replace the original chars with the swapped ones.  */
  replacementString = [NSString stringWithCharacters: chars  length: 2];

  if ([self shouldChangeTextInRange: range
	replacementString: replacementString])
    {
      [self replaceCharactersInRange: range
        withString: replacementString];
      [self didChangeText];
    }
}

-(void) delete: (id)sender
{
  [self deleteForward: sender];
}


/* Helper for -align*: */
-(void) _alignUser: (NSTextAlignment)alignment
{
  NSRange r = [self rangeForUserParagraphAttributeChange];
  if (r.location == NSNotFound)
    return;
  if (![self shouldChangeTextInRange: r
	 replacementString: nil])
    return;

  [self setAlignment: alignment
    range: r];
  [self didChangeText];
}

-(void) alignCenter: (id)sender
{
  [self _alignUser: NSCenterTextAlignment];
}
-(void) alignLeft: (id)sender
{
  [self _alignUser: NSLeftTextAlignment];
}
-(void) alignRight: (id)sender
{
  [self _alignUser: NSRightTextAlignment];
}
-(void) alignJustified: (id)sender
{
  [self _alignUser: NSJustifiedTextAlignment];
}


-(void) toggleContinuousSpellChecking: (id)sender
{
  [self setContinuousSpellCheckingEnabled: 
	    ![self isContinuousSpellCheckingEnabled]];
}


-(void) toggleRuler: (id)sender
{
  [self setRulerVisible: !_tf.is_ruler_visible];
}

@end

