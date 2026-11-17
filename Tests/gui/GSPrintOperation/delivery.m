/* Exercise delivery without a display, printer, or external application.
   Compile the delivery implementations with controlled transport substitutes
   so that failures cannot accidentally submit a real print job. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

static NSMutableDictionary *printAttributes;
static NSArray *taskArguments;
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
- (NSArray *) stringListForKey: (NSString *)key inTable: (NSString *)table;

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
  return printAttributes;
}

- (NSArray *) stringListForKey: (NSString *)key inTable: (NSString *)table
{
  if ([key isEqual: @"Resolution"])
    return [NSArray arrayWithObjects: @"300dpi", @"600dpi", nil];
  if ([key isEqual: @"InputSlot"])
    return [NSArray arrayWithObjects: @"Upper", @"Lower", nil];
  if ([key isEqual: @"ManualFeed"])
    return [NSArray arrayWithObjects: @"True", @"False", nil];
  if ([key isEqual: @"Duplex"])
    return [NSArray arrayWithObjects: @"None", @"DuplexNoTumble", nil];
  return nil;
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
  ASSIGNCOPY(taskArguments, arguments);
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

static NSMutableDictionary *submittedOptions;
static int optionsFreed;

/* Keep the CUPS transport mocked, including option storage, so these tests
   need headers but neither libcups nor a running server. */
static int
DeliveryCUPSAddOption(const char *name, const char *value, int count,
                      cups_option_t **options)
{
  int i;

  for (i = 0; i < count; i++)
    if (strcmp((*options)[i].name, name) == 0)
      break;
  if (i == count)
    {
      *options = realloc(*options, (count + 1) * sizeof(cups_option_t));
      (*options)[i].name = strdup(name);
      (*options)[i].value = NULL;
      count++;
    }
  free((*options)[i].value);
  (*options)[i].value = strdup(value);
  return count;
}

static void
DeliveryCUPSFreeOptions(int count, cups_option_t *options)
{
  int i;

  for (i = 0; i < count; i++)
    {
      free(options[i].name);
      free(options[i].value);
    }
  free(options);
  optionsFreed++;
}

