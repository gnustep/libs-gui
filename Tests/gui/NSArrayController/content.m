/* Coverage for NSArrayController content handling: added objects appear in the
   arranged objects, sort descriptors order them, and setting a selection index
   selects the object at that position.  Matches AppKit (verified on a macOS
   runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSSortDescriptor.h>
#include <Foundation/NSString.h>

#include <AppKit/NSArrayController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSArrayController *ac;
  NSSortDescriptor *sd;
  NSArray *arranged;

  ac = AUTORELEASE([[NSArrayController alloc] init]);
  [ac addObject: @"charlie"];
  [ac addObject: @"alpha"];
  [ac addObject: @"bravo"];
  PASS([[ac arrangedObjects] count] == 3, "three added objects are arranged");

  sd = AUTORELEASE([[NSSortDescriptor alloc]
    initWithKey: @"self" ascending: YES selector: @selector(compare:)]);
  [ac setSortDescriptors: [NSArray arrayWithObject: sd]];
  [ac rearrangeObjects];
  arranged = [ac arrangedObjects];
  PASS([[arranged objectAtIndex: 0] isEqual: @"alpha"],
       "sort descriptors order the arranged objects (first)");
  PASS([[arranged objectAtIndex: 2] isEqual: @"charlie"],
       "sort descriptors order the arranged objects (last)");
  PASS([[ac sortDescriptors] count] == 1, "sortDescriptors round-trips");

  [ac setSelectionIndex: 1];
  PASS([ac selectionIndex] == 1, "setSelectionIndex round-trips");
  PASS([[ac selectedObjects] count] == 1, "one object is selected");
  PASS([[[ac selectedObjects] objectAtIndex: 0] isEqual: @"bravo"],
       "the selected object is the one at the selection index");

  DESTROY(arp);
  return 0;
}
