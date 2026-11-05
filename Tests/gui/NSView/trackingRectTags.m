/* Adding a tracking rect mustn't look at the rects a view already has, or
 * adding n of them is quadratic, and a tool tip is a tracking rect.
 *
 * Counts -[GSTrackingRect tag], so the test doesn't depend on timing.
 */
#include "Testing.h"
#include <objc/runtime.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <GNUstepGUI/GSTrackingRect.h>

static unsigned		tagCalls = 0;
static IMP		originalTag = 0;

static NSTrackingRectTag
countedTag(id self, SEL _cmd)
{
  tagCalls++;
  return ((NSTrackingRectTag (*)(id, SEL))originalTag)(self, _cmd);
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  enum { COUNT = 1000 };
  NSTrackingRectTag	tags[COUNT];
  NSView		*view;
  NSView		*other;
  NSTrackingRectTag	again;
  NSUInteger		i;
  BOOL			different = YES;
  BOOL			positive = YES;
  Method		method;

  START_SET("tracking rect tags")
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

  method = class_getInstanceMethod([GSTrackingRect class], @selector(tag));
  originalTag = method_setImplementation(method, (IMP)countedTag);

  view = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 1000)];
  for (i = 0; i < COUNT; i++)
    {
      tags[i] = [view addTrackingRect: NSMakeRect(0, i, 100, 1)
				owner: view
			     userData: NULL
			 assumeInside: NO];
    }
  printf("%u calls of -tag for %u rects\n", tagCalls, COUNT);
  PASS(tagCalls == 0, "adding a rect doesn't look at the others' tags");

  for (i = 0; i < COUNT; i++)
    {
      if (tags[i] <= 0)
	positive = NO;
      if (i > 0 && tags[i] == tags[i - 1])
	different = NO;
    }
  PASS(positive, "tags are positive");
  PASS(different, "tags are different");

  /* Removing one leaves the rest, and its tag isn't given to a new rect. */
  [view removeTrackingRect: tags[COUNT - 1]];
  again = [view addTrackingRect: NSMakeRect(0, 0, 100, 1)
			  owner: view
		       userData: NULL
		   assumeInside: NO];
  different = YES;
  for (i = 0; i < COUNT - 1; i++)
    {
      if (tags[i] == again)
	different = NO;
    }
  PASS(different, "a new rect's tag differs from the remaining ones");

  /* Another view's rects don't get in the way. */
  other = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  PASS([other addTrackingRect: NSMakeRect(0, 0, 10, 10)
			owner: other
		     userData: NULL
		 assumeInside: NO] > 0, "another view can add a rect");

  method_setImplementation(method, originalTag);
  [other release];
  [view release];
  END_SET("tracking rect tags")

  [pool drain];
  return 0;
}
