/** <title>NSStringAdditions</title>

   <abstract>Categories which add drawing capabilities to NSAttributedString
   and NSString.</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Mar 1999 - rewrite from scratch

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

#include <Foundation/Foundation.h>
#include <AppKit/NSStringDrawing.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/AppKit.h>
#include "GSTextStorage.h"

// For the encoding functions
#include <base/Unicode.h>

#define	NO_R_MARGIN	1.0E8

/*
 * A function called by NSApplication to ensure that this file is linked
 * when it should be.
 */
void
GSStringDrawingDummyFunction()
{
}

static NSCharacterSet	*newlines;
static NSFont		*defFont;
static NSParagraphStyle	*defStyle;
static NSColor		*defFgCol;
static NSColor		*defBgCol;
static SEL		advSel;

/*
 *	Thne 'checkInit()' function is called to ensure that any static
 *	variables required by the string drawing code are initialised.
 */
static void
checkInit()
{
  static BOOL beenHere = NO;

  if (beenHere == NO)
    {
      NSMutableCharacterSet	*ms;
      NSCharacterSet	*whitespace;

      advSel = @selector(advancementForGlyph:);

      whitespace = RETAIN([NSCharacterSet whitespaceCharacterSet]);

      /*
       * Build a character set containing only newline characters.
       */
      ms = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
      [ms formIntersectionWithCharacterSet: [whitespace invertedSet]];
      newlines = [ms copy];
      RELEASE(ms);

      defStyle = [NSParagraphStyle defaultParagraphStyle];
      RETAIN(defStyle);
      defBgCol = nil;
      beenHere = YES;
    }

  /*
   * These defaults could change during the running of the program if the
   * user defaults are changed.
   */
  defFont = [NSFont userFontOfSize: 0];
  defFgCol = [NSColor textColor];
}

/*
 * A GSGlyphInfo is used to maintain information about a single glyph
 */
typedef struct {
  NSGlyph	glyph;		// The glyph to be drawn.
  NSSize	adv;		// How far to move to draw next glyph.
} GSGlyphInfo;

/*
 * A GSGlyphArray structure is used to keep track of how many slots in an
 * array of GSGlyphInfo structures have been allocated to GSTextRuns
 */
typedef struct {
  unsigned	size;
  unsigned	used;
  GSGlyphInfo	*glyphs;
} GSGlyphArray;

typedef struct {
  NSFont		*font;		// Last font used.
  NSStringEncoding      enc;            // The encoding of the font
  NSColor		*color;		// Last color used.
  NSGraphicsContext	*ctxt;		// Drawing context.
  BOOL			flip;		// If view is flipped.
} GSDrawInfo;

/*
 * A GSTextRun structure is used to hold information about a run of characters
 * identical attributes.
 */
typedef struct GSTextRunStruct {
  unsigned	glyphCount;	// Number of glyphs in run.
  GSGlyphInfo	*glyphs;	// Starting glyph.
  float		width;		// Width of entire run.
  float		height;		// Height of entire run.
  float		baseline;	// Where to draw glyphs.
  // These fields are for normal glyphs
  NSFont	*font;
  NSColor	*bg;
  NSColor	*fg;
  int		underline;
  int		superscript;
  float		base;
  float		kern;
  int		ligature;
  // Fields for special glyphs
  id <NSTextAttachmentCell> cell;
  unsigned charIndex;

  // Forward and backward link
  struct GSTextRunStruct *last;
  struct GSTextRunStruct *next;
} GSTextRun;

static void
drawSpecialRun(GSTextRun *run, NSPoint origin, GSDrawInfo *draw)
{
  // Currently this is only used for attachments
  id <NSTextAttachmentCell> cell = run->cell;
  unsigned charIndex = run->charIndex;
  NSRect cellFrame = NSMakeRect(origin.x, (draw->flip ?  
					   origin.y - run->glyphs[0].adv.height : 
					   origin.y), 
				run->glyphs[0].adv.width,
				run->glyphs[0].adv.height);
  NSView *controlView = [draw->ctxt focusView];

  [cell drawWithFrame: cellFrame 
	       inView: controlView 
       characterIndex: charIndex
	layoutManager: nil];
}

