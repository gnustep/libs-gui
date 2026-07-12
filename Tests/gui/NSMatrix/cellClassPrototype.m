/* A matrix that uses a cell prototype has no cell class, as on OS X:
   -cellClass returns Nil while a prototype is set, and returns the class
   again once a cell class is set (which clears the prototype). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSMatrix.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMatrix cell class vs prototype")

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

  /* Built with a prototype: no cell class. */
  {
    NSButtonCell *proto = AUTORELEASE([[NSButtonCell alloc] init]);
    NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                             mode: NSListModeMatrix
                                        prototype: proto
                                     numberOfRows: 1
                                  numberOfColumns: 1]);

    pass([m prototype] != nil, "the prototype is set");
    pass([m cellClass] == Nil, "a matrix with a prototype has no cell class");
  }

  /* Setting a cell class clears the prototype and reports the class. */
  {
    NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);

    [m setCellClass: [NSButtonCell class]];
    pass([m cellClass] == [NSButtonCell class], "setCellClass: reports the cell class");
    pass([m prototype] == nil, "setCellClass: clears the prototype");
  }

  /* Setting a prototype on that matrix hides the cell class again. */
  {
    NSMatrix *m = AUTORELEASE([[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);

    [m setCellClass: [NSButtonCell class]];
    [m setPrototype: AUTORELEASE([[NSButtonCell alloc] init])];
    pass([m cellClass] == Nil, "setPrototype: makes the cell class Nil again");
  }

  END_SET("NSMatrix cell class vs prototype")

  DESTROY(arp);
  return 0;
}
