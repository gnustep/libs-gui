/* Regression for applications assigning a title before printing long text. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#include <float.h>

@interface TitledTextView : NSTextView
{
@public
  NSUInteger pages;
  NSString *documentTitle;
}

@end

@implementation TitledTextView

- (NSString *) printJobTitle
{
  return @"View title";
}

- (void) beginPageInRect: (NSRect)rect atPlacement: (NSPoint)point
{
  pages++;
  [super beginPageInRect: rect atPlacement: point];
}

- (void) beginPrologueBBox: (NSRect)box creationDate: (NSString *)date
               createdBy: (NSString *)creator fonts: (NSString *)fonts
                 forWhom: (NSString *)user pages: (int)count
                   title: (NSString *)title
{
  ASSIGNCOPY(documentTitle, title);
  [super beginPrologueBBox: box creationDate: date createdBy: creator
                    fonts: fonts forWhom: user pages: count title: title];
}

- (void) dealloc
{
  RELEASE(documentTitle);
  DEALLOC;
}

@end

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  TitledTextView *view;
  NSPrintInfo *info;
  NSPrintOperation *operation;
  NSMutableData *data = [NSMutableData data];
  NSMutableString *text = [NSMutableString string];
  NSMutableString *title = [NSMutableString stringWithString: @"Assessment"];
  NSPDFImageRep *pdf;
  NSUInteger i;
  CGFloat height;

  START_SET("Print job title and text pagination")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  info = [[NSPrintInfo alloc] initWithDictionary: nil];
  [info setPaperSize: NSMakeSize(400, 400)];
  [info setLeftMargin: 20];
  [info setRightMargin: 20];
  [info setTopMargin: 20];
  [info setBottomMargin: 20];
  [info setHorizontalPagination: NSFitPagination];
  [info setVerticalPagination: NSAutoPagination];
  view = [[TitledTextView alloc] initWithFrame: NSMakeRect(0, 0, 360, 1)];
  [view setTextContainerInset: NSZeroSize];
  [view setVerticallyResizable: YES];
  [view setMaxSize: NSMakeSize(360, FLT_MAX)];
  [[view textContainer] setContainerSize: NSMakeSize(360, FLT_MAX)];
  for (i = 0; i < 100; i++)
    [text appendString: @"Printing assessment: a paragraph of document text.\n"];
  [view setString: text];
  [[view layoutManager] ensureLayoutForTextContainer: [view textContainer]];
  height = NSMaxY([[view layoutManager] usedRectForTextContainer: [view textContainer]]);
  [view setFrameSize: NSMakeSize(360, height)];
  operation = [NSPrintOperation PDFOperationWithView: view
    insideRect: [view bounds] toData: data printInfo: info];
  [operation setShowsPrintPanel: NO];
  [operation setShowsProgressPanel: NO];
  PASS_EQUAL([operation jobTitle], @"View title", "default title comes from the view");
  [operation setJobTitle: title];
  [title appendString: @" changed"];
  PASS_EQUAL([operation jobTitle], @"Assessment", "custom title is copied");
  [operation setPrintInfo: info];
  PASS_EQUAL([operation jobTitle], @"Assessment", "replacing settings preserves the title");
  [operation setJobTitle: nil];
  PASS_EQUAL([operation jobTitle], @"View title", "nil restores the view title");
  [operation setJobTitle: @"Assessment"];
  PASS_EQUAL([view printJobTitle], @"View title", "custom title does not alter the view");
  PASS([[[view pageHeader] string] hasPrefix: @"Assessment "],
       "page header uses the operation title");
  PASS([operation runOperation], "titled text document prints successfully");
  PASS_EQUAL(view->documentTitle, @"Assessment", "document prologue uses the custom title");
  pdf = [[NSPDFImageRep alloc] initWithData: data];
  PASS(view->pages > 1 && [pdf pageCount] == view->pages,
       "long text is printed across separate PDF pages");
  PASS([NSPrintOperation currentOperation] == nil,
       "printing releases the current operation");
  RELEASE(pdf);
  RELEASE(view);
  RELEASE(info);
  END_SET("Print job title and text pagination")
  RELEASE(pool);
  return 0;
}
