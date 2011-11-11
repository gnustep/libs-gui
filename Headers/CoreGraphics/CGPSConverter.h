/** <title>CGPSConverter</title>

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

#ifndef OPAL_CGPSConverter_h
#define OPAL_CGPSConverter_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGDataProvider.h>
#include <CoreGraphics/CGDataConsumer.h>

/* Callbacks */

typedef void (*CGPSConverterBeginDocumentCallback)(void *info);

typedef void (*CGPSConverterEndDocumentCallback)(void *info, bool success);

typedef void (*CGPSConverterBeginPageCallback)(
  void *info,
  size_t pageNumber,
  CFDictionaryRef pageInfo
);

typedef void (*CGPSConverterEndPageCallback)(
  void *info,
  size_t pageNumber,
  CFDictionaryRef pageInfo
);

typedef void (*CGPSConverterProgressCallback)(void *info);

typedef void (*CGPSConverterMessageCallback)(void *info, CFStringRef msg);

typedef void (*CGPSConverterReleaseInfoCallback)(void *info);

/* Data Types */

typedef struct CGPSConverterCallbacks {
    unsigned int version;
    CGPSConverterBeginDocumentCallback beginDocument;
    CGPSConverterEndDocumentCallback endDocument;
    CGPSConverterBeginPageCallback beginPage;
    CGPSConverterEndPageCallback endPage;
    CGPSConverterProgressCallback noteProgress;
    CGPSConverterMessageCallback noteMessage;
    CGPSConverterReleaseInfoCallback releaseInfo;
} CGPSConverterCallbacks;


#ifdef __OBJC__
@class CGPSConverter;
typedef CGPSConverter* CGPSConverterRef;
#else
typedef struct CGPSConverter* CGPSConverterRef;
#endif

/* Functions */

CGPSConverterRef CGPSConverterCreate(
  void *info,
  const CGPSConverterCallbacks *callbacks,
  CFDictionaryRef options
);

bool CGPSConverterConvert(
  CGPSConverterRef converter,
  CGDataProviderRef provider,
  CGDataConsumerRef consumer,
  CFDictionaryRef options
);

bool CGPSConverterAbort(CGPSConverterRef converter);

bool CGPSConverterIsConverting(CGPSConverterRef converter);

CFTypeID CGPSConverterGetTypeID();

#endif /* OPAL_CGPSConverter_h */
