/* 
   NSResponder.h

   Abstract class which is basis of command and event processing

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
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

#ifndef _GNUstep_H_NSResponder
#define _GNUstep_H_NSResponder

#include <Foundation/NSObject.h>
#include <AppKit/NSInterfaceStyle.h>
#include <AppKit/AppKitDefines.h>

@class NSCoder;
@class NSString;
@class NSEvent;
@class NSMenu;
@class NSUndoManager;

@interface NSResponder : NSObject <NSCoding>
{
#ifdef  STRICT_OPENSTEP
  int			_interface_style;
#else
  NSInterfaceStyle	_interface_style;
#endif
  NSResponder		*_next_responder;
  NSMenu                *_menu;  
  /*
   * Flags for internal use by NSResponder and it's subclasses.
   */
@public
  struct _rFlagsType {
    /*
     * 'flipped_view' is set in NSViews designated initialiser (and other
     * methods that create views) to be the value returned by [-isFlipped]
     * This caching assumes that the value returned by [-isFlipped] will
     * not change during the views lifetime - if it does, the view must
     * be sure to change the flag accordingly.
     */
    unsigned	flipped_view:1;
    unsigned	has_subviews:1;		/* The view has subviews.	*/
    unsigned	has_currects:1;		/* The view has cursor rects.	*/
    unsigned	has_trkrects:1;		/* The view has tracking rects.	*/
    unsigned	has_draginfo:1;		/* View/window has drag types.	*/
    unsigned	opaque_view:1;		/* For views whose opacity may	*/
					/* change to keep track of it.	*/
    unsigned	valid_rects:1;		/* Some cursor rects may be ok.	*/
    unsigned	needs_display:1;	/* Window/view needs display.	*/
  } _rFlags;
}

/*
 * Instance methods
 */

/*
 * Managing the next responder
 */
- (NSResponder*) nextResponder;
- (void) setNextResponder: (NSResponder*)aResponder;

/*
 * Determining the first responder
 */
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

/*
 * Aid event processing
 */
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent;
- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject;

/*
 * Forwarding event messages
 */
- (void) flagsChanged: (NSEvent*)theEvent;
- (void) helpRequested: (NSEvent*)theEvent;
- (void) keyDown: (NSEvent*)theEvent;
- (void) keyUp: (NSEvent*)theEvent;
- (void) mouseDown: (NSEvent*)theEvent;
- (void) mouseDragged: (NSEvent*)theEvent;
- (void) mouseEntered: (NSEvent*)theEvent;
- (void) mouseExited: (NSEvent*)theEvent;
- (void) mouseMoved: (NSEvent*)theEvent;
- (void) mouseUp: (NSEvent*)theEvent;
- (void) noResponderFor: (SEL)eventSelector;
#ifndef	STRICT_OPENSTEP
- (void) otherMouseDown: (NSEvent*)theEvent;
- (void) otherMouseDragged: (NSEvent*)theEvent;
- (void) otherMouseUp: (NSEvent*)theEvent;
#endif
- (void) rightMouseDown: (NSEvent*)theEvent;
- (void) rightMouseDragged: (NSEvent*)theEvent;
- (void) rightMouseUp: (NSEvent*)theEvent;
- (void) scrollWheel: (NSEvent *)theEvent;

/*
 * Services menu support
 */
- (id) validRequestorForSendType: (NSString*)typeSent
		      returnType: (NSString*)typeReturned;

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;

#ifndef	STRICT_OPENSTEP
- (void) interpretKeyEvents: (NSArray*)eventArray;
- (BOOL) performMnemonic: (NSString*)aString;
- (void) flushBufferedKeyEvents;
- (void) doCommandBySelector: (SEL)aSelector;
- (void) insertText: (NSString*)aString;
- (NSUndoManager*) undoManager;

/*
 * Menu
 */
- (NSMenu*) menu;
- (void) setMenu: (NSMenu*)aMenu;

/*
 * Setting the interface
 */
- (NSInterfaceStyle) interfaceStyle;
- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle;
#endif
@end

#ifndef	STRICT_OPENSTEP
@interface NSResponder (OptionalActionMethods)
- (void) capitalizeWord: (id)sender;
- (void) centerSelectionInVisibleArea: (id)sender;
- (void) changeCaseOfLetter: (id)sender;
- (void) complete: (id)sender;
- (void) deleteBackward: (id)sender;
- (void) deleteForward: (id)sender;
- (void) deleteToBeginningOfLine: (id)sender;
- (void) deleteToBeginningOfParagraph: (id)sender;
- (void) deleteToEndOfLine: (id)sender;
- (void) deleteToEndOfParagraph: (id)sender;
- (void) deleteToMark: (id)sender;
- (void) deleteWordBackward: (id)sender;
- (void) deleteWordForward: (id)sender;
- (void) indent: (id)sender;
- (void) insertBacktab: (id)sender;
- (void) insertNewline: (id)sender;
- (void) insertNewlineIgnoringFieldEditor: (id)sender;
- (void) insertParagraphSeparator: (id)sender;
- (void) insertTab: (id)sender;
- (void) insertTabIgnoringFieldEditor: (id)sender;
- (void) lowercaseWord: (id)sender;
- (void) moveBackward: (id)sender;
- (void) moveBackwardAndModifySelection: (id)sender;
- (void) moveDown: (id)sender;
- (void) moveDownAndModifySelection: (id)sender;
- (void) moveForward: (id)sender;
- (void) moveForwardAndModifySelection: (id)sender;
- (void) moveLeft: (id)sender;
- (void) moveRight: (id)sender;
- (void) moveToBeginningOfDocument: (id)sender;
- (void) moveToBeginningOfLine: (id)sender;
- (void) moveToBeginningOfParagraph: (id)sender;
- (void) moveToEndOfDocument: (id)sender;
- (void) moveToEndOfLine: (id)sender;
- (void) moveToEndOfParagraph: (id)sender;
- (void) moveUp: (id)sender;
- (void) moveUpAndModifySelection: (id)sender;
- (void) moveWordBackward: (id)sender;
- (void) moveWordBackwardAndModifySelection: (id)sender;
- (void) moveWordForward: (id)sender;
- (void) moveWordForwardAndModifySelection: (id)sender;
- (void) pageDown: (id)sender;
- (void) pageUp: (id)sender;
- (void) scrollLineDown: (id)sender;
- (void) scrollLineUp: (id)sender;
- (void) scrollPageDown: (id)sender;
- (void) scrollPageUp: (id)sender;
- (void) selectAll: (id)sender;
- (void) selectLine: (id)sender;
- (void) selectParagraph: (id)sender;
- (void) selectToMark: (id)sender;
- (void) selectWord: (id)sender;
- (void) showContextHelp: (id)sender;
- (void) swapWithMark: (id)sender;
- (void) transpose: (id)sender;
- (void) transposeWords: (id)sender;
- (void) uppercaseWord: (id)sender;
- (void) yank: (id)sender;
@end
#endif

#endif /* _GNUstep_H_NSResponder */
