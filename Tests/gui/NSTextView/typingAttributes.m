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
  pass([tv isEditable] == YES, "a text view is editable by default");
  pass([tv isSelectable] == YES, "a text view is selectable by default");
  pass([tv isRichText] == YES, "a text view is rich text by default");
  pass([tv isFieldEditor] == NO, "a text view is not a field editor by default");
  pass([tv drawsBackground] == YES, "a text view draws its background by default");

  /* The default typing attributes carry a font and a foreground colour. */
  {
    NSDictionary *ta = [tv typingAttributes];

    pass([ta objectForKey: NSFontAttributeName] != nil,
      "the typing attributes carry a font");
    pass([ta objectForKey: NSForegroundColorAttributeName] != nil,
      "the typing attributes carry a foreground colour");
  }

  /* The string. */
  [tv setString: @"hello"];
  pass([[tv string] isEqualToString: @"hello"], "setString: sets the string");
  pass([[tv string] length] == 5, "the string has the expected length");

  /* setFont: and setTextColor: update the typing attributes. */
  [tv setFont: [NSFont systemFontOfSize: 20.0]];
  pass([[tv font] pointSize] == 20.0, "setFont: sets the font");
  pass([[[tv typingAttributes] objectForKey: NSFontAttributeName] pointSize] == 20.0,
    "setFont: updates the typing attributes font");
  [tv setTextColor: [NSColor redColor]];
  pass([[[tv typingAttributes] objectForKey: NSForegroundColorAttributeName]
         isEqual: [NSColor redColor]],
    "setTextColor: updates the typing attributes colour");

  /* setTypingAttributes: applies the given attributes. */
  {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    [attrs setObject: [NSFont systemFontOfSize: 30.0] forKey: NSFontAttributeName];
    [tv setTypingAttributes: attrs];
    pass([[[tv typingAttributes] objectForKey: NSFontAttributeName] pointSize] == 30.0,
      "setTypingAttributes: applies the given font");
  }

  /* The editable and selectable flags are coupled: an editable text view is
     always selectable, and a non-selectable one is not editable. */
  tv = textView();
  [tv setEditable: NO];
  pass([tv isEditable] == NO && [tv isSelectable] == YES,
    "clearing editable leaves the view selectable");
  [tv setSelectable: NO];
  pass([tv isEditable] == NO && [tv isSelectable] == NO,
    "clearing selectable also clears editable");
  [tv setEditable: YES];
  pass([tv isEditable] == YES && [tv isSelectable] == YES,
    "setting editable makes the view selectable again");

  /* The rich-text and field-editor flags round-trip. */
  tv = textView();
  [tv setRichText: NO];
  pass([tv isRichText] == NO, "setRichText: round trips");
  [tv setFieldEditor: YES];
  pass([tv isFieldEditor] == YES, "setFieldEditor: round trips");

  END_SET("NSTextView typing attributes")

  DESTROY(arp);
  return 0;
}
