#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSText.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCell *cell;
  NSRect frame = NSMakeRect(10, 20, 100, 40);
  NSRect r;

  START_SET("NSCell defaults")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSCell alloc] initTextCell: @"hello"]);

  /* The base NSCell implementations of these methods return the empty
     defaults; the text-clipping and focus-ring behaviour is provided by
     subclasses.  Checked against AppKit. */
  PASS([cell fieldEditorForView: nil] == nil,
    "fieldEditorForView: returns nil by default");

  PASS([cell wantsNotificationForMarkedText] == NO,
    "wantsNotificationForMarkedText is NO by default");

  r = [cell expansionFrameWithFrame: frame inView: nil];
  PASS(NSEqualRects(r, NSZeroRect),
    "expansionFrameWithFrame:inView: returns NSZeroRect by default");

  r = [cell focusRingMaskBoundsForFrame: frame inView: nil];
  PASS(NSEqualRects(r, NSZeroRect),
    "focusRingMaskBoundsForFrame:inView: returns NSZeroRect by default");

  END_SET("NSCell defaults")

  DESTROY(arp);
  return 0;
}
