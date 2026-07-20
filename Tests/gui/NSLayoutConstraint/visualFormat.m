#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSLayoutConstraint.h>

static NSView *
addSubview(NSView *content)
{
  NSView *v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 0, 0)]);
  [v setTranslatesAutoresizingMaskIntoConstraints: NO];
  [content addSubview: v];
  return v;
}

static void
activateFormat(NSString *format, NSDictionary *views)
{
  [NSLayoutConstraint activateConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat: format
                                            options: 0
                                            metrics: nil
                                              views: views]];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSLayoutConstraint visual format")

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

      NSView *a = addSubview(content);
      activateFormat(@"H:|-20-[a(100)]", [NSDictionary dictionaryWithObject: a forKey: @"a"]);

      NSView *b = addSubview(content);
      activateFormat(@"H:|-20-[b]-30-|", [NSDictionary dictionaryWithObject: b forKey: @"b"]);

      NSView *c = addSubview(content);
      activateFormat(@"V:|-10-[c]-20-|", [NSDictionary dictionaryWithObject: c forKey: @"c"]);

      [w layoutIfNeeded];

      NSRect fa = [a frame];
      PASS(fabs(fa.origin.x - 20.0) < 0.01 && fabs(fa.size.width - 100.0) < 0.01,
        "H:|-20-[a(100)] places a at x=20 with width 100");

      NSRect fb = [b frame];
      PASS(fabs(fb.origin.x - 20.0) < 0.01 && fabs(fb.size.width - 250.0) < 0.01,
        "H:|-20-[b]-30-| insets b by 20 and 30 (width 250)");

      NSRect fc = [c frame];
      PASS(fabs(fc.origin.y - 20.0) < 0.01 && fabs(fc.size.height - 170.0) < 0.01,
        "V:|-10-[c]-20-| insets c by 10 top and 20 bottom (height 170)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint visual format")
  DESTROY(arp);
  return 0;
}
