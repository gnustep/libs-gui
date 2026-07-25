/* Coverage for NSTextStorage state that needs no window server: the edited-mask
   enum values, the initial string and length, the empty layout-manager list, a
   nil delegate, the zero editing state, and the delegate round-trip.  Every
   assertion here matches AppKit (verified on a macOS runner) and passes on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSTextStorage.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextStorage *ts;
  id delegate;

  PASS(NSTextStorageEditedAttributes == 1,
       "NSTextStorageEditedAttributes is 1");
  PASS(NSTextStorageEditedCharacters == 2,
       "NSTextStorageEditedCharacters is 2");

  ts = AUTORELEASE([[NSTextStorage alloc] initWithString: @"hello"]);

  PASS([ts length] == 5, "length is the length of the initial string");
  PASS([[ts string] isEqual: @"hello"], "string is the initial string");
  PASS([[ts layoutManagers] count] == 0,
       "a new text storage has no layout managers");
  PASS([ts delegate] == nil, "default delegate is nil");
  PASS([ts editedMask] == 0, "default editedMask is 0");
  PASS([ts changeInLength] == 0, "default changeInLength is 0");

  delegate = AUTORELEASE([[NSObject alloc] init]);
  [ts setDelegate: delegate];
  PASS([ts delegate] == delegate, "delegate round-trips");

  DESTROY(arp);
  return 0;
}
