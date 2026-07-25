/* NSSplitViewItem owns the view controller it holds: setViewController: keeps
   it alive and a deallocated item releases it. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewItem.h>
#include <AppKit/NSViewController.h>

static BOOL vcDeallocated;

@interface ProbeViewController : NSViewController
@end

@implementation ProbeViewController
- (void) dealloc
{
  vcDeallocated = YES;
  [super dealloc];
}
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAutoreleasePool *pool;
  NSSplitViewItem *item;
  ProbeViewController *vc;

  /* Keep the only reference to the item so that releasing it below runs its
     deallocation. */
  pool = [NSAutoreleasePool new];
  item = RETAIN([NSSplitViewItem splitViewItemWithViewController: nil]);
  RELEASE(pool);

  vcDeallocated = NO;
  vc = [[ProbeViewController alloc] init];
  [item setViewController: vc];
  RELEASE(vc);
  PASS(vcDeallocated == NO,
       "setViewController retains the view controller");
  PASS([item viewController] == vc,
       "the item still holds the view controller");

  RELEASE(item);
  PASS(vcDeallocated == YES,
       "a deallocated item releases its view controller");

  DESTROY(arp);
  return 0;
}
