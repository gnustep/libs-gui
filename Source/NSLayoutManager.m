/*
   NSLayoutManager.m

   The text layout manager class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: July 1999
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: August 1999

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

// _GSRunSearchKey is an internal class which serves as the foundation for
// all our searching. This may not be an elegant way to go about this, so
// if someone wants to optimize this out, please do.

@interface _GSRunSearchKey : NSObject
{
@public
  NSRange glyphRange;
}
@end

@implementation _GSRunSearchKey
- (id)init
{
  return [super init];
}

- (void) dealloc
{
  [super dealloc];
}
@end

@interface GSGlyphLocation : _GSRunSearchKey
{
@public
  NSPoint point;
}
@end

@implementation GSGlyphLocation
- (id)init
{
  return [super init];
}

- (void) dealloc
{
  [super dealloc];
}
@end

@interface GSLineLayoutInfo : _GSRunSearchKey
{
@public
  NSRect lineFragmentRect;
  NSRect usedRect;
}
@end

@implementation GSLineLayoutInfo
- (id)init
{
  return [super init];
}

- (void) dealloc
{
  [super dealloc];
}
@end

@interface GSTextContainerLayoutInfo : _GSRunSearchKey
{
@public
  NSTextContainer *textContainer;
  NSString *testString;
}
@end

@implementation GSTextContainerLayoutInfo
- (id)init
{
  return [super init];
}

- (void) dealloc
{
  [super dealloc];
}
@end

#define GSI_ARRAY_TYPES       GSUNION_OBJ

#ifdef GSIArray
#undef GSIArray
#endif
#include <base/GSIArray.h>

static NSComparisonResult aSort(GSIArrayItem i0, GSIArrayItem i1)
{
  if (((_GSRunSearchKey *)(i0.obj))->glyphRange.location
    < ((_GSRunSearchKey *)(i1.obj))->glyphRange.location)
    return NSOrderedAscending;
  else if (((_GSRunSearchKey *)(i0.obj))->glyphRange.location
    >= NSMaxRange(((_GSRunSearchKey *)(i1.obj))->glyphRange))
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

@interface GSRunStorage : NSObject
{
  unsigned int _count;
  void *_runs;
}
- (void)insertObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(unsigned)theIndex;
- (id)objectAtIndex:(unsigned)theIndex;
- (unsigned)indexOfObject:(id)anObject;
- (unsigned)indexOfObjectContainingLocation:(unsigned)aLocation;
- (id)objectContainingLocation:(unsigned)aLocation;
- (int)count;
@end

@implementation GSRunStorage
- (id)init
{
  NSZone *z;

  [super init];

  z = [self zone];

  _runs = NSZoneMalloc(z, sizeof(GSIArray_t));
  GSIArrayInitWithZoneAndCapacity((GSIArray)_runs, z, 8);

  return self;
}

- (void)insertObject:(id)anObject
{
  _GSRunSearchKey *aKey = [_GSRunSearchKey new];
  _GSRunSearchKey *aObject = (_GSRunSearchKey *)anObject;
  int position;

  aKey->glyphRange.location = aObject->glyphRange.location;

  position = GSIArrayInsertionPosition(_runs, (GSIArrayItem)aKey, aSort);

  NSLog(@"key: %d aObject: %d position: %d", aKey->glyphRange.location,
aObject->glyphRange.location, position);

  if (position > 0)
    {
      _GSRunSearchKey *anKey = GSIArrayItemAtIndex(_runs, (unsigned)position - 1).obj;

      if (anKey->glyphRange.location == aObject->glyphRange.location)
        {
//          GSIArrayInsertSorted(_runs, (GSIArrayItem)anObject, aSort);
	  NSLog(@"=========> duplicated item.");
	  GSIArraySetItemAtIndex(_runs, (GSIArrayItem)anObject, position-1);
        }
      else
	{
	  NSLog(@"=========> not duplicated item.");
	  GSIArrayInsertItem(_runs, (GSIArrayItem)anObject, position);
	}
    }
  else if (position == 0)
    {
	NSLog(@"=========> first item (zero index).");
	GSIArrayInsertItem(_runs, (GSIArrayItem)anObject, position);
//      GSIArrayInsertSorted(_runs, (GSIArrayItem)anObject, aSort);
//      [self insertObject:anObject atIndex:position];
    }
  else
    NSLog(@"dead. VERY DEAD DEAD DEAD DEAD.");

  NSLog(@"==> %d item(s)", GSIArrayCount(_runs));
}

- (void)insertObject:(id)anObject
	     atIndex:(unsigned)theIndex
{
  NSLog(@"insertObject:atIndex: called. %d item(s)", GSIArrayCount(_runs));
  GSIArrayInsertSorted(_runs, (GSIArrayItem)anObject, aSort);
//  GSIArrayInsertItem(_runs, (GSIArrayItem)anObject, theIndex);
  NSLog(@"insertObject:atIndex: ended. %d item(s)", GSIArrayCount(_runs));
}

- (void)removeObjectAtIndex:(int)theIndex
{
  GSIArrayRemoveItemAtIndex(_runs, theIndex);
}

- (id)objectAtIndex:(unsigned)theIndex
{
  return GSIArrayItemAtIndex(_runs, (unsigned)theIndex).obj;
}

- (unsigned)indexOfObject:(id)anObject
{
  return NSNotFound;
}

- (unsigned)indexOfObjectContainingLocation:(unsigned)aLocation
{
  _GSRunSearchKey *aKey = [_GSRunSearchKey new];
  int position;

  aKey->glyphRange.location = aLocation;

  position = GSIArrayInsertionPosition(_runs, (GSIArrayItem)aKey, aSort);

  if (position >= 0 && position - 1 >= 0)
    {
      aKey = GSIArrayItemAtIndex(_runs, (unsigned)position - 1).obj;

      if (NSLocationInRange(aLocation, aKey->glyphRange))
        {
	  return (position - 1);
        }
    }

  return -1;
}

- (id)objectContainingLocation:(unsigned)aLocation
{
  _GSRunSearchKey *aKey = [_GSRunSearchKey new];
  int position;

  aKey->glyphRange.location = aLocation;

  position = GSIArrayInsertionPosition(_runs, (GSIArrayItem)aKey, aSort);

  if (position >= 0 && position - 1 >= 0)
    {
      aKey = GSIArrayItemAtIndex(_runs, (unsigned)position - 1).obj;

      if (NSLocationInRange(aLocation, aKey->glyphRange))
        {
	  return aKey;
        }
    }

  return nil;  
}

- (id)lastObject
{
  return GSIArrayItemAtIndex(_runs, GSIArrayCount(_runs) - 1).obj;
}

- (int)count
{
  return GSIArrayCount(_runs);
}
@end

@implementation NSLayoutManager

- (id) init
{
  [super init];

  _backgroundLayout = YES;
  _delegate = nil;
  _textContainers = [[NSMutableArray alloc] initWithCapacity: 2];

  containerRuns = [GSRunStorage new];
  fragmentRuns = [GSRunStorage new];
  locationRuns = [GSRunStorage new];

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
  NSLog(@"NSLayoutManager was just notified that a change in the text
storage occured.");

/*
  if (mask == NSTextStorageEditedCharacters)
    {
      aLayoutHole = [[NSLayoutHole alloc]
initWithCharacterRange:invalidatedRange isSoft:NO];
    }
  else if (mask == NSTextStorageEditedAttributes)
    {
    }
  else if (mask == NSTextStorageEditedCharacters | NSTextStorageEditedAttributes)
    {
    }
*/
  // invalidation should occure here.

  [self _doLayout];
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

