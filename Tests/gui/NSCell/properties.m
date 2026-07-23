#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSActionCell.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSButtonCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSImageCell *imgCell;
  NSActionCell *actCell;
  NSButtonCell *buttCell;
  NSTextFieldCell *tfCell;
  NSCell *cell; 

  START_SET("NSCell RefusesResponder")
  
  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
       SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  imgCell = AUTORELEASE([[NSImageCell alloc] initImageCell:nil]);
  PASS([imgCell refusesFirstResponder] == YES, "NSImageCell initImageCell refusesFirstResponder");

  cell = AUTORELEASE([[NSCell alloc] initImageCell:nil]);
  PASS([cell refusesFirstResponder] == NO, "NSCell initImageCell refusesFirstResponder");

  buttCell = AUTORELEASE([[NSButtonCell alloc] init]);
  PASS([buttCell refusesFirstResponder] == NO, "NSButtonCell init refusesFirstResponder");

  tfCell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell:@""]);
  PASS([tfCell refusesFirstResponder] == NO, "NSTextFieldCell initTextCell refusesFirstResponder");

  actCell = AUTORELEASE([[NSActionCell alloc] init]);
  PASS([actCell refusesFirstResponder] == NO, "NSActionCell init refusesFirstResponder");

  cell = AUTORELEASE([[NSCell alloc] init]);
  PASS([cell refusesFirstResponder] == NO, "NSCell init refusesFirstResponder");

  END_SET("NSCell RefusesResponder")

  DESTROY(arp);
  return 0;
}
