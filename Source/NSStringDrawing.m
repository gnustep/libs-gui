/*
   NSStringDrawing.m

   Categories which add drawing capabilities to NSAttributedString
   and NSString.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
#include <AppKit/AppKit.h>

/*
 * A function called by NSApplication to ensure that this file is linked
 * when it should be.
 */
void
GSStringDrawingDummyFunction()
{
}

static NSCharacterSet	*whitespace;
static NSCharacterSet	*newlines;
static NSCharacterSet	*separators;
static NSFont		*defFont;
static NSParagraphStyle	*defStyle;
static NSColor		*defFgCol;
static NSColor		*defBgCol;
static SEL		advSel = @selector(advancementForGlyph:);

static BOOL (*isSepImp)(NSCharacterSet*, SEL, unichar);

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

      whitespace = [[NSCharacterSet whitespaceCharacterSet] retain];

      /*
       * Build a character set containing only newline characters.
       */
      ms = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
      [ms formIntersectionWithCharacterSet: [whitespace invertedSet]];
      newlines = [ms copy];
      [ms release];

      /*
       * Build a character set containing only word separators.
       */
      ms = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
      [ms formUnionWithCharacterSet: whitespace];
      separators = [ms copy];
      [ms release];

      isSepImp = (BOOL (*)(NSCharacterSet*, SEL, unichar))
	[separators methodForSelector: @selector(characterIsMember:)];

      defStyle = [NSParagraphStyle defaultParagraphStyle];
      [defStyle retain];
      defBgCol = nil;
      beenHere = YES;
    }

  /*
   * These defaults could change during the running of the program if the
   * user defaults are changed.
   */
  defFont = [NSFont userFontOfSize: 12];
  defFgCol = [NSColor textColor];
}

static inline BOOL
isSeparator(unichar c)
{
  return (*isSepImp)(separators, @selector(characterIsMember:), c);
}

#define	ADVANCEMENT(X)	(*advImp)(font, advSel, (X))

/*
 *	The 'sizeLine()' function is called to determine the size of a single
 *	line of text (specified by the 'range' argument) that may be part of
 *	a larger attributed string.
 *	If will also return the position of the baseline of the text within
 *	the bounding rectangle as an offset from the bottom of the rectangle.
 *	The 'line' range is shortened to indicate any line wrapping.
 */
