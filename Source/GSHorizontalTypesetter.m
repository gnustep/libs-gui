/*
   GSHorizontalTypesetter.m

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

#include "AppKit/GSHorizontalTypesetter.h"

#include "AppKit/GSLayoutManager.h"

#include <Foundation/NSException.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSGeometry.h>

#include "AppKit/NSTextStorage.h"
#include "AppKit/NSParagraphStyle.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSTextAttachment.h"


/*
Note that unless the user creates extra instances, there will only be one
instance of GSHorizontalTypesetter for all text typesetting, so we can
cache fairly aggressively without having to worry about memory consumption.
*/


@implementation GSHorizontalTypesetter

- init
{
  if (!(self = [super init])) return nil;
  lock = [[NSLock alloc] init];
  return self;
}

-(void) dealloc
{
  if (cache)
    {
      free(cache);
      cache = NULL;
    }
  [super dealloc];
}

+(GSHorizontalTypesetter *) sharedInstance
{
static GSHorizontalTypesetter *shared;
  if (!shared)
    shared = [[self alloc] init];
  return shared;
}


typedef struct GSHorizontalTypesetter_glyph_cache_s
{
  /* These fields are filled in by the caching: */
  NSGlyph g;
  int char_index;

  NSFont *font;
  struct
    {
      BOOL explicit_kern;
      float kern;
      float baseline_offset;
      int superscript;
    } attributes;

  /* These fields are filled in during layout: */
  BOOL nominal;
  NSPoint pos;    /* relative to the line's baseline */
  NSSize size;    /* height is used only for attachments */
  BOOL dont_show, outside_line_frag;
} glyph_cache_t;


/* TODO: if we could know whether the layout manager had been modified since
the last time or not, we wouldn't need to clear the cache every time */
-(void) _cacheClear
{
  cache_length = 0;
}

-(void) _cacheAttributes
{
  NSNumber *n;

  n = [curAttributes objectForKey: NSKernAttributeName];
  if (!n)
    attributes.explicit_kern = NO;
  else
    {
      attributes.explicit_kern = YES;
      attributes.kern = [n floatValue];
    }

  n = [curAttributes objectForKey: NSBaselineOffsetAttributeName];
  if (n)
    attributes.baseline_offset = [n floatValue];
  else
    attributes.baseline_offset = 0.0;

  n = [curAttributes objectForKey: NSSuperscriptAttributeName];
  if (n)
    attributes.superscript = [n intValue];
  else
    attributes.superscript = 0;
}

-(void) _cacheMoveTo: (unsigned int)glyph
{
  BOOL valid;

  if (cache_base <= glyph && cache_base + cache_length > glyph)
    {
      int delta = glyph - cache_base;
      cache_length -= delta;
      memmove(cache,&cache[delta],sizeof(glyph_cache_t) * cache_length);
      cache_base = glyph;
      return;
    }

  cache_base = glyph;
  cache_length = 0;

  [curLayoutManager glyphAtIndex: glyph
		    isValidIndex: &valid];

  if (valid)
    {
      unsigned int i;

      at_end = NO;
      i = [curLayoutManager characterIndexForGlyphAtIndex: glyph];
      curAttributes = [curTextStorage attributesAtIndex: i
				    effectiveRange: &attributeRange];
      [self _cacheAttributes];

      paragraphRange = NSMakeRange(i,[curTextStorage length] - i);
      curParagraphStyle = [curTextStorage attribute: NSParagraphStyleAttributeName
					atIndex: i
					longestEffectiveRange: &paragraphRange
					inRange: paragraphRange];

      curFont = [curLayoutManager effectiveFontForGlyphAtIndex: glyph
				range: &fontRange];
    }
  else
    at_end = YES;
}

