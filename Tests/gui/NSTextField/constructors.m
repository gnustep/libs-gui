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
      pass([[label stringValue] isEqualToString: @"Label"],
           "the label keeps its string");
      pass([label isEditable] == NO, "a label is not editable");
      pass([label isSelectable] == NO, "a label is not selectable");
      pass([label isBezeled] == NO, "a label is not bezeled");
      pass([label isBordered] == NO, "a label is not bordered");
      pass([label drawsBackground] == NO, "a label draws no background");
      pass([[label cell] lineBreakMode] == NSLineBreakByClipping,
           "a label clips its line");
      pass([label alignment] == NSTextAlignmentNatural,
           "a label uses natural alignment");

      /* +textFieldWithString: a standard editable field. */
      field = [NSTextField textFieldWithString: @"Field"];
      pass([[field stringValue] isEqualToString: @"Field"],
           "the text field keeps its string");
      pass([field isEditable] == YES, "a text field is editable");
      pass([field isSelectable] == YES, "a text field is selectable");
      pass([field isBezeled] == YES, "a text field is bezeled");
      pass([field isBordered] == NO, "a text field is not bordered");
      pass([field drawsBackground] == YES, "a text field draws its background");

      /* +wrappingLabelWithString: a selectable, wrapping label. */
      wrap = [NSTextField wrappingLabelWithString: @"Wrap"];
      pass([[wrap stringValue] isEqualToString: @"Wrap"],
           "the wrapping label keeps its string");
      pass([wrap isEditable] == NO, "a wrapping label is not editable");
      pass([wrap isSelectable] == YES, "a wrapping label is selectable");
      pass([wrap isBezeled] == NO, "a wrapping label is not bezeled");
      pass([wrap drawsBackground] == NO, "a wrapping label draws no background");
      pass([[wrap cell] lineBreakMode] == NSLineBreakByWordWrapping,
           "a wrapping label wraps at word boundaries");

      /* +labelWithAttributedString: a rich-text label. */
      attr = [NSTextField labelWithAttributedString:
        AUTORELEASE([[NSAttributedString alloc] initWithString: @"Attr"])];
      pass([[attr stringValue] isEqualToString: @"Attr"],
           "the attributed label exposes its plain string");
      pass([attr isEditable] == NO, "an attributed label is not editable");
      pass([attr isSelectable] == NO, "an attributed label is not selectable");
      pass([attr isBezeled] == NO, "an attributed label is not bezeled");
      pass([[attr cell] lineBreakMode] == NSLineBreakByWordWrapping,
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
