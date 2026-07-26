/* -[NSArrayController setSelectionIndexes:] stored a nil index set directly,
   so a later -selectedObjects sent -objectsAtIndexes: nil and raised, and
   -selectionIndex returned 0 rather than NSNotFound.  A nil index set now
   means an empty selection, matching AppKit. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSIndexSet.h>

#include <AppKit/NSArrayController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSArrayController *ac;

  ac = AUTORELEASE([[NSArrayController alloc] init]);
  [ac addObject: @"alpha"];
  [ac addObject: @"bravo"];
  [ac addObject: @"charlie"];

  [ac setSelectionIndex: 1];
  PASS([ac selectionIndex] == 1, "a selection index is set");

  /* Clearing the selection with nil must not raise or leave a nil set. */
  [ac setSelectionIndexes: nil];
  PASS([ac selectionIndex] == NSNotFound,
       "setSelectionIndexes: nil clears the selection index to NSNotFound");
  PASS([[ac selectedObjects] count] == 0,
       "setSelectionIndexes: nil leaves an empty selected-objects array");
  PASS([[ac selectionIndexes] count] == 0,
       "setSelectionIndexes: nil leaves an empty selection index set");

  DESTROY(arp);
  return 0;
}
