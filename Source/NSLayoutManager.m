/*
   NSLayoutManager.m

   Copyright (C) 1999, 2002, 2003 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: November 2002 - February 2003

   Parts based on the old NSLayoutManager.m:
   Author: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: July 1999
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: August 1999
   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date: January 2001

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

/*
TODO: document exact requirements on typesetting for this class

Roughly:

Line frag rects arranged in lines in which all line frag rects have same
y-origin and height. Lines must not overlap vertically, and must be arranged
with strictly increasing y-origin. Line frag rects go left->right, as do
points inside line frag rects.

"Nominally spaced", to this layout manager, is described at:
http://wiki.gnustep.org/index.php/NominallySpacedGlyphs

Lines are laid out as one unit. Ie. we never do layout for only a part of a
line, or invalidate only some line frags in a line.

Also, we assume that the limit of context on layout is the previous line.
Thus, when we invalidate layout, we invalidate all lines with invalidated
characters, and the line before the first invalidated line, and
soft-invalidate everything after the last invalidated line.

Consider:

|...            |
|foo bar zot    |
|abcdefghij     |
|...            |

If we insert a space between the 'a' and the 'b' in "abcd...", the correct
result is:

|...            |
|foo bar zot a  |
|bcdefghij      |
|...            |

and to get this, we must invalidate the previous line.

TODO: This is an important assumption, and the typesetter needs to make
sure that it holds. I'm not entirely convinced that it holds for standard
latin-text layout, but I haven't been able to come up with any
counter-examples. If it turns out not to hold, we'll have to fix
invalidation here (invalidate the entire paragraph? not good for
performance, but correctness is more important), or change the typesetter
behavior.

Another assumption is that each text container will contain at least one
line frag (unless there are no more glyphs to typeset).



TODO: We often need to deal with the case where a glyph can't be typeset
(because there's nowhere to typeset it, eg. all text containers are full).
Need to figure out how to handle it.


TODO: Don't do linear searches through the line frags if avoidable. Some
cases are considerably more important than others, and should be fixed
first. Remaining cases, highest priority first:

-glyphIndexForPoint:inTextContainer:fractionOfDistanceThroughGlyph:
	Used when selecting with the mouse, and called for every event.

-characterIndexMoving:fromCharacterIndex:originalCharacterIndex:distance:
	Keyboard insertion point movement. Performance isn't important.

*/

#include <math.h>

#include "AppKit/NSLayoutManager.h"
#include "AppKit/GSLayoutManager_internal.h"

#include <Foundation/NSException.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSWindow.h>
#include <AppKit/DPSOperators.h>



@interface NSLayoutManager (layout_helpers)
-(void) _doLayoutToContainer: (int)cindex  point: (NSPoint)p;
@end

@implementation NSLayoutManager (layout_helpers)
-(void) _doLayoutToContainer: (int)cindex  point: (NSPoint)p
{
  [self _doLayout];
}
@end


/* Helper for searching for the line frag of a glyph. */
#define LINEFRAG_FOR_GLYPH(glyph) \
  do { \
    int lo, hi, mid; \
\
    lf = tc->linefrags; \
    for (lo = 0, hi = tc->num_linefrags - 1; lo < hi; ) \
      { \
	mid = (lo + hi) / 2; \
	if (lf[mid].pos > glyph) \
	  hi = mid - 1; \
	else if (lf[mid].pos + lf[mid].length <= glyph) \
	  lo = mid + 1; \
	else \
	  lo = hi = mid; \
      } \
    lf = &lf[lo]; \
    i = lo; \
  } while (0)


@implementation NSLayoutManager (layout)

-(NSPoint) locationForGlyphAtIndex: (unsigned int)glyphIndex
{
  NSRange r;
  NSPoint p;
  NSFont *f;
  unsigned int i;

  r = [self rangeOfNominallySpacedGlyphsContainingIndex: glyphIndex
	    startLocation: &p];
  if (r.location == NSNotFound)
    {
      /* The glyph hasn't been typeset yet, probably because there isn't
      enough space in the text containers to fit it. */
      return NSMakePoint(0, 0);
    }

  i = r.location;
  f = [self effectiveFontForGlyphAtIndex: i
	    range: &r];
  /* TODO: this is rather inefficient and doesn't deal with non-shown
  glyphs */
  for (; i < glyphIndex; i++)
    {
      if (i == r.location + r.length)
	{
	  f = [self effectiveFontForGlyphAtIndex: i
		    range: &r];
	}
      p.x += [f advancementForGlyph: [self glyphAtIndex: i]].width;
    }
  return p;
}


