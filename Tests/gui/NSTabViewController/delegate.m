#import "Testing.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabViewController.h>

/* NSTabViewController acts as its tab view's delegate and its toolbar's data
   source.  These answers are plain and do not need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);

  PASS([tc tabView: nil shouldSelectTabViewItem: nil] == YES,
    "the controller allows any tab to be selected");

  PASS([tc toolbarAllowedItemIdentifiers: nil] != nil
    && [[tc toolbarAllowedItemIdentifiers: nil] count] == 0,
    "the allowed toolbar identifiers start empty");
  PASS([tc toolbarSelectableItemIdentifiers: nil] != nil
    && [[tc toolbarSelectableItemIdentifiers: nil] count] == 0,
    "the selectable toolbar identifiers start empty");

  DESTROY(arp);
  return 0;
}
