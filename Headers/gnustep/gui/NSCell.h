/* -*-objc-*-
   NSCell.h

   The abstract cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSCell
#define _GNUstep_H_NSCell

#include <Foundation/NSCoder.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSText.h>

@class NSString;
@class NSMutableDictionary;
@class NSView;
@class NSFont;
@class NSText;
@class NSFormatter;

typedef enum _NSCellType {
  NSNullCellType,
  NSTextCellType,
  NSImageCellType
} NSCellType;

enum {
  NSAnyType,
  NSIntType,
  NSPositiveIntType,   
  NSFloatType,
  NSPositiveFloatType,   
  NSDateType,
  NSDoubleType,   
  NSPositiveDoubleType
};

typedef enum {
  NSNoImage = 0,
  NSImageOnly,
  NSImageLeft,
  NSImageRight,
  NSImageBelow,
  NSImageAbove,
  NSImageOverlaps
} NSCellImagePosition;

typedef enum _NSCellAttribute {
  NSCellDisabled,
  NSCellState,
  NSPushInCell,
  NSCellEditable,
  NSChangeGrayCell,
  NSCellHighlighted,   
  NSCellLightsByContents,  
  NSCellLightsByGray,   
  NSChangeBackgroundCell,  
  NSCellLightsByBackground,  
  NSCellIsBordered,  
  NSCellHasOverlappingImage,  
  NSCellHasImageHorizontal,  
  NSCellHasImageOnLeftOrBottom, 
  NSCellChangesContents,  
  NSCellIsInsetButton,
  NSCellAllowsMixedState
} NSCellAttribute;

enum {
  NSNoCellMask			= 0,
  NSContentsCellMask		= 1,
  NSPushInCellMask		= 2,
  NSChangeGrayCellMask		= 4,
  NSChangeBackgroundCellMask	= 8
};

enum {
  xDist = 2,	// horizontal distance between the text and image rects. 
  yDist = 2	// vertical distance between the text and image rects. 
};

/* 
 * We try to do as in macosx. 
 */
enum { 
  NSOffState			= 0,
  NSOnState			= 1,
  NSMixedState			= -1
};

@interface NSCell : NSObject <NSCopying, NSCoding>
{
  // Attributes
  NSString *_contents;
  NSImage *_cell_image;
  NSFont *_font;
  id _objectValue;
  struct GSCellFlagsType { 
    // total 32 bits.  0 bits left.
    unsigned contents_is_attributed_string: 1;
    unsigned is_highlighted: 1;
    unsigned is_disabled: 1;
    unsigned is_editable: 1;
    unsigned is_rich_text: 1;
    unsigned imports_graphics: 1;
    unsigned shows_first_responder: 1; 
    unsigned refuses_first_responder: 1; 
    unsigned sends_action_on_end_editing: 1; 
    unsigned is_bordered: 1;   
    unsigned is_bezeled: 1;   
    unsigned is_scrollable: 1;
    unsigned wraps: 1;
    unsigned text_align: 3; // 5 values
    unsigned is_selectable: 1;
    unsigned is_continuous: 1;
    unsigned allows_mixed_state: 1;
    unsigned has_valid_object_value: 1;
    unsigned type: 2;           // 3 values
    unsigned image_position: 4; // 7 values
    unsigned entry_type: 4;     // 8 values
    // 2 bits reserved for subclass use
    unsigned subclass_bool_one: 1;
    unsigned subclass_bool_two: 1;
    /* This is not in the bitfield now (for simpler macosx compatibility) 
       but who knows in the future */
    int state; // 3 values but one negative
  } _cell;
  unsigned char _mnemonic_location;
  unsigned int _mouse_down_flags;
  unsigned int _action_mask; 
  NSFormatter *_formatter;
  NSMenu *_menu;
  id _represented_object; 
}

//
// Class methods
// 
+ (NSMenu *)defaultMenu;
+ (BOOL) prefersTrackingUntilMouseUp;

//
// Initializing an NSCell 
//
- (id)initImageCell:(NSImage *)anImage;
- (id)initTextCell:(NSString *)aString;

