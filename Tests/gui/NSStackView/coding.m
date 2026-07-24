/* A stack view built from an archive must be as usable as one built with the
   designated -initWithFrame:.  -initWithCoder: decoded the archived scalars and
   containers but never created the arranged/detached/view arrays or the
   custom-spacing and visibility-priority map tables, so on a decoded stack view
   every setter that routes through them silently did nothing:
   -setCustomSpacing:afterView: dropped the value and -customSpacingAfterView:
   then returned 0.  A stack view built directly records the value (the
   containers are archived nil here, so the layout pass is a no-op); check the
   decoded one now does too. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStackView.h>
#include <AppKit/NSView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStackView *sv;
  NSStackView *decoded;
  NSView *v1;
  NSView *v2;
  NSData *data;

  START_SET("NSStackView coding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      v1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);
      v2 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);

      sv = AUTORELEASE([[NSStackView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);

      /* Baseline: a directly built stack view records custom spacing. */
      [sv setCustomSpacing: 5.0 afterView: v1];
      PASS([sv customSpacingAfterView: v1] == 5.0,
           "a stack view records custom spacing after a view");

      data = [NSKeyedArchiver archivedDataWithRootObject: sv];
      PASS(data != nil && [data length] > 0, "a stack view archives");

      decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
      PASS(decoded != nil && [decoded isKindOfClass: [NSStackView class]],
           "a stack view unarchives");

      /* The decoded stack view must record custom spacing just like the
         original.  Before -initWithCoder: created the map its value was
         silently dropped and this read back 0. */
      [decoded setCustomSpacing: 7.0 afterView: v2];
      PASS([decoded customSpacingAfterView: v2] == 7.0,
           "a decoded stack view records custom spacing after a view");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSStackView coding")

  DESTROY(arp);
  return 0;
}
