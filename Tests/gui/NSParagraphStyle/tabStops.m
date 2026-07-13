/* Tests the NSParagraphStyle tab stop handling that the coder test does not:
 * the default tab stops and interval, addTabStop: keeping
 * the stops in location order, removeTabStop:, and setDefaultTabInterval:.
 * These are plain value operations.
 */
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSText.h>

static BOOL
eq(CGFloat a, CGFloat b)
{
  return fabs((double)(a - b)) < 0.001;
}

static CGFloat
locAt(NSParagraphStyle *p, NSUInteger i)
{
  return [[[p tabStops] objectAtIndex: i] location];
}

static NSTextTab *
tab(CGFloat loc)
{
  return [[[NSTextTab alloc] initWithType: NSLeftTabStopType
                                 location: loc] autorelease];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSParagraphStyle tab stops")

  /* The default paragraph style has twelve tab stops every 28 points and a
   * zero default tab interval. */
  {
    NSParagraphStyle *d = [NSParagraphStyle defaultParagraphStyle];

    pass([[d tabStops] count] == 12, "the default style has twelve tab stops");
    pass(eq(locAt(d, 0), 28.0) && eq(locAt(d, 1), 56.0)
      && eq(locAt(d, 11), 336.0),
      "the default tab stops are spaced every 28 points");
    pass(eq([d defaultTabInterval], 0.0),
      "the default tab interval is zero");
  }

  /* addTabStop: keeps the stops in location order wherever the new stop
   * belongs. */
  {
    NSMutableParagraphStyle *p = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);

    [p setTabStops: [NSArray arrayWithObjects: tab(100), tab(200), tab(300), nil]];

    [p addTabStop: tab(150)];
    pass(eq(locAt(p, 0), 100.0) && eq(locAt(p, 1), 150.0)
      && eq(locAt(p, 2), 200.0) && eq(locAt(p, 3), 300.0),
      "addTabStop: inserts a stop in the middle in order");

    [p addTabStop: tab(50)];
    pass(eq(locAt(p, 0), 50.0), "addTabStop: places an earlier stop first");

    [p addTabStop: tab(400)];
    pass(eq(locAt(p, [[p tabStops] count] - 1), 400.0)
      && [[p tabStops] count] == 6,
      "addTabStop: places a later stop last");
  }

  /* removeTabStop: removes the matching stop. */
  {
    NSMutableParagraphStyle *p = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
    NSTextTab *mid;

    [p setTabStops: [NSArray arrayWithObjects:
      tab(50), tab(100), tab(200), tab(300), nil]];
    mid = [[p tabStops] objectAtIndex: 2];      /* the 200 stop */
    [p removeTabStop: mid];
    pass([[p tabStops] count] == 3
      && eq(locAt(p, 0), 50.0) && eq(locAt(p, 1), 100.0)
      && eq(locAt(p, 2), 300.0),
      "removeTabStop: removes the stop and leaves the rest in order");
  }

  /* setDefaultTabInterval: stores the interval. */
  {
    NSMutableParagraphStyle *p = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);

    [p setDefaultTabInterval: 36.0];
    pass(eq([p defaultTabInterval], 36.0),
      "setDefaultTabInterval: stores the interval");
  }

  END_SET("NSParagraphStyle tab stops")

  DESTROY(arp);
  return 0;
}
