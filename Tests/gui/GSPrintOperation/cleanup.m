/* Failure-path cleanup with fake graphics contexts and real temporary files.
   No display, printer, or external application is required. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>

static int failureMode;
static int poolsDrained;
static int contextsClosed;
static int viewsCleaned;
static BOOL deliveredAfterClose;
static NSGraphicsContext *savedContext;

@interface CleanupSettings : NSObject <NSCopying>
{
  NSMutableDictionary *attributes;
}

- (NSMutableDictionary *) dictionary;

@end

@implementation CleanupSettings

- (id) init
{
  self = [super init];
  if (self != nil)
    attributes = [[NSMutableDictionary alloc] init];
  return self;
}

- (id) copyWithZone: (NSZone *)zone
{
  return RETAIN(self);
}

- (NSMutableDictionary *) dictionary
{
  return attributes;
}

- (void) dealloc
{
  RELEASE(attributes);
  DEALLOC;
}

@end

@interface PoolMarker : NSObject

@end

@implementation PoolMarker

- (void) dealloc
{
  poolsDrained++;
  DEALLOC;
}

@end

@interface CleanupContext : NSObject

@end

@implementation CleanupContext

- (void) dealloc
{
  contextsClosed++;
  DEALLOC;
}

@end

@interface CleanupView : NSObject

- (void) _cleanupPrinting;

@end

@implementation CleanupView

- (void) _cleanupPrinting
{
  viewsCleaned++;
  if (failureMode == 7)
    [NSException raise: NSInternalInconsistencyException format: @"View cleanup failure"];
}

@end

@interface CleanupOperation : NSPrintOperation

- (NSString *) outputPath;

@end

@implementation CleanupOperation

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      _print_info = (NSPrintInfo *)[[CleanupSettings alloc] init];
      _view = (NSView *)[[CleanupView alloc] init];
      [self _setTemporaryOutputFileWithExtension: @"ps"];
      [[NSFileManager defaultManager] createFileAtPath: _path
        contents: [@"Partial print job" dataUsingEncoding: NSUTF8StringEncoding]
        attributes: nil];
      [NSPrintOperation setCurrentOperation: self];
    }
  return self;
}

- (NSString *) outputPath
{
  return _path;
}

- (NSPrintPanel *) printPanel
{
  return nil;
}

- (NSGraphicsContext *) createContext
{
  AUTORELEASE([[PoolMarker alloc] init]);
  if (failureMode == 1)
    return nil;
  if (failureMode == 2)
    [NSException raise: NSInternalInconsistencyException format: @"Context creation failure"];
  _context = (NSGraphicsContext *)RETAIN(AUTORELEASE([[CleanupContext alloc] init]));
  if (failureMode == 3)
    [NSException raise: NSInternalInconsistencyException format: @"Partial context failure"];
  return _context;
}

- (void) _print
{
  if (failureMode == 4 || failureMode == 7)
    [NSException raise: NSInternalInconsistencyException format: @"Rendering failure"];
}

- (void) destroyContext
{
  if (failureMode == 8)
    [NSException raise: NSInternalInconsistencyException format: @"Context closing failure"];
  [super destroyContext];
}

- (BOOL) deliverResult
{
  deliveredAfterClose = contextsClosed == 1 && poolsDrained == 1
    && [NSGraphicsContext currentContext] == savedContext;
  if (failureMode == 5)
    [NSException raise: NSInternalInconsistencyException format: @"Delivery failure"];
  return YES;
}

- (void) cleanUpOperation
{
  if (failureMode == 6)
    [NSException raise: NSInternalInconsistencyException format: @"Subclass cleanup failure"];
  [super cleanUpOperation];
}

@end

static void
checkExport(BOOL pdf, BOOL save)
{
  CleanupSettings *settings = [[CleanupSettings alloc] init];
  NSMutableData *data = [NSMutableData data];
  const unsigned char bytes[] = { '%', '!', 'P', 'S', '\n', 0, 128, 255 };
  NSData *contents = [NSData dataWithBytes: bytes length: sizeof(bytes)];
  NSPrintOperation *operation;
  NSString *path;

  if (save)
    {
      path = [NSTemporaryDirectory() stringByAppendingPathComponent:
        [[NSProcessInfo processInfo] globallyUniqueString]];
      if (pdf)
        operation = RETAIN([NSPrintOperation PDFOperationWithView: nil insideRect: NSZeroRect
          toPath: path printInfo: (NSPrintInfo *)settings]);
      else
        operation = RETAIN([NSPrintOperation EPSOperationWithView: nil insideRect: NSZeroRect
          toPath: path printInfo: (NSPrintInfo *)settings]);
    }
  else
    {
      if (pdf)
        operation = RETAIN([NSPrintOperation PDFOperationWithView: nil insideRect: NSZeroRect
          toData: data printInfo: (NSPrintInfo *)settings]);
      else
        operation = RETAIN([NSPrintOperation EPSOperationWithView: nil insideRect: NSZeroRect
          toData: data printInfo: (NSPrintInfo *)settings]);
      path = [operation valueForKey: @"path"];
    }
  path = RETAIN(path);
  [[NSFileManager defaultManager] createFileAtPath: path contents: contents attributes: nil];
  PASS([operation deliverResult], "export delivery succeeds");
  if (save)
    {
      PASS([[NSData dataWithContentsOfFile: path] isEqual: contents],
           "explicit export paths are preserved, including paths in the temp directory");
    }
  else
    {
      PASS([data isEqual: contents], "data exports preserve every byte");
      PASS(![[NSFileManager defaultManager] fileExistsAtPath: path],
           "data export removes its temporary output after reading");
      PASS(![operation deliverResult], "missing export output reports failure");
      PASS([data isEqual: contents], "failed delivery leaves the caller's data unchanged");
    }
  [NSPrintOperation setCurrentOperation: nil];
  RELEASE(operation);
  if (save)
    {
      PASS([[NSFileManager defaultManager] fileExistsAtPath: path],
           "destroying an export operation does not remove the saved file");
      [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
    }
  RELEASE(path);
  RELEASE(settings);
}

int
main(void)
{
  START_SET("Print operation cleanup")
  int mode;

  savedContext = (NSGraphicsContext *)[[NSObject alloc] init];
  [NSGraphicsContext setCurrentContext: savedContext];
  for (mode = 0; mode <= 8; mode++)
    {
      CleanupOperation *operation;
      NSString *path;

      failureMode = mode;
      poolsDrained = contextsClosed = viewsCleaned = 0;
      deliveredAfterClose = NO;
      operation = [[CleanupOperation alloc] init];
      path = RETAIN([operation outputPath]);
      PASS([operation runOperation] == (mode == 0 || mode == 6),
           "operation reports the expected result for failure mode %d", mode);
      PASS([NSPrintOperation currentOperation] == nil, "current operation is cleared for mode %d", mode);
      PASS([NSGraphicsContext currentContext] == savedContext, "previous graphics context is restored for mode %d", mode);
      PASS(poolsDrained == 1, "rendering autorelease pool is drained for mode %d", mode);
      PASS(contextsClosed == (mode == 1 || mode == 2 ? 0 : 1),
           "allocated graphics context is closed for mode %d", mode);
      PASS(![[NSFileManager defaultManager] fileExistsAtPath: path],
           "partial temporary output is removed for mode %d", mode);
      if (mode == 0)
        PASS(deliveredAfterClose, "delivery starts only after context and pool cleanup");
      if (mode == 2 || mode == 3 || mode == 4 || mode == 7)
        PASS(viewsCleaned == 1, "rendering failures clean up the view");
      RELEASE(operation);
      RELEASE(path);
    }
  [NSGraphicsContext setCurrentContext: nil];
  RELEASE(savedContext);

  checkExport(YES, NO);
  checkExport(NO, NO);
  checkExport(YES, YES);
  checkExport(NO, YES);
  END_SET("Print operation cleanup")
  return 0;
}
