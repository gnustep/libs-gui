/*
   GSHorizontalTypesetter.m

   Copyright (C) 2002, 2003 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: November 2002 - February 2003

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/


#include <math.h>

#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSText.h"
#import "AppKit/NSAttributedString.h"
#import "AppKit/NSParagraphStyle.h"
#import "AppKit/NSTextAttachment.h"
#import "AppKit/NSTextContainer.h"
#import "AppKit/NSTextStorage.h"
#import "GNUstepGUI/GSLayoutManager.h"
#import "GNUstepGUI/GSHorizontalTypesetter.h"



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
  if (glyphCache)
    {
      free(glyphCache);
      glyphCache = NULL;
    }
  if (lineFragments)
    {
      free(lineFragments);
      lineFragments = NULL;
    }
  DESTROY(lock);
  [super dealloc];
}

+(GSHorizontalTypesetter *) sharedInstance
{
  NSMutableDictionary *threadDict =
    [[NSThread currentThread] threadDictionary];
  GSHorizontalTypesetter *shared =
    [threadDict objectForKey: @"sharedHorizontalTypesetter"];

  if (!shared)
    {
      shared = [[self alloc] init];
      [threadDict setObject: shared
                     forKey: @"sharedHorizontalTypesetter"];
      RELEASE(shared);
    }

  return shared;
}

#define CACHE_INITIAL 192
#define CACHE_STEP 192


struct GSHorizontalTypesetterGlyphCacheStruct
{
  /* These fields are filled in by the caching: */
  NSGlyph glyph;
  unsigned int characterIndex;

  NSFont *font;
  struct
    {
      BOOL explicitKern;
      float kern;
      float baselineOffset;
      int superscript;
    } attributes;

  /* These fields are filled in during layout: */
  BOOL nominal;
  NSPoint position;    /* relative to the line's baseline */
  NSSize size;    /* height is used only for attachments */
  BOOL dontShow, outsideLineFragment;
};
typedef struct GSHorizontalTypesetterGlyphCacheStruct GlyphCacheEntry;

/* TODO: if we could know whether the layout manager had been modified since
   the last time or not, we wouldn't need to clear the cache every time */
-(void) _clearCache
{
  cacheLength = 0;

  currentParagraphStyle = nil;
  paragraphRange = NSMakeRange(0, 0);
  currentAttributes = nil;
  attributeRange = NSMakeRange(0, 0);
  currentFont = nil;
  fontRange = NSMakeRange(0, 0);
}

-(void) _cacheAttributesAtCharacterIndex: (unsigned int)characterIndex
{
  NSNumber *numberValue;

  if (NSLocationInRange(characterIndex, attributeRange))
    {
      return;
    }
  
  currentAttributes = [currentTextStorage attributesAtIndex: characterIndex
                                             effectiveRange: &attributeRange];

  numberValue = [currentAttributes objectForKey: NSKernAttributeName];
  if (!numberValue)
    attributes.explicitKern = NO;
  else
    {
      attributes.explicitKern = YES;
      attributes.kern = [numberValue floatValue];
    }

  numberValue = [currentAttributes objectForKey: NSBaselineOffsetAttributeName];
  if (numberValue)
    attributes.baselineOffset = [numberValue floatValue];
  else
    attributes.baselineOffset = 0.0;

  numberValue = [currentAttributes objectForKey: NSSuperscriptAttributeName];
  if (numberValue)
    attributes.superscript = [numberValue intValue];
  else
    attributes.superscript = 0;
}

-(void) _moveCacheToGlyph: (unsigned int)glyphIndex
{
  BOOL valid;

  if (cacheBase <= glyphIndex && cacheBase + cacheLength > glyphIndex)
    {
      int delta = glyphIndex - cacheBase;
      cacheLength -= delta;
      memmove(glyphCache, &glyphCache[delta], sizeof(GlyphCacheEntry) * cacheLength);
      cacheBase = glyphIndex;
      return;
    }

  cacheBase = glyphIndex;
  cacheLength = 0;

  [currentLayoutManager glyphAtIndex: glyphIndex
                        isValidIndex: &valid];

  if (valid)
    {
      unsigned int charIndex;

      atEnd = NO;
      charIndex = [currentLayoutManager characterIndexForGlyphAtIndex: glyphIndex];
      [self _cacheAttributesAtCharacterIndex: charIndex];

      paragraphRange = NSMakeRange(charIndex, [currentTextStorage length] - charIndex);
      currentParagraphStyle = [currentTextStorage attribute: NSParagraphStyleAttributeName
                                                    atIndex: charIndex
                                      longestEffectiveRange: &paragraphRange
                                                    inRange: paragraphRange];
      if (currentParagraphStyle == nil)
        {
          currentParagraphStyle = [NSParagraphStyle defaultParagraphStyle];
        }

      currentFont = [currentLayoutManager effectiveFontForGlyphAtIndex: glyphIndex
                                                                 range: &fontRange];
    }
  else
    {
      atEnd = YES;
    }
}

