#import "Testing.h"
#import <AppKit/NSVisualEffectView.h>

/* NSVisualEffectView default state: a fresh view uses the appearance-based
   material, blends behind the window, follows the window's active state and
   has no mask image.  These are plain properties and do not need a window
   server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSVisualEffectView *v = AUTORELEASE([[NSVisualEffectView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)]);

  PASS([v material] == NSVisualEffectMaterialAppearanceBased,
    "the default material is appearance based");
  PASS([v blendingMode] == NSVisualEffectBlendingModeBehindWindow,
    "the default blending mode is behind the window");
  PASS([v state] == NSVisualEffectStateFollowsWindowActiveState,
    "the default state follows the window's active state");
  PASS([v interiorBackgroundStyle] == 0,
    "the interior background style starts at zero");
  PASS([v maskImage] == nil, "there is no mask image by default");

  DESTROY(arp);
  return 0;
}
