/* -[NSApplication setApplicationIconImage:] keeps a drawable image even when
   the image was produced by drawing into it (whose only representation is a
   cached one, which -[NSImage copyWithZone:] drops).  A red image is set as
   the application icon and read back; it must still contain the red drawing.
   Drawing needs the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSApplication applicationIconImage")

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
      NSImage *img = AUTORELEASE([[NSImage alloc]
        initWithSize: NSMakeSize(48, 48)]);
      [img lockFocus];
      [[NSColor redColor] set];
      NSRectFill(NSMakeRect(0, 0, 48, 48));
      [img unlockFocus];

      [NSApp setApplicationIconImage: img];
      NSImage *icon = [NSApp applicationIconImage];

      pass(icon != nil && [[icon representations] count] > 0,
           "the application icon keeps a representation");

      NSBitmapImageRep *bitmap = nil;
      NSEnumerator *e = [[icon representations] objectEnumerator];
      NSImageRep *rep;
      while ((rep = [e nextObject]) != nil)
        {
          if ([rep isKindOfClass: [NSBitmapImageRep class]])
            bitmap = (NSBitmapImageRep *)rep;
        }
      pass(bitmap != nil, "the application icon has a bitmap representation");

      if (bitmap != nil)
        {
          NSColor *c = [[bitmap colorAtX: 24 y: 24]
            colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
          pass(c != nil
               && [c redComponent] > 0.9
               && [c greenComponent] < 0.1
               && [c blueComponent] < 0.1,
               "the application icon keeps the red drawing");
        }
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

  END_SET("NSApplication applicationIconImage")

  DESTROY(arp);
  return 0;
}
