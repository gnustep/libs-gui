/* NSComboBox posts NSComboBoxSelectionDidChangeNotification when a programmatic
   selection changes the selected index, does not repost when the same index is
   selected again, and posts again when the selection is cleared.  selection.m
   already covers how the index tracks insertion and removal; this covers the
   change notification.  The observer takes any object because a combo box that
   has never been drawn has no control view to stamp on the notification.  The
   combo box uses the theme and font backend, so the set is skipped when the
   backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBox.h>

@interface Recorder : NSObject
{
@public
  int count;
}
- (void) changed: (NSNotification *)n;
@end

@implementation Recorder
- (void) changed: (NSNotification *)n
{
  count++;
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Recorder *r;
  NSComboBox *cb;
  NSNotificationCenter *nc;

  START_SET("NSComboBox selection notification")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      cb = AUTORELEASE([[NSComboBox alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 22)]);
      [cb addItemWithObjectValue: @"alpha"];
      [cb addItemWithObjectValue: @"beta"];
      [cb addItemWithObjectValue: @"gamma"];

      [nc addObserver: r
             selector: @selector(changed:)
                 name: NSComboBoxSelectionDidChangeNotification
               object: nil];

      /* A new selection posts the change notification. */
      [cb selectItemAtIndex: 1];
      PASS(r->count == 1,
        "selecting a new item posts the selection change notification");

      /* Selecting the same index again posts nothing. */
      [cb selectItemAtIndex: 1];
      PASS(r->count == 1,
        "selecting the same item again does not repost");

      /* Selecting a different index posts again. */
      [cb selectItemAtIndex: 2];
      PASS(r->count == 2,
        "selecting a different item posts again");

      /* Clearing the selection posts the change notification. */
      [cb deselectItemAtIndex: 2];
      PASS(r->count == 3,
        "deselecting the selected item posts the change notification");

      [nc removeObserver: r];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSComboBox selection notification")

  DESTROY(arp);
  return 0;
}
