/* Coverage for the NSTextView typing attributes and the related state: the
   defaults, the string, the way setFont: and setTextColor: update the
   typing attributes, the typing-attributes accessor, and the
   editable/selectable coupling.  The text view needs its text system and
   the font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextView.h>

static NSTextView *
textView(void)
{
  return AUTORELEASE([[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)]);
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextView *tv;

  START_SET("NSTextView typing attributes")

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
  tv = textView();
  PASS([tv isEditable] == YES, "a text view is editable by default");
  PASS([tv isSelectable] == YES, "a text view is selectable by default");
  PASS([tv isRichText] == YES, "a text view is rich text by default");
  PASS([tv isFieldEditor] == NO, "a text view is not a field editor by default");
  PASS([tv drawsBackground] == YES, "a text view draws its background by default");

  /* The default typing attributes carry a font and a foreground colour. */
  {
    NSDictionary *ta = [tv typingAttributes];

    PASS([ta objectForKey: NSFontAttributeName] != nil,
      "the typing attributes carry a font");
    PASS([ta objectForKey: NSForegroundColorAttributeName] != nil,
      "the typing attributes carry a foreground colour");
  }

  /* The string. */
  [tv setString: @"hello"];
  PASS([[tv string] isEqualToString: @"hello"], "setString: sets the string");
  PASS([[tv string] length] == 5, "the string has the expected length");

  /* setFont: and setTextColor: update the typing attributes. */
  [tv setFont: [NSFont systemFontOfSize: 20.0]];
  PASS([[tv font] pointSize] == 20.0, "setFont: sets the font");
  PASS([[[tv typingAttributes] objectForKey: NSFontAttributeName] pointSize] == 20.0,
    "setFont: updates the typing attributes font");
  [tv setTextColor: [NSColor redColor]];
  PASS([[[tv typingAttributes] objectForKey: NSForegroundColorAttributeName]
         isEqual: [NSColor redColor]],
    "setTextColor: updates the typing attributes colour");

  /* setTypingAttributes: applies the given attributes. */
  {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    [attrs setObject: [NSFont systemFontOfSize: 30.0] forKey: NSFontAttributeName];
    [tv setTypingAttributes: attrs];
    PASS([[[tv typingAttributes] objectForKey: NSFontAttributeName] pointSize] == 30.0,
      "setTypingAttributes: applies the given font");
  }

  /* The editable and selectable flags are coupled: an editable text view is
     always selectable, and a non-selectable one is not editable. */
  tv = textView();
  [tv setEditable: NO];
  PASS([tv isEditable] == NO && [tv isSelectable] == YES,
    "clearing editable leaves the view selectable");
  [tv setSelectable: NO];
  PASS([tv isEditable] == NO && [tv isSelectable] == NO,
    "clearing selectable also clears editable");
  [tv setEditable: YES];
  PASS([tv isEditable] == YES && [tv isSelectable] == YES,
    "setting editable makes the view selectable again");

  /* The rich-text and field-editor flags round-trip. */
  tv = textView();
  [tv setRichText: NO];
  PASS([tv isRichText] == NO, "setRichText: round trips");
  [tv setFieldEditor: YES];
  PASS([tv isFieldEditor] == YES, "setFieldEditor: round trips");

  END_SET("NSTextView typing attributes")

  DESTROY(arp);
  return 0;
}
