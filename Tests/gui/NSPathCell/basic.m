/* Coverage for NSPathCell: NSPathStyle enum values, the
   +pathComponentCellClass class method, init defaults, and the pathStyle /
   backgroundColor / placeholderString / allowedTypes / doubleAction setters.
   Every assertion was checked against Apple AppKit (macOS 26) and only the
   behaviours that match are asserted here.  Creating the cell pulls in the
   default font, which needs the backend, so that part is guarded. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSPathCell.h>
#import <AppKit/NSPathComponentCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* Enum values match AppKit; these need no backend. */
  PASS(NSPathStyleStandard == 0, "NSPathStyleStandard is 0");
  PASS(NSPathStyleNavigationBar == 1, "NSPathStyleNavigationBar is 1");
  PASS(NSPathStylePopUp == 2, "NSPathStylePopUp is 2");

  /* Class method; needs no backend. */
  PASS([NSPathCell pathComponentCellClass] == [NSPathComponentCell class],
       "+pathComponentCellClass is NSPathComponentCell");

  START_SET("NSPathCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSPathCell *pc = [[NSPathCell alloc] init];
  PASS(pc != nil, "NSPathCell -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([pc pathStyle] == NSPathStyleStandard,
       "default pathStyle is NSPathStyleStandard");
  PASS([pc backgroundColor] == nil, "default backgroundColor is nil");
  PASS([pc placeholderString] == nil, "default placeholderString is nil");
  PASS([pc allowedTypes] == nil, "default allowedTypes is nil");
  PASS([pc URL] == nil, "default URL is nil");
  PASS([pc doubleAction] == NULL, "default doubleAction is NULL");

  /* Setters round-trip. */
  [pc setPathStyle: NSPathStylePopUp];
  PASS([pc pathStyle] == NSPathStylePopUp, "setPathStyle: round-trips");

  NSColor *col = [NSColor redColor];
  [pc setBackgroundColor: col];
  PASS([[pc backgroundColor] isEqual: col], "setBackgroundColor: round-trips");

  [pc setPlaceholderString: @"choose"];
  PASS([[pc placeholderString] isEqualToString: @"choose"],
       "setPlaceholderString: round-trips");

  NSArray *types = [NSArray arrayWithObject: @"txt"];
  [pc setAllowedTypes: types];
  PASS([[pc allowedTypes] isEqual: types], "setAllowedTypes: round-trips");

  [pc setDoubleAction: @selector(doubleClick:)];
  PASS([NSStringFromSelector([pc doubleAction])
         isEqualToString: @"doubleClick:"], "setDoubleAction: round-trips");

  RELEASE(pc);

  END_SET("NSPathCell basic")

  DESTROY(arp);
  return 0;
}
