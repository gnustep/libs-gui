/*                                                       -*-objc-*-
   NSLayoutManager.h

     An NSLayoutManager stores glyphs, attributes, and layout information 
     generated from a NSTextStorage by a NSTextLayout.  It can map between 
     ranges of unichars in the NSTextStorage and ranges of glyphs within 
     itself.  It understands and keeps track of two types of range 
     invalidation.  A character range can need glyphs generated for it or 
     it can need its glyphs laid out.  

     When a NSLayoutManager is asked for information which would require 
     knowledge of glyphs or layout which is not currently available, the 
     NSLayoutManager must cause the appropriate recalculation to be done.

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#ifndef _GNUstep_H_NSLAYOUTMANAGER
#define _GNUstep_H_NSLAYOUTMANAGER

#include <Foundation/Foundation.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>

@class NSTypesetter;
@class NSTextView;
@class NSWindow;
@class NSRulerView;
@class NSParagraphStyle;
@class NSView;

// These are unclear:
@class NSGlyphGenerator;
@class NSStorage;
// Michael's botch list. :-)
@class GSRunStorage;

/*
  These glyph attributes are used only inside the glyph generation machinery, 
  but must be shared between componenets.
*/
enum _NSGlyphAttribute {
  NSGlyphAttributeSoft = 0,
  NSGlyphAttributeElastic = 1,
  NSGlyphAttributeInscribe = 5,
};

/*
  The inscribe attribute of a glyph determines how it is laid out relative to 
  the previous glyph.
*/
typedef enum {
  NSGlyphInscribeBase = 0,
  NSGlyphInscribeBelow = 1,
  NSGlyphInscribeAbove = 2,
  NSGlyphInscribeOverstrike = 3,
  NSGlyphInscribeOverBelow = 4
} NSGlyphInscription;

@interface NSLayoutManager : NSObject
{
  /* Public for use only in the associated NSTextViews.  Don't access
     them directly from elsewhere. */
@public 
  /* Ivars to synchronize multiple textviews */
  BOOL _isSynchronizingFlags;
  BOOL _isSynchronizingDelegates;
  BOOL _beganEditing;
  
@protected
  NSMutableArray *_textContainers;
  NSTextStorage	 *_textStorage;

  /* NB: if _textContainersCount == 1, then _firstTextView == our only
     text view. */
  /* Cached - number of text containers: */
  unsigned        _textContainersCount; 
  /* Cached -  first text view: */
  NSTextView	 *_firstTextView;

  id              _delegate;

  /* TODO: Tidyup the following ivars, remove useless ones */
  BOOL			_backgroundLayout;
  BOOL			_showsInvisibleChars;
  BOOL			_showsControlChars;
  BOOL			_usesScreenFonts;
  BOOL			_finished;
  float			_hyphenationFactor;
  NSTypesetter		*_typesetter;

  void			*_glyphData;	// Private glyph storage.
  void			*_currentGlyphs;	
  void			*_glyphGaps;	// Gaps in character mapping.
  unsigned		_chunkIndex;
  unsigned		_glyphIndex;
  unsigned		_endCharIndex;	// After last char with generated glyph.
  
  NSGlyphGenerator		*_glyphGenerator;
  NSStorage			*_containerUsedRects;
  
  
  // GS data storage.
  GSRunStorage *_containerRuns;
  GSRunStorage *_fragmentRuns;
  GSRunStorage *_locationRuns;
  
  NSRect 			 _extraLineFragmentRect;
  NSRect 			 _extraLineFragmentUsedRect;
  NSTextContainer		*_extraLineFragmentContainer;
  

  
  // Enable/disable stacks
  unsigned short		_textViewResizeDisableStack;
  unsigned short		_displayInvalidationDisableStack;
  NSRange			_deferredDisplayCharRange;
  
  
  // Cache for rectangle arrays (Cost: 8 bytes + malloced 16 * <max number of rects returned in an array> bytes)
  NSRect			*_cachedRectArray;
  unsigned			 _cachedRectArrayCapacity;
  
  // Cache for glyph strings (used when drawing) (Cost: 8 bytes + malloced glyph buffer size)
  char				*_glyphBuffer;
  unsigned 			 _glyphBufferSize;
  
  // Cache for faster glyph location lookup (Cost: 20 bytes)
  NSRange			_cachedLocationNominalGlyphRange;
  unsigned			_cachedLocationGlyphIndex;
  NSPoint			_cachedLocation;
  
  // Cache for faster glyph location lookup (Cost: 12 bytes)
  NSRange			 _cachedFontCharRange;
  NSFont			*_cachedFont;
  
  // Cache for first unlaid glypha and character (Cost: 8 bytes)
  unsigned			_firstUnlaidGlyphIndex;
  unsigned			_firstUnlaidCharIndex;
  
  NSRange			 _newlyFilledGlyphRange;
}

/**************************** Initialization ****************************/

- (id) init;

/*************************** Helper objects ***************************/

- (NSTextStorage *) textStorage;
- (void) setTextStorage: (NSTextStorage *)textStorage;

