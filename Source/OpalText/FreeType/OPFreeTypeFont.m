/** <title>OPFreeTypeFont</title>

   <abstract>Font Handling Class using FreeType2</abstract>

   Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>

   Author: Niels Grewe
   Date: Feb 2011

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */


#import "OPFreeTypeFont.h"
#import "OPFreeTypeUtil.h"
#include <stdint.h>

#include FT_TRUETYPE_TABLES_H
#include FT_TRUETYPE_TAGS_H
#include FT_TYPE1_TABLES_H
#include FT_GLYPH_H


#define REAL_SIZE(x) CGFloatFromFontUnits(x, [_descriptor pointSize], fontFace->units_per_EM)

// FIXME: This definitions need to be ammended to take vertical typesetting into
// account.
#define TRANSFORMED_SIZE(x,y)\
  ((CGSize)(CGSizeApplyAffineTransform(CGSizeMake(REAL_SIZE(x), REAL_SIZE(y)), _matrix.CGTransform)))

#define TRANSFORMED_POINT(x,y)\
  ((CGPoint)(CGPointApplyAffineTransform(CGPointMake(REAL_SIZE(x), REAL_SIZE(y)), _matrix.CGTransform)))

#define TRANSFORMED_RECT(x,y,w,h)\
  ((CGRect)(CGRectApplyAffineTransform(CGRectMake(REAL_SIZE(x), REAL_SIZE(y), REAL_SIZE(w), REAL_SIZE(h)), _matrix.CGTransform)))

#ifndef NSRectFromCGRect
#define NSRectFromCGRect(r) NSMakeRect(r.origin.x, r.origin.y, r.size.width, r.size.height)
#endif
static const NSString *kOPFreeTypeLibrary = @"OPFreeTypeLibrary";


@interface NSObject (NSFontconfigFontDescriptorInternals)
- (NSString*)_fontPath;
- (NSInteger)_fontfaceIndex;
@end

@implementation OPFreeTypeFont

- (FT_Library)currentThreadFreeTypeLibrary
{
  NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
 
  if (nil == [threadDict objectForKey: kOPFreeTypeLibrary])
  {
    FT_Library library = NULL;
    NSInteger error = FT_Init_FreeType(&library);
    if (0 != error)
    {
      [NSException raise: @"OTFontSystemException"
                  format: @"An error (%ld) occurred when initializing the FreeType library.", error];
    }
    [threadDict setObject: [NSValue valueWithPointer: library] forKey: kOPFreeTypeLibrary];
  }

  return [[threadDict objectForKey: kOPFreeTypeLibrary] pointerValue];
}

- (id)_initWithDescriptor: (NSFontDescriptor*)aDescriptor
                  options: (CTFontOptions)options
{
  NSInteger error = 0;
  const char* path;
  NSInteger faceIndex = NSNotFound;
  if (nil == (self = [super _initWithDescriptor: aDescriptor
                                        options: options]))
  {
    return nil;
  }
  /*
   * FIXME: It is ugly to rely on the font descriptor being a
   * NSFontconfigFontDescriptor but it is probably the most common situation.
   */
  if ([aDescriptor respondsToSelector: @selector(_fontPath)])
  {
    path = [[_descriptor _fontPath] UTF8String];
  }
  else
  {
    path = NULL;
  }
  if ([aDescriptor respondsToSelector: @selector(_fontfaceIndex)])
  {
    faceIndex = [_descriptor _fontfaceIndex];
  }

  if ((NSNotFound == faceIndex) || (NULL == path))
  {
    NSWarnMLog(@"Could not read freetype intialization information from font descriptor");
    [self release];
    return nil;
  }

  error = FT_New_Face([self currentThreadFreeTypeLibrary], path, faceIndex, &fontFace);
  if (0 != error)
  {
    NSWarnMLog(@"Could not initialize freetype font (error: %ld)",
      error);
    [self release];
    return nil;
  }

  /*
   * Check whether we are dealing with an sfnt packaged font. If not, we may be
   * loading a Type-1 font. We can use those as well, but we need to load the
   * metrics from the corresponding afm file.
   */
  if ((0 == faceIndex) && (NO == (BOOL)FT_IS_SFNT(fontFace)))
  {
    if (NO == [self attachMetricsForFontAtPath: [_descriptor _fontPath]])
    {
      [self release];
      return nil;
    }
    else
    {
      /*
       * We were able to load the metrics for the font and flag the font object
       * accordingly.
       * FIXME: Move to another subclass in this case.
       */
      isType1 = YES;
    }
  }
  // At this point, we are sure that freetype has a proper reference to the
  // font, so it's worth setting up our table cache now.
  tableCache = [[NSCache alloc] init];
  [tableCache setEvictsObjectsWithDiscardedContent: YES];

  FT_Matrix matrix = FT_MatrixFromCGAffineTransform(_matrix.CGTransform);
  FT_Vector vector = FT_VectorQ1616FromCGAffineTransform(_matrix.CGTransform);
  FT_Set_Transform(fontFace, &matrix, &vector);
  //FIXME: Do more stuff

  fontFaceLock = [[NSLock alloc] init];

  return self;
}

