/* GSHorizontalTypesetter applies a paragraph's paragraphSpacing as vertical
   space after the paragraph: the line fragment that begins the following
   paragraph is pushed down by that amount.  This is checked by laying out two
   paragraphs and comparing the second paragraph's y origin with and without
   the spacing.  It used to be ignored.  The typesetter uses the font backend,
   so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDictionary.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSStringDrawing.h>

/* Lays out two paragraphs with the given paragraph spacing and returns the
   y origin of the line fragment that starts the second paragraph. */
static CGFloat
secondParagraphY(CGFloat spacing)
{
  NSFont *font = [NSFont userFontOfSize: 12.0];
  NSMutableParagraphStyle *ps = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  [ps setParagraphSpacing: spacing];
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    font, NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];

  NSTextStorage *ts = AUTORELEASE([[NSTextStorage alloc]
    initWithString: @"aaa\nbbb" attributes: attrs]);
  NSLayoutManager *lm = AUTORELEASE([[NSLayoutManager alloc] init]);
  [ts addLayoutManager: lm];
  NSTextContainer *tc = AUTORELEASE([[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(200, 1000)]);
  [tc setLineFragmentPadding: 0.0];
  [lm addTextContainer: tc];
  [lm glyphRangeForTextContainer: tc];

  /* Glyph 5 is in the second paragraph ("bbb" after the newline at index 3). */
  NSRange r;
  NSRect frag = [lm lineFragmentRectForGlyphAtIndex: 5 effectiveRange: &r];
  return frag.origin.y;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("GSHorizontalTypesetter paragraphSpacing")

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
      CGFloat none = secondParagraphY(0.0);
      CGFloat spaced = secondParagraphY(20.0);

      pass(none > 0.0,
           "the second paragraph is below the first without extra spacing");
      pass(spaced - none == 20.0,
           "paragraphSpacing pushes the next paragraph down by that amount");
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

  END_SET("GSHorizontalTypesetter paragraphSpacing")

  DESTROY(arp);
  return 0;
}
