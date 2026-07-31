/* GSHorizontalTypesetter lays out a run that is much longer than the initial
   glyph cache, so the cache grows several times while laying it out.  This
   exercises that growth and checks that every glyph is still laid out and the
   run flows onto multiple lines.  The typesetter uses the font backend, so the
   set is skipped when the backend is unavailable.
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
#include <AppKit/NSStringDrawing.h>

int
main(int argc, char **argv)
{
  START_SET("GSHorizontalTypesetter longRun")

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
      const NSUInteger length = 3000;
      NSFont *font = [NSFont userFontOfSize: 12.0];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName, nil];
      NSString *s = [@"" stringByPaddingToLength: length
                                      withString: @"a b c d "
                                 startingAtIndex: 0];
      NSTextStorage *ts = AUTORELEASE([[NSTextStorage alloc]
        initWithString: s attributes: attrs]);
      NSLayoutManager *lm = AUTORELEASE([[NSLayoutManager alloc] init]);
      [ts addLayoutManager: lm];
      NSTextContainer *tc = AUTORELEASE([[NSTextContainer alloc]
        initWithContainerSize: NSMakeSize(300, 1.0e6)]);
      [tc setLineFragmentPadding: 0.0];
      [lm addTextContainer: tc];

      NSRange gr = [lm glyphRangeForTextContainer: tc];

      PASS([lm numberOfGlyphs] == length,
           "every glyph of a long run is generated");
      PASS(gr.location == 0 && gr.length == length,
           "the whole long run is laid out in the container");

      NSRange first, last;
      NSRect firstFrag = [lm lineFragmentRectForGlyphAtIndex: 0
                                             effectiveRange: &first];
      NSRect lastFrag = [lm lineFragmentRectForGlyphAtIndex: length - 1
                                            effectiveRange: &last];
      PASS(NSMinY(lastFrag) > NSMinY(firstFrag),
           "the run wraps onto later lines below the first");
      PASS(last.location + last.length == length,
           "the last line fragment reaches the end of the run");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available");
    }
  NS_ENDHANDLER

  END_SET("GSHorizontalTypesetter longRun")

  return 0;
}
