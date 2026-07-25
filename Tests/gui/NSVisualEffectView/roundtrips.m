#import "Testing.h"
#import <AppKit/NSImage.h>
#import <AppKit/NSVisualEffectView.h>

/* NSVisualEffectView remembers the material, blending mode, state and mask
   image it is given.  These are plain properties and do not need a window
   server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSVisualEffectView *v = AUTORELEASE([[NSVisualEffectView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSImage *img = AUTORELEASE([[NSImage alloc]
    initWithSize: NSMakeSize(8, 8)]);

  [v setMaterial: NSVisualEffectMaterialSidebar];
  PASS([v material] == NSVisualEffectMaterialSidebar,
    "the material round-trips");
  [v setMaterial: NSVisualEffectMaterialTitlebar];
  PASS([v material] == NSVisualEffectMaterialTitlebar,
    "the material round-trips to another value");

  [v setBlendingMode: NSVisualEffectBlendingModeWithinWindow];
  PASS([v blendingMode] == NSVisualEffectBlendingModeWithinWindow,
    "the blending mode round-trips");

  [v setState: NSVisualEffectStateActive];
  PASS([v state] == NSVisualEffectStateActive, "the state round-trips");
  [v setState: NSVisualEffectStateInactive];
  PASS([v state] == NSVisualEffectStateInactive,
    "the state round-trips to another value");

  [v setMaskImage: img];
  PASS([v maskImage] == img, "the mask image round-trips");
  [v setMaskImage: nil];
  PASS([v maskImage] == nil, "the mask image can be cleared");

  DESTROY(arp);
  return 0;
}
