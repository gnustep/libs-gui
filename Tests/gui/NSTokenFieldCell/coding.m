/* A token field cell carries its token style, completion delay and tokenizing
 * character set through an archive, keyed or old style.
 */
#include "Testing.h"

#include <Foundation/NSArchiver.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTokenFieldCell.h>

static NSTokenFieldCell *
cellToArchive(void)
{
  NSTokenFieldCell	*cell;

  cell = AUTORELEASE([[NSTokenFieldCell alloc] initTextCell: @"token"]);
  [cell setTokenStyle: NSRoundedTokenStyle];
  [cell setCompletionDelay: 2.5];
  [cell setTokenizingCharacterSet:
    [NSCharacterSet characterSetWithCharactersInString: @";"]];
  return cell;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("coding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTokenFieldCell	*decoded;
    NSData		*data;

    /* keyed */
    data = [NSKeyedArchiver archivedDataWithRootObject: cellToArchive()];
    decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    PASS(decoded != nil, "the cell comes back from a keyed archive");
    PASS([decoded tokenStyle] == NSRoundedTokenStyle,
      "the archived cell keeps its token style");
    PASS([decoded completionDelay] == 2.5,
      "the archived cell keeps its completion delay");
    PASS([decoded tokenizingCharacterSet] != nil
      && [[decoded tokenizingCharacterSet] characterIsMember: ';'],
      "the archived cell keeps its tokenizing character set");

    /* old style */
    data = [NSArchiver archivedDataWithRootObject: cellToArchive()];
    decoded = [NSUnarchiver unarchiveObjectWithData: data];

    PASS(decoded != nil, "the cell comes back from an old style archive");
    PASS([decoded tokenStyle] == NSRoundedTokenStyle,
      "the old style archived cell keeps its token style");
    PASS([decoded completionDelay] == 2.5,
      "the old style archived cell keeps its completion delay");
    PASS([decoded tokenizingCharacterSet] != nil
      && [[decoded tokenizingCharacterSet] characterIsMember: ';'],
      "the old style archived cell keeps its tokenizing character set");
  }

  END_SET("coding")

  DESTROY(arp);
  return 0;
}