- (void) replaceTextStorage: (NSTextStorage *)newTextStorage;

- (id) delegate;
- (void) setDelegate: (id)delegate;

/**************************** Containers ****************************/

- (NSArray *) textContainers;

-(void) addTextContainer: (NSTextContainer *)container;
- (void) insertTextContainer: (NSTextContainer *)container 
		     atIndex: (unsigned)index;
- (void) removeTextContainerAtIndex: (unsigned)index;

- (void) textContainerChangedGeometry: (NSTextContainer *)container;
- (void) textContainerChangedTextView: (NSTextContainer *)container;

/************************** Invalidation primitives **************************/

- (void) invalidateGlyphsForCharacterRange: (NSRange)charRange 
			    changeInLength: (int)delta 
		      actualCharacterRange: (NSRange *)actualCharRange;
- (void) invalidateLayoutForCharacterRange: (NSRange)charRange 
				    isSoft: (BOOL)flag 
		      actualCharacterRange: (NSRange *)actualCharRange;

- (void) invalidateDisplayForGlyphRange: (NSRange)glyphRange;
#ifndef STRICT_40
- (void) invalidateDisplayForCharacterRange: (NSRange)charRange;
#endif

/******************* Invalidation sent by NSTextStorage *******************/

- (void) textStorage: (NSTextStorage *)aTextStorage
	      edited: (unsigned)mask
	       range: (NSRange)range
      changeInLength: (int)lengthChange
    invalidatedRange: (NSRange)invalidatedRange;


/*********************** Global layout manager options ***********************/

- (void) setBackgroundLayoutEnabled: (BOOL)flag;
- (BOOL) backgroundLayoutEnabled;

- (void) setShowsInvisibleCharacters: (BOOL)flag;
- (BOOL) showsInvisibleCharacters;

- (void) setShowsControlCharacters: (BOOL)flag;
- (BOOL) showsControlCharacters;

/************************ Adding and removing glyphs ************************/

- (void) insertGlyph: (NSGlyph)glyph   atGlyphIndex: (unsigned)glyphIndex 
      characterIndex: (unsigned)charIndex;

- (void) replaceGlyphAtIndex: (unsigned)glyphIndex 
		   withGlyph: (NSGlyph)newGlyph;

- (void) deleteGlyphsInRange: (NSRange)glyphRange;

- (void) setCharacterIndex: (unsigned)charIndex 
	   forGlyphAtIndex: (unsigned)glyphIndex;

/************************ Accessing glyphs ************************/

- (unsigned) numberOfGlyphs;

- (NSGlyph) glyphAtIndex: (unsigned)glyphIndex;

- (NSGlyph) glyphAtIndex: (unsigned)glyphIndex 
	    isValidIndex: (BOOL *)isValidIndex;

- (unsigned) getGlyphs: (NSGlyph *)glyphArray  range: (NSRange)glyphRange;

- (unsigned) characterIndexForGlyphAtIndex: (unsigned)glyphIndex;

/************************ Set/Get glyph attributes ************************/

- (void) setIntAttribute: (int)attributeTag 
		   value: (int)val 
	 forGlyphAtIndex: (unsigned)glyphIndex;

- (int) intAttribute: (int)attributeTag  
     forGlyphAtIndex: (unsigned)glyphIndex;

- (void) setAttachmentSize: (NSSize)attachmentSize 
	     forGlyphRange: (NSRange)glyphRange;

/************************ Set/Get layout attributes ************************/

- (void) setTextContainer: (NSTextContainer *)container 
	    forGlyphRange: (NSRange)glyphRange;

- (void) setLineFragmentRect: (NSRect)fragmentRect 
	       forGlyphRange: (NSRange)glyphRange 
		    usedRect: (NSRect)usedRect;

- (void) setExtraLineFragmentRect: (NSRect)fragmentRect 
			 usedRect: (NSRect)usedRect 
		    textContainer: (NSTextContainer *)container;

- (void) setDrawsOutsideLineFragment: (BOOL)flag 
		     forGlyphAtIndex: (unsigned)glyphIndex;

- (void) setLocation: (NSPoint)location 
forStartOfGlyphRange: (NSRange)glyphRange;

- (void) setNotShownAttribute: (BOOL)flag 
	      forGlyphAtIndex: (unsigned)glyphIndex;

- (NSTextContainer *) textContainerForGlyphAtIndex: (unsigned)glyphIndex 
				    effectiveRange: (NSRange *)effectiveGlyphRange;

- (NSRect) usedRectForTextContainer: (NSTextContainer *)container;

- (NSRect) lineFragmentRectForGlyphAtIndex: (unsigned)glyphIndex 
			    effectiveRange: (NSRange *)effectiveGlyphRange;

- (NSRect) lineFragmentUsedRectForGlyphAtIndex: (unsigned)glyphIndex 
				effectiveRange: (NSRange *)effectiveGlyphRange;

- (NSRect) extraLineFragmentRect;

- (NSRect) extraLineFragmentUsedRect;

- (NSTextContainer *) extraLineFragmentTextContainer;

- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex: (unsigned) glyphIndex;

