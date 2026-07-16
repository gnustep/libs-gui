/* NSLevelIndicatorCell answers -levelIndicatorStyle (AppKit's name for the
   style getter) and returns the style set with -setLevelIndicatorStyle:. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLevelIndicatorCell.h>

/* Declared so the test compiles whether or not the getter is present yet; the
   respondsToSelector: check is what actually verifies it. */
@interface NSLevelIndicatorCell (Compat)
- (NSLevelIndicatorStyle) levelIndicatorStyle;
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLevelIndicatorCell *cell;

  START_SET("NSLevelIndicatorCell levelIndicatorStyle")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  pass([cell respondsToSelector: @selector(levelIndicatorStyle)],
       "responds to -levelIndicatorStyle");
  if ([cell respondsToSelector: @selector(levelIndicatorStyle)])
    {
      [cell setLevelIndicatorStyle: NSContinuousCapacityLevelIndicatorStyle];
      pass([cell levelIndicatorStyle] == NSContinuousCapacityLevelIndicatorStyle,
           "-levelIndicatorStyle returns the style set with -setLevelIndicatorStyle:");
    }

  END_SET("NSLevelIndicatorCell levelIndicatorStyle")

  DESTROY(arp);
  return 0;
}
