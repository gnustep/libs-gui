#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSColorPanel.h>

/* NSColorPanel -mode reports the mode set with -setMode: for each of the
   standard colour-space pickers, not just RGB.  Before the fix the standard
   picker stored its picker mask in place of the mode and -supportsMode: ignored
   its argument, so only RGB round-tripped (by coincidence of mask 2 / mode 1).
   Building the shared panel needs a window server, so the set skips without
   one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSColorPanel picker mode")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSColorPanel *cp = [NSColorPanel sharedColorPanel];

      [cp setMode: NSGrayModeColorPanel];
      PASS([cp mode] == NSGrayModeColorPanel,
        "the picker mode round-trips to gray");

      [cp setMode: NSRGBModeColorPanel];
      PASS([cp mode] == NSRGBModeColorPanel,
        "the picker mode round-trips to RGB");

      [cp setMode: NSCMYKModeColorPanel];
      PASS([cp mode] == NSCMYKModeColorPanel,
        "the picker mode round-trips to CMYK");

      [cp setMode: NSHSBModeColorPanel];
      PASS([cp mode] == NSHSBModeColorPanel,
        "the picker mode round-trips to HSB");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSColorPanel picker mode")
  DESTROY(arp);
  return 0;
}
