/*
   NSTextView.m

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

#include <AppKit/NSTextView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSControl.h>

#define ASSIGN(variable, value) [value retain]; \
								[variable release]; \
								variable = value;


@implementation NSTextView

- (void)insertText:(NSString *)insertString
{										
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

//
// Managing the Selection
//
- (void)setSelectedRange:(NSRange)range
{	
	selected_range = range;

	if([self usesFontPanel])								// update fontPanel
		{	
		BOOL isMultiple=NO;
		NSFont *currentFont;
		if([self isRichText])
			{	
				// if(are multiple fonts in selection) isMultiple=YES;
				// else currentFont=[rtfContent attribute:NSFontAttributeName 
				// atIndex:range.location longestEffectiveRange:NULL 
				// inRange:range]
			} 
//		else 
//			currentFont = [[self defaultTypingAttributes] 
//									objectForKey:NSFontAttributeName];
		[[NSFontPanel sharedFontPanel] setPanelFont:currentFont 
										isMultiple:isMultiple];
		}
	
	if(range.length)										// display
		{
		// disable caret timed entry
		} 
	else
		{
		// enable caret timed entry
		}

	[self scrollRangeToVisible:range];
}

- (void)setTypingAttributes:(NSDictionary*) dict
{	
	ASSIGN(typingAttributes, dict);
}

- (NSDictionary*)typingAttributes
{	
	if(typingAttributes) 
		return typingAttributes;
	else 
//		return [self defaultTypingAttributes];
		return nil;
}

- (int) spellCheckerDocumentTag
{	
	if(!spellCheckerDocumentTag) 
		spellCheckerDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];

	return spellCheckerDocumentTag;
}

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender
{	
	[[NSSpellChecker sharedSpellChecker] 
				ignoreWord:[[sender selectedCell] stringValue] 
				inSpellDocumentWithTag:[self spellCheckerDocumentTag]];
}

@end