// FIXME: Implement -dealloc?

- (BOOL)attachMetricsForFontAtPath: (NSString*)path
{
  NSString *extension = [[path pathExtension] lowercaseString];
  NSString *afmPath = nil;
  NSInteger error = 0;

  if ([@"pfa" isEqual: extension] || [@"pfb" isEqual: extension])
  {
    /*
     * If the file already has a proper Type-1 extension, we assume that we need
     * to replace that with .afm. Hence, we remove the extension from the path
     * at this point.
     */
    afmPath = [path substringToIndex: ([path length] - 4)];
  }
  else
  {
    afmPath = path;
  }

  // Add the proper extension
  afmPath = [afmPath stringByAppendingString: @".afm"];

  // We just leave loading the metric to freetype:
  error = FT_Attach_File(fontFace, [afmPath UTF8String]);

  // Return NO if an error occurred:
  return (0 == error);
}


- (NSData*)loadTableForTag: (uint32_t)tag
{
  NSUInteger length = 0;
  NSInteger error = 0;
  void *buffer;
  NSData *table = nil;

  if (0 == tag)
  {
    // tag == 0 means "whole file", and the caller didn't really mean that.
    return nil;
  }

  // First, run with a NULL pointer for the buffer to obtain the length needed.
  [fontFaceLock lock];
  error = FT_Load_Sfnt_Table(fontFace, tag, 0, NULL, &length);

  if (0 != error)
  {
    [fontFaceLock unlock];
    return nil;
  }

  // Allocate memory for the table:
  buffer = malloc(length);
  if (NULL == buffer)
  {
    [fontFaceLock unlock];
    return nil;
  }

  // Now load the table into the buffer:
  error = FT_Load_Sfnt_Table(fontFace, tag, 0, buffer, &length);

  [fontFaceLock unlock];

  if (0 != error)
  {
    // Oops, we could not fill the buffer, so we throw it away.
    free(buffer);
    return nil;
  }

  table = [NSData dataWithBytesNoCopy: buffer
                               length: length];
  /*
   * NOTE: the table object takes ownership of the allocated buffer and will
   * free it on deallocation.
   */
  return table;
}

- (NSData*)tableForTag: (uint32_t)tag
{
  // Unpack the tag into a table name:
  uint32_t first = tag;
  uint32_t second = tag >> 8;
  uint32_t third = tag >> 16;
  uint32_t fourth = tag >> 24;
  unichar tagUnichars[4] = {*(char*)&first, *(char*)&second, *(char*)&third, *(char*)&fourth};
  NSString *tagString = [[NSString alloc] initWithCharacters: tagUnichars
                                                      length: 4];
  NSData *table = [tableCache objectForKey: tagString];
  if (nil == table)
  {
    table = [self loadTableForTag: tag];
    if (table != nil)
    {
      [tableCache setObject: table
                     forKey: tagString
		       cost: [table length]];
    }
  }

  [tagString release];
  return table;
}

- (CGFloat)unitsPerEm
{
  [fontFaceLock lock];
  CGFloat result = (CGFloat)fontFace->units_per_EM;
  [fontFaceLock unlock];

  return result;
}

- (CGFloat)ascender
{
  [fontFaceLock lock];
  CGFloat result = ((fontFace->ascender * [_descriptor pointSize]) / (CGFloat)fontFace->units_per_EM);
  [fontFaceLock unlock];

  return result;
}


- (CGFloat)descender
{
  [fontFaceLock lock];
  CGFloat result = ((fontFace->descender * [_descriptor pointSize]) / (CGFloat)fontFace->units_per_EM);
  [fontFaceLock unlock];

  return result;
}

/* TODO: If this kind of method is too slow, we will have to cache the results
 * instead of the tables.
 */
