/* Exercise option-driven controls, accessory integration, and an actual
   generated document preview without submitting a print job. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSPrintPanel (OptionsTest)

- (void) _updateFromPrintInfo: (NSPrintInfo *)info;
- (void) _finalWritePrintInfo: (NSPrintInfo *)info;

@end

@interface OptionsPanel : NSPrintPanel

- (void) prepare: (NSPrintInfo *)info;

@end

@interface PDFCompletion : NSObject
{
@public
  BOOL completed;
  BOOL success;
}

- (void) operation: (NSPrintOperation *)operation success: (BOOL)result context: (void *)context;

@end

@implementation PDFCompletion

- (void) operation: (NSPrintOperation *)operation success: (BOOL)result context: (void *)context
{
  completed = YES;
  success = result;
}

@end

@implementation OptionsPanel

+ (id) allocWithZone: (NSZone *)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (void) prepare: (NSPrintInfo *)info
{
  ASSIGN(_printInfo, info);
  [self _updateFromPrintInfo: info];
}

@end

@interface OptionsController : NSViewController <NSPrintPanelAccessorizing>
{
  BOOL watermark;
}

- (BOOL) watermark;
- (void) setWatermark: (BOOL)flag;

@end

@implementation OptionsController

- (BOOL) watermark
{
  return watermark;
}

- (void) setWatermark: (BOOL)flag
{
  watermark = flag;
  [[[self representedObject] dictionary] setObject: [NSNumber numberWithBool: flag]
                                           forKey: @"TestWatermark"];
}

- (NSSet *) keyPathsForValuesAffectingPreview
{
  return [NSSet setWithObject: @"watermark"];
}

- (NSArray *) localizedSummaryItems
{
  return [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
    @"Watermark", NSPrintPanelAccessorySummaryItemNameKey,
    watermark ? @"On" : @"Off", NSPrintPanelAccessorySummaryItemDescriptionKey, nil]];
}

@end

static int draws;

@interface PreviewDocument : NSView

@end

@implementation PreviewDocument

- (BOOL) knowsPageRange: (NSRange *)range
{
  *range = NSMakeRange(1, 2);
  return YES;
}

- (NSRect) rectForPage: (NSInteger)page
{
  return [self bounds];
}

- (void) drawRect: (NSRect)rect
{
  draws++;
  [[NSColor blueColor] set];
  NSRectFill(NSMakeRect(10, 10, 80, 60));
}

@end

static NSView *
findView(NSView *root, Class class)
{
  NSEnumerator *enumerator = [[root subviews] objectEnumerator];
  NSView *child;

  if ([root isKindOfClass: class])
    return root;
  while ((child = [enumerator nextObject]) != nil)
    {
      NSView *found = findView(child, class);
      if (found != nil)
        return found;
    }
  return nil;
}

int
main(void)
{
  START_SET("Print panel options and accessories")
  OptionsPanel *panel;
  NSPrintInfo *info;
  NSMutableDictionary *dict;
  OptionsController *controller;
  NSView *accessory;
  NSView *legacy;
  NSView *extension;
  CGFloat originalWidth;
  NSPrintOperation *operation;
  PreviewDocument *document;
  NSImageView *imageView;
  NSPDFImageRep *representation;
  NSDate *deadline;
  int oldDraws;
  NSDictionary *beforePreview;

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  panel = [[OptionsPanel alloc] init];
  info = [[NSPrintInfo alloc] initWithDictionary: nil];
  dict = [info dictionary];
  originalWidth = [[panel contentView] frame].size.width;
  [dict setObject: [NSNumber numberWithInt: 5] forKey: NSPrintCopies];
  [dict setObject: [NSNumber numberWithBool: NO] forKey: NSPrintAllPages];
  [dict setObject: [NSNumber numberWithInt: 2] forKey: NSPrintFirstPage];
  [dict setObject: [NSNumber numberWithInt: 3] forKey: NSPrintLastPage];
  [dict setObject: [NSNumber numberWithDouble: 0.75] forKey: NSPrintScalingFactor];
  [panel setOptions: 0];
  [panel prepare: info];
  PASS([[[panel contentView] viewWithTag: NSPPCopiesField] isHidden], "copies option hides its control");
  PASS([[[panel contentView] viewWithTag: NSPPPageChoiceMatrix] isHidden], "page range option hides its controls");
  PASS([[[panel contentView] viewWithTag: NSPPScaleField] isHidden], "scaling option hides its control");
  [panel _finalWritePrintInfo: info];
  PASS([[dict objectForKey: NSPrintCopies] intValue] == 5
       && ![[dict objectForKey: NSPrintAllPages] boolValue]
       && [[dict objectForKey: NSPrintScalingFactor] doubleValue] == 0.75,
       "hidden controls preserve application-supplied settings");

  [panel setOptions: NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsScaling];
  PASS(![[[panel contentView] viewWithTag: NSPPCopiesField] isHidden]
       && ![[[panel contentView] viewWithTag: NSPPPageChoiceMatrix] isHidden]
       && ![[[panel contentView] viewWithTag: NSPPScaleField] isHidden],
       "controls reappear when their options are enabled");

  controller = [[OptionsController alloc] initWithNibName: nil bundle: nil];
  accessory = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 250, 70)];
  [controller setView: accessory];
  [controller setTitle: @"Application Options"];
  [panel addAccessoryController: controller];
  [panel addAccessoryController: controller];
  PASS([[panel accessoryControllers] count] == 1, "duplicate accessory controllers are ignored");
  PASS([accessory window] == panel && [controller representedObject] == info,
       "accessory view is displayed and receives the active print info");
  PASS([[panel contentView] frame].size.width > originalWidth, "panel expands for accessory controls");
  [controller setWatermark: YES];
  PASS([[dict objectForKey: @"TestWatermark"] boolValue], "accessory edits reach the print settings");
  [panel removeAccessoryController: controller];
  PASS([accessory window] == nil && [controller representedObject] == nil,
       "removing a controller detaches its view and print info");
  PASS([[panel contentView] frame].size.width == originalWidth, "panel shrinks after removing accessories");
  PASS_RUNS([controller setWatermark: NO];, "removed controllers no longer notify the panel");

  legacy = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 250, 60)];
  [panel setAccessoryView: legacy];
  PASS([legacy window] == panel, "legacy accessory views are displayed");
  [panel setAccessoryView: nil];
  PASS([legacy window] == nil, "legacy accessory views are removed");

  [panel setOptions: NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation];
  PASS([[dict objectForKey: NSPrintFirstPage] intValue] == 2
       && [[dict objectForKey: NSPrintLastPage] intValue] == 3,
       "rebuilding accessory controls preserves the selected page range");
  extension = [[panel contentView] viewWithTag: 19470];
  PASS(findView(extension, [NSPopUpButton class]) != nil, "paper and orientation options create controls");
  [panel setOptions: NSPrintPanelShowsPageSetupAccessory];
  PASS(findView(extension, [NSBox class]) != nil
       && [[[panel contentView] viewWithTag: NSPPScaleField] isHidden],
       "page setup uses its own group of controls");

  [panel setOptions: NSPrintPanelShowsOrientation];
  {
    NSPopUpButton *control = (id)findView(extension, [NSPopUpButton class]);
    [control selectItemAtIndex: 1];
    [[control target] performSelector: [control action] withObject: control];
    PASS([info orientation] == NSLandscapeOrientation,
         "orientation control changes the actual print settings");
  }
  [panel setOptions: NSPrintPanelShowsPaperSize];
  {
    NSPopUpButton *control = (id)findView(extension, [NSPopUpButton class]);
    if ([control numberOfItems] > 1)
      [control selectItemAtIndex: ([control indexOfSelectedItem] + 1) % [control numberOfItems]];
    NSString *selected = RETAIN([control titleOfSelectedItem]);
    [[control target] performSelector: [control action] withObject: control];
    PASS([[info paperName] isEqual: selected] && [info orientation] == NSLandscapeOrientation,
         "paper control changes media while preserving orientation");
    RELEASE(selected);
  }

  /* Preview the generated pages and verify that the outer operation remains
     current while the nested PDF operation is created and cleaned up. */
  document = [[PreviewDocument alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  [dict setObject: [NSNumber numberWithBool: YES] forKey: NSPrintAllPages];
  operation = RETAIN([NSPrintOperation printOperationWithView: document printInfo: info]);
  [operation setPrintPanel: panel];
  [panel prepare: [operation printInfo]];
  [panel addAccessoryController: controller];
  [panel setOptions: NSPrintPanelShowsPreview | NSPrintPanelShowsPageSetupAccessory];
  beforePreview = [[[operation printInfo] dictionary] copy];
  [extension performSelector: @selector(refreshPreview)];
  imageView = (id)findView(extension, [NSImageView class]);
  representation = (id)[[[imageView image] representations] lastObject];
  PASS([representation isKindOfClass: [NSPDFImageRep class]] && [representation pageCount] == 2,
       "embedded preview contains the two rendered pages");
  PASS([NSPrintOperation currentOperation] == operation, "preview restores the outer current operation");
  PASS([beforePreview isEqual: [[operation printInfo] dictionary]],
       "preview rendering leaves the real job settings unchanged");
  RELEASE(beforePreview);
  [extension performSelector: @selector(nextPage:) withObject: nil];
  PASS([representation currentPage] == 1, "preview navigates to the next page");
  oldDraws = draws;
  [controller setWatermark: YES];
  deadline = [NSDate dateWithTimeIntervalSinceNow: 5];
  while (draws == oldDraws && [deadline timeIntervalSinceNow] > 0)
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
  PASS(draws > oldDraws, "accessory preview key paths trigger document regeneration");

  if ([[[NSProcessInfo processInfo] environment] objectForKey: @"GS_PRINT_PANEL_SCREENSHOT"] != nil)
    {
      NSView *content = [panel contentView];
      NSBitmapImageRep *bitmap;
      NSScrollView *scroller = (id)findView(extension, [NSScrollView class]);
      [[scroller documentView] scrollPoint: NSZeroPoint];
      [panel orderFront: nil];
      [panel display];
      bitmap = [content bitmapImageRepForCachingDisplayInRect: [content bounds]];
      [content cacheDisplayInRect: [content bounds] toBitmapImageRep: bitmap];
      [[bitmap representationUsingType: NSPNGFileType properties: [NSDictionary dictionary]]
        writeToFile: [[[NSProcessInfo processInfo] environment] objectForKey: @"GS_PRINT_PANEL_SCREENSHOT"]
         atomically: YES];
    }

  [panel setOptions: 0];
  PASS(findView(extension, [NSImageView class]) == nil, "disabling preview removes the preview controls");
  [panel removeAccessoryController: controller];
  [operation cleanUpOperation];
  RELEASE(operation);

  {
    PDFCompletion *completion = [[PDFCompletion alloc] init];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
      [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension: @"pdf"]];
    NSPrintOperation *pdfOperation = RETAIN([NSPrintOperation PDFOperationWithView: document
      insideRect: [document bounds] toPath: path printInfo: info]);
    [pdfOperation setPrintPanel: panel];
    [pdfOperation setCanSpawnSeparateThread: YES];
    [pdfOperation runOperationModalForWindow: nil delegate: completion
      didRunSelector: @selector(operation:success:context:) contextInfo: NULL];
    deadline = [NSDate dateWithTimeIntervalSinceNow: 5];
    while (!completion->completed && [deadline timeIntervalSinceNow] > 0)
      [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
    PASS(completion->completed && completion->success,
         "actual PDF rendering completes on a worker");
    representation = [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: path]];
    PASS([representation pageCount] == 2, "worker-generated PDF contains both pages");
    [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
    RELEASE(pdfOperation);
    RELEASE(completion);
  }
  RELEASE(document);
  RELEASE(legacy);
  RELEASE(accessory);
  RELEASE(controller);
  RELEASE(info);
  RELEASE(panel);
  END_SET("Print panel options and accessories")
  return 0;
}
