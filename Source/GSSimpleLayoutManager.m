/*
   GSSimpleLayoutManager.m

   First GNUstep layout manager, extracted from NSText

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   Author:  Daniel Böhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: September 2000
   Extracted from NSText, reorganised to specification

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
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

#include <Foundation/NSRange.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSCharacterSet.h>

#include <AppKit/NSGraphics.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSStringDrawing.h>

#include "GSSimpleLayoutManager.h"

#define HUGE 1e7

static NSCharacterSet *newlines;
static NSCharacterSet *selectionWordGranularitySet;
static NSCharacterSet *invSelectionWordGranularitySet;

@interface _GNULineLayoutInfo: NSObject
{
@public
  NSRange	glyphRange;
  NSRect	lineFragmentRect;
  NSRect	usedRect;
}


+ (id) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		  usedRect: (NSRect)charRect;


- (NSRange) glyphRange;
- (NSRect) lineFragmentRect;

- (NSString*) description;
@end

@implementation _GNULineLayoutInfo

+ (_GNULineLayoutInfo *) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		      usedRect: (NSRect)charRect
{
  _GNULineLayoutInfo *ret = AUTORELEASE([_GNULineLayoutInfo new]);

  ret->glyphRange = aRange;
  ret->lineFragmentRect = aRect;
  ret->usedRect = charRect;
  return ret;
}

- (NSRange) glyphRange
{
  return glyphRange;
}

- (NSRect) lineFragmentRect
{
  return lineFragmentRect;
}

- (NSString*) description
{
  return [[NSDictionary dictionaryWithObjectsAndKeys:
			  NSStringFromRange(glyphRange), @"GlyphRange",
			  NSStringFromRect(lineFragmentRect), @"LineFragmentRect",
			  nil]
	   description];
}

@end
// end: _GNULineLayoutInfo------------------------------------------------------


@interface GSSimpleLayoutManager (Private)

+ (void) setSelectionWordGranularitySet: (NSCharacterSet*)aSet;

- (NSRect) rectForCharacterIndex: (unsigned) index;
- (NSRange) lineRangeForRect: (NSRect) aRect;
- (NSSize) _sizeOfRange: (NSRange) range;

// return value is identical to the real line number
- (int) lineLayoutIndexForGlyphIndex: (unsigned) anIndex;
// returns the full glyph range for a line range
- (NSRange) glyphRangeForLineLayoutRange: (NSRange) aRange;
- (unsigned) lineLayoutIndexForPoint: (NSPoint)point;

- (void) setNeedsDisplayForLineRange: (NSRange) redrawLineRange
		     inTextContainer:(NSTextContainer *)aTextContainer;
// override for special layout of text
- (NSRange) rebuildForRange: (NSRange)aRange
		  delta: (int)insertionDelta
	    inTextContainer:(NSTextContainer *)aTextContainer;
// low level, override but never invoke (use setNeedsDisplayForLineRange:)
- (void) drawLinesInLineRange: (NSRange)aRange;
- (void) drawSelectionAsRangeNoCaret: (NSRange)aRange;
@end

@implementation GSSimpleLayoutManager

+ (void) initialize
{
  NSMutableCharacterSet	*ms;
  NSCharacterSet        *whitespace;

  whitespace = [NSCharacterSet whitespaceCharacterSet];
  ms = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
  [ms formIntersectionWithCharacterSet: [whitespace invertedSet]];
  newlines = [ms copy];
  RELEASE(ms);
  [self setSelectionWordGranularitySet: whitespace];
}

- (id) init
{
  self = [super init];

  _lineLayoutInformation = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(_lineLayoutInformation);

  [super dealloc];
}

- (void) setTextStorage: (NSTextStorage*)aTextStorage
{
  [_lineLayoutInformation removeAllObjects];

  [super setTextStorage: aTextStorage];
}

// Returns the currently used bounds for all the text
- (NSRect)usedRectForTextContainer:(NSTextContainer *)aTextContainer
{
  if ([_lineLayoutInformation count])
    {
      NSEnumerator *lineEnum;
      _GNULineLayoutInfo *currentInfo;
      NSRect retRect = NSMakeRect (0, 0, 0, 0);

      for ((lineEnum = [_lineLayoutInformation objectEnumerator]);
	   (currentInfo = [lineEnum nextObject]);)
	{
	  retRect = NSUnionRect (retRect, currentInfo->usedRect);
	}
      return retRect;
    }
  else
    return NSZeroRect;
}

- (unsigned) glyphIndexForPoint: (NSPoint)point
		inTextContainer: (NSTextContainer*)aTextContainer
 fractionOfDistanceThroughGlyph: (float*)partialFraction
{
  _GNULineLayoutInfo *currentInfo = [_lineLayoutInformation 
				      objectAtIndex: 
					[self lineLayoutIndexForPoint: point]];
  NSRect rect = currentInfo->usedRect;
  NSRange range = currentInfo->glyphRange;
  int i;
  int min = range.location;
  int max = NSMaxRange(range);
  float x = point.x;
  float fmin = rect.origin.x;
  float fmax = NSMaxX(rect);
  float w1, w2;

  if (partialFraction != NULL)
    {
      *partialFraction = 0.0;
    }
  if (x <= fmin)
    {
      return MAX(0, min - 1);
    }
  if (x >= fmax)
    {
      return MAX(0, max);
    }
  if (range.length == 1)
    {
      return min;
    }

  // this should give a good starting index for binary search
  i = (int)((max - min) * (x - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      w1 = [self _sizeOfRange:
		  NSMakeRange (range.location,
			       i - range.location)].width + fmin;
      if (i > range.location)
	w2 = [self _sizeOfRange:
		     NSMakeRange (range.location,
				  i-1 - range.location)].width + fmin;
      else
	w2 = fmin;

      if (w1 < x)
	{
	  min = i + 1;
	  i = (max + min) / 2;
	  continue;
	}
      if (w2 > x)
	{
	  max = i - 1;
	  i = (max + min) / 2;
	  continue;
	}
      if (w1 > x)
	{
	  if (partialFraction != NULL)
	    {
	      *partialFraction = 1.0 - (w1 - x)/(w1 - w2); 
	    }
	}
      return MAX(0, i-1);
    }
  return MAX(0, min - 1);
}

- (NSRect)lineFragmentRectForGlyphAtIndex:(unsigned)index 
			   effectiveRange:(NSRange*)lineFragmentRange
{
  _GNULineLayoutInfo *currentInfo;

  if (![_textStorage length] || ![_lineLayoutInformation count])
    {
      return NSMakeRect(0, 0, 0, 12);
    }
    
  currentInfo = [_lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					     index]];

  if (lineFragmentRange)
      *lineFragmentRange = currentInfo->glyphRange;

  return currentInfo->lineFragmentRect;
}

- (NSPoint)locationForGlyphAtIndex:(unsigned)index
{
  float x;
  unsigned start;
  _GNULineLayoutInfo *currentInfo;
  NSRect rect;

  if (![_textStorage length] || ![_lineLayoutInformation count])
    {
      return NSMakePoint(0, 0);
    }
    
  currentInfo = [_lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					     index]];
  if (index >= NSMaxRange(currentInfo->glyphRange))
    return NSMakePoint(NSMaxX(currentInfo->usedRect), 0);

  start = currentInfo->glyphRange.location;
  rect = currentInfo->lineFragmentRect;
  x = [self _sizeOfRange: NSMakeRange(start, index-start)].width;

  return NSMakePoint(x, 0);
//  return NSMakePoint(rect.origin.x + x, rect.origin.y);
}

- (NSRect)boundingRectForGlyphRange:(NSRange)aRange 
		    inTextContainer:(NSTextContainer *)aTextContainer;
{
  float width = [aTextContainer containerSize].width;
  _GNULineLayoutInfo *currentInfo;
  unsigned i1, i2;
  NSRect rect1;

  if (![_textStorage length] || ![_lineLayoutInformation count])
    {
      return NSMakeRect(0, 0, width, 12);
    }

  i1 = [self lineLayoutIndexForGlyphIndex: aRange.location];
  i2 = [self lineLayoutIndexForGlyphIndex: NSMaxRange(aRange)];

  // This is not exacty what we need, but should be correct enough
  currentInfo = [_lineLayoutInformation objectAtIndex: i1];
  rect1 = currentInfo->usedRect;

  if (i1 != i2)
    {
      currentInfo = [_lineLayoutInformation objectAtIndex: i2];
      rect1 = NSUnionRect(rect1, currentInfo->usedRect);
    }

  rect1.size.width = width - rect1.origin.x;
  return rect1;
}

- (NSRange)glyphRangeForBoundingRect:(NSRect)aRect 
		     inTextContainer:(NSTextContainer *)aTextContainer
{
  NSRange aRange = [self lineRangeForRect: aRect];

  return [self glyphRangeForLineLayoutRange: aRange];    
}

- (NSRect*) rectArrayForCharacterRange:(NSRange)aRange 
	  withinSelectedCharacterRange:(NSRange)selCharRange
		       inTextContainer:(NSTextContainer *)aTextContainer 
			     rectCount:(unsigned *)rectCount;
{
  //FIXME: This currently ignores most of its arguments

  if (!rectCount)
      return _rects;

  if (aRange.length)
    {
      NSRect startRect = [self rectForCharacterIndex: aRange.location];
      NSRect endRect = [self rectForCharacterIndex: NSMaxRange (aRange)];
      float width = [aTextContainer containerSize].width;

      if (startRect.origin.y  == endRect.origin.y)
	{
	  // single line selection
	  _rects[0] = NSMakeRect (startRect.origin.x, startRect.origin.y,
				  endRect.origin.x - startRect.origin.x,
				  startRect.size.height);
	  *rectCount = 1;
	}
      else if (startRect.origin.y == endRect.origin.y - endRect.size.height)
	{
	  // two line selection

	  // first line
	  _rects[0] = NSMakeRect (startRect.origin.x, startRect.origin.y,
				  width - startRect.origin.x,
				  startRect.size.height);
	  // second line
	  _rects[1] = NSMakeRect (0, endRect.origin.y, endRect.origin.x,
				  endRect.size.height);
	  *rectCount = 2;
	}
      else
	{
	  //   3 Rects: multiline selection

	  // first line
	  _rects[0] = NSMakeRect (startRect.origin.x, startRect.origin.y,
				  width - startRect.origin.x,
				  startRect.size.height);
	  // intermediate lines
	  _rects[1] = NSMakeRect (0, NSMaxY(startRect),
				  width,
				  endRect.origin.y - NSMaxY (startRect));
	  // last line
	  _rects[2] = NSMakeRect (0, endRect.origin.y, endRect.origin.x,
				  endRect.size.height);
	  *rectCount = 3;
	}
    }
  else 
    *rectCount = 0;

  return _rects;
}

- (NSRange)glyphRangeForTextContainer: (NSTextContainer*)aContainer
{
  return NSMakeRange(0, [_textStorage length]);
}

- (NSTextContainer*) textContainerForGlyphAtIndex: (unsigned)glyphIndex
                                   effectiveRange: (NSRange*)effectiveRange
{
  if (effectiveRange)
    *effectiveRange = NSMakeRange(0, [_textStorage length]);

  return  [_textContainers objectAtIndex: 0];
}

- (void) setTextContainer: (NSTextContainer*)aTextContainer
	    forGlyphRange: (NSRange)glyphRange
{
}

- (void)invalidateGlyphsForCharacterRange:(NSRange)charRange 
			   changeInLength:(int)delta
		     actualCharacterRange:(NSRange*)actualCharRange
{
  // As we currenty dont have any glyph character mapping, we only have 
  // to adjust the ranges in the line layout infos

  if (actualCharRange)
    *actualCharRange = charRange;
}

- (void) invalidateLayoutForCharacterRange: (NSRange)aRange
				    isSoft: (BOOL)flag
		      actualCharacterRange: (NSRange*)actualRange
{
  NSRange lineRange;
  NSTextContainer *aTextContainer = [self textContainerForGlyphAtIndex: aRange.location
					  effectiveRange: NULL];

  lineRange = [self rebuildForRange: aRange 
		    delta: 0
		    inTextContainer: aTextContainer];
  [[aTextContainer textView] sizeToFit];
  [[aTextContainer textView] invalidateTextContainerOrigin];

  if (actualRange)
    *actualRange = [self glyphRangeForLineLayoutRange: lineRange];
}

- (void)textStorage:(NSTextStorage *)aTextStorage
	     edited:(unsigned int)mask
	      range:(NSRange)aRange
     changeInLength:(int)delta
   invalidatedRange:(NSRange)invalidatedCharRange;
{
  NSRange lineRange;
  NSTextContainer *aTextContainer;

  // No editing
  if (!mask)
    return;
  
  [self invalidateGlyphsForCharacterRange: invalidatedCharRange
	changeInLength: delta
	actualCharacterRange: NULL];

  aTextContainer = [self textContainerForGlyphAtIndex: aRange.location
			 effectiveRange: NULL];
  lineRange = [self rebuildForRange: aRange
		    delta: delta
		    inTextContainer: aTextContainer];
  [[aTextContainer textView] sizeToFit];
  [[aTextContainer textView] invalidateTextContainerOrigin];

  [self setNeedsDisplayForLineRange: lineRange
	inTextContainer: aTextContainer];
}

/* FIXME: According to the doc, the following method should be able to
 * draw in any view after the focus has been locked on it. */
