#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSWindow.h>

/* -[NSViewController viewWillAppear:]/-viewDidAppear: were sent from -loadView,
   so they fired when the view loaded rather than when it entered a window, and
   the disappear pair was never sent (gnustep/libs-gui issue #149).  They should
   now follow the view's window membership. */

@interface AppearanceVC : NSViewController
{
@public
  int didLoad;
  int willAppear;
  int didAppear;
  int willDisappear;
  int didDisappear;
}
@end

@implementation AppearanceVC
- (void) loadView
{
  [self setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)])];
}
- (void) viewDidLoad { didLoad++; }
- (void) viewWillAppear: (BOOL)a { [super viewWillAppear: a]; willAppear++; }
- (void) viewDidAppear: (BOOL)a { [super viewDidAppear: a]; didAppear++; }
- (void) viewWillDisappear: (BOOL)a { [super viewWillDisappear: a]; willDisappear++; }
- (void) viewDidDisappear: (BOOL)a { [super viewDidDisappear: a]; didDisappear++; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSViewController appearance")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  AppearanceVC *vc = AUTORELEASE([[AppearanceVC alloc]
    initWithNibName: nil bundle: nil]);
  NSView *view = [vc view];

  PASS(view != nil, "the controller loads its view");
  PASS(vc->didLoad == 1, "viewDidLoad is sent once when the view loads");
  PASS(vc->willAppear == 0 && vc->didAppear == 0,
    "the appearance methods are not sent while merely loading the view");

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      [[w contentView] addSubview: view];
      PASS(vc->willAppear == 1 && vc->didAppear == 1,
        "the appearance methods are sent when the view enters a window");

      [view removeFromSuperview];
      PASS(vc->willDisappear == 1 && vc->didDisappear == 1,
        "the disappearance methods are sent when the view leaves a window");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSViewController appearance")
  DESTROY(arp);
  return 0;
}
