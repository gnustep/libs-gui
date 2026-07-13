/* Coverage for NSTextTab: the type/alignment mappings in both directions,
 * the accessors, compare:, isEqual:, hash and copying.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCharacterSet.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSText.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("initWithType:location: maps type to alignment")
    NSTextTab	*t;

    t = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
				location: 50.0]);
    PASS(EQ([t location], 50.0), "the location is stored");
    PASS(NSLeftTabStopType == [t tabStopType], "the tab stop type is stored");
    PASS(NSLeftTextAlignment == [t alignment],
      "a left tab has left alignment");

    t = AUTORELEASE([[NSTextTab alloc] initWithType: NSRightTabStopType
				location: 10.0]);
    PASS(NSRightTextAlignment == [t alignment],
      "a right tab has right alignment");

    t = AUTORELEASE([[NSTextTab alloc] initWithType: NSCenterTabStopType
				location: 10.0]);
    PASS(NSCenterTextAlignment == [t alignment],
      "a center tab has center alignment");

    t = AUTORELEASE([[NSTextTab alloc] initWithType: NSDecimalTabStopType
				location: 10.0]);
    PASS(NSDecimalTabStopType == [t tabStopType],
      "a decimal tab keeps the decimal type");
    PASS(NSNaturalTextAlignment == [t alignment],
      "a decimal tab has natural alignment");
  END_SET("initWithType:location: maps type to alignment")

  START_SET("initWithTextAlignment:location:options: maps alignment to type")
    NSTextTab		*t;
    NSDictionary	*terminators;

    t = AUTORELEASE([[NSTextTab alloc] initWithTextAlignment: NSLeftTextAlignment
					 location: 20.0
					  options: nil]);
    PASS(NSLeftTabStopType == [t tabStopType]
      && NSLeftTextAlignment == [t alignment] && EQ([t location], 20.0),
      "a left-aligned tab is a left tab stop");

    t = AUTORELEASE([[NSTextTab alloc] initWithTextAlignment: NSCenterTextAlignment
					 location: 20.0
					  options: nil]);
    PASS(NSCenterTabStopType == [t tabStopType],
      "a center-aligned tab is a center tab stop");

    t = AUTORELEASE([[NSTextTab alloc] initWithTextAlignment: NSRightTextAlignment
					 location: 20.0
					  options: nil]);
    PASS(NSRightTabStopType == [t tabStopType],
      "a right-aligned tab with no terminators is a right tab stop");

    t = AUTORELEASE([[NSTextTab alloc] initWithTextAlignment: NSJustifiedTextAlignment
					 location: 20.0
					  options: nil]);
    PASS(NSLeftTabStopType == [t tabStopType],
      "a justified tab is a left tab stop");
    PASS(NSJustifiedTextAlignment == [t alignment],
      "a justified tab keeps its alignment");

    terminators = [NSDictionary dictionaryWithObject:
      [NSCharacterSet characterSetWithCharactersInString: @"."]
      forKey: NSTabColumnTerminatorsAttributeName];
    t = AUTORELEASE([[NSTextTab alloc] initWithTextAlignment: NSRightTextAlignment
					 location: 20.0
					  options: terminators]);
    PASS(NSRightTabStopType == [t tabStopType],
      "a right-aligned tab with terminators is still a right tab stop");
    PASS(NSRightTextAlignment == [t alignment],
      "a tab created with terminators keeps its alignment");
    PASS([t options] != nil && [[t options]
      objectForKey: NSTabColumnTerminatorsAttributeName] != nil,
      "the options are stored");
  END_SET("initWithTextAlignment:location:options: maps alignment to type")

  START_SET("compare: orders by location")
    NSTextTab	*a = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
					     location: 10.0]);
    NSTextTab	*b = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
					     location: 20.0]);
    NSTextTab	*c = AUTORELEASE([[NSTextTab alloc] initWithType: NSRightTabStopType
					     location: 10.0]);

    PASS(NSOrderedAscending == [a compare: b],
      "an earlier tab compares ascending");
    PASS(NSOrderedDescending == [b compare: a],
      "a later tab compares descending");
    PASS(NSOrderedSame == [a compare: c],
      "tabs at the same location compare the same");
    PASS(NSOrderedSame == [a compare: a], "a tab compares same with itself");
  END_SET("compare: orders by location")

  START_SET("isEqual: and hash")
    NSTextTab	*a = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
					     location: 10.0]);
    NSTextTab	*b = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
					     location: 10.0]);
    NSTextTab	*c = AUTORELEASE([[NSTextTab alloc] initWithType: NSRightTabStopType
					     location: 10.0]);
    NSTextTab	*d = AUTORELEASE([[NSTextTab alloc] initWithType: NSLeftTabStopType
					     location: 99.0]);

    PASS([a isEqual: b], "tabs with the same type and location are equal");
    PASS([a hash] == [b hash], "equal tabs have the same hash");
    PASS(![a isEqual: c], "tabs of different type are not equal");
    PASS(![a isEqual: d], "tabs at different locations are not equal");
  END_SET("isEqual: and hash")

  START_SET("copy")
    NSDictionary	*terminators = [NSDictionary dictionaryWithObject:
      [NSCharacterSet characterSetWithCharactersInString: @"."]
      forKey: NSTabColumnTerminatorsAttributeName];
    NSTextTab		*t = AUTORELEASE([[NSTextTab alloc]
      initWithTextAlignment: NSRightTextAlignment
		   location: 33.0
		    options: terminators]);
    NSTextTab		*c = AUTORELEASE([t copy]);

    PASS(EQ([c location], 33.0) && NSRightTabStopType == [c tabStopType]
      && NSRightTextAlignment == [c alignment],
      "copy preserves location, type and alignment");
    PASS([c options] != nil, "copy preserves the options");
    PASS([c isEqual: t], "the copy is equal to the original");
  END_SET("copy")

  DESTROY(arp);
  return 0;
}
