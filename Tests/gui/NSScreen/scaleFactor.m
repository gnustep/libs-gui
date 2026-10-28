#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "../GSFakeScreens.h"

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSScreen scale factor per screen")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      {
        SKIP("It looks like GNUstep backend is not yet installed")
      }
  NS_ENDHANDLER

  {
    NSArray *frames = [NSArray arrayWithObjects:
      [NSValue valueWithRect: NSMakeRect(0, 0, 1000, 800)],
      [NSValue valueWithRect: NSMakeRect(1000, 0, 1000, 800)], nil];
    GSFakeScreens *fake;
    NSArray *screens;

    GSSetScaleFactorArgument(@"1.5");

    fake = [GSFakeScreens installWithFrames: frames
      resolutions: [NSArray arrayWithObjects: @"144", @"72", nil]];
    screens = [NSScreen screens];
    PASS([screens count] == 2, "two screens");
    PASS([[screens objectAtIndex: 0] userSpaceScaleFactor] == 2.0,
      "a screen of 144 dpi next to one of 72 dpi has the factor 2");
    PASS([[screens objectAtIndex: 1] userSpaceScaleFactor] == 1.0,
      "the screen of 72 dpi next to it has the factor 1");
    [fake uninstall];

    fake = [GSFakeScreens installWithFrames: frames
      resolutions: [NSArray arrayWithObjects: @"96", @"96", nil]];
    screens = [NSScreen screens];
    PASS([[screens objectAtIndex: 0] userSpaceScaleFactor] == 1.5
      && [[screens objectAtIndex: 1] userSpaceScaleFactor] == 1.5,
      "screens of the same resolution use GSScaleFactor");
    [fake uninstall];

    fake = [GSFakeScreens installWithFrames:
        [NSArray arrayWithObject: [frames objectAtIndex: 0]]
      resolutions: [NSArray arrayWithObject: @"144"]];
    screens = [NSScreen screens];
    PASS([[screens objectAtIndex: 0] userSpaceScaleFactor] == 1.5,
      "a single screen uses GSScaleFactor");
    [fake uninstall];

    GSSetScaleFactorArgument(nil);
  }

  END_SET("NSScreen scale factor per screen")

  DESTROY(arp);
  return 0;
}
