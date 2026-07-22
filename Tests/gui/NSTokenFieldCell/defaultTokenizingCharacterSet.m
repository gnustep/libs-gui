/* A new token field cell starts with the class's default tokenizing character
 * set, so that it tokenizes without being told what to tokenize on.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTokenFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the default tokenizing character set")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTokenFieldCell	*cell;
    NSCharacterSet	*set;
    NSCharacterSet	*semicolons;

    cell = AUTORELEASE([[NSTokenFieldCell alloc] initTextCell: @"token"]);
    set = [cell tokenizingCharacterSet];
    PASS(set != nil, "a new cell has a tokenizing character set");
    PASS([set characterIsMember: ','] == YES,
      "a new cell tokenizes on a comma");
    PASS([cell completionDelay] == [NSTokenFieldCell defaultCompletionDelay],
      "a new cell has the default completion delay");

    cell = AUTORELEASE([[NSTokenFieldCell alloc] init]);
    PASS([cell tokenizingCharacterSet] != nil,
      "a cell made with init has a tokenizing character set");

    /* and it is still whatever it is set to */
    semicolons = [NSCharacterSet characterSetWithCharactersInString: @";"];
    [cell setTokenizingCharacterSet: semicolons];
    PASS([cell tokenizingCharacterSet] == semicolons,
      "the tokenizing character set round-trips");
  }

  END_SET("the default tokenizing character set")

  DESTROY(arp);
  return 0;
}
