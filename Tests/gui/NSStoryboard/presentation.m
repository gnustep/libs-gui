#import "Testing.h"
#import <AppKit/AppKit.h>
#import "../../../Source/GSStoryboardArchive.h"

static NSUInteger destroyedControllers;
@interface PresentationController : NSViewController
@end
@implementation PresentationController
- (void) dealloc
{
  destroyedControllers++;
  [super dealloc];
}

@end

int main(void)
{
  NSAutoreleasePool *outer = [NSAutoreleasePool new];
  NSUInteger i;

  START_SET("NSStoryboard show presentation lifetime")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER;

  for (i = 0; i < 3; i++)
    {
      NSAutoreleasePool *creation = [NSAutoreleasePool new];
      PresentationController *controller = [PresentationController new];
      NSView *view = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)];
      NSStoryboardSegue *segue = [[NSStoryboardSegue alloc]
        initWithIdentifier: @"show" source: nil destination: controller];
      NSWindow *window;
      [controller setView: view];
      [view release];
      [segue _setKind: @"show"];
      [segue perform];
      window = [[controller view] window];
      [segue release];
      [controller release];
      [creation drain];
      PASS(destroyedControllers == i,
        "the presentation retains its controller after the segue is gone");
      NSAutoreleasePool *closing = [NSAutoreleasePool new];
      [window close];
      [closing drain];
      PASS(destroyedControllers == i + 1,
        "closing releases the presentation controller without over-releasing its window");
    }
  END_SET("NSStoryboard show presentation lifetime")
  [outer drain];
  return 0;
}
