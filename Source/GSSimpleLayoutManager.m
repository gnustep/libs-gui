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

// toDo: 
//	 - formatting routine: broader than 1.5x width cause display problems
//	 - optimization: 1.deletion of single char in paragraph [opti hook 1]
//	 - optimization: 2.newline in first line
//	 - optimization: 3.paragraph made one less line due to delition
//                         of single char [opti hook 1; diff from 1.]

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

#define HUGE 1e99

static NSCharacterSet *selectionWordGranularitySet;
static NSCharacterSet *selectionParagraphGranularitySet;
static NSCharacterSet *invSelectionWordGranularitySet;
static NSCharacterSet *invSelectionParagraphGranularitySet;

@interface _GNULineLayoutInfo: NSObject
{
@public
  NSRange	lineRange;
  NSRect	lineRect;
  unsigned	type;
}

typedef enum
{
  // do not use 0 in order to secure calls to nil (calls to nil return 0)!
  LineLayoutInfoType_Text = 1,
  LineLayoutInfoType_Paragraph = 2
} _GNULineLayoutInfo_t;

+ (id) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		      type: (unsigned)aType;

- (NSRange) lineRange;
- (NSRect) lineRect;
- (unsigned) type;

- (void) setLineRange: (NSRange)aRange;
- (void) setLineRect: (NSRect)aRect;
- (void) setType: (unsigned)aType;

- (NSString*) description;
@end

@implementation _GNULineLayoutInfo

+ (_GNULineLayoutInfo *) lineLayoutWithRange: (NSRange)aRange
		      rect: (NSRect)aRect
		      type: (unsigned)aType
{
  _GNULineLayoutInfo *ret = AUTORELEASE([_GNULineLayoutInfo new]);

  ret->lineRange = aRange;
  ret->lineRect =aRect;
  ret->type = aType;
  return ret;
}

- (unsigned) type
{
  return type;
}

- (NSRange) lineRange
{
  return lineRange;
}

- (NSRect) lineRect
{
  return lineRect;
}

- (void) setLineRange: (NSRange)aRange
{
  lineRange = aRange;
}

- (void) setLineRect: (NSRect)aRect
{
  lineRect = aRect;
}

