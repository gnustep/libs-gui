/*
   NSTextView.h

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

#ifndef _GNUstep_H_NSTextView
#define _GNUstep_H_NSTextView

#include <AppKit/NSText.h>

@interface NSTextView : NSText
{
	NSDictionary *typingAttributes;
	int spellCheckerDocumentTag;
}

- (void)insertText:(NSString *)insertString;

- (NSDictionary*)typingAttributes;
- (void)setTypingAttributes:(NSDictionary *)attrs;

- (NSArray *)acceptableDragTypes;
- (void)updateDragTypeRegistration;

- (NSRange) selectionRangeForProposedRange:(NSRange)proposedCharRange 
			granularity:(NSSelectionGranularity)granularity;

- (int)spellCheckerDocumentTag;

//
// Managing the Selection   NSText method
//
- (void)setSelectedRange:(NSRange)range;

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender;

@end

#endif /* _GNUstep_H_NSTextView */
