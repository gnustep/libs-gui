/* 
   NSCStringText.m

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

#include <gnustep/gui/config.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSCStringText.h>
#include <AppKit/NSText.h>

//
// NSCStringText implementation
//
@implementation NSCStringText

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSCStringText class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Setting the font
//
+ (NSFont *)defaultFont
{
  return nil;
}

+ (void)setDefaultFont:(NSFont *)anObject
{}

//
// Displaying Graphics within the Text
//
+ registerDirective:(NSString *)directive
           forClass:class
{
  return nil;
}

+ excludeFromServicesMenu:(BOOL)flag
{
  return nil;
}

//
// Instance methods
//
//
// Initializing a New NSCStringText Object
//
- (id)initWithFrame:(NSRect)frameRect
               text:(NSString *)theText
          alignment:(NSTextAlignment)mode
{
  return nil;
}

//
// Modifying the Frame Rectangle
//
- (void)resizeTextWithOldBounds:(NSRect)oldBounds
                        maxRect:(NSRect)maxRect
{}

//
// Laying Out the Text
//
- (int)calcLine
{
  return 0;
}

- (BOOL)changeTabStopAt:(float)oldX
                     to:(float)newX
{
  return NO;
}

- (BOOL)charWrap
{
  return NO;
}

- (void *)defaultParagraphStyle
{
  return (void *)0;
}

- (float)descentLine
{
  return 0.0;
}

- (void)getMarginLeft:(float *)leftMargin
                right:(float *)rightMargin
		  top:(float *)topMargin
	       bottom:(float *)bottomMargin
{}

- (void)getMinWidth:(float *)width
          minHeight:(float *)height
           maxWidth:(float)widthMax
          maxHeight:(float)heightMax
{}

- (float)lineHeight
{
  return 0.0;
}

- (void *)paragraphStyleForFont:(NSFont *)fontId
                      alignment:(int)alignment
{
  return (void *)0;
}

- (void)setCharWrap:(BOOL)flag
{}

- (void)setDescentLine:(float)value
{}

- (void)setLineHeight:(float)value
{}

- (void)setMarginLeft:(float)leftMargin
                right:(float)rightMargin
                  top:(float)topMargin
               bottom:(float)bottomMargin
{}

- (void)setNoWrap
{}

- (void)setParagraphStyle:(void *)paraStyle
{}

- (BOOL)setSelProp:(NSParagraphProperty)property
                to:(float)value
{
  return NO;
}

//
// Reporting Line and Position
//
- (int)lineFromPosition:(int)position
{
  return 0;
}

- (int)positionFromLine:(int)line
{
  return 0;
}

//
// Reading and Writing Text
//
- (void)finishReadingRichText
{}

- (NSTextBlock *)firstTextBlock
{
  return (NSTextBlock *)0;
}

- (NSRect)paragraphRect:(int)paraNumber
                  start:(int *)startPos
                    end:(int *)endPos
{
  return NSZeroRect;
}

- (void)startReadingRichText
{}

//
// Editing Text
//
- (void)clear:(id)sender
{}

- (void)hideCaret
{}

- (void)showCaret
{}

//
// Managing the Selection
//
- (void)getSelectionStart:(NSSelPt *)start
                      end:(NSSelPt *)end
{}

- (void)replaceSel:(NSString *)aString
{}

- (void)replaceSel:(NSString *)aString
            length:(int)length
{}

- (void)replaceSel:(NSString *)aString
            length:(int)length
              runs:(NSRunArray *)insertRuns
{}

- (void)scrollSelToVisible
{}

- (void)selectError
{}

- (void)selectNull
{}

- (void)setSelectionStart:(int)start
                      end:(int)end
{}

- (void)selectText:(id)sender
{}

//
// Setting the font
//
- (void)setFont:(NSFont *)fontObj
 paragraphStyle:(void *)paragraphStyle
{}

- (void)setSelFont:(NSFont *)fontObj
{}

- (void)setSelFont:(NSFont *)fontObj
 paragraphStyle:(void *)paragraphStyle
{}

- (void)setSelFontFamily:(NSString *)fontName
{}

- (void)setSelFontSize:(float)size
{}

- (void)setSelFontStyle:(NSFontTraitMask)traits
{}

//
// Finding Text
//
- (BOOL)findText:(NSString *)textPattern
      ignoreCase:(BOOL)ignoreCase
       backwards:(BOOL)backwards
            wrap:(BOOL)wrap
{
  return NO;
}

//
// Modifying Graphics Attributes
//
- (NSColor *)runColor:(NSRun *)run
{
  return nil;
}

- (NSColor *)selColor
{
  return nil;
}

- (void)setSelColor:(NSColor *)color
{}

//
// Reusing an NSCStringText Object
//
- (void)renewFont:(NSFont *)newFontObj
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag
{}

- (void)renewFont:(NSString *)newFontName
             size:(float)newFontSize
            style:(int)newFontStyle
	     text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag
{}

- (void)renewRuns:(NSRunArray *)newRuns
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag
{}

//
// Setting Window Attributes
//
- (BOOL)isRetainedWhileDrawing
{
  return NO;
}

- (void)setRetainedWhileDrawing:(BOOL)flag
{}

//
// Assigning a Tag
//
- (void)setTag:(int)anInt
{}

- (int)tag
{
  return 0;
}

//
// Handling Event Messages
//
- (void)becomeKeyWindow
{}

- (void)moveCaret:(unsigned short)theKey
{}

- (void)resignKeyWindow
{}

//
// Displaying Graphics within the Text
//
- (NSPoint)locationOfCell:(NSCell *)cell
{
  return NSZeroPoint;
}

- (void)replaceSelWithCell:(NSCell *)cell
{}

- (void)setLocation:(NSPoint)origin
             ofCell:(NSCell *)cell
{}

- (BOOL)readSelectionFromPasteboard:(NSPasteBoard *)pboard
{
  return NO;
}

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
  return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
  return NO;
}

//
// Setting Tables and Functions
//
- (const NSFSM *)breakTable
{
  return (const NSFSM *)0;
}

- (const unsigned char *)charCategoryTable
{
  return (const unsigned char *)0;
}

- (NSCharFilterFunc)charFilter
{
  return (NSCharFilterFunc)0;
}

- (const NSFSM *)clickTable
{
  return (const NSFSM *)0;
}

- (NSTextFunc)drawFunc
{
  return (NSTextFunc)0;
}

- (const unsigned char *)postSelSmartTable
{
  return (const unsigned char *)0;
}

- (const unsigned char *)preSelSmartTable
{
  return (const unsigned char *)0;
}

- (NSTextFunc)scanFunc
{
  return (NSTextFunc)0;
}

- (void)setBreakTable:(const NSFSM *)aTable
{}

- (void)setCharCategoryTable:(const unsigned char *)aTable
{}

- (void)setCharFilter:(NSCharFilterFunc)aFunction
{}

- (void)setClickTable:(const NSFSM *)aTable
{}

- (void)setDrawFunc:(NSTextFunc)aFunction
{}

- (void)setPostSelSmartTable:(const unsigned char *)aTable
{}

- (void)setPreSelSmartTable:(const unsigned char *)aTable
{}

- (void)setScanFunc:(NSTextFunc)aFunction
{}

- (void)setTextFilter:(NSTextFilterFunc)aFunction
{}

- (NSTextFilterFunc)textFilter
{
  return (NSTextFilterFunc)0;
}

//
// Printing
//
- (void)adjustPageHeightNew:(float *)newBottom
                        top:(float)oldTop
                     bottom:(float)oldBottom
                      limit:(float)bottomLimit
{}

- (NSSize)cellSize
{
  return NSZeroSize;
}

- (void)drawWithFrame:(NSRect)cellFrame
               inView:(NSView *)controlView
{}

- (void)highlight:(BOOL)flag
        withFrame:(NSRect)cellFrame
           inView:(NSView *)controlView
{}

- (void)readRichText:(NSString *)stringObject
             forView:(NSView *)view
{}

- (NSString *)richTextForView:(NSView *)view
{
  return nil;
}

- (BOOL)trackMouse:(NSEvent *)theEvent
            inRect:(NSRect)cellFrame
	    ofView:(NSView *)controlView
      untilMouseUp:(BOOL)untilMouseUp
{
  return NO;
}

//
// Implemented by the Delegate
//
- (void)textDidRead:(NSCStringText *)textObject
          paperSize:(NSSize)paperSize
{}

- (NSRect)textDidResize:(NSCStringText *)textObject
              oldBounds:(NSRect)oldBounds
{
  return NSZeroRect;
}

- (NSFont *)textWillConvert:(NSCStringText *)textObject
                     toFont:(NSFont *)font
{
  return nil;
}

- (void)textWillFinishReadingRichText:(NSCStringText *)textObject
{}

- (void)textWillSetSel:(NSCStringText *)textObject
                toFont:(NSFont *)font
{}

- (void)textWillStartReadingRichText:(NSCStringText *)textObject
{}

- (NSSize)textWillWrite:(NSCStringText *)textObject
{
return NSZeroSize;
}

//
// Compatibility Methods
//
- (NSCStringTextInternalState *)cStringTextInternalState
{
  return (NSCStringTextInternalState *)0;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{}

- initWithCoder:aDecoder
{
  return nil;
}

//
// NSChangeSpelling protocol
//
- (void) changeSpelling:(id)sender
{}

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender
{}

@end
