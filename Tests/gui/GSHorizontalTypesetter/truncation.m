/* GSHorizontalTypesetter implements NSLineBreakByTruncatingTail: text that does
   not fit the line is laid out on a single line fragment with the trailing
   glyphs hidden and an ellipsis truncation glyph set on the fragment, rather
   than being clipped with no indicator.  A non-truncating line break mode sets
   no truncation glyph.  The typesetter uses the font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSStringDrawing.h>

@interface NSFont (TruncationTest)
- (NSGlyph) _defaultGlyphForChar: (unichar)theChar;
@end

/* Lays out a 20-glyph run in a narrow one-line container with the given line
   break mode and returns the layout manager. */
static NSLayoutManager *
layoutWithBreakMode(NSLineBreakMode mode)
{
  NSFont *font = [NSFont userFontOfSize: 12.0];
  NSMutableParagraphStyle *ps = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  [ps setLineBreakMode: mode];
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
    font, NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];
  NSTextStorage *ts = AUTORELEASE([[NSTextStorage alloc]
    initWithString: @"aaaaaaaaaaaaaaaaaaaa" attributes: attrs]);
  NSLayoutManager *lm = AUTORELEASE([[NSLayoutManager alloc] init]);
  [ts addLayoutManager: lm];
  NSTextContainer *tc = AUTORELEASE([[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(50, 1000)]);
  [tc setLineFragmentPadding: 0.0];
  [lm addTextContainer: tc];
  [lm glyphRangeForTextContainer: tc];
  return lm;
}

int
main(int argc, char **argv)
{
  START_SET("GSHorizontalTypesetter truncation")

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
      NSFont *font = [NSFont userFontOfSize: 12.0];
      NSGlyph ellipsis = [font _defaultGlyphForChar: 0x2026];
      NSLayoutManager *lm;
      NSRange r;

      lm = layoutWithBreakMode(NSLineBreakByTruncatingTail);

      PASS([lm numberOfGlyphs] == 20, "all glyphs are generated");

      [lm lineFragmentRectForGlyphAtIndex: 0 effectiveRange: &r];
      PASS(r.location == 0 && r.length == 20,
           "truncating tail keeps the whole run in one line fragment");

      PASS([lm notShownAttributeForGlyphAtIndex: 0] == NO,
           "the first glyph of a truncated line is shown");
      PASS([lm notShownAttributeForGlyphAtIndex: 19] == YES,
           "the trailing glyphs of a truncated line are hidden");

      PASS(ellipsis != NSNullGlyph, "the font provides an ellipsis glyph");
      PASS([lm truncationGlyphForGlyphAtIndex: 0] == ellipsis,
           "an ellipsis truncation glyph is set on the truncated line");

      lm = layoutWithBreakMode(NSLineBreakByWordWrapping);
      PASS([lm truncationGlyphForGlyphAtIndex: 0] == NSNullGlyph,
           "a wrapping line has no truncation glyph");

      /* Head: the leading glyphs are hidden and the trailing ones shown. */
      lm = layoutWithBreakMode(NSLineBreakByTruncatingHead);
      PASS([lm notShownAttributeForGlyphAtIndex: 0] == YES,
           "truncating head hides the leading glyphs");
      PASS([lm notShownAttributeForGlyphAtIndex: 19] == NO,
           "truncating head shows the trailing glyphs");
      PASS([lm truncationGlyphForGlyphAtIndex: 0] == ellipsis,
           "truncating head sets an ellipsis");

      /* Middle: the first and last glyphs are shown, the middle hidden. */
      lm = layoutWithBreakMode(NSLineBreakByTruncatingMiddle);
      PASS([lm notShownAttributeForGlyphAtIndex: 0] == NO,
           "truncating middle shows the leading glyphs");
      PASS([lm notShownAttributeForGlyphAtIndex: 19] == NO,
           "truncating middle shows the trailing glyphs");
      PASS([lm notShownAttributeForGlyphAtIndex: 10] == YES,
           "truncating middle hides the middle glyphs");
      PASS([lm truncationGlyphForGlyphAtIndex: 0] == ellipsis,
           "truncating middle sets an ellipsis");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available");
    }
  NS_ENDHANDLER

  END_SET("GSHorizontalTypesetter truncation")

  return 0;
}