-(void) textContainerChangedTextView: (NSTextContainer *)aContainer
{
/* TODO: what do we do here? invalidate the displayed range for that
container? necessary? */
  int i;

  /* NSTextContainer will send the necessary messages to update the text
  view that was disconnected from us. */
  for (i = 0; i < num_textcontainers; i++)
    {
      [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
      if (textcontainers[i].textContainer == aContainer)
	{
	  [[aContainer textView] setNeedsDisplay: YES];
	}
    }
}


-(NSRect *) rectArrayForGlyphRange: (NSRange)glyphRange
	  withinSelectedGlyphRange: (NSRange)selGlyphRange
		   inTextContainer: (NSTextContainer *)container
			 rectCount: (unsigned int *)rectCount
{
  unsigned int last;
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;
  int num_rects;
  float x0, x1;
  NSRect r;


  *rectCount = 0;

  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
//printf("container %i %@, %i+%i\n",i,tc->textContainer,tc->pos,tc->length);
  [self _doLayoutToGlyph: NSMaxRange(glyphRange) - 1];
//printf("   now %i+%i\n",tc->pos,tc->length);
  if (i == num_textcontainers)
    {
      if (i == num_textcontainers)
	NSLog(@"%s: invalid text container", __PRETTY_FUNCTION__);
      return NULL;
    }

  /* Silently clamp range to the text container.
  TODO: is this good? */
  if (tc->pos > glyphRange.location)
    {
      if (tc->pos > NSMaxRange(glyphRange))
	return NULL;
      glyphRange.length = NSMaxRange(glyphRange) - tc->pos;
      glyphRange.location = tc->pos;
    }

  if (tc->pos + tc->length < NSMaxRange(glyphRange))
    {
      if (tc->pos + tc->length < glyphRange.location)
        return NULL;
      glyphRange.length = tc->pos + tc->length - glyphRange.location;
    }

  if (!glyphRange.length)
    {
      return NULL;
    }

  last = NSMaxRange(glyphRange);

  num_rects = 0;

  LINEFRAG_FOR_GLYPH(glyphRange.location);

  /* Main loop. Work through all line frag rects and build the array of
  rects. */
  while (1)
    {
      /* Determine the starting x-coordinate for this line frag rect. */
      if (lf->pos < glyphRange.location)
	{
	  /*
	  The start index is inside the line frag rect, so we need to
	  search through it to find the exact starting location.
	  */
	  int i, j;
	  linefrag_point_t *lp;
	  glyph_run_t *r;
	  unsigned int gpos, cpos;

	  for (j = 0, lp = lf->points; j < lf->num_points; j++, lp++)
	    if (lp->pos + lp->length > glyphRange.location)
	      break;

	  NSAssert(j < lf->num_points, @"can't find starting point of glyph");

	  x0 = lp->p.x + lf->rect.origin.x;
	  r = run_for_glyph_index(lp->pos, glyphs, &gpos, &cpos);
	  i = lp->pos - gpos;

	  while (i + gpos < glyphRange.location)
	    {
	      if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
		  r->glyphs[i].g != NSControlGlyph)
		{
		  x0 += [r->font advancementForGlyph: r->glyphs[i].g].width;
		}
	      GLYPH_STEP_FORWARD(r, i, gpos, cpos)
	    }
	}
      else
	{
	  /*
	  The start index was before the this line frag, so the starting
	  x-coordinate is the left edge of the line frag.
	  */
	  x0 = NSMinX(lf->rect);
	}

      /* Determine the end x-coordinate for this line frag. */
      if (lf->pos + lf->length > last)
	{
	  /*
	  The end index is inside the line frag, so we need to find the
	  exact end location.
	  */
	  int i, j;
	  linefrag_point_t *lp;
	  glyph_run_t *r;
	  unsigned int gpos, cpos;

	  /*
	  At this point there is a glyph in our range that is in this
	  line frag rect. If we're on the first line frag rect, it's
	  trivially true. If not, the check before the lf++; ensures it.
	  */
	  for (j = 0, lp = lf->points; j < lf->num_points; j++, lp++)
	    if (lp->pos + lp->length > last)
	      break;

	  NSAssert(j < lf->num_points, @"can't find starting point of glyph");

	  x1 = lp->p.x + lf->rect.origin.x;
	  r = run_for_glyph_index(lp->pos, glyphs, &gpos, &cpos);
	  i = lp->pos - gpos;

	  while (i + gpos < last)
	    {
	      if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
		  r->glyphs[i].g != NSControlGlyph)
		{
		  x1 += [r->font advancementForGlyph: r->glyphs[i].g].width;
		}
	      GLYPH_STEP_FORWARD(r, i, gpos, cpos)
	    }
	}
      else
	{
	  /*
	  The range continues beyond the end of the line frag, so the end
	  x-coordinate is the right edge of the line frag.
	  */
	  x1 = NSMaxX(lf->rect);
	}

      /*
      We have the start and end x-coordinates, and use the height of the
      line frag for the y-coordinates.
      */
      r = NSMakeRect(x0, lf->rect.origin.y, x1 - x0, lf->rect.size.height);

      /*
      As an optimization of the rectangle array, we check if the previous
      rectangle had the same x-coordinates as the new rectangle and touches
      it vertically. If so, we combine them.
      */
      if (num_rects &&
	  r.origin.x == rect_array[num_rects - 1].origin.x &&
	  r.size.width == rect_array[num_rects - 1].size.width &&
	  r.origin.y == NSMaxY(rect_array[num_rects - 1]))
	{
	  rect_array[num_rects - 1].size.height += r.size.height;
	}
      else
	{
	  if (num_rects == rect_array_size)
	    {
	      rect_array_size += 4;
	      rect_array = realloc(rect_array, sizeof(NSRect) * rect_array_size);
	    }
	  rect_array[num_rects++] = r;
	}

      if (lf->pos + lf->length >= last)
	break;
      lf++;
    }

  *rectCount = num_rects;
  return rect_array;
}

-(NSRect *) rectArrayForCharacterRange: (NSRange)charRange
	  withinSelectedCharacterRange: (NSRange)selCharRange
		       inTextContainer: (NSTextContainer *)container
			     rectCount: (unsigned int *)rectCount
{
  NSRange r1, r2;

  /* TODO: we can actually do better than this by using the insertion point
  positioning behavior */
  r1 = [self glyphRangeForCharacterRange: charRange
	     actualCharacterRange: NULL];
  r2 = [self glyphRangeForCharacterRange: selCharRange
	     actualCharacterRange: NULL];

  return [self rectArrayForGlyphRange: r1
	       withinSelectedGlyphRange: r2
	       inTextContainer: container
	       rectCount: rectCount];
}

-(NSRect) boundingRectForGlyphRange: (NSRange)glyphRange
		    inTextContainer: (NSTextContainer *)aTextContainer
{
  NSRect *r;
  NSRect result;
  int i, c;

/* TODO: This isn't correct. Need to handle glyphs that extend outside the
line frag rect. */
  r = [self rectArrayForGlyphRange: glyphRange
	    withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0)
	    inTextContainer: aTextContainer
	    rectCount: &c];

  if (!c)
    return NSZeroRect;

  result = r[0];
  for (r++, i = 1; i < c; i++, r++)
    result = NSUnionRect(result, *r);

  return result;
}


-(NSRange) glyphRangeForBoundingRect: (NSRect)bounds
		     inTextContainer: (NSTextContainer *)container
{
  int i, j;
  int low, high, mid;
  textcontainer_t *tc;
  linefrag_t *lf;

  NSRange range;


  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: invalid text container", __PRETTY_FUNCTION__);
      return NSMakeRange(0, 0);
    }

  [self _doLayoutToContainer: i
    point: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];

  tc = textcontainers + i;

  if (!tc->num_linefrags)
    return NSMakeRange(0, 0);


  /* Find first glyph in bounds. */

  /* Find right "line", ie. the first "line" not above bounds. */
  for (low = 0, high = tc->num_linefrags - 1; low < high; )
    {
      mid = (low + high) / 2;
      lf = &tc->linefrags[mid];
      if (NSMaxY(lf->rect) > NSMinY(bounds))
	{
	  high = mid;
	}
      else
	{
	  low = mid + 1;
	}
    }

  i = low;
  lf = &tc->linefrags[i];

  if (NSMaxY(lf->rect) < NSMinY(bounds))
    {
      return NSMakeRange(0, 0);
    }

  /* Scan to first line frag intersecting bounds horizontally. */
  while (i < tc->num_linefrags - 1 &&
	 NSMinY(lf[0].rect) == NSMinY(lf[1].rect) &&
	 NSMaxX(lf[0].rect) < NSMinX(bounds))
    i++, lf++;

  /* TODO: find proper position in line frag rect */
  range.location = lf->pos;


  /* Find last glyph in bounds. */

  /* Find right "line", ie. last "line" not below bounds. */
  for (low = 0, high = tc->num_linefrags - 1; low < high; )
    {
      mid = (low + high) / 2;
      lf = &tc->linefrags[mid];
      if (NSMinY(lf->rect) > NSMaxY(bounds))
	{
	  high = mid;
	}
      else
	{
	  low = mid + 1;
	}
    }
  i = low;
  lf = &tc->linefrags[i];

  if (i && NSMinY(lf->rect) > NSMaxY(bounds))
    i--, lf--;

  if (NSMinY(lf->rect) > NSMaxY(bounds))
    {
      return NSMakeRange(0, 0);
    }

  /* Scan to last line frag intersecting bounds horizontally. */
  while (i > 0 &&
	 NSMinY(lf[0].rect) == NSMinY(lf[-1].rect) &&
	 NSMinX(lf[-1].rect) > NSMaxX(bounds))
    i--, lf--;

  /* TODO: find proper position in line frag rect */

  j = lf->pos + lf->length;
  if (j <= range.location)
    {
      return NSMakeRange(0, 0);
    }

  range.length = j - range.location;
  return range;
}