static NSSize
sizeLine(NSAttributedString *str,
	NSParagraphStyle *style,
	NSRange *para,
	BOOL first,
	float *baseptr)
{
  unsigned	pos = para->location;
  unsigned	end = pos + para->length;
  unsigned	lastSepIndex;
  float		lastSepOffset;
  NSLineBreakMode lbm;
  NSArray	*tabStops = [style tabStops];
  unsigned	numTabs = [tabStops count];
  unsigned	nextTab = 0;
  NSSize	size = NSMakeSize(0, 0);
  float		baseline = 0;
  float		maxx;
  NSFont	*oldFont = nil;
  NSSize	(*advImp)(NSFont*, SEL, NSGlyph);

  if (pos >= end)
    return size;

  /*
   * Perform initial horizontal positioning
   */
  if (first)
    size.width = [style firstLineHeadIndent];
  else
    size.width = [style headIndent];

  /*
   * Initialise possible linebreak points.
   */
  lbm = [style lineBreakMode];
  lastSepIndex = 0;
  lastSepOffset = size.width;

  /*
   * Determine the end of a line - use a very large value if the style does
   * not give us an eol relative to our starting point.
   */
  maxx = [style tailIndent];
  if (maxx <= 0.0)
    maxx = 1.0E8;

  while (pos < end)
    {
      NSFont		*font;
      int		superscript;
      int		ligature;
      float		base;
      float		kern;
      NSNumber		*num;
      NSRange		maxRange;
      NSRange		range;
      float		below;
      float		above;

      // Maximum range is up to end of line.
      maxRange = NSMakeRange(pos, end - pos);

      // Get font and range over which it applies.
      font = (NSFont*)[str attribute: NSFontAttributeName
			     atIndex: pos
		      effectiveRange: &range];
      if (font == nil)
	font = defFont;
      if (font != oldFont)
	{
	  oldFont = font;
	  advImp = (NSSize (*)(NSFont*, SEL, NSGlyph))
	    [font methodForSelector: advSel];
	}
      maxRange = NSIntersectionRange(maxRange, range);

      // Get baseline offset and range over which it applies.
      num = (NSNumber*)[str attribute: NSBaselineOffsetAttributeName 
			      atIndex: pos
		       effectiveRange: &range];
      if (num == nil)
	base = 0.0;
      else
	base = [num floatValue];
      maxRange = NSIntersectionRange(maxRange, range);

      // Get kern attribute and range over which it applies.
      num = (NSNumber*)[str attribute: NSKernAttributeName 
			      atIndex: pos
		       effectiveRange: &range];
      if (num == nil)
	kern = 0.0;
      else
	kern = [num floatValue];
      maxRange = NSIntersectionRange(maxRange, range);

      // Get superscript and range over which it applies.
      num = (NSNumber*)[str attribute: NSSuperscriptAttributeName 
			      atIndex: pos
		       effectiveRange: &range];
      if (num == nil)
	superscript = 0;
      else
	superscript = [num intValue];
      maxRange = NSIntersectionRange(maxRange, range);

      // Get ligature attribute and range over which it applies.
      num = (NSNumber*)[str attribute: NSLigatureAttributeName 
			      atIndex: pos
		       effectiveRange: &range];
      if (num == nil)
	ligature = 1;
      else
	ligature = [num intValue];
      maxRange = NSIntersectionRange(maxRange, range);

      /*
       * See if the height of the bounding rectangle needs to grow to fit
       * the font for this text.
       */
      // FIXME - superscript should have some effect on height.

      below = -([font descender]);
      above = [font pointSize];
      if (base > 0)
	above += base;		// Character is above baseline.
      else if (base < 0)
	below -= base;		// Character is below baseline.
      if (below > baseline)
	baseline = below;
      if (size.height < baseline + above)
	size.height = baseline + above;

      /*
       * Now we add the widths of the characters.
       */
      // FIXME - ligature should have some effect on width.
      range = maxRange;
      if (range.length > 0)
	{
	  unichar	chars[range.length];
	  unsigned	i = 0;
	  float		width = 0;

	  [[str string] getCharacters: chars range: range];
	  while (i < range.length && width < maxx)
	    {
	      unsigned	tabIndex = i;

	      while (tabIndex < range.length)
		{
		  if (chars[tabIndex] == '\t')
		    break;
		  tabIndex++;
		}

	      if (tabIndex == i)
		{
		  NSTextTab	*tab;

		  /*
		   *	Either advance to next tabstop or by a space if
		   *	there are no more tabstops.
		   */
		  while (nextTab < numTabs)
		    {
		      tab = [tabStops objectAtIndex: nextTab];
		      if ([tab location] > size.width)
			break;
		      nextTab++;
		    }
		  if (nextTab < numTabs)
		    width = [tab location];
		  else
		    {
		      NSSize	adv;

		      adv = ADVANCEMENT(' ');
		      width = size.width + adv.width;
		    }
		  if (width > maxx)
		    break;
		  /*
		   * In case we need to word-wrap, we must record this
		   * as a possible linebreak position.
		   */
		  if (lbm == NSLineBreakByWordWrapping)
		    {
		      lastSepIndex = pos + i;
		      lastSepOffset = size.width;
		    }
		  size.width = width;
		  i++;			// Point to next char.
		}
	      else
		{
		  while (i < tabIndex)
		    {
		      NSSize	adv;

		      adv = ADVANCEMENT(chars[i]);
		      width = size.width + adv.width + kern;
		      if (width > maxx)
			break;
		      if (lbm == NSLineBreakByWordWrapping
			&& isSeparator(chars[i]))
			{
			  lastSepIndex = pos + i;
			  lastSepOffset = size.width;
			}
		      size.width = width;
		      i++;
		    }
		}
	    }

	  if (width > maxx)
	    {
	      if (lbm == NSLineBreakByWordWrapping)
		{
		  unichar	c;

		  /*
		   * Word wrap - if the words are separated by whitespace
		   * we discard the whitespace character - is this right?.
		   */
		  pos = lastSepIndex;
		  size.width = lastSepOffset;
		  c = [[str string] characterAtIndex: pos];
		  if ([whitespace characterIsMember: c])
		    pos++;
		}
	      else if (lbm == NSLineBreakByCharWrapping)
		{
		  /*
		   * Simply do a linebreak at the current character position.
		   */
		  pos += i;
		}
	      else
		{
		  /*
		   * Truncate line.
		   */
		  size.width = maxx;
		  pos = end;
		}
		  
	      break;
	    }
	  else
	    {
	      pos = NSMaxRange(range);	// Next position in string.
	    }
	}
    }

  /*
   * Adjust the range 'para' to specify the characters in this line.
   */
  para->length = (pos - para->location);

  if (baseptr)
    *baseptr = baseline;
  return size;
}


/*
 *	I know it's severely sub-optimal, but the NSString methods just
 *	use NSAttributes string to do the job.
 */
@implementation NSString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [NSAttributedString allocWithZone: NSDefaultMallocZone()];
  [a initWithString: self attributes: attrs];
  [a drawAtPoint: point];
  [a release];
}

