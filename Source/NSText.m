/** <title>NSText</title>

   <abstract>The RTFD text class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de></email></author>
   Date: August 1998
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2000
   Reorganised and cleaned up code, added some action methods
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2000
   Made class abstract, moved most code to NSTextView.

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
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSData.h>

#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSText.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSScrollView.h>

#include <AppKit/NSDragging.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSLayoutManager.h>

static	Class	abstract;
static	Class	concrete;

@implementation NSText

/*
 * Class methods
 */
+ (void)initialize
{
  if (self  == [NSText class])
    {
      [self setVersion: 1];

      abstract = self;
      concrete = [NSTextView class];
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  if (self == abstract)
    return NSAllocateObject (concrete, 0, zone);
  else
    return NSAllocateObject (self, 0, zone);
}

/*
 * Instance methods
 */

/*
 * Initialization
 */

- (id) init
{
  return [self initWithFrame: NSMakeRect (0, 0, 100, 100)];
}

- (void) dealloc
{
  RELEASE (_background_color);

  [super dealloc];
}

/*
 * Getting and Setting Contents
 */
- (void) replaceCharactersInRange: (NSRange)aRange  withRTF: (NSData *)rtfData
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] initWithRTF: rtfData 
				     documentAttributes: NULL];
  AUTORELEASE (attr);
  [self replaceRange: aRange  withAttributedString: attr];
}

- (void) replaceCharactersInRange: (NSRange)aRange  
			 withRTFD: (NSData *)rtfdData
{
  NSAttributedString *attr;

  attr = [[NSAttributedString alloc] initWithRTFD: rtfdData 
				     documentAttributes: NULL];
  AUTORELEASE (attr);
  [self replaceRange: aRange  withAttributedString: attr];
}

- (void) replaceCharactersInRange: (NSRange)aRange
		       withString: (NSString*)aString
{
  [self subclassResponsibility: _cmd];
}

- (NSData*) RTFDFromRange: (NSRange)aRange
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSData*) RTFFromRange: (NSRange)aRange
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) setString: (NSString*)aString
{
  [self replaceCharactersInRange: NSMakeRange (0, [self textLength])
	withString: aString];
}

- (NSString*) string
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/*
 * old OpenStep methods doing the same
 */
- (void) replaceRange: (NSRange)aRange  withRTFD: (NSData*)rtfdData
{
  [self replaceCharactersInRange: aRange  withRTFD: rtfdData];
}

- (void) replaceRange: (NSRange)aRange  withRTF: (NSData*)rtfData
{
  [self replaceCharactersInRange: aRange  withRTF: rtfData];
}

- (void) replaceRange: (NSRange)aRange  withString: (NSString*)aString
{
  [self replaceCharactersInRange: aRange  withString: aString];
}

- (void) setText: (NSString*)aString  range: (NSRange)aRange
{
  [self replaceCharactersInRange: aRange  withString: aString];
}

- (void) setText: (NSString*)string
{
  [self setString: string];
}

- (NSString*) text
{
  return [self string];
}

/*
 * Graphic attributes
 */
- (NSColor*) backgroundColor
{
  return _background_color;
}

- (BOOL) drawsBackground
{
  return _tf.draws_background;
}

- (void) setBackgroundColor: (NSColor*)color
{
  if (![_background_color isEqual: color])
    {
      ASSIGN (_background_color, color);
      
      [self setNeedsDisplay: YES];

      if (!_tf.is_field_editor)
	{
	  /* If we are embedded in a scrollview, we might not be
	     filling all the scrollview's area (a textview might
	     resize itself dynamically in response to user input).  If
	     this is the case, the scrollview is drawing the rest of
	     the background - change that too.  */
	  NSScrollView *sv = [self enclosingScrollView];
	  
	  if (sv != nil)
	    {
	      [sv setBackgroundColor: color];
	    }
	}
    }
}