-(NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
					    inTextContainer: (NSTextContainer *)container
{
  /* TODO: this should be the same as
  -glyphRangeForBoundingRect:inTextContainer: but without the _doLayout...
  call.

  In other words, it returns the range of glyphs in the rect that have
  already been laid out.
  */

  return [self glyphRangeForBoundingRect: bounds
	       inTextContainer: container];
}


-(unsigned int) glyphIndexForPoint: (NSPoint)aPoint
		   inTextContainer: (NSTextContainer *)aTextContainer
{
  return [self glyphIndexForPoint: aPoint
	       inTextContainer: aTextContainer
	       fractionOfDistanceThroughGlyph: NULL];
}

/*
TODO: decide on behavior wrt. invisible glyphs and pointer far away from
anything visible
*/
-(unsigned int) glyphIndexForPoint: (NSPoint)point
		   inTextContainer: (NSTextContainer *)container
    fractionOfDistanceThroughGlyph: (float *)partialFraction
{
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;
  linefrag_point_t *lp;
  float dummy;

  if (!partialFraction)
    partialFraction = &dummy;

  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: invalid text container", __PRETTY_FUNCTION__);
      return -1;
    }

  [self _doLayoutToContainer: i  point: point];

  tc = textcontainers + i;

  /* Find the line frag rect that contains the point, and handle the case
  where the point isn't inside a line frag rect. */
  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    {
      /* The point is inside a rect; we're done. */
      if (NSPointInRect(point, lf->rect))
	break;

      /* If the current line frag rect is below the point, the point must
      be between the line with the current line frag rect and the line
      with the previous line frag rect. */
      if (NSMinY(lf->rect) > point.y)
	{
	  /* If this is not the first line frag rect in the text container,
	  we consider the point to be after the last glyph on the previous
	  line. Otherwise, we consider it to be before the first glyph on
	  the current line. */
	  if (i > 0)
	    {
	      *partialFraction = 1.0;
	      return lf->pos - 1;
	    }
	  else
	    {
	      *partialFraction = 0.0;
	      return lf->pos;
	    }
	}
      /* We know that NSMinY(lf->rect) <= point.y. If the point is on the
      current line and to the left of the current line frag rect, we
      consider the point to be before the first glyph in the current line
      frag rect.

      (This will happen if the point is between two line frag rects, or
      before the first line frag rect. If the point is to the right of the
      current line frag rect, it will be inside a subsequent line frag rect
      on this line, or to the left of one, which will be handled by the here
      or by the first check in the loop, or it will be after all line frag
      rects on the line, which will be detected and handled as a 'between
      two lines' case, or by the 'after all line frags' code below.)
      */
      if (NSMaxY(lf->rect) >= point.y && NSMinX(lf->rect) > point.x)
	{
	  *partialFraction = 0.0;
	  return lf->pos;
	}
    }

  /* Point is after all line frags. */
  if (i == tc->num_linefrags)
    {
      *partialFraction = 1.0;
      return tc->pos + tc->length - 1; /* TODO: this should return the correct thing even if the container is empty */
    }

  /* only interested in x from here on */
  point.x -= lf->rect.origin.x;

  /* scan to the first point beyond the target */
  for (i = 0, lp = lf->points; i < lf->num_points; i++, lp++)
    if (lp->p.x > point.x)
      break;

  if (!i)
    {
      /* Before the first glyph on the line. */
      /* TODO: what if it isn't shown? */
      *partialFraction = 0;
      return lp->pos;
    }
  else
    {
      /* There are points in this line frag before the point we're looking
      for. */
      float cur, prev, next;
      glyph_run_t *r;
      unsigned int glyph_pos, char_pos, last_visible;

      if (i < lf->num_points)
	next = lp->p.x;
      else
	next = NSMinX(lf->rect);

      lp--; /* Valid since we checked for !i above. */
      r = run_for_glyph_index(lp->pos, glyphs, &glyph_pos, &char_pos);

      prev = lp->p.x;

      last_visible = lf->pos;
      for (i = lp->pos - glyph_pos; i + glyph_pos < lp->pos + lp->length; )
	{
	  if (r->glyphs[i].isNotShown || r->glyphs[i].g == NSControlGlyph ||
	      !r->glyphs[i].g)
	    {
	      GLYPH_STEP_FORWARD(r, i, glyph_pos, char_pos)
		continue;
	    }
	  last_visible = i + glyph_pos;

	  cur = prev + [r->font advancementForGlyph: r->glyphs[i].g].width;
	  if (i + glyph_pos + 1 == lp->pos + lp->length && next > cur)
	    cur = next;

	  if (cur >= point.x)
	    {
	      *partialFraction = (point.x - prev) / (cur - prev);
	      if (*partialFraction < 0)
		*partialFraction = 0;
	      return i + glyph_pos;
	    }
	  prev = cur;
	  GLYPH_STEP_FORWARD(r, i, glyph_pos, char_pos)
	}
      *partialFraction = 1;
      return last_visible;
    }
}


/*** Insertion point positioning and movement. ***/

/*
Determines at which glyph, and how far through it, the insertion point
should be placed for a certain character index.
*/
-(unsigned int) _glyphIndexForCharacterIndex: (unsigned int)cindex
			     fractionThrough: (float *)fraction
{
  if (cindex == [[_textStorage string] length])
    {
      *fraction = 0.0;
      return (unsigned int)-1;
    }
  else
    {
      NSRange glyphRange, charRange;
      unsigned int glyph_index;
      float fraction_through;

      glyphRange = [self glyphRangeForCharacterRange: NSMakeRange(cindex, 1)
				actualCharacterRange: &charRange];

      /*
      Deal with composite characters and ligatures.

      We determine how far through the character range this character is a
      part of the character is, and then determine the glyph index and
      fraction that is the same distance through the glyph range it is
      mapped to.

      (This gives good behavior when dealing with ligatures, at least.)

      Eg. if the character index is at character 3 in a 5 character range,
      we are 3/5=0.6 through the entire character range. If this range was
      mapped to 4 glyphs, we get 0.6*4=2.4, so the glyph index is 2 and
      the fraction is 0.4.
      */
      fraction_through = (cindex - charRange.location) / (float)charRange.length;
      fraction_through *= glyphRange.length;

      glyph_index = glyphRange.location + floor(fraction_through);
      fraction_through -= floor(fraction_through);

      *fraction = fraction_through;
      return glyph_index;
    }
}

