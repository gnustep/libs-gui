#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSView.h>

@interface NSView (GSToolbarCustomizationView)
- (NSArray *) paletteItemsWithToolbarItems: (NSArray *)items;
@end

int
main(int argc, char **argv)
{
  START_SET("NSToolbarItem label in the customization palette")

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

  {
    Class viewClass = NSClassFromString(@"GSToolbarCustomizationView");
    NSView *view = AUTORELEASE([[viewClass alloc]
      initWithFrame: NSMakeRect(0, 0, 400, 100)]);
    NSToolbarItem *plain = AUTORELEASE([[NSToolbarItem alloc]
      initWithItemIdentifier: @"plain"]);
    NSToolbarItem *named = AUTORELEASE([[NSToolbarItem alloc]
      initWithItemIdentifier: @"named"]);
    NSArray *paletteItems;

    [plain setLabel: @"Label"];
    [named setLabel: @"Label"];
    [named setPaletteLabel: @"Palette Label"];
    paletteItems = [view paletteItemsWithToolbarItems:
      [NSArray arrayWithObjects: plain, named, nil]];
    printf("palette labels: \"%s\", \"%s\"\n",
      [[[paletteItems objectAtIndex: 0] label] UTF8String],
      [[[paletteItems objectAtIndex: 1] label] UTF8String]);
    PASS_EQUAL([[paletteItems objectAtIndex: 0] label], @"Label",
      "an item without a palette label keeps its label in the palette");
    PASS_EQUAL([[paletteItems objectAtIndex: 1] label], @"Palette Label",
      "an item with a palette label shows it in the palette");
  }

  END_SET("NSToolbarItem label in the customization palette")

  return 0;
}
