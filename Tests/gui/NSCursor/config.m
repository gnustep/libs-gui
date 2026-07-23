/* Coverage for NSCursor object state that does not depend on the window server:
   a cursor created with a hot spot reports it, a nil image stays nil, and the
   mouse-entered and mouse-exited flags default to NO and round-trip.  Every
   assertion here matches AppKit (verified on a macOS runner) and passes on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSCursor.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCursor *c;

  c = AUTORELEASE([[NSCursor alloc] initWithImage: nil
                                          hotSpot: NSMakePoint(4, 9)]);

  PASS(c != nil, "a cursor with a nil image is created");
  PASS([c hotSpot].x == 4 && [c hotSpot].y == 9, "the hot spot round-trips");
  PASS([c image] == nil, "a nil image stays nil");

  PASS([c isSetOnMouseEntered] == NO, "default isSetOnMouseEntered is NO");
  PASS([c isSetOnMouseExited] == NO, "default isSetOnMouseExited is NO");

  [c setOnMouseEntered: YES];
  PASS([c isSetOnMouseEntered] == YES, "setOnMouseEntered: round-trips");
  [c setOnMouseExited: YES];
  PASS([c isSetOnMouseExited] == YES, "setOnMouseExited: round-trips");

  DESTROY(arp);
  return 0;
}
