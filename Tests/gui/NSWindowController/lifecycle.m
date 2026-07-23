#import "Testing.h"
#import "GSRenderTest.h"

/* Local lifecycle exercise for NSWindowController: a controller that builds its
   window in -loadView should load it lazily, send -windowDidLoad once, show and
   close it, and its window should actually render.  Needs a window server, so
   it skips without one. */

@interface ProgrammaticWC : NSWindowController
{
@public
  int didLoad;
}
@end

@implementation ProgrammaticWC
- (void) loadWindow
{
  NSWindow *w = [[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 200, 120)
              styleMask: NSTitledWindowMask
                backing: NSBackingStoreBuffered
                  defer: NO];
  NSButton *b = [[NSButton alloc] initWithFrame: NSMakeRect(20, 40, 160, 30)];
  [b setTitle: @"content"];
  [w setContentView: AUTORELEASE(b)];
  [self setWindow: AUTORELEASE(w)];
}
- (void) windowDidLoad { [super windowDidLoad]; didLoad++; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindowController lifecycle")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      ProgrammaticWC *wc = AUTORELEASE([[ProgrammaticWC alloc]
        initWithWindow: nil]);
      NSWindow *w;

      PASS([wc isWindowLoaded] == NO,
        "the window is not loaded before it is accessed");

      w = [wc window];
      PASS(w != nil, "the controller supplies its window");
      PASS([wc isWindowLoaded] == YES, "the window is loaded after access");
      PASS(wc->didLoad == 1, "windowDidLoad is sent once when the window loads");

      [wc showWindow: nil];
      PASS([w isVisible], "showWindow: orders the window in");

      {
        NSBitmapImageRep *rep = GSRenderWindow(w);
        GSSavePNG(rep, @"nswindowcontroller");
        PASS(rep != nil
          && [rep pixelsWide] == 200 && [rep pixelsHigh] == 120,
          "the controller's window renders at its content size");
        PASS(GSRegionHasContent(rep, NSMakeRect(20, 40, 160, 30)),
          "the window's content view has drawn content");
      }

      [wc close];
      PASS([w isVisible] == NO, "close orders the window out");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindowController lifecycle")
  DESTROY(arp);
  return 0;
}
