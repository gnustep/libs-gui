/** <title>GSRingBuffer</title>

   <abstract>Ring buffer implementation</abstract>

   Copyright <copy>(C) 2025 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: May 2025

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

/* GSRingBuffer.m - Ring buffer implementation in Objective-C 1.0 for GNUstep */

#ifndef _GNUstep_H_GSRingBuffer
#define _GNUstep_H_GSRingBuffer

#import <Foundation/NSObject.h>
#import "AppKit/AppKitDefines.h"

APPKIT_EXPORT_CLASS
@interface GSRingBuffer : NSObject
{
  id *data;
  int capacity;
  int head;
  int tail;
  int size;
}

- (id)initWithCapacity: (int)cap;
- (void)dealloc;
- (BOOL)isEmpty;
- (BOOL)isFull;
- (BOOL)enqueue: (id)item;
- (id)dequeue;
- (id)peek;

@end

#endif
