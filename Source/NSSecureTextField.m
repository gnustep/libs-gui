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

#include "AppKit/NSAttributedString.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSLayoutManager.h"
#include "AppKit/NSSecureTextField.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSWindow.h"

/* 'Secure' subclasses */
@interface NSSecureTextView : NSTextView
{
}
- (void) setEchosBullets:(BOOL)flag;
- (BOOL) echosBullets;
@end

@interface GSSimpleSecureLayoutManager : NSLayoutManager
{
  BOOL _echosBullets;
}
- (void) setEchosBullets:(BOOL)flag;
- (BOOL) echosBullets;
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

- (NSAttributedString *)_replacementAttributedString
{
  NSDictionary *attributes;
  NSMutableString *string;
  unsigned int length;
  unsigned int i;

  length = [[self stringValue] length];
  string = [[NSMutableString alloc] initWithCapacity: length];
  for (i = 0; i < length; i++)
    {
      [string appendString: @"*"];
    }
  AUTORELEASE(string);

  attributes = [self _nonAutoreleasedTypingAttributes];
  return AUTORELEASE([[NSAttributedString alloc] initWithString: string 
                                                 attributes: attributes]);
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView *)controlView
{
  cellFrame = [self drawingRectForBounds: cellFrame];

  /* Draw background, then ... */ 
  if (_textfieldcell_draws_background)
    {
      if ([self isEnabled])
        {
          [_background_color set];
        }
      else
        {
          [[NSColor controlBackgroundColor] set];
        }
      NSRectFill(cellFrame);
    }

  if (_echosBullets)
    {
      // Add spacing between border and inside 
      if (_cell.is_bordered || _cell.is_bezeled)
        {
          cellFrame.origin.x += 3;
          cellFrame.size.width -= 6;
          cellFrame.origin.y += 1;
          cellFrame.size.height -= 2;
        }

      if (!_cell.is_disabled)
        {
          [self _drawAttributedText: [self _replacementAttributedString]
                inFrame: cellFrame];
        }
      else
        {
          NSAttributedString *attrStr = [self _replacementAttributedString];
          NSDictionary *attribs;
          NSMutableDictionary *newAttribs;
          
          attribs = [attrStr attributesAtIndex: 0 
                             effectiveRange: NULL];
          newAttribs = [NSMutableDictionary 
                           dictionaryWithDictionary: attribs];
          [newAttribs setObject: [NSColor disabledControlTextColor]
                      forKey: NSForegroundColorAttributeName];
          
          attrStr = [[NSAttributedString alloc]
                        initWithString: [attrStr string]
                        attributes: newAttribs];
          [self _drawAttributedText: attrStr 
                inFrame: cellFrame];
          RELEASE(attrStr);
        }
    }
  else
    {
      /* .. do nothing.  */
    }
}

- (NSText *) setUpFieldEditorAttributes: (NSText *)textObject
{
  NSSecureTextView *secureView;

  /* Replace the text object with a secure instance.  It's not shared.  */
  secureView = AUTORELEASE([[NSSecureTextView alloc] init]);

  [secureView setEchosBullets: [self echosBullets]];
  return [super setUpFieldEditorAttributes: secureView];
}

- (id) initWithCoder: (NSCoder *)decoder
{
  self = [super initWithCoder: decoder];
  if ([decoder allowsKeyedCoding])
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

- (BOOL) echosBullets
{
  return _echosBullets;
}

- (void) setEchosBullets: (BOOL)flag
{
  _echosBullets = flag;
}

- (void) drawGlyphsForGlyphRange: (NSRange)glyphRange
                         atPoint: (NSPoint)containerOrigin
{
  if ([self echosBullets])
    {
        /*
          FIXME: Functionality not implemented.
          This also doesn't eblong into this method, rather 
          we should do the replacement during the glyph generation.
          This gets currently done in [GSLayoutManager _generateGlyphsForRun:at:],
          but should be done in an NSTypesetter subclass. Only with this in place
          it seems possible to implement bullet echoing.
         */
    }
  else
    {
      /* Do nothing.  */
    }
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
  [[self textContainer] replaceLayoutManager: m];
  RELEASE(m);

  [self setFieldEditor: YES];

  return self;
}

- (BOOL) echosBullets
{
  return [(GSSimpleSecureLayoutManager*)[self layoutManager] echosBullets];
}

- (void) setEchosBullets: (BOOL)flag
{
  [(GSSimpleSecureLayoutManager*)[self layoutManager] setEchosBullets: flag];
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
