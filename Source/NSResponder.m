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

#include "gnustep/gui/config.h"
#include <Foundation/NSCoder.h>
#include <Foundation/NSDebug.h>
#include "AppKit/NSResponder.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSHelpManager.h"
#include "AppKit/NSInputManager.h"

@implementation NSResponder

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSResponder class])
    {
      [self setVersion: 1];
      
      /* Gets the current input manager - this forces it to read the
         key binding files at this stage.  */
      [NSInputManager currentInputManager];
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

/**
 * Returns YES if the receiver is able to become the first responder,
 * NO otherwise.
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
  [[NSInputManager currentInputManager] handleKeyboardEvents: eventArray
					client: self];
}

- (void) flushBufferedKeyEvents
{
}

- (void) doCommandBySelector:(SEL)aSelector
{
  if (![self tryToPerform: aSelector with: nil])
    {
      NSBeep();
    }
}

- (void) insertText: (NSString*)aString
{
  if (_next_responder)
    return [_next_responder insertText: aString];
  else
    {
      NSBeep ();
    }
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

- (void) otherMouseDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseDown: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseDown:)];
}

- (void) otherMouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseDragged:)];
}

- (void) otherMouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseUp:)];
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
  if (_next_responder)
    return [_next_responder scrollWheel: theEvent];
  else
    return [self noResponderFor: @selector(scrollWheel:)];
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
- (void) dealloc
{
  RELEASE(_menu);
  [super dealloc];
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
