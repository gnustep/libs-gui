/* Coverage for NSSplitViewItem default state: the view controller a factory
   item holds, the collapse flags, spring loading and the titlebar separator
   style.  Every assertion here matches AppKit (verified on a macOS runner) and
   passes on unmodified GNUstep. */
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

  vc = AUTORELEASE([[NSViewController alloc] init]);
  item = [NSSplitViewItem splitViewItemWithViewController: vc];

  PASS([item viewController] == vc,
       "a factory item holds the view controller it was created with");
  PASS([item canCollapse] == NO, "default canCollapse is NO");
  PASS([item collapseBehavior] == NSSplitViewItemCollapseBehaviorDefault,
       "default collapseBehavior is Default");
  PASS([item isSpringLoaded] == NO, "default isSpringLoaded is NO");
  PASS([item titlebarSeparatorStyle] == NSTitlebarSeparatorStyleAutomatic,
       "default titlebarSeparatorStyle is Automatic");

  DESTROY(arp);
  return 0;
}