- (void)drawBackgroundForGlyphRange:(NSRange)glyphRange 
			    atPoint:(NSPoint)containerOrigin
{
  NSTextContainer *aTextContainer = [self textContainerForGlyphAtIndex: glyphRange.location
					  effectiveRange: NULL];
  NSRect rect = [self boundingRectForGlyphRange: glyphRange 
		      inTextContainer: aTextContainer];

  /* FIXME: Which means that the following <which assumes we are
     drawing in a text view> can't be correct */
  // clear area under text
  [[[aTextContainer textView] backgroundColor] set];
  NSRectFill(rect);
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange 
			atPoint:(NSPoint)containerOrigin
{
  NSRange newRange;
  NSRange selectedRange = [[self firstTextView] selectedRange];
  unsigned start = [self lineLayoutIndexForGlyphIndex: glyphRange.location];
  unsigned end = [self lineLayoutIndexForGlyphIndex: NSMaxRange(glyphRange)];
  NSRange lineRange = NSMakeRange(start, end + 1 - start);

  [self drawLinesInLineRange: lineRange];

  // We have to redraw the part of the selection that is inside
  // the redrawn lines
  newRange = NSIntersectionRange(selectedRange, glyphRange);
  // Was there any overlapping with the selection?
  if ((selectedRange.length &&
       NSLocationInRange(newRange.location, selectedRange)))
    {
      [self drawSelectionAsRangeNoCaret: newRange];
    }
}

- (void) setLineFragmentRect: (NSRect)fragmentRect
	       forGlyphRange: (NSRange)glyphRange
		    usedRect: (NSRect)usedRect
{
  [_lineLayoutInformation addObject:
      [_GNULineLayoutInfo
	  lineLayoutWithRange: glyphRange
	  rect: fragmentRect
	  usedRect: usedRect]];
}

- (void) setLocation: (NSPoint)aPoint
forStartOfGlyphRange: (NSRange)glyphRange
{
}

@end

@implementation GSSimpleLayoutManager (Private)

+ (void) setSelectionWordGranularitySet: (NSCharacterSet*) aSet
{
  ASSIGN(selectionWordGranularitySet, aSet);
  ASSIGN(invSelectionWordGranularitySet, [aSet invertedSet]);
}

- (NSSize) _sizeOfRange: (NSRange)aRange
{
  if (!aRange.length || _textStorage == nil ||
      NSMaxRange(aRange) > [_textStorage length])
    return NSZeroSize;

  return [_textStorage sizeRange: aRange];
}

- (unsigned) lineLayoutIndexForPoint: (NSPoint)point
{
  int i;
  int min = 0;
  int max = MAX(0, [_lineLayoutInformation count] - 1);
  float y = point.y;
  float fmin = NSMinY([[_lineLayoutInformation objectAtIndex: 0] lineFragmentRect]);
  float fmax = NSMaxY([[_lineLayoutInformation lastObject] lineFragmentRect]);
  NSRect rect;

  if (y >= fmax)
    return max;

  if (y <= fmin)
    return min;

  // this should give a good starting index for binary search
  i = (int)((max - min) * (y - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      _GNULineLayoutInfo *ci = [_lineLayoutInformation objectAtIndex: i];

      rect = ci->lineFragmentRect;

      if (NSMaxY(rect) < y)
	{
	  min = i + 1;
	  i = (max + min) / 2;
	  continue;
	}
      if (NSMinY(rect) > y)
	{
	  max = i - 1;
	  i = (max + min) / 2;
	  continue;
	}

      return i;
    }
  return min;
}

- (int) lineLayoutIndexForGlyphIndex: (unsigned)anIndex
{
  int i;
  int min = 0;
  int max = MAX(0, (int)[_lineLayoutInformation count] - 1);
  unsigned y = anIndex;
  unsigned fmin;
  unsigned fmax;
  NSRange range;

  if (!max)
    return 0;

  fmin = [[_lineLayoutInformation objectAtIndex: 0] glyphRange].location;
  fmax = NSMaxRange([[_lineLayoutInformation lastObject] glyphRange]);

  if (y >= fmax)
    return max;

  if (y <= fmin)
    return min;

  // this should give a good starting index for binary search
  i = (int)((max - min) * (y - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      _GNULineLayoutInfo *ci = [_lineLayoutInformation objectAtIndex: i];

      range = ci->glyphRange;

      if (NSMaxRange(range) <= y)
	{
	  min = i + 1;
	  i = (max + min) / 2;
	  continue;
	}
      if (range.location > y)
	{
	  max = i - 1;
	  i = (max + min) / 2;
	  continue;
	}
      // Do we need a special treatment for paragraph infos?
      return i;
    }
  return min;
}

- (NSRange) glyphRangeForLineLayoutRange: (NSRange)aRange;
{
  _GNULineLayoutInfo	*currentInfo;
  unsigned startLine = aRange.location;
  unsigned endLine = NSMaxRange(aRange);
  unsigned startIndex;
  unsigned endIndex;

  if (startLine >= [_lineLayoutInformation count])
    currentInfo = [_lineLayoutInformation lastObject];
  else
    currentInfo = [_lineLayoutInformation objectAtIndex: startLine];
  startIndex = currentInfo->glyphRange.location;

  if (endLine >= [_lineLayoutInformation count])
    currentInfo = [_lineLayoutInformation lastObject];
  else
    currentInfo = [_lineLayoutInformation objectAtIndex: endLine];
  endIndex = NSMaxRange(currentInfo->glyphRange);

  return NSMakeRange(startIndex, endIndex - startIndex);
}

// rect to the end of line
- (NSRect) rectForCharacterIndex: (unsigned)index
{
  float width =  [[self textContainerForGlyphAtIndex: index
			effectiveRange: NULL] containerSize].width;
  _GNULineLayoutInfo *currentInfo;
  unsigned start;
  NSRect rect;
  float x;

  if (![_textStorage length] || ![_lineLayoutInformation count])
    {
      return NSMakeRect(0, 0, width, 12);
    }

  currentInfo = [_lineLayoutInformation lastObject];
  if (index >= NSMaxRange(currentInfo->glyphRange))
    {
      NSRect rect = currentInfo->lineFragmentRect;

      return NSMakeRect(NSMaxX (rect), rect.origin.y,
			width - NSMaxX (rect),
			rect.size.height);
    }


  currentInfo = [_lineLayoutInformation 
		  objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					 index]];
  start = currentInfo->glyphRange.location;
  rect = currentInfo->lineFragmentRect;
  x = rect.origin.x + [self _sizeOfRange: NSMakeRange(start, index-start)].width;
     
  return NSMakeRect(x, rect.origin.y, NSMaxX (rect) - x,
		    rect.size.height);
}

- (void) drawSelectionAsRangeNoCaret: (NSRange)aRange
{
  unsigned i, count;
  NSTextContainer *aTextContainer;
  NSRect *rects;

  aTextContainer = [self textContainerForGlyphAtIndex: aRange.location
			 effectiveRange: NULL];
  rects = [self rectArrayForCharacterRange: aRange 
		withinSelectedCharacterRange: aRange
		inTextContainer: aTextContainer
		rectCount: &count];

  for (i = 0; i < count; i++)
    {
	NSHighlightRect (rects[i]);
    }
}

- (NSRange) lineRangeForRect: (NSRect)rect
{
  NSPoint upperLeftPoint = rect.origin;
  NSPoint lowerRightPoint = NSMakePoint (NSMaxX (rect), NSMaxY (rect));
  unsigned startLine, endLine;

  startLine = [self lineLayoutIndexForPoint: upperLeftPoint];
  endLine = [self lineLayoutIndexForPoint: lowerRightPoint];
  if (++endLine > [_lineLayoutInformation count])
    endLine = [_lineLayoutInformation count];

  return NSMakeRange(startLine, endLine - startLine);
}

// relies on _lineLayoutInformation
- (void) drawLinesInLineRange: (NSRange)aRange;
{
  NSArray *linesToDraw = [_lineLayoutInformation subarrayWithRange: aRange];
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;

  for ((lineEnum = [linesToDraw objectEnumerator]);
       (currentInfo = [lineEnum nextObject]);)
    {
      [_textStorage drawRange: currentInfo->glyphRange
		    inRect: currentInfo->lineFragmentRect];
    }
}

- (void) setNeedsDisplayForLineRange: (NSRange)redrawLineRange
		     inTextContainer: (NSTextContainer *)aTextContainer 
{
  if ([_lineLayoutInformation count]
      && redrawLineRange.location < [_lineLayoutInformation count]
      && redrawLineRange.length)
    {
      _GNULineLayoutInfo *firstInfo
	= [_lineLayoutInformation objectAtIndex: redrawLineRange.location];
      NSRect displayRect = firstInfo->lineFragmentRect;
      float width = [aTextContainer containerSize].width;

      if (redrawLineRange.length > 1)
	  displayRect = NSUnionRect(displayRect,
				    [[_lineLayoutInformation
					 objectAtIndex: 
					     (int)NSMaxRange(redrawLineRange) - 1] lineFragmentRect]);

      displayRect.size.width = width - displayRect.origin.x;
      [[aTextContainer textView] setNeedsDisplayInRect: displayRect];
    }
}

- (BOOL) _relocLayoutArray: (NSMutableArray*)ghostArray
		    offset: (int)relocOffset
		floatTrift: (float*)yDisplacement
{
  _GNULineLayoutInfo *lastInfo = [_lineLayoutInformation lastObject];
  // The start character in the ghostArray
  unsigned nextChar = NSMaxRange(lastInfo->glyphRange) - relocOffset;
  NSEnumerator *relocEnum;
  _GNULineLayoutInfo *currReloc = nil;
  float yReloc;

  while ([ghostArray count])
    {
      unsigned firstChar;
      
      currReloc = [ghostArray objectAtIndex: 0];
      firstChar =  currReloc->glyphRange.location;
      if (firstChar == nextChar)
	break;
      else if (firstChar > nextChar)
	return NO;
      else
	[ghostArray removeObjectAtIndex: 0];
    }

  if (![ghostArray count])
    return NO;

  relocEnum = [ghostArray objectEnumerator];
  yReloc = NSMaxY(lastInfo->lineFragmentRect) - currReloc->lineFragmentRect.origin.y;
  if (yDisplacement)
    *yDisplacement = yReloc;

  while ((currReloc = [relocEnum nextObject]) != nil)
    {
      currReloc->glyphRange.location += relocOffset;
      if (yReloc)
	{
	  currReloc->lineFragmentRect.origin.y += yReloc;
	  currReloc->usedRect.origin.y += yReloc;
	}
      [_lineLayoutInformation addObject:  currReloc];
    }

  return YES;
}

/*
 * A little utility function to determine the range of characters in a scanner
 * that are present in a specified character set.
 */
static inline NSRange
scanRange(NSScanner *scanner, NSCharacterSet* aSet)
{
  unsigned	start = [scanner scanLocation];
  unsigned	end = start;

  if ([scanner scanCharactersFromSet: aSet intoString: 0] == YES)
    {
      end = [scanner scanLocation];
    }
  return NSMakeRange(start, end - start);
}

// returns range of lines actually updated
- (NSRange) rebuildForRange: (NSRange)aRange
		      delta: (int)insertionDelta
	    inTextContainer:(NSTextContainer *)aTextContainer 
{
  NSPoint drawingPoint = NSZeroPoint;
  float padding = [aTextContainer lineFragmentPadding];
  unsigned startingIndex = 0;
  unsigned currentLineIndex;
  NSString *allText = [_textStorage string];
  unsigned length = [allText length];
  unsigned paraPos;
  int maxLines = [_lineLayoutInformation count];
  int aLine = 0;
  // for optimization detection
  NSMutableArray *ghostArray = nil;

  if (maxLines)
    {
      int insertionLineIndex = [self lineLayoutIndexForGlyphIndex:
				       aRange.location];
      int nextLine = [self lineLayoutIndexForGlyphIndex: 
			     NSMaxRange(aRange) - insertionDelta] + 1;
      
      if (nextLine < maxLines)
	{
	  // remember old array for optimization purposes
	  ghostArray = AUTORELEASE([[_lineLayoutInformation
				      subarrayWithRange:
					NSMakeRange (nextLine, 
						     maxLines - nextLine)]
				     mutableCopy]);
	}
      
      aLine = MAX(0, insertionLineIndex - 1);
      if (aLine)
	{
	  _GNULineLayoutInfo *lastValidLineInfo = [_lineLayoutInformation 
						    objectAtIndex: aLine - 1];
	  NSRect aRect = lastValidLineInfo->lineFragmentRect;
	  
	  startingIndex = NSMaxRange(lastValidLineInfo->glyphRange);
	  drawingPoint = aRect.origin;
	  drawingPoint.y += aRect.size.height;
	}
      
      [_lineLayoutInformation removeObjectsInRange:
				NSMakeRange (aLine, maxLines - aLine)];
    }
  
  if (!length)
    {
      float width = [aTextContainer containerSize].width;

      // FIXME: This should be done via extra line fragment
      // If there is no text add one empty box
      [_lineLayoutInformation
	  addObject: [_GNULineLayoutInfo
			 lineLayoutWithRange: NSMakeRange (0, 0)
			 rect: NSMakeRect (0, 0, width, 12)
			 usedRect: NSMakeRect (0, 0, 0, 12)]];
      return NSMakeRange(0,1);
    }
      
  currentLineIndex = aLine;
  paraPos = startingIndex;

  while (paraPos < length)
    {
      NSRange	para;		// Range of current paragraph.
      NSRange	eol;		// Range of newline character.
      NSScanner	*lScanner;
      unsigned	startingLineCharIndex = paraPos;
      BOOL	isBuckled = NO;
      NSString *paragraph;
      unsigned	position;	// Position in NSString.
      NSRect remainingRect = NSZeroRect;

      // Determine the range of the next paragraph of text (in 'para') and set
      // 'paraPos' to point after the terminating newline character (if any).
      para = NSMakeRange(paraPos, length - paraPos);
      eol = [allText rangeOfCharacterFromSet: newlines
		     options: NSLiteralSearch
		     range: para];

      if (eol.length == 0)
	{
	  eol.location = length;
	}
      else
	{
	  para.length = eol.location - para.location;
	}
      paraPos = NSMaxRange(eol);
      position = para.location;

      paragraph = [allText substringWithRange: para];
      lScanner = [NSScanner scannerWithString: paragraph];
      [lScanner setCharactersToBeSkipped: nil];

      // Process a paragraph
      do
	{
	  // Temporary added a autorelease pool, as the current layout
	  // mechanism uses up much memory space, that should be freed
	  // as soon as possible.
	  CREATE_AUTORELEASE_POOL(pool);
	  NSRect fragmentRect;
	  NSRect usedLineRect;
	  float width;
	  NSRange lineGlyphRange;
	  // starts with zero, do not confuse with startingLineCharIndex
	  unsigned localLineStartIndex = [lScanner scanLocation];
	  unsigned scannerPosition = localLineStartIndex;

	  if (NSIsEmptyRect(remainingRect))
	    {
	      fragmentRect = NSMakeRect (0, drawingPoint.y, HUGE, HUGE);
	    }
	  else 
	    {
	      fragmentRect = remainingRect;
	    }
	  
	  fragmentRect = [aTextContainer 
			   lineFragmentRectForProposedRect: fragmentRect
			   sweepDirection: NSLineSweepRight
			   movementDirection: NSLineMoveDown
			   remainingRect: &remainingRect];
	  if (NSIsEmptyRect(fragmentRect))
 	    {
	      // No more space in the text container, give up doing the layout
	      int a = MAX (1, [_lineLayoutInformation count] - aLine);
	      return NSMakeRange(aLine, a);
	    }

	  width = fragmentRect.size.width - 2 * padding;
	  usedLineRect = fragmentRect;
	  usedLineRect.origin.x += padding;
	  usedLineRect.size = NSZeroSize;
	  
	  // scan the individual words to the end of the line
	  while (![lScanner isAtEnd]) 
	    {
	      NSRange	currentStringRange, trailingSpacesRange;
	      NSRange	leadingSpacesRange;
	      NSSize advanceSize;

	      // snack next word
	      // leading spaces: only first time
	      leadingSpacesRange
		= scanRange(lScanner, selectionWordGranularitySet);
	      currentStringRange
		= scanRange(lScanner, invSelectionWordGranularitySet);
	      trailingSpacesRange
		= scanRange(lScanner, selectionWordGranularitySet);

	      if (leadingSpacesRange.length)
		{
		  currentStringRange = NSUnionRange(leadingSpacesRange,
						    currentStringRange);
		}
	      if (trailingSpacesRange.length)
		{
		  currentStringRange = NSUnionRange(trailingSpacesRange,
						    currentStringRange);
		}
	      
	      // evaluate size of current word
	      advanceSize = [self _sizeOfRange:
				    NSMakeRange (currentStringRange.location + position,
						 currentStringRange.length)];

	      // handle case where single word is broader than width
	      // (buckle word)
	      if (advanceSize.width > width)
		{
		  if (isBuckled)
		    {
		      NSSize currentSize = NSMakeSize (HUGE, 0);
		      unsigned lastVisibleCharIndex;

		      for (lastVisibleCharIndex  =  currentStringRange.length;
			   currentSize.width >= width && lastVisibleCharIndex;
			   lastVisibleCharIndex--)
			{
			  currentSize = [self _sizeOfRange: NSMakeRange(
			      startingLineCharIndex, lastVisibleCharIndex)];
			}
		      isBuckled = NO;
		      usedLineRect.size = currentSize;
		      scannerPosition = localLineStartIndex + lastVisibleCharIndex +1;
		      [lScanner setScanLocation: scannerPosition];
		      break;
		    }
		  else
		    {
		      // undo layout of extralarge word
		      // (will be done on the next line [see above])
		      isBuckled = YES;
		    }
		}
	      else 
		{
		  isBuckled = NO;
		}
	      
	      // line to long
	      if (usedLineRect.size.width + advanceSize.width > width || 
		  isBuckled)
	        {
		  // end of line -> word wrap
		  // undo layout of last word
		  [lScanner setScanLocation: scannerPosition];
		  break;
		}

	      // Add next word
	      usedLineRect = NSUnionRect (usedLineRect,
					     NSMakeRect (drawingPoint.x,
							 drawingPoint.y,
							 advanceSize.width,
							 advanceSize.height));
	      scannerPosition = [lScanner scanLocation];
	      drawingPoint.x += advanceSize.width;
	    }

	  if ([lScanner isAtEnd])
	    {
	      // newline - induced premature lineending: flush
	      if (eol.length)
	        {
		  // Add information for the line break
		  scannerPosition += eol.length;
		  usedLineRect.size.width += 1;
		  // FIXME: This should use the real font size!!
		  if (usedLineRect.size.height == 0)
		    {
		      usedLineRect.size.height = 12;
		    }
		}
	    }
	  
	  lineGlyphRange = NSMakeRange (startingLineCharIndex,
					scannerPosition - localLineStartIndex);
	  // Adjust the height of the line fragment rect, as this will
	  // the to big
	  fragmentRect.size.height = usedLineRect.size.height;
	  
	  // This range is to small, as there are more lines that fit
	  // into the container
	  [self setTextContainer: aTextContainer 
		forGlyphRange: lineGlyphRange];
	  
	  [self setLineFragmentRect: fragmentRect
		forGlyphRange: lineGlyphRange
		usedRect: usedLineRect];

	  // This range is too big, as there are different runs in the
	  // glyph range
	  [self setLocation: NSMakePoint(0.0, 0.0)
		forStartOfGlyphRange: lineGlyphRange];
	  
	  currentLineIndex++;
	  startingLineCharIndex = NSMaxRange(lineGlyphRange);
	  drawingPoint.y += usedLineRect.size.height;
	  drawingPoint.x = 0;
	  
	  RELEASE(pool);
	  
	  if (ghostArray != nil)
	    {
	      float yDisplacement = 0;
	      
	      // is it possible to simply patch layout changes into
	      // layout array instead of doing a time consuming re -
	      // layout of the whole doc?
	      if ([self _relocLayoutArray: ghostArray
			offset: insertionDelta
			floatTrift: &yDisplacement])
	        {
		  unsigned erg;
		  
		  // y displacement: redisplay all remaining lines
		  if (yDisplacement)
		    {
		      erg = [_lineLayoutInformation count] - aLine;
		    }
		  else 
		    {
		      // return 2: redisplay only this and previous line
		      erg = currentLineIndex - aLine;
		    }
	      
		  return NSMakeRange(aLine, MAX(1, erg));
		}
	    }
	}
      while ([lScanner isAtEnd] == NO);
    }
  
  // lines actually updated (optimized drawing)
  return NSMakeRange(aLine, MAX(1, [_lineLayoutInformation count] - aLine));
}


/* Computing where the insertion point should be moved when the user
 * presses 'Up' or 'Down' is a task for the layout manager.  */

/* Insertion point has y coordinate `position'.  We'd like to put it
   one line up/down (up if upFlag == YES, down if upFlag == NO),
   horizontally at `wanted', or the nearest available place.  Return
   the char index for the new insertion point position.  */
- (unsigned) _charIndexForInsertionPointMovingFromY: (float)position
					      bestX: (float)wanted
						 up: (BOOL)upFlag
				      textContainer: (NSTextContainer *)tc
{
  NSPoint point;
  unsigned line;
  _GNULineLayoutInfo *lineInfo;
  NSRect rect;
  NSRange range;
  unsigned glyphIndex;
  
  /* Compute the line we were on */
  point.x = 0;
  point.y = position;
  
  line = [self lineLayoutIndexForPoint: point];
  
  if (upFlag == YES  &&  line == 0)
    {
      return 0;
    }
  else if (upFlag == NO  &&  line == ([_lineLayoutInformation count] - 1))
    {
      return [_textStorage length];
    }

  /* Get line info for previous/following line */
  if (upFlag)
    {
      line -= 1;
    }
  else
    {
      line += 1;
    }

  lineInfo = [_lineLayoutInformation objectAtIndex: line];
  
  rect  = lineInfo->usedRect;
  range = lineInfo->glyphRange;

  /* Check if we are outside the rect */
  if (wanted <= rect.origin.x)
    {
      glyphIndex = [self characterIndexForGlyphAtIndex: range.location];
    }
  
  else if (wanted >= NSMaxX (rect))
    {
      glyphIndex = [self characterIndexForGlyphAtIndex: 
			   (NSMaxRange (range) - 1)];
    }
  else
    {
      /* Else, we can simply move there ! */
      glyphIndex = [self glyphIndexForPoint: NSMakePoint (wanted, 
							  NSMidY (rect)) 
			 inTextContainer: tc
			 fractionOfDistanceThroughGlyph: NULL];
    }
  return [self characterIndexForGlyphAtIndex: glyphIndex];
}

@end

