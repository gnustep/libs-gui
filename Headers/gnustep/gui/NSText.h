/* 
   NSText.h

   The text object

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSText
#define _GNUstep_H_NSText

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <AppKit/NSFont.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSNotification.h>

@interface NSText : NSView <NSCoding>

{
  // Attributes
  id delegate;
  NSString *text_contents;
  unsigned int alignment;
  BOOL is_editable;
  BOOL is_rich_text;
  BOOL is_selectable;
  BOOL imports_graphics;
  BOOL uses_font_panel;
  BOOL is_horizontally_resizable;
  BOOL is_vertically_resizable;
  BOOL is_ruler_visible;
  BOOL is_field_editor;
  NSColor *background_color;
  NSColor *text_color;
  NSFont *default_font;
  NSRange selected_range;
  // Reserved for back-end use
  void *be_text_reserved;
}

//
// Getting and Setting Contents 
//
- (void)replaceRange:(NSRange)range
	     withRTF:(NSData *)rtfData;
- (void)replaceRange:(NSRange)range
	    withRTFD:(NSData *)rtfdData;
- (NSData *)RTFDFromRange:(NSRange)range;
- (NSData *)RTFFromRange:(NSRange)range;
- (void)setText:(NSString *)string;
- (void)setText:(NSString *)string
	  range:(NSRange)range;
- (NSString *)text;

//
// Managing Global Characteristics
//
- (NSTextAlignment)alignment;
- (BOOL)drawsBackground;
- (BOOL)importsGraphics;
- (BOOL)isEditable;
- (BOOL)isRichText;
- (BOOL)isSelectable;
- (void)setAlignment:(NSTextAlignment)mode;
- (void)setDrawsBackground:(BOOL)flag;
- (void)setEditable:(BOOL)flag;
- (void)setImportsGraphics:(BOOL)flag;
- (void)setRichText:(BOOL)flag;
- (void)setSelectable:(BOOL)flag;

//
// Managing Font and Color
//
- (NSColor *)backgroundColor;
- (void)changeFont:(id)sender;
- (NSFont *)font;
- (void)setBackgroundColor:(NSColor *)color;
- (void)setColor:(NSColor *)color
	 ofRange:(NSRange)range;
- (void)setFont:(NSFont *)obj;
- (void)setFont:(NSFont *)font
	ofRange:(NSRange)range;
- (void)setTextColor:(NSColor *)color;
- (void)setUsesFontPanel:(BOOL)flag;
- (NSColor *)textColor;
- (BOOL)usesFontPanel;

//
// Managing the Selection
//
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)range;

//
// Sizing the Frame Rectangle
//
- (BOOL)isHorizontallyResizable;
- (BOOL)isVerticallyResizable;
- (NSSize)maxSize;
- (NSSize)minSize;
- (void)setHorizontallyResizable:(BOOL)flag;
- (void)setMaxSize:(NSSize)newMaxSize;
- (void)setMinSize:(NSSize)newMinSize;
- (void)setVerticallyResizable:(BOOL)flag;
- (void)sizeToFit;

//
// Responding to Editing Commands
//
- (void)alignCenter:(id)sender;
- (void)alignLeft:(id)sender;
- (void)alignRight:(id)sender;
- (void)copy:(id)sender;
- (void)copyFont:(id)sender;
- (void)copyRuler:(id)sender;
- (void)cut:(id)sender;
- (void)delete:(id)sender;
- (void)paste:(id)sender;
- (void)pasteFont:(id)sender;
- (void)pasteRuler:(id)sender;
- (void)selectAll:(id)sender;
- (void)subscript:(id)sender;
- (void)superscript:(id)sender;
- (void)underline:(id)sender;
- (void)unscript:(id)sender;

//
// Managing the Ruler
//
- (BOOL)isRulerVisible;
- (void)toggleRuler:(id)sender;

//
// Spelling
//
- (void)checkSpelling:(id)sender;
- (void)showGuessPanel:(id)sender;

//
// Scrolling
//
- (void)scrollRangeToVisible:(NSRange)range;

//
// Reading and Writing RTFD Files
//
- (BOOL)readRTFDFromFile:(NSString *)path;
- (BOOL)writeRTFDToFile:(NSString *)path
	     atomically:(BOOL)flag;

//
// Managing the Field Editor
//
- (BOOL)isFieldEditor;
- (void)setFieldEditor:(BOOL)flag;

//
// Managing the Delegate
//
- (id)delegate;
- (void)setDelegate:(id)anObject;

//
// Implemented by the Delegate
//
- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (BOOL)textShouldBeginEditing:(NSText *)textObject;
- (BOOL)textShouldEndEditing:(NSText *)textObject;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSText
