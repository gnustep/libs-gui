/* Coverage for NSLayoutAnchor: the class hierarchy (NSLayoutDimension,
   NSLayoutXAxisAnchor and NSLayoutYAxisAnchor are subclasses of
   NSLayoutAnchor) and the NSCopying / NSCoding conformance.  These structural
   facts match Apple AppKit (verified on a macOS runner) and pass on unmodified
   GNUstep.  They need no backend. */
#import "Testing.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSLayoutAnchor.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  PASS([NSLayoutDimension isSubclassOfClass: [NSLayoutAnchor class]],
       "NSLayoutDimension is a subclass of NSLayoutAnchor");
  PASS([NSLayoutXAxisAnchor isSubclassOfClass: [NSLayoutAnchor class]],
       "NSLayoutXAxisAnchor is a subclass of NSLayoutAnchor");
  PASS([NSLayoutYAxisAnchor isSubclassOfClass: [NSLayoutAnchor class]],
       "NSLayoutYAxisAnchor is a subclass of NSLayoutAnchor");

  PASS([NSLayoutAnchor conformsToProtocol: @protocol(NSCopying)],
       "NSLayoutAnchor conforms to NSCopying");
  PASS([NSLayoutAnchor conformsToProtocol: @protocol(NSCoding)],
       "NSLayoutAnchor conforms to NSCoding");

  DESTROY(arp);
  return 0;
}