static void
drawRun(GSTextRun *run, NSPoint origin, GSDrawInfo *draw)
{
  /*
   * Adjust the drawing origin so that the y coordinate is at the baseline
   * of the font.
   */
  if (draw->flip)
    {
      origin.y -= run->base;
    }
  else
    {
      origin.y += run->base;
    }

  if (run->glyphs[0].glyph == NSControlGlyph)
    {
      drawSpecialRun(run, origin, draw);
      return;
    }

  /*
   * Set current font and color if necessary.
   */
  if (draw->color != run->fg)
    {
      [run->fg set];
      draw->color = run->fg;
    }

  if (draw->font != run->font)
    {
      [run->font set];
      draw->font = run->font;
      draw->enc = [run->font mostCompatibleStringEncoding];
    }

  /*
   * Now draw the text.
   * FIXME - should actually draw glyphs - at present we just use ascii.
   */
  if (run->kern == 0)
    {
      unsigned	i;
      NSStringEncoding enc = draw->enc;

      // glyph is an unicode char value
      // if the font has non-standard encoding we need to remap it.
      unichar u[run->glyphCount];
      char *r;
      unsigned l = run->glyphCount;
      unsigned s = 0;

      for (i = 0; i < run->glyphCount; i++)
        u[i] = run->glyphs[i].glyph;

      if (GSFromUnicode((unsigned char**)&r, &s, u, l, enc,
			     NSDefaultMallocZone(), GSUniTerminate) == NO)
        {
          [NSException raise: NSCharacterConversionException
                      format: @"Can't convert to/from Unicode string."];
        }

      DPSmoveto(draw->ctxt, origin.x, origin.y);
      if (l)
	DPSshow(draw->ctxt, r);
    }
  else
    {
      char	buf[2];
      unsigned	i;
      NSStringEncoding enc = draw->enc;

      buf[1] = '\0';
      for (i = 0; i < run->glyphCount; i++)
        {
	  // glyph is an unicode char value
	  // if the font has non-standard encoding we need to remap it.
	  if ((enc != NSASCIIStringEncoding) && 
	      (enc != NSUnicodeStringEncoding))
	    {
	      unsigned int  size = 1;
	      unsigned char c = 0;
	      unsigned char *dst = buf;

	      GSFromUnicode(&dst, &size, &(run->glyphs[i].glyph), 1, enc, 0, 0);
	    }
	  else
	    {
	      buf[0] = (char)run->glyphs[i].glyph;
	    }
	  DPSmoveto(draw->ctxt, origin.x, origin.y);
	  DPSshow(draw->ctxt, buf);
	  origin.x += run->glyphs[i].adv.width;
	}
    }

  if (run->underline)
    {
      DPSmoveto(draw->ctxt, origin.x, origin.y);
      DPSlineto(draw->ctxt, origin.x + run->width, origin.y);
      DPSstroke(draw->ctxt);
    }
}

static void
setupSpecialRun(GSTextRun *run, unsigned length, unichar *chars, unsigned pos,
		NSDictionary *attr)
{
  NSTextAttachment *attachment = [attr objectForKey: NSAttachmentAttributeName];

  run->cell = [attachment attachmentCell];
  run->charIndex = pos;
  run->glyphs[0].glyph = NSControlGlyph;
  // We should better call the cellFrameForTextContainer:... method here
  run->glyphs[0].adv = [run->cell cellSize];

  run->baseline = [run->cell cellBaselineOffset].y;
  run->height = run->glyphs[0].adv.height;
  run->width = run->glyphs[0].adv.width;
  // Unset the normale fields
  run->font = nil;
  run->bg = nil;
  run->fg = nil;
}

