/* NSTextView should not invalidate its cursor rects on every layout change
   when the text is plain.  -_updateState: runs (coalesced) on each layout
   invalidation, i.e. effectively on every keystroke; it used to always call
   -[NSWindow invalidateCursorRectsForView:], which rebuilds the sole
   full-visible-rect I-beam and momentarily drops it, so the mouse cursor
   flickers between the I-beam and the arrow while typing (bug #353).

   The only text attribute that currently produces a custom cursor rect is
   NSLinkAttributeName (pointing-hand over links); NSCursorAttributeName is
   still a FIXME in -resetCursorRects.  So the invalidation is only needed
   when the text actually contains a link — plain text keeps a static I-beam
   that never has to be rebuilt on a layout change.

   This spies on the window (a legitimate collaborator) to count the
   invalidations -_updateState: triggers.  The text view lays out through the
   theme and font backend, so the set is skipped when the backend is
   unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>

/* Count the cursor-rect invalidations the view asks the window for. */
@interface CursorCountWindow : NSWindow
{
@public
  int invalidateCount;
}
@end

@implementation CursorCountWindow
- (void) invalidateCursorRectsForView: (NSView *)aView
{
  invalidateCount++;
  [super invalidateCursorRectsForView: aView];
}
@end

/* -_updateState: is the private hook run on each (coalesced) layout change. */
@interface NSTextView (Private_UpdateState)
- (void) _updateState: (id)sender;
@end

int
main(int argc, char **argv)
{
  NSTextView *tv;
  CursorCountWindow *w;

  START_SET("NSTextView cursor-rect invalidation")

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
      tv = AUTORELEASE([[NSTextView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      [tv setEditable: YES];

      w = AUTORELEASE([[CursorCountWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 220, 120)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: tv];

      /* Plain text: a layout change must NOT invalidate the cursor rects,
         since the only cursor rect is the static full-visible-rect I-beam. */
      [tv insertText: @"hello world"];
      w->invalidateCount = 0;
      [tv _updateState: nil];
      PASS(w->invalidateCount == 0,
        "plain-text layout change does not invalidate cursor rects (no flicker)");

      /* Link text: a layout change may have moved the link, so its
         pointing-hand cursor rect must be rebuilt -> invalidation is needed. */
      [[tv textStorage]
        addAttribute: NSLinkAttributeName
               value: [NSURL URLWithString: @"http://www.gnustep.org"]
               range: NSMakeRange(0, 5)];
      w->invalidateCount = 0;
      [tv _updateState: nil];
      PASS(w->invalidateCount == 1,
        "layout change with a visible link still invalidates cursor rects");

      /* A link that is not on screen has no cursor rect of its own, because
         -resetCursorRects only builds them for the visible character range.
         Looking for it costs a scan of the whole text on every keystroke, and
         finding it makes us rebuild rects that cannot have changed. */
      NSTextView *big;
      NSMutableString *lines;
      NSUInteger middle;
      NSUInteger i;

      lines = AUTORELEASE([[NSMutableString alloc] init]);
      for (i = 0; i < 400; i++)
        {
          [lines appendString: @"a line of text in a long document\n"];
        }
      middle = [lines length] / 2;

      big = AUTORELEASE([[NSTextView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      [big setEditable: YES];
      [[w contentView] addSubview: big];
      [big insertText: lines];
      [[big textStorage]
        addAttribute: NSLinkAttributeName
               value: [NSURL URLWithString: @"http://www.gnustep.org"]
               range: NSMakeRange(middle, 10)];

      w->invalidateCount = 0;
      [big _updateState: nil];
      PASS(w->invalidateCount == 0,
        "a link outside the visible text does not invalidate cursor rects");
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

  END_SET("NSTextView cursor-rect invalidation")

  return 0;
}
