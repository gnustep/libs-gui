/* GSRenderTest.h

   Shared support for local "exercise" tests (the render and interaction tiers
   that need a real window server): render a view, save a PNG to look at,
   compare against a locally captured golden, sample regions structurally, and
   drive controls and panels with synthesised events.

   These helpers require a backend, so a test that uses them must keep the
   usual START_SET / SKIP guard.  Artifacts (PNGs and goldens) are written
   outside the source tree (GS_TEST_ARTIFACTS, else /tmp/gs-render-artifacts)
   and are never committed: the golden comparison is a local aid, while the
   region assertions are what run in CI.

   This is header-only (static inline) so each test tool gets its own copy.
*/

#ifndef GSRenderTest_h
#define GSRenderTest_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <math.h>

static inline NSString *
GSArtifactsDir(void)
{
  const char *env = getenv("GS_TEST_ARTIFACTS");
  NSString *dir = [NSString stringWithUTF8String:
    env ? env : "/tmp/gs-render-artifacts"];
  [[NSFileManager defaultManager] createDirectoryAtPath: dir
    withIntermediateDirectories: YES attributes: nil error: NULL];
  return dir;
}

/* Capture a window's content view (with its whole subview hierarchy).  The
   window is briefly ordered in so that a deferred backing store exists to
   read back from, then ordered out again. */
static inline NSBitmapImageRep *
GSRenderWindow(NSWindow *w)
{
  NSView *cv = [w contentView];
  NSRect b = [cv bounds];
  NSBitmapImageRep *rep;

  [w orderFront: nil];
  [w display];
  [cv lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: b];
  [cv unlockFocus];
  [w orderOut: nil];
  return [rep autorelease];
}

/* Render a standalone view (at its bounds) into a bitmap, drawing its whole
   subview hierarchy, through a temporary offscreen window. */
static inline NSBitmapImageRep *
GSRenderView(NSView *v)
{
  NSRect b = [v bounds];
  NSWindow *w = [[NSWindow alloc]
    initWithContentRect: b styleMask: NSBorderlessWindowMask
                backing: NSBackingStoreBuffered defer: NO];

  [w setContentView: v];
  return GSRenderWindow(w);
}

/* Save a bitmap as PNG under <artifacts>/<name>.png; return the path. */
static inline NSString *
GSSavePNG(NSBitmapImageRep *rep, NSString *name)
{
  NSString *path = [[GSArtifactsDir()
    stringByAppendingPathComponent: name]
    stringByAppendingPathExtension: @"png"];
  [[rep representationUsingType: NSPNGFileType properties: nil]
    writeToFile: path atomically: YES];
  return path;
}

/* Local golden aid: first run captures <artifacts>/golden/<name>.png and
   returns YES; later runs return whether the mean per-channel difference is
   within tol.  Never used as the CI gate (goldens are not portable). */
static inline BOOL
GSMatchesGolden(NSBitmapImageRep *rep, NSString *name, CGFloat tol)
{
  NSString *gdir = [GSArtifactsDir() stringByAppendingPathComponent: @"golden"];
  NSString *path;
  [[NSFileManager defaultManager] createDirectoryAtPath: gdir
    withIntermediateDirectories: YES attributes: nil error: NULL];
  path = [[gdir stringByAppendingPathComponent: name]
    stringByAppendingPathExtension: @"png"];

  if (![[NSFileManager defaultManager] fileExistsAtPath: path])
    {
      [[rep representationUsingType: NSPNGFileType properties: nil]
        writeToFile: path atomically: YES];
      return YES;
    }
  else
    {
      NSBitmapImageRep *g = [NSBitmapImageRep imageRepWithContentsOfFile: path];
      NSInteger W = [rep pixelsWide], H = [rep pixelsHigh], x, y, n = 0;
      double acc = 0.0;

      if ([g pixelsWide] != W || [g pixelsHigh] != H)
        return NO;
      for (y = 0; y < H; y += 2)
        for (x = 0; x < W; x += 2)
          {
            CGFloat ar,ag,ab,aa, cr,cg,cb,ca;
            [[[rep colorAtX: x y: y]
              colorUsingColorSpaceName: NSDeviceRGBColorSpace]
              getRed:&ar green:&ag blue:&ab alpha:&aa];
            [[[g colorAtX: x y: y]
              colorUsingColorSpaceName: NSDeviceRGBColorSpace]
              getRed:&cr green:&cg blue:&cb alpha:&ca];
            n++;
            if (isnan(ar) || isnan(cr)) continue;
            acc += (fabs(ar-cr)+fabs(ag-cg)+fabs(ab-cb))/3.0;
          }
      return (n > 0 && (acc/n) <= tol);
    }
}

