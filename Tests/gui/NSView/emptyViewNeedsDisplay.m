/* A view with no area cannot draw anything.  Marking it for display and
   then displaying the window has to leave it, and every view above it,
   clear again; otherwise nothing in that branch of the tree ever reports
   itself as drawn.  A view that has an area but falls outside the rectangle
   being displayed is a different matter and keeps its mark.  Drawing needs
   the backend, so the set is skipped without one.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

int
main(int argc, char **argv)
{
  NSWindow *window;
  NSView *content;
  NSView *flat;
  NSView *aside;
  NSBox *box;

  START_SET("NSView empty view needs display")

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

  NS_DURING
    {
      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      content = [window contentView];

      flat = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(10, 10, 100, 0)]);
      [content addSubview: flat];
      [flat setNeedsDisplay: YES];
      [window orderFront: nil];
      [window display];

      PASS([flat needsDisplay] == NO,
           "a view with no area does not wait for a display");
      PASS([content needsDisplay] == NO,
           "the view holding it does not wait either");
      PASS([window viewsNeedDisplay] == NO,
           "the window has nothing left to display");

      /* A box two pixels high gives its content view no room at all, which
         is how this turns up in a real window. */
      box = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(10, 100, 180, 2)]);
      [box setTitlePosition: NSNoTitle];
      [content addSubview: box];
      [window display];

      PASS([[box contentView] needsDisplay] == NO,
           "the content view of a box too short for it is not left waiting");
      PASS([box needsDisplay] == NO, "nor is the box");
      PASS([content needsDisplay] == NO, "nor is the view holding the box");

      /* A view with an area that the displayed rectangle does not reach
         keeps its mark, since it still has something to draw. */
      aside = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(150, 150, 20, 20)]);
      [content addSubview: aside];
      [window display];
      [aside setNeedsDisplay: YES];
      [content displayIfNeededInRect: NSMakeRect(0, 0, 40, 40)];

      PASS([aside needsDisplay] == YES,
           "a view outside the rectangle being displayed still waits");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSView empty view needs display")

  return 0;
}
