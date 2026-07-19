/* Coverage for the NSFormCell title API: the -init defaults, the title,
   title alignment, title font and title writing-direction accessors, the
   manual and automatic title-width behaviour of -titleWidth and
   -titleWidth:, the mnemonic title, the attributed title and the string /
   attributed placeholder pair.  The title cell touches the font backend,
   so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFormCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSFormCell *cell;

  START_SET("NSFormCell title")

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

  /* Defaults from -init. */
  cell = AUTORELEASE([[NSFormCell alloc] init]);
  pass([[cell title] isEqualToString: @"Field:"], "default title is Field:");
  pass([cell titleAlignment] == NSRightTextAlignment, "title is right aligned by default");
  pass([cell alignment] == NSLeftTextAlignment, "the entry itself is left aligned by default");
  pass([cell isEditable], "a form cell is editable by default");
  pass([cell isBezeled], "a form cell is bezeled by default");
  pass([cell titleBaseWritingDirection] == NSWritingDirectionNatural,
       "title writing direction is natural by default");

  /* Title, alignment, font and writing-direction accessors. */
  [cell setTitle: @"Name:"];
  pass([[cell title] isEqualToString: @"Name:"], "setTitle: updates the title");
  pass([[[cell attributedTitle] string] isEqualToString: @"Name:"],
       "attributedTitle tracks the title string");
  [cell setTitleAlignment: NSLeftTextAlignment];
  pass([cell titleAlignment] == NSLeftTextAlignment, "setTitleAlignment: updates the alignment");
  [cell setTitleFont: [NSFont systemFontOfSize: 24.0]];
  pass([[cell titleFont] pointSize] == 24.0, "setTitleFont: updates the title font");
  [cell setTitleBaseWritingDirection: NSWritingDirectionRightToLeft];
  pass([cell titleBaseWritingDirection] == NSWritingDirectionRightToLeft,
       "setTitleBaseWritingDirection: updates the writing direction");

  /* A manually set title width is reported verbatim and ignores the
     available size passed to -titleWidth:. */
  [cell setTitleWidth: 123.0];
  pass([cell titleWidth] == 123.0, "a manual title width is reported verbatim");
  pass([cell titleWidth: NSMakeSize(500.0, 20.0)] == 123.0,
       "a manual title width ignores the offered size");
  pass([cell titleWidth: NSMakeSize(10.0, 20.0)] == 123.0,
       "a manual title width ignores a small offered size too");

  /* A negative width restores automatic sizing: -titleWidth is then the
     natural width, and -titleWidth: clamps to the offered size. */
  [cell setTitleWidth: -1.0];
  {
    CGFloat natural = [cell titleWidth];
    pass(natural > 0.0, "the automatic title width is positive");
    pass([cell titleWidth: NSMakeSize(1.0, 20.0)] == 1.0,
         "an offered width below the natural width is used as is");
    pass([cell titleWidth: NSMakeSize(natural + 1000.0, 20.0)] == natural,
         "an offered width above the natural width falls back to the natural width");
  }

  /* The mnemonic title strips the ampersand. */
  cell = AUTORELEASE([[NSFormCell alloc] init]);
  [cell setTitleWithMnemonic: @"&File"];
  pass([[cell title] isEqualToString: @"File"], "setTitleWithMnemonic: drops the ampersand");

  /* The placeholder is either a plain string or an attributed string; the
     accessor for the other kind returns nil. */
  cell = AUTORELEASE([[NSFormCell alloc] init]);
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

  END_SET("NSFormCell title")

  DESTROY(arp);
  return 0;
}
