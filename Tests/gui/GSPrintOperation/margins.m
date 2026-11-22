/* Check physical page placement through the real PDF rendering pipeline.
   The flipped, explicitly paginated view models Bean's PageView: its page
   rectangles contain content only, at nonzero positions in a larger view. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface MarginView : NSView
{
@public
  BOOL customPages;
  BOOL flipped;
  BOOL customLocation;
  NSInteger pages;
  NSSize contentSize;
  NSPoint expected;
  int drawn;
}

@end

@implementation MarginView

- (BOOL) isFlipped
{
  return flipped;
}

- (BOOL) knowsPageRange: (NSRange *)range
{
  if (!customPages)
    return NO;
  *range = NSMakeRange(1, pages);
  return YES;
}

- (NSRect) rectForPage: (NSInteger)page
{
  return NSMakeRect(90, 100 + (page - 1) * 820,
                   contentSize.width, contentSize.height);
}

- (NSPoint) locationOfPrintRect: (NSRect)rect
{
  if (customLocation)
    return NSMakePoint(17, 23);
  return [super locationOfPrintRect: rect];
}

- (void) drawRect: (NSRect)dirty
{
  NSPrintOperation *operation = [NSPrintOperation currentOperation];
  NSRect rect = customPages ? [self rectForPage: [operation currentPage]] : [self bounds];
  NSPoint corner = NSMakePoint(NSMinX(rect), flipped ? NSMaxY(rect) : NSMinY(rect));
  NSPoint physical = [[[NSGraphicsContext currentContext] GSCurrentCTM] transformPoint: corner];

  drawn++;
  PASS(fabs(physical.x - expected.x) < 0.01
       && fabs(physical.y - expected.y) < 0.01,
       "the content's lower-left corner is placed at the expected paper coordinates");
  [[NSColor blackColor] set];
  NSRectFill(rect);
}

@end

static void
checkPlacement(BOOL custom, BOOL flipped, BOOL override, CGFloat scale,
               BOOL centered, NSInteger pages, NSString *label)
{
  NSPrintInfo *info = [[NSPrintInfo alloc] initWithDictionary: nil];
  MarginView *view;
  NSPrintOperation *operation;
  NSMutableData *data = [NSMutableData data];
  NSSize content = NSMakeSize(504, 648);
  NSString *output = [[[NSProcessInfo processInfo] environment] objectForKey: @"GSPRINT_TEST_OUTPUT_DIRECTORY"];

  [info setPaperSize: NSMakeSize(612, 792)];
  [info setLeftMargin: 36];
  [info setRightMargin: 72];
  [info setBottomMargin: 54];
  [info setTopMargin: 90];
  [info setHorizontallyCentered: centered];
  [info setVerticallyCentered: centered];
  [[info dictionary] setObject: [NSNumber numberWithDouble: scale] forKey: NSPrintScalingFactor];
  view = [[MarginView alloc] initWithFrame:
    custom ? NSMakeRect(0, 0, 700, 100 + (pages - 1) * 820 + content.height)
           : NSMakeRect(0, 0, content.width, content.height)];
  view->customPages = custom;
  view->flipped = flipped;
  view->customLocation = override;
  view->pages = pages;
  view->contentSize = content;
  if (override)
    view->expected = NSMakePoint(17, 23);
  else if (centered && pages == 1)
    view->expected = NSMakePoint(36 + content.width * (1 - scale) / 2,
                                54 + content.height * (1 - scale) / 2);
  else
    view->expected = NSMakePoint(36, 54 + content.height * (1 - scale));

  operation = [NSPrintOperation PDFOperationWithView: view insideRect: [view bounds]
                        toData: data printInfo: info];
  PASS([operation runOperation], "PDF rendering succeeds");
  PASS(view->drawn == pages, "every requested page is rendered");
  {
    NSPDFImageRep *pdf = [[NSPDFImageRep alloc] initWithData: data];
    PASS([pdf pageCount] == pages, "the PDF has the expected number of physical pages");
    RELEASE(pdf);
  }
  if (output != nil)
    [data writeToFile: [output stringByAppendingPathComponent:
      [label stringByAppendingPathExtension: @"pdf"]] atomically: YES];
  RELEASE(view);
  RELEASE(info);
}

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  START_SET("Print margins and placement")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  checkPlacement(YES, YES, NO, 1, NO, 2, @"bean");
  checkPlacement(NO, YES, NO, 1, NO, 1, @"automatic");
  checkPlacement(YES, NO, NO, 1, NO, 2, @"unflipped");
  checkPlacement(YES, YES, NO, 0.5, NO, 2, @"scaled");
  checkPlacement(YES, YES, NO, 0.5, YES, 1, @"centered");
  checkPlacement(NO, YES, YES, 1, NO, 1, @"custom-placement");
  checkPlacement(YES, YES, YES, 1, NO, 2, @"custom-pagination-placement");

  END_SET("Print margins and placement")
  RELEASE(pool);
  return 0;
}
