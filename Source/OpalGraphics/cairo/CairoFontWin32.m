/** <title>CairoFontWin32</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

// FIXME: hack, fix the build system
#ifdef __MINGW__

#import "CairoFontWin32.h"
#import "StandardGlyphNames.h"

typedef uint32_t Fixed;
typedef int16_t FWord; 
typedef uint16_t UFWORD;

struct post_table {
  Fixed Version;
  Fixed italicAngle;
  FWord underlinePosition;
  FWord underlineThickness;
  ULONG	isFixedPitch;
  ULONG	minMemType42;
  ULONG	maxMemType42;
  ULONG	minMemType1;
  ULONG	maxMemType1;
  // Only for version 2.0
  USHORT numberOfGlyphs;
  USHORT glyphNameIndex; //USHORT glyphNameIndex[numGlyphs];
  //CHAR names[numberNewGlyphs];
};

struct hhea_table{
  Fixed	ver;
  FWord	Ascender;
  FWord	Descender;
  FWord	LineGap;
  UFWORD advanceWidthMax;
  FWord	minLeftSideBearing;
  FWord	minRightSideBearing;
  FWord	xMaxExtent;
  SHORT	caretSlopeRise;
  SHORT	caretSlopeRun;
  SHORT	caretOffset;
  SHORT	r1;
  SHORT	r2;
  SHORT r3;
  SHORT r4;
  SHORT	metricDataFormat;
  USHORT numberOfHMetrics;
};

typedef struct 	_longHorMetric {
	USHORT	advanceWidth;
	SHORT		lsb;
}  longHorMetric;



@implementation CairoFontWin32

- (void) dealloc
{
  DeleteObject(hfont);
  [super dealloc];
}
  
- (CFStringRef) copyGlyphNameForGlyph: (CGGlyph)glyph
{
  HDC hdc = CreateCompatibleDC(NULL);
  SelectObject(hdc, hfont);
  
  // See http://www.microsoft.com/typography/otspec150/post.htm
   
  DWORD tableName = GSSwapBigI32ToHost('post');
  DWORD size = GetFontData(hdc, tableName, 0, NULL, 0);
  if (size == GDI_ERROR)
  {
    printf("CGFontCopyGlyphNameForGlyph: GDI error getting 'post' table");
    DeleteDC(hdc);
    return nil;
  }
    
  struct post_table *data = malloc(size);
  
  if (size != GetFontData(hdc, tableName, 0, data, size))
  {
    printf("CGFontCopyGlyphNameForGlyph: Getting 'post' table contents failed");
    DeleteDC(hdc);
    free(data);
    return nil;
  }
  
  if (GSSwapBigI32ToHost(data->Version) != 0x00020000)
  {
    // FIXME: handle other versions.
    printf("CGFontCopyGlyphNameForGlyph: 'post' table version != 2");
    DeleteDC(hdc);
    free(data);
    return nil;
  }
  
  USHORT glyphNameIndex = GSSwapBigI16ToHost((&(data->glyphNameIndex))[glyph]);
  
  if (glyphNameIndex < 258)
  {
    DeleteDC(hdc);
    CFStringRef ret = [[NSString alloc] initWithUTF8String: StandardGlyphNames[glyphNameIndex]]; 
    free(data);
    return ret;
  }
  else
  {
    glyphNameIndex -= 258; // Use this as an index into the list of pascal strings
  }
  
  unsigned char *names = (unsigned char *)(&(data->glyphNameIndex) + GSSwapBigI16ToHost(data->numberOfGlyphs));

  int index = 0;
  for (unsigned char *ptr = names; (ptr - (unsigned char *)data) < size; )
  {
    int count = ptr[0];
    ptr++;
    
    if (index == glyphNameIndex)
    {
      DeleteDC(hdc);
      CFStringRef ret = [[NSString alloc] initWithBytes: ptr length: count encoding: NSASCIIStringEncoding];
      free(data);
      return ret;
    }
    else
    {
      ptr += count;
    }
    index++;
  }
  
  DeleteDC(hdc);
  free(data);
  return nil;
}

- (CGGlyph) glyphWithGlyphName: (CFStringRef)glyphName
{
  HDC hdc = CreateCompatibleDC(NULL);
  SelectObject(hdc, hfont);
  
  // See http://www.microsoft.com/typography/otspec150/post.htm
   
  DWORD tableName = GSSwapBigI32ToHost('post');
  DWORD size = GetFontData(hdc, tableName, 0, NULL, 0);
  if (size == GDI_ERROR)
  {
    printf("CGFontGetGlyphWithGlyphName: GDI error getting 'post' table");
    DeleteDC(hdc);
    return 0;
  }
    
  struct post_table *data = malloc(size);
  
  if (size != GetFontData(hdc, tableName, 0, data, size))
  {
    printf("CGFontGetGlyphWithGlyphName: Getting 'post' table contents failed");
    DeleteDC(hdc);
    free(data);
    return 0;
  }
  
  if (GSSwapBigI16ToHost(data->Version) != 2)
  {
    // FIXME: handle other versions.
    printf("CGFontGetGlyphWithGlyphName: 'post' table version != 2");
    DeleteDC(hdc);
    free(data);
    return 0;
  }
  
  const char *glyphNameCString = [glyphName UTF8String];
  const int glyphNameCStringLen = strlen(glyphNameCString);
 
  for (int i=0; i<258; i++)
  {
    if (0 == strcmp(glyphNameCString, StandardGlyphNames[i]))
    {
      for (CFIndex j=0; j<self->numberOfGlyphs; j++)
      {
        if (GSSwapBigI16ToHost((&(data->glyphNameIndex))[j]) == i)
        {
          DeleteDC(hdc);
          free(data);
          return (CGGlyph)j;
        }
      }
      
      printf("CGFontGetGlyphWithGlyphName: Warning, %s is a standard glyph name but it is not present in the font\n", glyphNameCString);
      break;
    }
  }
   
  unsigned char *names = (unsigned char*)(&(data->glyphNameIndex) + self->numberOfGlyphs);
  
  int index = 0;
  for (unsigned char *ptr = names; (ptr - (unsigned char *)data) < size; )
  {
    int count = ptr[0];
    ptr++;
    if (count == glyphNameCStringLen && 0 == memcmp(ptr, glyphNameCString, count))
    {      
      int glyphNameIndex = index + 258;
      
      // Search for the glyph with this glyphNameIndex
      for (CFIndex j=0; j<self->numberOfGlyphs; j++)
      {
        if (GSSwapBigI16ToHost((&(data->glyphNameIndex))[j]) == glyphNameIndex)
        {
          DeleteDC(hdc);
          free(data);
          return (CGGlyph)j;
        }
      }
      
      printf("CGFontGetGlyphWithGlyphName: Warning, %s is in the font glyph name dictionary but it is not assigned to any glyph in the font\n", glyphNameCString);
      break;
    }
    else
    {
      ptr += count;
    }
    index++;
  }
  
  DeleteDC(hdc);
  free(data);
  return (CGGlyph)0;
}

- (bool) getGlyphAdvances: (const CGGlyph[])glyphs
                         : (size_t)count
                         : (int[]) advances
{
  HDC hdc = CreateCompatibleDC(NULL);
  SelectObject(hdc, hfont);

  DWORD tableName = GSSwapBigI32ToHost('hhea');
  DWORD size = GetFontData(hdc, tableName, 0, NULL, 0);
  if (size == GDI_ERROR)
  {
    printf("CGFontGetGlyphAdvances: GDI error getting 'hhea' table");
    DeleteDC(hdc);
    return false;
  }
  
  struct hhea_table *data = malloc(size);

  if (size != GetFontData(hdc, tableName, 0, data, size))
  {
    printf("CGFontGetGlyphAdvances: Error getting contents of 'hhea' table");
    DeleteDC(hdc);
    free(data);
    return false;      
  }
  
  UINT numHMetrics = GSSwapBigI16ToHost(data->numberOfHMetrics);
  
  DWORD tableName2 = GSSwapBigI32ToHost('hmtx');
  DWORD size2 = GetFontData(hdc, tableName2, 0, NULL, 0);
  if (size2 == GDI_ERROR)
  {
    printf("CGFontGetGlyphAdvances: GDI error getting 'hmtx' table");
    DeleteDC(hdc);
    free(data);
    return false;
  }
  
  longHorMetric *data2 = malloc(size2);

  if (size2 != GetFontData(hdc, tableName2, 0, data2, size2))
  {
    printf("CGFontGetGlyphAdvances: Error getting contents of 'hmtx' table");
    DeleteDC(hdc);
    free(data);
    free(data2);
    return false;      
  }
  
  for (int i=0; i<count; i++)
  {
    CGGlyph g = glyphs[i];
    int indexToUse;
    if (g > (numHMetrics - 1))
      indexToUse = numHMetrics - 1;
    else
      indexToUse = g;
    advances[i] = GSSwapBigI16ToHost(data2[indexToUse].advanceWidth);
  }
  
  DeleteDC(hdc);
  free(data);
  free(data2);  
  return true;
}

- (CFDataRef) copyTableForTag: (uint32_t)tag
{
  return nil;
}

- (CFArrayRef) copyTableTags
{
  return nil;
}

- (CFArrayRef) copyVariationAxes
{
  return nil;
}

- (CFDictionaryRef) copyVariations
{
  return nil;
}

- (CGFontRef) createCopyWithVariations: (CFDictionaryRef)variations
{
  return nil;
}

- (CFDataRef) createPostScriptEncoding: (const CGGlyph[])encoding
{
  return nil;
}

+ (CGFontRef) createWithFontName: (CFStringRef)name
{
  CairoFontWin32 *font = [[CairoFontWin32 alloc] init];
  cairo_font_face_t *unscaled;
  
  if (NULL == font) return nil;

  font->hfont = CreateFont(46, 28, 215, 0,
                           FW_NORMAL, FALSE, FALSE, FALSE,
                           ANSI_CHARSET, OUT_DEFAULT_PRECIS,
		         CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
		         DEFAULT_PITCH | FF_ROMAN,
			"Times New Roman");

  if (font->hfont) {
    unscaled = cairo_win32_font_face_create_for_hfont(font->hfont);
  } else {
    [font release];
    return nil;
  }

  // Create a cairo_scaled_font which we just use to access the underlying
  // FT_Face

  cairo_matrix_t ident;
  cairo_matrix_init_identity(&ident);

  cairo_font_options_t *opts = cairo_font_options_create();
  cairo_font_options_set_hint_metrics(opts, CAIRO_HINT_METRICS_OFF);
  cairo_font_options_set_hint_style(opts, CAIRO_HINT_STYLE_NONE);
  
  font->cairofont = cairo_scaled_font_create(unscaled, &ident, &ident, opts);
    
  cairo_font_options_destroy(opts);
  
  
  
  
  // Get metrics
  
  HDC hdc = CreateCompatibleDC(NULL);
  SelectObject(hdc, font->hfont);
  
  
  UINT metricsSize = GetOutlineTextMetrics(hdc, 0, NULL);
  if (metricsSize != 0)
  {
    LPOUTLINETEXTMETRIC metricsData = malloc(metricsSize);
    GetOutlineTextMetrics(hdc, metricsSize, metricsData);
    
    font->unitsPerEm = metricsData->otmEMSquare;  
    
    // FIXME: get real values
    font->fullName = @"";
    font->postScriptName = @"";
    font->ascent = 2000;
    font->capHeight = 2000;
    font->descent = 500;
    font->fontBBox = CGRectMake(0,0,2000,2000);
    font->italicAngle = 0;
    font->leading = 500;
    font->stemV = 500;
    font->xHeight = 2000; 
    
    free(metricsData);
  }
  else
  {
    printf("CGCreateFontWithName: Warning: couldn't get font metrics");
  }  
  
  /* Get the number of glyphs from the 'post' table */

  font->numberOfGlyphs = 0;

  DWORD tableName = GSSwapBigI32ToHost('post');
  DWORD size = GetFontData(hdc, tableName, 0, NULL, 0);  
  if (size != GDI_ERROR)
  {
    struct post_table *data = malloc(size);
    if (size == GetFontData(hdc, tableName, 0, data, size))
    {
      font->numberOfGlyphs = GSSwapBigI16ToHost(data->numberOfGlyphs);  
    }
  }

  if (font->numberOfGlyphs == 0)
  {
    printf("CGCreateFontWithName: Warning: font has 0 glyphs");    
  }

  DeleteDC(hdc);

  return (CGFontRef)font;
}

+ (CGFontRef) createWithPlatformFont: (void *)platformFontReference
{
  return nil;
}



@end

#endif
