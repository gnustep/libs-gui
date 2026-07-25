/* Coverage for NSTreeController defaults and round-trips: a new controller does
   not use the multiple-values marker, can insert, has no children/count/leaf
   key paths, no sort descriptors, and an empty selection and arrangement; the
   key paths and behavior flags round-trip.  Every assertion here matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSTreeController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTreeController *tc;

  tc = AUTORELEASE([[NSTreeController alloc] init]);

  PASS([tc alwaysUsesMultipleValuesMarker] == NO,
       "default alwaysUsesMultipleValuesMarker is NO");
  PASS([tc canInsert] == YES, "a new controller can insert");
  PASS([tc childrenKeyPath] == nil, "default childrenKeyPath is nil");
  PASS([tc countKeyPath] == nil, "default countKeyPath is nil");
  PASS([tc leafKeyPath] == nil, "default leafKeyPath is nil");
  PASS([tc sortDescriptors] == nil || [[tc sortDescriptors] count] == 0,
       "a new controller has no sort descriptors");
  PASS([tc selectionIndexPath] == nil,
       "a new controller has no selection index path");
  PASS([[tc selectionIndexPaths] count] == 0,
       "a new controller has an empty selection");
  PASS([[tc selectedObjects] count] == 0,
       "a new controller has no selected objects");

  [tc setChildrenKeyPath: @"children"];
  PASS([[tc childrenKeyPath] isEqual: @"children"], "childrenKeyPath round-trips");
  [tc setCountKeyPath: @"count"];
  PASS([[tc countKeyPath] isEqual: @"count"], "countKeyPath round-trips");
  [tc setLeafKeyPath: @"isLeaf"];
  PASS([[tc leafKeyPath] isEqual: @"isLeaf"], "leafKeyPath round-trips");

  [tc setAvoidsEmptySelection: NO];
  PASS([tc avoidsEmptySelection] == NO, "avoidsEmptySelection round-trips");
  [tc setPreservesSelection: NO];
  PASS([tc preservesSelection] == NO, "preservesSelection round-trips");
  [tc setSelectsInsertedObjects: NO];
  PASS([tc selectsInsertedObjects] == NO, "selectsInsertedObjects round-trips");
  [tc setAlwaysUsesMultipleValuesMarker: YES];
  PASS([tc alwaysUsesMultipleValuesMarker] == YES,
       "alwaysUsesMultipleValuesMarker round-trips");

  DESTROY(arp);
  return 0;
}
