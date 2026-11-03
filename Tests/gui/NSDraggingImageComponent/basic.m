/* Coverage for NSDraggingImageComponent, which needs no window server: the
   icon and label key constants, the key a component is created with, the nil
   contents and zero frame of a new component, and the key, frame and contents
   round-trips.  Every assertion here matches AppKit (verified on a macOS
   runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSDraggingItem.h>
#include <AppKit/NSImage.h>

int main()
{
  START_SET("NSDraggingImageComponent basic")
  NSDraggingImageComponent *c;
  NSImage *image;

  PASS([NSDraggingImageComponentIconKey isEqualToString: @"icon"],
       "NSDraggingImageComponentIconKey is \"icon\"");
  PASS([NSDraggingImageComponentLabelKey isEqualToString: @"label"],
       "NSDraggingImageComponentLabelKey is \"label\"");

  c = [NSDraggingImageComponent
        draggingImageComponentWithKey: NSDraggingImageComponentIconKey];
  PASS(c != nil, "+draggingImageComponentWithKey: returns an instance");
  PASS([[c key] isEqualToString: NSDraggingImageComponentIconKey],
       "the component keeps the key it was created with");
  PASS([c contents] == nil, "a new component has no contents");
  PASS(NSEqualRects([c frame], NSZeroRect), "a new component has a zero frame");

  c = AUTORELEASE([[NSDraggingImageComponent alloc] initWithKey: @"custom"]);
  PASS([[c key] isEqualToString: @"custom"], "initWithKey: keeps the key");

  [c setKey: NSDraggingImageComponentLabelKey];
  PASS([[c key] isEqualToString: NSDraggingImageComponentLabelKey],
       "the key round-trips");

  [c setFrame: NSMakeRect(1, 2, 3, 4)];
  PASS(NSEqualRects([c frame], NSMakeRect(1, 2, 3, 4)), "the frame round-trips");

  image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(10, 10)]);
  [c setContents: image];
  PASS([c contents] == image, "the contents round-trip");

  END_SET("NSDraggingImageComponent basic")
  return 0;
}
