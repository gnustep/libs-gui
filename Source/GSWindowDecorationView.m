/** <title>GSWindowDecorationView</title>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2004-03-24

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "GSWindowDecorationView.h"

#include <Foundation/NSException.h>

#include "AppKit/NSColor.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSDisplayServer.h"


struct NSWindow_struct
{
  @defs(NSWindow)
};


/*
Manage window decorations by using the backend functions. This only works
on backends that can handle window decorations.
*/
@interface GSBackendWindowDecorationView : GSWindowDecorationView
@end


/*
GSWindowDecorationView implementation.
*/
@implementation GSWindowDecorationView

+(id<GSWindowDecorator>) windowDecorator
{
  if ([GSCurrentServer() handlesWindowDecorations])
    return [GSBackendWindowDecorationView self];
  else
    return [GSStandardWindowDecorationView self];
}


+(id) newWindowDecorationViewWithFrame: (NSRect)frame
				window: (NSWindow *)aWindow
{
  return [[self alloc] initWithFrame: frame
			      window: aWindow];
}


+(void) offsets: (float *)l : (float *)r : (float *)t : (float *)b
   forStyleMask: (unsigned int)style
{
  [self subclassResponsibility: _cmd];
}

+ (NSRect) contentRectForFrameRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle
{
  float t, b, l, r;

  [self offsets: &l : &r : &t : &b
   forStyleMask: aStyle];
  aRect.size.width -= l + r;
  aRect.size.height -= t + b;
  aRect.origin.x += l;
  aRect.origin.y += b;
  return aRect;
}

+ (NSRect) frameRectForContentRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle
{
  float t, b, l, r;

  [self offsets: &l : &r : &t : &b
   forStyleMask: aStyle];
  aRect.size.width += l + r;
  aRect.size.height += t + b;
  aRect.origin.x -= l;
  aRect.origin.y -= b;
  return aRect;
}

+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle
{
  [self subclassResponsibility: _cmd];
  return 0.0;
}


/*
Internal helpers.

Returns the internal window frame rect for a given (screen) frame.
*/
+(NSRect) windowFrameRectForFrameRect: (NSRect)aRect
			    styleMask: (unsigned int)aStyle
{
  aRect.origin = NSZeroPoint;
  return aRect;
}

/*
Returns the content rect for a given window frame.
*/
+(NSRect) contentRectForWindowFrameRect: (NSRect)aRect
			      styleMask: (unsigned int)aStyle
{
  return [self contentRectForFrameRect: aRect  styleMask: aStyle];
}


- initWithFrame: (NSRect)frame
{
  NSAssert(NO, @"Tried to create GSWindowDecorationView without a window!");
  return nil;
}

- initWithFrame: (NSRect)frame
	 window: (NSWindow *)w
{
  frame = [isa windowFrameRectForFrameRect: frame
				 styleMask: [w styleMask]];

  self = [super initWithFrame: frame];
  if (!self)
    return nil;
    
  window = w;
  contentRect = frame;
  contentRect =
    [isa contentRectForWindowFrameRect: contentRect
			     styleMask: [window styleMask]];

  return self;
}

/*
 * Special setFrame: implementation - a minimal autoresize mechanism
 */
- (void) setFrame: (NSRect)frameRect
{
  NSSize oldSize = _frame.size;
  NSView *cv = [_window contentView];

  frameRect = [isa windowFrameRectForFrameRect: frameRect
				     styleMask: [window styleMask]];

  _autoresizes_subviews = NO;
  [super setFrame: frameRect];

  contentRect = [isa contentRectForWindowFrameRect: frameRect
					 styleMask: [window styleMask]];

  // Safety Check.
  [cv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [cv resizeWithOldSuperviewSize: oldSize];
}

- (void) setContentView: (NSView *)contentView
{
  NSSize oldSize;

  [contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [self addSubview: contentView];

  oldSize = [contentView frame].size;
  oldSize.width += _frame.size.width - contentRect.size.width;
  oldSize.height += _frame.size.height - contentRect.size.height;
  [contentView resizeWithOldSuperviewSize: oldSize];
  [contentView setFrameOrigin: NSMakePoint(contentRect.origin.x,
					   contentRect.origin.y)];
}

-(void) setWindowNumber: (int)theWindowNumber
{
  windowNumber = theWindowNumber;
  if (!windowNumber)
    return;

  [GSServerForWindow(window) titlewindow: [window title] : windowNumber];
  [GSServerForWindow(window) setinputstate: inputState : windowNumber];
  [GSServerForWindow(window) docedited: documentEdited : windowNumber];
}

-(void) setTitle: (NSString *)title
{
  if (windowNumber)
    [GSServerForWindow(window) titlewindow: title : windowNumber];
}
-(void) setInputState: (int)state
{
  inputState = state;
  if (windowNumber)
    [GSServerForWindow(window) setinputstate: inputState : windowNumber];
}
-(void) setDocumentEdited: (BOOL)flag
{
  documentEdited = flag;
  if (windowNumber)
    [GSServerForWindow(window) docedited: documentEdited : windowNumber];
}


- (BOOL) isOpaque
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  NSColor *c = [_window backgroundColor];

  if (NSIntersectsRect(rect, contentRect))
    {
      [c set];
      NSRectFill(contentRect);
    }
}



- initWithCoder: (NSCoder*)aCoder
{
  NSAssert(NO, @"The top-level window view should never be encoded.");
  return nil;
}
-(void) encodeWithCoder: (NSCoder*)aCoder
{
  NSAssert(NO, @"The top-level window view should never be encoded.");
}

@end



@implementation GSBackendWindowDecorationView

+(void) offsets: (float *)l : (float *)r : (float *)t : (float *)b
   forStyleMask: (unsigned int)style
{
  [GSCurrentServer() styleoffsets: l : r : t : b : style];
}
+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle
{
  /* TODO: we could at least guess... */
  return 0.0;
}

+(NSRect) windowFrameRectForFrameRect: (NSRect)aRect
			    styleMask: (unsigned int)aStyle
{
  float l, r, t, b;
  [self offsets: &l : &r : &t : &b forStyleMask: aStyle];
  aRect.size.width -= l + r;
  aRect.size.height -= t + b;
  return aRect;
}

/*
Returns the content rect for a given window frame.
*/
+(NSRect) contentRectForWindowFrameRect: (NSRect)aRect
			      styleMask: (unsigned int)aStyle
{
  return aRect;
}

@end

