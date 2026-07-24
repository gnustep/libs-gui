/* NSSplitViewController archives correctly with a keyed archiver: encoding does
   not corrupt the controller (the keyed encode branch used to decode into the
   receiver), and the minimum inline-sidebar thickness survives a keyed archive
   and unarchive round-trip. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewController.h>
#include <AppKit/NSSplitView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitViewController *svc;
  NSSplitViewController *decoded;
  NSSplitView *before;
  NSData *data;

  START_SET("NSSplitViewController coding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  svc = AUTORELEASE([[NSSplitViewController alloc] init]);
  [svc setMinimumThicknessForInlineSidebars: 123.0];
  before = [svc splitView];

  data = [NSKeyedArchiver archivedDataWithRootObject: svc];
  PASS([svc splitView] == before,
       "archiving does not replace the controller's split view");

  decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  PASS([decoded isKindOfClass: [NSSplitViewController class]],
       "the archive decodes to an NSSplitViewController");
  PASS([decoded minimumThicknessForInlineSidebars] == 123.0,
       "the minimum inline-sidebar thickness survives the round-trip");

  END_SET("NSSplitViewController coding")

  DESTROY(arp);
  return 0;
}
