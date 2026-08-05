/* The arranged subviews of a stack view are placed by layout constraints.
   Every frame checked here was measured on a macOS runner with the same three
   arranged views, whose intrinsic content sizes are 40x20, 60x30 and 20x10, in
   a 200x200 stack view that is a window's content view.  Coordinates are
   unflipped, so a vertical stack runs from the top down. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSLayoutConstraint.h>
#import <AppKit/NSStackView.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

@interface GSFixedSizeView : NSView
{
  NSSize _intrinsic;
}
- (id) initWithIntrinsicSize: (NSSize)size;
@end

@implementation GSFixedSizeView
- (id) initWithIntrinsicSize: (NSSize)size
{
  self = [super initWithFrame: NSMakeRect(0, 0, size.width, size.height)];
  if (self != nil)
    {
      _intrinsic = size;
    }
  return self;
}
- (NSSize) intrinsicContentSize
{
  return _intrinsic;
}
@end

static NSStackView *
stackWithThreeViews(void)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 200, 200)
              styleMask: NSBorderlessWindowMask
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSStackView *sv = AUTORELEASE([[NSStackView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 200)]);
  NSSize sizes[3] = {{40, 20}, {60, 30}, {20, 10}};
  NSUInteger i;

  [w setContentView: sv];
  for (i = 0; i < 3; i++)
    {
      [sv addArrangedSubview: AUTORELEASE([[GSFixedSizeView alloc]
        initWithIntrinsicSize: sizes[i]])];
    }
  return sv;
}

static BOOL
frameIs(NSStackView *sv, NSUInteger index, NSRect expected)
{
  return NSEqualRects([[[sv arrangedSubviews] objectAtIndex: index] frame],
                      expected);
}

/* Whether this build solves layout constraints at all: pin one view 30 points
   past the trailing edge of another and see where it lands. */
static BOOL
engineSolvesConstraints(void)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 200, 200)
              styleMask: NSBorderlessWindowMask
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSView *host = [w contentView];
  NSView *a = AUTORELEASE([[GSFixedSizeView alloc]
    initWithIntrinsicSize: NSMakeSize(40, 20)]);
  NSView *b = AUTORELEASE([[GSFixedSizeView alloc]
    initWithIntrinsicSize: NSMakeSize(60, 30)]);

  [a setTranslatesAutoresizingMaskIntoConstraints: NO];
  [b setTranslatesAutoresizingMaskIntoConstraints: NO];
  [host addSubview: a];
  [host addSubview: b];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [NSLayoutConstraint constraintWithItem: a
      attribute: NSLayoutAttributeLeading relatedBy: NSLayoutRelationEqual
         toItem: host attribute: NSLayoutAttributeLeading
     multiplier: 1.0 constant: 0],
    [NSLayoutConstraint constraintWithItem: b
      attribute: NSLayoutAttributeLeading relatedBy: NSLayoutRelationEqual
         toItem: a attribute: NSLayoutAttributeTrailing
     multiplier: 1.0 constant: 30], nil]];
  [host layoutSubtreeIfNeeded];
  return [b frame].origin.x == 70;
}

int
main(int argc, const char **argv)
{
  START_SET("NSStackView arranged layout")

  NSStackView *sv;
  BOOL solved = NO;

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationHorizontal];
      [sv setSpacing: 10];
      [sv layoutSubtreeIfNeeded];
      solved = engineSolvesConstraints();
      if (solved)
        {
      PASS(frameIs(sv, 0, NSMakeRect(0, 90, 40, 20))
        && frameIs(sv, 1, NSMakeRect(50, 85, 60, 30))
        && frameIs(sv, 2, NSMakeRect(120, 95, 20, 10)),
        "a horizontal stack spaces the views and centres them");
      PASS(NSEqualRects([sv frame], NSMakeRect(0, 0, 200, 200)),
        "laying out the arranged views leaves the stack view frame alone");

      [sv setSpacing: 0];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(0, 90, 40, 20))
        && frameIs(sv, 1, NSMakeRect(40, 85, 60, 30))
        && frameIs(sv, 2, NSMakeRect(100, 95, 20, 10)),
        "spacing 0 leaves no gap between the views");

      [sv setSpacing: 10];
      [sv setEdgeInsets: NSEdgeInsetsMake(5, 15, 5, 15)];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(15, 90, 40, 20))
        && frameIs(sv, 1, NSMakeRect(65, 85, 60, 30))
        && frameIs(sv, 2, NSMakeRect(135, 95, 20, 10)),
        "the leading edge inset moves the views");

      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationHorizontal];
      [sv setSpacing: 10];
      [sv setDistribution: NSStackViewDistributionFill];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(0, 90, 100, 20))
        && frameIs(sv, 1, NSMakeRect(110, 85, 60, 30))
        && frameIs(sv, 2, NSMakeRect(180, 95, 20, 10)),
        "Fill gives the slack to the first view and reaches the trailing edge");

      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationHorizontal];
      [sv setSpacing: 10];
      [sv setDistribution: NSStackViewDistributionFillEqually];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(0, 90, 60, 20))
        && frameIs(sv, 1, NSMakeRect(70, 85, 60, 30))
        && frameIs(sv, 2, NSMakeRect(140, 95, 60, 10)),
        "FillEqually gives every view the same width");

      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationVertical];
      [sv setSpacing: 10];
      [sv setAlignment: NSLayoutAttributeLeading];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(0, 180, 40, 20))
        && frameIs(sv, 1, NSMakeRect(0, 140, 60, 30))
        && frameIs(sv, 2, NSMakeRect(0, 120, 20, 10)),
        "a vertical stack runs from the top down, aligned leading");

      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationVertical];
      [sv setSpacing: 10];
      [sv setAlignment: NSLayoutAttributeCenterX];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(80, 180, 40, 20))
        && frameIs(sv, 1, NSMakeRect(70, 140, 60, 30))
        && frameIs(sv, 2, NSMakeRect(90, 120, 20, 10)),
        "alignment NSLayoutAttributeCenterX centres each view");

      sv = stackWithThreeViews();
      [sv setOrientation: NSUserInterfaceLayoutOrientationVertical];
      [sv setSpacing: 10];
      [sv setAlignment: NSLayoutAttributeTrailing];
      [sv layoutSubtreeIfNeeded];
      PASS(frameIs(sv, 0, NSMakeRect(160, 180, 40, 20))
        && frameIs(sv, 1, NSMakeRect(140, 140, 60, 30))
        && frameIs(sv, 2, NSMakeRect(180, 120, 20, 10)),
        "alignment NSLayoutAttributeTrailing puts every view at the far edge");
        }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  if (!solved)
    {
      SKIP("this build solves no layout constraints")
    }

  END_SET("NSStackView arranged layout")
  return 0;
}
