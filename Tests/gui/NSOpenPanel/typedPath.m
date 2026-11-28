#include "Testing.h"

#include <AppKit/AppKit.h>

@interface NSOpenPanel (TypedPathTest)
- (NSMatrix *) lastColumnMatrix;
- (void) typeString: (NSString *)s;
@end

@implementation NSOpenPanel (TypedPathTest)

- (NSMatrix *) lastColumnMatrix
{
  return [_browser matrixInColumn: [_browser lastColumn]];
}

- (void) typeString: (NSString *)s
{
  NSTextView *editor;
  NSDictionary *info;
  NSNotification *n;

  editor = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 100, 20)];
  [editor setString: s];
  info = [NSDictionary dictionaryWithObject: editor forKey: @"NSFieldEditor"];
  n = [NSNotification notificationWithName: NSControlTextDidChangeNotification
                                    object: _form
                                  userInfo: info];
  [self controlTextDidChange: n];
  [editor release];
}

@end

int main(int argc, char **argv)
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSOpenPanel *p;
  NSString *dir;
  NSString *sub;
  NSMatrix *m;

  START_SET("NSOpenPanel typed path")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  dir = [NSTemporaryDirectory() stringByAppendingPathComponent:
    [NSString stringWithFormat: @"typedPath-%d", (int)getpid()]];
  sub = [dir stringByAppendingPathComponent: @"sub"];
  [fm createDirectoryAtPath: sub
    withIntermediateDirectories: YES attributes: nil error: NULL];
  [[NSData data] writeToFile: [dir stringByAppendingPathComponent: @"alpha"]
                  atomically: NO];
  [[NSData data] writeToFile: [dir stringByAppendingPathComponent: @"beta"]
                  atomically: NO];
  [[NSData data] writeToFile: [sub stringByAppendingPathComponent: @"gamma"]
                  atomically: NO];

  p = [NSOpenPanel openPanel];
  [p setShowsHiddenFiles: NO];
  [p setDirectory: dir];

  [p typeString: [dir stringByAppendingPathComponent: @"beta"]];
  m = [p lastColumnMatrix];
  PASS_EQUAL([[m selectedCell] stringValue], @"beta",
    "typing the path of a file selects the file")

  [p typeString: [dir stringByAppendingPathComponent: @"alp"]];
  m = [p lastColumnMatrix];
  PASS_EQUAL([[m selectedCell] stringValue], @"alpha",
    "typing the start of a file name after a folder selects the file")

  [p typeString: [sub stringByAppendingPathComponent: @"gamma"]];
  m = [p lastColumnMatrix];
  PASS_EQUAL([[m selectedCell] stringValue], @"gamma",
    "typing the path of a file in another folder selects the file")
  PASS_EQUAL([p directory], sub,
    "typing the path of a file shows the folder it is in")

  [fm removeItemAtPath: dir error: NULL];

  END_SET("NSOpenPanel typed path")

  [arp release];
  return 0;
}
