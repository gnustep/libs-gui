/* Coverage for the NSStackView arranged-subview membership model, which does
   not depend on the constraint-based layout: -addArrangedSubview: leaves the
   view in both -arrangedSubviews and -subviews, -insertArrangedSubview:atIndex:
   orders the arranged list while the subview stays appended, re-adding a view
   does not duplicate it, -removeArrangedSubview: drops it from the arranged list
   but keeps it as a subview, a plain -addSubview: is not arranged, and
   -removeFromSuperview drops it from both.  Every assertion matches AppKit
   (checked on a macOS runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStackView.h>
#include <AppKit/NSView.h>

int main()
{
  NSStackView *sv;
  NSView *a, *b, *c, *d;

  START_SET("NSStackView membership")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      sv = AUTORELEASE([[NSStackView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      a = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 20, 20)]);
      b = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 20, 20)]);
      c = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 20, 20)]);
      d = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 20, 20)]);

      PASS([[sv arrangedSubviews] count] == 0 && [[sv subviews] count] == 0,
           "a new stack view has no arranged subviews or subviews");

      [sv addArrangedSubview: a];
      PASS([[sv arrangedSubviews] count] == 1 && [[sv subviews] count] == 1,
           "addArrangedSubview: adds to arrangedSubviews and subviews");
      PASS([[sv arrangedSubviews] containsObject: a]
           && [[sv subviews] containsObject: a],
           "the added view is in both lists");

      [sv addArrangedSubview: b];
      [sv insertArrangedSubview: c atIndex: 0];
      PASS([[sv arrangedSubviews] count] == 3,
           "insertArrangedSubview: adds the view");
      PASS([[sv arrangedSubviews] objectAtIndex: 0] == c
           && [[sv arrangedSubviews] objectAtIndex: 1] == a
           && [[sv arrangedSubviews] objectAtIndex: 2] == b,
           "insertArrangedSubview:atIndex: orders the arranged list");

      [sv addArrangedSubview: a];
      PASS([[sv arrangedSubviews] count] == 3,
           "re-adding an arranged view does not duplicate it");

      [sv removeArrangedSubview: a];
      PASS(![[sv arrangedSubviews] containsObject: a],
           "removeArrangedSubview: drops the view from arrangedSubviews");
      PASS([[sv subviews] containsObject: a],
           "removeArrangedSubview: keeps the view as a subview");

      [sv addSubview: d];
      PASS(![[sv arrangedSubviews] containsObject: d]
           && [[sv subviews] containsObject: d],
           "a plain addSubview: is a subview but not arranged");

      [b removeFromSuperview];
      PASS(![[sv arrangedSubviews] containsObject: b]
           && ![[sv subviews] containsObject: b],
           "removeFromSuperview drops the view from both lists");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
    else
      [localException raise];
  NS_ENDHANDLER

  END_SET("NSStackView membership")

  return 0;
}
