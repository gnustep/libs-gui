/*
   NSTextField.m

   Text field control class for text entry

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 1999

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

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSWindow.h>

@implementation NSTextField
//
// Class methods
//
+ (void) initialize
{
  if (self == [NSTextField class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSTextFieldCell class]];
    }
}

//
// Instance methods
//
- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];
  [_cell setState: 1];
  [_cell setBezeled: YES];
  [_cell setSelectable: YES];
  [_cell setEnabled: YES];
  [_cell setEditable: YES];
  [_cell setDrawsBackground: YES];
  _text_object = nil;

  return self;
}

//
// Creating copies
//
- (id) copyWithZone: (NSZone*)zone
{
  NSTextField	*c;

  c = [super copyWithZone: zone];

  return c;
}

//
// Setting User Access to Text
//
- (BOOL) isEditable
{
  return [_cell isEditable];
}

- (BOOL) isSelectable
{
  return [_cell isSelectable];
}

- (void) setEditable: (BOOL)flag
{
  [_cell setEditable: flag];
  if (_text_object)
    [_text_object setEditable: flag];
}

- (void) setSelectable: (BOOL)flag
{
  [_cell setSelectable: flag];
  if (_text_object)
    [_text_object setSelectable: flag];
}

//
// Editing Text
//
- (void) selectText: (id)sender
{
  if ([self isSelectable] && (super_view != nil))
    {
      if (_text_object)
	[_text_object selectAll: self];
      else
	{
	  NSText *t = [window fieldEditor: YES 
			      forObject: self];

	  if ([t superview] != nil)
	    if ([t resignFirstResponder] == NO)
	      return;
	  
	  //  [NSCursor hide];
	  _text_object = [_cell setUpFieldEditorAttributes: t];
	  [_cell selectWithFrame: bounds
		inView: self
		editor: _text_object
		delegate: self
		start: 0
		length: [[self stringValue] length]];
	}
    }
}

//
// Setting Tab Key Behavior
//
- (id) nextText
{
  return _nextKeyView;
}

- (id) previousText
{
  return _previousKeyView;
}

- (void) setNextText: (id)anObject
{
  [self setNextKeyView: anObject];
}

- (void) setPreviousText: (id)anObject
{
  [self setPreviousKeyView: anObject];
}

//
// Assigning a Delegate
//
- (void) setDelegate: (id)anObject
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(controlText##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(controlText##notif_name:) \
      name: NSControlText##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidBeginEditing);
  SET_DELEGATE_NOTIFICATION(DidEndEditing);
  SET_DELEGATE_NOTIFICATION(DidChange);
}

- (id) delegate
{
  return _delegate;
}

//
// Modifying Graphic Attributes
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  [_cell setBackgroundColor: aColor];
}

- (NSColor *) backgroundColor
{
  return [_cell backgroundColor];
}

- (BOOL) drawsBackground
{
  return [_cell drawsBackground];
}

- (BOOL) isBezeled
{
  return [_cell isBezeled];
}

- (BOOL) isBordered
{
  return [_cell isBordered];
}

- (void) setBezeled: (BOOL)flag
{
  [_cell setBezeled: flag];
}

- (void) setBordered: (BOOL)flag
{
  [_cell setBordered: flag];
}

- (void) setDrawsBackground: (BOOL)flag
{
  [_cell setDrawsBackground: flag];
}

- (void) setTextColor: (NSColor *)aColor
{
  [_cell setTextColor: aColor];
}

- (NSColor *) textColor
{
  return [_cell textColor];
}

//
// Target and Action
//
- (SEL) errorAction
{
  return _error_action;
}

- (void) setErrorAction: (SEL)aSelector
{
  _error_action = aSelector;
}

//
// Handling Events
//
- (void) mouseDown: (NSEvent*)theEvent
{
  NSText *t;
  
  if ([self isSelectable] == NO)
    return;

  // This could happen if someone pressed the mouse 
  // on the borders
  if (_text_object)
    return;

  t = [window fieldEditor: YES forObject: self];

  if ([t superview] != nil)
    {
      if ([t resignFirstResponder] == NO)
	{
	  if ([window makeFirstResponder: window] == NO)
	    return;
	}
    }


  //  [NSCursor hide];
  
  _text_object = [_cell setUpFieldEditorAttributes: t];
  [_cell editWithFrame: bounds
	inView: self
	editor: _text_object
	delegate: self
	event: theEvent];
}
- (BOOL) acceptsFirstMouse: (NSEvent *)aEvent
{
  return YES;
}

- (BOOL) acceptsFirstResponder
{
  return [self isSelectable];
}

- (BOOL) becomeFirstResponder
{
  return [self isSelectable];
}

- (BOOL) abortEditing
{
  if (_text_object)
    {
      [_text_object setString: @""];
      [_cell endEditing: _text_object];
      _text_object = nil;
      return YES;
    }
  else 
    return NO;
}

- (NSText *) currentEditor
{
  if (_text_object && ([window firstResponder] == _text_object))
    return _text_object;
  else
    return nil;
}

- (void) validateEditing 
{
  if (_text_object)
    [_cell setStringValue: [_text_object text]];
}

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;
  
  d = [NSDictionary dictionaryWithObject:[aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidBeginEditingNotification
      object: self
      userInfo: d];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;
  
  d = [NSDictionary dictionaryWithObject: [aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidChangeNotification
      object: self
      userInfo: d];
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSDictionary *d;
  id textMovement;

  [self validateEditing];

  d = [NSDictionary dictionaryWithObject: [aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidEndEditingNotification
      object: self
      userInfo: d];

  [_cell endEditing: [aNotification object]];

  textMovement = [[aNotification userInfo] objectForKey: @"NSTextMovement"];
  if (textMovement)
    {
      switch ([(NSNumber *)textMovement intValue])
	{
	case NSReturnTextMovement:
	  [self sendAction: [self action] to: [self target]];
	  break;
	case NSTabTextMovement:
	  [window selectKeyViewFollowingView: self];
	  break;
	case NSBacktabTextMovement:
	  [window selectKeyViewPrecedingView: self];
	  break;
	}
    }
  _text_object = nil;
}

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  if ([self isEditable] == NO)
    return NO;
  
  if (_delegate && [_delegate respondsToSelector: 
				@selector(control:textShouldBeginEditing:)])
    return [_delegate control: self 
		      textShouldBeginEditing: textObject];
  else 
    return YES;
}

- (BOOL) textShouldEndEditing: (NSText *)aTextObject
{
  if ([_cell isEntryAcceptable: [aTextObject text]] == NO)
    {
      [self sendAction: _error_action to: [self target]];
      return NO;
    }
  
  if ([_delegate respondsToSelector: 
		   @selector(control:textShouldEndEditing:)])
    {
      if ([_delegate control: self 
		     textShouldEndEditing: aTextObject] == NO)
	{
	  NSBeep ();
	  return NO;
	}
    }

  // In all other cases
  return YES;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_error_action];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [self setDelegate: [aDecoder decodeObject]];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_error_action];
  _text_object = nil;

  return self;
}

@end

