/** <title>CGPDFObject</title>

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

#ifndef OPAL_CGPDFObject_h
#define OPAL_CGPDFObject_h

#include <CoreGraphics/CGBase.h>

/* Data Types */

typedef unsigned char CGPDFBoolean;

typedef long int CGPDFInteger;

typedef CGFloat CGPDFReal;

#ifdef __OBJC__
@class CGPDFObject;
typedef CGPDFObject* CGPDFObjectRef;
#else
typedef struct CGPDFObject* CGPDFObjectRef;
#endif

/* Constants */

typedef enum CGPDFObjectType {
  kCGPDFObjectTypeNull = 1,
  kCGPDFObjectTypeBoolean = 2,
  kCGPDFObjectTypeInteger = 3,
  kCGPDFObjectTypeReal = 4,
  kCGPDFObjectTypeName = 5,
  kCGPDFObjectTypeString = 6,
  kCGPDFObjectTypeArray = 7,
  kCGPDFObjectTypeDictionary = 8,
  kCGPDFObjectTypeStream = 9
} CGPDFObjectType;

/* Functions */

CGPDFObjectType CGPDFObjectGetType(CGPDFObjectRef object);

bool CGPDFObjectGetValue(CGPDFObjectRef object, CGPDFObjectType type, void *value);

#endif /* OPAL_CGPDFDictionary_h */