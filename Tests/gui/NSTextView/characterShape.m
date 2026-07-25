/* NSTextView -toggleTraditionalCharacterShape: sets NSCharacterShapeAttributeName
   over the selection, toggling between the traditional shape (1) and the
   default shape (0).  The sequence (no attribute -> 1 -> 0 -> 1) matches AppKit
   (verified on a macOS runner).  NSTextView needs the text system and the font
   backend, so the set is skipped when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextStorage.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextView *tv;

  START_SET("NSTextView character shape")

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

  tv = AUTORELEASE([[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)]);
  [tv setString: @"hello"];
  [tv setSelectedRange: NSMakeRange(0, 5)];

  PASS([[tv textStorage] attribute: NSCharacterShapeAttributeName
                        atIndex: 0
                 effectiveRange: NULL] == nil,
    "no character shape attribute by default");

  [tv toggleTraditionalCharacterShape: nil];
  PASS([[[tv textStorage] attribute: NSCharacterShapeAttributeName
                          atIndex: 0
                   effectiveRange: NULL] intValue] == 1,
    "the first toggle sets the traditional character shape (1)");

  [tv toggleTraditionalCharacterShape: nil];
  PASS([[[tv textStorage] attribute: NSCharacterShapeAttributeName
                          atIndex: 0
                   effectiveRange: NULL] intValue] == 0,
    "the second toggle sets the default character shape (0)");

  [tv toggleTraditionalCharacterShape: nil];
  PASS([[[tv textStorage] attribute: NSCharacterShapeAttributeName
                          atIndex: 0
                   effectiveRange: NULL] intValue] == 1,
    "the third toggle sets the traditional character shape again");

  /* The attribute covers the whole selection, not just the first character. */
  PASS([[[tv textStorage] attribute: NSCharacterShapeAttributeName
                          atIndex: 4
                   effectiveRange: NULL] intValue] == 1,
    "the character shape is applied across the selection");

  END_SET("NSTextView character shape")

  DESTROY(arp);
  return 0;
}
