/* Regression test: the mutating methods of NSMutableFontCollection work on a
 * collection obtained through +fontCollectionWithDescriptors: (which builds the
 * mutable collection by copying an immutable one).  The mutating calls are
 * evaluated inside PASS so that, should they raise, the failure is reported
 * rather than aborting the process.  This needs no font backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSFontDescriptor.h>
#include <AppKit/NSFontCollection.h>

int
main(int argc, char **argv)
{
  START_SET("query and exclusion descriptors")
    NSFontDescriptor *fd = [NSFontDescriptor fontDescriptorWithFontAttributes:
      [NSDictionary dictionaryWithObject: @"Helvetica" forKey: NSFontFamilyAttribute]];
    NSFontDescriptor *fd2 = [NSFontDescriptor fontDescriptorWithFontAttributes:
      [NSDictionary dictionaryWithObject: @"Courier" forKey: NSFontFamilyAttribute]];

    NSMutableFontCollection *mc = [NSMutableFontCollection
      fontCollectionWithDescriptors: [NSArray arrayWithObject: fd]];

    PASS(([mc setQueryDescriptors: [NSArray arrayWithObjects: fd, fd2, nil]],
          [[mc queryDescriptors] count] == 2),
      "setQueryDescriptors: replaces the query descriptors");
    PASS(([mc setExclusionDescriptors: [NSArray arrayWithObject: fd2]],
          [[mc exclusionDescriptors] count] == 1
          && [[mc exclusionDescriptors] containsObject: fd2]),
      "setExclusionDescriptors: stores the exclusion descriptors");

    NSMutableFontCollection *mc2 = [NSMutableFontCollection
      fontCollectionWithDescriptors: [NSArray array]];

    PASS(([mc2 addQueryForDescriptors: [NSArray arrayWithObject: fd]],
          [[mc2 queryDescriptors] count] == 1
          && [[mc2 queryDescriptors] containsObject: fd]),
      "addQueryForDescriptors: adds to the query");
    PASS(([mc2 removeQueryForDescriptors: [NSArray arrayWithObject: fd]],
          [[mc2 queryDescriptors] count] == 0),
      "removeQueryForDescriptors: removes from the query");
  END_SET("query and exclusion descriptors")

  return 0;
}
