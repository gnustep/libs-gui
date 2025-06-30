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
