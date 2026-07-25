#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSDataLink.h>
#import <AppKit/NSDataLinkManager.h>
#import <AppKit/NSSelection.h>

/* A document standing in for the source and destination of a link.  It
   records the data-transfer messages -[NSDataLink updateDestination] sends. */
@interface DLDoc : NSObject
{
@public
  BOOL importCalled;
  BOOL pasteCalled;
  BOOL copyCalled;
  BOOL wantsUpdate;
  NSString *importedFile;
}
@end

@implementation DLDoc
- (BOOL) importFile: (NSString *)filename at: (NSSelection *)selection
{
  importCalled = YES;
  ASSIGN(importedFile, filename);
  return YES;
}
- (BOOL) pasteFromPasteboard: (NSPasteboard *)pb at: (NSSelection *)selection
{
  pasteCalled = YES;
  return YES;
}
- (BOOL) copyToPasteboard: (NSPasteboard *)pb
                       at: (NSSelection *)selection
         cheapCopyAllowed: (BOOL)flag
{
  copyCalled = YES;
  [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
  [pb setString: @"payload" forType: NSStringPboardType];
  return YES;
}
- (BOOL) dataLinkManager: (NSDataLinkManager *)m isUpdateNeededForLink: (NSDataLink *)l
{
  return wantsUpdate;
}
- (void) dealloc { RELEASE(importedFile); [super dealloc]; }
@end

static NSSelection *aSelection(void)
{
  return [NSSelection selectionWithDescriptionData:
           [@"sel" dataUsingEncoding: NSUTF8StringEncoding]];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDataLink updateDestination")

  // A link with no destination manager cannot update anything.
  {
    NSDataLink *link = AUTORELEASE([[NSDataLink alloc] init]);
    PASS([link updateDestination] == NO,
      "updateDestination returns NO with no destination manager");
  }

  // File source: the destination delegate re-imports the source file.
  {
    DLDoc *dst = AUTORELEASE([DLDoc new]);
    NSDataLinkManager *dstMgr = AUTORELEASE([[NSDataLinkManager alloc]
      initWithDelegate: dst]);
    NSDataLink *link = AUTORELEASE([[NSDataLink alloc]
      initLinkedToFile: @"/tmp/nsdl-source.txt"]);

    [dstMgr addLink: link at: aSelection()];
    BOOL ok = [link updateDestination];
    PASS(ok == YES, "updateDestination returns YES for a file source");
    PASS(dst->importCalled, "the destination delegate is asked to import the file");
    PASS([dst->importedFile isEqual: @"/tmp/nsdl-source.txt"],
      "the source filename is passed to importFile:at:");
    PASS([link lastUpdateTime] != nil, "lastUpdateTime is set after a successful update");
  }

  // In-process source: source copied through a pasteboard, destination pastes.
  {
    DLDoc *src = AUTORELEASE([DLDoc new]);
    DLDoc *dst = AUTORELEASE([DLDoc new]);
    NSDataLinkManager *srcMgr = AUTORELEASE([[NSDataLinkManager alloc]
      initWithDelegate: src]);
    NSDataLinkManager *dstMgr = AUTORELEASE([[NSDataLinkManager alloc]
      initWithDelegate: dst]);
    NSDataLink *link = AUTORELEASE([[NSDataLink alloc]
      initLinkedToSourceSelection: aSelection()
                        managedBy: srcMgr
                  supportingTypes: [NSArray arrayWithObject: NSStringPboardType]]);

    [dstMgr addLink: link at: aSelection()];
    BOOL ok = [link updateDestination];
    PASS(ok == YES, "updateDestination returns YES for an in-process source");
    PASS(src->copyCalled, "the source delegate is asked to copy to the pasteboard");
    PASS(dst->pasteCalled, "the destination delegate is asked to paste from the pasteboard");
  }

  // checkForLinkUpdates drives updateDestination for destination links the
  // delegate flags as needing an update.
  {
    DLDoc *dst = AUTORELEASE([DLDoc new]);
    dst->wantsUpdate = YES;
    NSDataLinkManager *dstMgr = AUTORELEASE([[NSDataLinkManager alloc]
      initWithDelegate: dst]);
    NSDataLink *link = AUTORELEASE([[NSDataLink alloc]
      initLinkedToFile: @"/tmp/nsdl-source.txt"]);

    [dstMgr addLink: link at: aSelection()];
    [dstMgr checkForLinkUpdates];
    PASS(dst->importCalled,
      "checkForLinkUpdates updates a destination link the delegate flags");
  }

  END_SET("NSDataLink updateDestination")

  DESTROY(arp);
  return 0;
}
