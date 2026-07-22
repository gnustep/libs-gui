/* Coverage for the NSTextField convenience constructors: +labelWithString:,
   +labelWithAttributedString:, +textFieldWithString: and
   +wrappingLabelWithString:.  Each configures the field the way AppKit does
   (checked against AppKit on a macOS runner): a label is not editable, not
   bezeled, not bordered and draws no background; a text field is editable and
   bezeled and draws its background; a wrapping label is selectable and word
   wraps.  Line-break modes and alignment are compared by their enumerated
   names, whose raw values differ between GNUstep and macOS.  The field uses
   the theme and font backend, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSText.h>
#include <AppKit/NSParagraphStyle.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextField *label, *field, *wrap, *attr;

  START_SET("NSTextField constructors")

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
      /* +labelWithString: a static, non-interactive label. */
      label = [NSTextField labelWithString: @"Label"];
      PASS([[label stringValue] isEqualToString: @"Label"],
           "the label keeps its string");
      PASS([label isEditable] == NO, "a label is not editable");
      PASS([label isSelectable] == NO, "a label is not selectable");
      PASS([label isBezeled] == NO, "a label is not bezeled");
      PASS([label isBordered] == NO, "a label is not bordered");
      PASS([label drawsBackground] == NO, "a label draws no background");
      PASS([[label cell] lineBreakMode] == NSLineBreakByClipping,
           "a label clips its line");
      PASS([label alignment] == NSTextAlignmentNatural,
           "a label uses natural alignment");

      /* +textFieldWithString: a standard editable field. */
      field = [NSTextField textFieldWithString: @"Field"];
      PASS([[field stringValue] isEqualToString: @"Field"],
           "the text field keeps its string");
      PASS([field isEditable] == YES, "a text field is editable");
      PASS([field isSelectable] == YES, "a text field is selectable");
      PASS([field isBezeled] == YES, "a text field is bezeled");
      PASS([field isBordered] == NO, "a text field is not bordered");
      PASS([field drawsBackground] == YES, "a text field draws its background");

      /* +wrappingLabelWithString: a selectable, wrapping label. */
      wrap = [NSTextField wrappingLabelWithString: @"Wrap"];
      PASS([[wrap stringValue] isEqualToString: @"Wrap"],
           "the wrapping label keeps its string");
      PASS([wrap isEditable] == NO, "a wrapping label is not editable");
      PASS([wrap isSelectable] == YES, "a wrapping label is selectable");
      PASS([wrap isBezeled] == NO, "a wrapping label is not bezeled");
      PASS([wrap drawsBackground] == NO, "a wrapping label draws no background");
      PASS([[wrap cell] lineBreakMode] == NSLineBreakByWordWrapping,
           "a wrapping label wraps at word boundaries");

      /* +labelWithAttributedString: a rich-text label. */
      attr = [NSTextField labelWithAttributedString:
        AUTORELEASE([[NSAttributedString alloc] initWithString: @"Attr"])];
      PASS([[attr stringValue] isEqualToString: @"Attr"],
           "the attributed label exposes its plain string");
      PASS([attr isEditable] == NO, "an attributed label is not editable");
      PASS([attr isSelectable] == NO, "an attributed label is not selectable");
      PASS([attr isBezeled] == NO, "an attributed label is not bezeled");
      PASS([[attr cell] lineBreakMode] == NSLineBreakByWordWrapping,
           "an attributed label wraps at word boundaries");
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

  END_SET("NSTextField constructors")

  DESTROY(arp);
  return 0;
}
