/** <title>CTRun</title>
 
 <abstract>C Interface to text layout library</abstract>
 
 Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>
 
 Author: Eric Wasylishen
 Date: Mar 2011
 
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

#include <CoreText/CTRun.h>

/**
 * Container of adjacent glyphs with the same attributes which have been layed out
 */
@interface CTRun : NSObject
{
  size_t _count;
  CGGlyph *_glyphs; // pointer to C array of glphs
  CGSize *_advances;
  CGPoint *_positions;
  CFIndex *_stringIndices;
  CFRange _stringRange;
  NSDictionary *_attributes;
  CTRunStatus _status;
  CGAffineTransform _matrix;
}

- (CFIndex)glyphCount;
- (NSDictionary*)attributes;
- (CTRunStatus)status;
- (const CGGlyph *)glyphs;
- (const CGPoint *)positions;
- (const CGSize *)advances;
- (const CFIndex *)stringIndices;
- (CFRange)stringRange;
- (double)typographicBoundsForRange: (CFRange)range
                             ascent: (CGFloat*)ascent
                            descent: (CGFloat*)descent
                            leading: (CGFloat*)leading;
- (CGRect)imageBoundsForRange: (CFRange)range
                  withContext: (CGContextRef)context;
- (CGAffineTransform)matrix;
- (void)drawRange: (CFRange)range onContext: (CGContextRef)ctx;

@end
