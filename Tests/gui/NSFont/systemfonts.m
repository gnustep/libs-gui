/* Coverage for the standard "role" fonts (system, bold system, user, user
 * fixed-pitch and label).  The physical font behind each role is platform and
 * configuration specific, so only the size behaviour is asserted: an explicit
 * size is honoured, and a zero size resolves to the matching default size.
 * Building the fonts needs the backend, so the test is guarded and skips
 * cleanly when none is present.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("standard role fonts")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like the GNUstep backend is not available")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFont *sys = [NSFont systemFontOfSize: 18.0];
      NSFont *bold = [NSFont boldSystemFontOfSize: 18.0];
      NSFont *user = [NSFont userFontOfSize: 14.0];
      NSFont *fixed = [NSFont userFixedPitchFontOfSize: 14.0];
      NSFont *label = [NSFont labelFontOfSize: 16.0];

      PASS(sys != nil && EQ([sys pointSize], 18.0),
        "systemFontOfSize: honours the requested size");
      PASS(bold != nil && EQ([bold pointSize], 18.0),
        "boldSystemFontOfSize: honours the requested size");
      PASS(user != nil && EQ([user pointSize], 14.0),
        "userFontOfSize: honours the requested size");
      PASS(fixed != nil && EQ([fixed pointSize], 14.0),
        "userFixedPitchFontOfSize: honours the requested size");
      PASS(label != nil && EQ([label pointSize], 16.0),
        "labelFontOfSize: honours the requested size");
    }

    {
      NSFont *sys0 = [NSFont systemFontOfSize: 0.0];

      PASS(sys0 != nil
        && EQ([sys0 pointSize], [NSFont systemFontSize]),
        "a zero size resolves to the system font size");
    }
  NS_HANDLER
    SKIP("No font backend available to build fonts")
  NS_ENDHANDLER

  END_SET("standard role fonts")
  DESTROY(arp);
  return 0;
}
