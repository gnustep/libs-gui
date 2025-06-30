/* GSRingBuffer.m - Ring buffer implementation in Objective-C 1.0 for GNUstep */

#import <Foundation/Foundation.h>

@interface GSRingBuffer : NSObject
{
  id *data;
  int capacity;
  int head;
  int tail;
  int size;
}

- (id)initWithCapacity:(int)cap;
- (void)dealloc;
- (BOOL)isEmpty;
- (BOOL)isFull;
- (BOOL)enqueue:(id)item;
- (id)dequeue;
- (id)peek;

@end
