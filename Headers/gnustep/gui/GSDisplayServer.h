/** <title>GSDisplayServer</title>

   <abstract>Abstract display server class.</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Mar 2002
   
   This file is part of the GNU Objective C User interface library.

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
   */

#ifndef _GSDisplayServer_h_INCLUDE
#define _GSDisplayServer_h_INCLUDE

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSSet.h>

#include <AppKit/NSDragging.h>
#include <AppKit/AppKitDefines.h>
#include <AppKit/NSGraphicsContext.h>

@class NSArray;
@class NSMutableDictionary;
@class NSEvent;
@class NSImage;
@class NSMutableArray;
@class NSMutableData;
@class GSDisplayServer;

#ifndef	NO_GNUSTEP
APPKIT_DECLARE GSDisplayServer * GSServerForWindow(NSWindow *window);
APPKIT_DECLARE GSDisplayServer * GSCurrentServer(void);

/* Display attributes */
APPKIT_DECLARE NSString * GSDisplayName;
APPKIT_DECLARE NSString * GSDisplayNumber;
APPKIT_DECLARE NSString * GSScreenNumber;

@interface GSDisplayServer : NSObject
{
  NSMutableDictionary	*server_info;
  NSMutableArray	*event_queue;
  NSMapTable		*drag_types;
}

+ (void) setDefaultServerClass: (Class)aClass;
+ (GSDisplayServer *) serverWithAttributes: (NSDictionary *)attributes;
+ (void) setCurrentServer: (GSDisplayServer *)server;

- initWithAttributes: (NSDictionary *)attributes;
- (NSDictionary *) attributes;
- (void) closeServer;

/* Drag and drop support. */
+ (BOOL) addDragTypes: (NSArray*)types toWindow: (NSWindow *)win;
+ (BOOL) removeDragTypes: (NSArray*)types fromWindow: (NSWindow *)win;
+ (NSCountedSet*) dragTypesForWindow: (NSWindow *)win;
- (BOOL) addDragTypes: (NSArray*)types toWindow: (NSWindow *)win;
- (BOOL) removeDragTypes: (NSArray*)types fromWindow: (NSWindow *)win;
- (NSCountedSet*) dragTypesForWindow: (NSWindow *)win;
- (id <NSDraggingInfo>) dragInfo;
- (BOOL) slideImage: (NSImage*)image from: (NSPoint)from to: (NSPoint)to;

/* Screen information */
- (NSSize) resolutionForScreen: (int)screen;
- (NSRect) boundsForScreen: (int)screen;
- (NSWindowDepth) windowDepthForScreen: (int)screen;
- (const NSWindowDepth *) availableDepthsForScreen: (int)screen;
- (NSArray *) screenList;

- (void *) serverDevice;
- (void *) windowDevice: (int)win;
@end

/* ----------------------------------------------------------------------- */
/* GNUstep Window operations */
/* ----------------------------------------------------------------------- */
@interface GSDisplayServer (WindowOps)
- (void) _setWindowOwnedByServer: (int)win;
- (int) window: (NSRect)frame : (NSBackingStoreType)type : (unsigned int)style;
- (int) window: (NSRect)frame : (NSBackingStoreType)type : (unsigned int)style
	      : (int)screen;
- (void) termwindow: (int) win;
- (void) stylewindow: (int) style : (int) win;
- (void) windowbacking: (NSBackingStoreType)type : (int) win;
- (void) titlewindow: (NSString *) window_title : (int) win;
- (void) miniwindow: (int) win;
- (BOOL) appOwnsMiniwindow;
- (void) windowdevice: (int) win;
- (void) orderwindow: (int) op : (int) otherWin : (int) win;
- (void) movewindow: (NSPoint)loc : (int) win;
- (void) placewindow: (NSRect)frame : (int) win;
- (NSRect) windowbounds: (int) win;
- (void) setwindowlevel: (int) level : (int) win;
- (int) windowlevel: (int) win;
- (NSArray *) windowlist;
- (int) windowdepth: (int) win;
- (void) setmaxsize: (NSSize)size : (int) win;
- (void) setminsize: (NSSize)size : (int) win;
- (void) setresizeincrements: (NSSize)size : (int) win;
- (void) flushwindowrect: (NSRect)rect : (int) win;
- (void) styleoffsets: (float*) l : (float*) r : (float*) t : (float*) b : (int) style;
- (void) docedited: (int) edited : (int) win;
- (void) setinputstate: (int)state : (int)win;
- (void) setinputfocus: (int) win;

- (NSPoint) mouselocation;
- (NSPoint) mouseLocationOnScreen: (int)aScreen window: (int *)win;
- (BOOL) capturemouse: (int) win;
- (void) releasemouse;
- (void) hidecursor;
- (void) showcursor;
- (void) standardcursor: (int) style : (void**) cid;
- (void) imagecursor: (NSPoint)hotp : (int)w : (int)h : (int) colors : (const char*) image : (void**) cid;
- (void) setcursorcolor: (NSColor *)fg : (NSColor *)bg : (void*) cid;

@end

/* ----------------------------------------------------------------------- */
/* GNUstep Event Operations */
/* ----------------------------------------------------------------------- */
@interface GSDisplayServer (EventOps)
- (NSEvent*) getEventMatchingMask: (unsigned)mask
		       beforeDate: (NSDate*)limit
			   inMode: (NSString*)mode
			  dequeue: (BOOL)flag;
- (void) discardEventsMatchingMask: (unsigned)mask
		       beforeEvent: (NSEvent*)limit;
- (void) postEvent: (NSEvent*)anEvent atStart: (BOOL)flag;
@end


static inline NSEvent*
DPSGetEvent(GSDisplayServer *ctxt, unsigned mask, NSDate* limit, NSString *mode)
{
  return [ctxt getEventMatchingMask: mask beforeDate: limit inMode: mode
	       dequeue: YES];
}

static inline NSEvent*
DPSPeekEvent(GSDisplayServer *ctxt, unsigned mask, NSDate* limit, NSString *mode)
{
  return [ctxt getEventMatchingMask: mask beforeDate: limit inMode: mode
	       dequeue: NO];
}

static inline void
DPSDiscardEvents(GSDisplayServer *ctxt, unsigned mask, NSEvent* limit)
{
  [ctxt discardEventsMatchingMask: mask beforeEvent: limit];
}

static inline void
DPSPostEvent(GSDisplayServer *ctxt, NSEvent* anEvent, BOOL atStart)
{
  [ctxt postEvent: anEvent atStart: atStart];
}

#endif /* NO_GNUSTEP */
#endif
