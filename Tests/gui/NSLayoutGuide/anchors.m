/* NSLayoutGuide vends layout anchors bound to the guide, and the constraints
   those anchors build carry the guide as their item with the right attribute
   and constant.  Values checked against AppKit on macOS. */
#import "Testing.h"
#import <AppKit/NSLayoutGuide.h>
#import <AppKit/NSLayoutAnchor.h>
#import <AppKit/NSLayoutConstraint.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSLayoutGuide *g = AUTORELEASE([[NSLayoutGuide alloc] init]);
  NSLayoutGuide *g2 = AUTORELEASE([[NSLayoutGuide alloc] init]);

  /* Anchor kinds. */
  PASS([[g widthAnchor] isKindOfClass: [NSLayoutDimension class]],
       "-widthAnchor is an NSLayoutDimension");
  PASS([[g leadingAnchor] isKindOfClass: [NSLayoutXAxisAnchor class]],
       "-leadingAnchor is an NSLayoutXAxisAnchor");
  PASS([[g topAnchor] isKindOfClass: [NSLayoutYAxisAnchor class]],
       "-topAnchor is an NSLayoutYAxisAnchor");

  /* A dimension constant constraint is bound to the guide. */
  NSLayoutConstraint *w = [[g widthAnchor] constraintEqualToConstant: 10.0];
  PASS([w firstItem] == g, "width constraint firstItem is the guide");
  PASS([w firstAttribute] == NSLayoutAttributeWidth,
       "width constraint firstAttribute is Width");
  PASS([w secondItem] == nil, "width constraint has no second item");
  PASS([w constant] == 10.0, "width constraint constant is 10");

  /* An anchor-to-anchor constraint carries both guides and attributes. */
  NSLayoutConstraint *lead =
      [[g leadingAnchor] constraintEqualToAnchor: [g2 leadingAnchor]];
  PASS([lead firstItem] == g, "leading constraint firstItem is the guide");
  PASS([lead firstAttribute] == NSLayoutAttributeLeading,
       "leading constraint firstAttribute is Leading");
  PASS([lead secondItem] == g2,
       "leading constraint secondItem is the other guide");
  PASS([lead secondAttribute] == NSLayoutAttributeLeading,
       "leading constraint secondAttribute is Leading");

  DESTROY(arp);
  return 0;
}
