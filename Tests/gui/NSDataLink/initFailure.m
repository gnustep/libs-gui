#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <AppKit/NSDataLink.h>
#import <AppKit/NSPasteboard.h>

/* -[NSDataLink initWithContentsOfFile:] and -initWithPasteboard: handed the
   loaded data straight to NSUnarchiver, which raises for nil data (a missing
   file or a pasteboard with no link) and while decoding malformed data.  A
   failed load must return nil instead (gnustep/libs-gui issue #215/#167). */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDataLink init failure")

  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *dir = NSTemporaryDirectory();
  NSString *missing = [dir stringByAppendingPathComponent: @"nsdl-missing.dlf"];
  NSString *empty = [dir stringByAppendingPathComponent: @"nsdl-empty.dlf"];
  NSString *corrupt = [dir stringByAppendingPathComponent: @"nsdl-corrupt.dlf"];
  id link;

  [fm removeFileAtPath: missing handler: nil];
  [[NSData data] writeToFile: empty atomically: YES];
  [[@"not a valid archive" dataUsingEncoding: NSUTF8StringEncoding]
    writeToFile: corrupt atomically: YES];

  link = AUTORELEASE([[NSDataLink alloc] initWithContentsOfFile: missing]);
  PASS(link == nil, "initWithContentsOfFile: returns nil for a missing file");

  link = AUTORELEASE([[NSDataLink alloc] initWithContentsOfFile: empty]);
  PASS(link == nil, "initWithContentsOfFile: returns nil for an empty file");

  link = AUTORELEASE([[NSDataLink alloc] initWithContentsOfFile: corrupt]);
  PASS(link == nil, "initWithContentsOfFile: returns nil for a corrupt file");

  NS_DURING
    {
      NSPasteboard *pb = [NSPasteboard pasteboardWithName: @"nsdl init test"];
      [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
                 owner: nil];
      link = AUTORELEASE([[NSDataLink alloc] initWithPasteboard: pb]);
      PASS(link == nil,
        "initWithPasteboard: returns nil when there is no link data");
    }
  NS_HANDLER
    SKIP("pasteboard server is not available")
  NS_ENDHANDLER

  [fm removeFileAtPath: empty handler: nil];
  [fm removeFileAtPath: corrupt handler: nil];

  END_SET("NSDataLink init failure")
  DESTROY(arp);
  return 0;
}
