/** <title>CGPDFPage</title>

   <abstract>C Interface to graphics drawing library
             - geometry routines</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.
   Author: Eric Wasylishen <ewasylishen@gmail.com>
    
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

#ifndef OPAL_CGPDFPage_h
#define OPAL_CGPDFPage_h

/* Data Types */

#ifdef __OBJC__
@class CGPDFPage;
typedef CGPDFPage* CGPDFPageRef;
#else
typedef struct CGPDFPage* CGPDFPageRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFDocument.h>
#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGPDFDictionary.h>

/* Constants */

typedef enum CGPDFBox {
  kCGPDFMediaBox = 0,
  kCGPDFCropBox = 1,
  kCGPDFBleedBox = 2,
  kCGPDFTrimBox = 3,
  kCGPDFArtBox = 4
} CGPDFBox;

/* Functions */

CGPDFDocumentRef CGPDFPageGetDocument(CGPDFPageRef page);

size_t CGPDFPageGetPageNumber(CGPDFPageRef page);

CGRect CGPDFPageGetBoxRect(CGPDFPageRef page, CGPDFBox box);

int CGPDFPageGetRotationAngle(CGPDFPageRef page);

CGAffineTransform CGPDFPageGetDrawingTransform(
  CGPDFPageRef page,
  CGPDFBox box,
  CGRect rect,
  int rotate,
  bool preserveAspectRatio
);

CGPDFDictionaryRef CGPDFPageGetDictionary(CGPDFPageRef page);

CFTypeID CGPDFPageGetTypeID(void);

CGPDFPageRef CGPDFPageRetain(CGPDFPageRef page);

void CGPDFPageRelease(CGPDFPageRef page);

#endif /* OPAL_CGPDFPage_h */