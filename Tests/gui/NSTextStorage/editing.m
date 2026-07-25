/* Coverage for NSTextStorage editing and layout managers.  An insertion inside
   a beginEditing/endEditing group records the edited characters and the change
   in length and is applied to the string; an added attribute is reported within
   its range and absent outside it; and a layout manager can be added and
   removed.  Processing the edit fixes attributes (which needs the font system),
   so these are guarded by the usual backend check.  Matches AppKit (verified on
   a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSRange.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSLayoutManager.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextStorage *ts;
  NSLayoutManager *lm;

  START_SET("NSTextStorage editing")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  ts = AUTORELEASE([[NSTextStorage alloc] initWithString: @"hello"]);

  [ts beginEditing];
  [ts replaceCharactersInRange: NSMakeRange(0, 0) withString: @"X"];
  PASS(([ts editedMask] & NSTextStorageEditedCharacters) != 0,
       "an insertion records edited characters");
  PASS([ts changeInLength] == 1,
       "an insertion records a change in length of one");
  [ts endEditing];
  PASS([[ts string] isEqual: @"Xhello"],
       "the insertion is applied to the string");
  PASS([ts length] == 6, "the length reflects the insertion");

  [ts addAttribute: @"testAttr" value: @"testVal" range: NSMakeRange(0, 3)];
  PASS([[ts attribute: @"testAttr" atIndex: 0 effectiveRange: NULL]
         isEqual: @"testVal"],
       "an added attribute is returned within its range");
  PASS([ts attribute: @"testAttr" atIndex: 5 effectiveRange: NULL] == nil,
       "the attribute is absent outside its range");

  lm = AUTORELEASE([[NSLayoutManager alloc] init]);
  [ts addLayoutManager: lm];
  PASS([[ts layoutManagers] count] == 1, "a layout manager can be added");
  PASS([[ts layoutManagers] containsObject: lm],
       "the added layout manager is in the list");
  [ts removeLayoutManager: lm];
  PASS([[ts layoutManagers] count] == 0, "a layout manager can be removed");

  END_SET("NSTextStorage editing")

  DESTROY(arp);
  return 0;
}
