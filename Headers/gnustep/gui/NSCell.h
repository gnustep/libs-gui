/* 
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
@class NSView;
@class NSFont;
@class NSText;

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
  NSCellIsInsetButton
} NSCellAttribute;

enum {
  NSNoCellMask			= 0,
  NSContentsCellMask		= 1,
  NSPushInCellMask		= 2,
  NSChangeGrayCellMask		= 4,
  NSChangeBackgroundCellMask	= 8
};

@interface NSCell : NSObject <NSCopying, NSCoding>
{
  // Attributes
  NSString *contents;
  NSImage *cell_image;
  NSFont *cell_font;
  BOOL cell_state;
  BOOL cell_highlighted;
  BOOL cell_enabled;
  BOOL cell_editable;
  BOOL cell_bordered;
  BOOL cell_bezeled;
  BOOL cell_scrollable;
  BOOL cell_selectable;
  BOOL cell_continuous;
  BOOL cell_float_autorange;
  unsigned int cell_float_left;
  unsigned int cell_float_right;
  NSCellImagePosition image_position;
  int cell_type;
  NSTextAlignment text_align;
  int entry_type;
  NSView *control_view;
  NSSize cell_size;
  id represented_object;
  unsigned int action_mask;
}

//
// Initializing an NSCell 
//
- (id)initImageCell:(NSImage *)anImage;
- (id)initTextCell:(NSString *)aString;

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
// Setting the NSCell's Type 
//
- (void)setType:(NSCellType)aType;
- (NSCellType)type;

//
// Setting the NSCell's State 
//
- (void)setState:(int)value;
- (int)state;

//
// Enabling and Disabling the NSCell 
//
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

//
// Setting the Image 
//
- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

//
// Setting the NSCell's Value 
//
- (double)doubleValue;
- (float)floatValue;
- (int)intValue;
- (NSString *)stringValue;
- (void)setDoubleValue:(double)aDouble;
- (void)setFloatValue:(float)aFloat;
- (void)setIntValue:(int)anInt;
- (void)setStringValue:(NSString *)aString;

//
// Interacting with Other NSCells 
//
- (void)takeDoubleValueFrom:(id)sender;
- (void)takeFloatValueFrom:(id)sender;
- (void)takeIntValueFrom:(id)sender;
- (void)takeStringValueFrom:(id)sender;

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
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject;
- (void)setWraps:(BOOL)flag;
- (BOOL)wraps;

//
// Editing Text 
//
- (void)editWithFrame:(NSRect)aRect
	       inView:(NSView *)controlView	
	       editor:(NSText *)textObject	
	       delegate:(id)anObject	
		event:(NSEvent *)theEvent;
- (void)endEditing:(NSText *)textObject;
- (void)selectWithFrame:(NSRect)aRect
		 inView:(NSView *)controlView	 
		 editor:(NSText *)textObject	 
		 delegate:(id)anObject	 
		  start:(int)selStart	 
		 length:(int)selLength;

//
// Validating Input 
//
- (int)entryType;
- (BOOL)isEntryAcceptable:(NSString *)aString;
- (void)setEntryType:(int)aType;

//
// Formatting Data 
//
- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned int)leftDigits
			 right:(unsigned int)rightDigits;

//
// Modifying Graphic Attributes 
//
- (BOOL)isBezeled;
- (BOOL)isBordered;
- (BOOL)isOpaque;
- (void)setBezeled:(BOOL)flag;
- (void)setBordered:(BOOL)flag;

//
// Setting Parameters 
//
- (int)cellAttribute:(NSCellAttribute)aParameter;
- (void)setCellAttribute:(NSCellAttribute)aParameter
		      to:(int)value;

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
// Target and Action 
//
- (SEL)action;
- (BOOL)isContinuous;
- (int)sendActionOn:(int)mask;
- (void)setAction:(SEL)aSelector;
- (void)setContinuous:(BOOL)flag;
- (void)setTarget:(id)anObject;
- (id)target;
- (void)performClick:(id)sender;

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// Handling Keyboard Alternatives 
//
- (NSString *)keyEquivalent;

//
// Tracking the Mouse 
//
+ (BOOL)prefersTrackingUntilMouseUp;
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
// Comparing to Another NSCell 
//
- (NSComparisonResult)compare:(id)otherCell;

//
// Using the NSCell to Represent an Object
//
- (id)representedObject;
- (void)setRepresentedObject:(id)anObject;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSCell

