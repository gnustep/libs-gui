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
  START_SET("NSLayoutConstraint edge insets")

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

      /* Inset on all four edges. The trailing (right) and top constants are
         negative offsets from the container edges. */
      [[[sub leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                        constant: 20.0] setActive: YES];
      [[[sub rightAnchor] constraintEqualToAnchor: [content rightAnchor]
                                         constant: -30.0] setActive: YES];
      [[[sub bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                          constant: 10.0] setActive: YES];
      [[[sub topAnchor] constraintEqualToAnchor: [content topAnchor]
                                       constant: -15.0] setActive: YES];

      [w layoutIfNeeded];

      NSRect f = [sub frame];
      PASS(fabs(f.origin.x - 20.0) < 0.01, "left anchor insets the origin x");
      PASS(fabs(f.origin.y - 10.0) < 0.01, "bottom anchor insets the origin y");
      PASS(fabs(f.size.width - 250.0) < 0.01,
        "a negative right anchor constant insets the width");
      PASS(fabs(f.size.height - 175.0) < 0.01,
        "a negative top anchor constant insets the height");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint edge insets")
  DESTROY(arp);
  return 0;
}
