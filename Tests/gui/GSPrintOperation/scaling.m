/* User scaling must remain independent of fit-to-page scaling. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface ScalingView : NSView
{
@public
  CGFloat expectedScale;
  NSUInteger drawn;
  BOOL customPages;
}

@end

@implementation ScalingView

- (BOOL) knowsPageRange: (NSRange *)range
{
  if (!customPages)
    return NO;
  *range = NSMakeRange(1, 1);
  return YES;
}

- (NSRect) rectForPage: (NSInteger)page
{
  return page == 1 ? [self bounds] : NSZeroRect;
}

- (void) drawRect: (NSRect)rect
{
  NSAffineTransform *transform = [[NSGraphicsContext currentContext]
    GSCurrentCTM];
  NSSize size = [transform transformSize: NSMakeSize(100, 100)];

  drawn++;
  PASS(fabs(size.width - 100 * expectedScale) < 0.01
       && fabs(size.height - 100 * expectedScale) < 0.01,
       "rendered dimensions combine pagination and user scaling");
  [[NSColor blackColor] set];
  NSRectFill(rect);
}

@end

static void
checkScaling(NSSize size, NSPrintingPaginationMode horizontal,
             NSPrintingPaginationMode vertical, CGFloat userScale,
             CGFloat expectedScale, NSUInteger pages, BOOL customPages)
{
  NSPrintInfo *info = [[NSPrintInfo alloc] initWithDictionary: nil];
  ScalingView *view = [[ScalingView alloc] initWithFrame:
    NSMakeRect(0, 0, size.width, size.height)];
  NSMutableData *data = [NSMutableData data];
  NSPrintOperation *operation;

  /* The printable area is 100 by 100 points. */
  [info setPaperSize: NSMakeSize(120, 120)];
  [info setLeftMargin: 10];
  [info setRightMargin: 10];
  [info setTopMargin: 10];
  [info setBottomMargin: 10];
  [info setHorizontalPagination: horizontal];
  [info setVerticalPagination: vertical];
  [[info dictionary] setObject: [NSNumber numberWithDouble: userScale]
                       forKey: NSPrintScalingFactor];
  view->expectedScale = expectedScale;
  view->customPages = customPages;
  operation = [NSPrintOperation PDFOperationWithView: view
    insideRect: [view bounds] toData: data printInfo: info];
  PASS([operation runOperation], "scaled PDF operation succeeds");
  PASS(view->drawn == pages, "scaling produces the expected page count");
  RELEASE(view);
  RELEASE(info);
}

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);

  START_SET("Print scaling")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  checkScaling(NSMakeSize(400, 200), NSFitPagination, NSFitPagination,
               1, 0.25, 1, NO);
  checkScaling(NSMakeSize(400, 200), NSFitPagination, NSFitPagination,
               0.5, 0.125, 1, NO);
  checkScaling(NSMakeSize(400, 200), NSFitPagination, NSFitPagination,
               2, 0.5, 1, NO);
  checkScaling(NSMakeSize(200, 400), NSFitPagination, NSFitPagination,
               0.5, 0.125, 1, NO);
  /* The unfitted axis must paginate using the combined scale as well. */
  checkScaling(NSMakeSize(200, 800), NSFitPagination, NSAutoPagination,
               0.5, 0.25, 2, NO);
  checkScaling(NSMakeSize(800, 200), NSAutoPagination, NSFitPagination,
               0.5, 0.25, 2, NO);
  checkScaling(NSMakeSize(200, 200), NSAutoPagination, NSAutoPagination,
               0.5, 0.5, 1, NO);
  checkScaling(NSMakeSize(400, 200), NSFitPagination, NSFitPagination,
               0.5, 0.5, 1, YES);

  END_SET("Print scaling")
  RELEASE(pool);
  return 0;
}
