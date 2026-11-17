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
}

- (void) beginSheetWithPrintInfo: (NSPrintInfo *)info
                 modalForWindow: (NSWindow *)window
                       delegate: (id)delegate
                 didEndSelector: (SEL)selector
                    contextInfo: (void *)context
{
  void (*callback)(id, SEL, id, int, void *);

  callback = (void (*)(id, SEL, id, int, void *))
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
    }
  return self;
}

- (void) _setupPrintInfo
{
}

- (BOOL) _runOperation
{
  renderCalls++;
  return renderResult;
}

- (BOOL) deliverResult
{
  deliveryCalls++;
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
  END_SET("Modal print completion callback")
  return 0;
}