-(void) _cacheGlyphs: (unsigned int)new_length
{
  glyph_cache_t *g;
  BOOL valid;

  if (cache_size < new_length)
    {
      cache_size = new_length;
      cache = realloc(cache,sizeof(glyph_cache_t) * cache_size);
    }

  for (g = &cache[cache_length];cache_length < new_length;cache_length++,g++)
    {
      g->g = [curLayoutManager glyphAtIndex: cache_base + cache_length
			     isValidIndex: &valid];
      if (!valid)
	{
	  at_end = YES;
	  break;
	}
      g->char_index = [curLayoutManager characterIndexForGlyphAtIndex: cache_base + cache_length];
//		printf("cache glyph %i, char %i\n",cache_base + cache_length,g->char_index);
      if (g->char_index >= paragraphRange.location + paragraphRange.length)
	{
	  at_end = YES;
	  break;
	}

      /* cache attributes */
      if (g->char_index >= attributeRange.location + attributeRange.length)
	{
	  curAttributes = [curTextStorage attributesAtIndex: g->char_index
					effectiveRange: &attributeRange];
	  [self _cacheAttributes];
	}

      g->attributes.explicit_kern = attributes.explicit_kern;
      g->attributes.kern = attributes.kern;
      g->attributes.baseline_offset = attributes.baseline_offset;
      g->attributes.superscript = attributes.superscript;

      if (cache_base + cache_length >= fontRange.location + fontRange.length)
	{
	  curFont = [curLayoutManager effectiveFontForGlyphAtIndex: cache_base + cache_length
				    range: &fontRange];
	}
      g->font = curFont;

      g->dont_show = NO;
      g->outside_line_frag = NO;
    }
}


/*
Should return the first glyph on the next line, which must be <=gi and
>=cache_base (TODO: not enough). Glyphs up to and including gi will have
been cached.
*/
-(unsigned int) breakLineByWordWrappingBefore: (unsigned int)gi
{
  glyph_cache_t *g;
  unichar ch;
  NSString *str = [curTextStorage string];

  gi -= cache_base;
  g = cache + gi;

  while (gi > 0)
    {
      if (g->g == NSControlGlyph)
	return gi;
      ch = [str characterAtIndex: g->char_index];
      if (ch == 0x20 || ch == 0x0a || ch == 0x0d /* TODO: paragraph/line separator */ )
	{
	  g->dont_show = YES;
	  if (gi > 0)
	    {
	      g->pos = g[-1].pos;
	      g->pos.x += g[-1].size.width;
	    }
	  else
	    g->pos = NSMakePoint(0,0);
	  g->size.width = 0;
	  return gi + 1 + cache_base;
	}
      gi--;
      g--;
    }
  return gi + cache_base;
}


typedef struct
{
  NSRect rect;
  float last_used;
  unsigned int last_glyph; /* last_glyph+1, actually */
} line_frag_t;


-(void) fullJustifyLine: (line_frag_t *)lf : (int)num_line_frags
{
  unsigned int i,start;
  float extra_space,delta;
  unsigned int num_spaces;
  NSString *str = [curTextStorage string];
  glyph_cache_t *g;
  unichar ch;

  for (start = 0;num_line_frags;num_line_frags--,lf++)
    {
      num_spaces = 0;
      for (i = start,g = cache + i;i < lf->last_glyph;i++,g++)
	{
	  if (g->dont_show)
	    continue;
	  ch = [str characterAtIndex: g->char_index];
	  if (ch == 0x20)
	    num_spaces++;
	}
      if (!num_spaces)
	continue;

      extra_space = lf->rect.size.width - lf->last_used;
      extra_space /= num_spaces;
      delta = 0;
      for (i = start,g = cache + i;i < lf->last_glyph;i++,g++)
	{
	  g->pos.x += delta;
	  if (!g->dont_show && [str characterAtIndex: g->char_index] == 0x20)
	    {
	      if (i < lf->last_glyph)
		g[1].nominal = NO;
	      delta += extra_space;
	    }
	}
      start = lf->last_glyph;
      lf->last_used = lf->rect.size.width;
    }
}


-(void) rightAlignLine: (line_frag_t *)lf : (int)num_line_frags
{
  unsigned int i;
  float delta;
  glyph_cache_t *g;

  for (i = 0,g = cache;num_line_frags;num_line_frags--,lf++)
    {
      delta = lf->rect.size.width - lf->last_used;
      for (;i < lf->last_glyph;i++,g++)
	g->pos.x += delta;
      lf->last_used += delta;
    }
}

-(void) centerAlignLine: (line_frag_t *)lf : (int)num_line_frags
{
  unsigned int i;
  float delta;
  glyph_cache_t *g;

  for (i = 0,g = cache;num_line_frags;num_line_frags--,lf++)
    {
      delta = (lf->rect.size.width - lf->last_used) / 2.0;
      for (;i < lf->last_glyph;i++,g++)
	g->pos.x += delta;
      lf->last_used += delta;
    }
}


