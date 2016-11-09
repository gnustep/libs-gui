/** <title>GSDisplayServer</title>

   <abstract>Abstract display server class.</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Mar 2002
   
   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _GSDisplayServer_h_INCLUDE
#define _GSDisplayServer_h_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#import <AppKit/AppKitDefines.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSGraphicsContext.h>

@class NSArray;
@class NSCountedSet;
@class NSDictionary;
@class NSMapTable;
@class NSMutableArray;
@class NSMutableData;
@class NSMutableDictionary;
@class NSString;

@class NSEvent;
@class NSImage;

@class GSDisplayServer;
@class NSGraphicsContext;
@class NSWindow;

#if !NO_GNUSTEP
APPKIT_EXPORT GSDisplayServer *GSServerForWindow(NSWindow *window);
APPKIT_EXPORT GSDisplayServer *GSCurrentServer(void);

/* Display attributes */
APPKIT_EXPORT NSString *GSDisplayName;
APPKIT_EXPORT NSString *GSDisplayNumber;
APPKIT_EXPORT NSString *GSScreenNumber;

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

/* GL context */
- glContextClass;
- glPixelFormatClass;

- (BOOL) handlesWindowDecorations;

/* Drag and drop support. */
+ (BOOL) addDragTypes: (NSArray*)types toWindow: (NSWindow *)win;
+ (BOOL) removeDragTypes: (NSArray*)types fromWindow: (NSWindow *)win;
+ (NSCountedSet*) dragTypesForWindow: (NSWindow *)win;
- (BOOL) addDragTypes: (NSArray*)types toWindow: (NSWindow *)win;
- (BOOL) removeDragTypes: (NSArray*)types fromWindow: (NSWindow *)win;
- (NSCountedSet*) dragTypesForWindow: (NSWindow *)win;
- (id <NSDraggingInfo>) dragInfo;
- (BOOL) slideImage: (NSImage*)image from: (NSPoint)from to: (NSPoint)to;
- (void) restrictWindow: (NSInteger)win toImage: (NSImage*)image;
- (int) findWindowAt: (NSPoint)screenLocation 
           windowRef: (int*)windowRef 
           excluding: (int)win;


/* Screen information */
- (NSSize) resolutionForScreen: (int)screen;
- (NSRect) boundsForScreen: (int)screen;
- (NSWindowDepth) windowDepthForScreen: (int)screen;
- (const NSWindowDepth *) availableDepthsForScreen: (int)screen;
- (NSArray *) screenList;

- (void *) serverDevice;
- (void *) windowDevice: (NSInteger)win;

- (void) beep;

/* AppIcon/MiniWindow information */
- (NSImage *) iconTileImage;
- (NSSize) iconSize;

/* Screen capture */ 
- (NSImage *) contentsOfScreen: (int)screen inRect: (NSRect)rect;

@end

/* ----------------------------------------------------------------------- */
/* GNUstep Window operations */
/* ----------------------------------------------------------------------- */
@interface GSDisplayServer (WindowOps)
- (void) _setWindowOwnedByServer: (NSInteger)win;
- (NSInteger) window: (NSRect)frame : (NSBackingStoreType)type : (unsigned int)style;
- (NSInteger) window: (NSRect)frame : (NSBackingStoreType)type : (unsigned int)style
	      : (int)screen;
- (void) termwindow: (NSInteger)win;
- (NSInteger) nativeWindow: (void *)winref : (NSRect*)frame : (NSBackingStoreType*)type
                    : (unsigned int*)style : (int*)screen;

/* Only if handlesWindowDecorations returns YES. */
- (void) stylewindow: (unsigned int)style : (NSInteger)win;

- (void) windowbacking: (NSBackingStoreType)type : (NSInteger)win;
- (void) titlewindow: (NSString *)window_title : (NSInteger)win;
- (void) miniwindow: (NSInteger)win;
- (BOOL) appOwnsMiniwindow;
- (void) setWindowdevice: (NSInteger)win forContext: (NSGraphicsContext *)ctxt;
// Deprecated
- (void) windowdevice: (NSInteger) winNum;
- (void) orderwindow: (int)op : (NSInteger)otherWin : (NSInteger)win;
- (void) movewindow: (NSPoint)loc : (NSInteger)win;
- (void) placewindow: (NSRect)frame : (NSInteger)win;
- (NSRect) windowbounds: (NSInteger)win;
- (void) setwindowlevel: (int)level : (NSInteger)win;
- (int) windowlevel: (NSInteger)win;
- (NSArray *) windowlist;
- (int) windowdepth: (NSInteger)win;
- (void) setmaxsize: (NSSize)size : (NSInteger)win;
- (void) setminsize: (NSSize)size : (NSInteger)win;
- (void) setresizeincrements: (NSSize)size : (NSInteger)win;
- (void) flushwindowrect: (NSRect)rect : (NSInteger)win;
- (void) styleoffsets: (float*)l : (float*)r : (float*)t : (float*)b 
                     : (unsigned int)style;
- (void) docedited: (int) edited : (NSInteger)win;
- (void) setinputstate: (int)state : (NSInteger)win;
- (void) setinputfocus: (NSInteger)win;
- (void) setalpha: (float)alpha : (NSInteger)win;
- (void) setShadow: (BOOL)hasShadow : (NSInteger)win;

- (NSPoint) mouselocation;
- (NSPoint) mouseLocationOnScreen: (int)aScreen window: (NSInteger *)win;
- (BOOL) capturemouse: (NSInteger)win;
- (void) releasemouse;
- (void) setMouseLocation: (NSPoint)mouseLocation onScreen: (int)aScreen;
- (void) hidecursor;
- (void) showcursor;
- (void) standardcursor: (int) style : (void**)cid;
- (void) imagecursor: (NSPoint)hotp : (NSImage *) image : (void**)cid;
- (void) setcursorcolor: (NSColor *)fg : (NSColor *)bg : (void*)cid;
- (void) recolorcursor: (NSColor *)fg : (NSColor *)bg : (void*) cid;
- (void) setcursor: (void*) cid;
- (void) freecursor: (void*) cid;
- (void) setParentWindow: (NSInteger)parentWin 
          forChildWindow: (NSInteger)childWin;
- (void) setIgnoreMouse: (BOOL)ignoreMouse : (NSInteger)win;

@end

// Testplant-MAL-10042016: support for checking running services i.e. bonjour
/* ----------------------------------------------------------------------- */
/* GNUstep Window operations */
/* ----------------------------------------------------------------------- */
@interface GSDisplayServer (ServiceOps)
- (BOOL) isServiceInstalled: (NSString*)serviceName;
- (BOOL) isServiceRunning: (NSString*)serviceName;
- (BOOL) isDiscoveryServiceInstalled;
- (BOOL) isDiscoveryServiceRunning;
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
- (void) _printEventQueue;
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