static void
setupRun(GSTextRun *run, unsigned length, unichar *chars, unsigned pos,
	NSDictionary *attr, GSGlyphArray *g, GSTextRun *last)
{
  NSNumber	*num;
  unsigned	i;
  float		above;
  float		below;

  /*
   * Add run to linked list after the previous run.
   */
  run->next = 0;
  run->last = last;
  if (last != 0)
    last->next = run;

  /*
   * Assign a section of the glyphs array to hold info for this run.
   */
  run->glyphCount = length;
  run->glyphs = &g->glyphs[g->used];
  g->used += run->glyphCount;

  if (chars[0] == NSAttachmentCharacter)
    {
      setupSpecialRun(run, length, chars, pos, attr);
      return;
    }

  // Get font to be used by characters in run.
  run->font = (NSFont*)[attr objectForKey: NSFontAttributeName];
  if (run->font == nil)
    run->font = defFont;

  // Get background color
  run->bg = (NSColor*)[attr objectForKey: NSBackgroundColorAttributeName]; 
  if (run->bg == nil)
    run->bg = defBgCol;

  // Get foreground color
  run->fg = (NSColor*)[attr objectForKey: NSForegroundColorAttributeName]; 
  if (run->fg == nil)
    run->fg = defFgCol;

  // Get underline style
  num = (NSNumber*)[attr objectForKey: NSUnderlineStyleAttributeName]; 
  if (num == nil)
    run->underline = GSNoUnderlineStyle;	// No underline
  else
    run->underline = [num intValue];

  // Get superscript
  num = (NSNumber*)[attr objectForKey: NSSuperscriptAttributeName]; 
  if (num == nil)
    run->base = 0.0;
  else
    // interprete as a baseline change without font change
    run->base = 3.0 * [num intValue];

  // Get baseline offset
  num = (NSNumber*)[attr objectForKey: NSBaselineOffsetAttributeName]; 
  if (num != nil)
    run->base = [num floatValue];
  // Else, use value from superscript!

  // Get kern attribute
  num = (NSNumber*)[attr objectForKey: NSKernAttributeName]; 
  if (num == nil)
    run->kern = 0.0;
  else
    run->kern = [num floatValue];

  // Get ligature attribute
  num = (NSNumber*)[attr objectForKey: NSLigatureAttributeName]; 
  if (num == nil)
    run->ligature = 1;
  else
    run->ligature = [num intValue];

  /*
   * Calculate height of line from font information and base offset.
   */
  below = -([run->font descender]);
  above = [run->font pointSize];
  if (run->base > 0)
    above += run->base;		// Character is above baseline.
  else if (run->base < 0)
    below -= run->base;		// Character is below baseline.
  run->baseline = below;
  run->height = below + above;

  /*
   *	Get the characters for this run from the string and set up the
   *    array of glyphs, allong with their advancement information.
   *	As we build the array, we keep a total of the run width.
   *	FIXME This code should really look at the string and determine
   *	glyphs properly rather than assuming that the unicode character
   *	is the same as the glyph (which will not always be true).
   *	At the moment, we are ignoring unicode character composition and
   *	are ignoring ligatures.
   */
  if (length > 0)
    {
      NSSize		(*advImp)(NSFont*, SEL, NSGlyph);
      NSFont		*font = run->font;
      float		kern = run->kern;
      float		width = 0;

      advImp = (NSSize (*)(NSFont*, SEL, NSGlyph))
	[run->font methodForSelector: advSel];

      if (kern == 0)
	{
	  /* Special case - if no kerning, we can do things a bit quicker. */
	  for (i = 0; i < length; i++)
	    {
	      GSGlyphInfo	*gi = &run->glyphs[i];

	      gi->glyph = (NSGlyph)chars[i];
	      gi->adv = (*advImp)(font, advSel, gi->glyph);
	      width += gi->adv.width;
	    }
	}
      else
	{
	  for (i = 0; i < length; i++)
	    {
	      GSGlyphInfo	*gi = &run->glyphs[i];

	      gi->glyph = (NSGlyph)chars[i];
	      gi->adv = (*advImp)(font, advSel, gi->glyph);
	      gi->adv.width += kern;
	      width += gi->adv.width;
	    }
	}

      run->width = width;
    }
  else
    {
      run->width = 0;
    }
}

/*
 * A GSTextChunk structure is used to maintain a list of GSTextRuns that make
 * up the text between two tabstops.
 */
typedef	struct GSTextChunkStruct {
  GSTextRun	run0;		// Starting run in chunk.
  float		width;		// Width of entire chunk.
  float		height;		// Height of entire chunk.
  float		baseline;	// Baseline for characters.
  float		xpos;		// Position of chunk in line.
  float		decimal;	// Position of decimal point.
  struct GSTextChunkStruct *last;
  struct GSTextChunkStruct *next;
} GSTextChunk;

static void
drawChunk(GSTextChunk *chunk, NSPoint origin, GSDrawInfo *draw)
{
  GSTextRun	*run = &chunk->run0;

  origin.x += chunk->xpos;
  if (draw->flip)
    {
      origin.y += (chunk->height - chunk->baseline);
    }
  else
    {
      origin.y -= (chunk->height - chunk->baseline);
    }
  while (run)
    {
      drawRun(run, origin, draw);
      origin.x += run->width;
      run = run->next;
    }
}

