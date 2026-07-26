/* Interaction exercise for NSMatrix action dispatch: -sendAction sends the
   selected cell's action to its target, a disabled selected cell suppresses
   it, -sendAction:to:forAllCells: reaches every cell, and -sendDoubleAction
   sends the matrix double action.  These drive the dispatch directly, so no
   window-server event loop is needed, but the set keeps the usual backend skip
   guard because building the matrix and its cells touches the graphics
   backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSActionCell.h>
#include <AppKit/NSMatrix.h>

@interface Recorder : NSObject
{
@public
  int count;
  id last;
}
- (void) fired: (id)sender;
- (id) visit: (id)cell;
@end

@implementation Recorder
- (void) fired: (id)sender
{
  count++;
  last = sender;
}
- (id) visit: (id)cell
{
  count++;
  return self;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Recorder *r;
  NSMatrix *m;
  NSActionCell *proto;

  START_SET("NSMatrix action")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[Recorder alloc] init]);
      proto = AUTORELEASE([[NSActionCell alloc] initTextCell: @""]);

      m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)
                 mode: NSRadioModeMatrix
            prototype: proto
         numberOfRows: 2
      numberOfColumns: 2]);

      /* -sendAction dispatches the selected cell's action to its target. */
      [m selectCellAtRow: 0 column: 0];
      [[m cellAtRow: 0 column: 0] setTarget: r];
      [[m cellAtRow: 0 column: 0] setAction: @selector(fired:)];
      PASS([m sendAction] == YES,
        "sendAction reports success for the selected cell");
      PASS(r->count == 1, "sendAction sends the selected cell's action");

      /* A disabled selected cell suppresses the action. */
      r->count = 0;
      [[m cellAtRow: 0 column: 0] setEnabled: NO];
      PASS([m sendAction] == NO,
        "sendAction reports failure for a disabled selected cell");
      PASS(r->count == 0, "a disabled selected cell sends nothing");

      /* -sendAction:to:forAllCells:YES reaches every cell in the matrix. */
      r->count = 0;
      [m sendAction: @selector(visit:) to: r forAllCells: YES];
      PASS(r->count == 4, "sendAction:to:forAllCells: visits every cell");

      /* -sendDoubleAction sends the matrix double action to its target. */
      r->count = 0;
      [[m cellAtRow: 0 column: 0] setEnabled: YES];
      [m setTarget: r];
      [m setDoubleAction: @selector(fired:)];
      [m sendDoubleAction];
      PASS(r->count == 1, "sendDoubleAction sends the double action");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix action")

  DESTROY(arp);
  return 0;
}