- (CGFloat)capHeight
{
  FT_Short rawCapHeight = 0;

  [fontFaceLock lock];
  TT_OS2* OS2Table = FT_Get_Sfnt_Table(fontFace, TTAG_OS2);
  if (NULL == OS2Table)
  {
    [fontFaceLock unlock];
    return 0;
  }
  rawCapHeight = OS2Table->sCapHeight;
  [fontFaceLock unlock];

  return TRANSFORMED_SIZE(0, rawCapHeight).height;
}

- (CGFloat)xHeight
{
  FT_Short rawXHeight = 0;

  [fontFaceLock lock];
  TT_OS2* OS2Table = FT_Get_Sfnt_Table(fontFace, TTAG_OS2);
  if (NULL == OS2Table)
  {
    [fontFaceLock unlock];
    return 0;
  }
  rawXHeight = OS2Table->sxHeight;
  [fontFaceLock unlock];

  return TRANSFORMED_SIZE(0, rawXHeight).height;

}

- (BOOL)isFixedPitch
{
  BOOL isFixedPitch = NO;

  [fontFaceLock lock];
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    [fontFaceLock unlock];
    return NO;
  }
  isFixedPitch = postTable->isFixedPitch;
  [fontFaceLock unlock];

  return isFixedPitch;
}

- (CGFloat)italicAngle
{
  FT_Fixed rawItalicAngle = 0;
  [fontFaceLock lock];
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    [fontFaceLock unlock];
    return 0;
  }
  rawItalicAngle = postTable->italicAngle;
  [fontFaceLock unlock];

  return CGFloatFromFT_Fixed(rawItalicAngle);
}

- (CGFloat)leading
{
  /*
   * FIXME: We should make this conditional on horizontal/vertical orientation
   * but we probably don't need to because the hhea and vhea tables are supposed
   * to be identical.
   */
  FT_Short rawLineGap = 0;

  [fontFaceLock lock];
  TT_HoriHeader *hheaTable = FT_Get_Sfnt_Table(fontFace, TTAG_hhea);
  if (NULL == hheaTable)
  {
    [fontFaceLock unlock];
    return 0;
  }
  rawLineGap = hheaTable->Line_Gap;
  [fontFaceLock unlock];

  return TRANSFORMED_SIZE(0, rawLineGap).height;
}

- (NSSize)maximumAdvancement
{
  /*
   * FIXME: We should make this conditional on horizontal/vertical orientation.
   */
  [fontFaceLock lock];
  NSSize size = NSMakeSize(REAL_SIZE(fontFace->max_advance_width), REAL_SIZE(fontFace->max_advance_height));
  [fontFaceLock unlock];

  return size;
}

- (NSSize)minimumAdvancement
{
  /*
   * FIXME: We don't really want the bounding box here
   * FIXME2: We should make this conditional on horizontal/vertical orientation.
   * FIXME3: Does FreeType apply the transform to the bounding box?
   */
  [fontFaceLock lock];
  NSSize size = NSMakeSize(REAL_SIZE((fontFace->bbox).xMin),
    REAL_SIZE((fontFace->bbox).yMin));
  [fontFaceLock unlock];

  return size;
}

- (NSUInteger)numberOfGlyphs
{
  [fontFaceLock lock];
  NSUInteger result = fontFace->num_glyphs;
  [fontFaceLock unlock];
  return result;
}

- (CGFloat)underlinePosition
{
  [fontFaceLock lock];
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    [fontFaceLock unlock];
    return 0;
  }
  CGFloat position = TRANSFORMED_SIZE(0, postTable->underlinePosition).height;
  [fontFaceLock unlock];
  return position;
}

- (CGFloat)underlineThickness
{
  [fontFaceLock lock];
  TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
  if (NULL == postTable)
  {
    [fontFaceLock unlock];
    return 0;
  }
  CGFloat thickness = TRANSFORMED_SIZE(0, postTable->underlineThickness).height;
  [fontFaceLock unlock];
  return thickness;
}

- (NSSize)advancementForGlyph: (NSGlyph)glyph
{
  if ((NSNullGlyph == glyph) || (NSControlGlyph == glyph))
  {
    return NSMakeSize(0, 0);
  }
  [fontFaceLock lock];
  FT_Load_Glyph(fontFace, glyph, FT_LOAD_DEFAULT);
  NSSize size = NSMakeSize(REAL_SIZE(fontFace->glyph->linearHoriAdvance),
    REAL_SIZE(fontFace->glyph->linearVertAdvance));
  [fontFaceLock unlock];

  return size;
  /*
   * FIXME: Add fast path for integer rendering modes. We don't need to do
   * so many integer->float conversions then.
   */
}

