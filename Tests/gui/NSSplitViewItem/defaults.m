/* Coverage for NSSplitViewItem thickness and priority defaults.  A newly
   created item reports the unspecified dimension for its thickness values and
   preferred thickness fraction, a default-low holding priority, and allows a
   full height layout, as AppKit does (verified on a macOS runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLayoutConstraint.h>
#include <AppKit/NSSplitViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitViewItem *item;

  PASS(NSSplitViewItemUnspecifiedDimension == -1.0,
       "NSSplitViewItemUnspecifiedDimension is -1");

  item = [NSSplitViewItem splitViewItemWithViewController: nil];

  PASS([item automaticMaximumThickness] == NSSplitViewItemUnspecifiedDimension,
       "default automaticMaximumThickness is the unspecified dimension");
  PASS([item preferredThicknessFraction] == NSSplitViewItemUnspecifiedDimension,
       "default preferredThicknessFraction is the unspecified dimension");
  PASS([item minimumThickness] == NSSplitViewItemUnspecifiedDimension,
       "default minimumThickness is the unspecified dimension");
  PASS([item maximumThickness] == NSSplitViewItemUnspecifiedDimension,
       "default maximumThickness is the unspecified dimension");
  PASS([item holdingPriority] == NSLayoutPriorityDefaultLow,
       "default holdingPriority is NSLayoutPriorityDefaultLow");
  PASS([item allowsFullHeightLayout] == YES,
       "default allowsFullHeightLayout is YES");

  DESTROY(arp);
  return 0;
}
