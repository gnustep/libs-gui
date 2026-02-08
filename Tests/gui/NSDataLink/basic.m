#import "ObjectTesting.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <AppKit/NSDataLink.h>
#import <AppKit/NSSelection.h>
#import <AppKit/NSPasteboard.h>

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  id testObject;
  id testObject1;
  id testObject2;
  NSArray *testObjects;

  START_SET("NSDataLink GNUstep basic")

  test_alloc(@"NSDataLink");

  // Test basic allocation
  testObject = [NSDataLink new];
  
  // Test init with file
  testObject1 = [[NSDataLink alloc] initLinkedToFile: @"testfile.txt"];
  
  // Test init with selection
  NSSelection *sel = [NSSelection selectionWithDescriptionData: [@"test data" dataUsingEncoding: NSUTF8StringEncoding]];
  NSArray *types = [NSArray arrayWithObject: @"NSStringPboardType"];
  testObject2 = [[NSDataLink alloc] initLinkedToSourceSelection: sel
							managedBy: nil
						  supportingTypes: types];

  testObjects = [NSArray arrayWithObjects: testObject, testObject1, testObject2, nil];
  RELEASE(testObject);
  RELEASE(testObject1);
  RELEASE(testObject2);

  test_NSObject(@"NSDataLink", testObjects);
  test_NSCoding(testObjects);
  test_keyed_NSCoding(testObjects);

  // Test additional methods
  testObject = [NSDataLink new];
  PASS([testObject disposition] == NSLinkInDestination, "Default disposition is NSLinkInDestination");
  PASS([testObject updateMode] == NSUpdateContinuously, "Default update mode is NSUpdateContinuously");
  
  // Test break
  PASS([testObject break] == YES, "break method returns YES");
  
  // Test setUpdateMode
  [testObject setUpdateMode: NSUpdateManually];
  PASS([testObject updateMode] == NSUpdateManually, "setUpdateMode works");
  
  // Test noteSourceEdited
  [testObject noteSourceEdited]; // Should not crash
  
  // Test pasteboard operations
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: @"test link"];
  [testObject writeToPasteboard: pb];
  NSDataLink *restored = [[NSDataLink alloc] initWithPasteboard: pb];
  PASS(restored != nil, "Can create link from pasteboard");
  RELEASE(restored);
  
  RELEASE(testObject);

  END_SET("NSDataLink GNUstep basic")

  [arp release];
  return 0;
}

@implementation NSDataLink (Testing)

- (BOOL) isEqual: (id)anObject
{
  if (self == anObject)
    return YES;
  if (![anObject isKindOfClass: [NSDataLink class]])
    return NO;
  
  // Compare basic properties
  if ([self linkNumber] != [anObject linkNumber])
    return NO;
  if ([self disposition] != [anObject disposition])
    return NO;
  if ([self updateMode] != [anObject updateMode])
    return NO;
  
  // Compare strings
  if (![[self sourceApplicationName] isEqual: [anObject sourceApplicationName]])
    return NO;
  if (![[self sourceFilename] isEqual: [anObject sourceFilename]])
    return NO;
  if (![[self destinationApplicationName] isEqual: [anObject destinationApplicationName]])
    return NO;
  if (![[self destinationFilename] isEqual: [anObject destinationFilename]])
    return NO;
  
  // Compare selections (basic check)
  if ([self sourceSelection] != [anObject sourceSelection] &&
      ![[self sourceSelection] isEqual: [anObject sourceSelection]])
    return NO;
  if ([self destinationSelection] != [anObject destinationSelection] &&
      ![[self destinationSelection] isEqual: [anObject destinationSelection]])
    return NO;
  
  return YES;
}

@end