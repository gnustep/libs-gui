/*
   NSLayoutManager.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2002

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
*/

#include "AppKit/NSLayoutManager.h"
#include "AppKit/GSLayoutManager_internal.h"

#include <Foundation/NSException.h>
#include <AppKit/NSColor.h>
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


@implementation NSLayoutManager (layout)

- (NSPoint) locationForGlyphAtIndex: (unsigned int)glyphIndex
{
  NSRange r;
  NSPoint p;
  NSFont *f;
  unsigned int i;

  r = [self rangeOfNominallySpacedGlyphsContainingIndex: glyphIndex
	    startLocation: &p];

  i = r.location;
  f = [self effectiveFontForGlyphAtIndex: i
	    range: &r];
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


- (void) textContainerChangedTextView: (NSTextContainer *)aContainer
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


- (NSRect *) rectArrayForGlyphRange: (NSRange)glyphRange
	   withinSelectedGlyphRange: (NSRange)selGlyphRange
		    inTextContainer: (NSTextContainer *)container
			  rectCount: (unsigned int *)rectCount
{
  unsigned int last = glyphRange.location + glyphRange.length;
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;
  int num_rects;
  float x0, x1;
  NSRect r;


  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  [self _doLayoutToGlyph: last - 1];
  if (i == num_textcontainers ||
      tc->pos + tc->length < last ||
      tc->pos > glyphRange.location)
    {
      if (i == num_textcontainers)
	NSLog(@"%s: invalid text container", __PRETTY_FUNCTION__);
      else
	[NSException raise: NSRangeException
		    format: @"%s invalid glyph range", __PRETTY_FUNCTION__];
      *rectCount = 0;
      return NULL;
    }

  if (!glyphRange.length)
    {
      *rectCount = 0;
      return NULL;
    }

  num_rects = 0;

  for (lf = tc->linefrags, i = 0; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > glyphRange.location)
      break;

  while (1)
    {
      if (lf->pos < glyphRange.location)
	{
	  int i, j;
	  linefrag_point_t *lp;
	  glyph_run_t *r;
	  unsigned int gpos, cpos;

	  for (j = 0, lp = lf->points; j < lf->num_points; j++)
	    if (lp->pos + lp->length > glyphRange.location)
	      break;

	  x0 = lp->p.x + lf->rect.origin.x;
	  r = run_for_glyph_index(lp->pos, glyphs, &gpos, &cpos);
	  i = lp->pos - gpos;

	  while (i + gpos < glyphRange.location)
	    {
	      if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
		  r->glyphs[i].g != NSControlGlyph)
		x0 += [r->font advancementForGlyph: r->glyphs[i].g].width;
	      GLYPH_STEP_FORWARD(r, i, gpos, cpos)
		}
	}
      else
	x0 = NSMinX(lf->rect);

      if (lf->pos + lf->length > last)
	{
	  int i, j;
	  linefrag_point_t *lp;
	  glyph_run_t *r;
	  unsigned int gpos, cpos;

	  /* At this point there is a glyph in our range that is in this
	     line frag rect. If we're on the first line frag rect, it's
	     trivially true. If not, the check before the lf++; ensures it. */
	  for (j = 0, lp = lf->points; j < lf->num_points; j++)
	    if (lp->pos < last)
	      break;

	  x1 = lp->p.x + lf->rect.origin.x;
	  r = run_for_glyph_index(lp->pos, glyphs, &gpos, &cpos);
	  i = lp->pos - gpos;

	  while (i + gpos < last)
	    {
	      if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
		  r->glyphs[i].g != NSControlGlyph)
		x1 += [r->font advancementForGlyph: r->glyphs[i].g].width;
	      GLYPH_STEP_FORWARD(r, i, gpos, cpos)
		}
	}
      else
	x1 = NSMaxX(lf->rect);

      r = NSMakeRect(x0, lf->rect.origin.y, x1 - x0, lf->rect.size.height);
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

- (NSRect *) rectArrayForCharacterRange: (NSRange)charRange
	   withinSelectedCharacterRange: (NSRange)selCharRange
			inTextContainer: (NSTextContainer *)container
			      rectCount: (unsigned int *)rectCount
{
  NSRange r1, r2;

  r1 = [self glyphRangeForCharacterRange: charRange
	     actualCharacterRange: NULL];
  r2 = [self glyphRangeForCharacterRange: selCharRange
	     actualCharacterRange: NULL];

  return [self rectArrayForGlyphRange: r1
	       withinSelectedGlyphRange: r2
	       inTextContainer: container
	       rectCount: rectCount];
}

- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange 
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


/*  NSLog(@"%@ %s  (%g %g)+(%g %g) in %@\n", self, __PRETTY_FUNCTION__,
	bounds.origin.x, bounds.origin.y,
	bounds.size.width, bounds.size.height,
	container);*/

  for (tc = textcontainers, i = 0; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: invalid text container", __PRETTY_FUNCTION__);
      return NSMakeRange(0, 0);
    }

  [self _doLayoutToContainer: i
    point: NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];

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

//  printf("low=%i (%g+%g) %g\n",low,lf->rect.origin.y,lf->rect.size.height,NSMinY(bounds));

  if (NSMaxY(lf->rect) < NSMinY(bounds))
    {
//      printf("  empty (bounds below text)\n");
      return NSMakeRange(0, 0);
    }

  /* Scan to first line frag intersecting bounds horizontally. */
  while (i < tc->num_linefrags - 1 &&
	 NSMinY(lf[0].rect) == NSMinY(lf[1].rect) &&
	 NSMaxX(lf[1].rect) < NSMinX(bounds))
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

//  printf("low=%i (%i) (%g+%g) %g\n",low,tc->num_linefrags,lf->rect.origin.y,lf->rect.size.height,NSMaxY(bounds));

  if (NSMinY(lf->rect) > NSMaxY(bounds))
    {
//      printf("  empty (bounds above text)\n");
      return NSMakeRange(0, 0);
    }

  /* Scan to last line frag intersecting bounds horizontally. */
  while (i > 0 &&
	 NSMinY(lf[0].rect) == NSMinY(lf[-1].rect) &&
	 NSMinX(lf[1].rect) > NSMaxX(bounds))
    i--, lf--;
//  printf("i=%i\n",i);

  /* TODO: find proper position in line frag rect */

  j = lf->pos + lf->length;
  if (j <= range.location)
    {
//      printf("  empty (bound between lines?)\n");
      return NSMakeRange(0, 0);
    }

  range.length = j - range.location;
/*  printf("  range= %i - %i  |%@|\n",
	range.location,range.length,
	[[_textStorage string] substringWithRange: range]);*/
  return range;
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
					     inTextContainer: (NSTextContainer *)container
{
  /* OPT: handle faster? how? */
  return [self glyphRangeForBoundingRect: bounds
	       inTextContainer: container];
}


- (unsigned int) glyphIndexForPoint: (NSPoint)aPoint
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
- (unsigned int) glyphIndexForPoint: (NSPoint)point
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

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    {
      if (NSPointInRect(point, lf->rect))
	break;

      /* Point is between two lines. */
      if (NSMinY(lf->rect) > point.y)
	{
	  if (lf->pos > 0)
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
    }

  /* Point is below all line frags. */
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

  /* Before the first glyph on the line. */
  if (!i)
    {
      /* TODO: what if it isn't shown? */
      *partialFraction = 0;
      return lp->pos;
    }
  else
    {
      float cur, prev, next;
      glyph_run_t *r;
      unsigned int glyph_pos, char_pos, last_visible;

      if (i < lf->num_points)
	next = lp->p.x;
      else
	next = NSMinX(lf->rect);

      lp--;
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

@end




@implementation NSLayoutManager (drawing)


/** Drawing **/

/*
If a range passed to a drawing function isn't contained in the text
container that containts its first glyph, the range is silently clamped.
My thought with this is that the requested glyphs might not fit in the
text container (if it's the last text container, or there's only one).
In that case, it isn't really the caller's fault, and drawing as much as
will fit in the text container makes sense.

TODO: reconsider silently clamping ranges in these methods; might
want to make sure we don't do it if part of the range is in a second
container */

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
      rects = [self rectArrayForGlyphRange:
		      NSMakeRange(glyph_pos + i, glyph_run->head.glyph_length - i)
		    withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0)
		    inTextContainer: textContainer
		    rectCount: &count];

      if (count)
	{
	  color = [_textStorage attribute: NSBackgroundColorAttributeName
				atIndex: char_pos
				effectiveRange: NULL];
	  if (color)
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
	r.length -= range.location - r.location;
	r.location = range.location;
      }
    if (r.location + r.length > range.location + range.length)
      {
	r.length = range.location + range.length - r.location;
      }
    if (r.length <= 0)
      return;

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

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > range.location)
      break;
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: can't find line frag rect for glyph (internal error)", __PRETTY_FUNCTION__);
      return;
    }

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

