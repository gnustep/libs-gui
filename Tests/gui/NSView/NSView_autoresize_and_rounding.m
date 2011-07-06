//
//  NSView_autoresize_and_rounding.m
//
//  Created by Eric Wasylishen on 06.07.11
//
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextView.h>

int CHECK(NSView *view, NSRect frame)
{
	NSRect r;

	r = [view frame];
	if (fabs(r.origin.x - frame.origin.x)>0.001
	 || fabs(r.origin.y - frame.origin.y)>0.001
	 || fabs(r.size.width - frame.size.width)>0.001
	 || fabs(r.size.height - frame.size.height)>0.001)
	{
		printf("(1) expected frame (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
			frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
			r.origin.x, r.origin.y, r.size.width, r.size.height);

		return 0;
	}
	return 1;
}

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(arp);

	NSWindow *window;
	NSView *view1;
	int passed = 1;

	[NSApplication sharedApplication];
	window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,100,100)
		styleMask: NSClosableWindowMask
		backing: NSBackingStoreRetained
		defer: YES];

	view1 = [[NSView alloc] initWithFrame: NSMakeRect(10,10,10,10)];
	[view1 setAutoresizingMask: NSViewMinXMargin |
	       NSViewWidthSizable |
	       NSViewMaxXMargin |
	       NSViewMinYMargin |
	       NSViewHeightSizable |
	       NSViewMaxYMargin ];
	
	[[window contentView] addSubview: view1];

	// All autoresize masks are enabled. Check that halving the
	// width and height of the window works as expected.

	passed = CHECK(view1, NSMakeRect(10,10,10,10)) && passed;
	[window setContentSize: NSMakeSize(50, 50)]; // reduce to 50%
	passed = CHECK(view1, NSMakeRect(5,5,5,5)) && passed;

	[window setContentSize: NSMakeSize(100, 100)]; // restore
	passed = CHECK(view1, NSMakeRect(10,10,10,10)) && passed;

	[window setContentSize: NSMakeSize(33, 33)]; // reduce to 33%
	// NOTE: Frame should be rounded from NSMakeRect(3.3,3.3,3.3,3.3) to
	// NSMakeRect(3,3,3,3)
	passed = CHECK(view1, NSMakeRect(3,3,3,3)) && passed;

	[window setContentSize: NSMakeSize(100, 100)]; // restore
	// NOTE: The following shows that the precision lost in the rounding
	// shown in the previous test was saved by the view
	passed = CHECK(view1, NSMakeRect(10,10,10,10)) && passed;


	// Now test that we can still set fractional frames

	[view1 setFrame: NSMakeRect(1.5, 1.5, 1.5, 1.5)];
	passed = CHECK(view1, NSMakeRect(1.5, 1.5, 1.5, 1.5)) && passed;

	pass(passed,"NSView autoresize rounding works");

	DESTROY(arp);
	return 0;
}
