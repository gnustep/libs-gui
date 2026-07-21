/* NSView vends layout anchors (leadingAnchor/widthAnchor/topAnchor/...), and
   the constraints those anchors build carry the right item, attribute, relation,
   multiplier and constant.  Values checked against AppKit on macOS. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSLayoutAnchor.h>
#import <AppKit/NSLayoutConstraint.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSView layout anchors")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSView *v = AUTORELEASE([[NSView alloc]
                            initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSView *v2 = AUTORELEASE([[NSView alloc]
                             initWithFrame: NSMakeRect(0, 0, 100, 100)]);

  /* Anchor kinds. */
  PASS([[v widthAnchor] isKindOfClass: [NSLayoutDimension class]],
       "-widthAnchor is an NSLayoutDimension");
  PASS([[v leadingAnchor] isKindOfClass: [NSLayoutXAxisAnchor class]],
       "-leadingAnchor is an NSLayoutXAxisAnchor");
  PASS([[v topAnchor] isKindOfClass: [NSLayoutYAxisAnchor class]],
       "-topAnchor is an NSLayoutYAxisAnchor");

  /* Dimension constant constraint: item, attribute, no second item. */
  NSLayoutConstraint *w = [[v widthAnchor] constraintEqualToConstant: 50.0];
  PASS([w firstItem] == v, "width constraint firstItem is the view");
  PASS([w firstAttribute] == NSLayoutAttributeWidth,
       "width constraint firstAttribute is Width");
  PASS([w secondItem] == nil, "width constraint has no second item");
  PASS([w secondAttribute] == NSLayoutAttributeNotAnAttribute,
       "width constraint secondAttribute is NotAnAttribute");
  PASS([w constant] == 50.0, "width constraint constant is 50");
  PASS([w relation] == NSLayoutRelationEqual, "width constraint relation is Equal");
  PASS([w multiplier] == 1.0, "width constraint multiplier is 1");

  /* Anchor-to-anchor constraint carries both attributes and the constant. */
  NSLayoutConstraint *lead =
      [[v leadingAnchor] constraintEqualToAnchor: [v2 leadingAnchor]
                                        constant: 8.0];
  PASS([lead firstItem] == v, "leading constraint firstItem is the view");
  PASS([lead firstAttribute] == NSLayoutAttributeLeading,
       "leading constraint firstAttribute is Leading");
  PASS([lead secondItem] == v2, "leading constraint secondItem is the other view");
  PASS([lead secondAttribute] == NSLayoutAttributeLeading,
       "leading constraint secondAttribute is Leading");
  PASS([lead constant] == 8.0, "leading constraint constant is 8");

  END_SET("NSView layout anchors")

  DESTROY(arp);
  return 0;
}