/*
 *	emptyChunk() - release memory used by all chunks after this one,
 *	and release all dynamically allocated runs in this chunk (ie all
 *	but 'run0').
 */
static void
emptyChunk(GSTextChunk *chunk)
{
  while (chunk->run0.next != 0)
    {
      GSTextRun	*tmp = chunk->run0.next;

      chunk->run0.next = tmp->next;
      objc_free(tmp);
    }
  if (chunk->next != 0)
    {
      emptyChunk(chunk->next);
      objc_free(chunk->next);
      chunk->next = 0;
    }
}

static void
setupChunk(GSTextChunk *chunk, NSAttributedString *str, NSString* string, 
	   NSRange range, GSGlyphArray *g, GSTextChunk *last)
{
  GSTextRun	*lastRun = 0;
  NSDictionary	*attr;
  unsigned	start = range.location;
  unsigned	loc = start;
  unsigned	end = NSMaxRange(range);
  unichar	chars[range.length];

  [string getCharacters: chars range: range];

  /*
   * Add chunk to linked list after the previous chunk.
   */
  chunk->next = 0;
  chunk->last = last;
  if (last != 0)
    last->next = chunk;

  chunk->xpos = 0;
  chunk->width = 0;
  chunk->height = 0;
  chunk->baseline = 0;
  chunk->decimal = -1;		// Not yet valid.

  /*
   *	Build up all the runs in this chunk - a run is a sequence of characters
   *	with the same attributes.
   */
  do
    {
      unsigned	where;
      unsigned	length;

      attr = [str attributesAtIndex: loc effectiveRange: &range];
      if (range.location < loc)
	{
	  range.length -= (loc - range.location);
	  range.location = loc;
	}
      if (NSMaxRange(range) > end)
	range.length = end - range.location;

      where = loc - start;
      length = range.length;
      if (lastRun == 0)
	{
	  setupRun(&chunk->run0, length, &chars[where], loc, attr, g, 0);
	  lastRun = &chunk->run0;
	}
      else
	{
	  GSTextRun	*run = (GSTextRun*)objc_malloc(sizeof(GSTextRun));

	  setupRun(run, length, &chars[where], loc, attr, g, lastRun);
	  lastRun = run;
	} 

      chunk->width += lastRun->width;
      if (lastRun->baseline > chunk->baseline)
	chunk->baseline = lastRun->baseline;
      if (lastRun->height > chunk->height)
	chunk->height = lastRun->height;

      loc = NSMaxRange(range);
    }
  while (loc < end);

  if (lastRun == 0)
    setupRun(&chunk->run0, 0, 0, start, nil, g, 0);
}

/*
 * The chunkDecimal() function searches a chunk of text for the first decimal
 * point and returns it's position within the chunk.  This is used for decimal
 * tabs.
 */
static float
chunkDecimal(GSTextChunk *chunk)
{
  if (chunk->decimal < 0)
    {
      GSTextRun	*run = &chunk->run0;

      chunk->decimal = 0;
      while (run != 0)
	{
	  unsigned	i;
	  GSGlyphInfo	*gi = run->glyphs;

	  for (i = 0; i < run->glyphCount; i++)
	    {
	      if (gi[i].glyph == (NSGlyph)'.')
		break;
	      chunk->decimal += gi[i].adv.width;
	    }
	  run = run->next;
	}
    }
  return chunk->decimal;
}

/*
 * The GSTextLine structure is used to maintain information about a
 * complete line of text consisting of one or more GSTextChunks.
 */
typedef	struct GSTextLine {
  GSTextChunk		chunk0;		// Starting run in chunk.
  float			width;		// Width of entire chunk.
  float			height;		// Height of entire chunk.
  NSArray		*tabs;		// Tabstops in line.
  float			indent;		// Position of start of line.
  float			rmargin;	// Position of end of line.
  float			leading;	// Space below line.
  NSTextAlignment	alignment;	// Alignment for entire line.
  NSLineBreakMode	lineBreakMode;	// How to deal with long lines.
} GSTextLine;

static void
emptyLine(GSTextLine *line)
{
  emptyChunk(&line->chunk0);
}

/*
 * The backLine() function draws the text background for a line of text.
 * FIXME - is this behavior what we want?
 * We actually fill the entire line including the inter-line space (leading)
 * with whatever background color is used by the text at any point.
 */
