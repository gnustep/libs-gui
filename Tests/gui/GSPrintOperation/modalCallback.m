/* Verify the public modal completion contract without opening a sheet or
   submitting a print job. The real NSPrintOperation orchestrates completion;
   only the panel, rendering, and delivery are replaced. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPrintPanel.h>

static int panelResult;
static BOOL renderResult;
static BOOL deliveryResult;
static int renderCalls;
static int deliveryCalls;
static int panelCalls;
static BOOL renderOnMain;
static BOOL deliveryOnMain;
static BOOL renderHasCurrentOperation;
static BOOL renderRaises;
static BOOL panelOnMain = YES;

@interface CallbackSettings : NSObject
{
  NSMutableDictionary *attributes;
}

- (NSMutableDictionary *) dictionary;

@end

@implementation CallbackSettings

- (id) init
{
  self = [super init];
  if (self != nil)
    attributes = [[NSMutableDictionary alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(attributes);
  DEALLOC;
}

- (NSMutableDictionary *) dictionary
{
  return attributes;
}

@end

@interface CallbackPanel : NSObject

- (void) setAccessoryView: (id)view;
- (void) orderOut: (id)sender;
- (void) beginSheetWithPrintInfo: (NSPrintInfo *)info
                 modalForWindow: (NSWindow *)window
                       delegate: (id)delegate
                 didEndSelector: (SEL)selector
                    contextInfo: (void *)context;

@end

@implementation CallbackPanel

- (void) setAccessoryView: (id)view
{
}

- (void) orderOut: (id)sender
{
  panelOnMain = panelOnMain && [NSThread isMainThread];
}

- (void) beginSheetWithPrintInfo: (NSPrintInfo *)info
                 modalForWindow: (NSWindow *)window
                       delegate: (id)delegate
                 didEndSelector: (SEL)selector
                    contextInfo: (void *)context
{
  void (*callback)(id, SEL, id, NSInteger, void *);

  panelCalls++;

  callback = (void (*)(id, SEL, id, NSInteger, void *))
    [delegate methodForSelector: selector];
  callback(delegate, selector, self, panelResult, context);
}

@end

@interface CallbackOperation : NSPrintOperation

@end

@implementation CallbackOperation

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      _print_info = (NSPrintInfo *)[[CallbackSettings alloc] init];
      _print_panel = (NSPrintPanel *)[[CallbackPanel alloc] init];
      [self _setTemporaryOutputFileWithExtension: @"ps"];
      [[NSFileManager defaultManager] createFileAtPath: _path
        contents: [NSData data] attributes: nil];
      [self setShowsPrintPanel: YES];
    }
  return self;
}

- (void) _setupPrintInfo
{
}

- (BOOL) _runOperation
{
  renderCalls++;
  renderOnMain = [NSThread isMainThread];
  renderHasCurrentOperation = [NSPrintOperation currentOperation] == self;
  if (renderRaises)
    [NSException raise: NSInternalInconsistencyException format: @"Test rendering failure"];
  return renderResult;
}

- (BOOL) deliverResult
{
  deliveryCalls++;
  deliveryOnMain = [NSThread isMainThread];
  return deliveryResult;
}

@end

@interface CallbackDelegate : NSObject
{
@public
  int calls;
  NSPrintOperation *receivedOperation;
  BOOL receivedSuccess;
  void *receivedContext;
  BOOL cleanedUp;
  BOOL callbackOnMain;
}

- (void) printOperationDidRun: (NSPrintOperation *)operation
                     success: (BOOL)success
                 contextInfo: (void *)context;

@end

@implementation CallbackDelegate

- (void) printOperationDidRun: (NSPrintOperation *)operation
                     success: (BOOL)success
                 contextInfo: (void *)context
{
  calls++;
  receivedOperation = operation;
  receivedSuccess = success;
  receivedContext = context;
  cleanedUp = ([NSPrintOperation currentOperation] == nil);
  callbackOnMain = [NSThread isMainThread];
  PASS(![[NSFileManager defaultManager] fileExistsAtPath:
    [operation valueForKey: @"path"]],
    "modal completion removes temporary output before calling the delegate");
}

@end

static void
checkCompletion(int response, BOOL rendered, BOOL delivered, BOOL expected)
{
  CallbackOperation *operation = [[CallbackOperation alloc] init];
  CallbackDelegate *delegate = [[CallbackDelegate alloc] init];
  int context = 123;

  panelResult = response;
  renderResult = rendered;
  deliveryResult = delivered;
  renderCalls = 0;
  deliveryCalls = 0;
  [NSPrintOperation setCurrentOperation: operation];
  [operation runOperationModalForWindow: nil
                              delegate: delegate
                        didRunSelector:
    @selector(printOperationDidRun:success:contextInfo:)
                           contextInfo: &context];

  PASS(delegate->calls == 1, "completion is called exactly once");
  PASS(delegate->receivedOperation == operation,
       "completion receives the print operation, not the sheet");
  PASS(delegate->receivedSuccess == expected,
       "completion receives the correct success flag");
  PASS(delegate->receivedContext == &context,
       "completion preserves the opaque context pointer");
  PASS(delegate->cleanedUp, "operation is cleaned up before completion");
  PASS(renderCalls == (response == NSOKButton ? 1 : 0),
       "cancellation does not render");
  PASS(deliveryCalls == (response == NSOKButton && rendered ? 1 : 0),
       "delivery requires successful rendering");

  RELEASE(operation);
  RELEASE(delegate);
}

static void
checkThreadedCompletion(BOOL showPanel, BOOL raises)
{
  CallbackOperation *operation = [[CallbackOperation alloc] init];
  CallbackDelegate *delegate = [[CallbackDelegate alloc] init];
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 5];
  int context;

  panelResult = NSOKButton;
  panelCalls = 0;
  renderResult = YES;
  deliveryResult = YES;
  renderRaises = raises;
  [operation setShowsPrintPanel: showPanel];
  [operation setCanSpawnSeparateThread: YES];
  [NSPrintOperation setCurrentOperation: operation];
  [operation runOperationModalForWindow: nil delegate: delegate
    didRunSelector: @selector(printOperationDidRun:success:contextInfo:)
    contextInfo: &context];
  PASS(delegate->calls == 0, "threaded modal printing returns before completion");
  PASS([NSPrintOperation currentOperation] == nil,
       "caller releases its thread-local current operation");
  while (delegate->calls == 0 && [deadline timeIntervalSinceNow] > 0)
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
  PASS(delegate->calls == 1, "worker completes exactly once");
  PASS(!renderOnMain && renderHasCurrentOperation,
       "rendering uses a worker with its own current operation");
  PASS(raises || !deliveryOnMain, "delivery also runs in the worker");
  PASS(delegate->receivedOperation == operation && delegate->receivedContext == &context,
       "worker completion preserves the operation and context");
  PASS(delegate->receivedSuccess == !raises, "worker reports rendering exceptions as failure");
  PASS(delegate->callbackOnMain && panelOnMain, "completion and panel cleanup run on main thread");
  PASS(panelCalls == (showPanel ? 1 : 0), "modal printing honors showsPrintPanel");
  renderRaises = NO;
  RELEASE(operation);
  RELEASE(delegate);
}

int
main(void)
{
  START_SET("Modal print completion callback")
  CallbackOperation *operation;

  checkCompletion(NSOKButton, YES, YES, YES);
  checkCompletion(NSOKButton, YES, NO, NO);
  checkCompletion(NSOKButton, NO, YES, NO);
  checkCompletion(NSCancelButton, YES, YES, NO);

  operation = [[CallbackOperation alloc] init];
  [NSPrintOperation setCurrentOperation: operation];
  PASS_RUNS([operation runOperationModalForWindow: nil
                                        delegate: nil
                                  didRunSelector: NULL
                                     contextInfo: NULL];,
            "completion delegate is optional");
  PASS([NSPrintOperation currentOperation] == nil,
       "operation is cleaned up without a delegate");
  RELEASE(operation);

  checkThreadedCompletion(YES, NO);
  checkThreadedCompletion(NO, NO);
  checkThreadedCompletion(NO, YES);

  {
    CallbackDelegate *delegate = [[CallbackDelegate alloc] init];
    CallbackOperation *newOperation = [[CallbackOperation alloc] init];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 5];

    operation = [[CallbackOperation alloc] init];
    [operation setShowsPrintPanel: NO];
    [operation setCanSpawnSeparateThread: YES];
    [NSPrintOperation setCurrentOperation: operation];
    [operation runOperationModalForWindow: nil delegate: delegate
      didRunSelector: @selector(printOperationDidRun:success:contextInfo:) contextInfo: NULL];
    [NSPrintOperation setCurrentOperation: newOperation];
    while (delegate->calls == 0 && [deadline timeIntervalSinceNow] > 0)
      [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
    PASS(delegate->calls == 1 && [NSPrintOperation currentOperation] == newOperation,
         "worker completion does not clear a newer operation on the caller thread");
    [NSPrintOperation setCurrentOperation: nil];
    RELEASE(newOperation);
    RELEASE(operation);
    RELEASE(delegate);
  }

  {
    CallbackDelegate *delegate = [[CallbackDelegate alloc] init];

    operation = [[CallbackOperation alloc] init];
    [operation setCanSpawnSeparateThread: YES];
    panelResult = NSCancelButton;
    renderCalls = 0;
    [NSPrintOperation setCurrentOperation: operation];
    [operation runOperationModalForWindow: nil delegate: delegate
      didRunSelector: @selector(printOperationDidRun:success:contextInfo:) contextInfo: NULL];
    PASS(delegate->calls == 1 && !delegate->receivedSuccess && renderCalls == 0,
         "cancellation completes without starting a worker");
    RELEASE(operation);
    RELEASE(delegate);
  }

  operation = [[CallbackOperation alloc] init];
  [operation setShowsPrintPanel: NO];
  [operation setCanSpawnSeparateThread: YES];
  renderResult = YES;
  deliveryResult = YES;
  PASS([operation runOperation], "synchronous printing still succeeds");
  PASS(renderOnMain && deliveryOnMain, "runOperation stays synchronous despite the thread flag");
  RELEASE(operation);
  END_SET("Modal print completion callback")
  return 0;
}
