/** <title>CGPDFContentStream</title>

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

#ifndef OPAL_CGPDFContentStream_h
#define OPAL_CGPDFContentStream_h

/* Data Types */

#ifdef __OBJC__
@class CGPDFContentStream;
typedef CGPDFContentStream* CGPDFContentStreamRef;
#else
typedef struct CGPDFContentStream* CGPDFContentStreamRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFPage.h>
#include <CoreGraphics/CGPDFStream.h>
#include <CoreGraphics/CGPDFDictionary.h>

/* Functions */

CGPDFContentStreamRef CGPDFContentStreamCreateWithPage(CGPDFPageRef page);

CGPDFContentStreamRef CGPDFContentStreamCreateWithStream(
  CGPDFStreamRef stream,
  CGPDFDictionaryRef streamResources,
  CGPDFContentStreamRef parent
);

CGPDFObjectRef CGPDFContentStreamGetResource(
  CGPDFContentStreamRef stream,
  const char *category,
  const char *name
);

CFArrayRef CGPDFContentStreamGetStreams(CGPDFContentStreamRef stream);

CGPDFContentStreamRef CGPDFContentStreamRetain(CGPDFContentStreamRef stream);

void CGPDFContentStreamRelease(CGPDFContentStreamRef stream);

#endif /* OPAL_CGPDFContentStream_h */