static int
DeliveryCUPSPrintFile(const char *name, const char *path, const char *title,
                      int count, cups_option_t *options)
{
  int i;

  [submittedOptions removeAllObjects];
  for (i = 0; i < count; i++)
    [submittedOptions setObject: [NSString stringWithUTF8String: options[i].value]
                         forKey: [NSString stringWithUTF8String: options[i].name]];
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
#define cupsAddOption DeliveryCUPSAddOption
#define cupsFreeOptions DeliveryCUPSFreeOptions
#include "../../../Printing/GSCUPS/GSCUPSPrintOperation.m"
#undef cupsFreeOptions
#undef cupsAddOption
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
  printAttributes = [[NSMutableDictionary alloc] init];
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
  [printAttributes setObject: [NSNumber numberWithInt: 3] forKey: NSPrintCopies];
  PASS([lpr _deliverSpooledResult] && [taskArguments containsObject: @"-#3"],
       "LPR submits the selected copy count");
  [printAttributes setObject: [NSNumber numberWithInt: 1] forKey: NSPrintCopies];
  PASS([lpr _deliverSpooledResult] && ![taskArguments containsObject: @"-#3"],
       "LPR does not reuse the previous copy count");
  [printAttributes removeAllObjects];
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
  NSMutableDictionary *features = [NSMutableDictionary dictionary];
  submittedOptions = [[NSMutableDictionary alloc] init];
  accepted = NO;
  PASS([cups _deliverSpooledResult] == NO, "CUPS job rejection fails");
  accepted = YES;
  PASS([cups _deliverSpooledResult] == YES, "CUPS job acceptance succeeds");
  PASS([[submittedOptions objectForKey: @"copies"] isEqual: @"1"],
       "CUPS defaults to one copy");
  PASS(optionsFreed == 2, "CUPS options are freed on success and failure");

  [printAttributes setObject: [NSNumber numberWithInt: 3] forKey: NSPrintCopies];
  [printAttributes setObject: [NSNumber numberWithBool: YES] forKey: NSPrintMustCollate];
  [printAttributes setObject: @"A4" forKey: NSPrintPaperName];
  [features setObject: @"Resolution/600dpi" forKey: @"Resolution"];
  [features setObject: @"InputSlot/Lower" forKey: @"InputSlot"];
  [features setObject: @"Duplex/DuplexNoTumble" forKey: @"Duplex"];
  [printAttributes setObject: features forKey: NSPrintJobFeatures];
  [printAttributes setObject: [NSNumber numberWithInt: 4] forKey: NSPrintPagesPerSheet];
  [printAttributes setObject: [NSNumber numberWithInt: 2] forKey: NSPrintFirstPage];
  [printAttributes setObject: [NSNumber numberWithInt: 6] forKey: NSPrintLastPage];
  [printAttributes setObject: [NSNumber numberWithBool: YES] forKey: NSPrintReversePageOrder];
  [printAttributes setObject: [NSNumber numberWithDouble: 0.5] forKey: NSPrintScalingFactor];
  [printAttributes setObject: [NSNumber numberWithInt: NSLandscapeOrientation] forKey: NSPrintOrientation];
  PASS([cups _deliverSpooledResult], "CUPS accepts a configured job");
  PASS([[submittedOptions objectForKey: @"copies"] isEqual: @"3"], "CUPS receives copies");
  PASS([[submittedOptions objectForKey: @"Collate"] isEqual: @"True"], "CUPS receives collation");
  PASS([[submittedOptions objectForKey: @"PageSize"] isEqual: @"A4"], "CUPS receives named media");
  PASS([[submittedOptions objectForKey: @"Resolution"] isEqual: @"600dpi"], "CUPS receives resolution");
  PASS([[submittedOptions objectForKey: @"InputSlot"] isEqual: @"Lower"], "CUPS receives paper tray");
  PASS([[submittedOptions objectForKey: @"Duplex"] isEqual: @"DuplexNoTumble"], "CUPS receives a supported PPD feature");
  PASS([submittedOptions count] == 6, "rendered layout settings are not forwarded");

  [features setObject: @"Resolution/999dpi" forKey: @"Resolution"];
  [features setObject: @"InputSlot/" forKey: @"InputSlot"];
  [features setObject: @"Duplex" forKey: @"Duplex"];
  [features setObject: [NSNumber numberWithInt: 3] forKey: @"Invalid"];
  [features setObject: @"number-up/4" forKey: @"Layout"];
  [printAttributes setObject: [NSNumber numberWithInt: -5] forKey: NSPrintCopies];
  [printAttributes setObject: [NSNumber numberWithBool: NO] forKey: NSPrintMustCollate];
  PASS([cups _deliverSpooledResult], "malformed optional features do not crash submission");
  PASS([[submittedOptions objectForKey: @"copies"] isEqual: @"1"], "invalid copies normalize to one");
  PASS([[submittedOptions objectForKey: @"Collate"] isEqual: @"False"], "collation can be disabled");
  PASS([submittedOptions count] == 3, "unsupported and malformed PPD choices are excluded");

  [printAttributes removeAllObjects];
  [printAttributes setObject: NSPrintManualFeed forKey: NSPrintPaperFeed];
  PASS([cups _deliverSpooledResult], "manual-feed job is submitted");
  PASS([[submittedOptions objectForKey: @"ManualFeed"] isEqual: @"True"], "manual feed is translated");
  [printAttributes setObject: @"InputSlot/Upper" forKey: NSPrintPaperFeed];
  PASS([cups _deliverSpooledResult], "tray job is submitted");
  PASS([[submittedOptions objectForKey: @"InputSlot"] isEqual: @"Upper"], "paper-feed reference is translated");
  PASS([submittedOptions objectForKey: @"ManualFeed"] == nil, "options do not leak between submissions");
  [printAttributes setObject: @"bad features" forKey: NSPrintJobFeatures];
  PASS_RUNS([cups _deliverSpooledResult];, "malformed feature dictionary is ignored");
  RELEASE(submittedOptions);
  RELEASE(cups);
#else
  SKIP("CUPS development headers are unavailable");
#endif
  END_SET("CUPS delivery results")

  RELEASE(lpr);
  RELEASE(operation);
  RELEASE(settings);
  RELEASE(printAttributes);
  RELEASE(taskArguments);
  END_SET("Print delivery results")
  return 0;
}
