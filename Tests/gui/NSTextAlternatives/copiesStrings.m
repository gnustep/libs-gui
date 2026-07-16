/* The initialiser copies the strings it is given, as its properties declare, so
 * that mutating the caller's objects afterwards does not show through.  The
 * getters hand back that storage rather than a fresh copy, so each call returns
 * the same object.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSTextAlternatives.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("mutable strings are copied")
    NSMutableString	*primary;
    NSMutableArray	*alternatives;
    NSTextAlternatives	*alt;

    primary = [NSMutableString stringWithString: @"abc"];
    alternatives = [NSMutableArray arrayWithObject: @"x"];
    alt = AUTORELEASE([[NSTextAlternatives alloc]
      initWithPrimaryString: primary
         alternativeStrings: alternatives]);

    PASS([alt primaryString] != (NSString *)primary,
      "the primary string is not the mutable string passed in");
    PASS([alt alternativeStrings] != (NSArray *)alternatives,
      "the alternative strings are not the mutable array passed in");

    [primary appendString: @"DEF"];
    [alternatives addObject: @"y"];

    PASS([[alt primaryString] isEqualToString: @"abc"],
      "mutating the primary string afterwards does not change the copy");
    PASS([[alt alternativeStrings] count] == 1,
      "mutating the alternative strings afterwards does not change the copy");
  END_SET("mutable strings are copied")

  START_SET("the getters return their storage")
    NSMutableString	*primary;
    NSMutableArray	*alternatives;
    NSTextAlternatives	*alt;

    primary = [NSMutableString stringWithString: @"abc"];
    alternatives = [NSMutableArray arrayWithObject: @"x"];
    alt = AUTORELEASE([[NSTextAlternatives alloc]
      initWithPrimaryString: primary
         alternativeStrings: alternatives]);

    PASS([alt primaryString] == [alt primaryString],
      "primaryString returns the same object each time");
    PASS([alt alternativeStrings] == [alt alternativeStrings],
      "alternativeStrings returns the same object each time");
  END_SET("the getters return their storage")

  START_SET("immutable strings are kept")
    NSArray		*alternatives;
    NSTextAlternatives	*alt;

    alternatives = [NSArray arrayWithObject: @"color"];
    alt = AUTORELEASE([[NSTextAlternatives alloc]
      initWithPrimaryString: @"colour"
         alternativeStrings: alternatives]);

    PASS([[alt primaryString] isEqualToString: @"colour"],
      "an immutable primary string reads back");
    PASS([alt alternativeStrings] == alternatives,
      "copying an immutable array keeps the array passed in");
  END_SET("immutable strings are kept")

  DESTROY(arp);
  return 0;
}
