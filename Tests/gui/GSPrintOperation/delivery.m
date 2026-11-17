/* Exercise delivery without a display, printer, or external application.
   Compile the delivery implementations with controlled transport substitutes
   so that failures cannot accidentally submit a real print job. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

static NSString *disposition;
static BOOL accepted;
static BOOL useViewer;
static BOOL toolFound;
static BOOL launchFails;
static int exitStatus;
static int spoolCalls;

@interface DeliverySettings : NSObject

- (NSString *) jobDisposition;
- (id) printer;
- (NSString *) name;
- (NSDictionary *) dictionary;

@end

@implementation DeliverySettings

- (NSString *) jobDisposition
{
  return disposition;
}

- (id) printer
{
  return self;
}

- (NSString *) name
{
  return @"Unknown";
}

- (NSDictionary *) dictionary
{
  return [NSDictionary dictionary];
}

@end

static DeliverySettings *settings;

@interface DeliveryWorkspace : NSObject

+ (id) sharedWorkspace;
- (NSString *) getBestAppInRole: (NSString *)role
                 forExtension: (NSString *)extension;
- (BOOL) openFile: (NSString *)path withApplication: (NSString *)application;

@end

@implementation DeliveryWorkspace

+ (id) sharedWorkspace
{
  return AUTORELEASE([[self alloc] init]);
}

- (NSString *) getBestAppInRole: (NSString *)role
                 forExtension: (NSString *)extension
{
  return useViewer ? @"TestViewer" : nil;
}

- (BOOL) openFile: (NSString *)path withApplication: (NSString *)application
{
  return accepted;
}

@end

@interface DeliveryTask : NSObject

+ (NSString *) launchPathForTool: (NSString *)tool;
- (void) setLaunchPath: (NSString *)path;
- (void) setArguments: (NSArray *)arguments;
- (void) launch;
- (void) waitUntilExit;
- (int) terminationStatus;

@end

@implementation DeliveryTask

+ (NSString *) launchPathForTool: (NSString *)tool
{
  return toolFound ? @"/test/lpr" : nil;
}

- (void) setLaunchPath: (NSString *)path
{
}

- (void) setArguments: (NSArray *)arguments
{
}

- (void) launch
{
  if (launchFails)
    [NSException raise: NSInternalInconsistencyException
                format: @"Test launch failure"];
}

- (void) waitUntilExit
{
}

- (int) terminationStatus
{
  return exitStatus;
}

@end

static NSInteger
DeliveryAlert(NSString *title, NSString *message, NSString *defaultButton,
              NSString *alternateButton, NSString *otherButton, ...)
{
  return NSAlertDefaultReturn;
}

/* Rename the classes so installed printing bundles cannot interfere. */
#define GSPrintOperation DeliveryOperation
#define NSWorkspace DeliveryWorkspace
#define NSTask DeliveryTask
#define NSRunAlertPanel DeliveryAlert
#include "../../../Source/GSPrintOperation.m"
#define GSLPRPrintOperation DeliveryLPROperation
#include "../../../Printing/GSLPR/GSLPRPrintOperation.m"
#undef GSLPRPrintOperation
#undef NSRunAlertPanel
#undef NSTask
#undef NSWorkspace
#undef GSPrintOperation

#ifdef __has_include
# if __has_include(<cups/cups.h>)
#  define TEST_CUPS 1
# endif
#endif

#ifdef TEST_CUPS
#include <cups/cups.h>

static int
DeliveryCUPSPrintFile(const char *name, const char *path, const char *title,
                      int count, cups_option_t *options)
{
  return accepted ? 42 : 0;
}

static const char *
DeliveryCUPSError(void)
{
  return "Test spool rejection";
}

#define GSPrintOperation DeliveryOperation
#define GSCUPSPrintOperation DeliveryCUPSOperation
#define cupsPrintFile DeliveryCUPSPrintFile
#define cupsLastErrorString DeliveryCUPSError
#include "../../../Printing/GSCUPS/GSCUPSPrintOperation.m"
#undef cupsLastErrorString
#undef cupsPrintFile
#undef GSCUPSPrintOperation
#undef GSPrintOperation

