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

#include <Foundation/NSCoder.h>
#include <AppKit/NSInterfaceStyle.h>

@class NSString;
@class NSEvent;

@interface NSResponder : NSObject <NSCoding>
{
  NSInterfaceStyle	interface_style;
  NSResponder		*next_responder;
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
- (BOOL) performKeyEquivalent: (NSEvent *)theEvent;
- (BOOL) tryToPerform: (SEL)anAction with: (id)anObject;

/*
 * Forwarding event messages
 */
- (void) flagsChanged: (NSEvent *)theEvent;
- (void) helpRequested: (NSEvent *)theEvent;
- (void) keyDown: (NSEvent *)theEvent;
- (void) keyUp: (NSEvent *)theEvent;
- (void) mouseDown: (NSEvent *)theEvent;
- (void) mouseDragged: (NSEvent *)theEvent;
- (void) mouseEntered: (NSEvent *)theEvent;
- (void) mouseExited: (NSEvent *)theEvent;
- (void) mouseMoved: (NSEvent *)theEvent;
- (void) mouseUp: (NSEvent *)theEvent;
- (void) noResponderFor: (SEL)eventSelector;
- (void) rightMouseDown: (NSEvent *)theEvent;
- (void) rightMouseDragged: (NSEvent *)theEvent;
- (void) rightMouseUp: (NSEvent *)theEvent;

/*
 * Services menu support
 */
- (id) validRequestorForSendType: (NSString *)typeSent
		      returnType: (NSString *)typeReturned;

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;

#ifndef	STRICT_OPENSTEP
- (NSInterfaceStyle) interfaceStyle;
- (void) setInterfaceStyle: (NSInterfaceStyle)aStyle;
#endif
@end

#endif /* _GNUstep_H_NSResponder */
