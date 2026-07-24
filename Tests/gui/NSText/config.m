/* Coverage for NSText: the defaults of a freshly created text object (empty
   string, editable and selectable, rich text, not a field editor, no imported
   graphics, draws its background, uses the font panel, natural alignment, not
   horizontally but vertically resizable, no delegate, empty selection) and the
   round-trips of the editable/selectable/field-editor/draws-background/imports-
   graphics flags, the alignment (compared by symbol, since the NSTextAlignment
   values differ between implementations), the string and the delegate.  Every
   assertion here matches AppKit (verified on a macOS runner) and passes on
   unmodified GNUstep.  NSText is a view, so the whole test is guarded on the
   backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSText.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSText *t;
  id delegate;

  START_SET("NSText config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  t = AUTORELEASE([[NSText alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 100)]);

  PASS([[t string] isEqual: @""], "a new text object has an empty string");
  PASS([t isEditable] == YES, "default isEditable is YES");
  PASS([t isSelectable] == YES, "default isSelectable is YES");
  PASS([t isRichText] == YES, "default isRichText is YES");
  PASS([t isFieldEditor] == NO, "default isFieldEditor is NO");
  PASS([t importsGraphics] == NO, "default importsGraphics is NO");
  PASS([t drawsBackground] == YES, "default drawsBackground is YES");
  PASS([t usesFontPanel] == YES, "default usesFontPanel is YES");
  PASS([t alignment] == NSNaturalTextAlignment, "default alignment is natural");
  PASS([t isHorizontallyResizable] == NO,
       "default isHorizontallyResizable is NO");
  PASS([t isVerticallyResizable] == YES,
       "default isVerticallyResizable is YES");
  PASS([t delegate] == nil, "default delegate is nil");
  PASS([t selectedRange].location == 0 && [t selectedRange].length == 0,
       "default selected range is empty");

  [t setEditable: NO];
  PASS([t isEditable] == NO, "isEditable round-trips");
  [t setSelectable: NO];
  PASS([t isSelectable] == NO, "isSelectable round-trips");
  [t setFieldEditor: YES];
  PASS([t isFieldEditor] == YES, "isFieldEditor round-trips");
  [t setDrawsBackground: NO];
  PASS([t drawsBackground] == NO, "drawsBackground round-trips");
  [t setImportsGraphics: YES];
  PASS([t importsGraphics] == YES, "importsGraphics round-trips");
  [t setAlignment: NSRightTextAlignment];
  PASS([t alignment] == NSRightTextAlignment, "alignment round-trips");
  [t setString: @"hello world"];
  PASS([[t string] isEqual: @"hello world"], "string round-trips");
  [t setHorizontallyResizable: YES];
  PASS([t isHorizontallyResizable] == YES, "isHorizontallyResizable round-trips");

  delegate = AUTORELEASE([[NSObject alloc] init]);
  [t setDelegate: delegate];
  PASS([t delegate] == delegate, "delegate round-trips");

  END_SET("NSText config")

  DESTROY(arp);
  return 0;
}
