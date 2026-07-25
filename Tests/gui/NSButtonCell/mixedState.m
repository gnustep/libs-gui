/* A switch button (NSButtonTypeSwitch) with -setAllowsMixedState: YES draws a
   distinct indicator in the mixed state: a dash, not the on state's check mark
   (gnustep/libs-gui#231).  This renders the cell in each state and checks the
   mixed rendering differs from both the on and off renderings.  It needs the
   backend, so the body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

/* Render the cell in the given state and return the indicator area. */
static NSBitmapImageRep *
render(NSButtonCell *cell, NSInteger state, int side)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, side, side)
              styleMask: NSWindowStyleMaskBorderless
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSView *v = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, side, side)]);
  NSBitmapImageRep *rep;

  [w setContentView: v];
  [v lockFocus];
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, side, side));

  [cell setState: state];
  [cell drawWithFrame: NSMakeRect(0, 0, side, side) inView: v];

  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: NSMakeRect(0, 0, side, side)]);
  [v unlockFocus];
  return rep;
}

/* Number of pixels that differ between two same-sized reps. */
static int
pixelDifference(NSBitmapImageRep *a, NSBitmapImageRep *b, int side)
{
  int x, y, n = 0;

  for (y = 0; y < side; y++)
    {
      for (x = 0; x < side; x++)
        {
          NSUInteger pa[5], pb[5];

          [a getPixel: pa atX: x y: y];
          [b getPixel: pb atX: x y: y];
          if (pa[0] != pb[0] || pa[1] != pb[1] || pa[2] != pb[2])
            {
              n++;
            }
        }
    }
  return n;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  int side = 20;

  START_SET("NSButtonCell mixed state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSButtonCell *cell = AUTORELEASE([[NSButtonCell alloc] initTextCell: @""]);
  [cell setButtonType: NSSwitchButton];
  [cell setAllowsMixedState: YES];

  NSBitmapImageRep *off = render(cell, NSOffState, side);
  NSBitmapImageRep *on = render(cell, NSOnState, side);
  NSBitmapImageRep *mixed = render(cell, NSMixedState, side);

  /* Sanity: on and off draw different indicators. */
  PASS(pixelDifference(off, on, side) > 0,
       "the on and off states render differently");

  /* The mixed state must not reuse the on state's check mark. */
  PASS(pixelDifference(mixed, on, side) > 0,
       "the mixed state does not render as the on state");

  /* Nor should it look empty like the off state. */
  PASS(pixelDifference(mixed, off, side) > 0,
       "the mixed state does not render as the off state");

  END_SET("NSButtonCell mixed state")

  DESTROY(arp);
  return 0;
}
