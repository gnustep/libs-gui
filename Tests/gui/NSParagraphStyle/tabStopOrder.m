/* -[NSMutableParagraphStyle setTabStops:] keeps the tab stops in the order
   given, as OS X does; it does not reorder them.  (-addTabStop: still
   inserts a single stop in sorted position.) */
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSText.h>

static CGFloat
locAt(NSParagraphStyle *p, NSUInteger i)
{
  return [[[p tabStops] objectAtIndex: i] location];
}

static NSTextTab *
tab(CGFloat loc)
{
  return AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
                                            location: loc]);
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSParagraphStyle tab stop order")

  {
    NSMutableParagraphStyle *p = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);

    [p setTabStops: [NSArray arrayWithObjects: tab(300), tab(100), tab(200), nil]];
    PASS([[p tabStops] count] == 3, "setTabStops: keeps all of the stops");
    PASS(locAt(p, 0) == 300.0 && locAt(p, 1) == 100.0 && locAt(p, 2) == 200.0,
      "setTabStops: keeps the stops in the order given");
  }

  END_SET("NSParagraphStyle tab stop order")

  DESTROY(arp);
  return 0;
}
