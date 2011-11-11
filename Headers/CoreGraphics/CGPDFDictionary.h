/** <title>CGPDFDictionary</title>

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

#ifndef OPAL_CGPDFDictionary_h
#define OPAL_CGPDFDictionary_h

/* Data Types */

#ifdef __OBJC__
@class CGPDFDictionary;
typedef CGPDFDictionary* CGPDFDictionaryRef;
#else
typedef struct CGPDFDictionary* CGPDFDictionaryRef;
#endif

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFObject.h>
#include <CoreGraphics/CGPDFArray.h>
#include <CoreGraphics/CGPDFStream.h>

/* Callbacks */

typedef void (*CGPDFDictionaryApplierFunction)(
  const char *key,
  CGPDFObjectRef value,
  void *info
);

/* Functions */

void CGPDFDictionaryApplyFunction(CGPDFDictionaryRef dict, CGPDFDictionaryApplierFunction function, void *info);

size_t CGPDFDictionaryGetCount(CGPDFDictionaryRef dict);

bool CGPDFDictionaryGetArray(CGPDFDictionaryRef dict, const char *key, CGPDFArrayRef *value);

bool CGPDFDictionaryGetBoolean(CGPDFDictionaryRef dict, const char *key, CGPDFBoolean *value);

bool CGPDFDictionaryGetDictionary(CGPDFDictionaryRef dict, const char *key, CGPDFDictionaryRef *value);

bool CGPDFDictionaryGetInteger(CGPDFDictionaryRef dict, const char *key, CGPDFInteger *value);

bool CGPDFDictionaryGetName(CGPDFDictionaryRef dict, const char *key, const char **value);

bool CGPDFDictionaryGetNumber(CGPDFDictionaryRef dict, const char *key, CGPDFReal *value);

bool CGPDFDictionaryGetObject(CGPDFDictionaryRef dict, const char *key, CGPDFObjectRef *value);

bool CGPDFDictionaryGetStream(CGPDFDictionaryRef dict, const char *key, CGPDFStreamRef *value);

bool CGPDFDictionaryGetString(CGPDFDictionaryRef dict, const char *key, CGPDFStringRef *value);

#endif /* OPAL_CGPDFDictionary_h */