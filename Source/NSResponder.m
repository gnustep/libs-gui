/** <title>NSResponder</title>

   <abstract>Abstract class which is basis of command and event processing</abstract>

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
#include <AppKit/NSResponder.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSHelpManager.h>
#include <objc/objc.h>

@implementation NSResponder

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSResponder class])
    {
      NSDebugLog(@"Initialize NSResponder class\n");

      [self setVersion: 1];
    }
}

/*
 * Instance methods
 */
/*
 * Managing the next responder
 */
- (id) nextResponder
{
  return _next_responder;
}

- (void) setNextResponder: (NSResponder*)aResponder
{
  _next_responder = aResponder;
}

/*
 * Determining the first responder
 */
- (BOOL) acceptsFirstResponder
{
  return NO;
}

- (BOOL) becomeFirstResponder
{
  return YES;
}

- (BOOL) resignFirstResponder
{
  return YES;
}

/*
 * Aid event processing
 */
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  return NO;
}

- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject
{
  /* Can we perform the action -then do it */
  if ([self respondsToSelector: anAction])
    {
      [self performSelector: anAction withObject: anObject];
      return YES;
    }
  else
    {
      /* If we cannot perform then try the next responder */
      if (!_next_responder)
	return NO;
      else
	return [_next_responder tryToPerform: anAction with: anObject];
    }
}

- (BOOL) performMnemonic: (NSString*)aString
{
  return NO;
}

- (void) interpretKeyEvents:(NSArray*)eventArray
{
  // FIXME: As NSInputManger is still missing this method is hard coded
  NSEvent *theEvent;
  NSEnumerator *eventEnum = [eventArray objectEnumerator];

  while((theEvent = [eventEnum nextObject]) != nil)
    {
      NSString *characters = [theEvent characters];
      unichar character = 0;

      if ([characters length] > 0)
	{
	  character = [characters characterAtIndex: 0];
	}
      
      switch (character)
	{
	case NSUpArrowFunctionKey:
	  [self doCommandBySelector: @selector(moveUp:)];
	  break;
	case NSDownArrowFunctionKey:
	  [self doCommandBySelector: @selector(moveDown:)];
	  break;
	case NSLeftArrowFunctionKey:
	  [self doCommandBySelector: @selector(moveLeft:)];
	  break;
	case NSRightArrowFunctionKey:
	  [self doCommandBySelector: @selector(moveRight:)];
	  break;
	case NSDeleteFunctionKey:
	  [self doCommandBySelector: @selector(deleteForward:)];
	  break;
	case NSHomeFunctionKey:
	  [self doCommandBySelector: @selector(moveToBeginningOfDocument:)];
	  break;
	case NSBeginFunctionKey:
	  [self doCommandBySelector: @selector(moveToBeginningOfLine:)];
	  break;
	case NSEndFunctionKey:
	  [self doCommandBySelector: @selector(moveToEndOfLine:)];
	  break;
	case NSPageUpFunctionKey:
	  [self doCommandBySelector: @selector(pageUp:)];
	  break;
	case NSPageDownFunctionKey:
	  [self doCommandBySelector: @selector(pageDown:)];
	  break;
	case NSBackspaceCharacter:
	  [self doCommandBySelector: @selector(deleteBackward:)];
	  break;
	case NSTabCharacter:
	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    [self doCommandBySelector: @selector(insertBacktab:)];
	  else
	    [self doCommandBySelector: @selector(insertTab:)];
	  break;
	case NSEnterCharacter:
	case NSFormFeedCharacter:
	case NSCarriageReturnCharacter:
	  [self doCommandBySelector: @selector(insertNewline:)];
	  break;
	case 0:
	  /* Character to implement ?? */
	  break;
	default:
	  // If the character(s) was not a special one, simply insert it.
	  [self insertText: characters];
	}  
    }
}

- (void) flushBufferedKeyEvents
{
}

- (void) doCommandBySelector:(SEL)aSelector
{
  if (![self tryToPerform: aSelector with: nil])
    NSBeep();
}

/*
 * Forwarding event messages
 */
- (void) flagsChanged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder flagsChanged: theEvent];
  else
    return [self noResponderFor: @selector(flagsChanged:)];
}

- (void) helpRequested: (NSEvent*)theEvent
{
  if(![[NSHelpManager sharedHelpManager]
	showContextHelpForObject: self
	locationHint: [theEvent locationInWindow]])
    if (_next_responder)
      return [_next_responder helpRequested: theEvent];
  [NSHelpManager setContextHelpModeActive: NO];
}

- (void) keyDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder keyDown: theEvent];
  else
    return [self noResponderFor: @selector(keyDown:)];
}

- (void) keyUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder keyUp: theEvent];
  else
    return [self noResponderFor: @selector(keyUp:)];
}

- (void) middleMouseDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder middleMouseDown: theEvent];
  else
    return [self noResponderFor: @selector(middleMouseDown:)];
}

- (void) middleMouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder middleMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(middleMouseDragged:)];
}

- (void) middleMouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder middleMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(middleMouseUp:)];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseDown: theEvent];
  else
    return [self noResponderFor: @selector(mouseDown:)];
}

- (void) mouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(mouseDragged:)];
}

- (void) mouseEntered: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseEntered: theEvent];
  else
    return [self noResponderFor: @selector(mouseEntered:)];
}

- (void) mouseExited: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseExited: theEvent];
  else
    return [self noResponderFor: @selector(mouseExited:)];
}

- (void) mouseMoved: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseMoved: theEvent];
  else
    return [self noResponderFor: @selector(mouseMoved:)];
}

- (void) mouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseUp: theEvent];
  else
    return [self noResponderFor: @selector(mouseUp:)];
}

- (void) noResponderFor: (SEL)eventSelector
{
  /* Only beep for key down events */
  if (sel_eq(eventSelector, @selector(keyDown:)))
    NSBeep();
}

- (void) rightMouseDown: (NSEvent*)theEvent
{
  if (_next_responder != nil)
    return [_next_responder rightMouseDown: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseDown:)];
}

- (void) rightMouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder rightMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseDragged:)];
}

- (void) rightMouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder rightMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseUp:)];
}

- (void) scrollWheel: (NSEvent *)theEvent
{
  // FIXME
  NSLog(@"Sorry, currently no support for scroll wheel.");
}

/*
 * Services menu support
 */
- (id) validRequestorForSendType: (NSString*)typeSent
		      returnType: (NSString*)typeReturned
{
  if (_next_responder)
    return [_next_responder validRequestorForSendType: typeSent
					  returnType: typeReturned];
  else
    return nil;
}

/*
 * NSCoding protocol
 * NB. Don't encode responder chain - it's transient information that should
 * be reconstructed from else where in the encoded archive.
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(NSInterfaceStyle)
			     at: &_interface_style];
  [aCoder encodeObject: _menu];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  id obj;

  [aDecoder decodeValueOfObjCType: @encode(NSInterfaceStyle)
			       at: &_interface_style];
  obj = [aDecoder decodeObject];
  [self setMenu: obj];

  return self;
}

- (NSMenu*) menu
{
  return _menu;
}

- (void) setMenu: (NSMenu*)aMenu
{
  ASSIGN(_menu, aMenu);
}

- (NSInterfaceStyle) interfaceStyle
{
  return _interface_style;
}

- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle
{
  _interface_style = aStyle;
}

- (NSUndoManager*) undoManager
{
  return nil;
}
@end
