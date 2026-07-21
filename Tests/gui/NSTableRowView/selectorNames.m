/* The drop target, the group row style and the dragging destination feedback
 * style answer to the names AppKit gives them, so that code written against
 * AppKit reaches them.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableRowView.h>
#include <AppKit/NSTableView.h>

/* Declared so this file builds against a header that does not have them yet;
 * what the test asks is whether the class answers to them. */
@interface NSTableRowView (AppKitNames)
- (void) setDraggingDestinationFeedbackStyle:
  (NSTableViewDraggingDestinationFeedbackStyle)style;
- (BOOL) isTargetForDropOperation;
- (BOOL) isGroupRowStyle;
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the AppKit selector names")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTableRowView	*view;
    BOOL		hasSetter;
    BOOL		hasTarget;
    BOOL		hasGroup;

    view = AUTORELEASE([[NSTableRowView alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)]);

    hasSetter = [view respondsToSelector:
      @selector(setDraggingDestinationFeedbackStyle:)];
    hasTarget = [view respondsToSelector: @selector(isTargetForDropOperation)];
    hasGroup = [view respondsToSelector: @selector(isGroupRowStyle)];

    PASS(hasSetter == YES,
      "the dragging destination feedback style has a setter");
    PASS(hasTarget == YES,
      "the drop target flag is asked for with isTargetForDropOperation");
    PASS(hasGroup == YES,
      "the group row style flag is asked for with isGroupRowStyle");

    if (hasSetter)
      {
        [view setDraggingDestinationFeedbackStyle:
          NSTableViewDraggingDestinationFeedbackStyleGap];
        PASS([view draggingDestinationFeedbackStyle]
          == NSTableViewDraggingDestinationFeedbackStyleGap,
          "the dragging destination feedback style round-trips");
      }

    if (hasTarget)
      {
        PASS([view isTargetForDropOperation] == NO,
          "a new row view is not a drop target");
        [view setTargetForDropOperation: YES];
        PASS([view isTargetForDropOperation] == YES,
          "the drop target flag round-trips");
      }

    if (hasGroup)
      {
        PASS([view isGroupRowStyle] == NO,
          "a new row view does not have the group row style");
        [view setGroupRowStyle: YES];
        PASS([view isGroupRowStyle] == YES,
          "the group row style round-trips");
      }
  }

  END_SET("the AppKit selector names")

  DESTROY(arp);
  return 0;
}
