#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSData.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableColumn.h>

int
main(int argc, char **argv)
{
  NSTableColumn *col;
  NSTableColumn *copy;
  NSData *data;
  CGFloat width = 123.456789;

  START_SET("NSTableColumn width")

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

  col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"col"]);
  [col setMaxWidth: 1000.0];
  [col setMinWidth: 1.0];

  [col setWidth: width];
  PASS([col width] == width, "-setWidth: keeps the width it was given");

  [col setMinWidth: width];
  PASS([col minWidth] == width, "-setMinWidth: keeps the width it was given");

  [col setMaxWidth: width];
  PASS([col maxWidth] == width, "-setMaxWidth: keeps the width it was given");

  /* The archive format stays as it was, so a column still reads back the
     width an earlier version wrote. */
  col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"col"]);
  [col setMinWidth: 8.0];
  [col setMaxWidth: 512.0];
  [col setWidth: 123.5];
  data = [NSArchiver archivedDataWithRootObject: col];
  copy = [NSUnarchiver unarchiveObjectWithData: data];
  PASS([copy width] == 123.5, "a column carries its width through an archive");
  PASS([copy minWidth] == 8.0 && [copy maxWidth] == 512.0,
       "a column carries its width limits through an archive");

  END_SET("NSTableColumn width")

  return 0;
}
