#import "ObjectTesting.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSFileManager.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSArray **testObjects;
  BOOL success = NO;
  NSFileManager *mgr = [NSFileManager defaultManager];
  NSString *path = [mgr currentDirectoryPath];
  NSBundle *bundle = [[NSBundle alloc] initWithPath: path];

  START_SET("NSNibLoading GNUstep basic")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
       SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER;

  if ([[path lastPathComponent] isEqualToString: @"obj"])
    {
      path = [path stringByDeletingLastPathComponent];
    }
  
  pass(bundle != NO, "NSBundle was initialized");
  
  success = [bundle loadNibNamed: @"Test-gorm"
                           owner: [NSApplication sharedApplication]
                 topLevelObjects: testObjects];
  
  pass(success == YES, ".gorm file was loaded properly using loadNibNamed:owner:topLevelObjects:");
  NSLog(@"%@", *testObjects);
  
  END_SET("NSNibLoading GNUstep basic")

  [arp release];
  return 0;
}
