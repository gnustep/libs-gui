/* -*- C++ -*-
   NSSecureTextField.m

   Secure Text field control class for hidden text entry

   Copyright (C) 1999 Free Software Foundation, Inc.

   Original Author:  Lyndon Tremblay <humasect@coolmail.com>
   Date: 1999

   Rewrite by: Gregory John Casamento <borgheron@yahoo.com>
   Date: 2000

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

//
// NOTE:
//
// All selecting methods have been overriden to do nothing, I don't know if this
// will hinder overall behavior of the specs, as I have never used the real thing.
//

#include <gnustep/gui/config.h>
#include <AppKit/NSSecureTextField.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include "GSSimpleLayoutManager.h"

/* Other secure subclasses */
@interface NSSecureTextView : NSTextView
{
}
@end

@interface GSSimpleSecureLayoutManager : GSSimpleLayoutManager
{
}
@end

@implementation NSSecureTextField

/*
==============
+initialize
==============
*/
+ (void) initialize
{
  if (self == [NSSecureTextField class]) {
	[self setVersion:1];
  }
}

/*
============
+ cellClass
============
*/
+ (Class) cellClass
{
  // Hard code here to make sure no other class can be used.
  return [NSSecureTextFieldCell class];
}

/*
============
+ setCellClass
============
*/
+ (void) setCellClass: (Class)factoryId
{
  // Ward off interlopers with a stern message.
  [NSException raise: NSInvalidArgumentException
	      format: @"NSSecureTextField can only use NSSecureTextFieldCells in order to ensure security."];
}

/*
==============
-initWithFrame:
==============
*/
- (id) initWithFrame:(NSRect)frameRect
{
  [super initWithFrame: frameRect];
  [_cell setEchosBullets: YES];

  return self;
}

/*
==============
-initWithCoder:
==============
*/
- (id) initWithCoder:(NSCoder *)decoder
{
  BOOL echosBullets = YES;

  [super initWithCoder: decoder];
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &echosBullets];
  [_cell setEchosBullets: echosBullets];

  return self;
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  [_text_object setText: [[aNotification object] text]]; 
  [super textDidEndEditing: aNotification];
}
@end /* NSSecureTextField */

@implementation NSSecureTextFieldCell
/*
==============
+initialize
==============
*/
+ (void)initialize
{
  if (self == [NSSecureTextFieldCell class])
	[self setVersion:1];
}

/*
==================================
+_sharedSecureFieldEditorInstance
==================================
*/
+ (id)_sharedSecureFieldEditorInstance
{
  static NSSecureTextView *secureView = nil;

  if( secureView == nil )
    {
      secureView = [[NSSecureTextView alloc] init];
      [secureView setFieldEditor: YES];
      [secureView setText: @""];
    }

  return secureView; 
}

/*
===============
-echosBullets
===============
*/
- (BOOL)echosBullets
{
  return i_echosBullets;
}

/*
================
+setEchosBullets:
================
*/
- (void)setEchosBullets:(BOOL)flag
{
  i_echosBullets = flag;
}

/*
===============
-drawInteriorWithFrame:
===============
*/
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  // do nothing....
}

/*
 * Editing Text
 */
- (void) editWithFrame: (NSRect)aRect
		inView: (NSView*)controlView
		editor: (NSText*)textObject 
	      delegate: (id)anObject
		 event: (NSEvent*)theEvent
{
  id l_editor = [NSSecureTextFieldCell _sharedSecureFieldEditorInstance];

  [l_editor setText: [textObject text]];
  [super editWithFrame: aRect
		inView: controlView
		editor: l_editor
	      delegate: anObject
		 event: theEvent];
}

- (void) selectWithFrame: (NSRect)aRect
		  inView: (NSView*)controlView
		  editor: (NSText*)textObject
		delegate: (id)anObject
		   start: (int)selStart
		  length: (int)selLength
{
  id l_editor = [NSSecureTextFieldCell _sharedSecureFieldEditorInstance];

  [l_editor setText: [textObject text]];
  [super selectWithFrame: aRect
		  inView: controlView
                  editor: l_editor
		delegate: anObject
		   start: selStart
                  length: selLength];
}
@end

@implementation GSSimpleSecureLayoutManager
- (void) drawGlyphsForGlyphRange: (NSRange)glyphRange
			 atPoint: (NSPoint)containerOrigin
{
  // do nothing...  
}
@end

@implementation NSSecureTextView
/* Class methods */
+ (void) initialize
{
  if ([self class] == [NSSecureTextView class])
    {
      [self setVersion: 1];
      [self registerForServices];
    }
}

- (id) initWithFrame: (NSRect)frameRect
{
  NSTextContainer *aTextContainer = 
      [[NSTextContainer alloc] initWithContainerSize: frameRect.size];
  GSSimpleSecureLayoutManager *layoutManager = [[GSSimpleSecureLayoutManager alloc] init];
  
  [super initWithFrame: frameRect];
  [layoutManager addTextContainer: aTextContainer];
  RELEASE(aTextContainer);

  _textStorage = [[NSTextStorage alloc] init];
  [_textStorage addLayoutManager: layoutManager];
  RELEASE(layoutManager);

  return [self initWithFrame: frameRect textContainer: aTextContainer];
}

- (void) copy: (id)sender
{
  // Do nothing since copying from a NSSecureTextView is *not* permitted.
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
			      types: (NSArray*)types
{
  /* Returns NO since the selection should never be 
     written to the pasteboard */
  return NO;
}

- (id) validRequestorForSendType: (NSString*) sendType
		      returnType: (NSString*) returnType
{
  /* return "nil" to indicate that no type can be sent to the pasteboard for
     an object of this class */
  return nil;
}
@end