-(void) _cacheGlyphsUpToLength: (unsigned int)newLength
{
  GlyphCacheEntry *glyphEntry;
  BOOL valid;

  if (cacheSize < newLength)
    {
      cacheSize = newLength;
      glyphCache = realloc(glyphCache, sizeof(GlyphCacheEntry) * cacheSize);
    }

  for (glyphEntry = &glyphCache[cacheLength]; cacheLength < newLength; cacheLength++, glyphEntry++)
    {
      glyphEntry->glyph = [currentLayoutManager glyphAtIndex: cacheBase + cacheLength
                                                isValidIndex: &valid];
      if (!valid)
        {
          atEnd = YES;
          break;
        }
      glyphEntry->characterIndex = [currentLayoutManager characterIndexForGlyphAtIndex: cacheBase + cacheLength];
      if (glyphEntry->characterIndex >= paragraphRange.location + paragraphRange.length)
        {
          atEnd = YES;
          break;
        }

      /* cache attributes */
      if (glyphEntry->characterIndex >= attributeRange.location + attributeRange.length)
        {
          [self _cacheAttributesAtCharacterIndex: glyphEntry->characterIndex];
        }

      glyphEntry->attributes.explicitKern = attributes.explicitKern;
      glyphEntry->attributes.kern = attributes.kern;
      glyphEntry->attributes.baselineOffset = attributes.baselineOffset;
      glyphEntry->attributes.superscript = attributes.superscript;

      if (cacheBase + cacheLength >= fontRange.location + fontRange.length)
        {
          currentFont = [currentLayoutManager effectiveFontForGlyphAtIndex: cacheBase + cacheLength
                                                                     range: &fontRange];
        }
      glyphEntry->font = currentFont;

      glyphEntry->dontShow = NO;
      glyphEntry->outsideLineFragment = NO;
      glyphEntry->nominal = YES;

      // FIXME: This assumes the layout manager implements this GNUstep extension
      glyphEntry->size = [currentLayoutManager advancementForGlyphAtIndex: cacheBase + cacheLength];
    }
}


/*
   Should return the first glyph on the next line, which must be <=glyphIndex and
   >=cacheBase (TODO: not enough. actually, it probably is now. the wrapping
   logic below will fall back to char wrapping if necessary). Glyphs up to and
   including glyphIndex will have been cached.
*/
-(unsigned int) breakLineByWordWrappingBefore: (unsigned int)glyphIndex
{
  GlyphCacheEntry *glyphEntry;
  unichar character;
  NSString *string = [currentTextStorage string];

  glyphIndex -= cacheBase;
  glyphEntry = glyphCache + glyphIndex;

  while (glyphIndex > 0)
    {
      if ((glyphEntry->glyph == NSControlGlyph) ||
          (glyphEntry->glyph == GSAttachmentGlyph))
        {
          return glyphIndex + cacheBase;
        }

      character = [string characterAtIndex: glyphEntry->characterIndex];
      /* TODO: paragraph/line separator */
      if (character == 0x20 || // space
          character == NSNewlineCharacter ||
          character == NSCarriageReturnCharacter ||
          character == NSTabCharacter)
        {
          glyphEntry->dontShow = YES;
          if (glyphIndex > 0)
            {
              glyphEntry->position = glyphEntry[-1].position;
              glyphEntry->position.x += glyphEntry[-1].size.width;
            }
          else
            glyphEntry->position = NSMakePoint(0, 0);

          glyphEntry->size.width = 0;
          return glyphIndex + 1 + cacheBase;
        }
      /* Each CJK glyph should be treated as a word when wrapping word.
         The range should work for most cases */
      else if ((character > 0x2ff0) && (character < 0x9fff))
         {
           glyphEntry->dontShow = NO;
           if (glyphIndex > 0)
             {
               glyphEntry->position = glyphEntry[-1].position;
               glyphEntry->position.x += glyphEntry[-1].size.width;
             }
           else
             glyphEntry->position = NSMakePoint(0,0);

           return glyphIndex + cacheBase;
         }

      glyphIndex--;
      glyphEntry--;
    }

  return glyphIndex + cacheBase;
}


struct GSHorizontalTypesetterLineFragmentStruct
{
  NSRect rect;
  CGFloat lastUsed;
  unsigned int lastGlyphIndex; /* lastGlyphIndex+1, actually */
};
typedef struct GSHorizontalTypesetterLineFragmentStruct LineFragment;

/*
Apple uses this as the maximum width of an NSTextContainer.
For bigger values the width gets ignored.
*/
#define LARGE_SIZE 1e7

-(void) fullJustifyLine: (LineFragment *)lineFragment : (int)numLineFragments
{
  unsigned int index, start;
  CGFloat extraSpace, delta;
  unsigned int numSpaces;
  NSString *string = [currentTextStorage string];
  GlyphCacheEntry *glyphEntry;
  unichar character;

  if (lineFragment->rect.size.width >= LARGE_SIZE)
    {
      return;
    }

  for (start = 0; numLineFragments; numLineFragments--, lineFragment++)
    {
      numSpaces = 0;
      for (index = start, glyphEntry = glyphCache + index; index < lineFragment->lastGlyphIndex; index++, glyphEntry++)
        {
          if (glyphEntry->dontShow)
            continue;

          character = [string characterAtIndex: glyphEntry->characterIndex];
          if (character == 0x20)
            numSpaces++;
        }
      if (!numSpaces)
        continue;

      extraSpace = lineFragment->rect.size.width - lineFragment->lastUsed;
      extraSpace /= numSpaces;
      delta = 0;
      for (index = start, glyphEntry = glyphCache + index; index < lineFragment->lastGlyphIndex; index++, glyphEntry++)
        {
          glyphEntry->position.x += delta;
          if (!glyphEntry->dontShow && [string characterAtIndex: glyphEntry->characterIndex] == 0x20)
            {
              if (index < lineFragment->lastGlyphIndex)
                glyphEntry[1].nominal = NO;

              delta += extraSpace;
            }
        }

      start = lineFragment->lastGlyphIndex;
      lineFragment->lastUsed = lineFragment->rect.size.width;
    }
}

