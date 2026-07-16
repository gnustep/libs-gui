/* Coverage for NSRulerMarker: the init defaults (markerLocation, imageOrigin,
   image, ruler, movable, removable, representedObject), the
   thicknessRequiredInRuler computation, the plain setter round-trips and the
   nil-argument exceptions.  Every assertion here matches AppKit (verified on a
   macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSScrollView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSScrollView *sv;
  NSRulerView *rv;
  NSImage *img;
  NSRulerMarker *m;
  BOOL raised;

  START_SET("NSRulerMarker basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  sv = AUTORELEASE([[NSScrollView alloc]
                     initWithFrame: NSMakeRect(0, 0, 200, 200)]);
  rv = AUTORELEASE([[NSRulerView alloc] initWithScrollView: sv
                                               orientation: NSHorizontalRuler]);
  img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(20, 16)]);

  /* init defaults */
  m = AUTORELEASE([[NSRulerMarker alloc] initWithRulerView: rv
                                            markerLocation: 100.0
                                                     image: img
                                               imageOrigin: NSMakePoint(3, 4)]);
  pass([m markerLocation] == 100.0, "markerLocation is the value passed in");
  pass([m imageOrigin].x == 3 && [m imageOrigin].y == 4,
       "imageOrigin is the point passed in");
  pass([m image] == img, "image is the image passed in");
  pass([m ruler] == rv, "ruler is the ruler view passed in");
  pass([m isMovable] == YES, "a marker is movable by default");
  pass([m isRemovable] == NO, "a marker is not removable by default");
  pass([m representedObject] == nil, "default representedObject is nil");

  /* thicknessRequiredInRuler: for a horizontal ruler this is the image height
     below the image origin (16 - 4). */
  pass([m thicknessRequiredInRuler] == 12.0,
       "thicknessRequiredInRuler is the image height minus the origin y");

  /* setter round-trips */
  [m setMarkerLocation: 200.0];
  [m setImageOrigin: NSMakePoint(5, 6)];
  [m setMovable: NO];
  [m setRemovable: YES];
  [m setRepresentedObject: @"obj"];
  pass([m markerLocation] == 200.0, "markerLocation round-trips");
  pass([m imageOrigin].x == 5 && [m imageOrigin].y == 6, "imageOrigin round-trips");
  pass([m isMovable] == NO, "movable round-trips");
  pass([m isRemovable] == YES, "removable round-trips");
  pass([(NSString *)[m representedObject] isEqualToString: @"obj"],
       "representedObject round-trips");

  /* a nil ruler view or image raises NSInvalidArgumentException */
  raised = NO;
  NS_DURING
    AUTORELEASE([[NSRulerMarker alloc] initWithRulerView: nil
                                          markerLocation: 0.0
                                                   image: img
                                             imageOrigin: NSZeroPoint]);
  NS_HANDLER
    raised = [[localException name] isEqualToString: NSInvalidArgumentException];
  NS_ENDHANDLER
  pass(raised, "a nil ruler view raises NSInvalidArgumentException");

  raised = NO;
  NS_DURING
    AUTORELEASE([[NSRulerMarker alloc] initWithRulerView: rv
                                          markerLocation: 0.0
                                                   image: nil
                                             imageOrigin: NSZeroPoint]);
  NS_HANDLER
    raised = [[localException name] isEqualToString: NSInvalidArgumentException];
  NS_ENDHANDLER
  pass(raised, "a nil image raises NSInvalidArgumentException");

  END_SET("NSRulerMarker basic")

  DESTROY(arp);
  return 0;
}
