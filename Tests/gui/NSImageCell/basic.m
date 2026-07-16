/* Coverage for NSImageCell: the NSImageAlignment / NSImageFrameStyle /
   NSImageScaling enum values, the init defaults (centered alignment,
   proportionally-down scaling, no frame, refuses first responder), and the
   imageAlignment / imageScaling / imageFrameStyle setters.  Every assertion was
   checked against Apple AppKit (macOS 26) and matches.  Creating the cell pulls
   in the default font, which needs the backend, so that part is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSImageCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* Enum values match AppKit; these need no backend. */
  PASS(NSImageAlignCenter == 0, "NSImageAlignCenter is 0");
  PASS(NSImageAlignTop == 1, "NSImageAlignTop is 1");
  PASS(NSImageAlignRight == 8, "NSImageAlignRight is 8");
  PASS(NSImageFrameNone == 0, "NSImageFrameNone is 0");
  PASS(NSImageFramePhoto == 1, "NSImageFramePhoto is 1");
  PASS(NSImageFrameButton == 4, "NSImageFrameButton is 4");
  PASS(NSImageScaleProportionallyDown == 0,
       "NSImageScaleProportionallyDown is 0");
  PASS(NSImageScaleNone == 2, "NSImageScaleNone is 2");

  START_SET("NSImageCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSImageCell *c = [[NSImageCell alloc] init];
  PASS(c != nil, "NSImageCell -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([c imageAlignment] == NSImageAlignCenter,
       "default imageAlignment is centered");
  PASS([c imageScaling] == NSImageScaleProportionallyDown,
       "default imageScaling is proportionally down");
  PASS([c imageFrameStyle] == NSImageFrameNone,
       "default imageFrameStyle is none");
  PASS([c refusesFirstResponder] == YES,
       "an image cell refuses first responder");

  /* Setters round-trip. */
  [c setImageAlignment: NSImageAlignTop];
  PASS([c imageAlignment] == NSImageAlignTop, "setImageAlignment: round-trips");

  [c setImageScaling: NSImageScaleNone];
  PASS([c imageScaling] == NSImageScaleNone, "setImageScaling: round-trips");

  [c setImageFrameStyle: NSImageFramePhoto];
  PASS([c imageFrameStyle] == NSImageFramePhoto,
       "setImageFrameStyle: round-trips");

  RELEASE(c);

  END_SET("NSImageCell basic")

  DESTROY(arp);
  return 0;
}
