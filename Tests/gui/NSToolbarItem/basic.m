/* Coverage for NSToolbarItem: the init defaults (identifier, label, toolTip,
   visibilityPriority, autovalidates, view/target/action, allowsDuplicates) and
   the plain setter round-trips for the label, paletteLabel, toolTip, tag,
   visibility priority, autovalidates and enabled flags and the min/max sizes.
   Every assertion here matches AppKit (verified on a macOS runner) and passes
   on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSToolbarItem *item;

  START_SET("NSToolbarItem basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* init defaults */
  item = AUTORELEASE([[NSToolbarItem alloc]
                       initWithItemIdentifier: @"myItem"]);
  pass([[item itemIdentifier] isEqualToString: @"myItem"],
       "itemIdentifier is the identifier passed in");
  pass([[item label] isEqualToString: @""], "default label is the empty string");
  pass([item toolTip] == nil, "default toolTip is nil");
  pass([item visibilityPriority] == NSToolbarItemVisibilityPriorityStandard,
       "default visibilityPriority is standard");
  pass([item autovalidates] == YES, "default autovalidates is YES");
  pass([item view] == nil, "default view is nil");
  pass([item target] == nil, "default target is nil");
  pass([item action] == NULL, "default action is NULL");
  pass([item allowsDuplicatesInToolbar] == NO,
       "a normal item does not allow duplicates in the toolbar");

  /* setter round-trips */
  item = AUTORELEASE([[NSToolbarItem alloc]
                       initWithItemIdentifier: @"setItem"]);
  [item setLabel: @"L"];
  [item setPaletteLabel: @"P"];
  [item setToolTip: @"T"];
  [item setTag: 42];
  [item setVisibilityPriority: NSToolbarItemVisibilityPriorityHigh];
  [item setAutovalidates: NO];
  [item setEnabled: NO];
  [item setMinSize: NSMakeSize(10, 20)];
  [item setMaxSize: NSMakeSize(30, 40)];
  pass([[item label] isEqualToString: @"L"], "label round-trips");
  pass([[item paletteLabel] isEqualToString: @"P"], "paletteLabel round-trips");
  pass([[item toolTip] isEqualToString: @"T"], "toolTip round-trips");
  pass([item tag] == 42, "tag round-trips");
  pass([item visibilityPriority] == NSToolbarItemVisibilityPriorityHigh,
       "visibilityPriority round-trips");
  pass([item autovalidates] == NO, "autovalidates round-trips");
  pass([item isEnabled] == NO, "enabled round-trips");
  pass([item minSize].width == 10 && [item minSize].height == 20,
       "minSize round-trips");
  pass([item maxSize].width == 30 && [item maxSize].height == 40,
       "maxSize round-trips");

  END_SET("NSToolbarItem basic")

  DESTROY(arp);
  return 0;
}