// Each NSGlyph has an attribute field, yes?

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
  GSTextContainerLayoutInfo *theLine = [GSTextContainerLayoutInfo new];

  theLine->glyphRange = glyphRange;
  ASSIGN(theLine->textContainer, aTextContainer);
  
  [containerRuns insertObject:theLine];
}

- (NSRange)glyphRangeForTextContainer: (NSTextContainer *)aTextContainer
{
  int i;

  NSLog(@"glyphRangeForTextContainer: called. There are %d
textContainer(s) in containerRuns.", [containerRuns count]);

  for (i=0;i<[containerRuns count];i++)
    {
      GSTextContainerLayoutInfo *aNewLine = [containerRuns objectAtIndex:i];

      NSLog(@"glyphRangeForTextContainer: (%d, %d)",
aNewLine->glyphRange.location,
aNewLine->glyphRange.length);

      if ([aNewLine->textContainer isEqual:aTextContainer])
        {
	  NSLog(@"glyphRangeForWantedTextContainer: (%d, %d)",
aNewLine->glyphRange.location,
aNewLine->glyphRange.length);

	  return aNewLine->glyphRange;
        }
    }

  return NSMakeRange(NSNotFound, 0);
}

- (NSTextContainer *)textContainerForGlyphAtIndex: (unsigned)glyphIndex
                                   effectiveRange: (NSRange *)effectiveRange
{
  GSTextContainerLayoutInfo *theLine = [containerRuns objectContainingLocation:glyphIndex];

  if(theLine)
    {
      (NSRange *)effectiveRange = &theLine->glyphRange;
      return theLine->textContainer;
    }

  (NSRange *)effectiveRange = NULL;
  return nil;
}

//
// Handling line fragment rectangles 
//
- (void)setLineFragmentRect: (NSRect)fragmentRect
              forGlyphRange: (NSRange)glyphRange
                   usedRect: (NSRect)usedRect
{
  GSLineLayoutInfo *aNewLine = [GSLineLayoutInfo new];

  aNewLine->glyphRange = glyphRange;
  aNewLine->lineFragmentRect = fragmentRect;
  aNewLine->usedRect = usedRect;

  [fragmentRuns insertObject:aNewLine];
}

- (NSRect)lineFragmentRectForGlyphAtIndex: (unsigned)glyphIndex
                           effectiveRange: (NSRange *)lineFragmentRange
{
  GSLineLayoutInfo *theLine = [fragmentRuns objectContainingLocation:glyphIndex];

  if (theLine)
    {
      (NSRange *)lineFragmentRange = &theLine->glyphRange;
      return theLine->lineFragmentRect;
    }

  (NSRange *)lineFragmentRange = NULL;
  return NSZeroRect;
}

- (NSRect)lineFragmentUsedRectForGlyphAtIndex: (unsigned)glyphIndex
                               effectiveRange: (NSRange *)lineFragmentRange
{
  GSLineLayoutInfo *theLine = [fragmentRuns objectContainingLocation:glyphIndex];

  if (theLine)
    {
      (NSRange *)lineFragmentRange = &theLine->glyphRange;
      return theLine->usedRect;
    }

  (NSRange *)lineFragmentRange = NULL;
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
  GSGlyphLocation *aNewLine = [GSGlyphLocation new];

  aNewLine->glyphRange = glyphRange;
  aNewLine->point = aPoint;

  [locationRuns insertObject:aNewLine];
}

- (NSPoint)locationForGlyphAtIndex: (unsigned)glyphIndex
{
  return NSZeroPoint;
}

- (NSRange)rangeOfNominallySpacedGlyphsContainingIndex: (unsigned)glyphIndex
{
  GSLineLayoutInfo *theLine = [locationRuns objectContainingLocation:glyphIndex];

  if (theLine)
    {
      return theLine->glyphRange;
    }

  return NSMakeRange(NSNotFound, 0);
}

- (NSRect *)rectArrayForCharacterRange: (NSRange)charRange
          withinSelectedCharacterRange: (NSRange)selChareRange
                       inTextContainer: (NSTextContainer *)aTextContainer
                             rectCount: (unsigned *)rectCount
{
/*
  GSLineLayoutInfo *theLine = [GSLineLayoutInfo new];
  int position, lastPosition;
  int i, j = 0;

  theLine->glyphRange.location = charRange.location;

  position = GSIArrayInsertionPosition(lineFragments, (GSIArrayItem)theLine, aSort);

  if (position < 0)
    {
      return NULL;
    }

  theLine->glyphRange.location = charRange.location + charRange.length;

  lastPosition = GSIArrayInsertionPosition(lineFragments, (GSIArrayItem)theLine, aSort);

  if (lastPosition > 0)
    {
      _cachedRectArray = NSZoneRealloc([self zone], _cachedRectArray,
				(lastPosition - position) * sizeof(NSRect));

      _cachedRectArrayCapacity = lastPosition - position;

      for (i = position - 1; i < lastPosition - 1; i++)
        {
          GSLineLayoutInfo *aLine = GSIArrayItemAtIndex(lineFragments, i).obj;

	  _cachedRectArray[j] = aLine->lineFragmentRect;
	  j++;
        }
    }

  (*rectCount) = (position - 1 + lastPosition - 1);
  return _cachedRectArray;
*/
}

- (NSRect *)rectArrayForGlyphRange: (NSRange)glyphRange
          withinSelectedGlyphRange: (NSRange)selectedGlyphRange
                   inTextContainer: (NSTextContainer *)aTextContainer
                         rectCount: (unsigned *)rectCount
{
  return _cachedRectArray;
}

- (NSRect)boundingRectForGlyphRange: (NSRange)glyphRange
                    inTextContainer: (NSTextContainer *)aTextContainer
{

/* Returns a single bounding rectangle enclosing all glyphs and other
marks drawn in aTextContainer for glyphRange, including glyphs that draw
outside their line fragment rectangles and text attributes such as
underlining. This method is useful for determining the area that needs to
be redrawn when a range of glyphs changes. */
/*
  unsigned rectCount;
  NSRect *rects = [self rectArrayForCharacterRange: [self glyphRangeForTextContainer:aTextContainer]
		      withinSelectedCharacterRange: NSMakeRange(0,0)
				   inTextContainer: aTextContainer
					 rectCount: &rectCount];
//  NSPoint aOrigin = [aTextContainer originPoint];
  NSRect rRect = NSZeroRect;
  int i;

  for (i=0;i<rectCount;i++)
    {
      NSRect aRect = rects[i];

      if (aRect.origin.y == rRect.size.height)
        rRect.size.height += aRect.size.width;

      if (rRect.size.width == aRect.origin.x)
        rRect.size.width += aRect.size.width;
    }

  return rRect;
*/
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

- (unsigned int)firstUnlaidCharacterIndex
{
  return 0;
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
  int firstPosition, lastPosition, i;

  for (i=0;i<[fragmentRuns count];i++)
    {
      GSLineLayoutInfo *info = [fragmentRuns objectAtIndex:i];

/*
      NSLog(@"i: %d glyphRange: (%d, %d) lineFragmentRect: (%f, %f) (%f, %f)",
i,
info->glyphRange.location,
info->glyphRange.length,
info->lineFragmentRect.origin.x,  
info->lineFragmentRect.origin.y,    
info->lineFragmentRect.size.width,  
info->lineFragmentRect.size.height);
*/
    }

  firstPosition = [fragmentRuns indexOfObjectContainingLocation:glyphRange.location];
  lastPosition = [fragmentRuns 
indexOfObjectContainingLocation:(glyphRange.location+glyphRange.length-2)];

  NSLog(@"glyphRange: (%d, %d) position1: %d position2: %d",
glyphRange.location, glyphRange.length, firstPosition, lastPosition);

  if (firstPosition >= 0)
    {
      if (lastPosition == -1)
        {
          lastPosition = [fragmentRuns count]; // FIXME
	  NSLog(@"fixed lastPosition: %d", lastPosition);
        }

      for (i = firstPosition; i < lastPosition; i++)
        {
	  GSLineLayoutInfo *aLine = [fragmentRuns objectAtIndex:i];
/*
NSLog(@"drawRange: (%d, %d) inRect (%f, %f) (%f, %f)",
aLine->glyphRange.location,
aLine->glyphRange.length,
aLine->lineFragmentRect.origin.x,
aLine->lineFragmentRect.origin.y,
aLine->lineFragmentRect.size.width,
aLine->lineFragmentRect.size.height);
*/
	  [_textStorage drawRange:aLine->glyphRange inRect:aLine->lineFragmentRect];
        }
    }
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

/* Thew methods laid out here are not correct, however the code they
contain for the most part is. Therefore, my country and a handsome gift of
Ghiradelli chocolate to he who puts all the pieces together :) */

@interface _GNUTextScanner:NSObject
{       NSString           *string;
        NSCharacterSet *set,*iSet;
        unsigned                stringLength;
        NSRange                 activeRange;
}
+(_GNUTextScanner*) scannerWithString:(NSString*) aStr set:(NSCharacterSet*) aSet invertedSet:(NSCharacterSet*) anInvSet;
-(void)                         setString:(NSString*) aString set:(NSCharacterSet*) aSet invertedSet:(NSCharacterSet*) anInvSet;
-(NSRange)                      _scanCharactersInverted:(BOOL) inverted;
-(NSRange)                      scanSetCharacters;
-(NSRange)                      scanNonSetCharacters;
-(BOOL)                         isAtEnd;
-(unsigned)                     scanLocation;
-(void)                         setScanLocation:(unsigned) aLoc;
@end

@implementation NSLayoutManager (Private)
- (int)_rebuildLayoutForTextContainer:(NSTextContainer *)aContainer
		  startingAtGlyphIndex:(int)glyphIndex
{
  NSSize cSize = [aContainer containerSize];
  float i = 0.0;
  NSMutableArray *lines = [NSMutableArray new];
  int indexToAdd;
  _GNUTextScanner *lineScanner;
  _GNUTextScanner *paragraphScanner;
  BOOL lastLineForContainerReached = NO;
  NSString *aString;
  int previousScanLocation;
  int endScanLocation;
  int startIndex;
  NSRect firstProposedRect;
  NSRect secondProposedRect;
  NSFont *default_font = [NSFont systemFontOfSize: 12.0];
  int widthOfString;
  NSSize rSize;
  NSCharacterSet *selectionParagraphGranularitySet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
  NSCharacterSet *selectionWordGranularitySet = [NSCharacterSet characterSetWithCharactersInString:@" "];
  NSCharacterSet *invSelectionWordGranularitySet = [selectionWordGranularitySet invertedSet];
  NSCharacterSet *invSelectionParagraphGranularitySet = [selectionParagraphGranularitySet invertedSet];
  NSRange paragraphRange;
  NSRange leadingSpacesRange;
  NSRange currentStringRange;
  NSRange trailingSpacesRange;
  NSRange leadingNlRange;
  NSSize lSize;
  float lineWidth = 0.0;
  float ourLines = 0.0;

  NSLog(@"rebuilding Layout at index: %d.\n", glyphIndex);

  // 1.) figure out how many glyphs we can fit in our container by
  // breaking up glyphs from the first unlaid out glyph and breaking it
  // into lines.
  //
  // 2.) 
  //     a.) set the range for the container
  //     b.) for each line in step 1 we need to set a lineFragmentRect and
  //         an origin point.


  // Here we go at part 1.

  startIndex = glyphIndex;

//  lineScanner = [NSScanner scannerWithString:[_textStorage string]];

  paragraphScanner = [_GNUTextScanner scannerWithString:[_textStorage string] 
			set:selectionParagraphGranularitySet invertedSet:invSelectionParagraphGranularitySet];

  [paragraphScanner setScanLocation:startIndex];

  NSLog(@"length of textStorage: %d", [[_textStorage string] length]);

//  NSLog(@"buffer: %@", [_textStorage string]);

  // This scanner eats one word at a time, we should have it imbeded in
  // another scanner that snacks on paragraphs (i.e. lines that end with
  // \n). Look in NSText.

  while (![paragraphScanner isAtEnd])
    {
//      leadingNlRange=[paragraphScanner scanSetCharacters];
      paragraphRange = [paragraphScanner scanNonSetCharacters];
      leadingNlRange=[paragraphScanner scanSetCharacters];

      if (leadingNlRange.length)
	currentStringRange = NSUnionRange (leadingNlRange,paragraphRange);

      NSLog(@"paragraphRange: (%d, %d)", paragraphRange.location, paragraphRange.length);

      NSLog(@"======> begin paragraph");

      lineScanner = [_GNUTextScanner scannerWithString:[[_textStorage string] substringWithRange:paragraphRange]
		      set:selectionWordGranularitySet invertedSet:invSelectionWordGranularitySet];

      while(![lineScanner isAtEnd])
        {
          previousScanLocation = [lineScanner scanLocation];
           // snack next word
          leadingSpacesRange = [lineScanner scanSetCharacters];    // leading spaces: only first time
          currentStringRange = [lineScanner scanNonSetCharacters];
          trailingSpacesRange= [lineScanner scanSetCharacters];

          if (leadingSpacesRange.length)
	    currentStringRange = NSUnionRange (leadingSpacesRange,currentStringRange);
          if (trailingSpacesRange.length)
	    currentStringRange = NSUnionRange (trailingSpacesRange,currentStringRange);

	  lSize = [_textStorage sizeRange:currentStringRange];

	  if (lineWidth + lSize.width < cSize.width)
	    {
	      if ([lineScanner isAtEnd])
                {
		  NSLog(@"we are at end before finishing a line: %d.\n",  [lineScanner scanLocation]);
	          [lines addObject:[NSNumber numberWithInt:(int)[lineScanner scanLocation] + paragraphRange.location]];
                }

	      lineWidth += lSize.width;
	      NSLog(@"lineWidth: %f", lineWidth);
	    }
	  else
	    {
	      if (ourLines > cSize.height)
                {
                   lastLineForContainerReached = YES;
                   break;
                 }

	      [lineScanner setScanLocation:previousScanLocation];
	      indexToAdd = previousScanLocation + paragraphRange.location;
	      ourLines += 14.0;
	      lineWidth = 0;

	      NSLog(@"indexToAdd: %d\tourLines: %f", indexToAdd, ourLines);

	      [lines addObject:[NSNumber numberWithInt:indexToAdd]];
	    }
	}

      if (lastLineForContainerReached)
        break;
    }

  endScanLocation = [lineScanner scanLocation] + paragraphRange.location;

  NSLog(@"endScanLocation: %d", endScanLocation);

  // set this container for that glyphrange

  [self setTextContainer:aContainer
	forGlyphRange:NSMakeRange(startIndex, endScanLocation - startIndex)];

  NSLog(@"ok, move on to step 2.");

  // step 2. break the lines up and assign rects to them.

  for (i=0;i<[lines count];i++)
    {
      NSRect aRect, bRect;
      float padding = [aContainer lineFragmentPadding];
      NSRange ourRange;

      NSLog(@"\t\t===> %d", [[lines objectAtIndex:i] intValue]);

      if (i == 0)
        {
          ourRange = NSMakeRange (startIndex, 
			[[lines objectAtIndex:i] intValue] - startIndex);
        }
      else
        {
          ourRange = NSMakeRange ([[lines objectAtIndex:i-1] intValue],
[[lines objectAtIndex:i] intValue] - [[lines objectAtIndex:i-1]
intValue]);
        }
 
      firstProposedRect = NSMakeRect (0, i * 14, cSize.width, 14);

      // ask our textContainer to fix our lineFragment.

      secondProposedRect = [aContainer
	lineFragmentRectForProposedRect: firstProposedRect
                            sweepDirection: NSLineSweepLeft
                         movementDirection: NSLineMoveLeft
			     remainingRect: &bRect];

      // set the line fragmentRect for this range.

      [self setLineFragmentRect: secondProposedRect
		  forGlyphRange: ourRange
		       usedRect: aRect];

      // set the location for this string to be 'show'ed.

      [self setLocation:NSMakePoint(secondProposedRect.origin.x + padding,
				    secondProposedRect.origin.y + padding) 
	    forStartOfGlyphRange: ourRange];
    }

// bloody hack.
//      if (moreText)
//      	[delegate layoutManager:self
//	  didCompleteLayoutForTextContainer:[textContainers objectAtIndex:i]
//          atEnd:NO];
//      else
//      	[delegate layoutManager:self
//	  didCompleteLayoutForTextContainer:[textContainers objectAtIndex:i]
//          atEnd:YES];

  [lines release];

  return endScanLocation;
}

- (void)_doLayout
{
  int i;
  BOOL moreText;
  int gIndex = 0;

  NSLog(@"doLayout called.\n");

  for (i=0;i<[_textContainers count];i++)
    {
      gIndex = [self _rebuildLayoutForTextContainer:[_textContainers objectAtIndex:i]
	startingAtGlyphIndex:gIndex];
    }
}
@end