-(void) rightAlignLine: (LineFragment *)lineFragment : (int)numLineFragments
{
  unsigned int index;
  CGFloat delta;
  GlyphCacheEntry *glyphEntry;

  if (lineFragment->rect.size.width >= LARGE_SIZE)
    {
      return;
    }

  for (index = 0, glyphEntry = glyphCache; numLineFragments; numLineFragments--, lineFragment++)
    {
      delta = lineFragment->rect.size.width - lineFragment->lastUsed;
      for (; index < lineFragment->lastGlyphIndex; index++, glyphEntry++)
        glyphEntry->position.x += delta;

      lineFragment->lastUsed += delta;
    }
}

-(void) centerAlignLine: (LineFragment *)lineFragment : (int)numLineFragments
{
  unsigned int index;
  CGFloat delta;
  GlyphCacheEntry *glyphEntry;

  if (lineFragment->rect.size.width >= LARGE_SIZE)
    {
      return;
    }

  for (index = 0, glyphEntry = glyphCache; numLineFragments; numLineFragments--, lineFragment++)
    {
      delta = (lineFragment->rect.size.width - lineFragment->lastUsed) / 2.0;
      for (; index < lineFragment->lastGlyphIndex; index++, glyphEntry++)
        glyphEntry->position.x += delta;

      lineFragment->lastUsed += delta;
    }
}


-(BOOL) _reuseSoftInvalidatedLayout
{
  /*
  We only handle the simple-horizontal-text-container case currently.
  */
  NSRect firstRect, rect;
  NSSize shift;
  int index;
  unsigned int glyph, nextGlyph, firstGlyph;
  CGFloat containerHeight;
  /*
  Ask the layout manager for soft-invalidated layout for the current
  glyph. If there is a set of line fragments starting at the current glyph,
  and we can get rects with the same size and horizontal position, we
  tell the layout manager to use the soft-invalidated information.
  */
  firstRect = [currentLayoutManager _softInvalidateLineFragRect: 0
                                                     firstGlyph: &firstGlyph
                                                      nextGlyph: &glyph
                                                inTextContainer: currentTextContainer];

  containerHeight = [currentTextContainer containerSize].height;
  if (!(currentPoint.y + firstRect.size.height <= containerHeight))
    return NO;

  /*
  We can shift the rects and still have things fit. Find all the line
  fragments in the line and shift them.
  */
  shift.width = 0;
  shift.height = currentPoint.y - firstRect.origin.y;
  index = 1;
  currentPoint.y = NSMaxY(firstRect) + shift.height;
  for (; 1; index++)
    {
      rect = [currentLayoutManager _softInvalidateLineFragRect: index
                                                    firstGlyph: &firstGlyph
                                                     nextGlyph: &nextGlyph
                                               inTextContainer: currentTextContainer];

      /*
      If there's a gap in soft invalidated information, we need to
      fill it in before we can continue.
      */
      if (firstGlyph != glyph)
        {
          break;
        }

      if (NSIsEmptyRect(rect) || NSMaxY(rect) + shift.height > containerHeight)
        break;

      glyph = nextGlyph;
      currentPoint.y = NSMaxY(rect) + shift.height;
    }

  [currentLayoutManager _softInvalidateUseLineFrags: index
                                          withShift: shift
                                    inTextContainer: currentTextContainer];

  currentGlyphIndex = glyph;

  return YES;
}


- (NSRect)_getProposedRectForNewParagraph: (BOOL)newParagraph
                           withLineHeight: (CGFloat) lineHeight
{
  CGFloat headIndent;
  CGFloat tailIndent = [currentParagraphStyle tailIndent];

  if (newParagraph)
    headIndent = [currentParagraphStyle firstLineHeadIndent];
  else
    headIndent = [currentParagraphStyle headIndent];

  if (tailIndent <= 0.0)
    {
      NSSize size;

      size = [currentTextContainer containerSize];
      tailIndent = size.width + tailIndent;
    }

  return NSMakeRect(headIndent,
                    currentPoint.y,
                    tailIndent - headIndent,
                    lineHeight + [currentParagraphStyle lineSpacing]);
}

- (void) _addExtraLineFragment
{
  NSRect rect, extraRect, remain;
  CGFloat lineHeight;

  /*
    We aren't actually interested in the glyph data, but we want the
    attributes for the final character so we can make the extra line
    frag rect match it. This call makes sure that currentParagraphStyle
    and currentFont are set.
  */
  if (currentGlyphIndex)
    {
      [self _moveCacheToGlyph: currentGlyphIndex - 1];
    }
  else
    {
      NSDictionary *typingAttributes = [currentLayoutManager typingAttributes];
      currentParagraphStyle = [typingAttributes
                                    objectForKey: NSParagraphStyleAttributeName];
      if (currentParagraphStyle == nil)
        {
          currentParagraphStyle = [NSParagraphStyle defaultParagraphStyle];
        }
      currentFont = [typingAttributes objectForKey: NSFontAttributeName];
    }

  if (currentFont)
    {
      lineHeight = [currentFont defaultLineHeightForFont];
    }
  else
    {
      lineHeight = 15.0;
    }

  rect = [self _getProposedRectForNewParagraph: YES
                                withLineHeight: lineHeight];
  rect = [currentTextContainer lineFragmentRectForProposedRect: rect
                                                sweepDirection: NSLineSweepRight
                                             movementDirection: NSLineMovesDown
                                                 remainingRect: &remain];

  if (!NSIsEmptyRect(rect))
    {
      extraRect = rect;
      extraRect.size.width = 1;
      [currentLayoutManager setExtraLineFragmentRect: rect
                                            usedRect: extraRect
                                       textContainer: currentTextContainer];
    }
}

