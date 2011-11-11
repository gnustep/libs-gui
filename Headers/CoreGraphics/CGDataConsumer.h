/** <title>CGDataConsumer</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   
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

#ifndef OPAL_CGDataConsumer_h
#define OPAL_CGDataConsumer_h

/* Data Types */

#ifdef __OBJC__
@class CGDataConsumer;
typedef CGDataConsumer* CGDataConsumerRef;
#else
typedef struct CGDataConsumer* CGDataConsumerRef;
#endif

#include <CoreGraphics/CGBase.h>

/* Callbacks */

typedef size_t (*CGDataConsumerPutBytesCallback)(
  void *info,
  const void *buffer,
  size_t count
);

typedef void (*CGDataConsumerReleaseInfoCallback)(void *info);

typedef struct CGDataConsumerCallbacks
{
  CGDataConsumerPutBytesCallback putBytes;
  CGDataConsumerReleaseInfoCallback releaseConsumer;
} CGDataConsumerCallbacks;

/* Functions */

CGDataConsumerRef CGDataConsumerCreate(
  void *info,
  const CGDataConsumerCallbacks *callbacks
);

CGDataConsumerRef CGDataConsumerCreateWithCFData(CFMutableDataRef data);

CGDataConsumerRef CGDataConsumerCreateWithURL(CFURLRef url);

CFTypeID CGDataConsumerGetTypeID();

void CGDataConsumerRelease(CGDataConsumerRef consumer);

CGDataConsumerRef CGDataConsumerRetain(CGDataConsumerRef consumer);

#endif /* OPAL_CGDataConsumer_h */
