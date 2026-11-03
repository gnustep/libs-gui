/* What -[NSTabViewItem setToolTip:] does with the string it is given.

   AppKit declares the property as
     @property (copy, nullable) NSString *toolTip;
   so the item holds a copy, and it gives that copy up when it is released.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTabViewItem.h>

int main()
{
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];
  NSTabViewItem		*item;
  NSMutableString	*mutable;
  NSString		*tip;
  NSUInteger		 before;

  START_SET("NSTabViewItem toolTip memory")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* The property is declared copy, so a string that changes afterwards does
   * not change the tooltip. */
  item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: @"copy"]);
  mutable = [NSMutableString stringWithString: @"one"];
  [item setToolTip: mutable];
  [mutable appendString: @" two"];
  PASS([[item toolTip] isEqual: @"one"],
       "the tooltip is a copy of the string it was given");

  /* An item that is released gives up the tooltip it holds.  The string is
   * made rather than a literal, so its retain count is its own. */
  tip = [[NSString alloc] initWithString: @"a tooltip"];
  before = [tip retainCount];
  item = [[NSTabViewItem alloc] initWithIdentifier: @"release"];
  [item setToolTip: tip];
  PASS([[item toolTip] isEqual: tip], "the tooltip reads back");
  [item release];
  PASS([tip retainCount] == before,
       "releasing the item releases the tooltip it held");
  [tip release];

  END_SET("NSTabViewItem toolTip memory")

  [arp release];
  return 0;
}
