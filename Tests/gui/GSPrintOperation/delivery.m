/* Exercise delivery without a display, printer, or external application.
   Compile the delivery implementations with controlled transport substitutes
   so that failures cannot accidentally submit a real print job. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

static NSMutableDictionary *printAttributes;
static NSArray *taskArguments;
static id launchedTask;
static BOOL openedTemporaryFile;
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
- (BOOL) openTempFile: (NSString *)path;

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
  openedTemporaryFile = NO;
  return accepted;
}

- (BOOL) openTempFile: (NSString *)path
{
  openedTemporaryFile = YES;
  /* Model the receiving application's temporary-file handling. A lazy
     viewer cannot read this source again after its open handler returns. */
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
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
  ASSIGN(launchedTask, self);
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
#define GSPrintPreviewFile DeliveryPreviewFile
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
#undef GSPrintPreviewFile

@interface TestDeliveryOperation : DeliveryOperation

- (NSString *) outputPath;

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

- (NSString *) outputPath
{
  return _path;
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

  {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
      [[NSProcessInfo processInfo] globallyUniqueString]];
    NSData *contents = [@"Print job" dataUsingEncoding: NSUTF8StringEncoding];
    TestDeliveryOperation *previewOperation;

    [operation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    disposition = NSPrintSpoolJob;
    accepted = YES;
    PASS([operation deliverResult] && ![manager fileExistsAtPath: path],
         "successful spooling removes its temporary file");
    [operation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    accepted = NO;
    PASS(![operation deliverResult] && ![manager fileExistsAtPath: path],
         "failed spooling removes its temporary file");

    disposition = NSPrintSaveJob;
    [operation _setOutputFile: path temporary: NO];
    [manager createFileAtPath: path contents: contents attributes: nil];
    PASS([operation deliverResult] && [manager fileExistsAtPath: path],
         "explicit save files inside the temporary directory are preserved");
    [printAttributes setObject: path forKey: NSPrintSavePath];
    disposition = NSPrintSpoolJob;
    PASS([operation _prepareOutputFile] && ![[operation outputPath] isEqual: path],
         "a previous save path is not reused for spooling");
    PASS([manager fileExistsAtPath: path], "preparing a spool job leaves the saved file intact");
    [manager removeFileAtPath: path handler: nil];
    [printAttributes removeAllObjects];
    disposition = NSPrintSaveJob;
    PASS(![operation _prepareOutputFile], "saving without a destination fails");

    disposition = NSPrintPreviewJob;
    useViewer = YES;
    accepted = NO;
    [operation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    PASS(![operation deliverResult] && ![manager fileExistsAtPath: path],
         "failed workspace handoff removes its temporary file");
    accepted = YES;
    [operation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    PASS([operation deliverResult] && !openedTemporaryFile,
         "workspace preview opens the source without immediate deletion");
    [operation _removeTemporaryOutputFile];
    PASS_EQUAL([NSData dataWithContentsOfFile: path], contents,
         "preview source remains readable after successful handoff and cleanup");
    [manager removeFileAtPath: path handler: nil];

    useViewer = NO;
    launchFails = YES;
    [operation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    PASS(![operation deliverResult] && ![manager fileExistsAtPath: path],
         "failed preview command launch removes its temporary file");
    launchFails = NO;
    previewOperation = [[TestDeliveryOperation alloc] init];
    [previewOperation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    PASS([previewOperation deliverResult], "preview command starts successfully");
    RELEASE(previewOperation);
    PASS([manager fileExistsAtPath: path], "preview file outlives its print operation");
    [[NSNotificationCenter defaultCenter] postNotificationName: NSTaskDidTerminateNotification
                                                      object: launchedTask];
    PASS(![manager fileExistsAtPath: path], "preview file is removed when the command exits");

    previewOperation = [[TestDeliveryOperation alloc] init];
    [previewOperation _setOutputFile: path temporary: YES];
    [manager createFileAtPath: path contents: contents attributes: nil];
    RELEASE(previewOperation);
    PASS(![manager fileExistsAtPath: path], "abandoned operations remove owned temporary files");
  }

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

  RELEASE(lpr);
  RELEASE(operation);
  RELEASE(settings);
  RELEASE(printAttributes);
  RELEASE(taskArguments);
  RELEASE(launchedTask);
  END_SET("Print delivery results")
  return 0;
}
