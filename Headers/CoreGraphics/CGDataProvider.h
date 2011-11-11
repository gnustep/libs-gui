/** <title>CGDataProvider</title>

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

#ifndef OPAL_CGDataProvider_h
#define OPAL_CGDataProvider_h

/* Data Types */

#ifdef __OBJC__
@class CGDataProvider;
typedef CGDataProvider* CGDataProviderRef;
#else
typedef struct CGDataProvider* CGDataProviderRef;
#endif

#include <CoreGraphics/CGBase.h>

/* Callbacks */

/**
* Sequential data provider callbacks
*/

typedef size_t (*CGDataProviderGetBytesCallback)(
  void *info,
  void *buffer,
  size_t count
);

typedef void (*CGDataProviderSkipBytesCallback)(void *info, size_t count);

typedef off_t (*CGDataProviderSkipForwardCallback)(
  void *info,
  off_t count
);

typedef void (*CGDataProviderRewindCallback)(void *info);

typedef void (*CGDataProviderReleaseInfoCallback)(void *info);

/**
 * Direct access data provider callbacks
 */
 
typedef const void *(*CGDataProviderGetBytePointerCallback)(void *info);

typedef void (*CGDataProviderReleaseBytePointerCallback)(
  void *info,
  const void *pointer
);

typedef size_t (*CGDataProviderGetBytesAtOffsetCallback)(
  void *info,
  void *buffer,
  size_t offset,
  size_t count
);

typedef size_t (*CGDataProviderGetBytesAtPositionCallback)(
  void *info,
  void *buffer,
  off_t position,
  size_t count
);

/** 
 * Callback for CGDataProviderCreateWithData
 */

typedef void (*CGDataProviderReleaseDataCallback)(
  void *info,
  const void *data,
  size_t size
);

/* Data Types */

/**
 * Direct access callbacks structure
 */
typedef struct CGDataProviderDirectCallbacks
{
   unsigned int version;
   CGDataProviderGetBytePointerCallback getBytePointer;
   CGDataProviderReleaseBytePointerCallback releaseBytePointer;
   CGDataProviderGetBytesAtPositionCallback getBytesAtPosition;
   CGDataProviderReleaseInfoCallback releaseInfo;
} CGDataProviderDirectCallbacks;

/**
 * Deprecated direct access callbacks structure
 */
typedef struct CGDataProviderDirectAccessCallbacks
{
  CGDataProviderGetBytePointerCallback getBytePointer;
  CGDataProviderReleaseBytePointerCallback releaseBytePointer;
  CGDataProviderGetBytesAtOffsetCallback getBytes;
  CGDataProviderReleaseInfoCallback releaseProvider;
} CGDataProviderDirectAccessCallbacks;

/**
 * Sequential callbacks structure
 */
typedef struct CGDataProviderSequentialCallbacks
{
   unsigned int version;
   CGDataProviderGetBytesCallback getBytes;
   CGDataProviderSkipForwardCallback skipForward;
   CGDataProviderRewindCallback rewind;
   CGDataProviderReleaseInfoCallback releaseInfo;
} CGDataProviderSequentialCallbacks;

/**
 * Deprecated sequential callbacks structure
 */
typedef struct CGDataProviderCallbacks
{
  CGDataProviderGetBytesCallback getBytes;
  CGDataProviderSkipBytesCallback skipBytes;
  CGDataProviderRewindCallback rewind;
  CGDataProviderReleaseInfoCallback releaseProvider;
} CGDataProviderCallbacks;


/* Functions */

CGDataProviderRef CGDataProviderCreateDirect(
   void *info,
   off_t size,
   const CGDataProviderDirectCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateSequential(
   void *info,
   const CGDataProviderSequentialCallbacks *callbacks
);

/**
 * Deprecated
 */
CGDataProviderRef CGDataProviderCreateDirectAccess(
  void *info,
  size_t size,
  const CGDataProviderDirectAccessCallbacks *callbacks
);

/**
 * Deprecated
 */
CGDataProviderRef CGDataProviderCreate(
  void *info,
  const CGDataProviderCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  void (*releaseData)(void *info, const void *data, size_t size)
);

CGDataProviderRef CGDataProviderCreateWithCFData(CFDataRef data);

CGDataProviderRef CGDataProviderCreateWithURL(CFURLRef url);

CGDataProviderRef CGDataProviderCreateWithFilename(const char *filename);

CFDataRef CGDataProviderCopyData(CGDataProviderRef provider);

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider);

void CGDataProviderRelease(CGDataProviderRef provider);

CFTypeID CGDataProviderGetTypeID();

#endif /* OPAL_CGDataProvider_h */
