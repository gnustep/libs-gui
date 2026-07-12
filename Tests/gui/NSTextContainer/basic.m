/* Coverage for NSTextContainer: the defaults, the container size and line
 * fragment padding, the width/height tracking flags,
 * isSimpleRectangularTextContainer and containsPoint:.  These are plain
 * object operations and need no backend.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSTextContainer.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("defaults")
    NSTextContainer	*t = AUTORELEASE([[NSTextContainer alloc] init]);
    NSSize		size = [t containerSize];

    PASS(EQ(size.width, 1e7) && EQ(size.height, 1e7),
      "the default container size is very large");
    PASS(EQ([t lineFragmentPadding], 5.0),
      "the default line fragment padding is 5");
    PASS([t widthTracksTextView] == NO,
      "a new container does not track the text view width");
    PASS([t heightTracksTextView] == NO,
      "a new container does not track the text view height");
    PASS([t layoutManager] == nil, "a new container has no layout manager");
    PASS([t textView] == nil, "a new container has no text view");
    PASS([t isSimpleRectangularTextContainer] == YES,
      "a plain container is simple and rectangular");
  END_SET("defaults")

  START_SET("container size")
    NSTextContainer	*t = AUTORELEASE([[NSTextContainer alloc]
      initWithContainerSize: NSMakeSize(100, 200)]);
    NSSize		size = [t containerSize];

    PASS(EQ(size.width, 100) && EQ(size.height, 200),
      "initWithContainerSize: stores the size");

    [t setContainerSize: NSMakeSize(50, 60)];
    size = [t containerSize];
    PASS(EQ(size.width, 50) && EQ(size.height, 60),
      "setContainerSize: round trips");
  END_SET("container size")

  START_SET("accessors round-trip")
    NSTextContainer	*t = AUTORELEASE([[NSTextContainer alloc] init]);

    [t setLineFragmentPadding: 3.0];
    PASS(EQ([t lineFragmentPadding], 3.0),
      "setLineFragmentPadding: round trips");

    [t setWidthTracksTextView: YES];
    PASS([t widthTracksTextView] == YES,
      "setWidthTracksTextView: round trips");

    [t setHeightTracksTextView: YES];
    PASS([t heightTracksTextView] == YES,
      "setHeightTracksTextView: round trips");
  END_SET("accessors round-trip")

  START_SET("containsPoint:")
    NSTextContainer	*t = AUTORELEASE([[NSTextContainer alloc]
      initWithContainerSize: NSMakeSize(100, 200)]);

    PASS([t containsPoint: NSMakePoint(10, 10)] == YES,
      "a point inside the container is contained");
    PASS([t containsPoint: NSMakePoint(150, 10)] == NO,
      "a point past the width is not contained");
    PASS([t containsPoint: NSMakePoint(100, 200)] == NO,
      "the far corner is not contained");
  END_SET("containsPoint:")

  DESTROY(arp);
  return 0;
}
