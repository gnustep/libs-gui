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

static NSCharacterSet	*nlset;
static NSFont		*defFont;
static NSParagraphStyle	*defStyle;
static NSColor		*defFgCol;
static NSColor		*defBgCol;

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
      NSCharacterSet		*not_ws;
      NSMutableCharacterSet	*new_set;

      /*
       * Build a character set containing only newline characters.
       */
      not_ws = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
      new_set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
      [new_set formIntersectionWithCharacterSet: not_ws];
      nlset = [new_set copy];
      [new_set release];

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

/*
 *	The 'sizeLine()' function is called to determine the size of a single
 *	line of text (specified by the 'range' argument) that may be part of
 *	a larger attributed string.
 *	If will also return the position of the baseline of the text within
 *	the bounding rectangle as an offset from the bottom of the rectangle.
 */
static NSSize
sizeLine(NSAttributedString *str, NSRange line, BOOL first, float *baseptr)
{
  unsigned	pos = line.location;
  unsigned	end = NSMaxRange(line);
  NSSize	size = NSMakeSize(0, 0);
  float		baseline = 0;

  while (pos < end)
    {
      NSFont		*font;
      NSParagraphStyle	*style;
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
      maxRange = NSIntersectionRange(maxRange, range);

      // Get style and range over which it applies.
      style = (NSParagraphStyle*)[str attribute: NSParagraphStyleAttributeName
					atIndex: pos
				 effectiveRange: &range];
      if (style == nil)
	style = defStyle;
      maxRange = NSIntersectionRange(maxRange, range);
      /*
       * Perform initial horizontal positioning
       */
      if (pos == line.location)
	{
	  if (first)
	    size.width = [style firstLineHeadIndent];
	  else
	    size.width = [style headIndent];
	}

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

      below = [font descender];
      above = [font pointSize] - below;
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
      pos = NSMaxRange(range);	// Next position in string.
      if (range.length > 0)
	{
	  unichar	chars[range.length];
	  NSArray	*tabStops = [style tabStops];
	  unsigned	numTabs = [tabStops count];
	  unsigned	nextTab = 0;
	  unsigned	i;

	  [[str string] getCharacters: chars range: range];
	  for (i = 0; i < range.length; i++)
	    {
	      if (chars[i] == '\t')
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
		    size.width = [tab location];
		  else
		    size.width += [font advancementForGlyph: ' '].width;
		}
	      else
		{
		  size.width += [font advancementForGlyph: chars[i]].width;
		  size.width += kern;
		}
	    }
	}
    }
  if (baseptr)
    *baseptr = baseline;
  return size;
}

