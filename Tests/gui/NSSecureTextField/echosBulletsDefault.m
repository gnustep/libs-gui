/* A freshly created NSSecureTextFieldCell echoes bullets by default, the
   same as NSSecureTextField and Apple's NSSecureTextFieldCell (a
   standalone cell reports echosBullets == YES on macOS).  The cell touches
   the font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSecureTextField.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSSecureTextFieldCell default echosBullets")

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

  PASS([AUTORELEASE([[NSSecureTextFieldCell alloc] init]) echosBullets] == YES,
       "a freshly created secure cell echoes bullets by default");
  PASS([AUTORELEASE([[NSSecureTextFieldCell alloc] initTextCell: @""]) echosBullets] == YES,
       "a secure cell from initTextCell: echoes bullets by default");

  END_SET("NSSecureTextFieldCell default echosBullets")

  DESTROY(arp);
  return 0;
}
