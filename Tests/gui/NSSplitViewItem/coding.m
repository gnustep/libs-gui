/* Coverage for NSSplitViewItem archiving: an item survives a keyed archive and
   unarchive round-trip, decoding back to an NSSplitViewItem.  Passes on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewItem.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitViewItem *item;
  NSSplitViewItem *decoded;
  NSData *data;

  item = [NSSplitViewItem splitViewItemWithViewController: nil];
  data = [NSKeyedArchiver archivedDataWithRootObject: item];
  PASS(data != nil && [data length] > 0,
       "an item archives to non-empty data");

  decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  PASS([decoded isKindOfClass: [NSSplitViewItem class]],
       "the archive decodes to an NSSplitViewItem");
  PASS([decoded viewController] == nil,
       "a nil view controller survives the round-trip");

  DESTROY(arp);
  return 0;
}