/* FIXME completely ignores paragraph style attachments and other layout info */
- (void) drawAtPoint: (NSPoint)point
{
  NSGraphicsContext	*ctxt = [NSGraphicsContext currentContext];
  NSString		*allText = [self string];
  unsigned		length = [allText length];
  unsigned		linePos = 0;
  BOOL			isFlipped = [[ctxt focusView] isFlipped];
  NSParagraphStyle	*style = nil;
  BOOL			first = YES;

  checkInit();

  /*
   * Now produce output on a per-line basis.
   */
  while (linePos < length)
    {
      NSRange	line;		// Range of current line.
      NSRange	eol;		// Rnage of newline character.
      unsigned	position;	// Position in NSString.
      NSSize	lineSize;
      float	baseline;
      float	xpos = 0;

      /*
       * Determine the range of the next line of text (in 'line') and set
       * 'linePos' to point after the terminating newline character (if any).
       */
      line = NSMakeRange(linePos, length - linePos);
      eol = [allText rangeOfCharacterFromSet: nlset
				     options: NSLiteralSearch
				       range: line];

      if (eol.length == 0)
	eol.location = length;
      else
	line.length = eol.location - line.location;
      linePos = NSMaxRange(eol);
      position = line.location;

      if (first == NO)
	{
	  NSParagraphStyle	*newStyle;
	  NSColor		*bg;
	  float			leading;

	  /*
	   * Check to see if the new line begins with the same paragraph style
	   * that the old ended in. This information is used to handle what
	   * happens between lines and whether the new line is also a new
	   * paragraph.
	   */
	  newStyle = (NSParagraphStyle*)[self
				attribute: NSParagraphStyleAttributeName
				  atIndex: position
			   effectiveRange: 0];
	  if ([style isEqual: newStyle])
	    {
	      leading = [style lineSpacing];
	    }
	  else
	    {
	      leading = [style paragraphSpacing];
	      first = YES;
	    }

	  if (isFlipped)
	    point.y -= leading;
	  else
	    point.y += leading;

	  /*
	   * Fill the inter-line/interparagraph space with the background
	   * color in use at the end of the last paragraph.
           */
          bg = (NSColor*)[self attribute: NSBackgroundColorAttributeName
                                 atIndex: position - 1
                          effectiveRange: 0];
          if (bg == nil)
            bg = defBgCol;

	  if (bg != nil)
	    {
	      NSRect	fillrect;

	      fillrect.origin = point;
	      fillrect.size.width = lineSize.width;
	      fillrect.size.height = leading;
	      [bg set];
	      if (isFlipped == NO)
		fillrect.origin.y -= fillrect.size.height;
	      NSRectFill(fillrect);
	    }
	}

      /*
       * Calculate sizing information for the entire line.
       */
      lineSize = sizeLine(self, line, first, &baseline);

      while (position < eol.location)
	{
	  NSAttributedString		*subAttr;
	  NSString		*subString;
	  NSSize		size;
	  NSFont		*font;
	  NSColor		*bg;
	  NSColor		*fg;
	  int			underline;
	  int			superscript;
	  float			base;
	  float			kern;
	  float			ypos;
	  int			ligature;
	  NSNumber		*num;
	  NSRange		maxRange;
	  NSRange		range;

	  // Maximum range is up to end of line.
	  maxRange = NSMakeRange(position, eol.location - position);

	  // Get font and range over which it applies.
	  font = (NSFont*)[self attribute: NSFontAttributeName
				  atIndex: position
			   effectiveRange: &range];
	  if (font == nil)
	    font = defFont;
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get style and range over which it applies.
	  style = (NSParagraphStyle*)[self
				attribute: NSParagraphStyleAttributeName
				  atIndex: position
			   effectiveRange: &range];
	  if (style == nil)
	    style = defStyle;
	  maxRange = NSIntersectionRange(maxRange, range);
	
	  // Get background color and range over which it applies.
	  bg = (NSColor*)[self attribute: NSBackgroundColorAttributeName 
				 atIndex: position
			  effectiveRange: &range];
	  if (bg == nil)
	    bg = defBgCol;
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get foreground color and range over which it applies.
	  fg = (NSColor*)[self attribute: NSForegroundColorAttributeName 
				 atIndex: position
			  effectiveRange: &range];
	  if (fg == nil)
	    fg = defFgCol;
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get underline style and range over which it applies.
	  num = (NSNumber*)[self attribute: NSUnderlineStyleAttributeName 
				   atIndex: position
			    effectiveRange: &range];
	  if (num == nil)
	    underline = GSNoUnderlineStyle;	// No underline
	  else
	    underline = [num intValue];
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get superscript and range over which it applies.
	  num = (NSNumber*)[self attribute: NSSuperscriptAttributeName 
				   atIndex: position
			    effectiveRange: &range];
	  if (num == nil)
	    superscript = 0;
	  else
	    superscript = [num intValue];
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get baseline offset and range over which it applies.
	  num = (NSNumber*)[self attribute: NSBaselineOffsetAttributeName 
				   atIndex: position
			    effectiveRange: &range];
	  if (num == nil)
	    base = 0.0;
	  else
	    base = [num floatValue];
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get kern attribute and range over which it applies.
	  num = (NSNumber*)[self attribute: NSKernAttributeName 
				   atIndex: position
			    effectiveRange: &range];
	  if (num == nil)
	    kern = 0.0;
	  else
	    kern = [num floatValue];
	  maxRange = NSIntersectionRange(maxRange, range);

	  // Get ligature attribute and range over which it applies.
	  num = (NSNumber*)[self attribute: NSLigatureAttributeName 
				   atIndex: position
			    effectiveRange: &range];
	  if (num == nil)
	    ligature = 1;
	  else
	    ligature = [num intValue];
	  maxRange = NSIntersectionRange(maxRange, range);

	  /*
	   *	If this is a new line - adjust for indentation.
	   */
	  if (position == line.location)
	    {
	      NSRect	fillrect;

	      fillrect.origin = point;
	      fillrect.size = lineSize;

	      if (first)
		xpos = [style firstLineHeadIndent];
	      else
		xpos += [style headIndent];

	      fillrect.size.width = xpos;
	      if (bg != nil && fillrect.size.width > 0)
		{
		  [bg set];
		  if (isFlipped == NO)
		    fillrect.origin.y -= fillrect.size.height;
		  NSRectFill(fillrect);
		}
	    }

	  /*
	   * Now, at last we have all the required text drawing attributes and
	   * we have a range over which ALL of them apply.  We update our
	   * position to point past this range, then we grab the substring from
	   * the range, draw it, and update our drawing position.
	   */
	  range = maxRange;
	  position = NSMaxRange(range);	// Next position in string.
	  subAttr = [self attributedSubstringFromRange: range];
	  subString = [subAttr string];
	  size.width = [font widthOfString: subString];
	  size.height = [font pointSize];

	  if (range.length > 0)
	    {
	      unichar	chars[range.length];
	      NSArray	*tabStops = [style tabStops];
	      unsigned	numTabs = [tabStops count];
	      unsigned	nextTab = 0;
	      unsigned	i;

	      [[self string] getCharacters: chars range: range];

	      /*
	       * If we have a background color set - we fill in the
	       * region occupied by this substring.
	       */
	      if (bg)
		{
		  float		oldx = xpos;
		  NSRect	rect;


		  for (i = 0; i < range.length; i++)
		    {
		      if (chars[i] == '\t')
			{
			  NSTextTab	*tab;

			  /*
			   *	Either advance to next tabstop or by a space
			   *	if there are no more tabstops.
			   */
			  while (nextTab < numTabs)
			    {
			      tab = [tabStops objectAtIndex: nextTab];
			      if ([tab location] > xpos)
				break;
			      nextTab++;
			    }
			  if (nextTab < numTabs)
			    xpos = [tab location];
			  else
			    xpos += [font advancementForGlyph: ' '].width;
			}
		      else
			{
			  xpos += [font advancementForGlyph: chars[i]].width;
			  xpos += kern;
			}
		    }
		  
		  rect.origin.x = point.x + oldx;
		  rect.origin.y = point.y;
		  rect.size.height = lineSize.height;
		  rect.size.width = xpos - oldx;
		  xpos = oldx;
		  if (isFlipped == NO)
		    rect.origin.y -= lineSize.height;

		  [bg set];
		  NSRectFill(rect);
		}

	      /*
	       * Set font and color, then draw the substring.
	       * NB. Our origin is top-left of the string so we need to
	       * calculate a vertical coordinate for the baseline of the
	       * text produced by psshow.
	       */
	      [fg set];
	      [font set];
	      if (isFlipped)
		ypos = point.y + lineSize.height - baseline - base;
	      else
		ypos = point.y - lineSize.height + baseline + base;

	      for (i = 0; i < range.length; i++)
		{
		  if (chars[i] == '\t')
		    {
		      NSTextTab	*tab;

		      /*
		       *	Either advance to next tabstop or by a space
		       *	if there are no more tabstops.
		       */
		      while (nextTab < numTabs)
			{
			  tab = [tabStops objectAtIndex: nextTab];
			  if ([tab location] > xpos)
			    break;
			  nextTab++;
			}
		      if (nextTab < numTabs)
			xpos = [tab location];
		      else
			xpos += [font advancementForGlyph: ' '].width;
		    }
		  else
		    {
		      char	buf[2];

		      xpos += kern;
		      DPSmoveto(ctxt, point.x + xpos, ypos);
		      /*
		       * FIXME Eugh - we simply assume that the unichar string
		       * actually contains ascii characters and render them
		       * using dpsshow
		       */
		      buf[0] = chars[i];
		      buf[1] = '\0';
		      DPSshow(ctxt, buf);
		      xpos += [font advancementForGlyph: chars[i]].width;
		    }
		}
	    }

	  if (underline == NSSingleUnderlineStyle)
	    {
	      DPSmoveto(ctxt, point.x, ypos);
	      DPSlineto(ctxt, point.x + xpos - 1, ypos);
	    }
	}
      if (isFlipped)
	point.y += lineSize.height;
      else
	point.y -= lineSize.height;
      first = NO;
    }
}

- (void) drawInRect: (NSRect)rect
{
  NSPoint	point;
  NSView	*view = [NSView focusView];

  NSRectClip(rect);

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
  NSRectClip([view bounds]);
}

/* FIXME completely ignores paragraph style attachments and other layout info */
- (NSSize) size
{
  unsigned	length = [self length];
  unsigned	position = 0;
  float		height = 0;
  float		width = 0;

  while (position < length)
    {
      NSRange	range;
      NSFont	*font;
      NSString	*subString;

      font = (NSFont*)[self attribute: NSFontAttributeName
			      atIndex: position
		       effectiveRange: &range];
      subString = [[self attributedSubstringFromRange: range] string];
      width += [font widthOfString: subString];
      height = MAX([font pointSize], height);
      position = NSMaxRange(range);
    }

  return NSMakeSize(width, height);
}

@end