//
// Setting the NSCell's Value 
//
- (id)objectValue;
- (BOOL)hasValidObjectValue;
- (double)doubleValue;
- (float)floatValue;
- (int)intValue;
- (NSString *)stringValue;
- (void) setObjectValue:(id)object;
- (void)setDoubleValue:(double)aDouble;
- (void)setFloatValue:(float)aFloat;
- (void)setIntValue:(int)anInt;
- (void)setStringValue:(NSString *)aString;

//
// Setting Parameters 
//
- (int)cellAttribute:(NSCellAttribute)aParameter;
- (void)setCellAttribute:(NSCellAttribute)aParameter
		      to:(int)value;

//
// Setting the NSCell's Type 
//
- (void)setType:(NSCellType)aType;
- (NSCellType)type;

//
// Enabling and Disabling the NSCell 
//
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

//
// Modifying Graphic Attributes 
//
- (BOOL)isBezeled;
- (BOOL)isBordered;
- (BOOL)isOpaque;
- (void)setBezeled:(BOOL)flag;
- (void)setBordered:(BOOL)flag;

//
// Setting the NSCell's State 
//
- (void)setState:(int)value;
- (int)state;
- (BOOL)allowsMixedState;
- (void)setAllowsMixedState:(BOOL)flag;
- (int)nextState;
- (void)setNextState;

//
// Modifying Text Attributes 
//
- (NSTextAlignment)alignment;
- (NSFont *)font;
- (BOOL)isEditable;
- (BOOL)isSelectable;
- (BOOL)isScrollable;
- (void)setAlignment:(NSTextAlignment)mode;
- (void)setEditable:(BOOL)flag;
- (void)setFont:(NSFont *)fontObject;
- (void)setSelectable:(BOOL)flag;
- (void)setScrollable:(BOOL)flag;
- (void)setWraps:(BOOL)flag;
- (BOOL)wraps;
- (void)setAttributedStringValue:(NSAttributedString *)attribStr;
- (NSAttributedString *)attributedStringValue;
- (void)setAllowsEditingTextAttributes:(BOOL)flag;
- (BOOL)allowsEditingTextAttributes;
- (void)setImportsGraphics:(BOOL)flag;
- (BOOL)importsGraphics;
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject;

//
// Target and Action 
//
- (SEL)action;
- (BOOL)isContinuous;
- (int)sendActionOn:(int)mask;
- (void)setAction:(SEL)aSelector;
- (void)setContinuous:(BOOL)flag;
- (void)setTarget:(id)anObject;
- (id)target;

//
// Setting the Image 
//
- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// Formatting Data and Validating Input 
//
- (void)setFormatter:(NSFormatter *)newFormatter;
- (id)formatter;
- (int)entryType;
- (BOOL)isEntryAcceptable:(NSString *)aString;
- (void)setEntryType:(int)aType;
- (void)setFloatingPointFormat:(BOOL)autoRange
                          left:(unsigned int)leftDigits
                         right:(unsigned int)rightDigits;

//
// Menu
//
- (void)setMenu:(NSMenu *)aMenu;
- (NSMenu *)menu;
- (NSMenu *)menuForEvent:(NSEvent *)anEvent 
                  inRect:(NSRect)cellFrame 
                  ofView:(NSView *)aView;

//
// Comparing to Another NSCell 
//
- (NSComparisonResult)compare:(id)otherCell;