static void
backLine(GSTextLine *line, NSGraphicsContext *ctxt, NSPoint origin, BOOL flip)
{
  NSRect	fillrect;
  GSTextChunk	*chunk = &line->chunk0;
  NSColor	*bg;
  float		offset = origin.x;

  fillrect.origin.y = origin.y;
  fillrect.size.height = line->height + line->leading;
  if (flip == NO)
    fillrect.origin.y -= fillrect.size.height;

  fillrect.origin.x = line->chunk0.xpos;

  bg = line->chunk0.run0.bg;
  while (chunk != 0)
    {
      GSTextRun	*run = &chunk->run0;

      fillrect.size.width = chunk->xpos - fillrect.origin.x;

      while (run != 0)
	{
	  if (run->bg == bg)
	    {
	      fillrect.size.width += run->width;
	    }
	  else
	    {
	      if (bg != nil)
		{
		  [bg set];
		  fillrect.origin.x += offset;
		  NSRectFill(fillrect);
		  fillrect.origin.x -= offset;
		}
	      bg = run->bg;
	      fillrect.origin.x += fillrect.size.width;
	      fillrect.size.width = 0;
	    }
	  run = run->next;
	}
      chunk = chunk->next;
    }

  if (bg != nil && fillrect.size.width > 0)
    {
      [bg set];
      fillrect.origin.x += offset;
      NSRectFill(fillrect);
    }
}

static void
drawLine(GSTextLine *line, NSGraphicsContext *ctxt, NSPoint origin, BOOL flip)
{
  GSTextChunk	*chunk = &line->chunk0;
  GSDrawInfo	draw;

  backLine(line, ctxt, origin, flip);

  draw.font = nil;
  draw.color = nil;
  draw.ctxt = ctxt;
  draw.flip = flip;

  while (chunk != 0)
    {
      drawChunk(chunk, origin, &draw);
      chunk = chunk->next;
    }
}

