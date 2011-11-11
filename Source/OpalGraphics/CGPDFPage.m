/** <title>CGPDFPage</title>
 
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

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGPDFPage.h"

CGPDFDocumentRef CGPDFPageGetDocument(CGPDFPageRef page)
{
  return nil;
}

size_t CGPDFPageGetPageNumber(CGPDFPageRef page)
{
  return 0;
}

CGRect CGPDFPageGetBoxRect(CGPDFPageRef page, CGPDFBox box)
{
  return CGRectNull;
}

int CGPDFPageGetRotationAngle(CGPDFPageRef page)
{
  return 0;
}

CGAffineTransform CGPDFPageGetDrawingTransform(
  CGPDFPageRef page,
  CGPDFBox box,
  CGRect rect,
  int rotate,
  bool preserveAspectRatio)
{
  return CGAffineTransformIdentity;
}

CGPDFDictionaryRef CGPDFPageGetDictionary(CGPDFPageRef page)
{
  return nil;
}

CFTypeID CGPDFPageGetTypeID(void)
{
  return (CFTypeID)nil;
}

CGPDFPageRef CGPDFPageRetain(CGPDFPageRef page)
{
  return nil;  
}

void CGPDFPageRelease(CGPDFPageRef page)
{
  
}
