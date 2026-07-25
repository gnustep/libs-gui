#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>

@interface HideRecorder : NSView
{
@public
  int hideCount;
  int unhideCount;
}
@end

@implementation HideRecorder
- (void) viewDidHide { hideCount++; }
- (void) viewDidUnhide { unhideCount++; }
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  HideRecorder *parent, *visibleChild, *hiddenChild;

  START_SET("NSView hidden notifications")

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

  parent = AUTORELEASE([[HideRecorder alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  visibleChild = AUTORELEASE([[HideRecorder alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)]);
  hiddenChild = AUTORELEASE([[HideRecorder alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)]);
  [parent addSubview: visibleChild];
  [parent addSubview: hiddenChild];

  /* Directly hiding a view whose ancestors are visible sends viewDidHide to
     it.  Checked against AppKit. */
  [hiddenChild setHidden: YES];
  PASS(hiddenChild->hideCount == 1,
    "setHidden: YES sends viewDidHide to the view");

  parent->hideCount = 0;
  visibleChild->hideCount = 0;
  hiddenChild->hideCount = 0;

  /* Hiding a view sends viewDidHide to the view and to its unhidden
     descendants, but not to descendants that are already hidden. */
  [parent setHidden: YES];
  PASS(parent->hideCount == 1,
    "viewDidHide is sent to the hidden view");
  PASS(visibleChild->hideCount == 1,
    "viewDidHide is sent to an unhidden descendant");
  PASS(hiddenChild->hideCount == 0,
    "viewDidHide is not sent to an already-hidden descendant");

  /* Changing the hidden state of a view below a hidden ancestor does not
     change effective visibility, so no notification is sent. */
  hiddenChild->hideCount = 0;
  hiddenChild->unhideCount = 0;
  [hiddenChild setHidden: NO];
  PASS(hiddenChild->unhideCount == 0,
    "no viewDidUnhide is sent below a hidden ancestor");
  [hiddenChild setHidden: YES];
  PASS(hiddenChild->hideCount == 0,
    "no viewDidHide is sent below a hidden ancestor");

  /* Unhiding sends viewDidUnhide to the view and its unhidden descendants. */
  parent->unhideCount = 0;
  visibleChild->unhideCount = 0;
  hiddenChild->unhideCount = 0;
  [parent setHidden: NO];
  PASS(parent->unhideCount == 1,
    "viewDidUnhide is sent to the unhidden view");
  PASS(visibleChild->unhideCount == 1,
    "viewDidUnhide is sent to an unhidden descendant");
  PASS(hiddenChild->unhideCount == 0,
    "viewDidUnhide is not sent to a still-hidden descendant");

  END_SET("NSView hidden notifications")

  DESTROY(arp);
  return 0;
}