/*
Note: other methods rely a lot on the fact that the rectangle returned here
has the same y origin and height as the line frag rect it is in.
*/
-(NSRect) _insertionPointRectForCharacterIndex: (unsigned int)cindex
				 textContainer: (int *)textContainer
{
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;
  float x0, x1;
  NSRect r;

  unsigned int glyph_index;
  float fraction_through;


  glyph_index = [self _glyphIndexForCharacterIndex: cindex
				   fractionThrough: &fraction_through];
  if (glyph_index == (unsigned int)-1)
    {
      /* Need complete layout information. */
      [self _doLayout];
      if (extra_textcontainer)
	{
	  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
	    if (tc == textcontainers)
	      break;
	  NSAssert(i < num_textcontainers, @"invalid extraTextContainer");
	  *textContainer = i;
	  r = extra_rect;
	  r.size.width = 1;
	  return r;
	}
      glyph_index = [self numberOfGlyphs] - 1;
      if (glyph_index == (unsigned int)-1)
	{
	  /* No information is available. The best we can do is guess. */

	  /* will be -1 if there are no text containers */
	  *textContainer = num_textcontainers - 1;
	  return NSMakeRect(1, 1, 1, 15);
	}
      fraction_through = 1.0;
    }

  [self _doLayoutToGlyph: glyph_index];
  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > glyph_index)
      break;
  if (i == num_textcontainers)
    {
      *textContainer = -1;
      return NSZeroRect;
    }

  *textContainer = i;

  LINEFRAG_FOR_GLYPH(glyph_index);

  {
    int i, j;
    linefrag_point_t *lp;
    glyph_run_t *r;
    unsigned int gpos, cpos;

    for (j = 0, lp = lf->points; j < lf->num_points; j++, lp++)
      if (lp->pos + lp->length > glyph_index)
	break;

    x0 = lp->p.x + lf->rect.origin.x;
    r = run_for_glyph_index(lp->pos, glyphs, &gpos, &cpos);
    i = lp->pos - gpos;

    while (i + gpos < glyph_index)
      {
	if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
	    r->glyphs[i].g != NSControlGlyph)
	  {
	    x0 += [r->font advancementForGlyph: r->glyphs[i].g].width;
	  }
	GLYPH_STEP_FORWARD(r, i, gpos, cpos)
      }
    x1 = x0;
    if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
	r->glyphs[i].g != NSControlGlyph)
      {
	x1 += [r->font advancementForGlyph: r->glyphs[i].g].width;
      }
  }

  r = lf->rect;
  r.origin.x = x0 + (x1 - x0) * fraction_through;
  r.size.width = 1;

  return r;
}

-(NSRect) insertionPointRectForCharacterIndex: (unsigned int)cindex
			      inTextContainer: (NSTextContainer *)textContainer
{
  int i;
  NSRect r;

  r = [self _insertionPointRectForCharacterIndex: cindex
				   textContainer: &i];
  if (i == -1 || textcontainers[i].textContainer != textContainer)
    return NSZeroRect;

  r.origin.y++;
  r.size.height -= 2;

  return r;
}


-(unsigned int) characterIndexMoving: (GSInsertionPointMovementDirection)direction
		  fromCharacterIndex: (unsigned int)from
	      originalCharacterIndex: (unsigned int)original
			    distance: (float)distance;
{
  NSRect from_rect, new_rect;
  int from_tc, new_tc;
  int i;
  unsigned int new;
  unsigned int length = [_textStorage length];

  /* This call will ensure that layout is built to 'from', and that layout
  for the line 'from' is in is built. */
  from_rect = [self _insertionPointRectForCharacterIndex: from
					   textContainer: &from_tc];
  if (from_tc == -1)
    {
      NSLog(@"%s: character index not in any text container",
	__PRETTY_FUNCTION__);
      return from;
    }

  if (direction == GSInsertionPointMoveLeft ||
      direction == GSInsertionPointMoveRight)
    {
      float target;

      if (distance == 0.0)
	{
	  new = from;
	  if (direction == GSInsertionPointMoveLeft && new > 0)
	    new--;
	  if (direction == GSInsertionPointMoveRight && new < length)
	    new++;

	  [self _insertionPointRectForCharacterIndex: new
				       textContainer: &i];

	/* Don't leave the text container. */
	if (i == from_tc)
	  return new;
	else
	  return from;
	}

      /*
      This is probably very inefficient, but it shouldn't be a bottleneck,
      and it guarantees that insertion point movement matches insertion point
      positioning. It also lets us do this by character instead of by glyph.
      */
      new = from;
      if (direction == GSInsertionPointMoveLeft)
	{
	  target = from_rect.origin.x - distance;
	  while (new > 0)
	    {
	      new_rect = [self _insertionPointRectForCharacterIndex: new - 1
						      textContainer: &new_tc];
	      if (new_tc != from_tc)
		break;
	      if (new_rect.origin.y != from_rect.origin.y)
		break;
	      new--;
	      if (NSMaxX(new_rect) <= target)
		break;
	    }
	  return new;
	}
      else
	{
	  target = from_rect.origin.x + distance;
	  while (new < length)
	    {
	      new_rect = [self _insertionPointRectForCharacterIndex: new + 1
						      textContainer: &new_tc];
	      if (new_tc != from_tc)
		break;
	      if (new_rect.origin.y != from_rect.origin.y)
		break;
	      new++;
	      if (NSMinX(new_rect) >= target)
		break;
	    }
	  return new;
	}
    }

  if (direction == GSInsertionPointMoveUp ||
      direction == GSInsertionPointMoveDown)
    {
      NSRect orig_rect, prev_rect;
      int orig_tc;
      float target;
      textcontainer_t *tc;
      linefrag_t *lf;
      int i;

      orig_rect = [self _insertionPointRectForCharacterIndex: original
					       textContainer: &orig_tc];
      if (orig_tc == from_tc)
	target = orig_rect.origin.x;
      else
	target = from_rect.origin.x;

      tc = &textcontainers[from_tc];
      /* Find first line frag rect on the from line. */
      for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
	{
	  if (lf->rect.origin.y == from_rect.origin.y)
	    break;
	}

      /* If we don't have a line frag rect that matches the from position,
      the from position is probably on the last line, in the extra rect,
      and i == tc->num_linefrags. The movement direction specific code
      handles this case, as long as tc->num_linefrags > 0. */
      if (!tc->num_linefrags)
	return from; /* Impossible? Should be, since from_tc!=-1. */

      if (direction == GSInsertionPointMoveDown)
	{
	  [self _doLayoutToContainer: from_tc
		point: NSMakePoint(target, distance + NSMaxY(from_rect))];
	  tc = textcontainers + from_tc;
	  /* Find the target line. Move at least (should be up to?)
	  distance, and at least one line. */
	  for (; i < tc->num_linefrags; i++, lf++)
	    if (NSMaxY(lf->rect) >= distance + NSMaxY(from_rect) &&
	        NSMinY(lf->rect) != NSMinY(from_rect))
	      break;

	  if (i == tc->num_linefrags)
	    {
	      /* We can't move as far as we want to. In fact, we might not
	      have been able to move at all.
	      TODO: figure out how to handle this
	      */
	      return from;
	    }
	}
      else
	{
	  if (i == tc->num_linefrags)
	    i--, lf--;
	  /* Find the target line. Move at least (should be up to?)
	  distance, and at least one line. */
	  for (; i >= 0; i--, lf--)
	    if (NSMinY(lf->rect) <= NSMinY(from_rect) - distance &&
	        NSMinY(lf->rect) != NSMinY(from_rect))
	      break;
	  /* Now we have the last line frag of the target line. Move
	  backwards to the first one. */
	  for (; i > 0; i--, lf--)
	    if (NSMinY(lf->rect) != NSMinY(lf[-1].rect))
	      break;

	  if (i == -1)
	    {
	      /* We can't move as far as we want to. In fact, we might not
	      have been able to move at all.
	      TODO: figure out how to handle this
	      */
	      return from;
	    }
	}

      /* Now we have the first line frag of the target line and the
      target x position. */
      new = [self characterRangeForGlyphRange: NSMakeRange(lf->pos, 1)
			     actualGlyphRange: NULL].location;

      /* The first character index might not actually be in this line
      rect, so move forwards to the first character in the target line. */
      while (new < length)
	{
	  new_rect = [self _insertionPointRectForCharacterIndex: new + 1
						  textContainer: &new_tc];
	  if (new_tc > from_tc)
	    break;
	  if (new_rect.origin.y >= lf->rect.origin.y)
	    break;
	  new++;
	}

      /* Now find the target character in the line. */
      new_rect = [self _insertionPointRectForCharacterIndex: new
					      textContainer: &new_tc];
      while (new < length)
	{
	  prev_rect = new_rect;
	  new_rect = [self _insertionPointRectForCharacterIndex: new + 1
						  textContainer: &new_tc];
	  if (new_tc != from_tc)
	    break;
	  if (new_rect.origin.y != lf->rect.origin.y)
	    break;
	  if (NSMinX(new_rect) >= target)
	    {
	      /*
	      'new+1' is beyond 'target', so either 'new' or 'new+1' is the
	      character we want. Pick the closest one. (Note that 'new' might
	      also be beyond 'target'.)
	      */
	      if (fabs(NSMinX(new_rect) - target) < fabs(NSMinX(prev_rect) - target))
		new++;
	      return new;
	    }
	  new++;
	}
      return new;
    }

  NSLog(@"(%s): invalid direction %i (distance %g)",
    __PRETTY_FUNCTION__, direction, distance);
  return from;
}



