/* A text alternatives object has no meaning without the text the alternatives
 * are for, so a nil primary string raises rather than building an object whose
 * primaryString is nil.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSTextAlternatives.h>

int
main(int argc, char **argv)
{
  START_SET("a nil primary string")
    NSArray		*alternatives;
    NSTextAlternatives	*alt;

    alternatives = [NSArray arrayWithObject: @"color"];

    PASS_EXCEPTION(({
      AUTORELEASE([[NSTextAlternatives alloc]
        initWithPrimaryString: nil
           alternativeStrings: alternatives]);
    }), NSInvalidArgumentException,
      "a nil primary string raises NSInvalidArgumentException");

    /* A primary string with no alternatives is still a usable object. */
    alt = nil;
    PASS_RUNS(({
      alt = AUTORELEASE([[NSTextAlternatives alloc]
        initWithPrimaryString: @"colour"
           alternativeStrings: nil]);
    }), "a nil alternative strings array does not raise");
    PASS([[alt primaryString] isEqualToString: @"colour"],
      "the primary string reads back when there are no alternatives");
  END_SET("a nil primary string")

  return 0;
}
