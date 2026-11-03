#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSPasteboard.h>

int
main(int argc, const char **argv)
{
  START_SET("NSResponder first responder")

  NSResponder *r = AUTORELEASE([NSResponder new]);

  /* Defaults checked against AppKit. */
  PASS([r acceptsFirstResponder] == NO,
    "acceptsFirstResponder defaults to NO");
  PASS([r becomeFirstResponder] == YES,
    "becomeFirstResponder defaults to YES");
  PASS([r resignFirstResponder] == YES,
    "resignFirstResponder defaults to YES");
  PASS([r undoManager] == nil,
    "undoManager defaults to nil");
  PASS([r validRequestorForSendType: NSStringPboardType
                          returnType: NSStringPboardType] == nil,
    "validRequestorForSendType:returnType: defaults to nil");

  END_SET("NSResponder first responder")
  return 0;
}
