/* Coverage for the NSTextFieldCell graphic attributes: the defaults for
   drawsBackground, the bezel style, the background colour and the
   placeholder, the text/background colour and bezel-style accessors, the
   string / attributed placeholder pair, and that the real string value is
   stored.  The cell touches the font backend, so the set is skipped when
   the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextFieldCell *cell;

  START_SET("NSTextFieldCell attributes")

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

  /* Defaults. */
  cell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell: @""]);
  pass([cell drawsBackground] == NO, "a text field cell does not draw its background by default");
  pass([cell bezelStyle] == NSTextFieldSquareBezel, "the default bezel style is square");
  pass([[cell backgroundColor] isEqual: [NSColor textBackgroundColor]],
       "the default background colour is the text background colour");
  pass([cell textColor] != nil, "a default text colour is set");
  pass([cell placeholderString] == nil && [cell placeholderAttributedString] == nil,
       "there is no placeholder by default");

  /* Colour and bezel-style accessors. */
  [cell setTextColor: [NSColor redColor]];
  pass([[cell textColor] isEqual: [NSColor redColor]], "setTextColor: updates the text colour");
  [cell setBackgroundColor: [NSColor blueColor]];
  pass([[cell backgroundColor] isEqual: [NSColor blueColor]], "setBackgroundColor: updates the background colour");
  [cell setBezelStyle: NSTextFieldRoundedBezel];
  pass([cell bezelStyle] == NSTextFieldRoundedBezel, "setBezelStyle: updates the bezel style");

  /* The placeholder is either a plain string or an attributed string; the
     accessor for the other kind returns nil. */
  cell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell: @""]);
  [cell setPlaceholderString: @"type here"];
  pass([[cell placeholderString] isEqualToString: @"type here"],
       "placeholderString returns the plain placeholder");
  pass([cell placeholderAttributedString] == nil,
       "placeholderAttributedString is nil for a plain placeholder");
  {
    NSAttributedString *attr = AUTORELEASE([[NSAttributedString alloc] initWithString: @"attr ph"]);
    [cell setPlaceholderAttributedString: attr];
    pass([[[cell placeholderAttributedString] string] isEqualToString: @"attr ph"],
         "placeholderAttributedString returns the attributed placeholder");
    pass([cell placeholderString] == nil,
         "placeholderString is nil for an attributed placeholder");
  }

  /* The real string value is stored. */
  [cell setStringValue: @"hello"];
  pass([[cell stringValue] isEqualToString: @"hello"], "the cell stores its string value");

  END_SET("NSTextFieldCell attributes")

  DESTROY(arp);
  return 0;
}
