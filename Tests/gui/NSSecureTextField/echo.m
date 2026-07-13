/* Coverage for NSSecureTextField and NSSecureTextFieldCell: the hard-wired
   cell class, the echosBullets flag and the way the field delegates it to
   its cell, the fixed-pitch font substitution done by the cell, the fact
   that the real string value is still stored, and the cell's NSCoding
   round trip.  These classes touch the font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSKeyedArchiver.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSSecureTextField.h>
#include <AppKit/NSTextFieldCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSecureTextField *field;
  NSSecureTextFieldCell *cell;

  START_SET("NSSecureTextField echo")

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

  /* The cell class is hard-wired and cannot be replaced. */
  pass([NSSecureTextField cellClass] == [NSSecureTextFieldCell class],
       "the cell class is NSSecureTextFieldCell");
  {
    BOOL raised = NO;

    NS_DURING
      [NSSecureTextField setCellClass: [NSTextFieldCell class]];
    NS_HANDLER
      raised = [[localException name] isEqualToString: NSInvalidArgumentException];
    NS_ENDHANDLER
    pass(raised, "setCellClass: raises rather than accept another class");
  }

  /* A field uses a secure cell, echoes bullets by default, and forwards
     the flag to its cell. */
  field = AUTORELEASE([[NSSecureTextField alloc] initWithFrame: NSMakeRect(0, 0, 100, 22)]);
  pass([[field cell] isKindOfClass: [NSSecureTextFieldCell class]],
       "the field is backed by a secure cell");
  pass([field echosBullets] == YES, "a field echoes bullets by default");
  [field setEchosBullets: NO];
  pass([field echosBullets] == NO, "setEchosBullets: NO turns echoing off");
  pass([[field cell] echosBullets] == NO, "the flag is forwarded to the cell");
  [field setEchosBullets: YES];
  pass([field echosBullets] == YES, "setEchosBullets: YES turns it back on");

  /* The cell round-trips the flag. */
  cell = AUTORELEASE([[NSSecureTextFieldCell alloc] init]);
  [cell setEchosBullets: NO];
  pass([cell echosBullets] == NO, "setEchosBullets: NO on the cell round trips");
  [cell setEchosBullets: YES];
  pass([cell echosBullets] == YES, "setEchosBullets: YES on the cell round trips");

  /* -setFont: substitutes a fixed-pitch font. */
  {
    NSFont *variable = [NSFont systemFontOfSize: 14.0];
    NSFont *fixed = [NSFont userFixedPitchFontOfSize: 14.0];

    [cell setFont: variable];
    pass([[[cell font] fontName] isEqualToString: [fixed fontName]],
         "setFont: substitutes the user fixed-pitch font for a variable one");
    pass([[cell font] pointSize] == 14.0, "the substituted font keeps the point size");
  }

  /* The real value is stored; only the display is obscured. */
  [cell setStringValue: @"secret"];
  pass([[cell stringValue] isEqualToString: @"secret"],
       "the cell still stores the real string value");

  /* The cell preserves echosBullets across a keyed archive. */
  {
    NSSecureTextFieldCell *seed = AUTORELEASE([[NSSecureTextFieldCell alloc] init]);
    NSData *data;
    NSSecureTextFieldCell *decoded;

    [seed setEchosBullets: NO];
    data = [NSKeyedArchiver archivedDataWithRootObject: seed];
    decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    pass([decoded echosBullets] == NO, "the cell preserves echosBullets across archiving");
  }

  END_SET("NSSecureTextField echo")

  DESTROY(arp);
  return 0;
}
