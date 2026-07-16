/* Coverage for NSPathControl: NSPathStyle enum values, initWithFrame:
   defaults, and the pathStyle / URL / placeholderString setters.  Every
   assertion was checked against Apple AppKit (macOS 26) and only the
   behaviours that match are asserted here. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <Foundation/NSURL.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPathControl.h>
#import <AppKit/NSPathCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* Enum values match AppKit; these need no backend. */
  PASS(NSPathStyleStandard == 0, "NSPathStyleStandard is 0");
  PASS(NSPathStyleNavigationBar == 1, "NSPathStyleNavigationBar is 1");
  PASS(NSPathStylePopUp == 2, "NSPathStylePopUp is 2");

  START_SET("NSPathControl basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSPathControl *pc =
      [[NSPathControl alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];
  PASS(pc != nil, "NSPathControl -initWithFrame: returns an instance");

  /* Defaults on a freshly created control. */
  PASS([pc pathStyle] == NSPathStyleStandard,
       "default pathStyle is NSPathStyleStandard");
  PASS([pc URL] == nil, "default URL is nil");
  PASS([pc doubleAction] == NULL, "default doubleAction is NULL");
  PASS([pc placeholderString] == nil, "default placeholderString is nil");
  PASS([pc allowedTypes] == nil, "default allowedTypes is nil");

  /* Setters round-trip. */
  [pc setPathStyle: NSPathStylePopUp];
  PASS([pc pathStyle] == NSPathStylePopUp, "setPathStyle: round-trips");

  NSURL *url = [NSURL fileURLWithPath: @"/tmp/foo"];
  [pc setURL: url];
  PASS([[pc URL] isEqual: url], "setURL: round-trips");

  [pc setPlaceholderString: @"pick a path"];
  PASS([[pc placeholderString] isEqualToString: @"pick a path"],
       "setPlaceholderString: round-trips");

  RELEASE(pc);

  END_SET("NSPathControl basic")

  DESTROY(arp);
  return 0;
}
