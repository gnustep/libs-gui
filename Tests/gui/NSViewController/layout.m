#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSWindow.h>

/* -[NSViewController viewWillLayout]/-viewDidLayout and -updateViewConstraints
   were declared but never sent (gnustep/libs-gui issue #149).  The view now
   brackets its -layout with the controller's will/did layout and routes
   -updateConstraints through the controller's -updateViewConstraints. */

@interface LayoutVC : NSViewController
{
@public
  int willLayout;
  int didLayout;
  int updateConstraints;
}
@end

@implementation LayoutVC
- (void) loadView
{
  [self setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)])];
}
- (void) viewWillLayout { [super viewWillLayout]; willLayout++; }
- (void) viewDidLayout { [super viewDidLayout]; didLayout++; }
- (void) updateViewConstraints { updateConstraints++; [super updateViewConstraints]; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  LayoutVC *vc;
  NSView *view;

  START_SET("NSViewController layout")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      vc = AUTORELEASE([[LayoutVC alloc] initWithNibName: nil bundle: nil]);
      view = [vc view];

      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: view];

      /* Laying out the controller's view brackets it with will/did layout. */
      vc->willLayout = 0;
      vc->didLayout = 0;
      [view layout];
      PASS(vc->willLayout == 1 && vc->didLayout == 1,
        "the view's -layout sends viewWillLayout and viewDidLayout");

      /* It happens on each layout pass. */
      [view layout];
      PASS(vc->willLayout == 2 && vc->didLayout == 2,
        "the layout methods are sent on each layout");

      /* Updating the view's constraints routes through updateViewConstraints. */
      vc->updateConstraints = 0;
      [view setNeedsUpdateConstraints: YES];
      [view updateConstraintsForSubtreeIfNeeded];
      PASS(vc->updateConstraints == 1,
        "updating the view's constraints sends updateViewConstraints");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
    else
      [localException raise];
  NS_ENDHANDLER

  END_SET("NSViewController layout")

  DESTROY(arp);
  return 0;
}
