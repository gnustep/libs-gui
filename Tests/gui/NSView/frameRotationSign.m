#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>

/* checked against AppKit: frameRotation keeps the sign of a negative
   rotation and reads back a full turn as ~0, instead of normalizing
   into [0, 360). */

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(arp);

	NSView *view;
	int passed;

	START_SET("NSView GNUstep frameRotationSign")

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

	passed = 1;

	[view setFrameRotation: -45.0];
	if (fabs([view frameRotation] - (-45.0)) > 0.0001)
	{
		passed = 0;
		printf("expected frameRotation -45, got %g\n", [view frameRotation]);
	}

	[view setFrameRotation: 360.0];
	if (fabs([view frameRotation]) > 0.0001)
	{
		passed = 0;
		printf("expected frameRotation ~0, got %g\n", [view frameRotation]);
	}

	pass(passed, "NSView -frameRotation keeps the sign of a negative rotation");

	END_SET("NSView GNUstep frameRotationSign")

	DESTROY(arp);
	return 0;
}
