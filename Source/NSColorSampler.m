/* Implementation of class NSColorSampler
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Thu Mar 12 03:11:27 EDT 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSGeometry.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColorSampler.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSPanel.h>

#import <GNUstepGUI/GSDisplayServer.h>

@interface NSWindow (private)
- (void) _captureMouse: sender;
- (void) _releaseMouse: sender;
@end

@implementation NSColorSampler

- (void) showSamplerWithSelectionHandler: (GSColorSampleHandler)selectionHandler
{
  NSEvent *currentEvent;
  NSCursor *cursor;
  NSRect contentRect = NSMakeRect(-1024,-1024,0,0);
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask
    | NSResizableWindowMask | NSUtilityWindowMask;
  NSPanel *w = [[NSPanel alloc] initWithContentRect: contentRect
                                           styleMask: style
                                             backing: NSBackingStoreRetained
                                               defer: NO
                                              screen: nil];      
  NSColor *color = nil;
  
  [w orderFront: nil];
  [w _captureMouse: self];

  /**
   * There was code here to dynamically generate a magnifying glass
   * cursor with a magnified portion of the screenshot in it,
   * but changing the cursor rapidly on X seems to cause flicker,
   * so we just use a plain magnifying glass. (dynamic code is in r33543)
   */
  cursor = [[[NSCursor alloc] initWithImage: [NSImage imageNamed: @"MagnifyGlass"]
					      hotSpot: NSMakePoint(12, 13)] autorelease];
  [cursor push];

  NS_DURING
    {
      do
        {
          NSPoint mouseLoc;
          NSImage *img;
          CREATE_AUTORELEASE_POOL(pool);
          
          RELEASE(color);
          currentEvent = [NSApp nextEventMatchingMask: NSLeftMouseDownMask | NSLeftMouseUpMask | NSMouseMovedMask
                                            untilDate: [NSDate distantFuture]
                                               inMode: NSEventTrackingRunLoopMode
                                              dequeue: YES];
          
          mouseLoc = [w convertBaseToScreen: [w mouseLocationOutsideOfEventStream]];
          
          img = [GSCurrentServer() contentsOfScreen: [[w screen] screenNumber]
                                             inRect: NSMakeRect(mouseLoc.x, mouseLoc.y, 1, 1)];
          
          if (nil != img)
            {
              NSBitmapImageRep *rep = (NSBitmapImageRep *)[img bestRepresentationForDevice: nil];
              color = [rep colorAtX: 0 y: 0];
              RETAIN(color);
            }
          [pool drain];
        } while ([currentEvent type] != NSLeftMouseUp && 
                 [currentEvent type] != NSLeftMouseDown);
    }
  NS_HANDLER
    {
      NSLog(@"Exception occurred in -[NSColorSampler showSamplerWithSelectionHandler:] : %@",
	    localException);
    }
  NS_ENDHANDLER;
  
  CALL_BLOCK(selectionHandler, color);
  RELEASE(color);
  [NSCursor pop];
  [w _releaseMouse: self];
  [w close];
}

@end

