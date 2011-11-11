/** <title>CGImageDestination</title>

   <abstract>C Interface to graphics drawing library</abstract>

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
   
#ifndef OPAL_CGImageDestination_h
#define OPAL_CGImageDestination_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGDataConsumer.h>

/* Constants */

extern const CFStringRef kCGImageDestinationLossyCompressionQuality;
extern const CFStringRef kCGImageDestinationBackgroundColor;

/* Data Types */

#ifdef __OBJC__
@class CGImageDestination;
typedef CGImageDestination* CGImageDestinationRef;
#else
typedef struct CGImageDestination* CGImageDestinationRef;
#endif

#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGImageSource.h>

/* Functions */

/* Creating */

CGImageDestinationRef CGImageDestinationCreateWithData(
  CFMutableDataRef data,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts
);

CGImageDestinationRef CGImageDestinationCreateWithDataConsumer(
  CGDataConsumerRef consumer,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts
);

CGImageDestinationRef CGImageDestinationCreateWithURL(
  CFURLRef url,
  CFStringRef type,
  size_t count,
  CFDictionaryRef opts
);

/* Getting Supported Image Types */

CFArrayRef CGImageDestinationCopyTypeIdentifiers();

/* Setting Properties */

void CGImageDestinationSetProperties(
  CGImageDestinationRef dest,
  CFDictionaryRef properties
);

/* Adding Images */

void CGImageDestinationAddImage(
  CGImageDestinationRef dest,
  CGImageRef image,
  CFDictionaryRef properties
);

void CGImageDestinationAddImageFromSource(
  CGImageDestinationRef dest,
  CGImageSourceRef source,
  size_t index,
  CFDictionaryRef properties
);

bool CGImageDestinationFinalize(CGImageDestinationRef dest);

CFTypeID CGImageDestinationGetTypeID();

#endif /* OPAL_CGImageDestination_h */
