#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSColorPanel.h>
#import <AppKit/NSGraphics.h>

/* NSColorPanel state: the shared panel, its picker mode, alpha, accessory view
   and colour, and their round-trips.  Building the shared panel needs a window
   server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSColorPanel config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSColorPanel *cp;

      PASS([NSColorPanel sharedColorPanelExists] == NO,
        "the shared color panel does not exist before it is asked for");
      cp = [NSColorPanel sharedColorPanel];
      PASS(cp != nil && [NSColorPanel sharedColorPanelExists] == YES,
        "asking for the shared color panel creates it");

      /* defaults */
      PASS([cp mode] == NSWheelModeColorPanel,
        "the default picker mode is the color wheel");
      PASS([cp accessoryView] == nil, "there is no accessory view by default");
      PASS([cp alpha] == 1.0, "the default color is fully opaque");

      /* mode round-trip (by symbol) */
      [cp setMode: NSRGBModeColorPanel];
      PASS([cp mode] == NSRGBModeColorPanel, "the picker mode round-trips to RGB");

      /* continuous / showsAlpha round-trips */
      [cp setContinuous: NO];
      PASS([cp isContinuous] == NO, "continuous round-trips to NO");
      [cp setContinuous: YES];
      PASS([cp isContinuous] == YES, "continuous round-trips to YES");

      [cp setShowsAlpha: YES];
      PASS([cp showsAlpha] == YES, "showsAlpha round-trips to YES");
      [cp setShowsAlpha: NO];
      PASS([cp showsAlpha] == NO, "showsAlpha round-trips to NO");

      /* colour round-trip (with alpha shown so the alpha survives) */
      [cp setShowsAlpha: YES];
      [cp setColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.0
                                               blue: 0.0 alpha: 0.5]];
      {
        NSColor *c = [[cp color]
          colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
        PASS([c redComponent] == 1.0 && [c greenComponent] == 0.0
          && [c blueComponent] == 0.0,
          "the set color round-trips its components");
        PASS([c alphaComponent] == 0.5 && [cp alpha] == 0.5,
          "the set color round-trips its alpha");
      }

      /* accessory view round-trip */
      {
        NSView *av = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 40, 20)]);
        [cp setAccessoryView: av];
        PASS([cp accessoryView] == av, "the accessory view round-trips");
        [cp setAccessoryView: nil];
        PASS([cp accessoryView] == nil, "the accessory view can be cleared");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSColorPanel config")
  DESTROY(arp);
  return 0;
}
