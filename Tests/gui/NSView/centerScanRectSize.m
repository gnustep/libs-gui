#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>

/* checked against AppKit: centerScanRect: rounds the origin and the size
   independently. It does not couple the size rounding to the origin's
   rounding error. */

static int
checkRect(NSView *view, NSRect in, NSRect want)
{
	NSRect r = [view centerScanRect: in];

	if (fabs(r.origin.x - want.origin.x) > 0.001
	 || fabs(r.origin.y - want.origin.y) > 0.001
	 || fabs(r.size.width - want.size.width) > 0.001
	 || fabs(r.size.height - want.size.height) > 0.001)
	{
		printf("expected (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
			want.origin.x, want.origin.y, want.size.width, want.size.height,
			r.origin.x, r.origin.y, r.size.width, r.size.height);
		return 0;
	}
	return 1;
}

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(arp);

	NSView *view;

	START_SET("NSView GNUstep centerScanRectSize")

	NS_DURING
	{
		[NSApplication sharedApplication];
	}
	NS_HANDLER
	{
	if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
		SKIP("It looks like GNUstep backend is not yet installed")
	}
	NS_ENDHANDLER

	view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0,0,100,100)]);

	/* origin and size each round to nearest, separately */
	PASS(checkRect(view, NSMakeRect(10.3,10.7,20.4,20.6),
			 NSMakeRect(10.0,11.0,20.0,21.0)),
		"NSView -centerScanRect: rounds origin and size to nearest");

	/* witness that the size rounding is not coupled to the origin's rounding
	   error: here the origin rounds down by 0.4 in x and up by 0.1 in y, but
	   the size stays (5, 5) rather than picking up either error term */
	PASS(checkRect(view, NSMakeRect(0.4,0.9,5.3,5.3),
			 NSMakeRect(0.0,1.0,5.0,5.0)),
		"NSView -centerScanRect: size rounding is independent of the origin error");

	END_SET("NSView GNUstep centerScanRectSize")

	DESTROY(arp);
	return 0;
}