- (void) insertTextContainer: (NSTextContainer *)aTextContainer
		     atIndex: (unsigned int)index
{
  int i;

  [super insertTextContainer: aTextContainer
  	atIndex: index];

  for (i = 0; i < num_textcontainers; i++)
    [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}

- (void) removeTextContainerAtIndex: (unsigned int)index
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


/* TODO */
-(float) hyphenationFactor
{
  return 0.0;
}

-(void) setHyphenationFactor: (float)factor
{
  NSLog(@"Warning: (NSLayoutManager) %s not implemented",__PRETTY_FUNCTION__);
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
		      paragraphStyle: (NSParagraphStyle *)style
			       ruler: (NSRulerView *)ruler
{
  /* TODO */
  return nil;
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
      if (!textcontainers[i].started)
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


-(void) textStorage: (NSTextStorage *)aTextStorage
	     edited: (unsigned int)mask
	      range: (NSRange)range
     changeInLength: (int)lengthChange
   invalidatedRange: (NSRange)invalidatedRange
{
  unsigned int g;
  int i;

  [super textStorage: aTextStorage
	edited: mask
	range: range
	changeInLength: lengthChange
	invalidatedRange: invalidatedRange];

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

  /* Invalidate display from the first glyph not laid out (which will
  generally be the first glyph to have been invalidated). */
  g = layout_glyph;

  for (i = 0; i < num_textcontainers; i++)
    {
      if (textcontainers[i].complete &&
	  g < textcontainers[i].pos + textcontainers[i].length)
        continue;

      [[textcontainers[i].textContainer textView] sizeToFit]; /* TODO? */
      [[textcontainers[i].textContainer textView] setNeedsDisplay: YES];
    }

}

@end

