/** <title>CGDataProvider</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010
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

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGDataProvider.h"

/**
 * These functions provide access to the data in a CGDataProvider.
 * Sequential or Direct Access functions can be used regardless of the
 * internal type of the data provider.
 */

/* Sequential Access */

size_t OPDataProviderGetBytes(CGDataProviderRef dp, void *buffer, size_t count);

off_t OPDataProviderSkipForward(CGDataProviderRef dp, off_t count);

void OPDataProviderRewind(CGDataProviderRef dp);

/* Direct Access */

size_t OPDataProviderGetSize(CGDataProviderRef dp);

const void *OPDataProviderGetBytePointer(CGDataProviderRef dp);

void OPDataProviderReleaseBytePointer(
  CGDataProviderRef dp,
  const void *pointer
);

size_t OPDataProviderGetBytesAtPosition(
  CGDataProviderRef dp, 
  void *buffer,
  off_t position,
  size_t count
);