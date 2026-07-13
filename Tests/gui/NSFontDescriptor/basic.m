/* Coverage for NSFontDescriptor: the attribute round-trip, the point size,
 * postscript name and matrix extractors, and the descriptor derivation
 * methods.  These operate on the attribute dictionary and need no backend.
 *
 * The symbolic traits and the postscript name of an attribute-less descriptor
 * depend on resolving the descriptor against the font system, which this
 * class does not do, so they are not covered here.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSFontDescriptor.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Helvetica", NSFontNameAttribute,
    [NSNumber numberWithDouble: 12.0], NSFontSizeAttribute, nil];

  START_SET("attributes and extractors")
    NSFontDescriptor *fd =
      [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];

    PASS([[fd objectForKey: NSFontNameAttribute] isEqualToString: @"Helvetica"],
      "objectForKey: reads an attribute");
    PASS([[fd fontAttributes] count] == 2, "fontAttributes returns the dictionary");
    PASS(EQ([fd pointSize], 12.0), "pointSize reads the size attribute");
    PASS([[fd postscriptName] isEqualToString: @"Helvetica"],
      "postscriptName is the name attribute");
    PASS([fd matrix] == nil, "matrix is nil when there is no matrix attribute");
  END_SET("attributes and extractors")

  START_SET("extractor defaults")
    NSFontDescriptor *e =
      [NSFontDescriptor fontDescriptorWithFontAttributes: [NSDictionary dictionary]];

    PASS([[e fontAttributes] count] == 0, "an empty descriptor has no attributes");
    PASS(EQ([e pointSize], 0.0), "pointSize is zero when the size is absent");
    PASS([e matrix] == nil, "matrix is nil when absent");
  END_SET("extractor defaults")

  START_SET("postscriptName strips spaces")
    NSFontDescriptor *fd = [NSFontDescriptor fontDescriptorWithFontAttributes:
      [NSDictionary dictionaryWithObject: @"Helvetica Neue"
                                  forKey: NSFontNameAttribute]];

    PASS([[fd postscriptName] isEqualToString: @"HelveticaNeue"],
      "postscriptName removes spaces from the name");
  END_SET("postscriptName strips spaces")

  START_SET("initWithFontAttributes: nil")
    NSFontDescriptor *fd =
      AUTORELEASE([[NSFontDescriptor alloc] initWithFontAttributes: nil]);

    PASS([fd fontAttributes] != nil && [[fd fontAttributes] count] == 0,
      "a nil attribute dictionary gives an empty descriptor");
  END_SET("initWithFontAttributes: nil")

  START_SET("fontDescriptorWithSize: derives a new descriptor")
    NSFontDescriptor *fd =
      [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];
    NSFontDescriptor *sized = [fd fontDescriptorWithSize: 24.0];

    PASS(sized != fd, "the derived descriptor is a distinct object");
    PASS(EQ([sized pointSize], 24.0), "the derived descriptor has the new size");
    PASS(EQ([fd pointSize], 12.0), "the original descriptor is unchanged");
    PASS([[sized objectForKey: NSFontNameAttribute] isEqualToString: @"Helvetica"],
      "the derived descriptor keeps the other attributes");
  END_SET("fontDescriptorWithSize: derives a new descriptor")

  START_SET("fontDescriptorByAddingAttributes: merges")
    NSFontDescriptor *fd =
      [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];
    NSFontDescriptor *merged = [fd fontDescriptorByAddingAttributes:
      [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble: 18.0], NSFontSizeAttribute,
        @"Arial", NSFontFamilyAttribute, nil]];

    PASS(EQ([merged pointSize], 18.0), "an added attribute overrides the old one");
    PASS([[merged objectForKey: NSFontFamilyAttribute] isEqualToString: @"Arial"],
      "a new attribute is added");
    PASS([[merged objectForKey: NSFontNameAttribute] isEqualToString: @"Helvetica"],
      "the untouched attributes are kept");
  END_SET("fontDescriptorByAddingAttributes: merges")

  START_SET("fontDescriptorWithFamily:")
    NSFontDescriptor *fd =
      [NSFontDescriptor fontDescriptorWithFontAttributes: attrs];
    NSFontDescriptor *fam = [fd fontDescriptorWithFamily: @"Courier"];

    PASS([[fam objectForKey: NSFontFamilyAttribute] isEqualToString: @"Courier"],
      "fontDescriptorWithFamily: adds the family attribute");
  END_SET("fontDescriptorWithFamily:")

  DESTROY(arp);
  return 0;
}
