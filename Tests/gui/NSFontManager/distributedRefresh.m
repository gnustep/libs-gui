#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDistributedNotificationCenter.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFontManager.h>

@interface RefreshObserver : NSObject
{
@public
  BOOL refreshed;
}
- (void) fontsDidChange: (NSNotification *)notification;
@end

@implementation RefreshObserver
- (void) fontsDidChange: (NSNotification *)notification
{
  refreshed = YES;
}
@end

int
main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  RefreshObserver *observer = [RefreshObserver new];
  NSFontManager *fm = nil;
  NSDate *limit;

  START_SET("font manager follows distributed font changes")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like the GNUstep backend is not available")
  NS_ENDHANDLER

  NS_DURING
    fm = [NSFontManager sharedFontManager];
  NS_HANDLER
    SKIP("No font backend available for the font manager")
  NS_ENDHANDLER

  [[NSNotificationCenter defaultCenter]
    addObserver: observer
       selector: @selector(fontsDidChange:)
           name: GSFontManagerAvailableFontsDidChangeNotification
         object: fm];

  [[NSDistributedNotificationCenter defaultCenter]
    postNotificationName: GSFontManagerAvailableFontsDidChangeNotification
                  object: nil
                userInfo: nil
      deliverImmediately: YES];

  limit = [NSDate dateWithTimeIntervalSinceNow: 5.0];
  while (observer->refreshed == NO && [limit timeIntervalSinceNow] > 0)
    {
      [[NSRunLoop currentRunLoop]
        runMode: NSDefaultRunLoopMode
        beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
    }

  PASS(observer->refreshed == YES,
    "a distributed font change notification refreshes the font manager");

  END_SET("font manager follows distributed font changes")

  [[NSNotificationCenter defaultCenter] removeObserver: observer];
  [observer release];
  [pool release];
  return 0;
}
