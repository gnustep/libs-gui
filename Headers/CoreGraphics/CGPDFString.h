/** <title>CGPDFString</title>

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

#ifndef OPAL_CGPDFString_h
#define OPAL_CGPDFString_h

/* Data Types */

#ifdef __OBJC__
@class CGPDFString;
typedef CGPDFString* CGPDFStringRef;
#else
typedef struct CGPDFString* CGPDFStringRef;
#endif

#include <CoreGraphics/CGBase.h>

/* Functions */

size_t CGPDFStringGetLength(CGPDFStringRef string);

const unsigned char *CGPDFStringGetBytePtr(CGPDFStringRef string);

CFStringRef CGPDFStringCopyTextString(CGPDFStringRef string);

CFDateRef CGPDFStringCopyDate(CGPDFStringRef string);

#endif /* OPAL_CGPDFString_h */
