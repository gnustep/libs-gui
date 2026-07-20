/* A text field that draws its background fills its interior with the
   background colour.  This is a render regression lock (GNUstep against
   itself), not a pixel comparison against AppKit.  The field uses the theme
   and font backend, so the set is skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTextField rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 60, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSTextField *tf = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(0, 0, 60, 24)]);
      [tf setBezeled: NO];
      [tf setBordered: NO];
      [tf setDrawsBackground: YES];
      [tf setBackgroundColor: [NSColor redColor]];
      [w setContentView: tf];

      [tf lockFocus];
      [tf drawRect: [tf bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 60, 24)]);
      [tf unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 60 && [rep pixelsHigh] == 24,
        "a text field renders into a bitmap of its bounds");

      NSColor *centre = [[rep colorAtX: 30 y: 12]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(centre != nil
           && [centre redComponent] > 0.9
           && [centre greenComponent] < 0.1
           && [centre blueComponent] < 0.1,
        "the interior is filled with the red background colour");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTextField rendering")
  DESTROY(arp);
  return 0;
}
