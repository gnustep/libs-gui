/*
   GSDragView - Generic Drag and Drop code.

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: May 2004

   Based on X11 specific code from:
   Created by: Wim Oudshoorn <woudshoo@xs4all.nl>
   Date: Nov 2001
   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998

   This file is part of the GNU Objective C User Interface Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */

#include <Foundation/NSGeometry.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSView.h>

@class NSCell;
@class NSMutableDictionary;

/*
  used in the operation mask to indicate that the
  user can not change the drag action by
  pressing modifiers.
*/

#define NSDragOperationIgnoresModifiers  0xffff

@interface GSDragView : NSView <NSDraggingInfo>
{
    NSCell          *dragCell;          // the graphics that is dragged
    NSPasteboard    *dragPasteboard;    // the pasteboard with the dragged data
    id              destWindow;         // NSWindow in this application that is the current target
    NSPoint         dragPoint;          // in base coordinates, only valid when destWindow != nil
    int             dragSequence;
    id              dragSource;         // the NSObject source of the dragging
    unsigned int    dragMask;           // Operations supported by the source
    unsigned int    operationMask;      // user specified operation mask (key modifiers).
                                        // this is either a mask of type _NSDragOperation,
                                        // or NSDragOperationIgnoresModifiers, which
                                        // is defined as 0xffff
    BOOL            slideBack;          // slide the image back when drag fails?

    /* information used in the drag and drop event loop */
    NSPoint         offset;             // offset of image w.r.t. cursor
    NSPoint         dragPosition;       // current drag position in screen coordinates
    NSPoint         newPosition;        // drag position, not yet processed

    int             targetWindowRef;    // OS specific current window target of the drag operation
    unsigned int    targetMask;         // Operations supported by the target, only valid if
                                        // targetWindowRef isn't 0

    BOOL            destExternal;       // YES if target and source are in a different application
    BOOL            isDragging;         // YES if we are currently dragging

    NSMutableDictionary *cursors;       // Cache for cursors
}

+ (GSDragView*) sharedDragView;
- (void) dragImage: (NSImage*)anImage
		at: (NSPoint)screenLocation
	    offset: (NSSize)initialOffset
	     event: (NSEvent*)event
	pasteboard: (NSPasteboard*)pboard
	    source: (id)sourceObject
         slideBack: (BOOL)slideFlag;
- (void) postDragEvent: (NSEvent *)theEvent;

@end
