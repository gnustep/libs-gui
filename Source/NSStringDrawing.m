/*
   NSStringDrawing.m

   Categories which add measure capabilities to NSAttributedString
   and NSString.

   Copyright (C) 1997,1999 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Aug 1998
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

static NSCharacterSet	*nlset = nil;

/* FIXME completely ignores paragraph style attachments and other layout info */
- (void) drawAtPoint: (NSPoint)point
{
  NSGraphicsContext	*ctxt = [NSGraphicsContext currentContext];
  NSString		*allText = [self string];
  unsigned		length = [allText length];
  unsigned		linePos = 0;
  NSFont		*defFont = [NSFont userFontOfSize: 12];
  NSParagraphStyle	*defStyle = [NSParagraphStyle defaultParagraphStyle];
  NSColor		*defFgCol = [NSColor textColor];
  NSColor		*defBgCol = nil;
  BOOL			isFlipped = [[ctxt focusView] isFlipped];
  NSPoint		start = point;

  /*
   * Build a character set containing only newline characters if necessary.
   */
  if (nlset == nil)
    {
      NSCharacterSet		*not_ws;
      NSMutableCharacterSet	*new_set;

      not_ws = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
      new_set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
      [new_set formIntersectionWithCharacterSet: not_ws];
      nlset = [new_set copy];
      [new_set release];
    }

  /*
   * Now produce output on a per-line basis.
   */
  while (linePos < length)
    {
      NSRange	line;		// Range of current line.
      NSRange	eol;		// Rnage of newline character.
      float	lineHeight;	// Height of text in this line.
      unsigned	position;	// Position in NSString.

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

      while (position < eol.location)
	{
	  NSAttributedString		*subAttr;
	  NSString		*subString;
	  NSSize		size;
	  NSFont		*font;
	  NSParagraphStyle	*style;
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
	  style = (NSParagraphStyle*)[self attribute: NSParagraphStyleAttributeName
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

	  lineHeight = size.height;

	  /*
	   * If we have a background color set - we fill in the
	   * region occupied by this substring.
	   */
	  if (bg)
	    {
	      NSRect	rect;

	      rect.origin = point;
	      rect.size = size;
	      if (isFlipped == NO)
		rect.origin.y -= size.height;

	      [bg set];
	      NSRectFill(rect);
	    }

	  /*
	   * Set font and color, then draw the substring.
	   * NB. Our origin is top-left of the string so we need to
	   * calculate a vertical coordinate for the baseline of the
	   * text produced by psshow.
	   */
	  if (isFlipped)
	    ypos = point.y + size.height - [font descender];
	  else
	    ypos = point.y - size.height + [font descender];
	  [fg set];
	  [font set];
	  DPSmoveto(ctxt, point.x, ypos);
	  DPSshow(ctxt, [subString cString]);
	  if (underline == NSSingleUnderlineStyle)
	    {
	      DPSmoveto(ctxt, point.x, ypos);
	      DPSlineto(ctxt, point.x + size.width - 1, ypos);
	    }

	  point.x += size.width;		// Next point to draw from.
	}
      point.x = start.x;
      if (isFlipped)
	point.y += lineHeight;
      else
	point.y -= lineHeight;
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

