/* Interaction exercise for NSMatrix: a real click on a cell selects that cell
   and sends the matrix action.  The click point is the centre of the cell's
   frame, which is exact grid geometry, so this is not theme dependent.  The
   click is delivered as real events through GSClick, so this needs a window
   server and keeps the usual START_SET / SKIP guard. */
#import "Testing.h"
#import "../GSRenderTest.h"

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSWindow.h>

@interface Hit : NSObject
{
@public
  int count;
}
- (void) hit: (id)sender;
@end

@implementation Hit
- (void) hit: (id)sender
{
  count++;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Hit *h;
  NSMatrix *m;
  NSButtonCell *proto;
  NSWindow *w;
  NSRect cf;

  START_SET("NSMatrix click")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      h = AUTORELEASE([[Hit alloc] init]);
      proto = AUTORELEASE([[NSButtonCell alloc] initTextCell: @"x"]);

      m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)
                 mode: NSRadioModeMatrix
            prototype: proto
         numberOfRows: 2
      numberOfColumns: 2]);
      [m setTarget: h];
      [m setAction: @selector(hit:)];

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 120)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: m];

      /* Click the centre of the lower-right cell. */
      cf = [m cellFrameAtRow: 1 column: 1];
      GSClick(w, m, NSMakePoint(NSMidX(cf), NSMidY(cf)));

      PASS([m selectedRow] == 1 && [m selectedColumn] == 1,
        "clicking a cell selects it");
      PASS(h->count > 0, "clicking a cell sends the matrix action");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix click")

  DESTROY(arp);
  return 0;
}
