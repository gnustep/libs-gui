/* -[NSBrowserCell copyWithZone:] gives the copy its own retained reference to
   the alternate image (rather than mistakenly retaining the receiver's), so a
   copy keeps the leaf/loaded flags and the alternate image. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSBrowserCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSBrowserCell copy")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSBrowserCell *cell = [[NSBrowserCell alloc] initTextCell: @"Item"];
  NSImage *img = [[NSImage alloc] initWithSize: NSMakeSize(8, 8)];
  [cell setLeaf: YES];
  [cell setLoaded: YES];
  [cell setAlternateImage: img];

  NSBrowserCell *copy = [cell copy];
  PASS(copy != nil, "-copy is non-nil");
  PASS(copy != cell, "-copy is a distinct object");
  PASS([copy isLeaf] == YES, "copy keeps the leaf flag");
  PASS([copy isLoaded] == YES, "copy keeps the loaded flag");
  PASS([copy alternateImage] == img, "copy keeps the alternate image");

  RELEASE(copy);
  RELEASE(cell);
  RELEASE(img);

  END_SET("NSBrowserCell copy")

  DESTROY(arp);
  return 0;
}
