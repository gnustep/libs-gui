/* The text colour of a highlighted ("overed") menu item can be set by the
   theme through the "NSMenuItemText" named colour, the same way the highlight
   background is set through "NSMenuItem" (gnustep/libs-gui#222).  When the
   theme provides no such colour the default stays [NSColor
   selectedMenuItemTextColor], and the hook only applies while the item is
   highlighted and enabled. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenuItemCell.h>
#import <GNUstepGUI/GSTheme.h>

/* A theme that paints the highlighted item's text red. */
@interface RedTextTheme : GSTheme
@end
@implementation RedTextTheme
- (NSString *) name
{
  return @"RedTextTheme";
}
- (NSColor *) colorNamed: (NSString *)aName state: (GSThemeControlState)state
{
  if ([aName isEqualToString: @"NSMenuItemText"])
    return [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0];
  return [super colorNamed: aName state: state];
}
@end

static BOOL
isRed(NSColor *c)
{
  c = [c colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  return [c redComponent] > 0.7 && [c greenComponent] < 0.3
    && [c blueComponent] < 0.3;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuItemCell text colour")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSMenuItemCell *cell = AUTORELEASE([[NSMenuItemCell alloc] init]);
  [cell setEnabled: YES];
  [cell setHighlightsBy: NSPushInCellMask];

  /* With no override the highlighted text colour is the default one. */
  [cell setHighlighted: YES];
  PASS([[cell textColor] isEqual: [NSColor selectedMenuItemTextColor]],
       "a highlighted item uses selectedMenuItemTextColor by default");

  GSTheme *saved = RETAIN([GSTheme theme]);
  [GSTheme setTheme: AUTORELEASE([[RedTextTheme alloc] initWithBundle: nil])];

  /* The theme's NSMenuItemText colour now drives the highlighted text. */
  [cell setHighlighted: YES];
  PASS(isRed([cell textColor]),
       "a highlighted item takes its text colour from the theme");

  /* The hook only applies while highlighted; a normal item is unaffected. */
  [cell setHighlighted: NO];
  PASS(!isRed([cell textColor]),
       "a non-highlighted item ignores the NSMenuItemText colour");

  [GSTheme setTheme: saved];
  RELEASE(saved);

  END_SET("NSMenuItemCell text colour")

  DESTROY(arp);
  return 0;
}