@end




@implementation NSLayoutManager (drawing)


/** Drawing **/

/*
If a range passed to a drawing function isn't contained in the text
container that contains its first glyph, the range is silently clamped.
My thought with this is that the requested glyphs might not fit in the
text container (if it's the last text container, or there's only one).
In that case, it isn't really the caller's fault, and drawing as much as
will fit in the text container makes sense.

TODO: reconsider silently clamping ranges in these methods; might
want to make sure we don't do it if part of the range is in a second
container
*/

-(void) drawBackgroundForGlyphRange: (NSRange)range
			    atPoint: (NSPoint)containerOrigin
{
  NSTextContainer *textContainer;
  glyph_run_t *glyph_run;
  unsigned int glyph_pos, char_pos, first_char_pos;
  int i, j;
  NSRect *rects;
  int count;
  NSColor *color, *last_color;

  NSGraphicsContext *ctxt = GSCurrentContext();


  if (!range.length)
    return;
  [self _doLayoutToGlyph: range.location + range.length - 1];

  {
    int i;
    textcontainer_t *tc;

    for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
      if (tc->pos + tc->length > range.location)
	break;
    if (i == num_textcontainers)
      {
	NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
	return;
      }

    if (range.location + range.length > tc->pos + tc->length)
      range.length = tc->pos + tc->length - range.location;

    textContainer = tc->textContainer;
  }

  glyph_run = run_for_glyph_index(range.location, glyphs, &glyph_pos, &char_pos);
  i = range.location - glyph_pos;
  last_color = nil;
  first_char_pos = char_pos;
  while (1)
    {
      NSRange r = NSMakeRange(glyph_pos + i, glyph_run->head.glyph_length - i);

      if (NSMaxRange(r) > NSMaxRange(range))
	r.length = NSMaxRange(range) - r.location;

      color = [_textStorage attribute: NSBackgroundColorAttributeName
			      atIndex: char_pos
		       effectiveRange: NULL];
      if (color)
	{
	  rects = [self rectArrayForGlyphRange: r
		      withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0)
			       inTextContainer: textContainer
				     rectCount: &count];

	  if (count)
	    {
	      if (last_color != color)
		{
		  [color set];
		  last_color = color;
		}
	      for (j = 0; j < count; j++, rects++)
		{
		  DPSrectfill(ctxt,
			      rects->origin.x + containerOrigin.x,
			      rects->origin.y + containerOrigin.y,
			      rects->size.width, rects->size.height);
		}
	    }
	}

      glyph_pos += glyph_run->head.glyph_length;
      char_pos += glyph_run->head.char_length;
      i = 0;
      glyph_run = (glyph_run_t *)glyph_run->head.next;
      if (i + glyph_pos >= range.location + range.length)
	break;
    }

  if (!_selected_range.length || _selected_range.location == NSNotFound)
    return;

  if (_selected_range.location >= char_pos ||
      _selected_range.location + _selected_range.length <= first_char_pos)
    {
      return;
    }

  /* The selection (might) intersect our glyph range. */
  {
    NSRange r = [self glyphRangeForCharacterRange: _selected_range
		  actualCharacterRange: NULL];
    NSRange sel = r;

    if (r.location < range.location)
      {
	if (range.location - r.location > r.length)
	  return;
	r.length -= range.location - r.location;
	r.location = range.location;
      }
    if (r.location + r.length > range.location + range.length)
      {
	if (r.location > range.location + range.length)
	  return;
	r.length = range.location + range.length - r.location;
      }

    /* TODO: use the text view's selected text attributes */
    color = [NSColor selectedTextBackgroundColor];
    if (!color)
      return;

    rects = [self rectArrayForGlyphRange: r
	      withinSelectedGlyphRange: sel
	      inTextContainer: textContainer
	      rectCount: &count];

    if (count)
      {
	[color set];
	for (j = 0; j < count; j++, rects++)
	  {
	    DPSrectfill(ctxt,
			rects->origin.x + containerOrigin.x,
			rects->origin.y + containerOrigin.y,
			rects->size.width, rects->size.height);
	  }
      }
  }
}