- (void) setType: (unsigned)aType
{
  type = aType;
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

@interface _GNUSeekableArrayEnumerator: NSObject
{
  unsigned	currentIndex;
  NSArray	*array;
}
- (id) initWithArray: (NSArray*)anArray;
- (id) nextObject;
- (id) previousObject;
- (id) currentObject;
@end

@implementation _GNUSeekableArrayEnumerator

- (id) initWithArray: (NSArray*)anArray
{
  self = [super init];
  array = RETAIN(anArray);
  return self;
}

- (id) nextObject
{
  if (currentIndex >= [array count])
    return nil;
  return [array objectAtIndex: currentIndex++];
}

- (id) previousObject
{
  if (currentIndex == 0)
    return nil;
  return [array objectAtIndex: --currentIndex];
}

- (id) currentObject
{
  return [array objectAtIndex: currentIndex];
}

- (void) dealloc
{
  RELEASE(array);
  [super dealloc];
}
@end

@interface NSArray(SeekableEnumerator)
- (_GNUSeekableArrayEnumerator*) seekableEnumerator;
@end
@implementation NSArray(SeekableEnumerator)
- (_GNUSeekableArrayEnumerator*) seekableEnumerator
{
  return AUTORELEASE([[_GNUSeekableArrayEnumerator alloc] initWithArray: self]);
}
@end


@interface GSSimpleLayoutManager (Private)

+ (void) setSelectionWordGranularitySet: (NSCharacterSet*)aSet;
+ (void) setSelectionParagraphGranularitySet: (NSCharacterSet*)aSet;

- (NSRect) rectForCharacterIndex: (unsigned) index;
- (NSRange) characterRangeForBoundingRect: (NSRect)bounds;
- (NSRange) lineRangeForRect: (NSRect) aRect;
- (NSSize) _sizeOfRange: (NSRange) range;
- (float) width;
- (float) maxWidth;

// return value is identical to the real line number
// (plus counted newline characters)
- (int) lineLayoutIndexForCharacterIndex: (unsigned) anIndex;
// returns the full character range for a line range
- (NSRange) characterRangeForLineLayoutRange: (NSRange) aRange;
- (unsigned) lineLayoutIndexForPoint: (NSPoint)point;

- (void) setNeedsDisplayForLineRange: (NSRange) redrawLineRange;
// override for special layout of text
- (NSRange) rebuildForRange: (NSRange)aRange
		  delta: (int)insertionDelta;
// low level, override but never invoke (use setNeedsDisplayForLineRange:)
- (void) drawLinesInLineRange: (NSRange)aRange;
- (NSRange) drawRectCharacters: (NSRect)rect;
- (void) drawSelectionAsRangeNoCaret: (NSRange)aRange;
@end

@implementation GSSimpleLayoutManager

+ (void) initialize
{
      [self setSelectionWordGranularitySet:
	      [NSCharacterSet whitespaceCharacterSet]];
      [self setSelectionParagraphGranularitySet:
	      [NSCharacterSet characterSetWithCharactersInString:
				[[NSText class] newlineString]]];
}


- (void) setTextStorage: (NSTextStorage*)aTextStorage
{
  RELEASE(lineLayoutInformation);
  lineLayoutInformation = nil;

  [super setTextStorage: aTextStorage];
}

// Currently gyphIndex is the same as character index
- (unsigned)characterIndexForGlyphAtIndex:(unsigned)glyphIndex
{
  return glyphIndex;
}

- (NSRange)characterRangeForGlyphRange:(NSRange)glyphRange 
		      actualGlyphRange:(NSRange*)actualGlyphRange
{
  if (actualGlyphRange != NULL)
    *actualGlyphRange = glyphRange;

  return glyphRange;
}

- (NSRange)glyphRangeForCharacterRange:(NSRange)charRange 
		  actualCharacterRange:(NSRange *)actualCharRange
{
  if (actualCharRange != NULL)
    *actualCharRange = charRange;

  return charRange;
}

// Returns the currently used bounds for all the text
- (NSRect)usedRectForTextContainer:(NSTextContainer *)aTextContainer
{
  if ([lineLayoutInformation count])
    {
      NSEnumerator *lineEnum;
      _GNULineLayoutInfo *currentInfo;
      NSRect retRect = NSMakeRect (0, 0, 0, 0);

      for ((lineEnum = [lineLayoutInformation objectEnumerator]);
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
  _GNULineLayoutInfo *currentInfo = [lineLayoutInformation 
				      objectAtIndex: 
					[self lineLayoutIndexForPoint: point]];
  NSRect rect = currentInfo->lineRect;
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
    
  currentInfo = [lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForCharacterIndex: 
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

  if (![_textStorage length])
    {
      return NSMakePoint(0, 0);
    }
    
  currentInfo = [lineLayoutInformation 
		    objectAtIndex: [self lineLayoutIndexForCharacterIndex: 
					     index]];
  if (index >= NSMaxRange(currentInfo->lineRange))
    return NSMakePoint(currentInfo->lineRect.size.width, 0);

  start = currentInfo->lineRange.location;
  x = [self _sizeOfRange: NSMakeRange(start, index-start)].width;

  return NSMakePoint(x, 0);
}

- (NSRect)boundingRectForGlyphRange:(NSRange)aRange 
		    inTextContainer:(NSTextContainer *)aTextContainer;
{
  float width = [self width];
  _GNULineLayoutInfo *currentInfo;
  unsigned i1, i2;
  NSRect rect1;

  if (![_textStorage length])
    {
      return NSMakeRect(0, 0, width, 12);
    }

  i1 = [self lineLayoutIndexForCharacterIndex: aRange.location];
  i2 = [self lineLayoutIndexForCharacterIndex: NSMaxRange(aRange)];

  // This is not exacty what we need, but should be correct enought
  currentInfo = [lineLayoutInformation objectAtIndex: i1];
  rect1 = currentInfo->lineRect;

  if (i1 != i2)
    {
      currentInfo = [lineLayoutInformation objectAtIndex: i2];
      rect1 = NSUnionRect(rect1, currentInfo->lineRect);
    }

  rect1.size.width = width - rect1.origin.x;
  return rect1;
}

- (NSRange)glyphRangeForBoundingRect:(NSRect)aRect 
		     inTextContainer:(NSTextContainer *)aTextContainer
{
  NSRange aRange = [self lineRangeForRect: aRect];

  return [self characterRangeForLineLayoutRange: aRange];    
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
      float width = [self width];

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

- (void) textContainerChangedGeometry: (NSTextContainer*)aContainer
{
  NSRange lineRange;

  RELEASE(lineLayoutInformation);
  lineLayoutInformation = nil;

  lineRange = [self rebuildForRange: NSMakeRange(0, [_textStorage length])
		delta: 0];
  [self setNeedsDisplayForLineRange: lineRange];
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
  NSRect rect = [self boundingRectForGlyphRange: glyphRange 
		      inTextContainer: nil];

  // clear area under text
  [[[self firstTextView] backgroundColor] set];
  NSRectFill(rect);
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange 
			atPoint:(NSPoint)containerOrigin
{
  NSRange newRange;
  NSRange selectedRange = [[self firstTextView] selectedRange];
  unsigned start = [self lineLayoutIndexForCharacterIndex: glyphRange.location];
  unsigned end = [self lineLayoutIndexForCharacterIndex: NSMaxRange(glyphRange)];
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

@end

@implementation GSSimpleLayoutManager (Private)

+ (void) setSelectionWordGranularitySet: (NSCharacterSet*) aSet
{
  ASSIGN(selectionWordGranularitySet, aSet);
  ASSIGN(invSelectionWordGranularitySet, [aSet invertedSet]);
}

+ (void) setSelectionParagraphGranularitySet: (NSCharacterSet*) aSet
{
  ASSIGN(selectionParagraphGranularitySet, aSet);
  ASSIGN(invSelectionParagraphGranularitySet, [aSet invertedSet]);
}

- (NSSize) _sizeOfRange: (NSRange)aRange
{
  if (!aRange.length || _textStorage == nil ||
      NSMaxRange(aRange) > [_textStorage length])
    return NSZeroSize;

  return [[_textStorage attributedSubstringFromRange: aRange] size];
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
  int max = MAX(0, [lineLayoutInformation count] - 1);
  float y = point.y;
  float fmin = NSMinY([[lineLayoutInformation objectAtIndex: 0] lineRect]);
  float fmax = NSMaxY([[lineLayoutInformation lastObject] lineRect]);
  NSRect rect;

  if (y >= fmax)
    return max;

  if (y <= fmin)
    return min;

  // this should give a good starting index for binary search
  i = (int)((max - min) * (y - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      _GNULineLayoutInfo *ci = [lineLayoutInformation objectAtIndex: i];

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

      // As the newline char generates its own lineLayoutinfo box
      // there may be two in one line, we have to check for this
      if ((NSMinX(rect) > point.x)  && (i > 0) &&
	  (ci->type == LineLayoutInfoType_Paragraph))
	{
	  _GNULineLayoutInfo *bi = [lineLayoutInformation objectAtIndex: i - 1];
	  rect = bi->lineRect;
	  if (NSPointInRect(point, rect))
	    return i - 1;
	}
      if ((NSMaxX(rect) < point.x) && (i < [lineLayoutInformation count] - 1) &&
	  (ci->type == LineLayoutInfoType_Text))
	{
	  _GNULineLayoutInfo *bi = [lineLayoutInformation objectAtIndex: i + 1];
	  rect = bi->lineRect;
	  if (NSPointInRect(point, rect))
	    return i + 1;
	}
 
      return i;
    }
  return min;
}

- (int) lineLayoutIndexForCharacterIndex: (unsigned)anIndex
{
  int i;
  int min = 0;
  int max = MAX(0, [lineLayoutInformation count] - 1);
  unsigned y = anIndex;
  unsigned fmin = [[lineLayoutInformation objectAtIndex: 0] lineRange].location;
  unsigned fmax = NSMaxRange([[lineLayoutInformation lastObject] lineRange]);
  NSRange range;

  if (y >= fmax)
    return max;

  if (y <= fmin)
    return min;

  // this should give a good starting index for binary search
  i = (int)((max - min) * (y - fmin) / (fmax - fmin)) + min;
  while (min < max)
    {
      _GNULineLayoutInfo *ci = [lineLayoutInformation objectAtIndex: i];

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

- (NSRange) characterRangeForLineLayoutRange: (NSRange)aRange;
{
  _GNULineLayoutInfo	*currentInfo;
  unsigned startLine = aRange.location;
  unsigned endLine = NSMaxRange(aRange);
  unsigned startIndex;
  unsigned endIndex;

  if (startLine >= [lineLayoutInformation count])
    currentInfo = [lineLayoutInformation lastObject];
  else
    currentInfo = [lineLayoutInformation objectAtIndex: startLine];
  startIndex = currentInfo->lineRange.location;

  if (endLine >= [lineLayoutInformation count])
    currentInfo = [lineLayoutInformation lastObject];
  else
    currentInfo = [lineLayoutInformation objectAtIndex: endLine];
  endIndex = NSMaxRange(currentInfo->lineRange);

  return NSMakeRange(startIndex, endIndex - startIndex);
}

- (NSRange) characterRangeForBoundingRect: (NSRect)boundsRect
{
  NSRange lineRange = [self lineRangeForRect: boundsRect];

  if (lineRange.length)
    return [self characterRangeForLineLayoutRange: lineRange];
  else
    return NSMakeRange (0, 0);
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

  currentInfo = [lineLayoutInformation lastObject];
  if (index >= NSMaxRange(currentInfo->lineRange))
    {
      NSRect rect = currentInfo->lineRect;
      if (NSMaxX(rect) >= width)
	{
	  return NSMakeRect(0, NSMaxY(rect),
			    width, rect.size.height);
	}
      return NSMakeRect(NSMaxX (rect), rect.origin.y,
			width - NSMaxX (rect),
			rect.size.height);
    }


 currentInfo = [lineLayoutInformation 
		   objectAtIndex: [self lineLayoutIndexForCharacterIndex: 
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
			inTextContainer: nil
			rectCount: &count];

  for (i = 0; i < count; i++)
    {
	NSHighlightRect(rects[i]);
    }
}

// Draws the lines in the given rectangle and hands back the drawn 
// character range.
- (NSRange) drawRectCharacters: (NSRect)rect
{
  NSRange aRange = [self lineRangeForRect: rect];

  [self drawLinesInLineRange: aRange];
  return [self characterRangeForLineLayoutRange: aRange];
}

- (NSRange) lineRangeForRect: (NSRect)rect
{
  NSPoint upperLeftPoint = rect.origin;
  NSPoint lowerRightPoint = NSMakePoint (NSMaxX (rect), NSMaxY (rect));
  unsigned startLine, endLine;

  startLine = [self lineLayoutIndexForPoint: upperLeftPoint];
  endLine = [self lineLayoutIndexForPoint: lowerRightPoint];
  if (++endLine > [lineLayoutInformation count])
    endLine = [lineLayoutInformation count];

  return NSMakeRange(startLine, endLine - startLine);
}

// relies on lineLayoutInformation
- (void) drawLinesInLineRange: (NSRange)aRange;
{
  NSArray *linesToDraw = [lineLayoutInformation subarrayWithRange: aRange];
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;

  for ((lineEnum = [linesToDraw objectEnumerator]);
       (currentInfo = [lineEnum nextObject]);)
    {
      if (currentInfo->type == LineLayoutInfoType_Paragraph)
	continue;	// e.g. for nl

      [_textStorage drawRange: currentInfo->lineRange
		    atPoint: currentInfo->lineRect.origin];
	  // <!> make this use drawRange: inRect: in the future
	  // (for proper adoption of layout information [e.g. centering])
    }
}

- (void) setNeedsDisplayForLineRange: (NSRange)redrawLineRange
{
  float width = [self width];

  if ([lineLayoutInformation count]
      && redrawLineRange.location < [lineLayoutInformation count]
      && redrawLineRange.length)
    {
      _GNULineLayoutInfo *firstInfo
	= [lineLayoutInformation objectAtIndex: redrawLineRange.location];
      NSRect displayRect = firstInfo->lineRect;

      if (firstInfo->type  == LineLayoutInfoType_Paragraph
	  && displayRect.origin.x >0 && redrawLineRange.location)
      {
	displayRect = [[lineLayoutInformation objectAtIndex: redrawLineRange.location-1] 
			  lineRect];
      }

      if (redrawLineRange.length > 1)
	  displayRect = NSUnionRect(displayRect,
				    [[lineLayoutInformation
					 objectAtIndex: 
					     (int)NSMaxRange(redrawLineRange) - 1] lineRect]);

      displayRect.size.width = width - displayRect.origin.x;
      [[self firstTextView] setNeedsDisplayInRect: displayRect];
    }


  // clean up the remaining area below the text
    {
      NSRect myFrame = [self frame];
      float lowestY = 0;

      if ([lineLayoutInformation count])
	lowestY = NSMaxY ([[lineLayoutInformation lastObject] lineRect]);

      if (![lineLayoutInformation count]
	  || (lowestY < NSMaxY(myFrame)))
	{
	  [[self firstTextView] setNeedsDisplayInRect: NSMakeRect(0, lowestY,
								  width, NSMaxY(myFrame) - lowestY)];
	}
    }

}

// internal method <!> range is currently not passed as absolute
- (void) addNewlines: (NSRange)aRange
     intoLayoutArray: (NSMutableArray*)anArray
	     atPoint: (NSPoint*)aPointP
	       width: (float)width
      characterIndex: (unsigned)startingLineCharIndex
     ghostEnumerator: (_GNUSeekableArrayEnumerator*)prevArrayEnum
	    didShift: (BOOL*)didShift
verticalDisplacement: (float*)verticalDisplacement
{
  NSSize advanceSize = [self _sizeOfRange:
			       NSMakeRange (startingLineCharIndex, 1)];
  int count = aRange.length;
  int charIndex;
  _GNULineLayoutInfo *ghostInfo = nil;

  (*didShift) = NO;

  for (charIndex = aRange.location; --count >= 0; charIndex++)
    {
      [anArray addObject:
		 [_GNULineLayoutInfo
		   lineLayoutWithRange:
		     NSMakeRange (startingLineCharIndex, 1)
		   rect: NSMakeRect (aPointP->x, aPointP->y,
				     width - aPointP->x, advanceSize.height)
		   type: LineLayoutInfoType_Paragraph]];

      startingLineCharIndex++;
      aPointP->x = 0;
      aPointP->y += advanceSize.height;

      if ((prevArrayEnum != nil) && !(ghostInfo = [prevArrayEnum nextObject]))
	prevArrayEnum = nil;

      if ((ghostInfo != nil) && (ghostInfo->type != LineLayoutInfoType_Paragraph))
	{
	  _GNULineLayoutInfo *prevInfo = [prevArrayEnum previousObject];
	  prevArrayEnum = nil;
	  (*didShift) = YES;
	  if (prevInfo != nil)
	    (*verticalDisplacement) += aPointP->y - prevInfo->lineRect.origin.y;
	}
    }
}

// private helper function
- (unsigned) _relocLayoutArray: (NSArray*)ghostArray
			atLine: (int) aLine
			offset: (int) relocOffset
		     lineTrift: (int) rebuildLineDrift
		    floatTrift: (float) yReloc
{
  // lines actually updated (optimized drawing)
  unsigned ret = [lineLayoutInformation count] - aLine;
  unsigned start = MAX(0, ret + rebuildLineDrift);
  NSArray *relocArray = [ghostArray subarrayWithRange: 
					NSMakeRange(start, [ghostArray count] - start)];
  NSEnumerator *relocEnum;
  _GNULineLayoutInfo *currReloc;

  if (![relocArray count])
    return ret;

  for ((relocEnum = [relocArray objectEnumerator]);
       (currReloc = [relocEnum nextObject]);)
    {
      NSRange range = currReloc->lineRange;
      [currReloc setLineRange: NSMakeRange (range.location + relocOffset,
					    range.length)];
      if (yReloc)
	{
	  NSRect rect = currReloc->lineRect;
	  [currReloc setLineRect: NSMakeRect (rect.origin.x,
					      rect.origin.y + yReloc,
					      rect.size.width,
					      rect.size.height)];
	}
    }
  [lineLayoutInformation addObjectsFromArray: relocArray];
  return ret;
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
// <!> detachNewThreadSelector: selector toTarget: target withObject: argument;

- (NSRange) rebuildForRange: (NSRange)aRange
		  delta: (int)insertionDelta
{
  int aLine = 0;
  int insertionLineIndex = 0;
  //unsigned oldMax = NSMaxRange(aRange);
  //unsigned newMax = oldMax + insertionDelta;
  NSPoint drawingPoint = NSZeroPoint;
  NSScanner *pScanner;
  float	maxWidth = [self maxWidth];
  float	width = [self width];
  unsigned startingIndex = 0;
  unsigned currentLineIndex;
  // for optimization detection
  NSArray *ghostArray;
  _GNUSeekableArrayEnumerator *prevArrayEnum;
  NSString *parsedString;
  int lineDriftOffset = 0, rebuildLineDrift = 0;
  BOOL frameshiftCorrection = NO, nlDidShift = NO;
  float	yDisplacement = 0;

  // sanity check that it is possible to do the layout
  if (maxWidth == 0.0)
    {
      NSLog(@"NSText formatting with empty frame");
      return NSMakeRange(0,0);
    }

  if (lineLayoutInformation == nil)
    {
      lineLayoutInformation = [[NSMutableArray alloc] init];
      aLine = 0;
      ghostArray = nil;
      prevArrayEnum = nil;
    }
  else
    {
      insertionLineIndex = [self lineLayoutIndexForCharacterIndex: 
				     aRange.location];
      aLine = MAX(0, insertionLineIndex - 1);

      if (NSMaxRange(aRange) < NSMaxRange([[lineLayoutInformation lastObject] lineRange]))
        {
	  // remember old array for optimization purposes
	  ghostArray = [lineLayoutInformation
			   subarrayWithRange:
			       NSMakeRange (aLine, [lineLayoutInformation count] - aLine)];
	  // every time an object is added to lineLayoutInformation
	  // a nextObject has to be performed on prevArrayEnum!
	  prevArrayEnum = [ghostArray seekableEnumerator];
	}
      else
        {
          ghostArray = nil;
	  prevArrayEnum = nil;
	}

      if (aLine)
	{
	  _GNULineLayoutInfo *lastValidLineInfo = [lineLayoutInformation 
						      objectAtIndex: aLine - 1];
	  NSRect aRect = lastValidLineInfo->lineRect;

	  startingIndex = NSMaxRange(lastValidLineInfo->lineRange);
	  drawingPoint = aRect.origin;
	  drawingPoint.y += aRect.size.height;
	  if (lastValidLineInfo->type == LineLayoutInfoType_Paragraph)
	    {
	      drawingPoint.x = 0;
	    }

	  // keep paragraph - terminating space on same line as paragraph
	  if ((((int)[lineLayoutInformation count]) - 1) >= aLine)
	    {
	      _GNULineLayoutInfo *anchorLine
		= [lineLayoutInformation objectAtIndex: aLine];
	      NSRect anchorRect = anchorLine->lineRect;

	      if (anchorRect.origin.x > drawingPoint.x
		  && aRect.origin.y == anchorRect.origin.y)
		{
		  drawingPoint = anchorRect.origin;
		}
	    }
	}

      [lineLayoutInformation
	removeObjectsInRange:
	  NSMakeRange (aLine, [lineLayoutInformation count] - aLine)];
    }

  if (![_textStorage length])
    {
	// If there is no text add one empty box
	[lineLayoutInformation
	    addObject: [_GNULineLayoutInfo
			   lineLayoutWithRange: NSMakeRange (0, 0)
			   rect: NSMakeRect (0, 0, 0, 12)
			   type: LineLayoutInfoType_Text]];
	return NSMakeRange(0,1);
    }
      

  currentLineIndex = aLine;

  // each paragraph
  parsedString = [[_textStorage string] substringFromIndex: startingIndex];
  pScanner = [NSScanner scannerWithString: parsedString];
  [pScanner setCharactersToBeSkipped: nil];
  while ([pScanner isAtEnd] == NO)
    {
      NSScanner	*lScanner;
      NSString	*paragraph;
      NSRange	paragraphRange, leadingNlRange, trailingNlRange;
      unsigned	currentLoc = [pScanner scanLocation];
      unsigned	startingParagraphIndex = currentLoc + startingIndex;
      unsigned	startingLineCharIndex = startingParagraphIndex;
      BOOL	isBuckled = NO, inBuckling = NO;

      leadingNlRange
	= scanRange(pScanner, selectionParagraphGranularitySet);
      if (leadingNlRange.length > 0)
	{
	  [self addNewlines: leadingNlRange
	    intoLayoutArray: lineLayoutInformation
		    atPoint: &drawingPoint
		      width: width
	     characterIndex: startingLineCharIndex
	    ghostEnumerator: prevArrayEnum
		   didShift: &nlDidShift
       verticalDisplacement: &yDisplacement];

	  if (nlDidShift)
	    {
	      if (insertionDelta  == 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift--;
		}
	      else if (insertionDelta  == - 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift++;
		}
	      else nlDidShift = NO;
	    }

	  startingLineCharIndex += leadingNlRange.length;
	  currentLineIndex += leadingNlRange.length;
	}

      // each line
      paragraphRange
	= scanRange(pScanner, invSelectionParagraphGranularitySet);
      paragraph = [parsedString substringWithRange: paragraphRange];
      lScanner = [NSScanner scannerWithString: paragraph];
      [lScanner setCharactersToBeSkipped: nil];
      while ([lScanner isAtEnd] == NO)
	{
	  NSRect	currentLineRect = NSMakeRect (0, drawingPoint.y, 0, 0);
	  // starts with zero, do not confuse with startingLineCharIndex
	  unsigned	localLineStartIndex = [lScanner scanLocation];
	  NSSize	advanceSize = NSZeroSize;

	  // scan the individual words to the end of the line
	  for (; ![lScanner isAtEnd]; drawingPoint.x += advanceSize.width)
	    {
	      NSRange	currentStringRange, trailingSpacesRange;
	      NSRange	leadingSpacesRange;
	      unsigned	scannerPosition = [lScanner scanLocation];

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
				    NSMakeRange (currentStringRange.location +
						 paragraphRange.location +
						 startingIndex,
						 currentStringRange.length)];

	      currentLineRect = NSUnionRect (currentLineRect,
					     NSMakeRect (drawingPoint.x,
							 drawingPoint.y,
							 advanceSize.width,
							 advanceSize.height));

	      // handle case where single word is broader than width
	      // (buckle word) <!> unfinished and untested
	      // for richText (absolute position see above)
	      if (advanceSize.width > maxWidth)
		{
		  if (isBuckled)
		    {
		      NSSize currentSize = NSMakeSize (HUGE, 0);
		      unsigned lastVisibleCharIndex;

		      for (lastVisibleCharIndex
			     = startingLineCharIndex + currentStringRange.length;
			   currentSize.width>= maxWidth
			     && lastVisibleCharIndex> startingLineCharIndex;
			   lastVisibleCharIndex--)
			{
			  currentSize = [self _sizeOfRange: NSMakeRange(
			      startingLineCharIndex, lastVisibleCharIndex-startingLineCharIndex)];
			}
		      isBuckled = NO;
		      inBuckling = YES;
		      scannerPosition
			= localLineStartIndex
			+ (lastVisibleCharIndex - startingLineCharIndex)+1;
		      currentLineRect.size.width = advanceSize.width = maxWidth;
		    }
		  else
		    {
		      // undo layout of extralarge word
		      // (will be done the next line [see above])
		      isBuckled = YES;
		      currentLineRect.size.width -= advanceSize.width;
		    }
		}

	      // end of line -> word wrap

	      // >= : wichtig für abknicken (isBuckled)
	      if (currentLineRect.size.width >= maxWidth || isBuckled)
	        {
		_GNULineLayoutInfo *ghostInfo = nil, *thisInfo;

		// undo layout of last word
		[lScanner setScanLocation: scannerPosition];

		currentLineRect.origin.x = 0;
		currentLineRect.origin.y = drawingPoint.y;
		drawingPoint.y += currentLineRect.size.height;
		drawingPoint.x = 0;

		[lineLayoutInformation
		  addObject: (thisInfo
			      = [_GNULineLayoutInfo
				  lineLayoutWithRange:
				    NSMakeRange (startingLineCharIndex,
						 scannerPosition - localLineStartIndex)
				  rect: currentLineRect
				  type: LineLayoutInfoType_Text])];

		currentLineIndex++;
		startingLineCharIndex = NSMaxRange(thisInfo->lineRange);

		if (prevArrayEnum
		    && !(ghostInfo = [prevArrayEnum nextObject]))
		  prevArrayEnum = nil;

		// optimization stuff
		// (do relayout only as much lines as necessary
		// and patch the rest)---------
		if (ghostInfo)
		  {
		    if (ghostInfo->type != thisInfo->type)
		      {
			// frameshift correction
			frameshiftCorrection = YES;
			if (insertionDelta  == - 1)
			  {
			    // deletition of newline
			    _GNULineLayoutInfo *nextObject;
			    if (!(nextObject = [prevArrayEnum nextObject]))
			      prevArrayEnum = nil;
			    else
			      {
				if (nlDidShift && frameshiftCorrection)
				  {
				    //	frameshiftCorrection = NO;
#if 0
				    NSLog(@"opti hook 1 (preferred)");
#endif
				  }
				else
				  {
				    lineDriftOffset
				      += (thisInfo->lineRange.length
					  - ghostInfo->lineRange.length
					  - nextObject->lineRange.length);
				    yDisplacement
				      += thisInfo->lineRect.origin.y
				      - nextObject->lineRect.origin.y;
				    rebuildLineDrift++;
				  }
			      }
			  }
		      }
		    else
		      lineDriftOffset += (thisInfo->lineRange.length
					  - ghostInfo->lineRange.length);

		    // is it possible to simply patch layout changes
		    // into layout array instead of doing a time
		    // consuming re - layout of the whole doc?
		    if ((currentLineIndex - 1 > insertionLineIndex
			 && !inBuckling && !isBuckled)
			&& (!(lineDriftOffset - insertionDelta)
			    || (nlDidShift && !lineDriftOffset)))
		      {
			unsigned erg =  [self _relocLayoutArray: ghostArray
					      atLine: aLine
					      offset: insertionDelta
					      lineTrift: rebuildLineDrift
					      floatTrift: yDisplacement];

			// y displacement: redisplay all remaining lines
			if (frameshiftCorrection)
			  erg = [lineLayoutInformation count] - aLine;
			else if (currentLineIndex - 1  == insertionLineIndex
				 && ABS(insertionDelta) == 1)
			  {
			    // return 2: redisplay only this and previous line
			    erg = 2;
			  }
#if 0
			NSLog(@"opti for: %d",erg);
#endif
			return NSMakeRange(aLine, MAX(1, erg));
		      }
		  }
		// end: optimization stuff--------------------------
		// -----------------------------------------------
		break;

		// newline - induced premature lineending: flush
	      }
	      else if ([lScanner isAtEnd])
		{
		  _GNULineLayoutInfo *thisInfo;
		  scannerPosition = [lScanner scanLocation];
		  [lineLayoutInformation
		    addObject: (thisInfo
				= [_GNULineLayoutInfo
				    lineLayoutWithRange:
				      NSMakeRange (startingLineCharIndex,
						   scannerPosition - localLineStartIndex)
				    rect: currentLineRect
				    type: LineLayoutInfoType_Text])];
		  currentLineIndex++;
		  startingLineCharIndex = NSMaxRange (thisInfo->lineRange);

		  // check for optimization (lines after paragraph
		  // are unchanged and do not need redisplay/relayout)------
		  if (prevArrayEnum)
		    {
		      _GNULineLayoutInfo *ghostInfo = nil;

		      ghostInfo = [prevArrayEnum nextObject];

		      if (ghostInfo)
			{
			  if (ghostInfo->type != thisInfo->type)
			    {
			      // frameshift correction for inserted newline
			      frameshiftCorrection = YES;

			      if (insertionDelta  == 1)
				{
				  [prevArrayEnum previousObject];
				  lineDriftOffset
				    += (thisInfo->lineRange.length
					- ghostInfo->lineRange.length) + insertionDelta;
				  rebuildLineDrift--;
				  yDisplacement
				    += thisInfo->lineRect.origin.y
				    - ghostInfo->lineRect.origin.y;
				}
			      else if (insertionDelta  == - 1)
				{
				  if (nlDidShift && frameshiftCorrection)
				    {
				      //	frameshiftCorrection = NO;
#if 0
				      NSLog(@"opti hook 2");
#endif
				    }
				}
			    }
			  else
			    lineDriftOffset
			      += (thisInfo->lineRange.length
				  - ghostInfo->lineRange.length);
			}
		      else
			{
			  // new array obviously longer than the previous one
			  prevArrayEnum = nil;
			}
		      // end: optimization stuff------------------------------
		      // -------------------------------------------
		    }
		}
	    }
	}
      // add the trailing newlines of current paragraph if any
      trailingNlRange
	= scanRange(pScanner, selectionParagraphGranularitySet);
      if (trailingNlRange.length)
	{
	  [self addNewlines: trailingNlRange
		intoLayoutArray: lineLayoutInformation
		atPoint: &drawingPoint
		width: width
		characterIndex: startingLineCharIndex
		ghostEnumerator: prevArrayEnum
		didShift: &nlDidShift
		verticalDisplacement: &yDisplacement];
	  if (nlDidShift)
	    {
	      if (insertionDelta == 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift--;
		}
	      else if (insertionDelta == - 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift++;
		}
	      else nlDidShift = NO;
	    }
	  currentLineIndex += trailingNlRange.length;
	}
    }

  // lines actually updated (optimized drawing)
  return NSMakeRange(aLine, MAX(1, [lineLayoutInformation count] - aLine));
}
// end: central line formatting method------------------------------------

@end