//
// respond to keyboard
//
// All these methods except -performClick: are provided only for some
// compatibility with MacOS-X code and their use in new programs is
// deprecated.  Please use -isEnabled, -setEnabled: instead of
// -acceptsFirstReponder, -refusesFirstResponder,
// -setRefusesFirstResponder:.  Mnemonics (eg 'File' with the 'F'
// underlined as in MS Windows(tm) menus) are not part of GNUstep's
// interface so methods referring to mnemonics do nothing -- they are
// provided for compatibility only; please use key equivalents instead
// in your GNUstep programs.
- (BOOL)acceptsFirstResponder;                     // deprecated  
- (void)setShowsFirstResponder:(BOOL)flag;         // does nothing
- (BOOL)showsFirstResponder;                       // does nothing
- (void)setTitleWithMnemonic:(NSString *)aString;  // does nothing
- (NSString *)mnemonic;                            // does nothing
- (void)setMnemonicLocation:(unsigned int)location;// does nothing
- (unsigned int)mnemonicLocation;                  // does nothing
- (BOOL)refusesFirstResponder;                     // deprecated  
- (void)setRefusesFirstResponder:(BOOL)flag;       // deprecated  
- (void)performClick:(id)sender;                   // good

//
// Interacting with Other NSCells 
//
- (void)takeObjectValueFrom: (id)sender;
- (void)takeDoubleValueFrom:(id)sender;
- (void)takeFloatValueFrom:(id)sender;
- (void)takeIntValueFrom:(id)sender;
- (void)takeStringValueFrom:(id)sender;

//
// Using the NSCell to Represent an Object
//
- (id)representedObject;
- (void)setRepresentedObject:(id)anObject;

//
// Tracking the Mouse 
//
- (BOOL)continueTracking:(NSPoint)lastPoint
		      at:(NSPoint)currentPoint
		  inView:(NSView *)controlView;
- (int)mouseDownFlags;
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval;
- (BOOL)startTrackingAt:(NSPoint)startPoint
		 inView:(NSView *)controlView;
- (void)stopTracking:(NSPoint)lastPoint
		  at:(NSPoint)stopPoint
	      inView:(NSView *)controlView
		  mouseIsUp:(BOOL)flag;
- (BOOL)trackMouse:(NSEvent *)theEvent
	    inRect:(NSRect)cellFrame
	    ofView:(NSView *)controlView
	    untilMouseUp:(BOOL)flag;

//
// Managing the Cursor 
//
- (void)resetCursorRect:(NSRect)cellFrame
		 inView:(NSView *)controlView;

//
// Handling Keyboard Alternatives 
//
- (NSString *)keyEquivalent;

//
// Determining Component Sizes 
//
- (void)calcDrawInfo:(NSRect)aRect;
- (NSSize)cellSize;
- (NSSize)cellSizeForBounds:(NSRect)aRect;
- (NSRect)drawingRectForBounds:(NSRect)theRect;
- (NSRect)imageRectForBounds:(NSRect)theRect;
- (NSRect)titleRectForBounds:(NSRect)theRect;

//
// Displaying 
//
- (NSView *)controlView;

- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView;
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView;
- (void)highlight:(BOOL)lit
	withFrame:(NSRect)cellFrame
	   inView:(NSView *)controlView;
- (BOOL)isHighlighted;

//
// Editing Text 
//
- (void)editWithFrame:(NSRect)aRect
	       inView:(NSView *)controlView	
	       editor:(NSText *)textObject	
	       delegate:(id)anObject	
		event:(NSEvent *)theEvent;
- (BOOL)sendsActionOnEndEditing;
- (void)setSendsActionOnEndEditing:(BOOL)flag;
- (void)endEditing:(NSText *)textObject;
- (void)selectWithFrame:(NSRect)aRect
		 inView:(NSView *)controlView	 
		 editor:(NSText *)textObject	 
		 delegate:(id)anObject	 
		  start:(int)selStart	 
		 length:(int)selLength;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

// 
// Methods that are private GNUstep extensions
//
@interface NSCell (PrivateMethods)

- (NSMutableDictionary*) _typingAttributes;
- (NSColor*) textColor;
- (NSSize) _sizeText: (NSString*) title;
- (void) _drawText: (NSString*)aString  inFrame: (NSRect)aRect;
- (void) _drawAttributedText: (NSAttributedString*)aString  
		     inFrame: (NSRect)aRect;

@end

//
// Function which should be somewhere else
//
inline NSSize 
_sizeForBorderType (NSBorderType aType);



#endif // _GNUstep_H_NSCell