-(int) layoutLineNewParagraph: (BOOL)newParagraph
{
  NSRect rect, remain;

  /* Baseline and line height handling. */
  float line_height;     /* Current line height. */
  float max_line_height; /* Maximum line height (usually from the paragraph style). */
  float baseline;        /* Baseline position (0 is top of line-height, positive is down). */
  float ascender;        /* Amount of space we want above the baseline (always>=0). */
  float descender;       /* Amount of space we want below the baseline (always>=0). */
  /*
  These are values for the line as a whole. We start out by initializing
  for the first glyph on the line and then update these as we add more
  glyphs.

  If we need to increase the line height, we jump back to 'restart:' and
  rebuild our array of line frag rects.

  (TODO (optimization): if we're dealing with a "simple rectangular
  text container", we should try to extend the existing line frag in place
  before jumping back to do all the expensive checking).
  */

  /*
  This calculation should match the calculation in [GSFontInfo
  -defaultLineHeightForFont], or text will look odd.
  */
#define COMPUTE_BASELINE  baseline = line_height - descender

  line_frag_t *line_frags = NULL;
  int num_line_frags = 0;


  [self _cacheMoveTo: curGlyph];
  if (!cache_length)
    [self _cacheGlyphs: 16];
  if (!cache_length && at_end)
    return 2;

  /* Set up our initial baseline info. */
  {
    float min = [curParagraphStyle minimumLineHeight];
    max_line_height = [curParagraphStyle maximumLineHeight];

    /* sanity */
    if (max_line_height < min)
      max_line_height = min;

    line_height = [cache->font defaultLineHeightForFont];
    ascender = [cache->font ascender];
    descender = -[cache->font descender];

    COMPUTE_BASELINE;

    if (line_height < min)
      line_height = min;

    if (max_line_height > 0 && line_height > max_line_height)
      line_height = max_line_height;
  }

  /* If we find out that we need to increase the line height, we have to
  start over. The increased line height might give _completely_ different
  line frag rects, so we can't reuse the layout information. */


#define WANT_LINE_HEIGHT(h) \
  do { \
    float __new_height = (h); \
    if (max_line_height > 0 && __new_height > max_line_height) \
      __new_height = max_line_height; \
    if (__new_height > line_height) \
      { \
	line_height = __new_height; \
	COMPUTE_BASELINE; \
	goto restart; \
      } \
  } while (0)

restart:
//	printf("start: at (%g %g)  line_height = %g, baseline = %g\n",curPoint.x,curPoint.y,line_height,baseline);
  {
    float hindent,tindent = [curParagraphStyle tailIndent];

    if (newParagraph)
      hindent = [curParagraphStyle firstLineHeadIndent];
    else
      hindent = [curParagraphStyle headIndent];

    if (tindent <= 0.0)
      tindent = [curTextContainer containerSize].width + tindent;

    remain = NSMakeRect(hindent,
		      curPoint.y,
		      tindent - hindent,
		      line_height + [curParagraphStyle lineSpacing]);
  }

  /*
  Build a list of all line frag rects for this line.

  TODO: it's very convenient to do this in advance, but it might be
  inefficient, and in theory, we might end up with an insane number of line
  rects (eg. a text container with "hole"-columns every 100 points and
  width 1e8)
  */
  num_line_frags = 0;
  if (line_frags)
    {
      free(line_frags);
      line_frags = NULL;
    }
  while (1)
    {
      rect = [curTextContainer lineFragmentRectForProposedRect: remain
			     sweepDirection: NSLineSweepRight
			     movementDirection: num_line_frags?NSLineDoesntMove:NSLineMoveDown
			     remainingRect: &remain];
      if (NSEqualRects(rect,NSZeroRect))
	break;

      num_line_frags++;
      line_frags = realloc(line_frags,sizeof(line_frag_t) * num_line_frags);
      line_frags[num_line_frags - 1].rect = rect;
    }
  if (!num_line_frags)
    {
      if (curPoint.y == 0.0 &&
	  line_height > [curTextContainer containerSize].height)
	{
	  /* Try to make sure each container contains at least one line frag
	  rect by shrinking our line height. */
	  line_height = [curTextContainer containerSize].height;
	  max_line_height = line_height;
	  goto restart;
	}
      return 1;
    }


  {
    unsigned int i = 0;
    glyph_cache_t *g;

    NSPoint p;
    
    NSFont *f = cache->font;
    float f_ascender = [f ascender], f_descender = -[f descender];

    NSGlyph last_glyph = NSNullGlyph;
    NSPoint last_p;

    unsigned int first_glyph;
    line_frag_t *lf = line_frags;
    int lfi = 0;

    BOOL prev_was_attachment;


    last_p = p = NSMakePoint(0,0);

    g = cache;
    first_glyph = 0;
    prev_was_attachment = NO;
    /*
    Main glyph layout loop.
    */
    while (1)
      {
/*printf("at %3i+%2i, glyph %08x, char %04x (%i)\n",
	cache_base,i,
	g->g,
	[[curTextStorage string] characterAtIndex: g->char_index],g->char_index);*/

	/* Update the cache. */
	if (i >= cache_length)
	  {
	    if (at_end)
	      break;
	    [self _cacheGlyphs: cache_length + 16];
	    if (i == cache_length)
	      break;
	    g = cache + i;
	  }

	/*
	At this point:

	  p is the current point (sortof); the point where a nominally
	  spaced glyph would be placed.

	  g is the current glyph. i is the current glyph index, relative to
	  the start of the cache.

	  last_p and last_glyph are used for kerning and hold the previous
	  glyph and its position. If there's no previous glyph (for kerning
	  purposes), last_glyph is NSNullGlyph and last_p is undefined.

	  lf and lfi track the current line frag rect. first_glyph is the
	  first glyph in the current line frag rect.

	Note that the variables tracking the previous glyph shouldn't be
	updated until we know that the current glyph will fit in the line
	frag rect.

	*/

	/* If there's a font change, check if the baseline or line height
	needs adjusting. We update the ascender and descender too, even
	though there might not actually be any glyphs for this font.
	(TODO?) */
	if (g->font != f)
	  {
	    float new_height;
	    f = g->font;
	    f_ascender = [f ascender];
	    f_descender = -[f descender];
	    last_glyph = NSNullGlyph;

	    new_height = [f defaultLineHeightForFont];

	    if (f_ascender > ascender)
	      ascender = f_ascender;
	    if (f_descender > descender)
	      descender = f_descender;

	    COMPUTE_BASELINE;

	    WANT_LINE_HEIGHT(new_height);
	  }

	if (g->g == NSControlGlyph)
	  {
	    unichar ch = [[curTextStorage string] characterAtIndex: g->char_index];

	    /* TODO: need to handle other control characters */

	    g->pos = p;
	    g->size.width = 0;
	    g->dont_show = YES;
	    g->nominal = !prev_was_attachment;
	    i++;
	    g++;
	    last_glyph = NSNullGlyph;

	    prev_was_attachment = NO;

	    if (ch == 0xa)
	      break;

	    continue;
	  }


	/* Set up glyph information. */

	/*
	TODO:
	Currently, the attributes of the attachment character (eg. font)
	affect the layout. Think hard about this.
	*/
	g->nominal = !prev_was_attachment;

	if (g->attributes.explicit_kern &&
	    g->attributes.kern != 0)
	  {
	    p.x += g->attributes.kern;
	    g->nominal = NO;
	  }

	/* Baseline adjustments. */
	{
	  float y = 0;

	  /* Attributes are up-side-down in our coordinate system. */
	  if (g->attributes.superscript)
	    {
	      y -= g->attributes.superscript * [f xHeight];
	    }
	  if (g->attributes.baseline_offset)
	    {
	      /* And baseline_offset is up-side-down again. TODO? */
	      y += g->attributes.baseline_offset;
	    }

	  if (y != p.y)
	    {
	      p.y = y;
	      g->nominal = NO;
	    }

	  /* The y==0 case is taken care of when the font is changed. */
	  if (y < 0 && f_ascender - y > ascender)
	    ascender = f_ascender - y;
	  if (y > 0 && f_descender + y > descender)
	    descender = f_descender + y;

	  COMPUTE_BASELINE;
	  WANT_LINE_HEIGHT(ascender + descender);
	}

	if (g->g == GSAttachmentGlyph)
	  {
	    NSTextAttachment *attach = [curTextStorage attribute: NSAttachmentAttributeName
		atIndex: g->char_index
		effectiveRange: NULL];
	    NSTextAttachmentCell *cell = [attach attachmentCell];
	    NSRect r;

	    if (!cell)
	      {
		g->pos = p;
		g->size = NSMakeSize(0,0);
		g->dont_show = YES;
		g->nominal = YES;
		i++;
		g++;
		last_glyph = NSNullGlyph;
		continue;
	      }

	    r = [cell cellFrameForTextContainer: curTextContainer
		  proposedLineFragment: lf->rect
		  glyphPosition: p
		  characterIndex: g->char_index];

/*	    printf("cell at %i, (%g %g) in (%g %g)+(%g %g), got rect (%g %g)+(%g %g)\n",
	      g->char_index,p.x,p.y,
	      lf->rect.origin.x,lf->rect.origin.y,
	      lf->rect.size.width,lf->rect.size.height,
	      r.origin.x,r.origin.y,
	      r.size.width,r.size.height);*/

	    /* For some obscure reason, the rectangle we get is up-side-down
	    compared to everything else here, and has it's origin in p.
	    (Makes sense from the cell's pov, though.) */

	    if (-NSMinY(r) > descender)
	      descender = -NSMinY(r);

	    if (NSMaxY(r) > ascender)
	      ascender = NSMaxY(r);

	    /* Update ascender and descender. Adjust line height and
	    baseline if necessary. */
	    COMPUTE_BASELINE;
	    WANT_LINE_HEIGHT(ascender + descender);

	    g->size = r.size;
	    g->pos.x = p.x + r.origin.x;
	    g->pos.y = p.y + r.origin.y;

	    p.x = g->pos.x + g->size.width;

	    /* An attachment is always in a point range of its own. */
	    g->nominal = NO;
	  }
	else
	  {
	    /* TODO: this is a major bottleneck */
/*	    if (last_glyph)
	      {
		p = [f positionOfGlyph: g->g
		      precededByGlyph: last_glyph
		      isNominal: &g->nominal];
		p.x += last_p.x;
		p.y += last_p.y;
	      }*/

	    last_p = g->pos = p;
	    g->size = [f advancementForGlyph: g->g]; /* only width is used */
	    p.x += g->size.width;
	  }

	/* Did the glyph fit in the line frag rect? */
	if (p.x > lf->rect.size.width)
	  {
	    /* It didn't. Try to break the line. */
	    switch ([curParagraphStyle lineBreakMode])
	      { /* TODO: implement all modes */
	      default:
	      case NSLineBreakByCharWrapping:
	      char_wrapping:
		lf->last_glyph = i;
		break;

	      case NSLineBreakByWordWrapping:
		lf->last_glyph = [self breakLineByWordWrappingBefore: cache_base + i] - cache_base;
		if (lf->last_glyph <= first_glyph)
		  goto char_wrapping;
		break;
	      }

	    /* We force at least one glyph into each line frag rect. This
	    ensures that typesetting will never get stuck (ie. if the text
	    container is to narrow to fit even a single glyph). */
	    if (lf->last_glyph <= first_glyph)
	      lf->last_glyph = i + 1;

	    last_p = p = NSMakePoint(0,0);
	    i = lf->last_glyph;
	    g = cache + i;
	    /* The -1 is always valid since there's at least one glyph in the
	    line frag rect (see above). */
	    lf->last_used = g[-1].pos.x + g[-1].size.width;
	    last_glyph = NSNullGlyph;
	    prev_was_attachment = NO;

	    lf++;
	    lfi++;
	    if (lfi == num_line_frags)
	      break;
	    first_glyph = i;
	  }
	else
	  {
	    /* Move to next glyph. */
	    last_glyph = g->g;
	    if (last_glyph == GSAttachmentGlyph)
	      {
		last_glyph = NSNullGlyph;
		prev_was_attachment = YES;
	      }
	    else
	      {
		prev_was_attachment = NO;
	      }
	    i++;
	    g++;
	  }
      }
    /* Basic layout is done. */

    /* Take care of the alignments. */
    if (lfi != num_line_frags)
      {
	lf->last_glyph = i;
	lf->last_used = p.x;

	/* TODO: incorrect if there is more than one line frag */
	if ([curParagraphStyle alignment] == NSRightTextAlignment)
	  [self rightAlignLine: line_frags : num_line_frags];
	else if ([curParagraphStyle alignment] == NSCenterTextAlignment)
	  [self centerAlignLine: line_frags : num_line_frags];

	newParagraph = YES;
      }
    else
      {
	if ([curParagraphStyle lineBreakMode] == NSLineBreakByWordWrapping &&
	    [curParagraphStyle alignment] == NSJustifiedTextAlignment)
	  [self fullJustifyLine: line_frags : num_line_frags];
	else if ([curParagraphStyle alignment] == NSRightTextAlignment)
	  [self rightAlignLine: line_frags : num_line_frags];
	else if ([curParagraphStyle alignment] == NSCenterTextAlignment)
	  [self centerAlignLine: line_frags : num_line_frags];

	lfi--;
	newParagraph = NO;
      }

    /* Layout is complete. Package it and give it to the layout manager. */
    [curLayoutManager setTextContainer: curTextContainer
		      forGlyphRange: NSMakeRange(cache_base, i)];
    curGlyph = i + cache_base;
    {
      line_frag_t *lf;
      NSPoint p;
      unsigned int i, j;
      glyph_cache_t *g;
      NSRect used_rect;

      for (lf = line_frags, i = 0, g = cache; lfi >= 0; lfi--, lf++)
	{
	  used_rect.origin.x = g->pos.x + lf->rect.origin.x;
	  used_rect.size.width = lf->last_used - g->pos.x;
	  /* TODO: be pickier about height? */
	  used_rect.origin.y = lf->rect.origin.y;
	  used_rect.size.height = lf->rect.size.height;

	  [curLayoutManager setLineFragmentRect: lf->rect
			    forGlyphRange: NSMakeRange(cache_base + i,lf->last_glyph - i)
			    usedRect: used_rect];
	  p = g->pos;
	  /* TODO: probably don't need to call unless the flags are YES */
	  [curLayoutManager setDrawsOutsideLineFragment: g->outside_line_frag
			    forGlyphAtIndex: cache_base + i];
	  [curLayoutManager setNotShownAttribute: g->dont_show
			    forGlyphAtIndex: cache_base + i];
	  p.y += baseline;
	  j = i;
	  while (i < lf->last_glyph)
	    {
	      if (!g->nominal && i != j)
		{
		  [curLayoutManager setLocation: p
				    forStartOfGlyphRange: NSMakeRange(cache_base + j, i - j)];
		  if (g[-1].g == GSAttachmentGlyph)
		    {
		      [curLayoutManager setAttachmentSize: g[-1].size
			forGlyphRange: NSMakeRange(cache_base + j, i - j)];
		    }
		  p = g->pos;
		  p.y += baseline;
		  j = i;
		}
	      i++;
	      g++;
	    }
	  if (i != j)
	    {
	      [curLayoutManager setLocation: p
				forStartOfGlyphRange: NSMakeRange(cache_base + j,i - j)];
	      if (g[-1].g == GSAttachmentGlyph)
		{
		  [curLayoutManager setAttachmentSize: g[-1].size
		    forGlyphRange: NSMakeRange(cache_base + j, i - j)];
		}
	    }
	}
    }
  }

  curPoint = NSMakePoint(0,NSMaxY(line_frags->rect));

  if (line_frags)
    {
      free(line_frags);
      line_frags = NULL;
    }

  /* TODO: if we're really at the end, we should probably set the extra
  line frag stuff here */
  if (newParagraph)
    return 3;
  else
    return 0;
}