-(void) drawGlyphsForGlyphRange: (NSRange)range
			atPoint: (NSPoint)containerOrigin
{
  int i, j;
  textcontainer_t *tc;
  linefrag_t *lf;
  linefrag_point_t *lp;

  linefrag_attachment_t *la;
  int la_i;

  NSPoint p;
  unsigned int g;

  NSDictionary *attributes;
  NSFont *f;
  NSColor *color, *new_color;

  glyph_run_t *glyph_run;
  unsigned int glyph_pos, char_pos;
  glyph_t *glyph;

  NSGraphicsContext *ctxt = GSCurrentContext();

#define GBUF_SIZE 16 /* TODO: tweak */
  NSGlyph gbuf[GBUF_SIZE];
  int gbuf_len;
  NSPoint gbuf_point;

  NSView *controlView = nil;

  if (!range.length)
    return;
  [self _doLayoutToGlyph: range.location + range.length - 1];

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > range.location)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return;
    }

  if (range.location + range.length > tc->pos + tc->length)
    range.length = tc->pos + tc->length - range.location;

  LINEFRAG_FOR_GLYPH(range.location);

  la = lf->attachments;
  la_i = 0;

  j = 0;
  lp = lf->points;
  while (lp->pos + lp->length < range.location)
    lp++, j++;

  glyph_run = run_for_glyph_index(lp->pos, glyphs, &glyph_pos, &char_pos);
  glyph = glyph_run->glyphs + lp->pos - glyph_pos;
  attributes = [_textStorage attributesAtIndex: char_pos
			     effectiveRange: NULL];
  color = [attributes valueForKey: NSForegroundColorAttributeName];
  if (color)
    [color set];
  else
    {
      DPSsetgray(ctxt, 0.0);
      DPSsetalpha(ctxt, 1.0);
    }
  f = glyph_run->font;
  [f set];

  p = lp->p;
  p.x += lf->rect.origin.x + containerOrigin.x;
  p.y += lf->rect.origin.y + containerOrigin.y;
  gbuf_len = 0;
  for (g = lp->pos; g < range.location + range.length; g++, glyph++)
    {
      if (g == lp->pos + lp->length)
	{
	  if (gbuf_len)
	    {
	      DPSmoveto(ctxt, gbuf_point.x, gbuf_point.y);
	      GSShowGlyphs(ctxt, gbuf, gbuf_len);
	      DPSnewpath(ctxt);
	      gbuf_len = 0;
	    }
	  j++;
	  lp++;
	  if (j == lf->num_points)
	    {
	      i++;
	      lf++;
	      j = 0;
	      lp = lf->points;
	      la = lf->attachments;
	      la_i = 0;
	    }
	  p = lp->p;
	  p.x += lf->rect.origin.x + containerOrigin.x;
	  p.y += lf->rect.origin.y + containerOrigin.y;
	}
      if (g == glyph_pos + glyph_run->head.glyph_length)
	{
	  glyph_pos += glyph_run->head.glyph_length;
	  char_pos += glyph_run->head.char_length;
	  glyph_run = (glyph_run_t *)glyph_run->head.next;
	  attributes = [_textStorage attributesAtIndex: char_pos
				     effectiveRange: NULL];
	  new_color = [attributes valueForKey: NSForegroundColorAttributeName];
	  glyph = glyph_run->glyphs;
	  if (glyph_run->font != f || new_color != color)
	    {
	      if (gbuf_len)
		{
		  DPSmoveto(ctxt, gbuf_point.x, gbuf_point.y);
		  GSShowGlyphs(ctxt, gbuf, gbuf_len);
		  DPSnewpath(ctxt);
		  gbuf_len = 0;
		}
	      if (color != new_color)
		{
		  color = new_color;
		  if (color)
		    [color set];
		  else
		    {
		      DPSsetgray(ctxt, 0.0);
		      DPSsetalpha(ctxt, 1.0);
		    }
		}
	      if (f != glyph_run->font)
		{
		  f = glyph_run->font;
		  [f set];
		}
	    }
	}
      if (!glyph->isNotShown && glyph->g && glyph->g != NSControlGlyph)
	{
	  if (glyph->g == GSAttachmentGlyph)
	    {
	      /* Silently ignore if we don't have any size information for
	      it. */
	      if (g >= range.location && la)
		{
		  unsigned int char_index =
		    [self characterRangeForGlyphRange: NSMakeRange(g, 1)
				     actualGlyphRange: NULL].location;
		  NSObject<NSTextAttachmentCell> *cell = [[_textStorage attribute: NSAttachmentAttributeName
			atIndex: char_index
			effectiveRange: NULL] attachmentCell];
		  NSRect cellFrame;

		  if (!controlView)
		    controlView = [NSView focusView];

		  while (la->pos != g && la_i < lf->num_attachments)
		    {
		      la++;
		      la_i++;
		    }
		  if (la_i >= lf->num_attachments)
		    continue;

		  cellFrame.origin = p;
		  cellFrame.size = la->size;
		  cellFrame.origin.y -= cellFrame.size.height;

		  /* Drawing the cell might mess up our state. */
		  /* TODO:
		  optimize this. probably cheaper to not save and
		  explicitly reset just the stuff we actually use, or to
		  collect attachments and draw them in bunches of eg. 4

		  should they really be drawn in our coordinate system?
		  */
		  [cell drawWithFrame: cellFrame
		    inView: controlView
		    characterIndex: char_index
		    layoutManager: self];
		  [f set];
		  if (color)
		    [color set];
		  else
		    {
		      DPSsetgray(ctxt, 0.0);
		      DPSsetalpha(ctxt, 1.0);
		    }
		}
	      continue;
	    }
	  if (g >= range.location)
	    {
	      if (!gbuf_len)
		{
		  gbuf[0] = glyph->g;
		  gbuf_point = p;
		  gbuf_len = 1;
		}
	      else
		{
		  if (gbuf_len == GBUF_SIZE)
		    {
		      DPSmoveto(ctxt, gbuf_point.x, gbuf_point.y);
		      GSShowGlyphs(ctxt, gbuf, GBUF_SIZE);
		      DPSnewpath(ctxt);
		      gbuf_len = 0;
		      gbuf_point = p;
		    }
		  gbuf[gbuf_len++] = glyph->g;
		}
	    }
	  p.x += [f advancementForGlyph: glyph->g].width;
	}
    }
  if (gbuf_len)
    {
/*int i;
printf("%i at (%g %g) 4\n", gbuf_len, gbuf_point.x, gbuf_point.y);
for (i = 0; i < gbuf_len; i++) printf("   %3i : %04x\n", i, gbuf[i]); */
      DPSmoveto(ctxt, gbuf_point.x, gbuf_point.y);
      GSShowGlyphs(ctxt, gbuf, gbuf_len);
      DPSnewpath(ctxt);
    }

#undef GBUF_SIZE
}

@end


@implementation NSLayoutManager

