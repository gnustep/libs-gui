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

/* GSRingBuffer.m */

#import "GSRingBuffer.h"

@implementation GSRingBuffer

- (id)initWithCapacity: (int)cap
{
  if (cap <= 0)
    return nil;

  self = [super init];
  if (self)
    {
      capacity = cap;
      head = 0;
      tail = 0;
      size = 0;

      data = (id *)calloc(capacity, sizeof(id));
      if (!data)
        {
          [self release];
          return nil;
        }
    }
  return self;
}

- (void)dealloc
{
  int i;
  for (i = 0; i < capacity; i++)
    {
      RELEASE(data[i]);
      data[i] = nil;
    }
  free(data);
  [super dealloc];
}

- (BOOL)isEmpty
{
  return size == 0;
}

- (BOOL)isFull
{
  return size == capacity;
}

- (BOOL)enqueue: (id)item
{
  if ([self isFull])
    return NO;

  data[tail] = RETAIN(item);
  tail = (tail + 1) % capacity;
  size++;
  return YES;
}

- (id)dequeue
{
  id item;
  if ([self isEmpty])
    return nil;

  item = data[head];
  data[head] = nil;
  head = (head + 1) % capacity;
  size--;
  return AUTORELEASE(item);
}

- (id)peek
{
  id obj = RETAIN(data[head]);
  
  if ([self isEmpty])
    return nil;
  
  return AUTORELEASE(obj);
}

@end
