/*
   GSComboSupport.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decillion.net>
   Date: 1999

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

#import <AppKit/AppKit.h>
#import "GSComboSupport.h"

@implementation GSComboWindow

+ (GSComboWindow *)defaultPopUp
{
   static GSComboWindow	*gsWindow = nil;

   if (!gsWindow)
      gsWindow = [[self alloc] initWithContentRect:NSMakeRect(0,0,100,100)
			       styleMask:NSBorderlessWindowMask
			       backing:NSBackingStoreBuffered
			       defer:YES];
   return gsWindow;
}

- (id)initWithContentRect:(NSRect)contentRect
		styleMask:(unsigned int)aStyle
		  backing:(NSBackingStoreType)bufferingType
		    defer:(BOOL)flag
{
   NSBox	*box;
   
   self = [super initWithContentRect:contentRect
		 styleMask:aStyle
		 backing:bufferingType
		 defer:flag];
   box = [[[NSBox alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
   [box setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
   [box setBorderType:NSLineBorder];
   [box setTitlePosition:NSNoTitle];
   [box setContentViewMargins:NSMakeSize(1,1)];
   [box sizeToFit];
   [self setContentView:box];
   browser = [[[GSPopUpActionBrowser alloc]
		 initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
   [browser setMaxVisibleColumns:1];
   [browser setTitled:NO];
   [browser setHasHorizontalScroller:NO];
   [browser setTarget:self];
   [browser setAction: @selector(selectItem:)];
   [browser setDelegate:self];
//    [browser setRefusesFirstResponder:YES];
   [browser setAutoresizingMask:NSViewWidthSizable | NSViewWidthSizable];
   [browser setAllowsEmptySelection:NO];
   [browser setAllowsMultipleSelection:NO];
   [box setContentView:browser];
   return self;
}

- (void)dealloc
{
   // Browser was not retained so don't release it
   [super dealloc];
}

- (NSMatrix *)matrix { return [browser matrixInColumn:0]; }

- (NSSize)popUpSize
{
   float	itemHeight;
   float	cellSpacing;

   if (!_cell)
      return NSZeroSize;
   
   if (![_cell isKindOfClass:[NSComboBoxCell class]])
      [NSEvent raise:@"GSComboWindow" format:@"Cell not a NSComboBoxCell"];

   itemHeight = [_cell itemHeight];
   cellSpacing = [_cell intercellSpacing].height;

   if (itemHeight <= 0)
      itemHeight = [[self matrix] cellSize].height;

   if (cellSpacing <= 0)
      cellSpacing = [[self matrix] intercellSpacing].height;
   return NSMakeSize(2.0 + [NSScroller scrollerWidth] + 100.0,
		     2.0 + (itemHeight * [_cell numberOfVisibleItems]) +
		     (cellSpacing * [_cell numberOfVisibleItems]));
}

- (NSSize)popUpCellSizeForPopUp:(NSComboBoxCell *)aCell
{
   NSSize	size;
   
   _cell = aCell;
   size = [self popUpSize];
   size.height += 4.0;
   size.width += 4.0;
   _cell = nil;
   return size;
}

- (void)popUpCell:(NSComboBoxCell *)aCell
	  popUpAt:(NSPoint)aPoint
	    width:(float)aWidth
{
   NSRect	rect;
   
   rect.size = [self popUpCellSizeForPopUp:aCell];
   _cell = aCell;
   _width = aWidth;
   _point = aPoint;

   rect.size.width = _width;
   rect.origin.x = _point.x;
   rect.origin.y = _point.y;
   
   [self setFrame:rect display:NO];

   [_cell reloadData];
   [browser loadColumnZero];
   
//    [self enableKeyEquivalentForDefaultButtonCell];
   [self runModalPopUp];

   _cell = nil;
}

- (void)runModalPopUp
{
   NSWindow	*onWindow;
   NSEvent	*event;
   NSException	*exception = nil;

   onWindow = [[_cell controlView] window];
   [self setLevel:[onWindow level]];
   [self orderWindow:NSWindowAbove relativeTo:[onWindow windowNumber]];

   while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
			  untilDate:[NSDate dateWithTimeIntervalSinceNow:0]
			  inMode:NSDefaultRunLoopMode
			  dequeue:NO]))
   {
      if ([event type] == NSAppKitDefined ||
	  [event type] == NSSystemDefined ||
	  [event type] == NSApplicationDefined ||
	  [event windowNumber] == [self windowNumber])
	 break;
      [NSApp nextEventMatchingMask:NSAnyEventMask
	     untilDate:[NSDate distantFuture]
	     inMode:NSDefaultRunLoopMode
	     dequeue:YES];
   }

   [self makeKeyAndOrderFront:nil];

   _shouldOrder = YES;

   NS_DURING
      [self runLoop];
   NS_HANDLER
      exception = localException;
   NS_ENDHANDLER;

   if (onWindow && _shouldOrder)
   {
      [onWindow makeKeyWindow];
      [onWindow orderFrontRegardless];
   }

   if ([self isVisible])
      [self orderOut:nil];

   if (exception)
      [exception raise];
}

- (void)runLoop
{
   NSEvent		*event;
   int			cnt;
   NSAutoreleasePool	*pool;
   BOOL			kDown;

   cnt = 0;
   pool = [[NSAutoreleasePool alloc] init];
   _stopped = NO;
   _shouldNotify = YES;
   while (!_stopped)
   {
      kDown = NO;
      cnt++;
      if (cnt >= 5)
      {
	 [pool release];
	 pool = [[NSAutoreleasePool alloc] init];
	 cnt = 0;
      }
      event = [NSApp nextEventMatchingMask:NSAnyEventMask
		     untilDate:[NSDate distantFuture]
		     inMode:NSDefaultRunLoopMode
		     dequeue:NO];
      if (event)
      {
	 if ([event type] == NSAppKitDefined ||
	     [event type] == NSSystemDefined ||
	     [event type] == NSApplicationDefined ||
	     [event windowNumber] == [self windowNumber])
	 {
	    event = [NSApp nextEventMatchingMask:NSAnyEventMask
			   untilDate:[NSDate distantFuture]
			   inMode:NSDefaultRunLoopMode
			   dequeue:YES];
	    [NSApp sendEvent:event];
	    if ([event type] == NSKeyDown)
	       kDown = YES;
	 }
	 else if ([event type] == NSMouseMoved ||
		  [event type] == NSLeftMouseDragged ||
		  [event type] == NSRightMouseDragged ||
		  [event type] == NSMouseEntered ||
		  [event type] == NSMouseExited ||
		  [event type] == NSCursorUpdate)
	 {
	    event = [NSApp nextEventMatchingMask:NSAnyEventMask
			   untilDate:[NSDate distantFuture]
			   inMode:NSDefaultRunLoopMode
			   dequeue:YES];
	    [NSApp sendEvent:event];
	 }
	 else
	    _stopped = YES;
      }
   }
   _shouldNotify = NO;
   if (kDown)
      while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
			     untilDate:[NSDate distantFuture]
			     inMode:NSDefaultRunLoopMode
			     dequeue:NO]))
      {
	 if ([event windowNumber] != [self windowNumber])
	    break;
	 event = [NSApp nextEventMatchingMask:NSAnyEventMask
			untilDate:[NSDate distantFuture]
			inMode:NSDefaultRunLoopMode
			dequeue:YES];
	 [NSApp sendEvent:event];
	 if ([event type] == NSKeyUp)
	    break;
      }
   [pool release];
}

- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)worksWhenModal { return NO; }

// Target/Action of Browser
- (void)selectItem:(id)sender
{
   if (_cell && [_cell isKindOfClass:[NSComboBoxCell class]])
   {
      [_cell setStringValue:[[sender selectedCell] stringValue]];
      _stopped = YES;
   }
}

// Browser Delegate Methods
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
   if (!(_cell && [_cell isKindOfClass:[NSComboBoxCell class]]))
      return 0;
   [list release];
   list = [[_cell objectValues] retain];
   return [list count];
   return 0;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)aCell
	  atRow:(int)row column:(int)column
{
   [aCell setStringValue:[list objectAtIndex:row]];
   [aCell setLeaf:YES];
}

@end

@implementation GSPopUpActionBrowser

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
   // This Jippo is there because the browser does not want to send
   // the action if we came from a modal panel
   if (theTarget && theAction && [theTarget respondsToSelector:theAction])
   {
      [theTarget performSelector:theAction withObject:self];
      return YES;
   }
   return [super sendAction:theAction to:theTarget];
}

@end
