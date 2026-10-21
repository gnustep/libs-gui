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
  // Use the original implementation if we have it, otherwise return -1
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
    [base setTag: 1];
    PASS([base tag] == 1, "base class returns the tag we set")
    PASS(foundOriginal == 1, "base class executed override method")
  
    sub = AUTORELEASE([MyCell new]);
    [sub setTag: 2];
    PASS([sub tag] == 2, "sub class returns the tag we set")
    PASS(foundOriginal == 2, "subclass executed override method")

  LEAVE_POOL
  return 0;
}
