#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSClipView state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSClipView *clip = AUTORELEASE([[NSClipView alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      NSView *doc = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 500, 500)]);
      [clip setDocumentView: doc];

      /* Document and state round-trips. Checked against AppKit. */
      PASS([clip documentView] == doc, "setDocumentView: round-trips");
      PASS([doc superview] == clip,
        "the document view's superview is the clip view");

      [clip setCopiesOnScroll: NO];
      PASS([clip copiesOnScroll] == NO, "setCopiesOnScroll: round-trips");
      [clip setDrawsBackground: NO];
      PASS([clip drawsBackground] == NO, "setDrawsBackground: round-trips");
      [clip setBackgroundColor: [NSColor redColor]];
      PASS([[clip backgroundColor] isEqual: [NSColor redColor]],
        "setBackgroundColor: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSClipView state")
  DESTROY(arp);
  return 0;
}
