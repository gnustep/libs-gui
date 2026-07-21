#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>

/* checked against AppKit: a windowless convertRect:toView:/fromView:
   must apply the view hierarchy transform, the same as convertPoint:
   does, instead of returning the rect unchanged. */

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(arp);

	NSView *outer;
	NSView *inner;
	NSRect r;
	int passed;

	START_SET("NSView GNUstep convertRectNoWindow")

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

	outer = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0,0,200,200)]);
	inner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(50,30,100,100)]);
	[outer addSubview: inner];

	passed = 1;

	r = [inner convertRect: NSMakeRect(10,10,20,20) toView: outer];
	if (fabs(r.origin.x - 60.0) > 0.001
	 || fabs(r.origin.y - 40.0) > 0.001
	 || fabs(r.size.width - 20.0) > 0.001
	 || fabs(r.size.height - 20.0) > 0.001)
	{
		passed = 0;
		printf("expected (60 40)+(20 20), got (%g %g)+(%g %g)\n",
			r.origin.x, r.origin.y, r.size.width, r.size.height);
	}

	r = [outer convertRect: NSMakeRect(10,10,20,20) fromView: inner];
	if (fabs(r.origin.x - 60.0) > 0.001
	 || fabs(r.origin.y - 40.0) > 0.001
	 || fabs(r.size.width - 20.0) > 0.001
	 || fabs(r.size.height - 20.0) > 0.001)
	{
		passed = 0;
		printf("expected (60 40)+(20 20), got (%g %g)+(%g %g)\n",
			r.origin.x, r.origin.y, r.size.width, r.size.height);
	}

	pass(passed, "NSView -convertRect:toView:/-convertRect:fromView: apply the hierarchy transform without a window");

	END_SET("NSView GNUstep convertRectNoWindow")

	DESTROY(arp);
	return 0;
}