static GSTextChunk*
setupLine(GSTextLine *line, NSAttributedString *str, NSString* string, NSRange range,
	  GSGlyphArray *g, NSParagraphStyle *style, float rMargin, BOOL first)
{
  GSTextChunk	*lastChunk = 0;
  NSArray	*tabs = [style tabStops];
  float		maxh = [style maximumLineHeight];
  unsigned	start = range.location;
  unsigned	end = NSMaxRange(range);
  unsigned	numTabs = [tabs count];
  unsigned	nextTab = 0;

  line->alignment = [style alignment];
  line->lineBreakMode = [style lineBreakMode];
  line->height = [style minimumLineHeight];
  line->rmargin = [style tailIndent];
  if (line->rmargin <= 0.0)
    line->rmargin += rMargin;

  if (first)
    line->indent = [style firstLineHeadIndent];
  else
    line->indent = [style headIndent];
  line->width = line->indent;

  line->leading = [style lineSpacing];

  do
    {
      NSRange	tabRange;
      NSRange	chunkRange;
 
      /*
       * Locate a tab or end-of-line and set the chunk range to be the range
       * up to (but not including) the tab.
       */
      tabRange = [string rangeOfString: @"\t"
			       options: NSLiteralSearch
				 range: range];
      if (tabRange.length == 0)
	tabRange.location = end;
      chunkRange.location = range.location;
      chunkRange.length = tabRange.location - range.location;

      /*
       * Load information about the text chunk upto the tabstop into a
       * GSTextChunk structure.
       */
      if (lastChunk == 0)
	{
	  setupChunk(&line->chunk0, str, string, chunkRange, g, 0);
	  lastChunk = &line->chunk0;
	}
      else
	{
	  GSTextChunk	*chunk;

	  chunk = (GSTextChunk*)objc_malloc(sizeof(GSTextChunk));
	  setupChunk(chunk, str, string, chunkRange, g, lastChunk);
	  lastChunk = chunk;
	}

      /*
       * Advance our range past the tab we found, or to the end-of-line
       */
      range.location = NSMaxRange(tabRange);
      range.length = end - range.location;

      if (chunkRange.location > start)
	{
	  float	offset;
	  BOOL	found = NO;

	  /*
	   * We have had a tab before this chunk, try to align at a tabstop
	   */
	  while (found == NO && nextTab < numTabs)
	    {
	      NSTextTab		*tab = [tabs objectAtIndex: nextTab++];
	      float		loc = [tab location];

	      if (loc > line->width)
		{
		  NSTextTabType	type = [tab tabStopType];

		  if (type == NSLeftTabStopType)
		    {
		      lastChunk->xpos = loc;
		      found = YES;
		    }
		  else if (type == NSRightTabStopType
		    && loc - (offset = lastChunk->width) > line->width)
		    {
		      lastChunk->xpos = loc - offset;
		      found = YES;
		    }
		  else if (type == NSCenterTabStopType
		    && loc - (offset = lastChunk->width/2.0) > line->width)
		    {
		      lastChunk->xpos = loc - offset;
		      found = YES;
		    }
		  else if (type == NSDecimalTabStopType
		    && loc - (offset = chunkDecimal(lastChunk)) > line->width)
		    {
		      lastChunk->xpos = loc - offset;
		      found = YES;
		    }
		}
	    }
	  if (found == NO)
	    {
	      /*
	       * No more tabs - run this chunk on directly from last.
	       */
	      lastChunk->xpos = line->width;
	    }
	}
      else if (range.location >= end)
	{
	  /*
	   * There are no tabs in this line - align by paragraph style.
	   * FIXME - NSNaturalTextAlignment should have different effects
	   * depending on script in use.
	   */
	  if (line->alignment == NSLeftTextAlignment
	    || line->alignment == NSNaturalTextAlignment
	    || line->rmargin == NO_R_MARGIN)
	    {
	      /*
	       * Simple left alignment.
	       */
	      lastChunk->xpos = line->width;
	    }
	  else if (line->alignment == NSRightTextAlignment)
	    {
	      lastChunk->xpos = line->rmargin - lastChunk->width;
	    }
	  else if (line->alignment == NSCenterTextAlignment)
	    {
	      lastChunk->xpos = line->rmargin - line->width - lastChunk->width;
	      lastChunk->xpos = (lastChunk->xpos / 2.0) + line->width;
	    }
	  else if (line->alignment == NSJustifiedTextAlignment)
	    {
	      // FIXME - need to support justified text.
	      lastChunk->xpos = line->width;
	    }
	  else
	    {
	      lastChunk->xpos = line->width;
	    }
	}
      else
	{
	  /*
	   * First chunk on a line with tabs - simply align to left.
	   */
	  lastChunk->xpos = line->width;
	}

      /*
       * FIXME - should check for line-break and handle long lines here.
       * If we break a line, we should return the first chunk of the next line.
       */
/*
      if (lastChunk->xpos + lastChunk->width > line->rmargin)
      {
	NSLineBreakMode lbm = line->lineBreakMode;  
	unsigned pos = 0;
	unisgned i;
	float xpos = lastChunk->xpos;

	// find the first character that does not fit on the line
	for (i = chunkRange.location; i < NSMaxRange(chunkRange); i++)
	  {
	    float adv = g[i].adv.width;
	    
	    if (xpos + adv > line->rmargin)
	      break;
	    xpos += adv;
	  }

	if (lbm == NSLineBreakByWordWrapping)
	  {
	    // Get break position from string
	    pos = [str lineBreakBeforeIndex: i
	              withinRange: chunkRange];
	  }
	else if (lbm == NSLineBreakByCharWrapping)
	  {
	    // Simply do a linebreak at the current character position.
	    pos = i;
	  }
	else
	  {
	    // Truncate line.
	    //pos = NSMaxRange(chunkRange);
	  }
	  // Break up the last chunk
          // FIXME We should try to reuse as much as possible 
	  if (pos)
	    {
	      NSRange newRange = NSMakeRange(chunkRange.location, pos-chunkRange.location);
	      end = pos;
	      empty_chunk(lastChunk);
	      setupChunk(lastChunk, str, string, newRange, g, lastChunk->last);
	    }

      }
*/

      /*
       * Now extend line width to add the new chunk and adjust the line
       * height if necessary.
       */
      line->width = lastChunk->xpos + lastChunk->width;
      if (lastChunk->height > line->height)
	{
	  line->height = lastChunk->height;
	  if (maxh > 0 && line->height > maxh)
	    line->height = maxh;
	}
    }
  while (range.location < end);

  /*
   * If we got here, we are on the last line in the paragraph, so we use the
   * paragraph spacing rather than line spacing as our leading.
   */
  line->leading = [style paragraphSpacing];

  return 0;
}

