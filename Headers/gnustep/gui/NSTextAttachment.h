/*
   NSTextAttachment.h

	Classes to represent text attachments.

	NSTextAttachment is used to represent text attachments. When inline, 
	text attachments appear as the value of the NSAttachmentAttributeName 
	attached to the special character NSAttachmentCharacter.

	NSTextAttachment uses an object obeying the NSTextAttachmentCell 
	protocol to get input from the user and to display an image.

	NSTextAttachmentCell is a simple subclass of NSCell which provides 
	the NSTextAttachment protocol.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into GNUstep gui
   by Felipe A. Rodriguez <far@ix.netcom.com> 
   
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

#ifndef STRICT_OPENSTEP

#import <Foundation/Foundation.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSStringDrawing.h>

@class NSFileWrapper;
@class NSTextAttachment;

enum {
    NSAttachmentCharacter = 0xfffc	/* To denote attachments. */
};

/* These are the only methods required of cells in text attachments... The default NSCell class implements most of these; the NSTextAttachmentCell class is a subclass which implements all and provides some additional functionality.
 */
@protocol NSTextAttachmentCell <NSObject>
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (BOOL)wantsToTrackMouse;
- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag;
- (NSSize)cellSize;
- (NSPoint)cellBaselineOffset;
- (void)setAttachment:(NSTextAttachment *)anObject;
- (NSTextAttachment *)attachment;
@end


/* Simple class to provide basic attachment cell functionality. By default this class causes NSTextView to send out delegate messages when the attachment is clicked on or dragged.
 */
@interface NSTextAttachmentCell : NSCell <NSTextAttachmentCell> {
    NSTextAttachment *_attachment;
}
@end


@interface NSTextAttachment : NSObject <NSCoding> {
    NSFileWrapper *_fileWrapper;
    id <NSTextAttachmentCell>_cell;
    struct {
        unsigned int cellWasExplicitlySet:1;
        unsigned int :31;
    } _flags;
}

/* Designated initializer.
 */
- (id)initWithFileWrapper:(NSFileWrapper *)fileWrapper;

/* The fileWrapper is the meat of most types of attachment.  It can be set or queried with these methods.  An NSTextAttachment usually has a fileWrapper.  setFileWrapper does not update the attachment's cell in any way.
 */
- (void)setFileWrapper:(NSFileWrapper *)fileWrapper;
- (NSFileWrapper *)fileWrapper;

/* The cell which handles user interaction. By default an instance of NSTextAttachmentCell is used.
 */
- (id <NSTextAttachmentCell>)attachmentCell;
- (void)setAttachmentCell:(id <NSTextAttachmentCell>)cell;

@end


/* Convenience for creating an attributed string with an attachment.
 */
@interface NSAttributedString (NSAttributedStringAttachmentConveniences)

+ (NSAttributedString *)attributedStringWithAttachment:(NSTextAttachment *)attachment;

@end

@interface NSMutableAttributedString (NSMutableAttributedStringAttachmentConveniences)

- (void)updateAttachmentsFromPath:(NSString *)path;

@end

#endif