- (void) drawInRect: (NSRect)rect withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [NSAttributedString allocWithZone: NSDefaultMallocZone()];
  [a initWithString: self attributes: attrs];
  [a drawInRect: rect];
  [a release];
}

- (NSSize) sizeWithAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;
  NSSize		s;

  a = [NSAttributedString allocWithZone: NSDefaultMallocZone()];
  [a initWithString: self attributes: attrs];
  s = [a size];
  [a release];
  return s;
}
@end



@implementation NSAttributedString (NSStringDrawing)

/*
 * A GSGlyphInfo is usee to maintain information about a single glyph
 */
typedef struct {
  NSGlyph	glyph;		// The glyph to be drawn.
  NSSize	adv;		// How far to move to draw next glyph.
  unsigned	pos;		// Position in attributed string.
} GSGlyphInfo;

/*
 * A GSGlyphArray structure is used to keep track of how many slots in an
 * array of GSGlyphInfo structures have been allocated to GSTextRuns
 */
typedef struct {
  unsigned	used;
  GSGlyphInfo	*glyphs;
} GSGlyphArray;

typedef struct {
  NSFont		*font;		// Last font used.
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
  NSFont	*font;
  NSColor	*bg;
  NSColor	*fg;
  int		underline;
  int		superscript;
  float		base;
  float		kern;
  float		ypos;
  int		ligature;
  struct GSTextRunStruct *last;
  struct GSTextRunStruct *next;
} GSTextRun;

