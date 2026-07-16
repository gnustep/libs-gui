/* Selecting a page: the arranged objects are the application's own, and the
 * delegate says which view controller shows one.  The controller reports the
 * object it moved to, and refuses an index it has no object for.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPageController.h>
#include <AppKit/NSView.h>
#include <AppKit/NSViewController.h>

@interface Delegate : NSObject
{
@public
  NSMutableArray	*calls;
  NSViewController	*vended;
  id			transitionedTo;
  id			framedFor;
}
@end

@implementation Delegate

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      calls = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(calls);
  RELEASE(vended);
  [super dealloc];
}

- (NSString *) pageController: (NSPageController *)controller
          identifierForObject: (id)object
{
  [calls addObject: @"identifierForObject:"];
  return [NSString stringWithFormat: @"id-%@", object];
}

- (NSViewController *) pageController: (NSPageController *)controller
          viewControllerForIdentifier: (NSString *)identifier
{
  NSViewController	*controllerForPage;
  NSView		*view;

  [calls addObject: @"viewControllerForIdentifier:"];
  controllerForPage = AUTORELEASE([[NSViewController alloc] init]);
  view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);
  [controllerForPage setView: view];
  ASSIGN(vended, controllerForPage);
  return controllerForPage;
}

- (void) pageController: (NSPageController *)controller
  prepareViewController: (NSViewController *)viewController
             withObject: (id)object
{
  [calls addObject: @"prepareViewController:withObject:"];
}

- (void) pageController: (NSPageController *)controller
  didTransitionToObject: (id)object
{
  [calls addObject: @"didTransitionToObject:"];
  transitionedTo = object;
}

- (NSRect) pageController: (NSPageController *)controller
           frameForObject: (id)object
{
  [calls addObject: @"frameForObject:"];
  framedFor = object;
  return NSMakeRect(0, 0, 50, 50);
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("selection")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSPageController	*controller;
    Delegate		*delegate;
    NSArray		*objects;
    BOOL		raised;

    /* selecting through the delegate */
    controller = AUTORELEASE([[NSPageController alloc] init]);
    delegate = AUTORELEASE([[Delegate alloc] init]);
    objects = [NSArray arrayWithObjects: @"a", @"b", @"c", nil];

    [controller setDelegate: delegate];
    [controller setArrangedObjects: objects];
    [controller setSelectedIndex: 2];

    PASS([controller selectedIndex] == 2, "the selected index is set");
    PASS([controller selectedViewController] == delegate->vended,
      "the selected view controller is the one the delegate vends");
    PASS([delegate->calls containsObject: @"identifierForObject:"],
      "the delegate is asked for the object's identifier");
    PASS([delegate->calls containsObject: @"viewControllerForIdentifier:"],
      "the delegate is asked for the view controller of that identifier");
    PASS([delegate->calls containsObject: @"prepareViewController:withObject:"],
      "the delegate is asked to prepare the view controller");
    PASS([(NSString *)delegate->transitionedTo isEqualToString: @"c"],
      "the delegate is told which object was moved to, not its view controller");
    PASS([(NSString *)delegate->framedFor isEqualToString: @"c"],
      "the delegate is asked for the frame of the object, not its view controller");

    /* selecting without a delegate */
    controller = AUTORELEASE([[NSPageController alloc] init]);
    [controller setArrangedObjects:
      [NSArray arrayWithObjects: @"a", @"b", nil]];

    raised = NO;
    NS_DURING
      [controller setSelectedIndex: 1];
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER

    PASS(raised == NO, "selecting a page with no delegate does not raise");
    PASS([controller selectedIndex] == 1, "the selected index is still set");
    PASS([controller selectedViewController] == nil,
      "there is no selected view controller without a delegate");

    /* an index with no object.  Selecting the index already selected asks for
     * nothing and so cannot be out of range, which is why an empty controller
     * tolerates zero. */
    controller = AUTORELEASE([[NSPageController alloc] init]);
    raised = NO;
    NS_DURING
      [controller setSelectedIndex: 0];
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER
    PASS(raised == NO, "selecting zero on an empty controller does not raise");
    PASS([controller selectedIndex] == 0, "the selected index stays at zero");

    raised = NO;
    NS_DURING
      [controller setSelectedIndex: 5];
    NS_HANDLER
      raised = [[localException name]
        isEqualToString: NSInternalInconsistencyException];
    NS_ENDHANDLER
    PASS(raised == YES, "an index an empty controller has no object for raises");

    controller = AUTORELEASE([[NSPageController alloc] init]);
    [controller setArrangedObjects:
      [NSArray arrayWithObjects: @"a", @"b", @"c", nil]];

    raised = NO;
    NS_DURING
      [controller setSelectedIndex: 3];
    NS_HANDLER
      raised = [[localException name]
        isEqualToString: NSInternalInconsistencyException];
    NS_ENDHANDLER
    PASS(raised == YES, "an index past the last object raises");

    raised = NO;
    NS_DURING
      [controller setSelectedIndex: -1];
    NS_HANDLER
      raised = [[localException name]
        isEqualToString: NSInternalInconsistencyException];
    NS_ENDHANDLER
    PASS(raised == YES, "a negative index raises");

    /* navigating an empty controller */
    controller = AUTORELEASE([[NSPageController alloc] init]);
    raised = NO;
    NS_DURING
      [controller navigateBack: nil];
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER
    PASS(raised == NO, "navigating back on an empty controller does not raise");
    PASS([controller selectedIndex] == 0,
      "the selected index stays at zero when navigating back");
  }

  END_SET("selection")

  DESTROY(arp);
  return 0;
}
