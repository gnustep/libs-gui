#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSScreen.h>
#include <GNUstepGUI/GSDisplayServer.h>

int
main(int argc, char **argv)
{
  NSScreen *screen;
  NSRect frame;
  NSRect visible;
  NSRect workArea;

  START_SET("NSScreen visibleFrame")

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

  screen = [NSScreen mainScreen];
  if (screen == nil)
    SKIP("no screen to ask")

  frame = [screen frame];
  visible = [screen visibleFrame];
  PASS(NSWidth(frame) > 0 && NSHeight(frame) > 0, "the screen has a frame");
  PASS(NSContainsRect(frame, visible) || NSEqualRects(frame, visible),
       "the visible frame lies within the frame");

  workArea = [GSCurrentServer() workAreaForScreen: 0];
  PASS(NSIsEmptyRect(workArea) || NSContainsRect(frame, workArea)
       || NSEqualRects(frame, workArea),
       "the work area of the screen lies within its frame");

  if (NSIsEmptyRect(workArea) || NSEqualRects(workArea, frame))
    {
      SKIP("the display server reserves nothing on this screen")
    }

  PASS(NSMinX(visible) >= NSMinX(workArea)
       && NSMaxX(visible) <= NSMaxX(workArea),
       "the visible frame keeps out of what the server reserves");
  PASS(NSMinY(visible) >= NSMinY(workArea)
       && NSMaxY(visible) <= NSMaxY(workArea),
       "the visible frame keeps out of it in both directions");

  /* What the server reserved at the top is not taken off a second time for
     a menu bar that is already standing in it. */
  if (NSMaxY(frame) - NSMaxY(workArea) >= [NSMenuView menuBarHeight])
    {
      PASS(NSHeight(visible) == NSHeight(workArea),
           "a menu bar the server has already reserved is not taken off twice");
    }

  END_SET("NSScreen visibleFrame")

  return 0;
}
