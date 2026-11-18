/* Verify page coverage and ordering through the PDF printing pipeline. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PaginationView : NSView
{
@public
  NSMutableArray *rects;
  CGFloat adjustment;
  NSUInteger adjustments;
}

@end

@implementation PaginationView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    rects = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(rects);
  DEALLOC;
}

- (CGFloat) widthAdjustLimit
{
  return 1;
}

- (CGFloat) heightAdjustLimit
{
  return 1;
}

- (void) adjustPageWidthNew: (CGFloat *)right left: (CGFloat)left
                    right: (CGFloat)oldRight limit: (CGFloat)limit
{
  adjustments++;
  *right = adjustment ? MIN(oldRight, left + adjustment) : oldRight;
}

- (void) adjustPageHeightNew: (CGFloat *)bottom top: (CGFloat)top
                    bottom: (CGFloat)oldBottom limit: (CGFloat)limit
{
  adjustments++;
  *bottom = adjustment ? MIN(oldBottom, top + adjustment) : oldBottom;
}

- (void) beginPageInRect: (NSRect)rect atPlacement: (NSPoint)point
{
  [rects addObject: [NSValue valueWithRect: rect]];
  [super beginPageInRect: rect atPlacement: point];
}

- (void) drawRect: (NSRect)rect
{
  [[NSColor blackColor] set];
  NSRectFill(rect);
}

@end

/* A subview whose width and height break decisions differ. */
@interface WidthView : NSView

@end

@implementation WidthView

- (void) adjustPageWidthNew: (CGFloat *)right left: (CGFloat)left
                    right: (CGFloat)oldRight limit: (CGFloat)limit
{
  *right = oldRight - 10;
}

@end

static void
checkPages(NSRect bounds, CGFloat scale, CGFloat adjustment, BOOL columns,
           BOOL reverse, NSInteger first, NSInteger last,
           NSPrintingPaginationMode horizontal,
           NSPrintingPaginationMode vertical)
{
  NSPrintInfo *info = [[NSPrintInfo alloc] initWithDictionary: nil];
  PaginationView *view = [[PaginationView alloc] initWithFrame:
    NSMakeRect(0, 0, NSWidth(bounds), NSHeight(bounds))];
  NSMutableData *data = [NSMutableData data];
  NSPrintOperation *operation;
  NSUInteger nx, ny, total, count, i;
  CGFloat step = adjustment ? adjustment : 100 / scale;
  BOOL correct = YES;

  if (horizontal == NSFitPagination)
    step = NSWidth(bounds);
  if (vertical == NSFitPagination)
    step = MAX(step, NSHeight(bounds));

  [view setBounds: bounds];
  view->adjustment = adjustment;
  [info setPaperSize: NSMakeSize(120, 120)];
  [info setLeftMargin: 10];
  [info setRightMargin: 10];
  [info setTopMargin: 10];
  [info setBottomMargin: 10];
  [info setHorizontalPagination: horizontal];
  [info setVerticalPagination: vertical];
  [[info dictionary] setObject: [NSNumber numberWithDouble: scale]
                       forKey: NSPrintScalingFactor];
  [[info dictionary] setObject: columns ? @"Columns" : @"Rows"
                       forKey: NSPrintPageDirection];
  if (first != 0)
    {
      [[info dictionary] setObject: [NSNumber numberWithBool: NO] forKey: NSPrintAllPages];
      [[info dictionary] setObject: [NSNumber numberWithInteger: first] forKey: NSPrintFirstPage];
      [[info dictionary] setObject: [NSNumber numberWithInteger: last] forKey: NSPrintLastPage];
    }
  operation = [NSPrintOperation PDFOperationWithView: view insideRect: bounds
                                             toData: data printInfo: info];
  [[info dictionary] setObject: @"Automatic pagination regression document"
                       forKey: @"TestTitle"];
  [operation setPageOrder: reverse ? NSDescendingPageOrder : NSAscendingPageOrder];
  PASS([operation runOperation], "pagination PDF operation succeeds");
  nx = horizontal == NSClipPagination ? 1 : ceil(NSWidth(bounds) / step);
  ny = vertical == NSClipPagination ? 1 : ceil(NSHeight(bounds) / step);
  total = nx * ny;
  count = first ? last - first + 1 : total;
  PASS([[[[operation printInfo] dictionary] objectForKey: @"NSPrintTotalPages"] integerValue] == total,
       "total page count includes adjusted overflow pages");
  PASS([view->rects count] == count, "all requested adjusted pages are rendered");
  for (i = 0; i < [view->rects count] && i < count; i++)
    {
      NSUInteger page = reverse ? (first ? last : total) - i - 1
                               : (first ? first - 1 : 0) + i;
      NSUInteger x = columns ? page / ny : page % nx;
      NSUInteger y = columns ? page % ny : page / nx;
      NSRect expected = NSMakeRect(NSMinX(bounds) + x * step,
                                  NSMinY(bounds) + y * step,
                                  MIN(step, NSWidth(bounds) - x * step),
                                  MIN(step, NSHeight(bounds) - y * step));
      if (!NSEqualRects([[view->rects objectAtIndex: i] rectValue], expected))
        correct = NO;
    }
  PASS(correct, "page rectangles cover the content in the requested order");
  PASS(view->adjustments <= 2 * (nx + ny), "pagination work grows linearly, including reverse output");
  {
    NSPDFImageRep *pdf = [[NSPDFImageRep alloc] initWithData: data];
    PASS([pdf pageCount] == count, "PDF physical page count matches the requested range");
    RELEASE(pdf);
  }
  RELEASE(view);
  RELEASE(info);
}

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSView *parent;
  WidthView *child;
  CGFloat right;

  START_SET("Automatic pagination")
  [NSApplication sharedApplication];
  checkPages(NSMakeRect(250, 350, 200, 200), 1, 0, NO, NO, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(-250, -350, 200, 200), 1, 0, NO, NO, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 90, NO, NO, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 90, YES, NO, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 90, NO, YES, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 90, NO, NO, 8, 9, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 90, YES, YES, 8, 9, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(250, 350, 400, 400), 0.5, 0, NO, NO, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 0, NO, NO, 0, 0, NSClipPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 200, 200), 1, 0, NO, NO, 0, 0, NSAutoPagination, NSClipPagination);
  checkPages(NSMakeRect(0, 0, 100, 10000), 1, 0, NO, YES, 0, 0, NSAutoPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 400, 400), 1, 0, NO, NO, 0, 0, NSFitPagination, NSFitPagination);
  checkPages(NSMakeRect(0, 0, 100, 300), 1, 0, NO, NO, 0, 0, NSFitPagination, NSAutoPagination);
  checkPages(NSMakeRect(0, 0, 300, 100), 1, 0, NO, NO, 0, 0, NSAutoPagination, NSFitPagination);
  parent = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)];
  child = [[WidthView alloc] initWithFrame: NSMakeRect(20, 30, 150, 150)];
  [parent addSubview: child];
  [parent adjustPageWidthNew: &right left: 0 right: 100 limit: 80];
  PASS(right == 90, "horizontal page adjustment calls the subview's width method");
  RELEASE(child);
  RELEASE(parent);
  END_SET("Automatic pagination")
  RELEASE(pool);
  return 0;
}
