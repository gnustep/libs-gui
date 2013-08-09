#import "ObjectTesting.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSImage.h>

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  id testObject;
  id testObject1;
  id testObject2;
  NSArray *testObjects;

  [NSApplication sharedApplication];  

  test_alloc(@"NSCell");

  testObject = [NSCell new];
  testObject1 = [[NSCell alloc] initImageCell: [NSImage imageNamed: @"GNUstep"]];
  testObject2 = [[NSCell alloc] initTextCell: @"GNUstep"];

  testObjects = [NSArray arrayWithObjects: testObject, testObject1, testObject2, nil];
  test_NSObject(@"NSCell", testObjects);
  test_NSCoding(testObjects);
  test_keyed_NSCoding(testObjects);
  test_NSCopying(@"NSCell",
                 @"NSCell",
		 testObjects, NO, NO);

  [arp release];
  return 0;
}

@implementation NSCell (Testing)

- (BOOL) isEqual: (id)anObject
{
  if (self == anObject)
    return YES;
  if (![anObject isKindOfClass: [NSCell class]])
    return NO;
  if (![[anObject stringValue] isEqual: [self stringValue]])
    return NO;
  if (![[anObject title] isEqual: [self title]])
    return NO;
  if (!([anObject image] == [self image]) && ![[anObject image] isEqual: [self image]])
    {
      NSLog(@"image differ %@ %@", [self image], [anObject image]);
      return NO;
    }
  if ([anObject type] != [self type])
    return NO;
  if ([anObject tag] != [self tag])
    return NO;
  return YES;
}

@end
