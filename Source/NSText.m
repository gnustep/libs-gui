/* 
   NSText.m

   The RTFD text class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
  
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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>

#include <AppKit/NSText.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSControl.h>

#include <Foundation/NSScanner.h>

#define ASSIGN(variable, value) [value retain]; \
								[variable release]; \
								variable = value;


//
// NSText implementation
//
@implementation NSText

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSText class])
		[self setVersion:1];						// Initial version
}

//
// Instance methods
//
//
// Initialization
//
- init
{
	return [self initWithFrame:NSZeroRect];
}

- initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	
	text_contents = @"Text";
	alignment = NSLeftTextAlignment;
	is_editable = YES;
	is_rich_text = NO;
	is_selectable = YES;
	imports_graphics = NO;
	uses_font_panel = YES;
	is_horizontally_resizable = YES;
	is_vertically_resizable = YES;
	is_ruler_visible = NO;
	is_field_editor = NO;
	draws_background = YES;
	background_color = [[NSColor whiteColor] retain];
	text_color = [[NSColor blackColor] retain];
	default_font = [[NSFont userFontOfSize:12] retain];

	return self;
}

- (void)dealloc 
{	
	[default_font release];
	[text_color release];
	[background_color release];
	[plainContent release];
	[rtfContent release];

    [super dealloc];
}

//
// Getting and Setting Contents 
//
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)aString
{	
}

- (void)replaceCharactersInRange:(NSRange)range withRTF:(NSData *)rtfData
{	
}

- (void)replaceCharactersInRange:(NSRange)range withRTFD:(NSData *)rtfdData
{	
}

- (void)replaceRange:(NSRange)range withRTF:(NSData *)rtfData
{	
	[self replaceRange:range withRTFD:rtfData];
}

- (void)replaceRange:(NSRange)range withRTFD:(NSData *)rtfdData
{	
}

- (NSData *)RTFDFromRange:(NSRange)range
{	
	return nil;
}

- (NSData *)RTFFromRange:(NSRange)range
{	
	return [self RTFDFromRange:range];
}

- (void)setString:(NSString *)string
{	
	ASSIGN(text_contents, string);
}

- (NSString*)string
{	
	if([self isRichText])	
		return [rtfContent string];
	else					
		return text_contents;
}

- (void)setText:(NSString *)string	{ [self setString:string]; }

- (void)setText:(NSString *)aString range:(NSRange)range
{	
	[self replaceCharactersInRange:(NSRange)range withString:aString];
}

- (NSString *)text					{ return text_contents; }

//
// Managing Global Characteristics
//
- (NSTextAlignment)alignment		{ return alignment; }
- (BOOL)drawsBackground				{ return draws_background; }
- (BOOL)importsGraphics				{ return imports_graphics; }
- (BOOL)isEditable					{ return is_editable; }
- (BOOL)isRichText					{ return is_rich_text; }
- (BOOL)isSelectable				{ return is_selectable; }

- (void)setAlignment:(NSTextAlignment)mode
{
	alignment = mode;
}

- (void)setDrawsBackground:(BOOL)flag
{
	draws_background = flag;
}

- (void)setEditable:(BOOL)flag
{
	is_editable = flag;
	if (flag)									// If we are editable then we 
    	is_selectable = YES;					// are selectable
}

- (void)setImportsGraphics:(BOOL)flag
{
	imports_graphics = flag;
}

- (void)setRichText:(BOOL)flag
{
	is_rich_text = flag;
}

- (void)setSelectable:(BOOL)flag
{
	is_selectable = flag;
	if (!flag)									// If we are not selectable
    	is_editable = NO;						// then we must not be editable
}

//
// Managing Font and Color
//
- (NSColor *)backgroundColor		{ return background_color; }
- (NSFont *)font					{ return default_font; }
- (NSColor *)textColor				{ return text_color; }
- (BOOL)usesFontPanel				{ return uses_font_panel; }

- (void)changeFont:(id)sender
{	
}

- (void)setBackgroundColor:(NSColor *)color
{
	ASSIGN(background_color, color);
}

- (void)setTextColor:(NSColor *)color ofRange:(NSRange)range
{	
	if([self isRichText])
		{	
		if(color) 
			[rtfContent addAttribute:NSForegroundColorAttributeName 
						value:color 
						range:range];
		else 
			{}
		}
}

- (void)setColor:(NSColor *)color ofRange:(NSRange)range
{	
	[self setColor:color ofRange:range];
}

- (void)setFont:(NSFont *)obj
{
	ASSIGN(default_font, obj);
}

- (void)setFont:(NSFont *)font ofRange:(NSRange)range
{	
	if([self isRichText])
		{	
		if(font) 
			[rtfContent addAttribute:NSFontAttributeName 
						value:font 
						range:range];
		else 
			{}
		}
}

- (void)setTextColor:(NSColor *)color
{
	text_color = color;
}

- (void)setUsesFontPanel:(BOOL)flag
{
	uses_font_panel = flag;
}

//
// Managing the Selection
//
- (NSRange)selectedRange			{ return selected_range; }

- (void)setSelectedRange:(NSRange)range
{	
	selected_range = range;
}

//
// Sizing the Frame Rectangle
//
- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
}

- (BOOL)isHorizontallyResizable		{ return is_horizontally_resizable; }
- (BOOL)isVerticallyResizable		{ return is_vertically_resizable; }
- (NSSize)maxSize 					{ return NSZeroSize; }
- (NSSize)minSize					{ return NSZeroSize; }

- (void)setHorizontallyResizable:(BOOL)flag
{
	is_horizontally_resizable = flag;
}

- (void)setMaxSize:(NSSize)newMaxSize
{
}

- (void)setMinSize:(NSSize)newMinSize
{
}

- (void)setVerticallyResizable:(BOOL)flag
{
	is_vertically_resizable = flag;
}

- (void)sizeToFit
{	
}

//
// Responding to Editing Commands
//
- (void)alignCenter:(id)sender
{
}

- (void)alignLeft:(id)sender
{
}

- (void)alignRight:(id)sender
{
}

- (void)copy:(id)sender
{	
NSMutableArray *types = [NSMutableArray arrayWithObjects:NSStringPboardType, 
													   NSColorPboardType, nil];
NSPasteboard *pboard = [NSPasteboard generalPasteboard];

	if([self isRichText])			
		[types addObject:NSRTFPboardType];
	if([self importsGraphics])		
		[types addObject:NSRTFDPboardType];
	[pboard declareTypes:types owner:self];
	[pboard setString:[self string] forType:NSStringPboardType];
//	if([self isRichText]) 
//		[pboard setData:[[self class] dataForAttributedString:rtfContent] 
//									  forType:NSRTFPboardType];
//	if([self importsGraphics]) 
//		[pboard setData:[[self class] dataForAttributedString:rtfContent] 
//									  forType:NSRTFDPboardType];
}

- (void)copyFont:(id)sender
{
}

- (void)copyRuler:(id)sender
{
}

- (void)delete:(id)sender
{	
NSRange selRange = [self selectedRange];
	
	if(selRange.length) 
		[self replaceCharactersInRange:selRange withString:@""];
															// move the cursor
	[self setSelectedRange:NSMakeRange([self selectedRange].location,0)];	
}

- (void)cut:(id)sender
{	
	if([self selectedRange].length)
		{	
		[self delete:self];
		[self copy:self];
		}
}

- (void)paste:(id)sender
{	
// NSPasteboard *pboard = [NSPasteboard generalPasteboard];

	//-(void) insertText:(NSString *)insertString
}

- (void)pasteFont:(id)sender
{
}

- (void)pasteRuler:(id)sender
{
}

- (void)selectAll:(id)sender
{
}

- (void)subscript:(id)sender
{
}

- (void)superscript:(id)sender
{
}

- (void)underline:(id)sender
{
}

- (void)unscript:(id)sender
{
}

//
// Managing the Ruler
//
- (BOOL)isRulerVisible				{ return NO; }

- (void)toggleRuler:(id)sender
{
}

//
// Spelling
//
- (void)checkSpelling:(id)sender
{
}

- (void)showGuessPanel:(id)sender
{	
	[[NSSpellChecker sharedSpellChecker] orderFront:self];
}

//
// Scrolling
//
- (void)scrollRangeToVisible:(NSRange)range
{	
}

//
// Reading and Writing RTFD Files
//
- (BOOL)readRTFDFromFile:(NSString *)path
{	
	return NO;
}

- (BOOL)writeRTFDToFile:(NSString *)path atomically:(BOOL)flag
{	
	return NO;
}

//
// Managing the Field Editor
//
- (BOOL)isFieldEditor				{ return is_field_editor; }

- (void)setFieldEditor:(BOOL)flag
{
	is_field_editor = flag;
}

//
// Handling Events 
//
- (void)mouseDown:(NSEvent *)theEvent
{	
	if (!is_selectable) 						// If not selectable then don't
		return;									// recognize the mouse down
	[[self window] makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (!is_selectable) 						// If not selectable then don't
		return;									// recognize the mouse up
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if (!is_selectable) 						// If not selectable then don't
		return;									// recognize the mouse moved
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (!is_editable) 							// If not editable then don't
		return;									// recognize the key down
}

- (void)keyUp:(NSEvent *)theEvent
{
	if (!is_editable) 							// If not editable then don't
		return;									// recognize the key up
}

- (BOOL)acceptsFirstResponder
{
	if ([self isSelectable])
		return YES;
	else
		return NO;
}

- (BOOL)becomeFirstResponder
{
	if ([self isEditable])
		return YES;
	else
		return NO;
}

//
// Managing the Delegate
//
- (id)delegate						{ return delegate; }

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

//
// Implemented by the Delegate
//
- (void)textDidBeginEditing:(NSNotification *)aNotification
{
	if ([delegate respondsToSelector:@selector(textDidBeginEditing:)])
    	[delegate textDidBeginEditing:nil];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	if ([delegate respondsToSelector:@selector(textDidChange:)])
		[delegate textDidChange:nil];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
	if ([delegate respondsToSelector:@selector(textDidEndEditing:)])
    	[delegate textDidEndEditing:nil];
}

- (BOOL)textShouldBeginEditing:(NSText *)textObject
{
	if ([delegate respondsToSelector:@selector(textShouldBeginEditing:)])
    	return [delegate textShouldBeginEditing:nil];
	else
		return YES;
}

- (BOOL)textShouldEndEditing:(NSText *)textObject
{
	if ([delegate respondsToSelector:@selector(textShouldEndEditing:)])
    	return [delegate textShouldEndEditing:nil];
	else
		return YES;
}

//
// Displaying
//
- (void)drawRect:(NSRect)rect
{	
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeConditionalObject:delegate];

	[aCoder encodeObject: plainContent];
	[aCoder encodeObject: rtfContent];

	[aCoder encodeValueOfObjCType: "I" at: &alignment];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_editable];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_rich_text];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_selectable];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &imports_graphics];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &uses_font_panel];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at:&is_horizontally_resizable];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_vertically_resizable];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_ruler_visible];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_field_editor];
	[aCoder encodeObject: background_color];
	[aCoder encodeObject: text_color];
	[aCoder encodeObject: default_font];
	[aCoder encodeValueOfObjCType: @encode(NSRange) at: &selected_range];
}

- initWithCoder:aDecoder
{
	[super initWithCoder:aDecoder];

	delegate = [aDecoder decodeObject];

	plainContent= [aDecoder decodeObject];
	rtfContent= [aDecoder decodeObject];

	[aDecoder decodeValueOfObjCType: "I" at: &alignment];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_editable];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_rich_text];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_selectable];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &imports_graphics];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &uses_font_panel];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) 
			  at: &is_horizontally_resizable];
	[aDecoder decodeValueOfObjCType:@encode(BOOL) at:&is_vertically_resizable];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_ruler_visible];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_field_editor];
	background_color = [aDecoder decodeObject];
	text_color = [aDecoder decodeObject];
	default_font = [aDecoder decodeObject];
	[aDecoder decodeValueOfObjCType: @encode(NSRange) at: &selected_range];

	return self;
}

//
// NSChangeSpelling protocol
//
- (void) changeSpelling:(id)sender
{	
	[self replaceCharactersInRange:[self selectedRange] 
		  withString:[[sender selectedCell] stringValue]];
}

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender
{	
}

@end
