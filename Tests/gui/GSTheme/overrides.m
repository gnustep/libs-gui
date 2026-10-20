#import "Testing.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

/* A theme that overrides -[NSActionCell tag]. */
@interface ReproTheme : GSTheme
@end

static int	foundOriginal = 0;

@implementation ReproTheme
- (NSInteger) _overrideNSActionCellMethod_tag
{
  typedef NSInteger (*TagIMP)(id, SEL);
  TagIMP original = (TagIMP)[[GSTheme theme] overriddenMethod: _cmd for: self];

  if (original)
    {
      foundOriginal++;
    }
  return original ? original(self, _cmd) : -1;
}
@end

/* A subclass that inherits -tag unchanged. */
@interface MyCell : NSActionCell
@end
@implementation MyCell
@end

int main(int argc, const char *argv[])
{
  ENTER_POOL
    NSActionCell	*base;
    MyCell 		*sub;

    [NSApplication sharedApplication];
    [GSTheme setTheme: [[ReproTheme alloc] initWithBundle: nil]];

    base = AUTORELEASE([NSActionCell new]);
    [base tag];
    sub = AUTORELEASE([MyCell new]);
    [sub tag];

    PASS(foundOriginal == 2, "subclass found original of overridden method")

  LEAVE_POOL
  return 0;
}
