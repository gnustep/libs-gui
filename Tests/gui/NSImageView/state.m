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
      pass([iv image] == nil, "a new image view has no image");
      pass([iv imageAlignment] == NSImageAlignCenter,
           "the default alignment is centre");
      pass([iv imageFrameStyle] == NSImageFrameNone,
           "the default frame style is none");
      pass([iv isEditable] == NO, "an image view is not editable by default");
      pass([iv allowsCutCopyPaste] == YES,
           "cut, copy and paste are allowed by default");

      /* Round-trips. */
      [iv setImageAlignment: NSImageAlignTop];
      pass([iv imageAlignment] == NSImageAlignTop, "setImageAlignment: round trips");
      [iv setImageScaling: NSImageScaleNone];
      pass([iv imageScaling] == NSImageScaleNone, "setImageScaling: round trips");
      [iv setImageFrameStyle: NSImageFramePhoto];
      pass([iv imageFrameStyle] == NSImageFramePhoto,
           "setImageFrameStyle: round trips");
      [iv setEditable: YES];
      pass([iv isEditable] == YES, "setEditable: round trips");

      /* Image round-trip. */
      NSImage *img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
      [iv setImage: img];
      pass([iv image] == img, "setImage: keeps the image");

      /* +imageViewWithImage: builds a non-editable view holding the image. */
      NSImageView *iv2 = [NSImageView imageViewWithImage: img];
      pass([iv2 image] == img, "+imageViewWithImage: sets the image");
      pass([iv2 isEditable] == NO,
           "+imageViewWithImage: makes a non-editable view");
      pass([iv2 imageFrameStyle] == NSImageFrameNone,
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
