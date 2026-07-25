#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSOpenGLView.h>
#import <AppKit/NSOpenGL.h>

/* NSOpenGLView pixel-format state: a view gets the default pixel format and its
   pixel format round-trips.  (NSOpenGLView wraps OpenGL, so this checks
   GNUstep's own behaviour.)  Building the GL pixel format needs a display, so
   the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenGLView config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSOpenGLPixelFormat *fmt = [NSOpenGLView defaultPixelFormat];

      if (fmt == nil)
        {
          SKIP("No OpenGL pixel format available on this display")
        }
      else
        {
          NSOpenGLView *v = AUTORELEASE([[NSOpenGLView alloc]
            initWithFrame: NSMakeRect(0, 0, 100, 100)]);

          PASS([v pixelFormat] != nil,
            "a new OpenGL view has a pixel format");

          [v setPixelFormat: nil];
          PASS([v pixelFormat] == nil,
            "the pixel format can be cleared");
          [v setPixelFormat: fmt];
          PASS([v pixelFormat] == fmt, "the pixel format round-trips");
        }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenGLView config")
  DESTROY(arp);
  return 0;
}
