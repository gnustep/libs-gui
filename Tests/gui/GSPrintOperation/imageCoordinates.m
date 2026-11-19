/* Regression coverage for image placement in a flipped printing view. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PrintImageView : NSImageView
{
@public
  BOOL flipped;
  NSUInteger scans;
}

@end

@implementation PrintImageView

- (BOOL) isFlipped
{
  return flipped;
}

- (NSRect) centerScanRect: (NSRect)rect
{
  NSRect result = [super centerScanRect: rect];

  if ([NSPrintOperation currentOperation] != nil)
    {
      scans++;
      PASS(NSEqualRects(result, rect),
           "printing preserves the image's integral drawing rectangle");
    }
  return result;
}

@end

static void
checkImage(BOOL flipped)
{
  NSWindow *window;
  PrintImageView *view;
  NSImage *image;
  NSPrintInfo *info;
  NSPrintOperation *operation;
  NSMutableData *data = [NSMutableData data];
  NSPoint before;
  NSPoint after;
  NSString *output = [[[NSProcessInfo processInfo] environment]
    objectForKey: @"GSPRINT_TEST_OUTPUT_DIRECTORY"];

  window = [[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 700, 500)
             styleMask: NSBorderlessWindowMask
               backing: NSBackingStoreBuffered defer: NO];
  view = [[PrintImageView alloc]
    initWithFrame: NSMakeRect(23, 37, 640, 400)];
  view->flipped = flipped;
  [[window contentView] addSubview: view];
  image = [[NSImage alloc] initWithSize: NSMakeSize(640, 400)];
  [image lockFocus];
  [[NSColor redColor] set];
  NSRectFill(NSMakeRect(0, 0, 640, 400));
  [image unlockFocus];
  [view setImage: image];
  [view setImageScaling: NSScaleToFit];
  [view setImageAlignment: NSImageAlignTopLeft];
  before = [view convertPoint: NSMakePoint(10, 20) toView: nil];

  info = [[NSPrintInfo alloc] initWithDictionary: nil];
  [info setPaperSize: NSMakeSize(612, 792)];
  [info setOrientation: NSPortraitOrientation];
  [info setHorizontalPagination: NSFitPagination];
  [info setVerticalPagination: NSFitPagination];
  operation = [NSPrintOperation PDFOperationWithView: view
    insideRect: [view bounds] toData: data printInfo: info];
  PASS([operation runOperation], "the image print operation succeeds");
  PASS(view->scans > 0, "printing draws the image through NSImageCell");
  after = [view convertPoint: NSMakePoint(10, 20) toView: nil];
  PASS(NSEqualPoints(before, after),
       "printing restores the view's window coordinate conversion");
  if (output != nil)
    [data writeToFile: [output stringByAppendingPathComponent:
      flipped ? @"image-flipped.pdf" : @"image-unflipped.pdf"] atomically: YES];
  RELEASE(info);
  RELEASE(image);
  RELEASE(view);
  RELEASE(window);
}

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  START_SET("Print image coordinates")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  checkImage(YES);
  checkImage(NO);

  END_SET("Print image coordinates")
  RELEASE(pool);
  return 0;
}