-(void) insertTextContainer: (NSTextContainer *)aTextContainer
		    atIndex: (unsigned int)index
{
  int i;

  [super insertTextContainer: aTextContainer
  	atIndex: index];

  for (i = 0; i < num_textcontainers; i++)
    [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}

-(void) removeTextContainerAtIndex: (unsigned int)index
{
  int i;
  NSTextView *tv = [textcontainers[index].textContainer textView];

  RETAIN(tv);

  [super removeTextContainerAtIndex: index];

  [tv _updateMultipleTextViews];
  RELEASE(tv);

  for (i = 0; i < num_textcontainers; i++)
    [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}


-(void) dealloc
{
  DESTROY(_typingAttributes);
  [super dealloc];
}


/*
TODO: Add a general typesetterAttributes dictionary. Implement the
hyphenation factor methods by setting/getting an attribute in this
dictionary.
*/
-(float) hyphenationFactor
{
  return 0.0;
}

-(void) setHyphenationFactor: (float)factor
{
  NSLog(@"Warning: (NSLayoutManager) %s not implemented", __PRETTY_FUNCTION__);
}


-(NSTextView *) firstTextView
{
  int i;
  NSTextView *tv;
  for (i = 0; i < num_textcontainers; i++)
    {
      tv = [textcontainers[i].textContainer textView];
      if (tv)
        return tv;
    }
  return nil;
}

-(NSTextView *) textViewForBeginningOfSelection
{
  /* TODO */
  return [self firstTextView];
}

-(BOOL) layoutManagerOwnsFirstResponderInWindow: (NSWindow *)window
{
  int i;
  NSView *tv;
  NSView *v = [window firstResponder];

  for (i = 0; i < num_textcontainers; i++)
    {
      tv = (NSView *)[textcontainers[i].textContainer textView];
      if (tv == v)
        return YES;
    }
  return NO;
}


-(NSArray *) rulerMarkersForTextView: (NSTextView *)textView
		      paragraphStyle: (NSParagraphStyle *)paragraphStyle
			       ruler: (NSRulerView *)aRulerView
{
  NSRulerMarker *marker;
  NSTextTab *tab;
  NSImage *image;
  NSArray *tabs = [paragraphStyle tabStops];
  NSEnumerator *enumerator = [tabs objectEnumerator];
  NSMutableArray *markers = [NSMutableArray arrayWithCapacity: [tabs count]];

  while ((tab = [enumerator nextObject]) != nil)
    {
      switch ([tab tabStopType])
        {
	  case NSLeftTabStopType:
	    image = [NSImage imageNamed: @"common_LeftTabStop"];
	    break;
	  case NSRightTabStopType:
	    image = [NSImage imageNamed: @"common_RightTabStop"];
	    break;
	  case NSCenterTabStopType:
	    image = [NSImage imageNamed: @"common_CenterTabStop"];
	    break;
	  case NSDecimalTabStopType:
	    image = [NSImage imageNamed: @"common_DecimalTabStop"];
	    break;
	  default:
	    image = nil;
	    break;
	}
      marker = [[NSRulerMarker alloc] 
		   initWithRulerView: aRulerView
		   markerLocation: [tab location]
		   image: image
		   imageOrigin: NSMakePoint(0, 0)];
      [marker setRepresentedObject: tab];
      [markers addObject: marker];
    }

  return markers;
}

-(NSView *) rulerAccessoryViewForTextView: (NSTextView *)textView
			   paragraphStyle: (NSParagraphStyle *)style
				    ruler: (NSRulerView *)ruler
				  enabled: (BOOL)isEnabled
{
  /* TODO */
  return nil;
}


/*
TODO: not really clear what these should do
*/
-(void) invalidateDisplayForGlyphRange: (NSRange)aRange
{
  int i;
  unsigned int m;
  NSRange r;
  NSRect rect;
  NSPoint p;
  NSTextView *tv;

  for (i = 0; i < num_textcontainers; i++)
    {
      if (!textcontainers[i].num_linefrags)
        break;

      if (textcontainers[i].pos >= aRange.location + aRange.length)
        break; /* we're past the end of the range */

      m = textcontainers[i].pos + textcontainers[i].length;
      if (m < aRange.location)
        continue;

      r.location = textcontainers[i].pos;
      if (aRange.location > r.location)
        r.location = aRange.location;

      if (m > aRange.location + aRange.length)
        m = aRange.location + aRange.length;

      r.length = m - r.location;

      /* Range r in this text view should be invalidated. */
      rect = [self boundingRectForGlyphRange: r
 	       inTextContainer: textcontainers[i].textContainer];
      tv = [textcontainers[i].textContainer textView];
      p = [tv textContainerOrigin];
      rect.origin.x += p.x;
      rect.origin.y += p.y;

      [tv setNeedsDisplayInRect: rect];
    }
}

-(void) invalidateDisplayForCharacterRange: (NSRange)aRange
{
  if (layout_char < aRange.location)
    return;
  if (layout_char < aRange.location + aRange.length)
    aRange.length = layout_char - aRange.location;
  [self invalidateDisplayForGlyphRange:
    [self glyphRangeForCharacterRange: aRange
      actualCharacterRange: NULL]];

}


-(void) _didInvalidateLayout
{
  unsigned int g;
  int i;

  /* Invalidate from the first glyph not laid out (which will
  generally be the first glyph to have been invalidated). */
  g = layout_glyph;

  [super _didInvalidateLayout];

  for (i = 0; i < num_textcontainers; i++)
    {
      if (textcontainers[i].complete &&
	  g < textcontainers[i].pos + textcontainers[i].length)
        continue;

      [[textcontainers[i].textContainer textView] _layoutManagerDidInvalidateLayout];
    }
}


-(void) _dumpLayout
{
  int i, j, k;
  textcontainer_t *tc;
  linefrag_t *lf;
  linefrag_point_t *lp;
  linefrag_attachment_t *la;

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      printf("tc %2i, %5i+%5i  (complete %i)\n",
	i,tc->pos,tc->length,tc->complete);
      printf("  lfs: (%3i)\n", tc->num_linefrags);
      for (j = 0, lf = tc->linefrags; j < tc->num_linefrags; j++, lf++)
	{
	  printf("   %3i : %5i+%5i  (%g %g)+(%g %g)\n",
	    j,lf->pos,lf->length,
	    lf->rect.origin.x,lf->rect.origin.y,
	    lf->rect.size.width,lf->rect.size.height);
	  for (k = 0, lp = lf->points; k < lf->num_points; k++, lp++)
	    printf("               p%3i : %5i+%5i\n",k,lp->pos,lp->length);
	  for (k = 0, la = lf->attachments; k < lf->num_attachments; k++, la++)
	    printf("               a%3i : %5i+%5i\n",k,la->pos,la->length);
	}
      printf("  softs: (%3i)\n", tc->num_soft);
      for (; j < tc->num_linefrags + tc->num_soft; j++, lf++)
	{
	  printf("   %3i : %5i+%5i  (%g %g)+(%g %g)\n",
	    j,lf->pos,lf->length,
	    lf->rect.origin.x,lf->rect.origin.y,
	    lf->rect.size.width,lf->rect.size.height);
	  for (k = 0, lp = lf->points; k < lf->num_points; k++, lp++)
	    printf("               p%3i : %5i+%5i\n",k,lp->pos,lp->length);
	  for (k = 0, la = lf->attachments; k < lf->num_attachments; k++, la++)
	    printf("               a%3i : %5i+%5i\n",k,la->pos,la->length);
	}
    }
    printf("layout to: char %i, glyph %i\n",layout_char,layout_glyph);
}


/*
We completely override this method and use the extra information we have
about layout to do smarter invalidation. The comments at the beginning of
this file describes this.
*/
- (void) textStorage: (NSTextStorage *)aTextStorage
	      edited: (unsigned int)mask
	       range: (NSRange)range
      changeInLength: (int)lengthChange
    invalidatedRange: (NSRange)invalidatedRange
{
  NSRange r;
  unsigned int original_last_glyph, new_last_glyph;
  int glyph_delta;

/*  printf("\n*** invalidating\n");
  [self _dumpLayout];*/

  /*
  Using -glyphRangeForChara... here would be safer, but we must make
  absolutely sure that we don't cause any glyph generation until the
  invalidation is done.

  TODO: make sure last_glyph is set as expected
  */
  original_last_glyph = layout_glyph;

  if (!(mask & NSTextStorageEditedCharacters))
    lengthChange = 0;

  [self invalidateGlyphsForCharacterRange: invalidatedRange
	changeInLength: lengthChange
	actualCharacterRange: &r];

  if (layout_char > r.location)
    {
      layout_char += lengthChange;
      if (layout_char < r.location)
        layout_char = r.location;
    }

  if (layout_char == [_textStorage length])
    new_last_glyph = [self numberOfGlyphs];
  else
    new_last_glyph = [self glyphRangeForCharacterRange: NSMakeRange(layout_char, 1)
				  actualCharacterRange: NULL].location;

  glyph_delta = new_last_glyph - original_last_glyph;
/*  printf("original=%i, new=%i, delta %i\n",
    original_last_glyph,new_last_glyph,glyph_delta);*/

  if (r.location <= layout_char)
    {
      unsigned int glyph_index, last_glyph;
      textcontainer_t *tc;
      linefrag_t *lf;
      int i, j, k;
      int new_num;
      NSRange char_range;

      /*
      Note that r.location might equal layout_char, in which case
      r.location won't actually have any text container or line frag.
      */
      if (r.location == [_textStorage length])
	{
	  /*
	  Since layout was built beyond r.location, glyphs must have been
	  too, so invalidation only removed trailing glyphs and we still
	  have glyphs built up to the end. Thus, -numberOfGlyphs is cheap
	  to call.
	  */
	  glyph_index = [self numberOfGlyphs];
	  char_range.location = [_textStorage length];
	}
      else
	{
	  /*
	  Will cause generation of glyphs, but I consider that acceptable
	  for now. Soft-invalidation will cause even more glyph generation,
	  anyway.
	  */
	  glyph_index =
	    [self glyphRangeForCharacterRange: NSMakeRange(r.location,1)
			 actualCharacterRange: &char_range].location;
	}

      /*
      For soft invalidation, we need to know where to stop hard-invalidating.
      This will cause immediate glyph generation to fill the gaps the
      invalidation caused.
      */
      if (NSMaxRange(r) == [_textStorage length])
	{
	  last_glyph = [self numberOfGlyphs];
	}
      else
	{
	  last_glyph =
	    [self glyphRangeForCharacterRange: NSMakeRange(NSMaxRange(r),1)
			 actualCharacterRange: NULL].location;
	}
      last_glyph -= glyph_delta;

      /* glyph_index is the first index we should invalidate for. */
      for (j = 0, tc = textcontainers; j < num_textcontainers; j++, tc++)
	if (tc->pos + tc->length >= glyph_index)
	  break;

      LINEFRAG_FOR_GLYPH(glyph_index);

      /*
      We invalidate the entire line containing lf, and the entire
      previous line. Thus, we scan backwards to find the first line frag
      on the previous line.
      */
      while (i > 0 && lf[-1].rect.origin.y == lf->rect.origin.y)
	lf--, i--;
      /* Now we have the first line frag on this line. */
      if (i > 0)
	{
	  lf--, i--;
	}
      else
	{
	  /*
	  The previous line isn't in this text container, so we move
	  to the previous text container.
	  */
	  if (j > 0)
	    {
	      j--;
	      tc--;
	      i = tc->num_linefrags - 1;
	      lf = tc->linefrags + i;
	    }
	}
      /* Last line frag on previous line. */
      while (i > 0 && lf[-1].rect.origin.y == lf->rect.origin.y)
	lf--, i--;
      /* First line frag on previous line. */

      /* Invalidate all line frags that intersect the invalidated range. */
      new_num = i;
      while (1)
	{
	  for (; i < tc->num_linefrags + tc->num_soft; i++, lf++)
	    {
	      /*
	      Since we must invalidate whole lines, we can only stop if
	      the line frag is beyond the invalidated range, and the line
	      frag is the first line frag in a line.
	      */
	      if (lf->pos >= last_glyph &&
		  (!i || lf[-1].rect.origin.y != lf->rect.origin.y))
		{
		  break;
		}
	      if (lf->points)
		{
		  free(lf->points);
		  lf->points = NULL;
		}
	      if (lf->attachments)
		{
		  free(lf->attachments);
		  lf->attachments = NULL;
		}
	    }
	  if (i < tc->num_linefrags + tc->num_soft)
	    break;
	  tc->num_linefrags = new_num;
	  tc->num_soft = 0;
	  tc->was_invalidated = YES;
	  tc->complete = NO;
	  if (new_num)
	    {
	      tc->length = tc->linefrags[new_num-1].pos + tc->linefrags[new_num-1].length - tc->pos;
	    }
	  else
	    {
	      tc->pos = tc->length = 0;
	    }

	  j++, tc++;
	  if (j == num_textcontainers)
	    break;

	  new_num = 0;
	  i = 0;
	  lf = tc->linefrags;
	}

      if (j == num_textcontainers)
	goto no_soft_invalidation;

      if (new_num != i)
	{
	  /*
	  There's a gap between the last valid line frag and the first
	  soft line frag. Compact the linefrags.
	  */
	  memmove(tc->linefrags + new_num, lf, sizeof(linefrag_t) * (tc->num_linefrags + tc->num_soft - i));
	  tc->num_linefrags -= i - new_num;
	  i = new_num;
	  lf = tc->linefrags + i;
	}
      tc->num_soft += tc->num_linefrags - new_num;
      tc->num_linefrags = new_num;
      tc->was_invalidated = YES;
      tc->complete = NO;
      if (new_num)
	{
	  tc->length = tc->linefrags[new_num - 1].pos + tc->linefrags[new_num - 1].length - tc->pos;
	}
      else
	{
	  tc->pos = tc->length = 0;
	}

      /*
      Soft invalidate all remaining layout. Update their glyph positions
      and set the soft-invalidate markers in the text containers.
      */
      while (1)
	{
	  for (; i < tc->num_linefrags + tc->num_soft; i++, lf++)
	    {
	      lf->pos += glyph_delta;
	      for (k = 0; k < lf->num_points; k++)
		lf->points[k].pos += glyph_delta;
	      for (k = 0; k < lf->num_attachments; k++)
		lf->attachments[k].pos += glyph_delta;
	    }
	
	  j++, tc++;
	  if (j == num_textcontainers)
	    break;
	  i = 0;
	  lf = tc->linefrags;
	  tc->num_soft += tc->num_linefrags;
	  tc->num_linefrags = 0;
	  tc->was_invalidated = YES;
	  tc->complete = NO;
	}

no_soft_invalidation:
      /* Set layout_glyph and layout_char. */
      for (i = num_textcontainers - 1, tc = textcontainers + i; i >= 0; i--, tc--)
	{
	  if (tc->num_linefrags)
	    {
	      layout_glyph = tc->pos + tc->length;
	      if (layout_glyph == glyphs->glyph_length)
		layout_char = glyphs->char_length;
	      else
		layout_char = [self characterIndexForGlyphAtIndex: layout_glyph]; /* TODO? */
	      break;
	    }
        }
      if (i < 0)
	layout_glyph = layout_char = 0;
    }
  else
    {
      int i, j;
      linefrag_t *lf;
      textcontainer_t *tc;
      /*
      TODO: could handle this better, but it should be a rare case,
      handling it efficiently is tricky.

      For now, we simply clear out all soft invalidation information.
      */
      for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
	{
	  for (j = 0, lf = tc->linefrags + tc->num_linefrags; j < tc->num_soft; j++, lf++)
	    {
	      if (lf->points)
		{
		  free(lf->points);
		  lf->points = NULL;
		}
	      if (lf->attachments)
		{
		  free(lf->attachments);
		  lf->attachments = NULL;
		}
	    }
	  tc->num_soft = 0;
	  if (tc->pos + tc->length == r.location)
	    {
	      tc->complete = NO;
	    }
	}
    }

  /* Clear the extra line fragment information. */
  extra_textcontainer = nil;

/*  [self _dumpLayout];
  printf("*** done\n");*/

  [self _didInvalidateLayout];

  if ((mask & NSTextStorageEditedCharacters) && lengthChange)
    {
      /*
      Adjust the selected range so it's still valid. We don't try to
      be smart here (smart adjustments will have to be done by whoever
      made the change), we just want to keep it in range to avoid crashes.

      TODO: It feels slightly ugly to be doing this here, but there aren't
      many other places that can do this, and it gives reasonable behavior
      for select-only text views.

      One option is to only adjust when absolutely necessary to keep the
      selected range valid.
      */
      if (_selected_range.location >= range.location + range.length - lengthChange)
	{
	  _selected_range.location += lengthChange;
	}
      else if (_selected_range.location + _selected_range.length >= range.location)
	{
	  if (-lengthChange > _selected_range.length)
	    {
	      _selected_range.length = 0;
	      _selected_range.location = range.location;
	    }
	  else
	    {
	      _selected_range.length += lengthChange;
	    }
	}
    }
}


@end

