/* Coverage for NSImageView configuration: the defaults (no image, centre
   alignment, no frame, not editable, cut/copy/paste allowed), the alignment,
   scaling and frame-style round-trips, the image round-trip and the
   +imageViewWithImage: constructor.  Checked against AppKit on a macOS runner
   (alignment, scaling and frame style are compared by their enumerated names).
   The view uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImage.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSImageView *iv;

  START_SET("NSImageView state")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      iv = AUTORELEASE([[NSImageView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 80)]);

      /* Defaults. */
      PASS([iv image] == nil, "a new image view has no image");
      PASS([iv imageAlignment] == NSImageAlignCenter,
           "the default alignment is centre");
      PASS([iv imageFrameStyle] == NSImageFrameNone,
           "the default frame style is none");
      PASS([iv isEditable] == NO, "an image view is not editable by default");
      PASS([iv allowsCutCopyPaste] == YES,
           "cut, copy and paste are allowed by default");

      /* Round-trips. */
      [iv setImageAlignment: NSImageAlignTop];
      PASS([iv imageAlignment] == NSImageAlignTop, "setImageAlignment: round trips");
      [iv setImageScaling: NSImageScaleNone];
      PASS([iv imageScaling] == NSImageScaleNone, "setImageScaling: round trips");
      [iv setImageFrameStyle: NSImageFramePhoto];
      PASS([iv imageFrameStyle] == NSImageFramePhoto,
           "setImageFrameStyle: round trips");
      [iv setEditable: YES];
      PASS([iv isEditable] == YES, "setEditable: round trips");

      /* Image round-trip. */
      NSImage *img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
      [iv setImage: img];
      PASS([iv image] == img, "setImage: keeps the image");

      /* +imageViewWithImage: builds a non-editable view holding the image. */
      NSImageView *iv2 = [NSImageView imageViewWithImage: img];
      PASS([iv2 image] == img, "+imageViewWithImage: sets the image");
      PASS([iv2 isEditable] == NO,
           "+imageViewWithImage: makes a non-editable view");
      PASS([iv2 imageFrameStyle] == NSImageFrameNone,
           "+imageViewWithImage: uses no frame");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSImageView state")

  DESTROY(arp);
  return 0;
}
