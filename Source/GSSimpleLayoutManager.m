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

static NSCharacterSet *selectionWordGranularitySet;
static NSCharacterSet *newlines;
static NSCharacterSet *invSelectionWordGranularitySet;

@interface _GNULineLayoutInfo: NSObject
{
@public
  NSRange	lineRange;
  NSRect	lineRect;
  NSRect	usedRect;
}


+ (id) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		  usedRect: (NSRect)charRect;


- (NSRange) lineRange;
- (NSRect) lineRect;

- (NSString*) description;
@end

@implementation _GNULineLayoutInfo

+ (_GNULineLayoutInfo *) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		      usedRect: (NSRect)charRect
{
  _GNULineLayoutInfo *ret = AUTORELEASE([_GNULineLayoutInfo new]);

  ret->lineRange = aRange;
  ret->lineRect = aRect;
  ret->usedRect = charRect;
  return ret;
}

- (NSRange) lineRange
{
  return lineRange;
}

- (NSRect) lineRect
{
  return lineRect;
}

- (NSString*) description
{
  return [[NSDictionary dictionaryWithObjectsAndKeys:
			  NSStringFromRange(lineRange), @"LineRange",
			  NSStringFromRect(lineRect), @"LineRect",
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
- (float) width;
- (float) maxWidth;

// return value is identical to the real line number
- (int) lineLayoutIndexForGlyphIndex: (unsigned) anIndex;
// returns the full glyph range for a line range
- (NSRange) glyphRangeForLineLayoutRange: (NSRange) aRange;
- (unsigned) lineLayoutIndexForPoint: (NSPoint)point;

- (void) setNeedsDisplayForLineRange: (NSRange) redrawLineRange;
// override for special layout of text
- (NSRange) rebuildForRange: (NSRange)aRange
		  delta: (int)insertionDelta;
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

- (void) dealloc
{
  RELEASE(_lineLayoutInformation);

  [super dealloc];
}

- (void) setTextStorage: (NSTextStorage*)aTextStorage
{
  DESTROY(_lineLayoutInformation);

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
	  retRect = NSUnionRect (retRect, currentInfo->lineRect);
	}
      return retRect;
    }
  else
    return NSZeroRect;
}

- (unsigned)glyphIndexForPoint:(NSPoint)point 
	       inTextContainer:(NSTextContainer *)aTextContainer
{
  _GNULineLayoutInfo *currentInfo = [_lineLayoutInformation 
				      objectAtIndex: 
					[self lineLayoutIndexForPoint: point]];
  NSRect rect = currentInfo->usedRect;
  NSRange range = currentInfo->lineRange;
  int i;
  int min = range.location;
  int max = NSMaxRange(range);
  float x = point.x;
  float fmin = rect.origin.x;
  float fmax = NSMaxX(rect);
  float w1, w2;

  if (x <= fmin)
    return MAX(0, min - 1);
  if (x >= fmax)
    return MAX(0, max);
  if (range.length == 1)
    return min;

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
      return MAX(0, i-1);
    }
  return MAX(0, min - 1);
}

- (NSRect)lineFragmentRectForGlyphAtIndex:(unsigned)index 
			   effectiveRange:(NSRange*)lineFragmentRange
{
  _GNULineLayoutInfo *currentInfo;

  if (![_textStorage length])
    {
      return NSMakeRect(0, 0, 0, 12);
    }
    
  currentInfo = [_lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					     index]];

  if (lineFragmentRange)
      *lineFragmentRange = currentInfo->lineRange;

  return currentInfo->lineRect;
}

- (NSPoint)locationForGlyphAtIndex:(unsigned)index
{
  float x;
  unsigned start;
  _GNULineLayoutInfo *currentInfo;
  NSRect rect;

  if (![_textStorage length])
    {
      return NSMakePoint(0, 0);
    }
    
  currentInfo = [_lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					     index]];
  if (index >= NSMaxRange(currentInfo->lineRange))
    return NSMakePoint(NSMaxX(currentInfo->usedRect), 0);

  start = currentInfo->lineRange.location;
  rect = currentInfo->lineRect;
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

  if (![_textStorage length])
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

- (void) invalidateLayoutForCharacterRange: (NSRange)aRange
				    isSoft: (BOOL)flag
		      actualCharacterRange: (NSRange*)actualRange
{
  NSRange lineRange;

  lineRange = [self rebuildForRange: aRange delta: 0];

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

  // No editing
  if (!mask)
    return;

  lineRange = [self rebuildForRange: aRange
		delta: delta];
  [self setNeedsDisplayForLineRange: lineRange];
}

