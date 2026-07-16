/* Coverage for NSLayoutGuide: the init defaults (a zero frame, no owning view,
   an unambiguous layout) and the NSCoding / NSUserInterfaceItemIdentification
   conformance.  Every assertion was checked against Apple AppKit (macOS 26) and
   matches.  NSLayoutGuide is a plain model object and needs no backend. */
#import "Testing.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSLayoutGuide.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSLayoutGuide *g = [[NSLayoutGuide alloc] init];
  PASS(g != nil, "NSLayoutGuide -init returns an instance");

  /* Defaults that match AppKit. */
  PASS(NSEqualRects([g frame], NSZeroRect), "default frame is a zero rect");
  PASS([g owningView] == nil, "default owningView is nil");
  PASS([g hasAmbiguousLayout] == NO, "default hasAmbiguousLayout is NO");

  /* Declared protocol conformance. */
  PASS([g conformsToProtocol: @protocol(NSCoding)],
       "conforms to NSCoding");
  PASS([g conformsToProtocol: @protocol(NSUserInterfaceItemIdentification)],
       "conforms to NSUserInterfaceItemIdentification");

  RELEASE(g);
  DESTROY(arp);
  return 0;
}
