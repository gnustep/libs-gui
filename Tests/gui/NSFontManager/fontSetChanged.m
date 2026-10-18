#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFontManager.h>

@interface SetObserver : NSObject
{
@public
  int count;
  id sender;
}
- (void) fontSetChanged: (NSNotification *)notification;
@end

@implementation SetObserver
- (void) fontSetChanged: (NSNotification *)notification
{
  count++;
  sender = [notification object];
}
@end

int
main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  SetObserver *observer = [SetObserver new];
  NSFontManager *fm = nil;

  START_SET("NSFontSetChangedNotification")

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

  PASS([NSFontSetChangedNotification isEqualToString: @"NSFontSetChangedNotification"],
    "the notification has the name Cocoa uses");

  [[NSNotificationCenter defaultCenter]
    addObserver: observer
       selector: @selector(fontSetChanged:)
           name: NSFontSetChangedNotification
         object: nil];

  [fm refreshAvailableFonts];

  PASS(observer->count == 1,
    "refreshing the available fonts posts NSFontSetChangedNotification");
  PASS(observer->sender == fm,
    "the font manager is the object of the notification");

  END_SET("NSFontSetChangedNotification")

  [[NSNotificationCenter defaultCenter] removeObserver: observer];
  [observer release];
  [pool release];
  return 0;
}
