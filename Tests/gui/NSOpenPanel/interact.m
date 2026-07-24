#import "Testing.h"
#import "../GSRenderTest.h"

/* Local interaction exercise for NSOpenPanel: drive the panel's modal session
   the way a user would end it, and check the result it returns.  Needs a
   window server, so it skips without one. */

static NSString *
dummyDir(void)
{
  return [[[[[NSBundle mainBundle] bundlePath]
    stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]
    stringByAppendingPathComponent: @"dummy"];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenPanel interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSString *dir = dummyDir();

      /* Confirming returns NSOKButton and a non-empty list of URLs.  With no
         browser selection the current directory is the result, so directories
         are enabled here; browser-driven file choice is exercised elsewhere. */
      {
        NSOpenPanel *p = [NSOpenPanel openPanel];
        NSInteger r;
        [p setCanChooseFiles: YES];
        [p setCanChooseDirectories: YES];
        [p setAllowsMultipleSelection: NO];
        [p setDirectory: dir];
        r = GSRunModalDismissing(p, @selector(ok:));
        PASS(r == NSOKButton, "confirming with ok: returns NSOKButton");
        PASS([[p URLs] count] >= 1 && [p URL] != nil,
          "the OK result is a non-empty list of URLs");
      }

      /* Cancelling returns NSCancelButton. */
      {
        NSOpenPanel *p = [NSOpenPanel openPanel];
        NSInteger r;
        [p setDirectory: dir];
        r = GSRunModalDismissing(p, @selector(cancel:));
        PASS(r == NSCancelButton, "cancelling returns NSCancelButton");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenPanel interaction")
  DESTROY(arp);
  return 0;
}