-(int) layoutGlyphsInLayoutManager: (GSLayoutManager *)layoutManager
		   inTextContainer: (NSTextContainer *)textContainer
	      startingAtGlyphIndex: (unsigned int)glyphIndex
	  previousLineFragmentRect: (NSRect)previousLineFragRect
		    nextGlyphIndex: (unsigned int *)nextGlyphIndex
	     numberOfLineFragments: (unsigned int)howMany
{
  int ret = 0;
  BOOL newParagraph;

  [lock lock];

NS_DURING
  curLayoutManager = layoutManager;
  curTextContainer = textContainer;
  curTextStorage = [layoutManager textStorage];

/*	printf("*** layout some stuff |%@|\n",curTextStorage);
	[curLayoutManager _glyphDumpRuns];*/

  curGlyph = glyphIndex;

  [self _cacheClear];

  newParagraph = NO;
  if (!curGlyph)
    newParagraph = YES;

  ret = 0;
  curPoint = NSMakePoint(0,NSMaxY(previousLineFragRect));
  while (1)
    {
      ret = [self layoutLineNewParagraph: newParagraph];
      if (ret == 3)
	{
	  newParagraph = YES;
	  ret = 0;
	}
      else
	newParagraph = NO;
      if (ret)
	break;

      if (howMany)
	if (!--howMany)
	  break;
   }

  *nextGlyphIndex = curGlyph;
NS_HANDLER
  [lock unlock];
//  printf("got exception %@\n",localException);
  [localException raise];
NS_ENDHANDLER
  [lock unlock];
  return ret;
}


@end

