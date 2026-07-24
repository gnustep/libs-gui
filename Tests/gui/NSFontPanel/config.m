#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontPanel.h>

/* NSFontPanel state: the shared panel, its enabled flag, working when modal,
   converting the displayed font, and the accessory view.  Building the shared
   panel needs a window server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSFontPanel config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFontPanel *fp;

      PASS([NSFontPanel sharedFontPanelExists] == NO,
        "the shared font panel does not exist before it is asked for");
      fp = [NSFontPanel sharedFontPanel];
      PASS(fp != nil && [NSFontPanel sharedFontPanelExists] == YES,
        "asking for the shared font panel creates it");

      /* defaults */
      PASS([fp isEnabled] == YES, "the font panel is enabled by default");
      PASS([fp worksWhenModal] == YES, "the font panel works when modal");

      /* enabled round-trip */
      [fp setEnabled: YES];
      PASS([fp isEnabled] == YES, "enabling the font panel keeps it enabled");

      /* converting the displayed font keeps its family and size when nothing
         else is selected */
      {
        NSFont *font = [NSFont systemFontOfSize: 14.0];
        NSFont *conv;
        [fp setPanelFont: font isMultiple: NO];
        conv = [fp panelConvertFont: font];
        PASS(conv != nil
          && [[conv familyName] isEqualToString: [font familyName]],
          "converting the displayed font keeps its family");
        PASS([conv pointSize] == [font pointSize],
          "converting the displayed font keeps its size");
      }

      /* accessory view round-trip */
      {
        NSView *av = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 40, 20)]);
        [fp setAccessoryView: av];
        PASS([fp accessoryView] == av, "the accessory view round-trips");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSFontPanel config")
  DESTROY(arp);
  return 0;
}
