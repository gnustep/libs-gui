/* NSTextView posts NSTextDidChangeNotification and calls the delegate's
   -textDidChange: when its text changes through -insertText:, and the inserted
   text lands in the storage.  config.m covers the view configuration; this
   covers the text-change notification.  The text view lays out through the
   theme and font backend, so the set is skipped when the backend is
   unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>

@interface Recorder : NSObject
{
@public
  int notifCount;
  int delegateCount;
}
- (void) changed: (NSNotification *)n;
- (void) textDidChange: (NSNotification *)n;
@end

@implementation Recorder
- (void) changed: (NSNotification *)n
{
  notifCount++;
}
- (void) textDidChange: (NSNotification *)n
{
  delegateCount++;
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Recorder *r;
  NSTextView *tv;
  NSWindow *w;
  NSNotificationCenter *nc;

  START_SET("NSTextView change notification")

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
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      tv = AUTORELEASE([[NSTextView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      [tv setEditable: YES];
      [tv setDelegate: r];

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 220, 120)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: tv];

      [nc addObserver: r
             selector: @selector(changed:)
                 name: NSTextDidChangeNotification
               object: tv];

      /* Typing text posts the change notification and reaches the delegate. */
      [tv insertText: @"hello"];
      PASS(r->notifCount >= 1, "inserting text posts the text change notification");
      PASS(r->delegateCount >= 1, "the delegate receives textDidChange:");
      PASS([[tv string] isEqualToString: @"hello"],
        "the inserted text lands in the text view");

      /* Typing more text posts again. */
      [tv insertText: @" world"];
      PASS(r->notifCount >= 2, "inserting more text posts again");
      PASS([[tv string] isEqualToString: @"hello world"],
        "the further text is appended");

      [nc removeObserver: r];
      [tv setDelegate: nil];
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

  END_SET("NSTextView change notification")

  DESTROY(arp);
  return 0;
}
