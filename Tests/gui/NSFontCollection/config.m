/* Coverage for NSFontCollection: the standard collection name constants are
 * defined and distinct, and a collection built from a descriptor list exposes
 * those descriptors through -queryDescriptors.  Building a collection only
 * manipulates the descriptor dictionary and needs no font backend.
 *
 * The matching descriptors resolve against the installed fonts, so they are
 * environment-specific and are not asserted here.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSFontDescriptor.h>
#include <AppKit/NSFontCollection.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("collection name constants")
    PASS(NSFontCollectionAllFonts != nil, "NSFontCollectionAllFonts is defined");
    PASS(NSFontCollectionUser != nil, "NSFontCollectionUser is defined");
    PASS(NSFontCollectionFavorites != nil, "NSFontCollectionFavorites is defined");
    PASS(NSFontCollectionRecentlyUsed != nil,
      "NSFontCollectionRecentlyUsed is defined");
    PASS(![NSFontCollectionAllFonts isEqualToString: NSFontCollectionUser]
      && ![NSFontCollectionUser isEqualToString: NSFontCollectionFavorites]
      && ![NSFontCollectionFavorites isEqualToString: NSFontCollectionRecentlyUsed],
      "the standard collection names are distinct");
  END_SET("collection name constants")

  START_SET("query descriptors")
    NSFontDescriptor *fd = [NSFontDescriptor fontDescriptorWithFontAttributes:
      [NSDictionary dictionaryWithObject: @"Helvetica"
                                  forKey: NSFontFamilyAttribute]];
    NSFontCollection *fc = [NSFontCollection fontCollectionWithDescriptors:
      [NSArray arrayWithObject: fd]];

    PASS(fc != nil, "fontCollectionWithDescriptors: returns a collection");
    PASS([[fc queryDescriptors] count] == 1,
      "the collection reports its query descriptor");
    PASS([[fc queryDescriptors] containsObject: fd],
      "the query descriptor is the one supplied");

    NSFontCollection *empty = [NSFontCollection fontCollectionWithDescriptors:
      [NSArray array]];
    PASS([[empty queryDescriptors] count] == 0,
      "an empty descriptor list gives no query descriptors");
  END_SET("query descriptors")

  DESTROY(arp);
  return 0;
}
