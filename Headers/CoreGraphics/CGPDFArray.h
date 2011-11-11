/** <title>CGPDFArray</title>

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

#ifndef OPAL_CGPDFArray_h
#define OPAL_CGPDFArray_h

/* Data Types */

#ifdef __OBJC__
@class CGPDFArray;
typedef CGPDFArray* CGPDFArrayRef;
#else
typedef struct CGPDFArray* CGPDFArrayRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFObject.h>
#include <CoreGraphics/CGPDFString.h>
#include <CoreGraphics/CGPDFDictionary.h>
#include <CoreGraphics/CGPDFStream.h>

/* Functions */

bool CGPDFArrayGetArray(CGPDFArrayRef array, size_t index, CGPDFArrayRef *value);

bool CGPDFArrayGetBoolean(CGPDFArrayRef array, size_t index, CGPDFBoolean *value);

size_t CGPDFArrayGetCount(CGPDFArrayRef array);

bool CGPDFArrayGetDictionary(CGPDFArrayRef array, size_t index, CGPDFDictionaryRef *value);

bool CGPDFArrayGetInteger(CGPDFArrayRef array, size_t index, CGPDFInteger *value);

bool CGPDFArrayGetName(CGPDFArrayRef array, size_t index, const char **value);

bool CGPDFArrayGetNull(CGPDFArrayRef array, size_t index);

bool CGPDFArrayGetNumber(CGPDFArrayRef array, size_t index, CGPDFReal *value);

bool CGPDFArrayGetObject(CGPDFArrayRef array, size_t index, CGPDFObjectRef *value);

bool CGPDFArrayGetStream(CGPDFArrayRef array, size_t index, CGPDFStreamRef *value);

bool CGPDFArrayGetString(CGPDFArrayRef array, size_t index, CGPDFStringRef *value);

#endif /* OPAL_CGPDFArray_h */