static void
drawAttributedString(NSAttributedString *str, NSString *allText, NSRange aRange, 
		     NSPoint point, float width, NSGraphicsContext *ctxt)
{
  BOOL			isFlipped = [[ctxt focusView] isFlipped];
  unsigned		length = NSMaxRange(aRange);
  unsigned		paraPos = aRange.location;
  NSRange		styleRange;
  NSParagraphStyle	*style = nil;
  GSTextLine		current;

  checkInit();

  /*
   * Now produce output on a per-line basis.
   */
  while (paraPos < length)
    {
      NSRange	para;		// Range of current paragraph.
      NSRange	line;		// Range of current line.
      NSRange	eol;		// Range of newline character.
      unsigned	position;	// Position in NSString.

      /*
       * Determine the range of the next paragraph of text (in 'para') and set
       * 'paraPos' to point after the terminating newline character (if any).
       */
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

      do
	{
	  if (style == nil || NSMaxRange(styleRange) > position)
	    {
	      style = (NSParagraphStyle*)[str
				    attribute: NSParagraphStyleAttributeName
				      atIndex: position
			       effectiveRange: &styleRange];
	      if (style == nil)
		style = defStyle;
	    }
    
	  /*
	   * Assemble drawing information for the entire line.
	   */
	  line = para;
	  {
	    GSGlyphInfo		info[line.length];
	    GSGlyphArray	garray;

	    garray.used = 0;
	    garray.size = line.length;
	    garray.glyphs = info;

	    setupLine(&current, str, allText, line, &garray, style, width, YES);
	    drawLine(&current, ctxt, point, isFlipped);

	    if (isFlipped)
	      point.y += current.height + current.leading;
	    else
	      point.y -= current.height + current.leading;

	    emptyLine(&current);
	  }
	  para.length -= line.length;
	  para.location += line.length;
	}
      while (para.location < eol.location);
    }
}

static NSSize
sizeAttributedString(NSAttributedString *str, NSString *allText, NSRange aRange)
{
  unsigned		length = NSMaxRange(aRange);
  unsigned		paraPos = aRange.location;
  NSParagraphStyle	*style = nil;
  GSTextLine		current;
  NSSize		size = NSMakeSize(0,0);
  float rMargin = NO_R_MARGIN;

  checkInit();

  while (paraPos < length)
    {
      NSRange	para;		// Range of current paragraph.
      NSRange	line;		// Range of current line.
      NSRange	eol;		// Range of newline character.
      unsigned	position;	// Position in NSString.
      BOOL	firstLine = YES;

      /*
       * Determine the range of the next paragraph of text (in 'para') and set
       * 'paraPos' to point after the terminating newline character (if any).
       */
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

      do
	{
	  if (firstLine == YES)
	    {
	      style = (NSParagraphStyle*)[str
				    attribute: NSParagraphStyleAttributeName
				      atIndex: position
			       effectiveRange: 0];
	      if (style == nil)
		style = defStyle;
	    }
    
	  /*
	   * Assemble drawing information for the entire line.
	   */
	  line = para;
	  {
	    GSGlyphInfo		info[line.length];
	    GSGlyphArray	garray;

	    garray.used = 0;
	    garray.glyphs = info;

	    setupLine(&current, str, allText, line, &garray, style, rMargin, YES);
	    if (current.width > size.width)
	      size.width = current.width;
	    size.height += current.height + current.leading;

	    emptyLine(&current);
	  }
	  para.length -= line.length;
	  para.location += line.length;
	}
      while (para.location < eol.location);
    }

  return size;
}
 


@implementation NSAttributedString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point
{
  NSGraphicsContext	*ctxt = GSCurrentContext();

  drawAttributedString(self, [self string], NSMakeRange(0, [self length]), 
		       point, NO_R_MARGIN, ctxt);
}

- (void) drawInRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

  /* FIXME: This is an extremely lossy and temporary workaround for
     the fact that we should draw only inside rect. */
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSgsave(ctxt);
  NSRectClip (rect);

  /*
   * Since [-drawAtPoint:] positions the top-left corner of the text at
   * the point, we locate the top-left corner of the rectangle to do the
   * drawing.
   */
  point.x = rect.origin.x;
  if ([view isFlipped])
    point.y = rect.origin.y;
  else
    point.y = rect.origin.y + rect.size.height;

  drawAttributedString(self, [self string], NSMakeRange(0, [self length]), 
		       point, rect.size.width, ctxt);

  /* Restore matching the DPSgsave used in the temporary workaround */
  DPSgrestore(ctxt);
}

