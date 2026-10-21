#import "Testing.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

/* A theme that overrides -[NSActionCell tag]. */
@interface ReproTheme : GSTheme
@end

static int	foundOriginal = 0;

@implementation ReproTheme

/* GSTheme applies introspection to its methods and, when the theme is
 * activated it recognises that this method should be used to override
 * the -[NSActionCell tage] method.
 *
 * When this method is invoked it asks the theme what the original imp
 * was for 'self' (the object on which the method was invoked).
 *
 * This operation should work whether 'self' belongs to the class whose
 * method was overridden, *or* to a subclass of that class. 
 */
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
    GSTheme		*theme;

fprintf(stderr, "about to call sharedApplication\n");    
    [NSApplication sharedApplication];
fprintf(stderr, "about to create theme\n");    
    theme = [[ReproTheme alloc] initWithBundle: nil];
fprintf(stderr, "about to install theme\n");    
    [GSTheme setTheme: theme];

fprintf(stderr, "about to test overrides\n");    
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
