/*
   NSTextView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <AppKit/NSTextView.h>
#include <AppKit/NSPasteboard.h>


@implementation NSTextView

-(void) insertText:(NSString *)insertString
{										// update previous line in case a word 
										// moved up on becoming shorter
unsigned lineIndex = MAX(0, [self lineLayoutIndexForCharacterIndex:
							[self selectedRange].location - 1]);	

	//if(![delegate textDid...]) return; // also send notifications
	
	if([self isRichText])
		{	
		[self replaceRange:[self selectedRange]
				withAttributedString:[[[NSAttributedString alloc] 
				initWithString:insertString attributes:[self typingAttributes]] 
				autorelease]];
		[self rebuildRichLineLayoutInformationStartingAtLine:lineIndex];
		} 
	else
		{	
		[self replaceRange:[self selectedRange] withString:insertString];
		[self rebuildPlainLineLayoutInformationStartingAtLine:lineIndex];
		}													// move the cursor
	[self setSelectedRange:NSMakeRange([self selectedRange].location + 
										[insertString length],0)];	
//	[self displayRect:NSUnionRect([[lineLayoutInformation 
//						objectAtIndex:lineIndex] lineRect], 
//						[[lineLayoutInformation lastObject]lineRect])];
}

- (NSArray*)acceptableDragTypes
{	
NSMutableArray *ret = [NSMutableArray arrayWithObjects:NSStringPboardType, 
						NSColorPboardType, nil];

	if([self isRichText])			
		[ret addObject:NSRTFPboardType];
	if([self importsGraphics])		
		[ret addObject:NSRTFDPboardType];
	return ret;
}

- (void)updateDragTypeRegistration
{	
	[self registerForDraggedTypes:[self acceptableDragTypes]];
}

- (NSRange) selectionRangeForProposedRange:(NSRange)proposedCharRange 
			granularity:(NSSelectionGranularity)granularity
{	
	switch(granularity)
		{	
		case NSSelectByCharacter: 
			return proposedCharRange;

		case NSSelectByWord:
			{	//selectionWordGranularitySet
			} 
			break;
		case NSSelectByParagraph:
			{	//selectionParagraphGranularitySet
			} 
			break;
		} 
	return proposedCharRange;
}

@end
