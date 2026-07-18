/* Coverage for NSBrowserCell: init defaults (not a leaf, no alternate image),
   the leaf/loaded/alternateImage setters, set/reset (highlight and state), the
   +branchImage / +highlightedBranchImage class images, and highlightColorInView:.
   Every assertion was checked against Apple AppKit (macOS 26) and matches.
   Creating the cell and the theme images need the backend, so the body is
   guarded. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSBrowserCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSBrowserCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSBrowserCell *c = [[NSBrowserCell alloc] initTextCell: @"Item"];
  PASS(c != nil, "NSBrowserCell -initTextCell: returns an instance");

  /* Defaults that match AppKit. */
  PASS([c isLeaf] == NO, "a fresh cell is not a leaf");
  PASS([c alternateImage] == nil, "a fresh cell has no alternate image");

  /* Setters round-trip. */
  [c setLeaf: YES];
  PASS([c isLeaf] == YES, "setLeaf: round-trips");

  [c setLoaded: YES];
  PASS([c isLoaded] == YES, "setLoaded: round-trips");

  NSImage *img = [[NSImage alloc] initWithSize: NSMakeSize(8, 8)];
  [c setAlternateImage: img];
  PASS([c alternateImage] == img, "setAlternateImage: round-trips");

  /* set / reset drive the highlight and state together. */
  [c set];
  PASS([c isHighlighted] == YES && [c state] == NSOnState,
       "-set highlights the cell and turns its state on");
  [c reset];
  PASS([c isHighlighted] == NO && [c state] == NSOffState,
       "-reset unhighlights the cell and turns its state off");

  /* Class images and highlight colour are available. */
  PASS([NSBrowserCell branchImage] != nil, "+branchImage is not nil");
  PASS([NSBrowserCell highlightedBranchImage] != nil,
       "+highlightedBranchImage is not nil");
  PASS([c highlightColorInView: nil] != nil,
       "-highlightColorInView: is not nil");

  RELEASE(img);
  RELEASE(c);

  END_SET("NSBrowserCell basic")

  DESTROY(arp);
  return 0;
}
