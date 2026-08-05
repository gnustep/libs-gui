/* NSSplitViewItem: the three factory methods produce differently configured
   items (behavior, holding priority, collapse and spring-load flags, automatic
   maximum thickness), and -isCollapsed reflects and controls the collapse of
   the item in its split view.  The factory values were checked against AppKit
   on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSSplitViewController.h>
#include <AppKit/NSSplitViewItem.h>
#include <AppKit/NSView.h>
#include <AppKit/NSViewController.h>

static NSViewController *
controllerWithView(void)
{
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);
  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)])];
  return vc;
}

int
main()
{
  NSViewController *vc;
  NSSplitViewItem *item;
  NSSplitViewItem *side;
  NSSplitViewItem *content;

  START_SET("NSSplitViewItem behavior")

  /* Factory differentiation (backend independent). */
  vc = controllerWithView();
  item = [NSSplitViewItem splitViewItemWithViewController: vc];
  side = [NSSplitViewItem sidebarWithViewController: controllerWithView()];
  content = [NSSplitViewItem contentListWithViewController: controllerWithView()];

  PASS([item behavior] == NSSplitViewItemBehaviorDefault,
       "the plain factory has the default behavior");
  PASS([side behavior] == NSSplitViewItemBehaviorSidebar,
       "the sidebar factory has the sidebar behavior");
  PASS([content behavior] == NSSplitViewItemBehaviorContentList,
       "the content-list factory has the content-list behavior");

  PASS([side holdingPriority] == 260 && [item holdingPriority] == 250
    && [content holdingPriority] == 255,
       "each factory sets its holding priority");
  PASS([side canCollapse] == YES && [item canCollapse] == NO,
       "only the sidebar factory can collapse by default");
  PASS([side isSpringLoaded] == YES && [item isSpringLoaded] == NO,
       "only the sidebar factory is spring loaded by default");

  PASS([item isCollapsed] == NO, "an item is not collapsed by default");

  /* isCollapsed reflects and controls the split view collapse. */
  NS_DURING
    {
      NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);
      NSSplitViewItem *a = [NSSplitViewItem splitViewItemWithViewController: controllerWithView()];
      NSSplitViewItem *b = [NSSplitViewItem splitViewItemWithViewController: controllerWithView()];
      NSSplitView *sv;

      [svc addSplitViewItem: a];
      [svc addSplitViewItem: b];
      sv = [svc splitView];
      [sv setFrame: NSMakeRect(0, 0, 200, 200)];
      [sv adjustSubviews];

      PASS([a isCollapsed] == NO,
           "an item laid out in a split view starts uncollapsed");
      [a setCollapsed: YES];
      PASS([a isCollapsed] == YES,
           "setCollapsed:YES collapses the item in its split view");
      [a setCollapsed: NO];
      PASS([a isCollapsed] == NO,
           "setCollapsed:NO expands the item again");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
    else
      [localException raise];
  NS_ENDHANDLER

  END_SET("NSSplitViewItem behavior")

  return 0;
}
