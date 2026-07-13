/* Coverage for NSTrackingArea: the option constant values, the rect, options,
 * owner and userInfo accessors, and copying.  These are plain object
 * operations and need no backend.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSTrackingArea.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.001)

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("option constants match AppKit")
    PASS(NSTrackingMouseEnteredAndExited == 0x01
      && NSTrackingMouseMoved == 0x02
      && NSTrackingCursorUpdate == 0x04,
      "the mouse option values are correct");
    PASS(NSTrackingActiveWhenFirstResponder == 0x10
      && NSTrackingActiveInKeyWindow == 0x20
      && NSTrackingActiveInActiveApp == 0x40
      && NSTrackingActiveAlways == 0x80,
      "the active option values are correct");
    PASS(NSTrackingAssumeInside == 0x100
      && NSTrackingInVisibleRect == 0x200
      && NSTrackingEnabledDuringMouseDrag == 0x400,
      "the remaining option values are correct");
  END_SET("option constants match AppKit")

  START_SET("accessors")
    NSDictionary	*info = [NSDictionary dictionaryWithObject: @"v"
							   forKey: @"k"];
    id			owner = AUTORELEASE([[NSObject alloc] init]);
    NSRect		rect = NSMakeRect(10, 20, 30, 40);
    NSTrackingAreaOptions opts =
      NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
    NSTrackingArea	*a = AUTORELEASE([[NSTrackingArea alloc]
      initWithRect: rect options: opts owner: owner userInfo: info]);

    PASS(NSEqualRects([a rect], rect), "the rect reads back");
    PASS(opts == [a options], "the options read back");
    PASS(owner == [a owner], "the owner reads back");
    PASS([[a userInfo] objectForKey: @"k"] != nil, "the userInfo reads back");
  END_SET("accessors")

  START_SET("a nil userInfo is allowed")
    id			owner = AUTORELEASE([[NSObject alloc] init]);
    NSTrackingArea	*a = AUTORELEASE([[NSTrackingArea alloc]
      initWithRect: NSMakeRect(0, 0, 1, 1)
	   options: NSTrackingMouseMoved | NSTrackingActiveAlways
	     owner: owner userInfo: nil]);

    PASS(nil == [a userInfo], "a tracking area with no userInfo returns nil");
  END_SET("a nil userInfo is allowed")

  START_SET("copy preserves the rect, options, owner and userInfo")
    NSDictionary	*info = [NSDictionary dictionaryWithObject: @"v"
							   forKey: @"k"];
    id			owner = AUTORELEASE([[NSObject alloc] init]);
    NSRect		rect = NSMakeRect(5, 6, 7, 8);
    NSTrackingAreaOptions opts =
      NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow;
    NSTrackingArea	*a = AUTORELEASE([[NSTrackingArea alloc]
      initWithRect: rect options: opts owner: owner userInfo: info]);
    NSTrackingArea	*c = AUTORELEASE([a copy]);

    PASS(c != a, "the copy is a distinct object");
    PASS(NSEqualRects([c rect], rect) && opts == [c options]
      && owner == [c owner]
      && [[c userInfo] objectForKey: @"k"] != nil,
      "the copy keeps the rect, options, owner and userInfo");
  END_SET("copy preserves the rect, options, owner and userInfo")

  DESTROY(arp);
  return 0;
}
