/* A demonstration of writing and reading with NSArchiver */

#include <objects/objects.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSAutoreleasePool.h>

@interface TestClass : NSObject
{
  id next_responder;
}

- (void)setNextResponder: anObject;
- nextResponder;
@end

@implementation TestClass

- (void)setNextResponder: anObject
{
  next_responder = anObject;
}

- nextResponder
{
  return next_responder;
}

// NSCoding protocol
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObjectReference:next_responder withName:@"Next Responder"];
}

- initWithCoder:aDecoder
{
  id d;
  [super initWithCoder:aDecoder];
  [aDecoder decodeObjectAt:&next_responder withName:&d];
  return self;
}
@end

////////////////////////////////////////

int main()
{
  id arp;
  id r1, r2;
  
  arp = [[NSAutoreleasePool alloc] init];

  // Create a simple loop
  r1 = [[TestClass alloc] init];
  r2 = [[TestClass alloc] init];
  [r1 setNextResponder: r2];
  [r2 setNextResponder: r1];

  printf("Writing\n");
  printf("%d\n", [r1 hash]);
  printf("%d\n", [r2 hash]);
  printf("%d\n", [[r1 nextResponder] hash]);
  printf("%d\n", [[r2 nextResponder] hash]);

  //[Coder setDefaultCStreamClass: [TextCStream class]];

  /* Write it to a file */
  {
    id d = [[NSMutableData alloc] init];
    id a = [[NSArchiver alloc] initForWritingWithMutableData: d];

    [a startEncodingInterconnectedObjects];
    [a encodeRootObject: r1 withName:@"one"];
    [a encodeObject: r2 withName:@"another"];
    [a finishEncodingInterconnectedObjects];

    [d writeToFile: @"./nsarchiver.dat" atomically:NO];

    [d release];
    [a release];
  }

  /* Release the object that was coded */
  [r1 release];
  [r2 release];

  /* Read it back in from the file */
  printf("\nReading:\n");
  {
    id d = [[NSData alloc] initWithContentsOfFile: @"./nsarchiver.dat"];
    id a = [[NSUnarchiver alloc] initForReadingWithData: d];

    [a startDecodingInterconnectedObjects];
    [a decodeObjectAt: &r1 withName:&d];
    [a decodeObjectAt: &r2 withName:&d];
    [a finishDecodingInterconnectedObjects];
  }

  /* Display what we read, to make sure it matches what we wrote */
  {
    printf("%d\n", [r1 hash]);
    printf("%d\n", [r2 hash]);
    printf("%d\n", [[r1 nextResponder] hash]);
    printf("%d\n", [[r2 nextResponder] hash]);
  }

  /* Do the autorelease. */
  [arp release];
  
  exit(0);
}
