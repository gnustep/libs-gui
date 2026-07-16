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
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("a nil primary string")
    NSArray		*alternatives;
    NSTextAlternatives	*alt;
    BOOL		raised;

    alternatives = [NSArray arrayWithObject: @"color"];

    raised = NO;
    NS_DURING
      alt = AUTORELEASE([[NSTextAlternatives alloc]
        initWithPrimaryString: nil
           alternativeStrings: alternatives]);
    NS_HANDLER
      raised = [[localException name]
        isEqualToString: NSInvalidArgumentException];
    NS_ENDHANDLER
    PASS(raised == YES,
      "a nil primary string raises NSInvalidArgumentException");

    /* A primary string with no alternatives is still a usable object. */
    raised = NO;
    alt = nil;
    NS_DURING
      alt = AUTORELEASE([[NSTextAlternatives alloc]
        initWithPrimaryString: @"colour"
           alternativeStrings: nil]);
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER
    PASS(raised == NO, "a nil alternative strings array does not raise");
    PASS([[alt primaryString] isEqualToString: @"colour"],
      "the primary string reads back when there are no alternatives");
  END_SET("a nil primary string")

  DESTROY(arp);
  return 0;
}
