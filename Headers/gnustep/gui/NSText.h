/*                                                        -*-objc-*-
    NSText.h

    The text object

    Copyright (C) 1996 Free Software Foundation, Inc.

    Author: Scott Christley <scottc@net-community.com>
    Date: 1996
    Author: Felipe A. Rodriguez <far@ix.netcom.com>
    Date: July 1998
    Author: Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
    Date: August 1998
    Author: Nicola Pero <n.pero@mi.flashnet.it>
    Date: December 2000

    This file is part of the GNUstep GUI Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.
     
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSText
#define _GNUstep_H_NSText

/*
 * The NSText class is now an abstract class.  When you allocate an
 * instance of NSText, an instance of NSTextView is always allocated
 * instead.
 *
 * But you can still subclass NSText to implement your own text
 * editing class not derived from NSTextView.  NSText declares general
 * methods that a text editing object should have; it has ivars to
 * track the various options (editable, selectable, background color
 * etc) and implementations for methods setting and getting these
 * generic options and for some helper methods which are simple
 * wrappers around the real basic editing methods.  The real editing
 * methods are not implemented in NSText, which is why it is abstract.
 * To make a working subclass, you need to implement these methods.
 * The working subclass could potentially be implemented in absolutely
 * *any* way you want.  I have been told that some versions of Emacs
 * can be embedded as an X subwindow inside alien widgets and windows
 * - so yes, potentially if you are able to figure out how to embed 
 * Emacs inside the GNUstep NSView tree, you can write a subclass 
 * of NSText which just uses Emacs. */
 
#include <AppKit/NSView.h>
#include <AppKit/NSSpellProtocol.h>
#include <Foundation/NSRange.h>

@class NSString;
@class NSData;
@class NSNotification;
@class NSColor;
@class NSFont;

typedef enum _NSTextAlignment {
  NSLeftTextAlignment = 0,
  NSRightTextAlignment,
  NSCenterTextAlignment,
  NSJustifiedTextAlignment,
  NSNaturalTextAlignment
} NSTextAlignment;

enum {
  NSIllegalTextMovement	= 0,
  NSReturnTextMovement	= 0x10,
  NSTabTextMovement	= 0x11,
  NSBacktabTextMovement	= 0x12,
  NSLeftTextMovement	= 0x13,
  NSRightTextMovement	= 0x14,
  NSUpTextMovement	= 0x15,
  NSDownTextMovement	= 0x16
};
	 	
enum {
  NSParagraphSeparatorCharacter	= 0x2029,
  NSLineSeparatorCharacter	= 0x2028,
  NSTabCharacter		= 0x0009,
  NSFormFeedCharacter		= 0x000c,
  NSNewlineCharacter		= 0x000a,
  NSCarriageReturnCharacter	= 0x000d,
  NSEnterCharacter		= 0x0003,
  NSBackspaceCharacter		= 0x0008,
  NSBackTabCharacter		= 0x0019,
  NSDeleteCharacter		= 0x007f,
};


/* The following are required by the original openstep doc.  */
enum {
  NSBackspaceKey      = 8,
  NSCarriageReturnKey = 13,
  NSDeleteKey         = 0x7f,
  NSBacktabKey        = 25
};

#include <AppKit/NSStringDrawing.h>

@interface NSText : NSView <NSChangeSpelling, NSIgnoreMisspelledWords>
{	
  id _delegate;
  struct GSTextFlagsType {
    unsigned is_field_editor: 1;
    unsigned is_editable: 1;
    unsigned is_selectable: 1;
    unsigned is_rich_text: 1;
    unsigned imports_graphics: 1;
    unsigned draws_background: 1;
    unsigned is_horizontally_resizable: 1;
    unsigned is_vertically_resizable: 1;
    unsigned uses_font_panel: 1;
    unsigned uses_ruler: 1;
    unsigned is_ruler_visible: 1;
  } _tf;
  NSColor *_background_color;
  NSSize _minSize;
  NSSize _maxSize;
}

/*
 * Getting and Setting Contents 
 */
- (void) replaceCharactersInRange: (NSRange)aRange  
			  withRTF: (NSData*)rtfData;
- (void) replaceCharactersInRange: (NSRange)aRange  
			 withRTFD: (NSData*)rtfdData;
- (void) replaceCharactersInRange: (NSRange)aRange  
		       withString: (NSString*)aString;
- (void) setString: (NSString*)aString;
- (NSString*) string;

/*
 * Old fashioned OpenStep methods (wrappers for the previous ones)
 */
- (void) replaceRange: (NSRange)aRange  withString: (NSString*)aString;
- (void) replaceRange: (NSRange)aRange  withRTF: (NSData*)rtfData;
- (void) replaceRange: (NSRange)aRange  withRTFD: (NSData*)rtfdData;
- (void) setText: (NSString*)aString;
- (void) setText: (NSString*)aString  range: (NSRange)aRange;
- (NSString*) text;