- (void) setDrawsBackground: (BOOL)flag
{
  if (_tf.draws_background != flag)
    {
      _tf.draws_background = flag;

      [self setNeedsDisplay: YES];

      if (!_tf.is_field_editor)
	{
	  /* See comment in setBackgroundColor:.  */
	  NSScrollView *sv = [self enclosingScrollView];
	  
	  if (sv != nil)
	    {
	      [sv setDrawsBackground: flag];
	    }
	}
    }
}

/*
 * Managing Global Characteristics
 */
- (BOOL) importsGraphics
{
  return _tf.imports_graphics;
}

- (BOOL) isEditable
{
  return _tf.is_editable;
}

- (BOOL) isFieldEditor
{
  return _tf.is_field_editor;
}

- (BOOL) isRichText
{
  return _tf.is_rich_text;
}

- (BOOL) isSelectable
{
  return _tf.is_selectable;
}

- (void) setEditable: (BOOL)flag
{
  _tf.is_editable = flag;

  if (flag)
    {
      _tf.is_selectable = YES;
    }
}

- (void) setFieldEditor: (BOOL)flag
{
  _tf.is_field_editor = flag;
}

- (void) setImportsGraphics: (BOOL)flag
{
  _tf.imports_graphics = flag;

  if (flag == YES)
    {
      _tf.is_rich_text = YES;
    }
}

- (void) setRichText: (BOOL)flag
{
  _tf.is_rich_text  = flag;

  if (flag == NO)
    {
      _tf.imports_graphics = NO;
    }
}

- (void)setSelectable: (BOOL)flag
{
  _tf.is_selectable = flag;

  if (flag == NO)
    {
      _tf.is_editable = NO;
    }
}

/*
 * Using the font panel
 */
- (BOOL) usesFontPanel
{
  return _tf.uses_font_panel;
}

- (void) setUsesFontPanel: (BOOL)flag
{
  _tf.uses_font_panel = flag;
}

/*
 * Managing the Ruler
 */
- (BOOL) isRulerVisible
{
  return _tf.is_ruler_visible;
}

- (void) toggleRuler: (id)sender
{
  [self subclassResponsibility: _cmd];
}

/*
 * Managing the Selection
 */
- (NSRange) selectedRange
{
  [self subclassResponsibility: _cmd];
  return NSMakeRange (NSNotFound, 0);
}

- (void) setSelectedRange: (NSRange)range
{
  [self subclassResponsibility: _cmd];
}

/*
 * Copy and paste
 */
- (void) copy: (id)sender
{  
  [self subclassResponsibility: _cmd];
}

/* Copy the current font to the font pasteboard */
- (void) copyFont: (id)sender
{
  [self subclassResponsibility: _cmd];
}

/* Copy the current ruler settings to the ruler pasteboard */
- (void) copyRuler: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) delete: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) cut: (id)sender
{
  [self copy: sender];
  [self delete: sender];
}

- (void) paste: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) pasteFont: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) pasteRuler: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) selectAll: (id)sender
{
  [self setSelectedRange: NSMakeRange (0, [self textLength])];
}

/*
 * Managing Font
 */
- (NSFont*) font
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/*
 * This action method changes the font of the selection for a rich
 * text object, or of all text for a plain text object. If the
 * receiver doesn't use the Font Panel, however, this method does
 * nothing.  */
- (void) changeFont: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) setFont: (NSFont*)font
{
  [self subclassResponsibility: _cmd];
}

- (void) setFont: (NSFont*)font  ofRange: (NSRange)aRange
{
  [self subclassResponsibility: _cmd];
}

/*
 * Managing Alingment
 */
- (NSTextAlignment) alignment
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  [self subclassResponsibility: _cmd];
}

- (void) alignCenter: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) alignLeft: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) alignRight: (id)sender
{
  [self subclassResponsibility: _cmd];
}

/*
 * Text colour
 */
- (NSColor*) textColor
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) setTextColor: (NSColor*)color
{
  [self subclassResponsibility: _cmd];
}

- (void) setTextColor: (NSColor*)color  range: (NSRange)aRange
{
  [self subclassResponsibility: _cmd];
}

