/* A drag over a browser offers the delegate a row and a column to drop on,
   and the drop itself goes to whatever the delegate settled on. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSURL.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSPasteboard.h>

static NSArray *rows;

@interface FakeDrag : NSObject <NSDraggingInfo>
{
@public
  NSPoint location;
}
@end

@implementation FakeDrag
- (NSWindow *) draggingDestinationWindow
{
  return nil;
}
- (NSPoint) draggingLocation
{
  return location;
}
- (NSPasteboard *) draggingPasteboard
{
  return [NSPasteboard pasteboardWithName: NSDragPboard];
}
- (NSInteger) draggingSequenceNumber
{
  return 1;
}
- (id) draggingSource
{
  return nil;
}
- (NSDragOperation) draggingSourceOperationMask
{
  return NSDragOperationEvery;
}
- (NSImage *) draggedImage
{
  return nil;
}
- (NSPoint) draggedImageLocation
{
  return location;
}
- (void) slideDraggedImageTo: (NSPoint)screenPoint
{
}
- (NSArray *) namesOfPromisedFilesDroppedAtDestination: (NSURL *)dropDestination
{
  return nil;
}
@end

@interface Dropper : NSObject
{
@public
  NSInteger validateCalls;
  NSInteger acceptCalls;
  NSInteger proposedRow;
  NSInteger proposedColumn;
  NSBrowserDropOperation proposedOperation;
  NSInteger acceptedRow;
  NSInteger acceptedColumn;
  NSBrowserDropOperation acceptedOperation;
  BOOL retarget;
  NSInteger retargetRow;
  NSDragOperation answer;
}
@end

@implementation Dropper
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  return [rows count];
}
- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
	   atRow: (NSInteger)row
	  column: (NSInteger)column
{
  [cell setStringValue: [rows objectAtIndex: row]];
  [cell setLeaf: YES];
}
- (NSDragOperation) browser: (NSBrowser *)browser
	       validateDrop: (id <NSDraggingInfo>)info
		proposedRow: (NSInteger *)row
		     column: (NSInteger *)column
	      dropOperation: (NSBrowserDropOperation *)dropOperation
{
  validateCalls++;
  proposedRow = *row;
  proposedColumn = *column;
  proposedOperation = *dropOperation;
  if (retarget)
    {
      *row = retargetRow;
    }
  return answer;
}
- (BOOL) browser: (NSBrowser *)browser
      acceptDrop: (id <NSDraggingInfo>)info
	   atRow: (NSInteger)row
	  column: (NSInteger)column
   dropOperation: (NSBrowserDropOperation)dropOperation
{
  acceptCalls++;
  acceptedRow = row;
  acceptedColumn = column;
  acceptedOperation = dropOperation;
  return YES;
}
@end

static NSBrowser *browser;
static NSMatrix *matrix;

static void
buildBrowser(id delegate)
{
  browser = AUTORELEASE([[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 400, 200)]);
  [browser setMaxVisibleColumns: 1];
  [browser setDelegate: delegate];
  [browser loadColumnZero];
  matrix = [browser matrixInColumn: 0];
}

/* A point a given fraction down the band row occupies, in the coordinates a
   drag reports. */
static NSPoint
pointInRow(NSInteger row, CGFloat fraction)
{
  CGFloat height = [matrix cellSize].height + [matrix intercellSpacing].height;
  NSPoint p = NSMakePoint([matrix cellSize].width / 2,
			  row * height + fraction * height);

  return [browser convertPoint: p fromView: matrix];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  FakeDrag *drag;
  Dropper *dropper;

  START_SET("NSBrowser drop delegate methods")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  rows = [NSArray arrayWithObjects: @"alpha", @"beta", @"Bravo", @"charlie",
		  @"delta", nil];
  drag = AUTORELEASE([[FakeDrag alloc] init]);

  NS_DURING
    {
      dropper = AUTORELEASE([[Dropper alloc] init]);
      dropper->answer = NSDragOperationCopy;
      buildBrowser(dropper);

      drag->location = pointInRow(2, 0.5);
      PASS([browser draggingEntered: drag] == NSDragOperationCopy,
	"the operation the delegate returns is what the drag is told");
      PASS(dropper->validateCalls == 1,
	"a drag over the browser asks the delegate to validate the drop");
      PASS(dropper->proposedRow == 2 && dropper->proposedColumn == 0,
	"the row and column under the drag are what is proposed");
      PASS(dropper->proposedOperation == NSBrowserDropOn,
	"a drag over the middle of a row proposes dropping on it");

      drag->location = pointInRow(3, 0.05);
      [browser draggingUpdated: drag];
      PASS(dropper->proposedRow == 3
	&& dropper->proposedOperation == NSBrowserDropAbove,
	"a drag near the top of a row proposes dropping above it");

      drag->location = pointInRow([rows count], 0.5);
      [browser draggingUpdated: drag];
      PASS(dropper->proposedRow == (NSInteger)[rows count],
	"a drag past the last row proposes the row after it");

      dropper->retarget = YES;
      dropper->retargetRow = 4;
      drag->location = pointInRow(1, 0.5);
      [browser draggingUpdated: drag];
      PASS([browser performDragOperation: drag] == YES,
	"the drop is accepted when the delegate accepts it");
      PASS(dropper->acceptCalls == 1 && dropper->acceptedRow == 4
	&& dropper->acceptedColumn == 0,
	"the drop lands on the row the delegate moved it to");

      dropper = AUTORELEASE([[Dropper alloc] init]);
      dropper->answer = NSDragOperationNone;
      buildBrowser(dropper);
      drag->location = pointInRow(2, 0.5);
      PASS([browser draggingEntered: drag] == NSDragOperationNone,
	"a delegate that refuses the drag is what the drag is told");
      PASS([browser performDragOperation: drag] == NO
	&& dropper->acceptCalls == 0,
	"a refused drag does not drop");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBrowser drop delegate methods")

  DESTROY(arp);

  return 0;
}
