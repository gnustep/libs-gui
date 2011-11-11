/** <title>OPFreeTypeUtil</title>

   <abstract>Utility functions for FreeType</abstract>

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

#import "CoreGraphics/CoreGraphics.h"

#include <ft2build.h>
#include FT_FREETYPE_H


static inline CGFloat CGFloatFromFT_Fixed(FT_Fixed f)
{
  //FT_Fixed is Q16.16
  return (f/65536.0);
}

static inline FT_Fixed FT_FixedFromCGFloat(CGFloat f)
{
  return (FT_Fixed)((f * 65536.0) + 0.5);

}

static inline CGFloat CGFloatFromFontUnits(NSInteger units, CGFloat pointSize, NSUInteger unitsPerEm)
{
  return (((CGFloat)units * pointSize) / (CGFloat)unitsPerEm);
}

static inline FT_Matrix FT_MatrixFromCGAffineTransform(CGAffineTransform transform)
{
  FT_Matrix theMatrix = {FT_FixedFromCGFloat(transform.a),
    FT_FixedFromCGFloat(transform.b),
    FT_FixedFromCGFloat(transform.c),
    FT_FixedFromCGFloat(transform.d)};
  return theMatrix;
}

/**
 * Creates a Q16.16 fixed point translation vector from an affine transform.
 */
static inline FT_Vector FT_VectorQ1616FromCGAffineTransform(CGAffineTransform transform)
{
  FT_Vector theVector = {FT_FixedFromCGFloat(transform.tx), FT_FixedFromCGFloat(transform.ty)};
  return theVector;
}
