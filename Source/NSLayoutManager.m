/*
   NSLayoutManager.m

   The text layout manager class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: July 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#include <AppKit/NSLayoutManager.h>

@implementation NSLayoutManager

- (id) init
{
  [super init];
  _backgroundLayout = YES;
  _delegate = nil;
  _textContainers = [[NSMutableArray alloc] initWithCapacity: 2];
  return self;
}

//
// Setting the text storage
//
- (void)setTextStorage: (NSTextStorage *)aTextStorage
{
  ASSIGN(_textStorage, aTextStorage);
}

- (NSTextStorage *)textStorage
{
  return _textStorage;
}

- (void)replaceTextStorage: (NSTextStorage *)newTextStorage
{
  NSArray *layoutManagers = [_textStorage layoutManagers];
  NSEnumerator *enumerator = [layoutManagers objectEnumerator];
  NSLayoutManager *object;

  // Remove layout managers from old NSTextStorage object and add them to the
  // new one.  NSTextStorage's addLayoutManager invokes NSLayoutManager's
  // setTextStorage method automatically, and that includes self.

  while( (object = (NSLayoutManager *)[enumerator nextObject]) )
  {
    [_textStorage removeLayoutManager: object];
    [newTextStorage addLayoutManager: object];
  }
}

//
// Setting text containers
//
- (NSArray *)textContainers
{
  return _textContainers;
}

- (void)addTextContainer: (NSTextContainer *)obj
{
  if( [_textContainers indexOfObjectIdenticalTo: obj] == NSNotFound )
  {
    [_textContainers addObject: obj];
    [obj setLayoutManager: self];
  }
}

- (void)insertTextContainer: (NSTextContainer *)aTextContainer
                    atIndex: (unsigned)index
{
  [_textContainers insertObject: aTextContainer atIndex: index];
}

- (void)removeTextContainerAtIndex: (unsigned)index
{
  [_textContainers removeObjectAtIndex: index];
}

//
// Invalidating glyphs and layout
//
- (void)invalidateGlyphsForCharacterRange: (NSRange)aRange
                           changeInLength: (int)lengthChange
                     actualCharacterRange: (NSRange *)actualRange
{
}

- (void)invalidateLayoutForCharacterRange: (NSRange)aRange
                                   isSoft: (BOOL)flag
                     actualCharacterRange: (NSRange *)actualRange
{
}

- (void)invalidateDisplayForCharacterRange: (NSRange)aRange
{
}

- (void)invalidateDisplayForGlyphRange: (NSRange)aRange
{
}

- (void)textContainerChangedGeometry: (NSTextContainer *)aContainer
{
}

- (void)textContainerChangedTextView: (NSTextContainer *)aContainer
{
}

- (void)textStorage: (NSTextStorage *)aTextStorage
             edited: (unsigned)mask
              range: (NSRange)range
     changeInLength: (int)lengthChange
   invalidatedRange: (NSRange)invalidatedRange
{
  NSDebugLLog(@"NSText",
    @"NSLayoutManager was just notified that a change in the text storage occured.");
}

//
// Turning on/off background layout
//

- (void)setBackgroundLayoutEnabled: (BOOL)flag
{
  _backgroundLayout = flag;
}

- (BOOL)backgroundLayoutEnabled
{
  return _backgroundLayout;
}

//
// Accessing glyphs
//
- (void)insertGlyph: (NSGlyph)aGlyph
       atGlyphIndex: (unsigned)glyphIndex
     characterIndex: (unsigned)charIndex
{
}

- (NSGlyph)glyphAtIndex: (unsigned)index
{
  return NSNullGlyph;
}

- (NSGlyph)glyphAtIndex: (unsigned)index
           isValidIndex: (BOOL *)flag
{
  *flag = NO;
  return NSNullGlyph;
}

- (void)replaceGlyphAtIndex: (unsigned)index
                  withGlyph: (NSGlyph)newGlyph
{
}

- (unsigned)getGlyphs: (NSGlyph *)glyphArray
                range: (NSRange)glyphRange
{
  return (unsigned)0;
}

- (void)deleteGlyphsInRange: (NSRange)aRange
{
}

- (unsigned)numberOfGlyphs
{
  return 0;
}

//
// Mapping characters to glyphs
//
- (void)setCharacterIndex: (unsigned)charIndex
          forGlyphAtIndex: (unsigned)glyphIndex
{
}

- (unsigned)characterIndexForGlyphAtIndex: (unsigned)glyphIndex
{
  return 0;
}

- (NSRange)characterRangeForGlyphRange: (NSRange)glyphRange
                      actualGlyphRange: (NSRange *)actualGlyphRange
{
  return NSMakeRange(0, 0);
}

- (NSRange)glyphRangeForCharacterRange: (NSRange)charRange
                  actualCharacterRange: (NSRange *)actualCharRange
{
  return NSMakeRange(0, 0);
}

//
// Setting glyph attributes 
//
- (void)setIntAttribute: (int)attribute
                  value: (int)anInt
        forGlyphAtIndex: (unsigned)glyphIndex
{
}

- (int)intAttribute: (int)attribute
    forGlyphAtIndex: (unsigned)glyphIndex
{
  return 0;
}

//
// Handling layout for text containers 
//
- (void)setTextContainer: (NSTextContainer *)aTextContainer
           forGlyphRange: (NSRange)glyphRange
{
}

- (NSRange)glyphRangeForTextContainer: (NSTextContainer *)aTextContainer
{
  NSSize tcSize = [aTextContainer containerSize];

  

  return NSMakeRange(0, 0);
}

- (NSTextContainer *)textContainerForGlyphAtIndex: (unsigned)glyphIndex
                                   effectiveRange: (NSRange *)effectiveRange
{
  return nil;
}

- (NSRect)usedRectForTextContainer: (NSTextContainer *)aTextContainer
{
  return NSZeroRect;
}

//
// Handling line fragment rectangles 
//
- (void)setLineFragmentRect: (NSRect)fragmentRect
              forGlyphRange: (NSRange)glyphRange
                   usedRect: (NSRect)usedRect
{
}

- (NSRect)lineFragmentRectForGlyphAtIndex: (unsigned)glyphIndex
                           effectiveRange: (NSRange *)lineFragmentRange
{
  return NSZeroRect;
}

- (NSRect)lineFragmentUsedRectForGlyphAtIndex: (unsigned)glyphIndex
                               effectiveRange: (NSRange *)lineFragmentRange
{
  return NSZeroRect;
}

- (void)setExtraLineFragmentRect: (NSRect)aRect
                        usedRect: (NSRect)usedRect
                   textContainer: (NSTextContainer *)aTextContainer
{
}

- (NSRect)extraLineFragmentRect 
{
  return NSZeroRect;
}

- (NSRect)extraLineFragmentUsedRect 
{
  return NSZeroRect;
}

- (NSTextContainer *)extraLineFragmentTextContainer 
{
  return nil;
}

- (void)setDrawsOutsideLineFragment: (BOOL)flag
                    forGlyphAtIndex: (unsigned)glyphIndex
{
}

- (BOOL)drawsOutsideLineFragmentForGlyphAtIndex: (unsigned)glyphIndex
{
  return NO;
}

//
// Layout of glyphs 
//
- (void)setLocation: (NSPoint)aPoint
        forStartOfGlyphRange: (NSRange)glyphRange
{
}

- (NSPoint)locationForGlyphAtIndex: (unsigned)glyphIndex
{
  return NSZeroPoint;
}

- (NSRange)rangeOfNominallySpacedGlyphsContainingIndex: (unsigned)glyphIndex
{
  return NSMakeRange(0, 0);
}

- (NSRect *)rectArrayForCharacterRange: (NSRange)charRange
          withinSelectedCharacterRange: (NSRange)selChareRange
                       inTextContainer: (NSTextContainer *)aTextContainer
                             rectCount: (unsigned *)rectCount
{
  return NULL;
}

- (NSRect *)rectArrayForGlyphRange: (NSRange)glyphRange
          withinSelectedGlyphRange: (NSRange)selectedGlyphRange
                   inTextContainer: (NSTextContainer *)aTextContainer
                         rectCount: (unsigned *)rectCount
{
  return NULL;
}

- (NSRect)boundingRectForGlyphRange: (NSRange)glyphRange
                    inTextContainer: (NSTextContainer *)aTextContainer
{
  return NSZeroRect;
}

- (NSRange)glyphRangeForBoundingRect: (NSRect)aRect
                     inTextContainer: (NSTextContainer *)aTextContainer
{
  return NSMakeRange(0, 0);
}

- (NSRange)glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
                           inTextContainer: (NSTextContainer *)aTextContainer
{
  return NSMakeRange(0, 0);
}

- (unsigned)glyphIndexForPoint: (NSPoint)aPoint
               inTextContainer: (NSTextContainer *)aTextContainer
fractionOfDistanceThroughGlyph: (float *)partialFraction
{
  return 0;
}

//
// Display of special glyphs 
//
- (void)setNotShownAttribute: (BOOL)flag
             forGlyphAtIndex: (unsigned)glyphIndex
{
}

- (BOOL)notShownAttributeForGlyphAtIndex: (unsigned)glyphIndex
{
  return YES;
}

- (void)setShowsInvisibleCharacters: (BOOL)flag
{
  _showsInvisibleChars = flag;
}

- (BOOL)showsInvisibleCharacters 
{
  return _showsInvisibleChars;
}

- (void)setShowsControlCharacters: (BOOL)flag
{
  _showsControlChars = flag;
}

- (BOOL)showsControlCharacters
{
  return _showsControlChars;
}

//
// Controlling hyphenation 
//
- (void)setHyphenationFactor: (float)factor
{
  _hyphenationFactor = factor;
}

- (float)hyphenationFactor
{
  return _hyphenationFactor;
}

//
// Finding unlaid characters/glyphs 
//
- (void)getFirstUnlaidCharacterIndex: (unsigned *)charIndex
                          glyphIndex: (unsigned *)glyphIndex
{
}

//
// Using screen fonts 
//
- (void)setUsesScreenFonts: (BOOL)flag
{
  _usesScreenFonts = flag;
}

- (BOOL)usesScreenFonts 
{
  return _usesScreenFonts;
}

- (NSFont *)substituteFontForFont: (NSFont *)originalFont
{
  return originalFont;
}

//
// Handling rulers 
//
- (NSView *)rulerAccessoryViewForTextView: (NSTextView *)aTextView
                           paragraphStyle: (NSParagraphStyle *)paragraphStyle
                                    ruler: (NSRulerView *)aRulerView
                                  enabled: (BOOL)flag
{
  return NULL;
}

- (NSArray *)rulerMarkersForTextView: (NSTextView *)aTextView
                      paragraphStyle: (NSParagraphStyle *)paragraphStyle
                               ruler: (NSRulerView *)aRulerView
{
  return NULL;
}

//
// Managing the responder chain 
//
- (BOOL)layoutManagerOwnsFirstResponderInWindow: (NSWindow *)aWindow
{
  return NO;
}

- (NSTextView *)firstTextView 
{
  return NULL;
}

- (NSTextView *)textViewForBeginningOfSelection
{
  return NULL;
}

//
// Drawing 
//
- (void)drawBackgroundForGlyphRange: (NSRange)glyphRange
                            atPoint: (NSPoint)containerOrigin
{
}

- (void)drawGlyphsForGlyphRange: (NSRange)glyphRange
                        atPoint: (NSPoint)containerOrigin
{
}

- (void)drawUnderlineForGlyphRange: (NSRange)glyphRange
                     underlineType: (int)underlineType
                    baselineOffset: (float)baselineOffset
                  lineFragmentRect: (NSRect)lineRect
            lineFragmentGlyphRange: (NSRange)lineGlyphRange
                   containerOrigin: (NSPoint)containerOrigin
{
}

- (void)underlineGlyphRange: (NSRange)glyphRange
              underlineType: (int)underlineType
           lineFragmentRect: (NSRect)lineRect
     lineFragmentGlyphRange: (NSRange)lineGlyphRange
            containerOrigin: (NSPoint)containerOrigin
{
}

//
// Setting the delegate 
//
- (void)setDelegate: (id)aDelegate
{
  _delegate = aDelegate;
}

- (id)delegate
{
  return _delegate;
}

@end /* NSLayoutManager */