- (void)drawBackgroundForGlyphRange:(NSRange)glyphRange 
			    atPoint:(NSPoint)containerOrigin
{
  NSTextContainer *aContainer = [_textContainers objectAtIndex: 0];
  NSRect rect = [self boundingRectForGlyphRange: glyphRange 
		      inTextContainer: aContainer];

  // clear area under text
  [[[aContainer textView] backgroundColor] set];
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

- (NSRect) frame
{
  if ([self firstTextView] == nil)
    {
      NSSize size =  [[_textContainers objectAtIndex: 0] containerSize];
      return NSMakeRect(0, 0, size.width, size.height);
    }
  return [[self firstTextView] frame];
}

- (float) width
{
  return [[_textContainers objectAtIndex: 0] containerSize].width;
}

- (float) maxWidth
{
  if ([[self firstTextView] isHorizontallyResizable])
    return HUGE;
  else
    return [self width];
}

- (unsigned) lineLayoutIndexForPoint: (NSPoint)point
{
  int i;
  int min = 0;
  int max = MAX(0, [_lineLayoutInformation count] - 1);
  float y = point.y;
  float fmin = NSMinY([[_lineLayoutInformation objectAtIndex: 0] lineRect]);
  float fmax = NSMaxY([[_lineLayoutInformation lastObject] lineRect]);
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

      rect = ci->lineRect;

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
  int max = MAX(0, [_lineLayoutInformation count] - 1);
  unsigned y = anIndex;
  unsigned fmin = [[_lineLayoutInformation objectAtIndex: 0] lineRange].location;
  unsigned fmax = NSMaxRange([[_lineLayoutInformation lastObject] lineRange]);
  NSRange range;

  if (y >= fmax)
    return max;

  if (y <= fmin)
    return min;

  // this should give a good starting index for binary search
  i = (int)((max - min) * (y - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      _GNULineLayoutInfo *ci = [_lineLayoutInformation objectAtIndex: i];

      range = ci->lineRange;

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
  startIndex = currentInfo->lineRange.location;

  if (endLine >= [_lineLayoutInformation count])
    currentInfo = [_lineLayoutInformation lastObject];
  else
    currentInfo = [_lineLayoutInformation objectAtIndex: endLine];
  endIndex = NSMaxRange(currentInfo->lineRange);

  return NSMakeRange(startIndex, endIndex - startIndex);
}

// rect to the end of line
- (NSRect) rectForCharacterIndex: (unsigned)index
{
  float width = [self width];
  _GNULineLayoutInfo *currentInfo;
  unsigned start;
  NSRect rect;
  float x;

  if (![_textStorage length])
    {
      return NSMakeRect(0, 0, width, 12);
    }

  currentInfo = [_lineLayoutInformation lastObject];
  if (index >= NSMaxRange(currentInfo->lineRange))
    {
      NSRect rect = currentInfo->lineRect;

      return NSMakeRect(NSMaxX (rect), rect.origin.y,
			width - NSMaxX (rect),
			rect.size.height);
    }


 currentInfo = [_lineLayoutInformation 
		   objectAtIndex: [self lineLayoutIndexForGlyphIndex: 
					    index]];
 start = currentInfo->lineRange.location;
 rect = currentInfo->lineRect;
 x = rect.origin.x + [self _sizeOfRange: NSMakeRange(start, index-start)].width;
     
 return NSMakeRect(x, rect.origin.y, NSMaxX (rect) - x,
		   rect.size.height);
}

- (void) drawSelectionAsRangeNoCaret: (NSRange) aRange
{
  int i;
  unsigned count;
  NSRect *rects = [self rectArrayForCharacterRange: aRange 
			withinSelectedCharacterRange: aRange
			inTextContainer: [_textContainers objectAtIndex: 0]
			rectCount: &count];

  for (i = 0; i < count; i++)
    {
	NSHighlightRect(rects[i]);
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
      [_textStorage drawRange: currentInfo->lineRange
		    inRect: currentInfo->lineRect];
    }
}

- (void) setNeedsDisplayForLineRange: (NSRange)redrawLineRange
{
  float width = [self width];

  if ([_lineLayoutInformation count]
      && redrawLineRange.location < [_lineLayoutInformation count]
      && redrawLineRange.length)
    {
      _GNULineLayoutInfo *firstInfo
	= [_lineLayoutInformation objectAtIndex: redrawLineRange.location];
      NSRect displayRect = firstInfo->lineRect;

      if (redrawLineRange.length > 1)
	  displayRect = NSUnionRect(displayRect,
				    [[_lineLayoutInformation
					 objectAtIndex: 
					     (int)NSMaxRange(redrawLineRange) - 1] lineRect]);

      displayRect.size.width = width - displayRect.origin.x;
      [[self firstTextView] setNeedsDisplayInRect: displayRect];
    }


  // clean up the remaining area below the text
    {
      NSRect myFrame = [self frame];
      float lowestY = 0;

      if ([_lineLayoutInformation count])
	lowestY = NSMaxY ([[_lineLayoutInformation lastObject] lineRect]);

      if (![_lineLayoutInformation count]
	  || (lowestY < NSMaxY(myFrame)))
	{
	  [[self firstTextView] setNeedsDisplayInRect: NSMakeRect(0, lowestY,
								  width, NSMaxY(myFrame) - lowestY)];
	}
    }

}

- (BOOL) _relocLayoutArray: (NSMutableArray*)ghostArray
		    offset: (int)relocOffset
		    floatTrift: (float*)yDisplacement
{
  _GNULineLayoutInfo *lastInfo = [_lineLayoutInformation lastObject];
  // The start character in the ghostArray
  unsigned nextChar = NSMaxRange(lastInfo->lineRange) - relocOffset;
  NSEnumerator *relocEnum;
  _GNULineLayoutInfo *currReloc = nil;
  float yReloc;

  while ([ghostArray count])
    {
      unsigned firstChar;
      
      currReloc = [ghostArray objectAtIndex: 0];
      firstChar =  currReloc->lineRange.location;
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
  yReloc = NSMaxY(lastInfo->lineRect) - currReloc->lineRect.origin.y;
  if (yDisplacement)
    *yDisplacement = yReloc;

  while ((currReloc = [relocEnum nextObject]) != nil)
    {
      currReloc->lineRange.location += relocOffset;
      if (yReloc)
	{
	  currReloc->lineRect.origin.y += yReloc;
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

// begin: central line formatting method---------------------------------------
// returns count of lines actually updated
- (NSRange) rebuildForRange: (NSRange)aRange
		  delta: (int)insertionDelta
{
  int aLine = 0;
  NSPoint drawingPoint = NSZeroPoint;
  float	maxWidth = [self maxWidth];
  float	width = [self width];
  unsigned startingIndex = 0;
  unsigned currentLineIndex;
  // for optimization detection
  NSMutableArray *ghostArray;
  NSString *allText = [_textStorage string];
  unsigned length = [allText length];
  unsigned paraPos;

  // sanity check that it is possible to do the layout
  if (maxWidth == 0.0)
    {
      NSLog(@"NSText formatting with empty frame");
      return NSMakeRange(0,0);
    }

  if (_lineLayoutInformation == nil)
    {
      _lineLayoutInformation = [[NSMutableArray alloc] init];
      aLine = 0;
      ghostArray = nil;
    }
  else
    {
      int insertionLineIndex = [self lineLayoutIndexForGlyphIndex: 
					 aRange.location];
      int nextLine = [self lineLayoutIndexForGlyphIndex: 
				     NSMaxRange(aRange)] + 1;
      int maxLines = [_lineLayoutInformation count];

      aLine = MAX(0, insertionLineIndex - 1);

      if (nextLine < maxLines)
        {
	  // remember old array for optimization purposes
	  ghostArray = AUTORELEASE([[_lineLayoutInformation
					subarrayWithRange:
					    NSMakeRange (nextLine, 
							 maxLines - nextLine)]
				       mutableCopy]);
	}
      else
        {
          ghostArray = nil;
	}

      if (aLine)
	{
	  _GNULineLayoutInfo *lastValidLineInfo = [_lineLayoutInformation 
						      objectAtIndex: aLine - 1];
	  NSRect aRect = lastValidLineInfo->lineRect;

	  startingIndex = NSMaxRange(lastValidLineInfo->lineRange);
	  drawingPoint = aRect.origin;
	  drawingPoint.y += aRect.size.height;

	  // keep paragraph - terminating space on same line as paragraph
	  if ((((int)[_lineLayoutInformation count]) - 1) >= aLine)
	    {
	      _GNULineLayoutInfo *anchorLine
		= [_lineLayoutInformation objectAtIndex: aLine];
	      NSRect anchorRect = anchorLine->lineRect;

	      if (anchorRect.origin.x > drawingPoint.x
		  && aRect.origin.y == anchorRect.origin.y)
		{
		  drawingPoint = anchorRect.origin;
		}
	    }
	}

      [_lineLayoutInformation removeObjectsInRange:
	  NSMakeRange (aLine, [_lineLayoutInformation count] - aLine)];
    }

  if (!length)
    {
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

      // Determine the range of the next paragraph of text (in 'para') and set
      // 'paraPos' to point after the terminating newline character (if any).
      para = NSMakeRange(paraPos, length - paraPos);
      eol = [allText rangeOfCharacterFromSet: newlines
				     options: NSLiteralSearch
				       range: para];

      if (eol.length == 0)
	eol.location = length;
      else
	para.length = eol.location - para.location;
      paraPos = NSMaxRange(eol);
      position = para.location;

      paragraph = [allText substringWithRange: para];
      lScanner = [NSScanner scannerWithString: paragraph];
      [lScanner setCharactersToBeSkipped: nil];

      do
	{
	  NSRect currentLineRect = NSMakeRect (0, drawingPoint.y, 0, 0);
	  NSRange currentLineRange;
	  // starts with zero, do not confuse with startingLineCharIndex
	  unsigned localLineStartIndex = [lScanner scanLocation];
	  unsigned scannerPosition = localLineStartIndex;

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
		currentStringRange = NSUnionRange(leadingSpacesRange,
						   currentStringRange);
	      if (trailingSpacesRange.length)
		currentStringRange = NSUnionRange(trailingSpacesRange,
						   currentStringRange);

	      // evaluate size of current word and line so far
	      advanceSize = [self _sizeOfRange:
				    NSMakeRange (currentStringRange.location + position,
						 currentStringRange.length)];

	      // handle case where single word is broader than width
	      // (buckle word) <!> unfinished and untested
	      // for richText (absolute position see above)
	      if (advanceSize.width > maxWidth)
		{
		  if (isBuckled)
		    {
		      NSSize currentSize = NSMakeSize (HUGE, 0);
		      unsigned lastVisibleCharIndex;

		      for (lastVisibleCharIndex  =  currentStringRange.length;
			   currentSize.width >= maxWidth && lastVisibleCharIndex;
			   lastVisibleCharIndex--)
			{
			  currentSize = [self _sizeOfRange: NSMakeRange(
			      startingLineCharIndex, lastVisibleCharIndex)];
			}
		      isBuckled = NO;
		      currentLineRect.size = currentSize;
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
		isBuckled = NO;

	      // line to long
	      if (currentLineRect.size.width + advanceSize.width > maxWidth || 
		  isBuckled)
	        {
		  // end of line -> word wrap
		  // undo layout of last word
		  [lScanner setScanLocation: scannerPosition];
		  break;
		}

	      // Add next word
	      currentLineRect = NSUnionRect (currentLineRect,
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
		  currentLineRect.size.width += 1;
		  // FIXME: This should use the real font size!!
		  if (!currentLineRect.size.height)
		      currentLineRect.size.height = 12;
		}
	    }

	  currentLineRange = NSMakeRange (startingLineCharIndex,
					  scannerPosition - localLineStartIndex);
	  [self setLineFragmentRect: currentLineRect
		forGlyphRange: currentLineRange
		usedRect: currentLineRect];
	  currentLineIndex++;
	  startingLineCharIndex = NSMaxRange(currentLineRange);
	  drawingPoint.y += currentLineRect.size.height;
	  drawingPoint.x = 0;
	  
	  if (ghostArray != nil)
	    {
	      float yDisplacement = 0;

	      // is it possible to simply patch layout changes
	      // into layout array instead of doing a time
	      // consuming re - layout of the whole doc?
	      if ([self _relocLayoutArray: ghostArray
			offset: insertionDelta
			floatTrift: &yDisplacement])
	        {
		  unsigned erg;
		  
		  // y displacement: redisplay all remaining lines
		  if (yDisplacement)
		      erg = [_lineLayoutInformation count] - aLine;
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
// end: central line formatting method------------------------------------

@end
