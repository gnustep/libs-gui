/* NSViewController sends -viewDidLoad once its view has been loaded, including
   when the view is created in a -loadView override rather than from a nib.  It
   used to be sent only on the nib path.  -isViewLoaded reports whether the view
   has been loaded.  A plain view is created, so the theme and font backend is
   used; the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSViewController.h>

@interface CodeViewController : NSViewController
{
@public
  int viewDidLoadCount;
}
@end

@implementation CodeViewController
- (void) loadView
{
  [self setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 20, 20)])];
}
- (void) viewDidLoad
{
  [super viewDidLoad];
  viewDidLoadCount++;
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSViewController viewDidLoad")

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

  NS_DURING
    {
      CodeViewController *vc = AUTORELEASE([[CodeViewController alloc]
        initWithNibName: nil bundle: nil]);

      pass([vc isViewLoaded] == NO, "the view is not loaded before it is used");
      pass(vc->viewDidLoadCount == 0, "viewDidLoad has not been sent yet");

      NSView *v = [vc view];
      pass(v != nil, "accessing the view loads it from -loadView");
      pass([vc isViewLoaded] == YES, "the view reports as loaded");
      pass(vc->viewDidLoadCount == 1, "viewDidLoad is sent once the view loads");

      /* Accessing the view again must not send viewDidLoad a second time. */
      [vc view];
      pass(vc->viewDidLoadCount == 1, "viewDidLoad is sent only once");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSViewController viewDidLoad")

  DESTROY(arp);
  return 0;
}