static inline BOOL wantNewLineHeight(CGFloat height, CGFloat *lineHeight, CGFloat maxLineHeight)
{
  CGFloat newHeight = height;

  if (maxLineHeight > 0 && newHeight > maxLineHeight)
    {
      newHeight = maxLineHeight;
    }

  if (newHeight > *lineHeight)
    {
      *lineHeight = newHeight;
      return YES;
    }

  return NO;
}

- (BOOL)_baseLayoutBlockNewParagraph:(BOOL *)newParagraph
                        onLineHeight:(CGFloat *)lineHeight
                         considering:(CGFloat)maxLineHeight
                       usingAscender:(CGFloat *)ascender
                        andDescender:(CGFloat *)descender
          returningLineFragmentIndex:(int *)lineFragmentIndex
                 returningGlyphIndex:(unsigned int*)glyphIndex
                   returningPosition:(NSPoint *)position
{
  *glyphIndex = 0;
  GlyphCacheEntry *glyphEntry;

  NSFont *font = glyphCache->font;

  CGFloat baseline; /* Baseline position (0 is top of line-height, positive is down). */
  CGFloat fontAscender = [font ascender];
  CGFloat fontDescender = -[font descender];

  NSGlyph lastGlyph = NSNullGlyph;
  NSPoint lastPosition;

  unsigned int firstGlyphIndex;
  LineFragment *lineFragment = lineFragments;
  *lineFragmentIndex = 0;

  BOOL previousHadNonNominalWidth;


  lastPosition = *position = NSMakePoint(0, 0);

  glyphEntry = glyphCache;
  firstGlyphIndex = 0;
  previousHadNonNominalWidth = NO;
  /*
    Main glyph layout loop.
  */
  /* TODO: handling of newParagraph is ugly. must be set on all exits
     from this loop */
  while (1)
    {
      BOOL doesGlyphFitInLine = YES;

      //        printf("at %3i+%3i\n", cacheBase, *glyphIndex);
      /* Update the cache. */
      if (*glyphIndex >= cacheLength)
        {
          if (atEnd)
            {
              *newParagraph = NO;
              break;
            }
          [self _cacheGlyphsUpToLength: cacheLength + CACHE_STEP];
          if (*glyphIndex >= cacheLength)
            {
              *newParagraph = NO;
              break;
            }
          glyphEntry = &glyphCache[*glyphIndex];
        }

      /*
        At this point:

        position is the current point (sortof); the point where a nominally
        spaced glyph would be placed.

        glyphEntry is the current glyph. glyphIndex is the current glyph index, relative to
        the start of the cache.

        lastPosition and lastGlyph are used for kerning and hold the previous
        glyph and its position. If there's no previous glyph (for kerning
        purposes), lastGlyph is NSNullGlyph and lastPosition is undefined.

        lineFragment and lineFragmentIndex track the current line fragment rect. firstGlyphIndex is the
        first glyph in the current line fragment rect.

        Note that the variables tracking the previous glyph shouldn't be
        updated until we know that the current glyph will fit in the line
        fragment rect.
      */

      /* If there's a font change, we update the ascender and descender
         (line height adjusted later), even though there might not actually be
         any glyphs for this font.
         (TODO?) */
      if (glyphEntry->font != font)
        {
          font = glyphEntry->font;
          fontAscender = [font ascender];
          fontDescender = -[font descender];
          lastGlyph = NSNullGlyph;
        }


      /* Set up glyph information. */

      /*
        TODO:
        Currently, the attributes of the attachment character (eg. font)
        affect the layout. Think hard about this.
      */
      glyphEntry->nominal = !previousHadNonNominalWidth;

      if (glyphEntry->attributes.explicitKern &&
          glyphEntry->attributes.kern != 0)
        {
          position->x += glyphEntry->attributes.kern;
          glyphEntry->nominal = NO;
        }


      /* does the glyph fit ? */
      doesGlyphFitInLine = !((*glyphIndex > firstGlyphIndex) && (position->x + glyphEntry->size.width > lineFragment->rect.size.width));
      if (doesGlyphFitInLine)
        {
          /* Baseline adjustments. */
          CGFloat yOffset = 0;

          /* Attributes are up-side-down in our coordinate system. */
          if (glyphEntry->attributes.superscript)
            {
              yOffset -= glyphEntry->attributes.superscript * [font xHeight];
            }
          if (glyphEntry->attributes.baselineOffset)
            {
              /* And baselineOffset is up-side-down again. TODO? */
              yOffset += glyphEntry->attributes.baselineOffset;
            }

          if (yOffset != position->y)
            {
              position->y = yOffset;
              glyphEntry->nominal = NO;
            }

          /* defaultLineHeightForFont is ascender+descender, match calculation here */

          /* coming from potential font change taken in account above*/
          if (fontAscender > *ascender)
            *ascender = fontAscender;
          if (fontDescender > *descender)
            *descender = fontDescender;

          /* coming from superscript/subscript */
          if (yOffset < 0 && fontAscender - yOffset > *ascender)
            *ascender = fontAscender - yOffset;
          if (yOffset > 0 && fontDescender + yOffset > *descender)
            *descender = fontDescender + yOffset;

          if (wantNewLineHeight(*ascender + *descender, lineHeight, maxLineHeight))
            return YES;
        }

      if (glyphEntry->glyph == NSControlGlyph)
        {
          unichar character = [[currentTextStorage string] characterAtIndex: glyphEntry->characterIndex];

          /* TODO: need to handle other control characters */

          glyphEntry->position = *position;
          glyphEntry->size.width = 0;
          glyphEntry->dontShow = YES;
          glyphEntry->nominal = !previousHadNonNominalWidth;

          (*glyphIndex)++;
          glyphEntry++;

          lastGlyph = NSNullGlyph;

          previousHadNonNominalWidth = NO;

          if (character == NSNewlineCharacter)
            {
              *newParagraph = YES;
              break;
            }

          if (character == NSTabCharacter)
            {
              /*
                Handle tabs. This is a very basic and stupid implementation.
                TODO: implement properly
              */
              NSArray *tabs = [currentParagraphStyle tabStops];
              NSTextTab *tab = nil;
              CGFloat defaultInterval = [currentParagraphStyle defaultTabInterval];

              /* Set it to something reasonable if unset */
              if (defaultInterval == 0.0)
                {
                  defaultInterval = 100.0;
                }

              unsigned int tabIndex;
              unsigned int tabCount = [tabs count];
              /* Find first tab beyond our current position. */
              for (tabIndex = 0; tabIndex < tabCount; tabIndex++)
                {
                  tab = [tabs objectAtIndex: tabIndex];
                  /*
                     We cannot use a tab at our exact location; we must
                     use one beyond it. The reason is that several tabs in
                     a row would get very odd behavior. Eg. given "\t\t",
                     the first tab would move (exactly) to the next tab
                     stop, and the next tab stop would move to the same
                     tab, thus having no effect.
                  */
                  if ([tab location] > position->x + lineFragment->rect.origin.x)
                    {
                      break;
                    }
                }
              if (tabIndex == tabCount)
                {
                  /*
                     Tabs after the last value in tabStops should use the
                     defaultTabInterval provided by NSParagraphStyle.
                  */
                  position->x = (floor(position->x / defaultInterval) + 1.0) * defaultInterval;
                }
              else
                {
                  position->x = [tab location] - lineFragment->rect.origin.x;
                }
              previousHadNonNominalWidth = YES;
              continue;
            }

          NSDebugLLog(@"GSHorizontalTypesetter",
                      @"ignoring unknown control character %04x\n", character);

          continue;
        }

      if (glyphEntry->glyph == GSAttachmentGlyph)
        {
          NSTextAttachment *attachment;
          NSTextAttachmentCell *cell;
          NSRect cellFrame;

          attachment = [currentTextStorage attribute: NSAttachmentAttributeName
                                             atIndex: glyphEntry->characterIndex
                                      effectiveRange: NULL];
          cell = (NSTextAttachmentCell*)[attachment attachmentCell];
          if (!cell)
            {
              glyphEntry->position = *position;
              glyphEntry->size = NSMakeSize(0, 0);
              glyphEntry->dontShow = YES;
              glyphEntry->nominal = YES;

              (*glyphIndex)++;
              glyphEntry++;
              lastGlyph = NSNullGlyph;

              continue;
            }

          baseline = *lineHeight - *descender;

          cellFrame = [cell cellFrameForTextContainer: currentTextContainer
                                 proposedLineFragment: lineFragment->rect
                                        glyphPosition: NSMakePoint(position->x, lineFragment->rect.size.height - baseline)
                                       characterIndex: glyphEntry->characterIndex];

          /* For some obscure reason, the rectangle we get is up-side-down
             compared to everything else here, and has it's origin in position.
             (Makes sense from the cell's pov, though.) */

          /* does the attachment fit (and it is not the first element in line) ?*/
          doesGlyphFitInLine = !((*glyphIndex > firstGlyphIndex) && (position->x + NSMaxX(cellFrame) > lineFragment->rect.size.width));
          if (doesGlyphFitInLine)
            {
              if (-NSMinY(cellFrame) > *descender)
                *descender = -NSMinY(cellFrame);

              if (NSMaxY(cellFrame) > *ascender)
                *ascender = NSMaxY(cellFrame);

              /* Update ascender and descender. Adjust line height and
                 baseline if necessary. */

              if (wantNewLineHeight(*ascender + *descender, lineHeight, maxLineHeight))
                return YES;
            }

          glyphEntry->size = cellFrame.size;
          glyphEntry->position.x = position->x + cellFrame.origin.x;
          glyphEntry->position.y = position->y - cellFrame.origin.y;

          position->x = glyphEntry->position.x + glyphEntry->size.width;

          /* An attachment is always in a point range of its own. */
          glyphEntry->nominal = NO;
        }
      else
        {
          /* TODO: this is a major bottleneck */
          /*
          if (lastGlyph)
            {
              BOOL n;
              *position = [font positionOfGlyph: glyphEntry->glyph
                               precededByGlyph: lastGlyph
                                     isNominal: &n];
              if (!n)
                glyphEntry->nominal = NO;
              position->x += lastPosition.x;
              position->y += lastPosition.y;
            }
          */
          lastPosition = glyphEntry->position = *position;
          /* Only the width is used. */
          position->x += glyphEntry->size.width;
        }

      /* Did the glyph fit in the line fragment rect? */
      if (!doesGlyphFitInLine)
        {
          /* It didn't. Try to break the line. */
          switch ([currentParagraphStyle lineBreakMode])
            { /* TODO: implement all modes */
              default:
              case NSLineBreakByCharWrapping:
                lineFragment->lastGlyphIndex = *glyphIndex;
                break;

              case NSLineBreakByWordWrapping:
                lineFragment->lastGlyphIndex = [self breakLineByWordWrappingBefore: cacheBase + *glyphIndex] - cacheBase;
                if (lineFragment->lastGlyphIndex <= firstGlyphIndex)
                  {
                    // same operation as for NSLineBreakByCharWrapping
                    lineFragment->lastGlyphIndex = *glyphIndex;
                  }
                break;

              case NSLineBreakByTruncatingHead:
              case NSLineBreakByTruncatingMiddle:
              case NSLineBreakByTruncatingTail:
                /* Pretending that these are clipping is far from prefect,
                   but it's the closest we've got. */
              case NSLineBreakByClipping:
                /* Scan forward to the next paragraph separator and mark
                   all the glyphs up to there as not visible. */
                glyphEntry->outsideLineFragment = YES;
                while (1)
                  {
                    (*glyphIndex)++;
                    glyphEntry++;

                    /* Update the cache. */
                    if (*glyphIndex >= cacheLength)
                      {
                        if (atEnd)
                          {
                            *newParagraph = NO;
                            (*glyphIndex)--;
                            break;
                          }
                        [self _cacheGlyphsUpToLength: cacheLength + CACHE_STEP];
                        if (*glyphIndex >= cacheLength)
                          {
                            *newParagraph = NO;
                            (*glyphIndex)--;
                            break;
                          }
                        glyphEntry = &glyphCache[*glyphIndex];
                      }

                    glyphEntry->dontShow = YES;
                    glyphEntry->position = *position;

                    if (glyphEntry->glyph == NSControlGlyph
                        && [[currentTextStorage string] characterAtIndex: glyphEntry->characterIndex] == NSNewlineCharacter)
                      break;
                  }

                lineFragment->lastGlyphIndex = *glyphIndex + 1;
                break;
            }

          /* We force at least one glyph into each line fragment rect. This
             ensures that typesetting will never get stuck (ie. if the text
             container is too narrow to fit even a single glyph). */
          if (lineFragment->lastGlyphIndex <= firstGlyphIndex)
            lineFragment->lastGlyphIndex = *glyphIndex + 1;

          lastPosition = *position = NSMakePoint(0, 0);
          *glyphIndex = lineFragment->lastGlyphIndex;
          glyphEntry = &glyphCache[*glyphIndex];
          /* The -1 is always valid since there's at least one glyph in the
             line fragment rect (see above). */
          lineFragment->lastUsed = glyphEntry[-1].position.x + glyphEntry[-1].size.width;
          lastGlyph = NSNullGlyph;
          previousHadNonNominalWidth = NO;

          lineFragment++;
          (*lineFragmentIndex)++;
          if (*lineFragmentIndex == lineFragmentCount)
            {
              *newParagraph = NO;
              break;
            }
          firstGlyphIndex = *glyphIndex;
        }
      else
        {
          /* Move to next glyph. */
          lastGlyph = glyphEntry->glyph;

          if (lastGlyph == GSAttachmentGlyph)
            {
              lastGlyph = NSNullGlyph;
              previousHadNonNominalWidth = YES;
            }
          else
            {
              previousHadNonNominalWidth = NO;
            }

          (*glyphIndex)++;
          glyphEntry++;
        }
    }

  return NO;
}