/* Darkest brightness in a region (ignoring transparent pixels): a proxy for
   how dark drawn text or a filled shape is. */
static inline CGFloat
GSRegionMinBrightness(NSBitmapImageRep *rep, NSRect r)
{
  NSInteger x, y;
  CGFloat lo = 1.0;

  for (y = (NSInteger)NSMinY(r); y < (NSInteger)NSMaxY(r); y++)
    for (x = (NSInteger)NSMinX(r); x < (NSInteger)NSMaxX(r); x++)
      {
        CGFloat cr,cg,cb,ca;
        [[[rep colorAtX: x y: y]
          colorUsingColorSpaceName: NSDeviceRGBColorSpace]
          getRed:&cr green:&cg blue:&cb alpha:&ca];
        if (isnan(cr) || ca < 0.1) continue;
        if ((cr+cg+cb)/3.0 < lo) lo = (cr+cg+cb)/3.0;
      }
  return lo;
}

/* Whether a region contains any drawn content darker than a light background
   (text, borders, icons), rather than being blank. */
static inline BOOL
GSRegionHasContent(NSBitmapImageRep *rep, NSRect r)
{
  return GSRegionMinBrightness(rep, r) < 0.7;
}

/* Deliver a synthesised click to a control.  Both events are queued, then the
   loop is pumped: dispatching the mouse-down starts the control's tracking
   loop, which dequeues the mouse-up itself. */
static inline void
GSClick(NSWindow *w, NSView *v, NSPoint pInView)
{
  NSPoint p = [v convertPoint: pInView toView: nil];
  NSEvent *down = [NSEvent mouseEventWithType: NSLeftMouseDown
    location: p modifierFlags: 0 timestamp: 0 windowNumber: [w windowNumber]
    context: nil eventNumber: 1 clickCount: 1 pressure: 1.0];
  NSEvent *up = [NSEvent mouseEventWithType: NSLeftMouseUp
    location: p modifierFlags: 0 timestamp: 0 windowNumber: [w windowNumber]
    context: nil eventNumber: 2 clickCount: 1 pressure: 1.0];
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 1.0];
  NSEvent *e;

  [w makeKeyAndOrderFront: nil];
  [NSApp postEvent: down atStart: NO];
  [NSApp postEvent: up atStart: NO];
  while ([deadline timeIntervalSinceNow] > 0
    && (e = [NSApp nextEventMatchingMask: NSAnyEventMask
                              untilDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]
                                 inMode: NSDefaultRunLoopMode dequeue: YES]) != nil)
    {
      [NSApp sendEvent: e];
    }
}

/* Run a panel modally but end the session ourselves by performing `dismiss`
   (e.g. @selector(ok:) or @selector(cancel:)), so the panel displays and lays
   out without blocking on the user.  A manual modal session is pumped a few
   cycles to let the panel appear, then dismissed; this avoids relying on a
   timer firing inside -runModal (which will not wake without server events).
   Returns the modal result code. */
static inline NSInteger
GSRunModalDismissing(id panel, SEL dismiss)
{
  NSModalSession session = [NSApp beginModalSessionForWindow: panel];
  NSInteger code = NSRunContinuesResponse;
  int i;

  for (i = 0; i < 5 && code == NSRunContinuesResponse; i++)
    code = [NSApp runModalSession: session];

  if (code == NSRunContinuesResponse)
    {
      [panel performSelector: dismiss withObject: panel];
      code = [NSApp runModalSession: session];
    }
  [NSApp endModalSession: session];
  return code;
}

#endif /* GSRenderTest_h */
