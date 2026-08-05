/* NSDataLinkManager watches the source file of every link it tracks, so that
   editing that file outside the application marks the link as needing an
   update.  The manager asks its delegate whether the update is wanted, and it
   has to ask on the main thread: the answer usually comes from the document,
   and the delegate must not be called from the monitoring thread. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSDataLink.h>
#import <AppKit/NSDataLinkManager.h>
#import <AppKit/NSSelection.h>

@interface DLWatchDoc : NSObject
{
@public
  int   askedCount;
  BOOL  askedOnMainThread;
  BOOL  importCalled;
}
@end

@implementation DLWatchDoc
- (BOOL) dataLinkManager: (NSDataLinkManager *)m
   isUpdateNeededForLink: (NSDataLink *)l
{
  askedCount++;
  askedOnMainThread = [NSThread isMainThread];
  return NO;      /* keep the test to the notification itself */
}
- (BOOL) importFile: (NSString *)filename at: (NSSelection *)selection
{
  importCalled = YES;
  return YES;
}
@end

static NSSelection *
aSelection(void)
{
  return [NSSelection selectionWithDescriptionData:
           [@"sel" dataUsingEncoding: NSUTF8StringEncoding]];
}

/* Spin the run loop until the delegate has been asked, or the time runs out. */
static void
waitForNotice(DLWatchDoc *doc, NSTimeInterval limit)
{
  NSDate *end = [NSDate dateWithTimeIntervalSinceNow: limit];

  while (doc->askedCount == 0 && [end timeIntervalSinceNow] > 0)
    {
      [[NSRunLoop currentRunLoop]
        runMode: NSDefaultRunLoopMode
        beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
    }
}

int
main(int argc, const char **argv)
{
  NSFileManager *mgr;
  NSString *dir;
  NSString *source;

  START_SET("NSDataLinkManager source monitoring")

  mgr = [NSFileManager defaultManager];
  dir = [NSTemporaryDirectory()
          stringByAppendingPathComponent: @"nsdl-monitor-test"];
  [mgr createDirectoryAtPath: dir
 withIntermediateDirectories: YES
                  attributes: nil
                       error: NULL];
  source = [dir stringByAppendingPathComponent: @"source.txt"];

  if (![@"first" writeToFile: source atomically: YES])
    {
      SKIP("could not create a source file to watch")
    }

  {
    DLWatchDoc *doc = AUTORELEASE([DLWatchDoc new]);
    NSDataLinkManager *manager = AUTORELEASE([[NSDataLinkManager alloc]
      initWithDelegate: doc
              fromFile: [dir stringByAppendingPathComponent: @"doc"]]);
    NSDataLink *link = AUTORELEASE([[NSDataLink alloc]
      initLinkedToFile: source]);

    PASS([manager addLink: link at: aSelection()] == YES,
      "a link to a source file is added to the manager");

    /* Change the file the way another application would. */
    [@"second" writeToFile: source atomically: NO];

    waitForNotice(doc, 5.0);

    PASS(doc->askedCount > 0,
      "editing the source file asks the delegate whether an update is needed");
    PASS(doc->askedCount == 0 || doc->askedOnMainThread,
      "the delegate is asked on the main thread");

    [manager removeLink: link];
  }

  [mgr removeItemAtPath: dir error: NULL];

  END_SET("NSDataLinkManager source monitoring")

  return 0;
}
