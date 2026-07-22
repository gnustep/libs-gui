#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSLayoutConstraint.h>
#import <AppKit/NSLayoutAnchor.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSLayoutConstraint activation")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *content = [w contentView];

      NSView *sub = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 0, 0)]);
      [sub setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: sub];

      /* The content view is pinned to its own bounds automatically, so the
         subview position and size below are fully determined. */
      NSLayoutConstraint *width =
        [[sub widthAnchor] constraintEqualToConstant: 120.0];
      NSLayoutConstraint *height =
        [[sub heightAnchor] constraintEqualToConstant: 80.0];
      NSLayoutConstraint *left =
        [[sub leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                         constant: 20.0];
      NSLayoutConstraint *bottom =
        [[sub bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                           constant: 10.0];
      [width setActive: YES];
      [height setActive: YES];
      [left setActive: YES];
      [bottom setActive: YES];

      PASS([width isActive] && [height isActive]
        && [left isActive] && [bottom isActive],
        "setActive: YES marks a constraint active");

      [w layoutIfNeeded];

      NSRect f = [sub frame];
      PASS(fabs(f.size.width - 120.0) < 0.01,
        "an active width constraint sets the solved width");
      PASS(fabs(f.size.height - 80.0) < 0.01,
        "an active height constraint sets the solved height");
      PASS(fabs(f.origin.x - 20.0) < 0.01,
        "an active leading constraint sets the solved origin x");
      PASS(fabs(f.origin.y - 10.0) < 0.01,
        "an active bottom constraint sets the solved origin y");

      [width setActive: NO];
      PASS([width isActive] == NO,
        "setActive: NO marks a constraint inactive");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint activation")
  DESTROY(arp);
  return 0;
}
