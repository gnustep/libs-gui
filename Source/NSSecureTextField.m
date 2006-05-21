/** <title>NSSecureTextField</title>

   <abstract>Secure Text field control class for hidden text entry</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Gregory John Casamento <borgheron@yahoo.com>
   Date: 2000

   Author: Nicola Pero <nicola@brainstorm.co.uk>
   Date: October 2002

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include <Foundation/NSException.h>
#include "AppKit/NSSecureTextField.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSLayoutManager.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSEvent.h"

/* 'Secure' subclasses */
@interface NSSecureTextView : NSTextView
{}
@end

@interface GSSimpleSecureLayoutManager : NSLayoutManager
{}
@end

@implementation NSSecureTextField

+ (void) initialize
{
  if (self == [NSSecureTextField class])
    {
      [self setVersion:2];
    }
}

+ (Class) cellClass
{
  /* Hard code here to make sure no other class is used.  */
  return [NSSecureTextFieldCell class];
}

+ (void) setCellClass: (Class)factoryId
{
  /* Ward off interlopers with a stern message.  */
  [NSException raise: NSInvalidArgumentException
	       format: @"NSSecureTextField only uses NSSecureTextFieldCells."];
}

- (id) initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  [self setEchosBullets: YES];

  return self;
}

- (void) setEchosBullets: (BOOL)flag
{
  [_cell setEchosBullets: flag];
}

- (BOOL) echosBullets
{
  return [_cell echosBullets];
}
@end /* NSSecureTextField */

@implementation NSSecureTextFieldCell

+ (void)initialize
{
  if (self == [NSSecureTextFieldCell class])
    {
      [self setVersion:2];
    }
}

- (BOOL) echosBullets
{
  return _echosBullets;
}

/* Functionality not implemented.  */
- (void) setEchosBullets: (BOOL)flag
{
  _echosBullets = flag;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView *)controlView
{
  /* Draw background, then ... */ 
  if (_textfieldcell_draws_background)
    {
      [_background_color set];
      NSRectFill ([self drawingRectForBounds: cellFrame]);
    }
  /* .. do nothing.  */
}

- (NSText *) setUpFieldEditorAttributes: (NSText *)textObject
{
  /* Replace the text object with a secure instance.  It's not shared.  */
  textObject = [NSSecureTextView new];
  AUTORELEASE (textObject);

  return [super setUpFieldEditorAttributes: textObject];
}

- (id) initWithCoder: (NSCoder *)decoder
{
  self = [super initWithCoder: decoder];
  if([decoder allowsKeyedCoding])
    {
      // do nothing for now...
    }
  else
    {
      [decoder decodeValueOfObjCType: @encode(BOOL) at: &_echosBullets];
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_echosBullets];
}

@end

@implementation GSSimpleSecureLayoutManager
- (void) drawGlyphsForGlyphRange: (NSRange)glyphRange
			 atPoint: (NSPoint)containerOrigin
{
  /* Do nothing.  */
}
@end

@implementation NSSecureTextView

- (id) initWithFrame: (NSRect)frameRect
       textContainer: (NSTextContainer*)aTextContainer
{
  GSSimpleSecureLayoutManager *m;

  /* Perform the normal init.  */
  [super initWithFrame: frameRect  textContainer: aTextContainer];

  /* Then, replace the layout manager with a
   * GSSimpleSecureLayoutManager.  */
  m = [[GSSimpleSecureLayoutManager alloc] init];
  AUTORELEASE (m);
  [[self textContainer] replaceLayoutManager: m];

  [self setFieldEditor: YES];

  return self;
}

- (void) copy: (id)sender
{
  /* Do nothing since copying from a NSSecureTextView is not permitted.  */
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pboard
			      types: (NSArray*)types
{
  /* Return NO since the selection should never be written to the
   * pasteboard */
  return NO;
}

- (id) validRequestorForSendType: (NSString*) sendType
		      returnType: (NSString*) returnType
{
  /* Return nil to indicate that no type can be sent to the pasteboard
   * for an object of this class.  */
  return nil;
}
@end
