#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>

/* Values checked against AppKit. */

static NSView *
makeSuperview(void)
{
  NSView *sup = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  AUTORELEASE(sup);
  [sup setAutoresizesSubviews: YES];
  return sup;
}

static NSView *
addSubview(NSView *sup, NSRect frame, NSUInteger mask)
{
  NSView *sub = [[NSView alloc] initWithFrame: frame];
  AUTORELEASE(sub);
  [sub setAutoresizingMask: mask];
  [sup addSubview: sub];
  return sub;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView autoresize")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30), NSViewNotSizable);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 30, 30)),
      "NSViewNotSizable leaves the subview frame unchanged");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30), NSViewWidthSizable);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 130, 30)),
      "NSViewWidthSizable stretches the width by the superview's width delta");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30), NSViewHeightSizable);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 30, 80)),
      "NSViewHeightSizable stretches the height by the superview's height delta");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30),
      NSViewWidthSizable | NSViewHeightSizable);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 130, 80)),
      "NSViewWidthSizable | NSViewHeightSizable stretches both dimensions");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30), NSViewMinXMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(110, 10, 30, 30)),
      "NSViewMinXMargin pushes the subview by the full width delta, size unchanged");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30), NSViewMaxXMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 30, 30)),
      "NSViewMaxXMargin absorbs the width delta on the right, origin and size unchanged");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30),
      NSViewMinXMargin | NSViewMaxXMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(24, 10, 30, 30)),
      "NSViewMinXMargin | NSViewMaxXMargin splits the width delta evenly, keeps the subview centered");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30),
      NSViewMinYMargin | NSViewMaxYMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 17, 30, 30)),
      "NSViewMinYMargin | NSViewMaxYMargin splits the height delta evenly, keeps the subview centered");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30),
      NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(24, 17, 30, 30)),
      "all four margins split both deltas evenly, keeps the subview centered in both axes");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 30, 30),
      NSViewWidthSizable | NSViewHeightSizable
        | NSViewMinXMargin | NSViewMaxXMargin
        | NSViewMinYMargin | NSViewMaxYMargin);
    [sup setFrameSize: NSMakeSize(200, 150)];
    PASS(NSEqualRects([sub frame], NSMakeRect(20, 15, 60, 45)),
      "width, height and all four margins share the delta proportionally to their original sizes");
  }

  {
    NSView *sup = makeSuperview();
    NSView *sub = addSubview(sup, NSMakeRect(10, 10, 33, 33),
      NSViewWidthSizable | NSViewHeightSizable);
    [sup setFrameSize: NSMakeSize(151, 151)];
    PASS(NSEqualRects([sub frame], NSMakeRect(10, 10, 84, 84)),
      "a fractional resize delta rounds the resulting subview frame");
  }

  END_SET("NSView autoresize")

  DESTROY(arp);
  return 0;
}
