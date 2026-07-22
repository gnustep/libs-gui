#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSLayoutConstraint.h>
#import <AppKit/NSLayoutAnchor.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSLayoutConstraint intrinsic content size")

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

      NSButton *button = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 0, 0)]);
      [button setTitle: @"Click Me"];
      [button setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: button];

      NSSize intrinsic = [button intrinsicContentSize];
      PASS(intrinsic.width > 0.0 && intrinsic.height > 0.0,
        "a control reports a positive intrinsic content size");

      /* Only position constraints: the button should adopt its intrinsic
         content size in both dimensions. */
      [[[button leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                           constant: 20.0] setActive: YES];
      [[[button bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                             constant: 20.0] setActive: YES];

      [w layoutIfNeeded];

      NSRect f = [button frame];
      PASS(fabs(f.size.width - intrinsic.width) < 0.5,
        "the button width matches its intrinsic content width");
      PASS(fabs(f.size.height - intrinsic.height) < 0.5,
        "the button height matches its intrinsic content height");
      PASS(fabs(f.origin.x - 20.0) < 0.5 && fabs(f.origin.y - 20.0) < 0.5,
        "the button keeps its position constraints");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint intrinsic content size")
  DESTROY(arp);
  return 0;
}
