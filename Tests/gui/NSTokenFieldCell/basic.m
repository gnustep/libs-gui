/* Coverage for NSTokenFieldCell: the token style enumeration, the class
 * defaults, the init defaults and the setter round-trips.  Every assertion here
 * matches AppKit (verified on a macOS runner) and passes on unmodified GNUstep.
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

  START_SET("NSTokenFieldCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTokenFieldCell	*cell;
    NSCharacterSet	*defaultSet;
    NSCharacterSet	*semicolons;

    /* the enumeration */
    PASS(NSDefaultTokenStyle == 0 && NSPlainTextTokenStyle == 1
      && NSRoundedTokenStyle == 2,
      "the token styles have their AppKit values");

    /* class defaults */
    PASS([NSTokenFieldCell defaultCompletionDelay] == 0,
      "the default completion delay is none");
    defaultSet = [NSTokenFieldCell defaultTokenizingCharacterSet];
    PASS(defaultSet != nil, "there is a default tokenizing character set");
    PASS([defaultSet characterIsMember: ','] == YES,
      "the default tokenizing character set tokenizes on a comma");
    PASS([defaultSet characterIsMember: ';'] == NO,
      "the default tokenizing character set does not tokenize on a semicolon");

    /* init defaults */
    cell = AUTORELEASE([[NSTokenFieldCell alloc] initTextCell: @"token"]);
    PASS(cell != nil, "a token field cell is created");
    PASS([cell tokenStyle] == NSDefaultTokenStyle,
      "a new cell has the default token style");
    PASS([cell completionDelay] == 0, "a new cell has no completion delay");

    /* setter round-trips */
    semicolons = [NSCharacterSet characterSetWithCharactersInString: @";"];
    [cell setTokenStyle: NSRoundedTokenStyle];
    [cell setCompletionDelay: 2.5];
    [cell setTokenizingCharacterSet: semicolons];
    PASS([cell tokenStyle] == NSRoundedTokenStyle,
      "the token style round-trips");
    PASS([cell completionDelay] == 2.5, "the completion delay round-trips");
    PASS([cell tokenizingCharacterSet] == semicolons,
      "the tokenizing character set reads back");
  }

  END_SET("NSTokenFieldCell basic")

  DESTROY(arp);
  return 0;
}
