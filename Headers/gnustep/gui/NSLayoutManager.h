/*
   NSLayoutManager.h

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2002-11

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

#ifndef _GNUstep_H_NSLayoutManager
#define _GNUstep_H_NSLayoutManager

#include <AppKit/GSLayoutManager.h>
#include <AppKit/NSTextView.h>

@class NSParagraphStyle;

@interface NSLayoutManager : GSLayoutManager
{
  /* Public for use only in the associated NSTextViews.  Don't access
     them directly from elsewhere. */
@public 
  /* Ivars to synchronize multiple textviews */
  BOOL _isSynchronizingFlags;
  BOOL _isSynchronizingDelegates;
  BOOL _beganEditing;

  /* Selection */
  NSRange _selected_range;
  NSRange _original_selected_range;
  NSSelectionGranularity _selectionGranularity;

  /* Retained by the NSLayoutManager. NSTextView:s that change this value
  should release the old value and retain the new one. It is nil originally
  and will be released when the NSLayoutManager is deallocated. */
  NSMutableDictionary *_typingAttributes;
}

/* TODO */

- (void) invalidateDisplayForGlyphRange: (NSRange)aRange;
- (void) invalidateDisplayForCharacterRange: (NSRange)aRange; /* not STRICT_40 ?? */

- (NSTextView *) firstTextView;
- (NSTextView *) textViewForBeginningOfSelection;
- (BOOL) layoutManagerOwnsFirstResponderInWindow: (NSWindow *)window;

- (NSArray *) rulerMarkersForTextView: (NSTextView *)textView
	paragraphStyle: (NSParagraphStyle *)style
	ruler: (NSRulerView *)ruler;
- (NSView *) rulerAccessoryViewForTextView: (NSTextView *)textView
	paragraphStyle: (NSParagraphStyle *)style
	ruler: (NSRulerView *)ruler
	enabled: (BOOL)isEnabled;

- (float) hyphenationFactor;
- (void) setHyphenationFactor: (float)factor;

@end


@interface NSLayoutManager (layout)

- (void) textContainerChangedTextView: (NSTextContainer *)aContainer;


- (NSPoint) locationForGlyphAtIndex: (unsigned int)glyphIndex;


- (NSRect *) rectArrayForGlyphRange: (NSRange)glyphRange
	withinSelectedGlyphRange: (NSRange)selGlyphRange
	inTextContainer: (NSTextContainer *)container
	rectCount: (unsigned int *)rectCount;
- (NSRect *) rectArrayForCharacterRange: (NSRange)charRange
	withinSelectedCharacterRange: (NSRange)selCharRange
	inTextContainer: (NSTextContainer *)container
	rectCount: (unsigned int *)rectCount;

- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange 
	inTextContainer: (NSTextContainer *)aTextContainer;


- (NSRange) glyphRangeForBoundingRect: (NSRect)bounds 
	inTextContainer: (NSTextContainer *)container;
- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
	inTextContainer: (NSTextContainer *)container;

- (unsigned int) glyphIndexForPoint: (NSPoint)aPoint
	inTextContainer: (NSTextContainer *)aTextContainer;
- (unsigned int) glyphIndexForPoint: (NSPoint)point
	inTextContainer: (NSTextContainer *)container
	fractionOfDistanceThroughGlyph: (float *)partialFraction;


@end


@interface NSLayoutManager (drawing)

-(void) drawBackgroundForGlyphRange: (NSRange)range
	atPoint: (NSPoint)containerOrigin;

-(void) drawGlyphsForGlyphRange: (NSRange)range
	atPoint: (NSPoint)containerOrigin;

/* TODO: underline */

@end


#endif

