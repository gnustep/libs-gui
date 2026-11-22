/* Exercise the image view's Print action through the real PDF pagination and
   drawing pipeline, substituting only the operation factory to avoid a print
   dialog and printer delivery. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static NSMutableData *output;
static NSPrintOperation *operation;

@interface NSPrintOperation (ImageViewPrintingTest)

+ (NSPrintOperation *) imageViewTestOperationWithView: (NSView *)view
                                          printInfo: (NSPrintInfo *)info;

@end

@implementation NSPrintOperation (ImageViewPrintingTest)

+ (NSPrintOperation *) imageViewTestOperationWithView: (NSView *)view
                                          printInfo: (NSPrintInfo *)info
{
  operation = [self PDFOperationWithView: view insideRect: [view bounds]
                                 toData: output printInfo: info];
  return operation;
}

@end

@interface PrintingImageView : NSImageView
{
@public
  BOOL flipped;
  NSUInteger pages;
  NSRect printedRect;
  NSRect placedRect;
}

@end

@implementation PrintingImageView

- (BOOL) isFlipped
{
  return flipped;
}

- (NSPoint) locationOfPrintRect: (NSRect)rect
{
  NSPoint point = [super locationOfPrintRect: rect];

  placedRect = rect;
  placedRect.origin = point;
  return point;
}

- (void) beginPageInRect: (NSRect)rect atPlacement: (NSPoint)point
{
  pages++;
  printedRect = rect;
  [super beginPageInRect: rect atPlacement: point];
}

@end

static void
checkPrinting(BOOL flipped, NSSize size, NSPrintingOrientation orientation)
{
  NSPrintInfo *info = [[NSPrintInfo alloc] initWithDictionary: nil];
  NSDictionary *settings;
  NSWindow *window;
  PrintingImageView *view;
  NSImage *image;
  NSRect frame = NSMakeRect(23, 37, size.width, size.height);
  NSPoint before;
  NSRect printable;
  NSString *directory = [[[NSProcessInfo processInfo] environment]
    objectForKey: @"GSPRINT_TEST_OUTPUT_DIRECTORY"];
  NSString *imagePath = [[[NSProcessInfo processInfo] environment]
    objectForKey: @"GSPRINT_TEST_IMAGE"];

  [info setPaperSize: NSMakeSize(612, 792)];
  [info setOrientation: orientation];
  [info setLeftMargin: 25];
  [info setRightMargin: 35];
  [info setBottomMargin: 45];
  [info setTopMargin: 55];
  [NSPrintInfo setSharedPrintInfo: info];
  settings = [[info dictionary] copy];
  printable = NSMakeRect(25, 45, [info paperSize].width - 60,
                        [info paperSize].height - 100);

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 700, 500)
    styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
  view = [[PrintingImageView alloc] initWithFrame: frame];
  view->flipped = flipped;
  [[window contentView] addSubview: view];
  if (imagePath != nil)
    image = [[NSImage alloc] initByReferencingFile: imagePath];
  else
    {
      image = [[NSImage alloc] initWithSize: size];
      [image lockFocus];
      [[NSColor redColor] set];
      NSRectFill(NSMakeRect(0, 0, size.width, size.height));
      [[NSColor blueColor] set];
      NSRectFill(NSMakeRect(size.width - 20, 0, 20, size.height));
      [image unlockFocus];
    }
  [view setImage: image];
  [view setImageScaling: NSScaleToFit];
  [view setImageAlignment: NSImageAlignTopLeft];
  before = [view convertPoint: NSMakePoint(10, 20) toView: nil];
  output = [NSMutableData data];
  [view print: nil];

  PASS([output length] > 0, "Print produces PDF output");
  PASS(view->pages == 1, "Print fits the image view onto one page");
  PASS(NSEqualRects(view->printedRect, [view bounds]),
       "the printed page covers the entire image view");
  PASS(NSMinX(view->placedRect) >= NSMinX(printable) - 0.001
       && NSMinY(view->placedRect) >= NSMinY(printable) - 0.001
       && NSMaxX(view->placedRect) <= NSMaxX(printable) + 0.001
       && NSMaxY(view->placedRect) <= NSMaxY(printable) + 0.001,
       "the full image fits within all four page margins");
  PASS(fabs(NSWidth(view->placedRect) / size.width
            - NSHeight(view->placedRect) / size.height) < 0.001,
       "printing preserves the image view's aspect ratio");
  PASS([[operation printInfo] orientation] == orientation,
       "Print preserves the chosen paper orientation");
  PASS([[info dictionary] isEqual: settings],
       "image printing leaves shared print settings unchanged");
  PASS(NSEqualRects([view frame], frame) && [view image] == image
       && NSEqualPoints(before, [view convertPoint: NSMakePoint(10, 20) toView: nil]),
       "printing preserves the displayed image and view coordinates");
  if (directory != nil)
    [output writeToFile: [directory stringByAppendingPathComponent:
      [NSString stringWithFormat: @"print-action-%d-%d.pdf", flipped,
        (int)orientation]] atomically: YES];
  RELEASE(settings);
  RELEASE(info);
  RELEASE(image);
  RELEASE(view);
  RELEASE(window);
}

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSPrintInfo *saved;
  Method factory;
  Method replacement;

  START_SET("NSImageView printing")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  saved = RETAIN([NSPrintInfo sharedPrintInfo]);
  factory = class_getClassMethod([NSPrintOperation class],
    @selector(printOperationWithView:printInfo:));
  replacement = class_getClassMethod([NSPrintOperation class],
    @selector(imageViewTestOperationWithView:printInfo:));
  method_exchangeImplementations(factory, replacement);
  checkPrinting(YES, NSMakeSize(640, 400), NSPortraitOrientation);
  checkPrinting(NO, NSMakeSize(640, 1200), NSPortraitOrientation);
  checkPrinting(YES, NSMakeSize(640, 1200), NSLandscapeOrientation);
  checkPrinting(NO, NSMakeSize(1000, 400), NSLandscapeOrientation);
  method_exchangeImplementations(factory, replacement);
  [NSPrintInfo setSharedPrintInfo: saved];
  RELEASE(saved);

  END_SET("NSImageView printing")
  RELEASE(pool);
  return 0;
}