static void
drawRun(GSTextRun *run, NSPoint origin, GSDrawInfo *draw)
{
  /*
   * Adjust the drawing origin so that the y coordinate is at the baseline
   * of the font.
   */
  if (draw->flip)
    {
      origin.y += (run->height - run->baseline);
    }
  else
    {
      origin.y -= (run->height - run->baseline);
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
    }

  /*
   * Now draw the text.
   * FIXME - should actually draw glyphs - at present we just use ascii.
   */
  if (run->kern == 0)
    {
      char	buf[run->glyphCount + 1];
      unsigned	i;

      for (i = 0; i < run->glyphCount; i++)
	{
	  buf[i] = (char)run->glyphs[i].glyph;
	}
      buf[i] = '\0';
      DPSmoveto(draw->ctxt, origin.x, origin.y);
      DPSshow(draw->ctxt, buf);
#ifdef XDPS_BACKEND_LIBRARY
      /* FIXME: Hack to force DGS to flush the text */
      DPSrectfill(draw->ctxt, 0, 0, 0.5, 0.5);
#endif
    }
  else
    {
      char	buf[2];
      unsigned	i;

      buf[1] = '\0';
      for (i = 0; i < run->glyphCount; i++)
        {
	  buf[0] = (char)run->glyphs[i].glyph;
	  DPSmoveto(draw->ctxt, origin.x, origin.y);
	  DPSshow(draw->ctxt, buf);
	  origin.x += run->glyphs[i].adv.width;
	}
#ifdef XDPS_BACKEND_LIBRARY
      /* FIXME: Hack to force DGS to flush the text */
      DPSrectfill(draw->ctxt, 0, 0, 0.5, 0.5);
#endif
    }

  if (run->underline)
    {
      DPSmoveto(draw->ctxt, origin.x, origin.y);
      DPSlineto(draw->ctxt, origin.x + run->width, origin.y);
    }
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
    run->superscript = 0;
  else
    run->superscript = [num intValue];

  // Get baseline offset
  num = (NSNumber*)[attr objectForKey: NSBaselineOffsetAttributeName]; 
  if (num == nil)
    run->base = 0.0;
  else
    run->base = [num floatValue];

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
   * FIXME - should include superscript information here.
   */
  below = -([run->font descender]);
  above = [run->font pointSize];
  if (run->base > 0)
    above += run->base;		// Character is above baseline.
  else if (run->base < 0)
    below -= run->base;		// Character is below baseline.
  run->baseline = below;
  run->height = run->baseline + above;

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
	      gi->pos = pos++;
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
	      gi->pos = pos++;
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
  while (run != 0)
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
setupChunk(GSTextChunk *chunk, NSAttributedString *str, NSRange range,
	GSGlyphArray *g, GSTextChunk *last)
{
  GSTextRun	*lastRun = 0;
  NSDictionary	*attr;
  unsigned	start = range.location;
  unsigned	loc = start;
  unsigned	end = NSMaxRange(range);
  NSString	*string = [str string];
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
	  range.length -= (range.location - loc);
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
setupLine(GSTextLine *line, NSAttributedString *str, NSRange range,
	GSGlyphArray *g, NSParagraphStyle *style, BOOL first)
{
  GSTextChunk	*lastChunk = 0;
  NSString	*string = [str string];
  NSArray	*tabs = [style tabStops];
  float		maxh = [style maximumLineHeight];
  unsigned	start = range.location;
  unsigned	end = NSMaxRange(range);
  unsigned	numTabs = [tabs count];
  unsigned	nextTab = 0;
#define	NO_R_MARGIN	1.0E8

  line->alignment = [style alignment];
  line->lineBreakMode = [style lineBreakMode];
  line->height = [style minimumLineHeight];
  line->rmargin = [style tailIndent];
  if (line->rmargin <= 0.0)
    line->rmargin = NO_R_MARGIN;

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
	  setupChunk(&line->chunk0, str, chunkRange, g, 0);
	  lastChunk = &line->chunk0;
	}
      else
	{
	  GSTextChunk	*chunk;

	  chunk = (GSTextChunk*)objc_malloc(sizeof(GSTextChunk));
	  setupChunk(chunk, str, chunkRange, g, lastChunk);
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

- (void) drawAtPoint: (NSPoint)point
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  BOOL			isFlipped = [[ctxt focusView] isFlipped];
  NSString		*allText = [self string];
  unsigned		length = [allText length];
  unsigned		paraPos = 0;
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
	      style = (NSParagraphStyle*)[self
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

	    setupLine(&current, self, line, &garray, style, YES);
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

- (void) drawInRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

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

  [self drawAtPoint: point];
}

- (NSSize) size
{
  NSString		*allText = [self string];
  unsigned		length = [allText length];
  unsigned		paraPos = 0;
  NSParagraphStyle	*style = nil;
  GSTextLine		current;
  NSSize		size = NSMakeSize(0,0);

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
	      style = (NSParagraphStyle*)[self
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
	    GSTextChunk		*chunk;

	    garray.used = 0;
	    garray.glyphs = info;

	    setupLine(&current, self, line, &garray, style, YES);

	    chunk = &current.chunk0;
	    while (chunk->next != 0)
	      chunk = chunk->next;
	    if (chunk->xpos + chunk->width > size.width)
	      size.width = chunk->xpos + chunk->width;
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


#if 1
- (NSSize) sizeRange: (NSRange) lineRange
{
  return [[self attributedSubstringFromRange: lineRange] size];
}

- (void) drawRange: (NSRange) lineRange atPoint: (NSPoint) aPoint
{
  [[self attributedSubstringFromRange: lineRange] drawAtPoint: aPoint];
}

- (void) drawRange: (NSRange) lineRange inRect: (NSRect)aRect
{
  [[self attributedSubstringFromRange: lineRange] drawInRect: aRect];
}

#else
- (NSSize) sizeRange: (NSRange) lineRange
{
  NSRect retRect = NSZeroRect;
  NSRange currRange = NSMakeRange (lineRange.location, 0);
  NSPoint currPoint = NSMakePoint (0, 0);
  NSString *string = [self string];
  

  for (; NSMaxRange (currRange) < NSMaxRange (lineRange);) // draw all "runs"
    {
      NSDictionary *attributes = [self attributesAtIndex: NSMaxRange(currRange) 
				       longestEffectiveRange: &currRange 
				       inRange: lineRange];
      NSString *substring = [string substringWithRange: currRange];
      NSRect sizeRect = NSMakeRect (currPoint.x, 0, 0, 0);
      
      sizeRect.size = [substring sizeWithAttributes: attributes];
      retRect = NSUnionRect (retRect, sizeRect);
      currPoint.x += sizeRect.size.width;
      //<!> size attachments
    } 
  return retRect.size;
}

- (void) drawRange: (NSRange) lineRange atPoint: (NSPoint) aPoint
{
  NSRange currRange = NSMakeRange (lineRange.location, 0);
  NSPoint currPoint;
  NSString *string = [self string];
  
  for (currPoint = aPoint; NSMaxRange (currRange) < NSMaxRange (lineRange);)
    {
      // draw all "runs"
      NSDictionary *attributes = [self attributesAtIndex: NSMaxRange(currRange) 
				       longestEffectiveRange: &currRange 
				       inRange: lineRange];
      NSString *substring = [string substringWithRange: currRange];
      [substring drawAtPoint: currPoint withAttributes: attributes];
      currPoint.x += [substring sizeWithAttributes: attributes].width;
      //<!> draw attachments
    }
}

- (void) drawRange: (NSRange)aRange inRect: (NSRect)aRect
{
  NSString *substring = [[self string] substringWithRange: aRange];
  
  [substring drawInRect: aRect
	     withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: 
					     [NSFont systemFontOfSize: 12.0], 
					     NSFontAttributeName,
					     [NSColor blueColor], 
					     NSForegroundColorAttributeName,
					     nil]];
}
#endif

@end
