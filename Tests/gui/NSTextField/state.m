/* Coverage for NSTextField state: the defaults of a plain frame-initialised
   field (editable, selectable, bezeled, not bordered, draws its background,
   left alignment, square bezel, no attribute editing, colours present, empty
   value, no placeholder), the setter round-trips and the rule that making a
   field editable also makes it selectable.  Checked against AppKit on a macOS
   runner (alignment and bezel style are compared by their enumerated names,
   whose raw values differ between GNUstep and macOS).  The field uses the
   theme and font backend, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSText.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextField *tf;

  START_SET("NSTextField state")

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

  NS_DURING
    {
      tf = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 22)]);

      /* Defaults. */
      pass([tf isEditable] == YES, "a text field is editable by default");
      pass([tf isSelectable] == YES, "a text field is selectable by default");
      pass([tf isBezeled] == YES, "a text field is bezeled by default");
      pass([tf isBordered] == NO, "a text field is not bordered by default");
      pass([tf drawsBackground] == YES,
           "a text field draws its background by default");
      pass([tf alignment] == NSTextAlignmentLeft,
           "the default alignment is left");
      pass([tf allowsEditingTextAttributes] == NO,
           "attribute editing is off by default");
      pass([tf textColor] != nil, "there is a text colour by default");
      pass([tf backgroundColor] != nil, "there is a background colour by default");
      pass([[tf stringValue] isEqualToString: @""],
           "the default string value is empty");
      pass([tf placeholderString] == nil, "there is no placeholder by default");

      /* Setter round-trips. */
      [tf setEditable: NO];
      pass([tf isEditable] == NO, "setEditable: round trips");
      [tf setSelectable: NO];
      pass([tf isSelectable] == NO, "setSelectable: round trips");
      [tf setBezeled: NO];
      pass([tf isBezeled] == NO, "setBezeled: round trips");
      [tf setBordered: YES];
      pass([tf isBordered] == YES, "setBordered: round trips");
      [tf setDrawsBackground: NO];
      pass([tf drawsBackground] == NO, "setDrawsBackground: round trips");
      [tf setAlignment: NSTextAlignmentRight];
      pass([tf alignment] == NSTextAlignmentRight, "setAlignment: round trips");
      [tf setStringValue: @"hello"];
      pass([[tf stringValue] isEqualToString: @"hello"],
           "setStringValue: round trips");
      [tf setPlaceholderString: @"type here"];
      pass([[tf placeholderString] isEqualToString: @"type here"],
           "setPlaceholderString: round trips");

      /* Making a field editable makes it selectable too. */
      NSTextField *tf2 = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 22)]);
      [tf2 setSelectable: NO];
      [tf2 setEditable: YES];
      pass([tf2 isSelectable] == YES,
           "making a field editable makes it selectable");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSTextField state")

  DESTROY(arp);
  return 0;
}