- (void)getAdvancements: (NSSizeArray)advancements
              forGlyphs: (const NSGlyph*)glyphs
	          count: (NSUInteger)glyphCount
{
  NSSize nullSize = NSMakeSize(0,0);
  for (int i = 0; i < glyphCount; i++, glyphs++, advancements++)
  {
    if ((NSNullGlyph == *glyphs) || (NSControlGlyph == *glyphs))
    {
      *advancements = nullSize;
    }
    else
    {
      //TODO: Optimize if too slow.
      *advancements = [self advancementForGlyph: *glyphs];
    }
  }
}

- (void)getAdvancements: (NSSizeArray)advancements
        forPackedGlyphs: (const void*)packedGlyphs
	         length: (NSUInteger)length
{
  /*
   * We only support NSNativeShortGlyphPacking, which gives us glyph streams
   * which are big-endian, short integer values.
   */

  // FIXME: Breaks for platforms where shorts are not word aligned.
  NSUInteger glyphsPerWord = sizeof(void*)/sizeof(unsigned short);
  NSUInteger maxGlyphCount = length * glyphsPerWord;
  NSUInteger step = 0;
  for (int i=0; i < maxGlyphCount; i++, step = (i / sizeof(void*)), advancements++)
  {
    /*
     * Mask the value by bit-shifting it to the correct starting point,
     * truncating it to short, and converting it back to host byte-order.
     */

    /*
     * The modulus of index and word size calculates how many glyphs we
     * processed in this word, so we shift the content of the word by n
     * times the size of short.
     */
    NSUInteger shift = ((i % sizeof(void*)) * sizeof(unsigned short));
    NSGlyph glyph = NSSwapBigShortToHost((unsigned short)(((intptr_t*)packedGlyphs)[step] << shift));

    // TODO: Optimize if too slow
    *advancements = [self advancementForGlyph: glyph];
  }
}

- (NSRect)boundingRectForFont
{
  //FIXME: Determine whether FreeType already transforms the bounding box for
  //us.
  [fontFaceLock lock];
  CGFloat originX = REAL_SIZE((fontFace->bbox).xMin);
  CGFloat originY = REAL_SIZE((fontFace->bbox).yMin);
  CGFloat sizeX = (REAL_SIZE((fontFace->bbox).xMax) - originX);
  CGFloat sizeY = (REAL_SIZE((fontFace->bbox).yMax) - originY);
  [fontFaceLock unlock];

  return NSMakeRect(originX, originY, sizeX, sizeY);
}

- (NSRect)boundingRectforGlyph: (NSGlyph)glyph
{
  //FIXME: Handle vertical typesetting.
  if ((NSNullGlyph == glyph) || (NSControlGlyph == glyph))
  {
    return NSMakeRect(0, 0, 0, 0);
  }

  [fontFaceLock lock];
  FT_Load_Glyph(fontFace, glyph, FT_LOAD_DEFAULT);
  NSRect result = NSRectFromCGRect(TRANSFORMED_RECT(fontFace->glyph->metrics.horiBearingX,
    fontFace->glyph->metrics.horiBearingY,
    fontFace->glyph->metrics.width,
    fontFace->glyph->metrics.height));
  [fontFaceLock unlock];
  return result;
}

- (void)getBoundingRects: (NSRectArray)rects
               forGlyphs: (const NSGlyph*)glyphs
	           count: (NSUInteger)glyphCount
{
  NSRect nullRect = NSMakeRect(0,0,0,0);
  for (int i = 0; i < glyphCount; i++, glyphs++, rects++)
  {
    if ((NSNullGlyph == *glyphs) || (NSControlGlyph == *glyphs))
    {
      *rects = nullRect;
    }
    else
    {
      //TODO: Optimize if too slow.
      *rects = [self boundingRectForGlyph: *glyphs];
    }
  }
}

- (NSGlyph)glyphWithName: (NSString*)name
{
  [fontFaceLock lock];
  FT_UInt glyph = FT_Get_Name_Index(fontFace, (FT_String*)[name UTF8String]);
  [fontFaceLock unlock];
  if(0 == glyph)
  {
    return NSNullGlyph;
  }
  return glyph;
}

@end