@interface TestCUPSOperation : DeliveryCUPSOperation

@end

@implementation TestCUPSOperation

- (NSPrintInfo *) printInfo
{
  return (NSPrintInfo *)settings;
}

- (NSPrintPanel *) printPanel
{
  return nil;
}

@end
#endif

@interface TestDeliveryOperation : DeliveryOperation

@end

@implementation TestDeliveryOperation

+ (id) allocWithZone: (NSZone *)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (id) init
{
  self = [super init];
  if (self != nil)
    ASSIGN(_path, @"/test/print.ps");
  return self;
}

- (NSPrintInfo *) printInfo
{
  return (NSPrintInfo *)settings;
}

- (NSPrintPanel *) printPanel
{
  return nil;
}

- (BOOL) _deliverSpooledResult
{
  spoolCalls++;
  return accepted;
}

@end

@interface TestLPROperation : DeliveryLPROperation

@end

@implementation TestLPROperation

- (id) init
{
  self = [super init];
  if (self != nil)
    ASSIGN(_path, @"/test/print.ps");
  return self;
}

- (NSPrintInfo *) printInfo
{
  return (NSPrintInfo *)settings;
}

- (NSPrintPanel *) printPanel
{
  return nil;
}

@end

int
main(void)
{
  START_SET("Print delivery results")
  TestDeliveryOperation *operation;
  TestLPROperation *lpr;

  settings = [[DeliverySettings alloc] init];
  operation = [[TestDeliveryOperation alloc] init];
  disposition = NSPrintSpoolJob;
  accepted = NO;
  PASS([operation deliverResult] == NO, "spool rejection is propagated");
  accepted = YES;
  PASS([operation deliverResult] == YES, "spool acceptance is propagated");
  PASS(spoolCalls == 2, "spooling delegates to the backend");

  disposition = NSPrintSaveJob;
  PASS([operation deliverResult] == YES, "completed save remains successful");
  disposition = NSPrintCancelJob;
  PASS([operation deliverResult] == NO, "cancelled delivery fails");
  disposition = NSPrintFaxJob;
  PASS([operation deliverResult] == NO, "unsupported fax delivery fails");
  disposition = @"UnknownDisposition";
  PASS([operation deliverResult] == NO, "unknown delivery fails");
  disposition = nil;
  PASS([operation deliverResult] == NO, "missing disposition fails");
  PASS(spoolCalls == 2, "other dispositions do not submit a print job");

  disposition = NSPrintPreviewJob;
  useViewer = YES;
  accepted = NO;
  PASS([operation deliverResult] == NO, "workspace preview rejection fails");
  accepted = YES;
  PASS([operation deliverResult] == YES, "workspace preview acceptance succeeds");
  useViewer = NO;
  launchFails = YES;
  PASS([operation deliverResult] == NO, "preview launch exception fails");
  launchFails = NO;
  PASS([operation deliverResult] == YES, "preview launch succeeds");

  lpr = [[TestLPROperation alloc] init];
  toolFound = YES;
  exitStatus = 0;
  PASS([lpr _deliverSpooledResult] == YES, "lpr exit zero succeeds");
  exitStatus = 9;
  PASS([lpr _deliverSpooledResult] == NO, "lpr nonzero exit fails");
  launchFails = YES;
  PASS([lpr _deliverSpooledResult] == NO, "lpr launch exception fails");
  launchFails = NO;
  toolFound = NO;
  PASS([lpr _deliverSpooledResult] == NO, "missing lpr fails");

  START_SET("CUPS delivery results")
#ifdef TEST_CUPS
  TestCUPSOperation *cups = [[TestCUPSOperation alloc] init];
  accepted = NO;
  PASS([cups _deliverSpooledResult] == NO, "CUPS job rejection fails");
  accepted = YES;
  PASS([cups _deliverSpooledResult] == YES, "CUPS job acceptance succeeds");
  RELEASE(cups);
#else
  SKIP("CUPS development headers are unavailable");
#endif
  END_SET("CUPS delivery results")

  RELEASE(lpr);
  RELEASE(operation);
  RELEASE(settings);
  END_SET("Print delivery results")
  return 0;
}
