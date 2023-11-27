#import "ObjectTesting.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// For some nib/xibs the AppDelegate is defined...
@interface AppDelegate : NSObject 
{
  IBOutlet NSWindow *window;
}
@end

@implementation AppDelegate
@end


int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSArray **testObjects;
  BOOL success = NO;
  NSFileManager *mgr = [NSFileManager defaultManager];
  NSString *path = [mgr currentDirectoryPath];
  NSBundle *bundle = [[NSBundle alloc] initWithPath: path];

  START_SET("NSCollectionView GNUstep basic")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
       SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  if ([[path lastPathComponent] isEqualToString: @"obj"])
    {
      path = [path stringByDeletingLastPathComponent];
    }
  
  PASS(bundle != nil, "NSBundle was initialized");

  NS_DURING
    {
      success = [bundle loadNibNamed: @"MainMenu"
                               owner: [NSApplication sharedApplication]
                     topLevelObjects: testObjects];
      
      PASS(success == YES, ".xib file containing an NSCollectionView loads properly");      
    }
  NS_HANDLER
    {
      NSLog(@"%@", [localException reason]);
    }
  NS_ENDHANDLER
  
  END_SET("NSCollectionView GNUstep basic")

  [arp release];
  return 0;
}
