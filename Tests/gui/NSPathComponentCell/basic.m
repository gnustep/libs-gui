/* Coverage for NSPathComponentCell: the init defaults (image and URL are nil),
   the image and URL setters, and the title round-trip.  Every assertion here
   matches AppKit (verified on a macOS runner) and passes on unmodified
   GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSPathComponentCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSPathComponentCell *cell;
  NSImage *img;
  NSURL *url;

  START_SET("NSPathComponentCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* init defaults */
  cell = AUTORELEASE([[NSPathComponentCell alloc] init]);
  pass([cell image] == nil, "default image is nil");
  pass([cell URL] == nil, "default URL is nil");

  /* image setter */
  img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  [cell setImage: img];
  pass([cell image] != nil, "image is set");
  pass([cell image] != nil
         && [cell image].size.width == 16 && [cell image].size.height == 16,
       "the image keeps its size");

  /* URL setter */
  url = [NSURL fileURLWithPath: @"/tmp/foo"];
  [cell setURL: url];
  pass([cell URL] != nil, "URL is set");
  pass([[cell URL] isEqual: url], "URL round-trips");

  /* title round-trip */
  [cell setTitle: @"MyTitle"];
  pass([[cell title] isEqualToString: @"MyTitle"], "title round-trips");

  END_SET("NSPathComponentCell basic")

  DESTROY(arp);
  return 0;
}
