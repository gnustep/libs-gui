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
  START_SET("NSLayoutConstraint resize reflow")

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

      /* Subview sized relative to the content view, inset from two edges. */
      [[[sub leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                        constant: 20.0] setActive: YES];
      [[[sub bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                          constant: 10.0] setActive: YES];
      [[[sub widthAnchor] constraintEqualToAnchor: [content widthAnchor]
                                         constant: -50.0] setActive: YES];
      [[[sub heightAnchor] constraintEqualToAnchor: [content heightAnchor]
                                          constant: -25.0] setActive: YES];

      [w layoutIfNeeded];
      NSRect before = [sub frame];
      PASS(fabs(before.size.width - 250.0) < 0.01
        && fabs(before.size.height - 175.0) < 0.01,
        "the subview tracks the initial content size");

      /* Resizing the window reflows the subview without an explicit layout. */
      [w setContentSize: NSMakeSize(400, 300)];
      NSRect after = [sub frame];
      PASS(fabs(after.origin.x - 20.0) < 0.01
        && fabs(after.origin.y - 10.0) < 0.01,
        "the subview keeps its insets after a resize");
      PASS(fabs(after.size.width - 350.0) < 0.01
        && fabs(after.size.height - 275.0) < 0.01,
        "the subview reflows to the new content size");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint resize reflow")
  DESTROY(arp);
  return 0;
}
