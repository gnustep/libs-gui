/* NSButton -setBezelColor: tints the drawn bezel.  A/B/C: the property round
   trips and defaults to nil (A), and rendering the button with a bezel colour
   changes the bezel pixels to that colour (C), which the default colour does
   not.  The colour check is backend agnostic (the fill colour is the same on
   any backend), verified on xlib, art and cairo. */
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSColor.h>

#include "../GSRenderTest.h"

static NSColor *
centerColor(NSButton *b)
{
  NSBitmapImageRep *rep = GSRenderView(b);
  NSInteger x = [rep pixelsWide] / 2;
  NSInteger y = [rep pixelsHigh] / 2;

  return [[rep colorAtX: x y: y]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
}

int
main(int argc, char **argv)
{
  NSButton *b;

  START_SET("NSButton bezelColor")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  b = AUTORELEASE([[NSButton alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 40)]);
  [b setTitle: @""];
  [b setBordered: YES];

  /* A: defaults and round-trip */
  PASS([b bezelColor] == nil, "the bezel color is nil by default");
  [b setBezelColor: [NSColor greenColor]];
  PASS([[b bezelColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace] != nil
    && [[[b bezelColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]
         greenComponent] == 1.0,
    "the bezel color round-trips");
  [b setBezelColor: nil];
  PASS([b bezelColor] == nil, "the bezel color can be cleared");
  PASS([b contentTintColor] == nil, "the content tint color is nil by default");
  [b setContentTintColor: [NSColor blueColor]];
  PASS([[b contentTintColor] isEqual: [NSColor blueColor]]
    && [[[b cell] contentTintColor] isEqual: [NSColor blueColor]],
    "the content tint color forwards to the cell");
  [b setContentTintColor: nil];
  PASS([b contentTintColor] == nil, "the content tint color can be cleared");

  NS_DURING
    {
      NSColor *plain;
      NSColor *tinted;

      /* C: the default bezel is not red */
      plain = centerColor(b);

      /* C: a red bezel color tints the bezel red */
      [b setBezelColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.0
                                                   blue: 0.0 alpha: 1.0]];
      tinted = centerColor(b);

      /* The bezel is drawn in backend independent theme code; only assert the
         colour when the backend produced a readable rendering (an opaque, non
         black bezel), so a backend that cannot read a rendering back skips
         rather than fails. */
      if (plain == nil || tinted == nil
        || [plain alphaComponent] < 0.5
        || ([plain redComponent] < 0.05 && [plain greenComponent] < 0.05
            && [plain blueComponent] < 0.05))
        {
          SKIP("the backend did not produce a readable rendering")
        }
      else
        {
          PASS([tinted redComponent] > 0.5
            && [tinted redComponent] > [tinted greenComponent]
            && [tinted redComponent] > [tinted blueComponent],
            "a red bezel color makes the bezel red-dominant");
          PASS([plain redComponent] < 0.5
            || [plain redComponent] <= [plain greenComponent]
            || [plain redComponent] <= [plain blueComponent],
            "the default bezel is not the red tint");
        }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
    else
      [localException raise];
  NS_ENDHANDLER

  END_SET("NSButton bezelColor")

  return 0;
}