- (NSPoint) locationForGlyphAtIndex: (unsigned)glyphIndex;

- (BOOL) notShownAttributeForGlyphAtIndex: (unsigned) glyphIndex;

/************************ More sophisticated queries ************************/

- (NSRange) glyphRangeForCharacterRange: (NSRange)charRange 
		   actualCharacterRange: (NSRange *)actualCharRange;

- (NSRange) characterRangeForGlyphRange: (NSRange)glyphRange 
		       actualGlyphRange: (NSRange *)actualGlyphRange;

- (NSRange) glyphRangeForTextContainer: (NSTextContainer *)container;

- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(unsigned)glyphIndex;

- (NSRect *) rectArrayForCharacterRange: (NSRange)charRange 
	   withinSelectedCharacterRange: (NSRange)selCharRange 
			inTextContainer: (NSTextContainer *)container 
			      rectCount: (unsigned *)rectCount;

- (NSRect *) rectArrayForGlyphRange: (NSRange)glyphRange 
	   withinSelectedGlyphRange: (NSRange)selGlyphRange 
		    inTextContainer: (NSTextContainer *)container 
			  rectCount: (unsigned *)rectCount;

- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange 
		     inTextContainer: (NSTextContainer *)container;

- (NSRange) glyphRangeForBoundingRect: (NSRect)bounds 
		      inTextContainer: (NSTextContainer *)container;

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds 
					     inTextContainer: (NSTextContainer *)container;

- (unsigned) glyphIndexForPoint: (NSPoint)aPoint 
		inTextContainer: (NSTextContainer *)aTextContainer;

- (unsigned) glyphIndexForPoint: (NSPoint)point 
		inTextContainer: (NSTextContainer *)container 
 fractionOfDistanceThroughGlyph: (float *)partialFraction;

- (unsigned) firstUnlaidCharacterIndex;

- (unsigned) firstUnlaidGlyphIndex;

- (void) getFirstUnlaidCharacterIndex: (unsigned *)charIndex 
			  glyphIndex: (unsigned *)glyphIndex;

/************************ Screen font usage control ************************/

- (BOOL) usesScreenFonts;

- (void) setUsesScreenFonts: (BOOL)flag;

- (NSFont *) substituteFontForFont: (NSFont *)originalFont;

@end

@interface NSLayoutManager (NSTextViewSupport)

/************************ Ruler stuff ************************/

- (NSArray *) rulerMarkersForTextView: (NSTextView *)view 
		       paragraphStyle: (NSParagraphStyle *)style 
				ruler: (NSRulerView *)ruler;

- (NSView *) rulerAccessoryViewForTextView: (NSTextView *)view 
			    paragraphStyle: (NSParagraphStyle *)style 
				     ruler: (NSRulerView *)ruler 
				   enabled: (BOOL)isEnabled;

/************************ First responder support ************************/

- (BOOL) layoutManagerOwnsFirstResponderInWindow: (NSWindow *)window;

- (NSTextView *) firstTextView;

- (NSTextView *) textViewForBeginningOfSelection;

/************************ Drawing support ************************/

- (void) drawBackgroundForGlyphRange: (NSRange)glyphsToShow 
			     atPoint: (NSPoint)origin;

- (void) drawGlyphsForGlyphRange: (NSRange)glyphsToShow 
			 atPoint: (NSPoint)origin;

- (void) drawUnderlineForGlyphRange: (NSRange)glyphRange 
		      underlineType: (int)underlineVal 
		     baselineOffset: (float)baselineOffset 
		   lineFragmentRect: (NSRect)lineRect 
	     lineFragmentGlyphRange: (NSRange)lineGlyphRange 
		    containerOrigin: (NSPoint)containerOrigin;

- (void) underlineGlyphRange: (NSRange)glyphRange 
	       underlineType: (int)underlineVal 
	    lineFragmentRect: (NSRect)lineRect 
      lineFragmentGlyphRange: (NSRange)lineGlyphRange 
	     containerOrigin: (NSPoint)containerOrigin;

/************************ Hyphenation support ************************/

- (float) hyphenationFactor;

- (void) setHyphenationFactor: (float)factor;

- (unsigned) _charIndexForInsertionPointMovingFromY: (float)position
					      bestX: (float)wanted
						 up: (BOOL)upFlag
				      textContainer: (NSTextContainer *)tc;
@end

@interface NSObject (NSLayoutManagerDelegate)

- (void) layoutManagerDidInvalidateLayout: (NSLayoutManager *)sender;
// This is sent whenever layout or glyphs become invalidated in a 
// layout manager which previously had all layout complete.

- (void) layoutManager: (NSLayoutManager *)layoutManager 
didCompleteLayoutForTextContainer: (NSTextContainer *)textContainer 
atEnd: (BOOL)layoutFinishedFlag;
// This is sent whenever a container has been filled. 
// This method can be useful for paginating.  The textContainer might
// be nil if we have completed all layout and not all of it fit into
// the existing containers.  atEnd indicates whether all layout is complete.

@end

#endif // _GNUstep_H_NSLAYOUTMANAGER
