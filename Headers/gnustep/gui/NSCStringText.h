/* 
   NSCStringText.h

   C string text class

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSCStringText
#define _GNUstep_H_NSCStringText

#include <AppKit/stdappkit.h>
#include <AppKit/NSText.h>
#include <Foundation/NSCoder.h>

@class NSCell;
@class NSPasteBoard;



@interface NSCStringText : NSText
           <NSChangeSpelling, NSIgnoreMisspelledWords, NSCoding>

{
  // Attributes
}


//
// Initializing a New NSCStringText Object
//
- (id)initWithFrame:(NSRect)frameRect
               text:(NSString *)theText
          alignment:(NSTextAlignment)mode;

//
// Modifying the Frame Rectangle
//
- (void)resizeTextWithOldBounds:(NSRect)oldBounds
                        maxRect:(NSRect)maxRect;

//
// Laying Out the Text
//
- (int)calcLine;
- (BOOL)changeTabStopAt:(float)oldX
                     to:(float)newX;
- (BOOL)charWrap;
- (void *)defaultParagraphStyle;
- (float)descentLine;
- (void)getMarginLeft:(float *)leftMargin
                right:(float *)rightMargin
		  top:(float *)topMargin
	       bottom:(float *)bottomMargin;
- (void)getMinWidth:(float *)width
          minHeight:(float *)height
           maxWidth:(float)widthMax
          maxHeight:(float)heightMax;
- (float)lineHeight;
- (void *)paragraphStyleForFont:(NSFont *)fontId
                      alignment:(int)alignment;
- (void)setCharWrap:(BOOL)flag;
- (void)setDescentLine:(float)value;
- (void)setLineHeight:(float)value;
- (void)setMarginLeft:(float)leftMargin
                right:(float)rightMargin
                  top:(float)topMargin
               bottom:(float)bottomMargin;
- (void)setNoWrap;
- (void)setParagraphStyle:(void *)paraStyle;
- (BOOL)setSelProp:(NSParagraphProperty)property
                to:(float)value;

//
// Reporting Line and Position
//
- (int)lineFromPosition:(int)position;
- (int)positionFromLine:(int)line;

//
// Reading and Writing Text
//
- (void)finishReadingRichText;
- (NSTextBlock *)firstTextBlock;
- (NSRect)paragraphRect:(int)paraNumber
                  start:(int *)startPos
                    end:(int *)endPos;
- (void)startReadingRichText;

//
// Editing Text
//
- (void)clear:(id)sender;
- (void)hideCaret;
- (void)showCaret;

//
// Managing the Selection
//
- (void)getSelectionStart:(NSSelPt *)start
                      end:(NSSelPt *)end;
- (void)replaceSel:(NSString *)aString;
- (void)replaceSel:(NSString *)aString
            length:(int)length;
- (void)replaceSel:(NSString *)aString
            length:(int)length
              runs:(NSRunArray *)insertRuns;
- (void)scrollSelToVisible;
- (void)selectError;
- (void)selectNull;
- (void)setSelectionStart:(int)start
                      end:(int)end;
- (void)selectText:(id)sender;

//
// Setting the font
//
+ (NSFont *)defaultFont;
+ (void)setDefaultFont:(NSFont *)anObject;
- (void)setFont:(NSFont *)fontObj
 paragraphStyle:(void *)paragraphStyle;
- (void)setSelFont:(NSFont *)fontObj;
- (void)setSelFont:(NSFont *)fontObj
    paragraphStyle:(void *)paragraphStyle;
- (void)setSelFontFamily:(NSString *)fontName;
- (void)setSelFontSize:(float)size;
- (void)setSelFontStyle:(NSFontTraitMask)traits;

//
// Finding Text
//
- (BOOL)findText:(NSString *)textPattern
      ignoreCase:(BOOL)ignoreCase
       backwards:(BOOL)backwards
            wrap:(BOOL)wrap;

//
// Modifying Graphics Attributes
//
- (NSColor *)runColor:(NSRun *)run;
- (NSColor *)selColor;
- (void)setSelColor:(NSColor *)color;

//
// Reusing an NSCStringText Object
//
- (void)renewFont:(NSFont *)newFontObj
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;
- (void)renewFont:(NSString *)newFontName
             size:(float)newFontSize
            style:(int)newFontStyle
	     text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;
- (void)renewRuns:(NSRunArray *)newRuns
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;

//
// Setting Window Attributes
//
- (BOOL)isRetainedWhileDrawing;
- (void)setRetainedWhileDrawing:(BOOL)flag;

//
// Assigning a Tag
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// Handling Event Messages
//
- (void)becomeKeyWindow;
- (void)moveCaret:(unsigned short)theKey;
- (void)resignKeyWindow;

//
// Displaying Graphics within the Text
//
+ registerDirective:(NSString *)directive
           forClass:class;
- (NSPoint)locationOfCell:(NSCell *)cell;
- (void)replaceSelWithCell:(NSCell *)cell;
- (void)setLocation:(NSPoint)origin
             ofCell:(NSCell *)cell;
+ excludeFromServicesMenu:(BOOL)flag;
- (BOOL)readSelectionFromPasteboard:(NSPasteBoard *)pboard;
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType;
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types;

//
// Setting Tables and Functions
//
- (const NSFSM *)breakTable;
- (const unsigned char *)charCategoryTable;
- (NSCharFilterFunc)charFilter;
- (const NSFSM *)clickTable;
- (NSTextFunc)drawFunc;
- (const unsigned char *)postSelSmartTable;
- (const unsigned char *)preSelSmartTable;
- (NSTextFunc)scanFunc;
- (void)setBreakTable:(const NSFSM *)aTable;
- (void)setCharCategoryTable:(const unsigned char *)aTable;
- (void)setCharFilter:(NSCharFilterFunc)aFunction;
- (void)setClickTable:(const NSFSM *)aTable;
- (void)setDrawFunc:(NSTextFunc)aFunction;
- (void)setPostSelSmartTable:(const unsigned char *)aTable;
- (void)setPreSelSmartTable:(const unsigned char *)aTable;
- (void)setScanFunc:(NSTextFunc)aFunction;
- (void)setTextFilter:(NSTextFilterFunc)aFunction;
- (NSTextFilterFunc)textFilter;

//
// Printing
//
- (void)adjustPageHeightNew:(float *)newBottom
                        top:(float)oldTop
                     bottom:(float)oldBottom
                      limit:(float)bottomLimit;
- (NSSize)cellSize;
- (void)drawWithFrame:(NSRect)cellFrame
               inView:(NSView *)controlView;
- (void)highlight:(BOOL)flag
        withFrame:(NSRect)cellFrame
           inView:(NSView *)controlView;
- (void)readRichText:(NSString *)stringObject
             forView:(NSView *)view;
- (NSString *)richTextForView:(NSView *)view;
- (BOOL)trackMouse:(NSEvent *)theEvent
            inRect:(NSRect)cellFrame
            ofView:(NSView *)controlView
      untilMouseUp:(BOOL)untilMouseUp;

//
// Implemented by the Delegate
//
- (void)textDidRead:(NSCStringText *)textObject
          paperSize:(NSSize)paperSize;
- (NSRect)textDidResize:(NSCStringText *)textObject
              oldBounds:(NSRect)oldBounds;
- (NSFont *)textWillConvert:(NSCStringText *)textObject
                     toFont:(NSFont *)font;
- (void)textWillFinishReadingRichText:(NSCStringText *)textObject;
- (void)textWillSetSel:(NSCStringText *)textObject
                toFont:(NSFont *)font;
- (void)textWillStartReadingRichText:(NSCStringText *)textObject;
- (NSSize)textWillWrite:(NSCStringText *)textObject;

//
// Compatibility Methods
//
- (NSCStringTextInternalState *)cStringTextInternalState;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

//
// NSChangeSpelling protocol
//
- (void) changeSpelling:(id)sender;

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender;

@end

#endif // _GNUstep_H_NSCStringText
