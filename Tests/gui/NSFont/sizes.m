/* Coverage for the standard system font sizes.  The absolute point sizes are a
 * platform metric (and are read from user defaults), so only the structural
 * relationships that hold across platforms are asserted here: the regular and
 * small control sizes track the system and small-system sizes, the control
 * sizes are ordered mini < small < regular, and every size is positive.  These
 * need no font backend.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSCell.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  CGFloat system = [NSFont systemFontSize];
  CGFloat small = [NSFont smallSystemFontSize];
  CGFloat label = [NSFont labelFontSize];
  CGFloat mini = [NSFont systemFontSizeForControlSize: NSMiniControlSize];
  CGFloat cSmall = [NSFont systemFontSizeForControlSize: NSSmallControlSize];
  CGFloat cRegular = [NSFont systemFontSizeForControlSize: NSRegularControlSize];

  START_SET("system font sizes")
    PASS(system > 0, "the system font size is positive");
    PASS(small > 0, "the small system font size is positive");
    PASS(label > 0, "the label font size is positive");
    PASS(small < system, "the small system font size is below the system size");
  END_SET("system font sizes")

  START_SET("control sizes")
    PASS(EQ(cRegular, system),
      "the regular control size is the system font size");
    PASS(EQ(cSmall, small),
      "the small control size is the small system font size");
    PASS(mini > 0, "the mini control size is positive");
    PASS(mini < cSmall && cSmall < cRegular,
      "the control sizes are ordered mini < small < regular");
  END_SET("control sizes")

  DESTROY(arp);
  return 0;
}
