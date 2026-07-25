/* NSSplitViewItem round-trips its thickness, priority, collapse behaviour and
   flag state through a keyed archive, not just its view controller. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitViewItem *item;
  NSSplitViewItem *decoded;
  NSData *data;

  item = [NSSplitViewItem splitViewItemWithViewController: nil];
  [item setMinimumThickness: 50.0];
  [item setMaximumThickness: 300.0];
  [item setPreferredThicknessFraction: 0.25];
  [item setAutomaticMaximumThickness: 200.0];
  [item setSpringLoaded: YES];
  [item setAllowsFullHeightLayout: YES];
  [item setTitlebarSeparatorStyle: NSTitlebarSeparatorStyleLine];

  data = [NSKeyedArchiver archivedDataWithRootObject: item];
  decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];

  PASS([decoded isKindOfClass: [NSSplitViewItem class]],
       "the archive decodes to an NSSplitViewItem");
  PASS([decoded minimumThickness] == 50.0,
       "minimumThickness survives the round-trip");
  PASS([decoded maximumThickness] == 300.0,
       "maximumThickness survives the round-trip");
  PASS([decoded preferredThicknessFraction] == 0.25,
       "preferredThicknessFraction survives the round-trip");
  PASS([decoded automaticMaximumThickness] == 200.0,
       "automaticMaximumThickness survives the round-trip");
  PASS([decoded isSpringLoaded] == YES,
       "springLoaded survives the round-trip");
  PASS([decoded allowsFullHeightLayout] == YES,
       "allowsFullHeightLayout survives the round-trip");
  PASS([decoded titlebarSeparatorStyle] == NSTitlebarSeparatorStyleLine,
       "titlebarSeparatorStyle survives the round-trip");

  DESTROY(arp);
  return 0;
}
