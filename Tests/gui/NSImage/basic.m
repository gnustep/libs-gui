#import "ObjectTesting.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  id testObject;
  id testObject1;
  id testObject2;
  NSArray *testObjects;

  [NSApplication sharedApplication];  

  test_alloc(@"NSImage");

  testObject = [NSImage new];
  testObject1 = [NSImage imageNamed: @"GNUstep"];
  testObject2 = [[NSImage alloc] initWithData: nil];

  testObjects = [NSArray arrayWithObjects: testObject, testObject1, testObject2, nil];
  RELEASE(testObject);

  test_NSObject(@"NSImage", testObjects);
  test_NSCoding(testObjects);
  test_keyed_NSCoding(testObjects);
  test_NSCopying(@"NSImage",
                 @"NSImage",
		 testObjects, NO, NO);

  [arp release];
  return 0;
}

@implementation NSImage (Testing)

- (BOOL) isEqual: (id)anObject
{
  if (self == anObject)
    return YES;
  if (![anObject isKindOfClass: [NSImage class]])
    return NO;
  if (![[anObject backgroundColor] isEqual: [self backgroundColor]])
    return NO;
  if ([anObject isFlipped] != [self isFlipped])
    return NO;
  if (!NSEqualSizes([anObject size], [self size]))
    return NO;

  // FIXME
  return YES;
}

@end
