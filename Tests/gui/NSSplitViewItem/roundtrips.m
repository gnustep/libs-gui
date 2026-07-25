/* Coverage for NSSplitViewItem setters: the thickness values, the preferred
   thickness fraction, spring loading, full height layout, the titlebar
   separator style and the view controller all round-trip.  Matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewItem.h>
#include <AppKit/NSViewController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSViewController *vc;
  NSSplitViewItem *item;

  item = [NSSplitViewItem splitViewItemWithViewController: nil];

  [item setMinimumThickness: 100.0];
  PASS([item minimumThickness] == 100.0, "minimumThickness round-trips");
  [item setMaximumThickness: 400.0];
  PASS([item maximumThickness] == 400.0, "maximumThickness round-trips");
  [item setPreferredThicknessFraction: 0.25];
  PASS([item preferredThicknessFraction] == 0.25,
       "preferredThicknessFraction round-trips");
  [item setAutomaticMaximumThickness: 200.0];
  PASS([item automaticMaximumThickness] == 200.0,
       "automaticMaximumThickness round-trips");

  [item setSpringLoaded: YES];
  PASS([item isSpringLoaded] == YES, "springLoaded set to YES");
  [item setSpringLoaded: NO];
  PASS([item isSpringLoaded] == NO, "springLoaded set back to NO");

  [item setAllowsFullHeightLayout: YES];
  PASS([item allowsFullHeightLayout] == YES, "allowsFullHeightLayout set to YES");
  [item setAllowsFullHeightLayout: NO];
  PASS([item allowsFullHeightLayout] == NO,
       "allowsFullHeightLayout set back to NO");

  [item setTitlebarSeparatorStyle: NSTitlebarSeparatorStyleLine];
  PASS([item titlebarSeparatorStyle] == NSTitlebarSeparatorStyleLine,
       "titlebarSeparatorStyle set to Line");
  [item setTitlebarSeparatorStyle: NSTitlebarSeparatorStyleShadow];
  PASS([item titlebarSeparatorStyle] == NSTitlebarSeparatorStyleShadow,
       "titlebarSeparatorStyle set to Shadow");

  vc = AUTORELEASE([[NSViewController alloc] init]);
  [item setViewController: vc];
  PASS([item viewController] == vc, "viewController round-trips");

  DESTROY(arp);
  return 0;
}
