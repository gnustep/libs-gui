/** <title>NSStringAdditions</title>

   <abstract>Categories which add drawing capabilities to NSAttributedString
   and NSString.</abstract>

   Copyright (C) 1999, 2003 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Mar 1999 - rewrite from scratch

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: November 2002 - February 2003 (rewrite to use NSLayoutManager et al)

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

#include <math.h>

#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSLayoutManager.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSTextStorage.h"
#include "AppKit/DPSOperators.h"
#include "GSTextStorage.h"

/*
TODO:

these methods are _not_ reentrant. should they be?

We could save time by trying to avoid changing the text storage and
container size if the new rect and text are the same as the previous.
This might be a common case if lots of calls to -size... and -draw...
are paired.
*/


#define LARGE_SIZE 8e6
/*
8e6 is not as arbitrary as it seems. 8e6 is chosen because it's close to
1<<23-1, the largest number that can be stored in a 32-bit float with an
ulp of 0.5, which means things should round to the correct whole point.
*/

static NSTextStorage *textStorage;
static NSLayoutManager *layoutManager;
static NSTextContainer *textContainer;

static void init_string_drawing(void)
{
  if (textStorage)
    return;

  textStorage = [[NSTextStorage alloc] init];
  layoutManager = [[NSLayoutManager alloc] init];
  [textStorage addLayoutManager: layoutManager];
  [layoutManager release];
  textContainer = [[NSTextContainer alloc]
		    initWithContainerSize: NSMakeSize(10,10)];
  [layoutManager addTextContainer: textContainer];
  [textContainer release];
}

/*
This is an ugly hack to get text to display correctly in non-flipped views.

The text system always has positive y down, so we flip the coordinate
system when drawing (if the view isn't flipped already). This causes the
glyphs to be drawn upside-down, so we need to tell NSFont to flip the fonts.
*/
@interface NSFont (font_flip_hack)
+(void) _setFontFlipHack: (BOOL)flip;
@end

@implementation NSAttributedString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point
{
  NSRange r;
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSAffineTransform *ctm = GSCurrentCTM(ctxt);

  init_string_drawing();

  [textStorage replaceCharactersInRange: NSMakeRange(0, [textStorage length])
			     withString: @""];

  [textContainer setContainerSize: NSMakeSize(LARGE_SIZE, LARGE_SIZE)];

  if (ctm->matrix.m11 != 1.0 || ctm->matrix.m12 != 0.0 ||
      ctm->matrix.m21 != 0.0 || fabs(ctm->matrix.m22) != 1.0)
    {
      [layoutManager setUsesScreenFonts: NO];
    }
  else
    {
      [layoutManager setUsesScreenFonts: YES];
    }

  [textStorage replaceCharactersInRange: NSMakeRange(0, 0)
		   withAttributedString: self];

  r = NSMakeRange(0, [layoutManager numberOfGlyphs]);

  if (![[NSView focusView] isFlipped])
    {
      NSRect usedRect;

      DPSscale(ctxt, 1, -1);
      point.y = -point.y;

      /*
      Adjust point.y so the lower left corner of the used rect is at the
      point that was passed to us.
      */
      usedRect = [layoutManager usedRectForTextContainer: textContainer];
      point.y -= NSMaxY(usedRect);

      [NSFont _setFontFlipHack: YES];
    }

  [layoutManager drawBackgroundForGlyphRange: r
				     atPoint: point];

  [layoutManager drawGlyphsForGlyphRange: r
				 atPoint: point];

  if (![[NSView focusView] isFlipped])
    {
      DPSscale(ctxt, 1, -1);
      [NSFont _setFontFlipHack: NO];
    }
}