/* Old OpenStep method to do the same */
- (void) setColor: (NSColor*)color  ofRange: (NSRange)aRange
{
  [self setTextColor: color  range: aRange];
}

/*
 * Text attributes
 */
- (void) subscript: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) superscript: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) unscript: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) underline: (id)sender
{
  [self subclassResponsibility: _cmd];
}

/*
 * Reading and Writing RTFD Files
 */
- (BOOL) readRTFDFromFile: (NSString*)path
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL) writeRTFDToFile: (NSString*)path  atomically: (BOOL)flag
{
  [self subclassResponsibility: _cmd];
  return NO;
}

/*
 * Sizing the Frame Rectangle
 */
- (BOOL) isHorizontallyResizable
{
  return _tf.is_horizontally_resizable;
}

- (BOOL) isVerticallyResizable
{
  return _tf.is_vertically_resizable;
}

- (NSSize) maxSize
{
  return _maxSize;
}

- (NSSize) minSize
{
  return _minSize;
}

- (void) setHorizontallyResizable: (BOOL)flag
{
  _tf.is_horizontally_resizable = flag;
}

- (void) setVerticallyResizable: (BOOL)flag
{
  _tf.is_vertically_resizable = flag;
}

- (void) setMaxSize: (NSSize)newMaxSize
{
  _maxSize = newMaxSize;
}

- (void) setMinSize: (NSSize)newMinSize
{
  _minSize = newMinSize;
}

- (void) sizeToFit
{
  [self subclassResponsibility: _cmd];
}

/*
 * Spelling
 */

- (void) checkSpelling: (id)sender
{
  [self subclassResponsibility: _cmd];
}

- (void) showGuessPanel: (id)sender
{
  NSSpellChecker *sp = [NSSpellChecker sharedSpellChecker];

  [[sp spellingPanel] orderFront: self];
}

/*
 * Scrolling
 */
- (void) scrollRangeToVisible: (NSRange)aRange
{
  [self subclassResponsibility: _cmd];
}

/*
 * Managing the Delegate
 */
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  _delegate = anObject;
}

/*
 * NSView
 */

/* text lays out from top to bottom */
- (BOOL) isFlipped
{
  return YES;
}

- (BOOL) isOpaque
{
  if (_tf.draws_background == NO
      || _background_color == nil
      || [_background_color alphaComponent] < 1.0)
    return NO;
  else
    return YES;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  BOOL flag;
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _delegate];

  flag = _tf.is_field_editor;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_editable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_selectable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_rich_text;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.imports_graphics;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.draws_background;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_horizontally_resizable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_vertically_resizable;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.uses_font_panel;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.uses_ruler;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _tf.is_ruler_visible;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];

  [aCoder encodeObject: _background_color];
  [aCoder encodeValueOfObjCType: @encode(NSSize) at: &_minSize];
  [aCoder encodeValueOfObjCType: @encode(NSSize) at: &_maxSize];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  BOOL flag;

  [super initWithCoder: aDecoder];

  _delegate  = [aDecoder decodeObject];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_field_editor = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_editable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_selectable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_rich_text = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.imports_graphics = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.draws_background = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_horizontally_resizable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_vertically_resizable = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.uses_font_panel = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.uses_ruler = flag;
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  _tf.is_ruler_visible = flag;

  _background_color  = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(NSSize) at: &_minSize];
  [aDecoder decodeValueOfObjCType: @encode(NSSize) at: &_maxSize];

  return self;
}

/*
 * NSChangeSpelling protocol
 */
- (void) changeSpelling: (id)sender
{
  [self subclassResponsibility: _cmd];
}

/*
 * NSIgnoreMisspelledWords protocol
 */
- (void) ignoreSpelling: (id)sender
{
  [self subclassResponsibility: _cmd];
}

@end

@implementation NSText (GNUstepExtensions)

- (void) replaceRange: (NSRange)aRange
 withAttributedString: (NSAttributedString*)attrString
{
  [self subclassResponsibility: _cmd];
}

- (unsigned) textLength
{
  [self subclassResponsibility: _cmd];
  return 0;
}

@end
