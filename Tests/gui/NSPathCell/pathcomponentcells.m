/* -[NSPathCell pathComponentCells] returns an empty array (not nil) for a cell
   with no components, matching AppKit. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPathCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPathCell pathComponentCells")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSPathCell *pc = [[NSPathCell alloc] init];

  PASS([pc pathComponentCells] != nil,
       "-pathComponentCells is not nil for an empty cell");
  PASS([[pc pathComponentCells] count] == 0,
       "-pathComponentCells is empty for an empty cell");

  RELEASE(pc);

  END_SET("NSPathCell pathComponentCells")

  DESTROY(arp);
  return 0;
}
