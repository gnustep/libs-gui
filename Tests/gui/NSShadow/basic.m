/* Coverage for NSShadow: the defaults, the accessors, copying and archiving. */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSKeyedArchiver.h>
#include <AppKit/NSShadow.h>
#include <AppKit/NSColor.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("defaults")
    NSShadow	*s = [[[NSShadow alloc] init] autorelease];
    NSSize	off = [s shadowOffset];

    PASS(EQ(off.width, 0.0) && EQ(off.height, 0.0),
      "the default shadow offset is zero");
    PASS(EQ([s shadowBlurRadius], 0.0), "the default blur radius is zero");
    PASS([s shadowColor] != nil, "there is a default shadow colour");
    PASS(EQ([[s shadowColor] alphaComponent], 0.333),
      "the default shadow colour is a translucent black");
  END_SET("defaults")

  START_SET("accessors round-trip")
    NSShadow	*s = [[[NSShadow alloc] init] autorelease];
    NSSize	off;

    [s setShadowOffset: NSMakeSize(3.0, -4.0)];
    off = [s shadowOffset];
    PASS(EQ(off.width, 3.0) && EQ(off.height, -4.0), "the offset round-trips");

    [s setShadowBlurRadius: 7.5];
    PASS(EQ([s shadowBlurRadius], 7.5), "the blur radius round-trips");

    [s setShadowColor: [NSColor redColor]];
    PASS([[s shadowColor] isEqual: [NSColor redColor]],
      "the shadow colour round-trips");

    [s setShadowColor: nil];
    PASS(nil == [s shadowColor], "the shadow colour can be cleared");
  END_SET("accessors round-trip")

  START_SET("copy is an independent object")
    NSShadow	*s = [[[NSShadow alloc] init] autorelease];
    NSShadow	*c;

    [s setShadowOffset: NSMakeSize(5.0, 6.0)];
    [s setShadowBlurRadius: 2.0];
    [s setShadowColor: [NSColor blueColor]];
    c = [[s copy] autorelease];

    PASS(c != s, "copy is a distinct object");
    PASS(EQ([c shadowOffset].width, 5.0) && EQ([c shadowOffset].height, 6.0)
      && EQ([c shadowBlurRadius], 2.0)
      && [[c shadowColor] isEqual: [NSColor blueColor]],
      "copy preserves the offset, blur radius and colour");

    /* Mutating the copy must not disturb the original. */
    [c setShadowBlurRadius: 99.0];
    [c setShadowColor: [NSColor greenColor]];
    PASS(EQ([s shadowBlurRadius], 2.0),
      "mutating the copy leaves the original blur radius intact");
    PASS([[s shadowColor] isEqual: [NSColor blueColor]],
      "mutating the copy leaves the original colour intact");
  END_SET("copy is an independent object")

  START_SET("keyed archiving round-trip")
    NSShadow	*s = [[[NSShadow alloc] init] autorelease];
    NSData	*data;
    NSShadow	*d;

    [s setShadowOffset: NSMakeSize(8.0, 9.0)];
    [s setShadowBlurRadius: 4.0];
    [s setShadowColor: [NSColor redColor]];
    data = [NSKeyedArchiver archivedDataWithRootObject: s];
    d = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    PASS(d != nil && EQ([d shadowOffset].width, 8.0)
      && EQ([d shadowOffset].height, 9.0) && EQ([d shadowBlurRadius], 4.0),
      "keyed archiving preserves the offset and blur radius");
    PASS([[d shadowColor] isEqual: [NSColor redColor]],
      "keyed archiving preserves the colour");
  END_SET("keyed archiving round-trip")

  START_SET("non-keyed archiving round-trip")
    NSShadow	*s = [[[NSShadow alloc] init] autorelease];
    NSData	*data;
    NSShadow	*d;

    [s setShadowOffset: NSMakeSize(1.0, 2.0)];
    [s setShadowBlurRadius: 3.0];
    [s setShadowColor: [NSColor redColor]];
    data = [NSArchiver archivedDataWithRootObject: s];
    d = [NSUnarchiver unarchiveObjectWithData: data];

    PASS(d != nil && EQ([d shadowOffset].width, 1.0)
      && EQ([d shadowOffset].height, 2.0) && EQ([d shadowBlurRadius], 3.0),
      "non-keyed archiving preserves the offset and blur radius");
    PASS([[d shadowColor] isEqual: [NSColor redColor]],
      "non-keyed archiving preserves the colour");
  END_SET("non-keyed archiving round-trip")

  DESTROY(arp);
  return 0;
}
