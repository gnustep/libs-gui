/* Interaction exercise for NSSlider: a real click on the track moves the value
   toward the click and sends the action.  The exact value depends on the knob
   width and theme, so this checks the direction (a click on the right of a
   horizontal track raises the value, a click on the left lowers it) rather than
   an exact figure.  The clicks are delivered as real events through GSClick, so
   this needs a window server and keeps the usual START_SET / SKIP guard. */
#import "Testing.h"
#import "../GSRenderTest.h"

#import <Foundation/NSAutoreleasePool.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSSlider.h>
#import <AppKit/NSWindow.h>

@interface SlideTarget : NSObject
{
@public
  int count;
}
- (void) slid: (id)sender;
@end

@implementation SlideTarget
- (void) slid: (id)sender
{
  count++;
}
@end

int
main(int argc, const char **argv)
{
  SlideTarget *t;
  NSSlider *sl;
  NSWindow *w;
  int before;

  START_SET("NSSlider interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      t = AUTORELEASE([[SlideTarget alloc] init]);

      /* A wide, short frame makes a horizontal slider. */
      sl = AUTORELEASE([[NSSlider alloc]
        initWithFrame: NSMakeRect(10, 10, 100, 20)]);
      [sl setMinValue: 0.0];
      [sl setMaxValue: 10.0];
      [sl setDoubleValue: 5.0];
      [sl setTarget: t];
      [sl setAction: @selector(slid:)];

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 40)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: sl];

      /* Clicking near the right of the track raises the value. */
      before = t->count;
      GSClick(w, sl, NSMakePoint(92, 10));
      PASS([sl doubleValue] > 5.0 && t->count > before,
        "clicking the right of the track raises the value and sends the action");

      /* Clicking near the left of the track lowers the value. */
      [sl setDoubleValue: 5.0];
      before = t->count;
      GSClick(w, sl, NSMakePoint(8, 10));
      PASS([sl doubleValue] < 5.0 && t->count > before,
        "clicking the left of the track lowers the value and sends the action");

      /* The value stays within the configured range. */
      PASS([sl doubleValue] >= 0.0 && [sl doubleValue] <= 10.0,
        "the value stays within the slider range");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSlider interaction")

  return 0;
}
