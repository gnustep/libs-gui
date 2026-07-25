#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSSavePanel.h>

/* State defaults and round-trips for NSSavePanel.  Default values checked
   against AppKit; the ones AppKit sets differently (canCreateDirectories,
   isExtensionHidden, the default name and prompt) are handled separately and
   are not pinned here.  Creating the panel needs a backend, so this keeps the
   usual guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSavePanel config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSavePanel *p = [NSSavePanel savePanel];

      /* defaults that match AppKit */
      PASS([p showsHiddenFiles] == NO, "showsHiddenFiles defaults to NO");
      PASS([p treatsFilePackagesAsDirectories] == NO,
        "treatsFilePackagesAsDirectories defaults to NO");
      PASS([p canSelectHiddenExtension] == NO,
        "canSelectHiddenExtension defaults to NO");
      PASS([p allowedFileTypes] == nil, "allowedFileTypes defaults to nil");
      PASS([[p title] isEqual: @"Save"], "title defaults to Save");

      /* round-trips */
      [p setTitle: @"Store"];
      PASS([[p title] isEqual: @"Store"], "setTitle: round-trips");
      [p setPrompt: @"Go"];
      PASS([[p prompt] isEqual: @"Go"], "setPrompt: round-trips");
      [p setNameFieldStringValue: @"file.txt"];
      PASS([[p nameFieldStringValue] isEqual: @"file.txt"],
        "setNameFieldStringValue: round-trips");
      [p setShowsHiddenFiles: YES];
      PASS([p showsHiddenFiles] == YES, "setShowsHiddenFiles: round-trips");
      [p setTreatsFilePackagesAsDirectories: YES];
      PASS([p treatsFilePackagesAsDirectories] == YES,
        "setTreatsFilePackagesAsDirectories: round-trips");
      [p setCanCreateDirectories: YES];
      PASS([p canCreateDirectories] == YES,
        "setCanCreateDirectories: round-trips");
      [p setExtensionHidden: NO];
      PASS([p isExtensionHidden] == NO, "setExtensionHidden: round-trips");
      [p setCanSelectHiddenExtension: YES];
      PASS([p canSelectHiddenExtension] == YES,
        "setCanSelectHiddenExtension: round-trips");
      [p setAllowedFileTypes: [NSArray arrayWithObject: @"txt"]];
      PASS([[p allowedFileTypes] isEqual: [NSArray arrayWithObject: @"txt"]],
        "setAllowedFileTypes: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSavePanel config")
  DESTROY(arp);
  return 0;
}
