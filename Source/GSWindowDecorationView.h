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

#ifndef _GNUstep_H_GSWindowDecorationView
#define _GNUstep_H_GSWindowDecorationView

#include <Foundation/NSGeometry.h>
#include "AppKit/NSView.h"

@class NSWindow;

@protocol GSWindowDecorator
- (id) newWindowDecorationViewWithFrame: (NSRect)frame
				 window: (NSWindow *)window;

- (NSRect) contentRectForFrameRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;
- (NSRect) frameRectForContentRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle;
- (NSRect) screenRectForFrameRect: (NSRect)aRect
			styleMask: (unsigned int)aStyle;
- (NSRect) frameRectForScreenRect: (NSRect)aRect
			styleMask: (unsigned int)aStyle;
- (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle;
@end


/*
Abstract superclass for the top-level view in each window. This view is
responsible for managing window decorations. Concrete subclasses may do
this, either directly, or indirectly (by using the backend).
*/
@interface GSWindowDecorationView : NSView
{
  NSWindow *window; /* not retained */
  int windowNumber;

  NSRect contentRect;

  int inputState;
  BOOL documentEdited;
}
+(id<GSWindowDecorator>) windowDecorator;

- initWithFrame: (NSRect)frame
	 window: (NSWindow *)w;

-(void) setContentView: (NSView *)contentView;

/*
Called when the backend window is created or destroyed. When it's destroyed,
windowNumber will be 0.
*/
-(void) setWindowNumber: (int)windowNumber;

-(void) setTitle: (NSString *)title;
-(void) setInputState: (int)state;
-(void) setDocumentEdited: (BOOL)flag;
-(void) setBackgroundColor: (NSColor *)color;
@end


/*
Standard OPENSTEP-ish window decorations.
*/
@class NSButton;

@interface GSStandardWindowDecorationView : GSWindowDecorationView
{
  BOOL hasTitleBar, hasResizeBar, hasCloseButton, hasMiniaturizeButton;
  BOOL isTitled;
  NSRect titleBarRect;
  NSRect resizeBarRect;
  NSRect closeButtonRect;
  NSRect miniaturizeButtonRect;

  NSButton *closeButton, *miniaturizeButton;
}
@end

#endif

