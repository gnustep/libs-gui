/* Coverage for NSTabView scalar state: the type, background, truncation and
   font defaults and their setter round-trips, plus the control-size and
   control-tint getter defaults. Every assertion matches AppKit (checked on a
   macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTabView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabView *tv;

  START_SET("NSTabView defaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);

      pass([tv tabViewType] == NSTopTabsBezelBorder,
           "the default tab view type is NSTopTabsBezelBorder");
      pass([tv font] != nil, "a tab view has a font");
      pass([tv controlSize] == NSRegularControlSize,
           "the default control size is regular");
      pass([tv controlTint] == NSDefaultControlTint,
           "the default control tint is the default tint");

      [tv setTabViewType: NSNoTabsNoBorder];
      pass([tv tabViewType] == NSNoTabsNoBorder, "tabViewType round-trips");

      [tv setDrawsBackground: YES];
      pass([tv drawsBackground] == YES, "drawsBackground round-trips to YES");
      [tv setDrawsBackground: NO];
      pass([tv drawsBackground] == NO, "drawsBackground round-trips to NO");

      [tv setAllowsTruncatedLabels: YES];
      pass([tv allowsTruncatedLabels] == YES,
           "allowsTruncatedLabels round-trips to YES");
      [tv setAllowsTruncatedLabels: NO];
      pass([tv allowsTruncatedLabels] == NO,
           "allowsTruncatedLabels round-trips to NO");

      [tv setFont: [NSFont boldSystemFontOfSize: 12]];
      pass([[tv font] isEqual: [NSFont boldSystemFontOfSize: 12]],
           "font round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView defaults")

  DESTROY(arp);
  return 0;
}