/*
 * Graphic attributes
 */
- (NSColor*) backgroundColor;
- (BOOL) drawsBackground;
- (void) setBackgroundColor: (NSColor*)color;
- (void) setDrawsBackground: (BOOL)flag;

/*
 * Managing Global Characteristics
 */
- (BOOL) importsGraphics;
- (BOOL) isEditable;
- (BOOL) isFieldEditor;
- (BOOL) isRichText;
- (BOOL) isSelectable;
- (void) setEditable: (BOOL)flag;
- (void) setFieldEditor: (BOOL)flag;
- (void) setImportsGraphics: (BOOL)flag;
- (void) setRichText: (BOOL)flag;
- (void) setSelectable: (BOOL)flag;

/*
 * Using the font panel
 */ 
- (void) setUsesFontPanel: (BOOL)flag;
- (BOOL) usesFontPanel;

/*
 * Managing the Ruler
 */
- (BOOL) isRulerVisible;
- (void) toggleRuler: (id)sender;

/*
 * Managing the Selection
 */
- (NSRange) selectedRange;
- (void) setSelectedRange: (NSRange)range;

/*
 * Responding to Editing Commands
 */
- (void) copy: (id)sender;
- (void) copyFont: (id)sender;
- (void) copyRuler: (id)sender;
- (void) cut: (id)sender;
- (void) delete: (id)sender;
- (void) paste: (id)sender;
- (void) pasteFont: (id)sender;
- (void) pasteRuler: (id)sender;
- (void) selectAll: (id)sender;

/*
 * Managing Font
 */
- (void) changeFont: (id)sender;
- (NSFont*) font;
- (void) setFont: (NSFont*)font;
- (void) setFont: (NSFont*)font ofRange: (NSRange)aRange;

/*
 * Managing Alignment
 */
- (NSTextAlignment) alignment;
- (void) setAlignment: (NSTextAlignment)mode;
- (void) alignCenter: (id)sender;
- (void) alignLeft: (id)sender;
- (void) alignRight: (id)sender;

/*
 * Text colour
 */
- (void) setTextColor: (NSColor*)color range: (NSRange)aRange;
- (void) setColor: (NSColor*)color ofRange: (NSRange)aRange;
- (void) setTextColor: (NSColor*)color;
- (NSColor*) textColor;

/*
 * Text attributes
 */
- (void) subscript: (id)sender;
- (void) superscript: (id)sender;
- (void) underline: (id)sender;
- (void) unscript: (id)sender;

/*
 * Reading and Writing RTFD Files
 */
-(BOOL) readRTFDFromFile: (NSString*)path;
-(BOOL) writeRTFDToFile: (NSString*)path atomically: (BOOL)flag;
-(NSData*) RTFDFromRange: (NSRange)aRange;
-(NSData*) RTFFromRange: (NSRange)aRange;

/*
 * Sizing the Frame Rectangle
 */
- (BOOL) isHorizontallyResizable;
- (BOOL) isVerticallyResizable;
- (NSSize) maxSize;
- (NSSize) minSize;
- (void) setHorizontallyResizable: (BOOL)flag;
- (void) setMaxSize: (NSSize)newMaxSize;
- (void) setMinSize: (NSSize)newMinSize;
- (void) setVerticallyResizable: (BOOL)flag;
- (void) sizeToFit;

/*
 * Spelling
 */
- (void) checkSpelling: (id)sender;
- (void) showGuessPanel: (id)sender;

/*
 * Scrolling
 */
- (void) scrollRangeToVisible: (NSRange)aRange;

/*
 * Managing the Delegate
 */
- (id) delegate;
- (void) setDelegate: (id)anObject;

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder;
- (id) initWithCoder: (NSCoder*)aDecoder;

/*
 * NSChangeSpelling protocol
 */
- (void) changeSpelling: (id)sender;

/*
 * NSIgnoreMisspelledWords protocol
 */
- (void) ignoreSpelling: (id)sender;
@end

@interface NSText (GNUstepExtensions)

- (void) replaceRange: (NSRange)aRange 
 withAttributedString: (NSAttributedString*)attrString;

- (unsigned) textLength;

@end

/* Notifications */
APPKIT_EXPORT NSString *NSTextDidBeginEditingNotification;
APPKIT_EXPORT NSString *NSTextDidEndEditingNotification;
APPKIT_EXPORT NSString *NSTextDidChangeNotification;

@interface NSObject (NSTextDelegate)
- (BOOL) textShouldBeginEditing: (NSText*)textObject; /* YES means do it */
- (BOOL) textShouldEndEditing: (NSText*)textObject; /* YES means do it */
- (void) textDidBeginEditing: (NSNotification*)notification;
- (void) textDidEndEditing: (NSNotification*)notification;
- (void) textDidChange: (NSNotification*)notification; /* Any keyDown or paste which changes the contents causes this */
@end

#endif // _GNUstep_H_NSText

