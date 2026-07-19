/* An appearance survives being archived, through a keyed archive as well as an
 * old style one.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSAppearance.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("keyed coding")
    NSAppearance	*appearance;
    NSAppearance	*decoded;
    NSData		*data;

    appearance = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    data = [NSKeyedArchiver archivedDataWithRootObject: appearance];
    PASS(data != nil && [data length] > 0, "the appearance archives");

    decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    PASS(decoded != nil, "the appearance comes back");
    PASS([[decoded name] isEqualToString: NSAppearanceNameDarkAqua],
      "the archived appearance keeps its name");
  END_SET("keyed coding")

  START_SET("old style coding")
    NSAppearance	*appearance;
    NSAppearance	*decoded;
    NSData		*data;

    appearance = [NSAppearance appearanceNamed: NSAppearanceNameAqua];
    data = [NSArchiver archivedDataWithRootObject: appearance];
    decoded = [NSUnarchiver unarchiveObjectWithData: data];
    PASS(decoded != nil, "the appearance comes back from an old style archive");
    PASS([[decoded name] isEqualToString: NSAppearanceNameAqua],
      "the old style archived appearance keeps its name");
  END_SET("old style coding")

  DESTROY(arp);
  return 0;
}
