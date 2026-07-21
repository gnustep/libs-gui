#import "Testing.h"
#import "GSRenderTest.h"

/* Local interaction exercise for NSSavePanel: drive the panel's modal session
   the way a user would end it (OK / Cancel) without blocking on input, and
   check the result it hands back.  Needs a window server, so it skips without
   one. */

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
  START_SET("NSSavePanel interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSString *dir = dummyDir();

      /* Ending the session with OK returns NSOKButton and keeps the result. */
      {
        NSSavePanel *p = [NSSavePanel savePanel];
        NSInteger r;
        [p setDirectory: dir];
        [p setNameFieldStringValue: @"chosen.txt"];
        r = GSRunModalDismissing(p, @selector(ok:), 0.2);
        PASS(r == NSOKButton, "dismissing with ok: returns NSOKButton");
        PASS([[[p URL] lastPathComponent] isEqual: @"chosen.txt"],
          "the OK result carries the entered name");
      }

      /* Ending the session with Cancel returns NSCancelButton. */
      {
        NSSavePanel *p = [NSSavePanel savePanel];
        NSInteger r;
        [p setDirectory: dir];
        r = GSRunModalDismissing(p, @selector(cancel:), 0.2);
        PASS(r == NSCancelButton, "dismissing with cancel: returns NSCancelButton");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSavePanel interaction")
  DESTROY(arp);
  return 0;
}