/*
   Return values 0, 1, 2 are mostly the same as from
   -layoutGlyphsInLayoutManager:.... Additions:

   0   Last typeset character was not a newline; next glyph does not start
       a new paragraph.

   3   Last typeset character was a newline; next glyph starts a new
       paragraph.

   4   Last typeset character may or may not have been a newline; must
       test before next call.

*/
-(int) layoutLineNewParagraph: (BOOL)newParagraph
{
  NSRect rect;

  /* Baseline and line height handling. */
  CGFloat lineHeight;      /* Current line height. */
  CGFloat maxLineHeight;   /* Maximum line height (usually from the paragraph style). */
  CGFloat ascender;        /* Amount of space we want above the baseline (always>=0). */
  CGFloat descender;       /* Amount of space we want below the baseline (always>=0). */

  /*
     These are values for the line as a whole. We start out by initializing
     for the first glyph on the line and then update these as we add more
     glyphs.

     If we need to increase the line height, we jump back to 'restart:' and
     rebuild our array of line fragment rects.

     (TODO (optimization): if we're dealing with a "simple rectangular
     text container", we should try to extend the existing line fragment in place
     before jumping back to do all the expensive checking).
  */

  /* TODO: doesn't have to be a simple horizontal container, but it's easier
     to handle that way. */
  if ([currentTextContainer isSimpleRectangularTextContainer] &&
      [currentLayoutManager _softInvalidateFirstGlyphInTextContainer: currentTextContainer] == currentGlyphIndex)
    {
      if ([self _reuseSoftInvalidatedLayout])
        return 4;
    }


  [self _moveCacheToGlyph: currentGlyphIndex];
  if (!cacheLength)
    [self _cacheGlyphsUpToLength: CACHE_INITIAL];
    
  if (!cacheLength && atEnd)
    {
      /*
      We've typeset all glyphs, and thus return 2. If we ended with a
      new-line, we set the extra line fragment rect here so the insertion point
      will be properly positioned after a trailing newline in the text.
      */
      if (newParagraph)
        {
          [self _addExtraLineFragment];
        }

      return 2;
    }

  /* Set up our initial baseline info. */
  {
    CGFloat min = [currentParagraphStyle minimumLineHeight];
    maxLineHeight = [currentParagraphStyle maximumLineHeight];

    /* sanity */
    if (maxLineHeight > 0 && maxLineHeight < min)
      maxLineHeight = min;

    lineHeight = [glyphCache->font defaultLineHeightForFont];
    ascender = [glyphCache->font ascender];
    descender = -[glyphCache->font descender];

    if (lineHeight < min)
      lineHeight = min;

    if (maxLineHeight > 0 && lineHeight > maxLineHeight)
      lineHeight = maxLineHeight;
  }

  /*
     If we find out that we need to increase the line height, we have to
     start over. The increased line height might give _completely_ different
     line fragment rects, so we can't reuse the layout information.

     OPT: However, we could recreate the line fragment rects and see if they
     match before throwing away layout information, since most of the time
     they will be equivalent.

     Also, in the very common case of a simple rectangular text container, we
     can always extend the current line fragment rects as long as they don't extend
     past the bottom of the container.
  */

  BOOL recalculateLineHeight = NO;
  int lineFragmentIndex = 0;
  unsigned int lastGlyphIndex = 0;
  NSPoint position = NSMakePoint(0.0, 0.0);
  do
    {
      do
        {
          NSRect remain;

          remain = [self _getProposedRectForNewParagraph: newParagraph
                                          withLineHeight: lineHeight];

          /*
            Build a list of all line fragment rects for this line.

            TODO: it's very convenient to do this in advance, but it might be
            inefficient, and in theory, we might end up with an insane number of line
            rects (eg. a text container with "hole"-columns every 100 points and
            width 1e8)
          */
          lineFragmentCount = 0;
          rect = [currentTextContainer lineFragmentRectForProposedRect: remain
                                                        sweepDirection: NSLineSweepRight
                                                     movementDirection: NSLineMovesDown
                                                         remainingRect: &remain];
          while (!NSIsEmptyRect(rect))
            {
              lineFragmentCount++;
              if (lineFragmentCount > lineFragmentCapacity)
                {
                  lineFragmentCapacity += 2;
                  lineFragments = realloc(lineFragments, sizeof(LineFragment) * lineFragmentCapacity);
                }
              lineFragments[lineFragmentCount - 1].rect = rect;

              rect = [currentTextContainer lineFragmentRectForProposedRect: remain
                                                            sweepDirection: NSLineSweepRight
                                                         movementDirection: NSLineDoesntMove
                                                             remainingRect: &remain];
            }
          if (lineFragmentCount == 0)
            {
              if (currentPoint.y == 0.0 &&
                  lineHeight > [currentTextContainer containerSize].height &&
                  [currentTextContainer containerSize].height > 0.0)
                {
                  /* Try to make sure each container contains at least one line fragment
                     rect by shrinking our line height. */
                  lineHeight = [currentTextContainer containerSize].height;
                  maxLineHeight = lineHeight;
                  continue;
                }
              return 1;
            }
        }
      while (lineFragmentCount == 0);

      recalculateLineHeight = [self _baseLayoutBlockNewParagraph: &newParagraph
                                                    onLineHeight: &lineHeight
                                                     considering: maxLineHeight
                                                   usingAscender: &ascender
                                                    andDescender: &descender
                                      returningLineFragmentIndex: &lineFragmentIndex
                                             returningGlyphIndex: &lastGlyphIndex
                                               returningPosition: &position];

    }
  while (recalculateLineHeight);

  /* Basic layout is done. */

  /* Take care of the alignments. */
  if (lineFragmentIndex != lineFragmentCount)
    {
      LineFragment *lineFragment = &lineFragments[lineFragmentIndex];

      lineFragment->lastGlyphIndex = lastGlyphIndex;
      lineFragment->lastUsed = position.x;

      /* TODO: incorrect if there is more than one line fragment */
      if ([currentParagraphStyle alignment] == NSRightTextAlignment)
        {
          [self rightAlignLine: lineFragments : lineFragmentCount];
        }
      else if ([currentParagraphStyle alignment] == NSCenterTextAlignment)
        {
          [self centerAlignLine: lineFragments : lineFragmentCount];
        }
    }
  else
    {
      if ([currentParagraphStyle lineBreakMode] == NSLineBreakByWordWrapping &&
          [currentParagraphStyle alignment] == NSJustifiedTextAlignment)
        {
          [self fullJustifyLine: lineFragments : lineFragmentCount];
        }
      else if ([currentParagraphStyle alignment] == NSRightTextAlignment)
        {
          [self rightAlignLine: lineFragments : lineFragmentCount];
        }
      else if ([currentParagraphStyle alignment] == NSCenterTextAlignment)
        {
          [self centerAlignLine: lineFragments : lineFragmentCount];
        }

      lineFragmentIndex--;
    }

  /* Layout is complete. Package it and give it to the layout manager. */
  [currentLayoutManager setTextContainer: currentTextContainer
                           forGlyphRange: NSMakeRange(cacheBase, lastGlyphIndex)];
  currentGlyphIndex = lastGlyphIndex + cacheBase;
  {
    LineFragment *lineFragment;
    NSPoint glyphPosition;
    unsigned int glyphCounter, savedGlyphCounter;
    GlyphCacheEntry *glyphEntry;
    NSRect usedRect;

    CGFloat baseline = lineHeight - descender;

    glyphCounter = 0;
    glyphEntry = glyphCache;
    for (lineFragment = lineFragments; lineFragmentIndex >= 0; lineFragmentIndex--, lineFragment++)
      {
        usedRect.origin.x = glyphEntry->position.x + lineFragment->rect.origin.x;
        usedRect.size.width = lineFragment->lastUsed - glyphEntry->position.x;
        /* TODO: be pickier about height? */
        usedRect.origin.y = lineFragment->rect.origin.y;
        usedRect.size.height = lineFragment->rect.size.height;

        [currentLayoutManager setLineFragmentRect: lineFragment->rect
                                    forGlyphRange: NSMakeRange(cacheBase + glyphCounter, lineFragment->lastGlyphIndex - glyphCounter)
                                         usedRect: usedRect];
        glyphPosition = glyphEntry->position;
        glyphPosition.y += baseline;
        savedGlyphCounter = glyphCounter;
        while (glyphCounter < lineFragment->lastGlyphIndex)
          {
            if (glyphEntry->outsideLineFragment)
              {
                [currentLayoutManager setDrawsOutsideLineFragment: YES
                                                  forGlyphAtIndex: cacheBase + glyphCounter];
              }
            if (glyphEntry->dontShow)
              {
                [currentLayoutManager setNotShownAttribute: YES
                                           forGlyphAtIndex: cacheBase + glyphCounter];
              }
            if (!glyphEntry->nominal && glyphCounter != savedGlyphCounter)
              {
                [currentLayoutManager setLocation: glyphPosition
                             forStartOfGlyphRange: NSMakeRange(cacheBase + savedGlyphCounter, glyphCounter - savedGlyphCounter)];
                if (glyphEntry[-1].glyph == GSAttachmentGlyph)
                  {
                    [currentLayoutManager setAttachmentSize: glyphEntry[-1].size
                                              forGlyphRange: NSMakeRange(cacheBase + savedGlyphCounter, glyphCounter - savedGlyphCounter)];
                  }
                glyphPosition = glyphEntry->position;
                glyphPosition.y += baseline;
                savedGlyphCounter = glyphCounter;
              }
            glyphCounter++;
            glyphEntry++;
          }
        if (glyphCounter != savedGlyphCounter)
          {
            [currentLayoutManager setLocation: glyphPosition
                         forStartOfGlyphRange: NSMakeRange(cacheBase + savedGlyphCounter, glyphCounter - savedGlyphCounter)];
            if (glyphEntry[-1].glyph == GSAttachmentGlyph)
              {
                [currentLayoutManager setAttachmentSize: glyphEntry[-1].size
                                          forGlyphRange: NSMakeRange(cacheBase + savedGlyphCounter, glyphCounter - savedGlyphCounter)];
              }
          }
      }
  }

  currentPoint = NSMakePoint(0, NSMaxY(lineFragments->rect));

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
  int ret, realRet;
  BOOL newParagraph;

  if (![lock tryLock])
    {
      /* Since we might be the shared system typesetter, we must be
      reentrant. Thus, if we are already in use and can't lock our lock,
      we create a new instance and let it handle the call. */
      GSHorizontalTypesetter *tempTypesetter;

      tempTypesetter = [[object_getClass(self) alloc] init];
      ret = [tempTypesetter layoutGlyphsInLayoutManager: layoutManager
                                        inTextContainer: textContainer
                                   startingAtGlyphIndex: glyphIndex
                               previousLineFragmentRect: previousLineFragRect
                                         nextGlyphIndex: nextGlyphIndex
                                  numberOfLineFragments: howMany];
      DESTROY(tempTypesetter);
      return ret;
    }

NS_DURING
  currentLayoutManager = layoutManager;
  currentTextContainer = textContainer;
  currentTextStorage = [layoutManager textStorage];

/*    printf("*** layout some stuff |%@|\n", currentTextStorage);
    [currentLayoutManager _glyphDumpRuns];*/

  currentGlyphIndex = glyphIndex;

  [self _clearCache];

  realRet = 4;
  currentPoint = NSMakePoint(0, NSMaxY(previousLineFragRect));
  while (1)
    {
      if (realRet == 4)
        {
          /*
          -layoutLineNewParagraph: needs to know if the starting glyph is the
          first glyph of a paragraph so it can apply eg. -firstLineHeadIndent and
          paragraph spacing properly.
          */
          if (!currentGlyphIndex)
            {
              newParagraph = YES;
            }
          else
            {
              unsigned int charIndex;
              unichar character;
              charIndex = [currentLayoutManager characterRangeForGlyphRange: NSMakeRange(currentGlyphIndex - 1, 1)
                                                           actualGlyphRange: NULL].location;

              character = [[currentTextStorage string] characterAtIndex: charIndex];

              if (character == '\n')
                newParagraph = YES;
              else
                newParagraph = NO;
            }
        }
      else if (realRet == 3)
        {
          newParagraph = YES;
        }
      else
        {
          newParagraph = NO;
        }

      ret = [self layoutLineNewParagraph: newParagraph];

      realRet = ret;
      if (ret == 3 || ret == 4)
        ret = 0;

      if (ret)
        break;

      if (howMany)
        if (!--howMany)
          break;
   }

  *nextGlyphIndex = currentGlyphIndex;
NS_HANDLER
  NSLog(@"GSHorizontalTypesetter - %@", [localException reason]);
  [lock unlock];
  [localException raise];
  ret = 0; /* This is never reached, but it shuts up the compiler. */
NS_ENDHANDLER
  [lock unlock];
  return ret;
}

@end
