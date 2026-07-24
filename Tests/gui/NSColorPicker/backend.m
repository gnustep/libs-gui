/* Coverage for NSColorPicker with the window server: -colorPanel reports the
   shared color panel it was created with, and insertNewButtonImage:in: sets the
   image on the button cell.  Matches AppKit (verified on a macOS runner) and
   passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColorPicker.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSImage.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSColorPicker *picker;
  NSColorPanel *panel;
  NSButtonCell *cell;
  NSImage *image;

  START_SET("NSColorPicker backend")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  panel = [NSColorPanel sharedColorPanel];
  picker = AUTORELEASE([[NSColorPicker alloc]
    initWithPickerMask: 0 colorPanel: panel]);
  PASS([picker colorPanel] == panel,
       "colorPanel returns the panel passed to the initializer");

  cell = AUTORELEASE([[NSButtonCell alloc] init]);
  image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  [picker insertNewButtonImage: image in: cell];
  PASS([cell image] == image,
       "insertNewButtonImage:in: sets the image on the button cell");

  END_SET("NSColorPicker backend")

  DESTROY(arp);
  return 0;
}
