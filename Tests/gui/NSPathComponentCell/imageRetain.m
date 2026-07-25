/* NSPathComponentCell keeps the same image object rather than copying it, as
   AppKit does (its image is a retained, not copied, property). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSPathComponentCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSPathComponentCell *cell;
  NSImage *img;

  START_SET("NSPathComponentCell imageRetain")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSPathComponentCell alloc] init]);
  img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  [cell setImage: img];
  PASS([cell image] == img, "setImage: keeps the same image object");

  END_SET("NSPathComponentCell imageRetain")

  DESTROY(arp);
  return 0;
}
