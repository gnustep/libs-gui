/* 
    NSText.h

    The text object

    Copyright (C) 1996 Free Software Foundation, Inc.

    Author: 	Scott Christley <scottc@net-community.com>
    Date: 1996
    Author: 	Felipe A. Rodriguez <far@ix.netcom.com>
    Date: July 1998
    Author: 	Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
    Date: August 1998

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

#include <AppKit/NSView.h>
#include <AppKit/NSSpellProtocol.h>
#include <Foundation/NSRange.h>

@class NSString;
@class NSData;
@class NSNotification;
@class NSColor;
@class NSFont;
@class NSTextStorage;

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

#include <AppKit/NSStringDrawing.h>

// these definitions should migrate to NSTextView when implemented
typedef enum _NSSelectionGranularity {	
  NSSelectByCharacter	= 0,
  NSSelectByWord	= 1,
  NSSelectByParagraph	= 2,
} NSSelectionGranularity;

#ifndef NO_GNUSTEP
typedef enum _NSSelectionAffinity {	
  NSSelectionAffinityUpstream	= 0,
  NSSelectionAffinityDownstream	= 1,
} NSSelectionAffinity;
#endif

@interface NSText : NSView <NSChangeSpelling,NSIgnoreMisspelledWords,NSCoding>
{	
  // Attributes
  id _delegate;
  struct GSTextFlagsType {
    unsigned is_editable: 1;
    unsigned is_rich_text: 1;
    unsigned is_selectable: 1;
    unsigned imports_graphics: 1;
    unsigned uses_font_panel: 1;
    unsigned is_horizontally_resizable: 1;
    unsigned is_vertically_resizable: 1;
    unsigned is_ruler_visible: 1;
    unsigned is_field_editor: 1;
    unsigned draws_background: 1;
  } _tf;
  NSTextAlignment _alignment;
  NSColor *_background_color;
  NSColor *_text_color;
  NSFont *_default_font;
  NSRange _selected_range;
  NSSize _minSize;
  NSSize _maxSize;
  NSMutableDictionary *_typingAttributes;
  
  // content
  NSTextStorage	*_textStorage;
  
  int _spellCheckerDocumentTag;
  
  // column-stable cursor up/down
  NSPoint _currentCursor;

  // contains private _GNULineLayoutInfo objects
  id _layoutManager;  
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
- (void) setString: (NSString*)string;
- (NSString*) string;

// old fashioned
- (void) replaceRange: (NSRange)range withString: (NSString*)aString;
- (void) replaceRange: (NSRange)range withRTF: (NSData*)rtfData;
- (void) replaceRange: (NSRange)range withRTFD: (NSData*)rtfdData;
- (void) setText: (NSString*)string;
- (void) setText: (NSString*)aString 
	   range: (NSRange)aRange;
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
- (void) setFont: (NSFont*)obj;
- (void) setFont: (NSFont*)font ofRange: (NSRange)range;

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
- (void) setTextColor: (NSColor*)color range: (NSRange)range;
- (void) setColor: (NSColor*)color ofRange: (NSRange)range;
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
-(NSData*) RTFDFromRange: (NSRange)range;
-(NSData*) RTFFromRange: (NSRange)range;

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
- (void) scrollRangeToVisible: (NSRange)range;

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


@interface NSText(GNUstepExtension)
// GNU extension (override it if you want other characters treated 
// as newline characters)
+ (NSString*) newlineString;	

// GNU extension
- (void) replaceRange: (NSRange)range 
 withAttributedString: (NSAttributedString*)attrString;
- (unsigned) textLength;

//
// these NSTextView methods are here only informally (GNU extensions)
//
- (int) spellCheckerDocumentTag;

// changed to only except class NSString
- (void) insertText: (NSString*)insertString;

- (NSMutableDictionary*) typingAttributes;
- (void) setTypingAttributes: (NSDictionary*)attrs;

- (void) updateFontPanel;

- (BOOL) shouldDrawInsertionPoint;
- (void) drawInsertionPointInRect: (NSRect)rect 
			    color: (NSColor*)color 
			 turnedOn: (BOOL)flag;

// override if you want special cursor behaviour
- (NSRange) selectionRangeForProposedRange: (NSRange)proposedCharRange 
			       granularity: (NSSelectionGranularity)granularity;

- (NSArray*) acceptableDragTypes;
- (void) updateDragTypeRegistration;
@end

/* Notifications */
extern NSString *NSTextDidBeginEditingNotification;
extern NSString *NSTextDidEndEditingNotification;
extern NSString *NSTextDidChangeNotification;

#ifdef GNUSTEP
@interface NSObject(NSTextDelegate)
- (BOOL) textShouldBeginEditing: (NSText*)textObject; /* YES means do it */
- (BOOL) textShouldEndEditing: (NSText*)textObject; /* YES means do it */
- (void) textDidBeginEditing: (NSNotification*)notification;
- (void) textDidEndEditing: (NSNotification*)notification;
- (void) textDidChange: (NSNotification*)notification; /* Any keyDown or paste which changes the contents causes this */
@end
#endif

#endif // _GNUstep_H_NSText

#if 0
NSFontAttributeName; /* NSFont, default Helvetica 12 */
->  NSParagraphStyleAttributeName; /* NSParagraphStyle, default defaultParagraphStyle */
NSForegroundColorAttributeName; /* NSColor, default blackColor */
NSUnderlineStyleAttributeName; /* int, default 0: no underline */
NSSuperscriptAttributeName; /* int, default 0 */
NSBackgroundColorAttributeName; /* NSColor, default nil: no background */
->  NSAttachmentAttributeName; /* NSTextAttachment, default nil */
NSLigatureAttributeName; /* int, default 1: default ligatures, 0: no ligatures, 2: all ligatures */
NSBaselineOffsetAttributeName; /* float, in points; offset from baseline, default 0 */
NSKernAttributeName; /* float, amount to modify default kerning, if 0, kerning off */
#endif
