/* Coverage for NSTextView: the text network wired up by initWithFrame:
   (text container, layout manager and text storage, cross-linked), the
   defaults of a new text view (rich text, editable, selectable, not a field
   editor, draws its background, no undo, smart insert/delete, no continuous
   spell checking, uses the ruler, a non-nil insertion point colour, a zero
   text container inset), and the round-trips of the undo, smart-insert,
   continuous-spell-checking, ruler, accepts-glyph-info flags and the text
   container inset.  Every assertion here matches AppKit (verified on a macOS
   runner) and passes on unmodified GNUstep.  NSTextView is a view, so the test
   is guarded on the backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextView *tv;
  NSSize inset;

  START_SET("NSTextView config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  tv = AUTORELEASE([[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);

  PASS([tv textContainer] != nil, "a new text view has a text container");
  PASS([tv layoutManager] != nil, "a new text view has a layout manager");
  PASS([tv textStorage] != nil, "a new text view has a text storage");
  PASS([[tv textContainer] layoutManager] == [tv layoutManager],
       "the text container points at the layout manager");
  PASS([[tv layoutManager] textStorage] == [tv textStorage],
       "the layout manager points at the text storage");

  PASS([tv isRichText] == YES, "default isRichText is YES");
  PASS([tv isEditable] == YES, "default isEditable is YES");
  PASS([tv isSelectable] == YES, "default isSelectable is YES");
  PASS([tv isFieldEditor] == NO, "default isFieldEditor is NO");
  PASS([tv drawsBackground] == YES, "default drawsBackground is YES");
  PASS([tv allowsUndo] == NO, "default allowsUndo is NO");
  PASS([tv smartInsertDeleteEnabled] == YES,
       "default smartInsertDeleteEnabled is YES");
  PASS([tv isContinuousSpellCheckingEnabled] == NO,
       "default continuous spell checking is off");
  PASS([tv usesRuler] == YES, "default usesRuler is YES");
  PASS([tv insertionPointColor] != nil, "there is an insertion point colour");
  inset = [tv textContainerInset];
  PASS(inset.width == 0 && inset.height == 0,
       "default text container inset is zero");

  [tv setAllowsUndo: YES];
  PASS([tv allowsUndo] == YES, "allowsUndo round-trips");
  [tv setSmartInsertDeleteEnabled: NO];
  PASS([tv smartInsertDeleteEnabled] == NO,
       "smartInsertDeleteEnabled round-trips");
  [tv setContinuousSpellCheckingEnabled: YES];
  PASS([tv isContinuousSpellCheckingEnabled] == YES,
       "continuousSpellCheckingEnabled round-trips");
  [tv setUsesRuler: NO];
  PASS([tv usesRuler] == NO, "usesRuler round-trips");
  [tv setAcceptsGlyphInfo: YES];
  PASS([tv acceptsGlyphInfo] == YES, "acceptsGlyphInfo round-trips");
  [tv setTextContainerInset: NSMakeSize(5, 7)];
  inset = [tv textContainerInset];
  PASS(inset.width == 5 && inset.height == 7,
       "textContainerInset round-trips");

  END_SET("NSTextView config")

  DESTROY(arp);
  return 0;
}
