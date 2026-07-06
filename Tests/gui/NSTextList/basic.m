/* Coverage for NSTextList: the accessors and markerForItemNumber: for the
 * numeric, alphabetic and glyph marker formats.
 */
#include "Testing.h"
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <AppKit/NSTextList.h>

static NSString *
marker(NSString *fmt, int item)
{
  NSTextList	*l = [[[NSTextList alloc] initWithMarkerFormat: fmt
						       options: 0] autorelease];
  return [l markerForItemNumber: item];
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("accessors")
    NSTextList	*l = [[[NSTextList alloc]
      initWithMarkerFormat: @"{decimal}." options: 7] autorelease];

    PASS([[l markerFormat] isEqualToString: @"{decimal}."],
      "markerFormat reads back");
    PASS(7 == [l listOptions], "listOptions reads back");
    PASS(1 == [l startingItemNumber],
      "the starting item number defaults to 1");
    [l setStartingItemNumber: 5];
    PASS(5 == [l startingItemNumber], "the starting item number round-trips");
  END_SET("accessors")

  START_SET("decimal, octal and hexadecimal markers")
    PASS([marker(@"{decimal}", 1) isEqualToString: @"1"],
      "decimal item 1 is 1");
    PASS([marker(@"{decimal}", 42) isEqualToString: @"42"],
      "decimal item 42 is 42");
    PASS([marker(@"{octal}", 8) isEqualToString: @"10"], "octal item 8 is 10");
    PASS([marker(@"{lower-hexadecimal}", 255) isEqualToString: @"ff"],
      "lower hexadecimal item 255 is ff");
    PASS([marker(@"{upper-hexadecimal}", 255) isEqualToString: @"FF"],
      "upper hexadecimal item 255 is FF");
  END_SET("decimal, octal and hexadecimal markers")

  START_SET("the format string surrounds the marker")
    PASS([marker(@"{decimal}.", 3) isEqualToString: @"3."],
      "trailing text is kept");
    PASS([marker(@"({decimal})", 3) isEqualToString: @"(3)"],
      "surrounding text is kept");
  END_SET("the format string surrounds the marker")

  START_SET("alphabetic markers start at the first letter")
    /* Item numbers are 1-based (startingItemNumber defaults to 1), so the
     * first item of an alphabetic list is 'a', matching decimal item 1 = 1. */
    PASS([marker(@"{lower-alpha}", 1) isEqualToString: @"a"],
      "lower-alpha item 1 is a");
    PASS([marker(@"{lower-alpha}", 2) isEqualToString: @"b"],
      "lower-alpha item 2 is b");
    PASS([marker(@"{lower-alpha}", 26) isEqualToString: @"z"],
      "lower-alpha item 26 is z");
    PASS([marker(@"{upper-alpha}", 1) isEqualToString: @"A"],
      "upper-alpha item 1 is A");
    PASS([marker(@"{lower-latin}", 1) isEqualToString: @"a"],
      "lower-latin item 1 is a");
    PASS([marker(@"{upper-latin}", 1) isEqualToString: @"A"],
      "upper-latin item 1 is A");
  END_SET("alphabetic markers start at the first letter")

  START_SET("glyph markers are independent of the item number")
    NSString	*disc = marker(@"{disc}", 1);
    NSString	*check = marker(@"{check}", 7);

    PASS(1 == [disc length] && 0x2022 == [disc characterAtIndex: 0],
      "{disc} is the bullet character");
    PASS(1 == [check length] && 0x2713 == [check characterAtIndex: 0],
      "{check} is the check character");
  END_SET("glyph markers are independent of the item number")

  START_SET("copy")
    NSTextList	*l = [[[NSTextList alloc]
      initWithMarkerFormat: @"{upper-roman}." options: 3] autorelease];
    NSTextList	*c = [[l copy] autorelease];

    PASS(c != nil && [[c markerFormat] isEqualToString: @"{upper-roman}."]
      && 3 == [c listOptions], "copy preserves the marker format and options");
  END_SET("copy")

  DESTROY(arp);
  return 0;
}
