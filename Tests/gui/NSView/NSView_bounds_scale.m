/*
copyright 2011 HNS <hns@goldelico.com>
*/
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

int CHECK(NSView *view, NSRect frame, NSRect bounds)
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

	r = [view bounds];
	if (fabs(r.origin.x - bounds.origin.x)>0.001
	 || fabs(r.origin.y - bounds.origin.y)>0.001
	 || fabs(r.size.width - bounds.size.width)>0.001
	 || fabs(r.size.height - bounds.size.height)>0.001)
	{
		printf("(2) expected bounds (%g %g)+(%g %g), got (%g %g)+(%g %g)\n",
			bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
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
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,200,200)
		styleMask: NSClosableWindowMask
                                         backing: NSBackingStoreRetained
                                           defer: YES];
  view1 = [[NSView alloc] initWithFrame: NSMakeRect(20,20,100,100)];
  
  [[window contentView] addSubview: view1];
  
  [view1 setBounds: NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)];
  passed = CHECK(view1, NSMakeRect(20,20,100,100), NSMakeRect(30.4657, 88.5895, 21.2439, 60.8716)) && passed;
  [view1 setBoundsRotation: 30];
  passed = (fabs([view1 boundsRotation] - 30.0) <= 0.001) && passed;
  //  passed = CHECK(view1, NSMakeRect(20,20,100,100), NSMakeRect(70.5714, 50.9892, 48.8336, 63.3383)) && passed;
  passed = CHECK(view1, NSMakeRect(20,20,100,100), NSMakeRect(70.6788, 50.866, 48.8336, 63.3383)) && passed;
  [view1 setBounds:(NSRect){{30.4657, 88.5895}, {21.2439, 60.8716}}];
  passed = CHECK(view1, NSMakeRect(20,20,100,100),(NSRect) {{30.4657, 77.9676}, {48.8336, 63.3383}}) && passed;
  [view1 scaleUnitSquareToSize:(NSSize){0.720733, 0.747573}];
  passed = CHECK(view1, NSMakeRect(20,20,100,100),(NSRect) {{42.2704, 104.294}, {67.7554, 84.7253}}) && passed;
  [view1 setBoundsRotation: 30 - 1e-6];
  passed = (fabs([view1 boundsRotation] - 30.0 + 1e-6) <= 0.001) && passed;
  passed = CHECK(view1, NSMakeRect(20,20,100,100),(NSRect) {{39.9801, 104.211}, {66.2393, 85.2544}}) && passed;
  [view1 rotateByAngle: 1e-6];
  passed = CHECK(view1, NSMakeRect(20,20,100,100),(NSRect) {{39.9801, 104.211}, {66.2393, 85.2544}}) && passed;
  passed = (fabs([view1 boundsRotation] - 30.0) <= 0.001) && passed;
  
  pass(passed,"NSView -scaleUnitSquareToSize works");
  
  DESTROY(arp);
  return 0;
}

