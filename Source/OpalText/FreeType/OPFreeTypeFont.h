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


#include <ft2build.h>
#include FT_FREETYPE_H

#import "../NSFont.h"
#include <stdint.h>
@interface OPFreeTypeFont: NSFont
{
  FT_Face fontFace;
  /**
   * NSFont can be used simultaneously by multiple threads, so it is
   * necessary to lock before we call FreeType, because an FT_Face
   * object may be used by only one thread.
   */
  NSLock *fontFaceLock;
  BOOL isType1;
  NSCache *tableCache;
}


/**
 * This method is called by the initializer to load additional font metrics
 * from an extern file. This will happen when the font is not a TrueType or
 * OpenType font but a Type-1 font instead.
 */
- (BOOL)attachMetricsForFontAtPath: (NSString*)path;

/**
 * Obtains the truetype table with the corresponding tag. The object is
 * disposable and has been marked as accessed on return from the method. The
 * caller is resonsible for calling -endContentAccess on it.
 */
- (NSData*)tableForTag: (uint32_t)tag;

@end
