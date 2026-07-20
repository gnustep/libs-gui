/* A frame-initialised NSTokenField constructs without hanging and carries its
   token defaults: the default token style, a zero completion delay and a
   tokenizing character set of a single comma.  The setters round-trip.
   Checked against AppKit on a macOS runner (the token style is compared by
   its enumerated name, whose raw value differs between GNUstep and macOS).
   The field uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSCharacterSet.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTokenField.h>
#include <AppKit/NSTokenFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTokenField *tf;

  START_SET("NSTokenField defaults")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      tf = AUTORELEASE([[NSTokenField alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 22)]);

      /* Defaults. */
      pass([tf tokenStyle] == NSDefaultTokenStyle,
           "the default token style is the default style");
      pass([tf completionDelay] == 0.0, "the default completion delay is zero");
      pass([[tf tokenizingCharacterSet] characterIsMember: ','],
           "the default tokenizing set contains a comma");
      pass([[tf tokenizingCharacterSet] characterIsMember: ' '] == NO,
           "the default tokenizing set does not contain a space");

      /* Setter round-trips. */
      [tf setTokenStyle: NSRoundedTokenStyle];
      pass([tf tokenStyle] == NSRoundedTokenStyle, "setTokenStyle: round trips");
      [tf setCompletionDelay: 0.5];
      pass([tf completionDelay] == 0.5, "setCompletionDelay: round trips");
      [tf setTokenizingCharacterSet:
        [NSCharacterSet characterSetWithCharactersInString: @";"]];
      pass([[tf tokenizingCharacterSet] characterIsMember: ';'],
           "setTokenizingCharacterSet: keeps the new separator");
      pass([[tf tokenizingCharacterSet] characterIsMember: ','] == NO,
           "setTokenizingCharacterSet: replaces the old separator");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSTokenField defaults")

  DESTROY(arp);
  return 0;
}
