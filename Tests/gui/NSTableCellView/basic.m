/* Coverage for NSTableCellView: the init defaults, the background style and
 * row size style enumerations, and the setter round-trips for the object
 * value, the text field, the image view and the two styles.  Every assertion
 * here matches AppKit (verified on a macOS runner) and passes on unmodified
 * GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSTableCellView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextField.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTableCellView basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTableCellView	*view;
    NSTextField		*textField;
    NSImageView		*imageView;
    NSString		*objectValue = @"value";

    /* the enumerations */
    PASS(NSTableViewRowSizeStyleDefault == -1
      && NSTableViewRowSizeStyleCustom == 0
      && NSTableViewRowSizeStyleSmall == 1
      && NSTableViewRowSizeStyleMedium == 2
      && NSTableViewRowSizeStyleLarge == 3,
      "the row size styles have their AppKit values");
    PASS(NSBackgroundStyleNormal == 0 && NSBackgroundStyleEmphasized == 1
      && NSBackgroundStyleRaised == 2 && NSBackgroundStyleLowered == 3,
      "the background styles have their AppKit values");

    /* init defaults */
    view = AUTORELEASE([[NSTableCellView alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)]);
    PASS(view != nil, "a table cell view is created");
    PASS([view objectValue] == nil, "a new cell view has no object value");
    PASS([view textField] == nil, "a new cell view has no text field");
    PASS([view imageView] == nil, "a new cell view has no image view");
    PASS([view backgroundStyle] == NSBackgroundStyleNormal,
      "a new cell view has the normal background style");

    /* setter round-trips */
    textField = AUTORELEASE([[NSTextField alloc]
      initWithFrame: NSMakeRect(0, 0, 50, 20)]);
    imageView = AUTORELEASE([[NSImageView alloc]
      initWithFrame: NSMakeRect(0, 0, 20, 20)]);

    [view setObjectValue: objectValue];
    [view setTextField: textField];
    [view setImageView: imageView];
    [view setRowSizeStyle: NSTableViewRowSizeStyleMedium];
    [view setBackgroundStyle: NSBackgroundStyleEmphasized];

    PASS([view objectValue] == objectValue, "the object value reads back");
    PASS([view textField] == textField, "the text field reads back");
    PASS([view imageView] == imageView, "the image view reads back");
    PASS([view rowSizeStyle] == NSTableViewRowSizeStyleMedium,
      "the row size style round-trips");
    PASS([view backgroundStyle] == NSBackgroundStyleEmphasized,
      "the background style round-trips");
  }

  END_SET("NSTableCellView basic")

  DESTROY(arp);
  return 0;
}