- (NSSize) size
{
  return sizeAttributedString(self, [self string], NSMakeRange(0, [self length]));
}

// GNUstep extensions.
- (NSSize) sizeRange: (NSRange) lineRange
{
  return sizeAttributedString(self, [self string], lineRange);
}

- (void) drawRange: (NSRange) lineRange atPoint: (NSPoint) point
{
  NSGraphicsContext	*ctxt = GSCurrentContext();

  drawAttributedString(self, [self string], lineRange, point, NO_R_MARGIN,
		       ctxt);
}

- (void) drawRange: (NSRange) lineRange inRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

  /* FIXME: This is an extremely lossy and temporary workaround for
     the fact that we should draw only inside rect. */
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSgsave(ctxt);
  NSRectClip (rect);

  /*
   * Since [-drawAtPoint:] positions the top-left corner of the text at
   * the point, we locate the top-left corner of the rectangle to do the
   * drawing.
   */
  point.x = rect.origin.x;
  if ([view isFlipped])
    point.y = rect.origin.y;
  else
    point.y = rect.origin.y + rect.size.height;

  drawAttributedString(self, [self string], lineRange, point, rect.size.width,
		       ctxt);
  /* Restore matching the DPSgsave used in the temporary workaround */
  DPSgrestore(ctxt);
}

@end


@implementation GSTextStorage (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point
{
  NSGraphicsContext	*ctxt = GSCurrentContext();

  drawAttributedString(self, _textChars, NSMakeRange(0, [self length]), 
		       point, NO_R_MARGIN, ctxt);
}

- (void) drawInRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

  /* FIXME: This is an extremely lossy and temporary workaround for
     the fact that we should draw only inside rect. */
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSgsave(ctxt);
  NSRectClip (rect);

  /*
   * Since [-drawAtPoint:] positions the top-left corner of the text at
   * the point, we locate the top-left corner of the rectangle to do the
   * drawing.
   */
  point.x = rect.origin.x;
  if ([view isFlipped])
    point.y = rect.origin.y;
  else
    point.y = rect.origin.y + rect.size.height;

  drawAttributedString(self, _textChars, NSMakeRange(0, [self length]), 
		       point, rect.size.width, ctxt);

  /* Restore matching the DPSgsave used in the temporary workaround */
  DPSgrestore(ctxt);
}

- (NSSize) size
{
  return sizeAttributedString(self, _textChars, NSMakeRange(0, [self length]));
}

// GNUstep extensions.
- (NSSize) sizeRange: (NSRange) lineRange
{
  return sizeAttributedString(self, _textChars, lineRange);
}

- (void) drawRange: (NSRange) lineRange atPoint: (NSPoint) point
{
  NSGraphicsContext	*ctxt = GSCurrentContext();

  drawAttributedString(self, _textChars, lineRange, point, NO_R_MARGIN,
		       ctxt);
}

- (void) drawRange: (NSRange) lineRange inRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

  /* FIXME: This is an extremely lossy and temporary workaround for
     the fact that we should draw only inside rect. */
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSgsave(ctxt);
  NSRectClip (rect);

  /*
   * Since [-drawAtPoint:] positions the top-left corner of the text at
   * the point, we locate the top-left corner of the rectangle to do the
   * drawing.
   */
  point.x = rect.origin.x;
  if ([view isFlipped])
    point.y = rect.origin.y;
  else
    point.y = rect.origin.y + rect.size.height;

  drawAttributedString(self, _textChars, lineRange, point, rect.size.width,
		       ctxt);
  /* Restore matching the DPSgsave used in the temporary workaround */
  DPSgrestore(ctxt);
}

@end


/*
 *	I know it's severely sub-optimal, but the NSString methods just
 *	use NSAttributes string to do the job.
 */
@implementation NSString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()] 
	  initWithString: self attributes: attrs];
  [a drawAtPoint: point];
  RELEASE(a);
}

- (void) drawInRect: (NSRect)rect withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()]
	  initWithString: self attributes: attrs];
  [a drawInRect: rect];
  RELEASE(a);
}

- (NSSize) sizeWithAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;
  NSSize		s;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()]
	  initWithString: self attributes: attrs];
  s = [a size];
  RELEASE(a);
  return s;
}
@end