- (void) drawInRect: (NSRect)rect
{
  NSRange r;
  BOOL need_clip;
  NSRect used;
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSAffineTransform *ctm = GSCurrentCTM(ctxt);

  init_string_drawing();

  [textStorage replaceCharactersInRange: NSMakeRange(0, [textStorage length])
			     withString: @""];

  /*
  TODO: Use rect.size.heigth instead of LARGE_SIZE? Should make things faster,
  since we'll only typeset what fits, but lines that used to fit partially
  won't fit at all.
  */
  [textContainer setContainerSize: NSMakeSize(rect.size.width, LARGE_SIZE)];

  if (ctm->matrix.m11 != 1.0 || ctm->matrix.m12 != 0.0 ||
      ctm->matrix.m21 != 0.0 || fabs(ctm->matrix.m22) != 1.0)
    {
      [layoutManager setUsesScreenFonts: NO];
    }
  else
    {
      [layoutManager setUsesScreenFonts: YES];
    }

  [textStorage replaceCharactersInRange: NSMakeRange(0, 0)
		   withAttributedString: self];

  used = [layoutManager usedRectForTextContainer: textContainer];

  /*
  If the used rect fits completely in the rect we draw in, we save time
  by avoiding the DPSrectclip (and the state save and restore).

  This isn't completely safe; the used rect isn't guaranteed to contain
  all parts of all glyphs.
  */
  if (used.origin.x >= 0 && used.origin.y <= 0 &&
      NSMaxX(used) <= rect.size.width && NSMaxY(used) <= rect.size.height)
    {
      need_clip = NO;
    }
  else
    {
      need_clip = YES;
      DPSgsave(ctxt);
      DPSrectclip(ctxt, rect.origin.x, rect.origin.y,
		  rect.size.width, rect.size.height);
    }

  r = [layoutManager
	glyphRangeForBoundingRect: NSMakeRect(0, 0, rect.size.width, rect.size.height)
		  inTextContainer: textContainer];

  if (![[NSView focusView] isFlipped])
    {
      DPSscale(ctxt, 1, -1);
      rect.origin.y = -NSMaxY(rect);
      [NSFont _setFontFlipHack: YES];
    }

  [layoutManager drawBackgroundForGlyphRange: r
				     atPoint: rect.origin];

  [layoutManager drawGlyphsForGlyphRange: r
				 atPoint: rect.origin];

  [NSFont _setFontFlipHack: NO];
  if (![[NSView focusView] isFlipped])
    {
      DPSscale(ctxt, 1, -1);
    }

  if (need_clip)
    {
      /* Restore the original clipping path. */
      DPSgrestore(ctxt);
    }
}

- (NSSize) size
{
  NSRange r;
  NSRect rect;

  init_string_drawing();

  [textStorage replaceCharactersInRange: NSMakeRange(0, [textStorage length])
			     withString: @""];

  [textContainer setContainerSize: NSMakeSize(LARGE_SIZE, LARGE_SIZE)];
  [layoutManager setUsesScreenFonts: YES];

  [textStorage replaceCharactersInRange: NSMakeRange(0, 0)
		   withAttributedString: self];

  r = NSMakeRange(0, [layoutManager numberOfGlyphs]);

  rect = [layoutManager usedRectForTextContainer: textContainer];
  return rect.size;
}

@end

/*
TODO: It's severely sub-optimal, but the NSString methods just use
NSAttributedString to do the job.
*/
@implementation NSString (NSStringDrawing)

- (void) drawAtPoint: (NSPoint)point withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()]
			  initWithString: self
			      attributes: attrs];
  [a drawAtPoint: point];
  RELEASE(a);
}

- (void) drawInRect: (NSRect)rect withAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()]
			  initWithString: self
			      attributes: attrs];
  [a drawInRect: rect];
  RELEASE(a);
}

- (NSSize) sizeWithAttributes: (NSDictionary *)attrs
{
  NSAttributedString	*a;
  NSSize		s;

  a = [[NSAttributedString allocWithZone: NSDefaultMallocZone()]
			  initWithString: self
			      attributes: attrs];
  s = [a size];
  RELEASE(a);
  return s;
}

@end


/*
Dummy function; see comment in NSApplication.m, +initialize.
*/
void GSStringDrawingDummyFunction(void)
{
}

