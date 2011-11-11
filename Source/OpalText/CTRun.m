/** <title>CTRun</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

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

#import "CTRun-private.h"

/* Classes */

@implementation CTRun

- (void)dealloc
{
  free(_glyphs);
  free(_advances);
  free(_positions);
  [_attributes release];
  [super dealloc];
}

- (CFIndex)glyphCount
{
  return _count;
}

- (NSDictionary*)attributes
{
  return _attributes;
}

- (CTRunStatus)status
{
  return _status;
}

- (const CGGlyph *)glyphs
{
  return _glyphs;
}
- (const CGPoint *)positions
{
  return _positions;
}
- (const CGSize *)advances
{
  return _advances;
}
- (const CFIndex *)stringIndices
{
  return _stringIndices;
}
- (CFRange)stringRange
{
  return _stringRange;
}
- (double)typographicBoundsForRange: (CFRange)range
			     ascent: (CGFloat*)ascent
			    descent: (CGFloat*)descent
			    leading: (CGFloat*)leading
{
  return 0;
}
- (CGRect)imageBoundsForRange: (CFRange)range
		  withContext: (CGContextRef)context
{
  return CGRectMake(0,0,0,0);
}

- (CGAffineTransform)matrix
{
  return _matrix;
}

- (void)drawRange: (CFRange)range onContext: (CGContextRef)ctx
{
  if (range.length == 0)
  {
    range.length = _count;
  }

  if (range.location > _count || (range.location + range.length) > _count)
  {
    NSLog(@"CTRunDraw range out of bounds"); 
    return;
  }

  CGContextShowGlyphsAtPositions(ctx, _glyphs + range.location, _positions, range.length);
}

@end


/* Functions */
 
CFIndex CTRunGetGlyphCount(CTRunRef run)
{
  return [run glyphCount];
}

CFDictionaryRef CTRunGetAttributes(CTRunRef run)
{
  return [run attributes];
}

CTRunStatus CTRunGetStatus(CTRunRef run)
{
  return [run status];
}

const CGGlyph* CTRunGetGlyphsPtr(CTRunRef run)
{
  return [run glyphs];
}

void CTRunGetGlyphs(
	CTRunRef run,
	CFRange range,
	CGGlyph buffer[])
{
  memcpy(buffer, [run glyphs] + range.location, sizeof(CGGlyph) * range.length);
}

const CGPoint* CTRunGetPositionsPtr(CTRunRef run)
{
  return [run positions];
}

void CTRunGetPositions(
	CTRunRef run,
	CFRange range,
	CGPoint buffer[])
{
  memcpy(buffer, [run positions] + range.location, sizeof(CGPoint) * range.length);
}

const CGSize* CTRunGetAdvancesPtr(CTRunRef run)
{
  return [run advances];
}

void CTRunGetAdvances(
	CTRunRef run,
	CFRange range,
	CGSize buffer[])
{
   memcpy(buffer, [run advances] + range.location, sizeof(CGSize) * range.length);
}

const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run)
{
  return [run stringIndices];
}

void CTRunGetStringIndices(
	CTRunRef run,
	CFRange range,
	CFIndex buffer[])
{
  memcpy(buffer, [run stringIndices] + range.location, sizeof(CFIndex) * range.length);
}

CFRange CTRunGetStringRange(CTRunRef run)
{
  return [run stringRange];
}

double CTRunGetTypographicBounds(
	CTRunRef run,
	CFRange range,
	CGFloat *ascent,
	CGFloat *descent,
	CGFloat *leading)
{
  return [run typographicBoundsForRange: range
				 ascent: ascent
				descent: descent
				leading: leading];
}

CGRect CTRunGetImageBounds(
	CTRunRef run,
	CGContextRef context,
	CFRange range)
{
  return [run imageBoundsForRange: range
		      withContext: context];
}

CGAffineTransform CTRunGetTextMatrix(CTRunRef run)
{
  return [run matrix];
}

void CTRunDraw(
	CTRunRef run,
	CGContextRef ctx,
	CFRange range)
{
  [run drawRange: range onContext: ctx];
}

CFTypeID CTRunGetTypeID()
{
  return (CFTypeID)[CTRun class];
}

