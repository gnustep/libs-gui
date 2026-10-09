#import "Testing.h"
#import <AppKit/AppKit.h>
#import "../../../Source/GSStoryboardArchive.h"

@interface NSStoryboard (TestApplication)
- (void) _instantiateApplicationScene;
@end
@interface NSCoder (TestResources)
- (id) findResourceWithName: (NSString *)name;
@end

static NSUInteger controllerDeaths;
static NSUInteger delegateAwakes;
static NSUInteger windowControllerDeaths;
@interface StructureView : NSView
@end
@implementation StructureView
@end
@interface StructureViewController : NSViewController
{
@public
  BOOL resourceFound;
  NSUInteger awakes;
}
@end
@implementation StructureViewController

- (id) initWithCoder: (NSCoder *)coder
{
  if ((self = [super initWithCoder: coder]) != nil)
    resourceFound = [coder findResourceWithName: @"StoryboardTestResource"] != nil;
  return self;
}

- (void) awakeFromNib { awakes++; }

- (void) dealloc { controllerDeaths++; [super dealloc]; }
@end
@interface StructureNamedController : StructureViewController
@end
@implementation StructureNamedController
@end
@interface StructureWindowController : NSWindowController
{
@public
  BOOL ready;
  NSUInteger shows;
}
@end
@implementation StructureWindowController

- (void) showWindow: (id)sender { shows++; }

- (void) dealloc { windowControllerDeaths++; [super dealloc]; }

- (void) awakeFromNib
{
  ready = [[[self window] contentView] isKindOfClass: [StructureView class]]
    && [[self window] delegate] == self
    && [self valueForKey: @"storyboard"] != nil;
}
@end
@interface StructureDelegate : NSObject
@end
@implementation StructureDelegate

- (void) awakeFromNib { delegateAwakes++; }
@end

int main(void)
{
  START_SET("NSStoryboard relationships and references")
  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqual: NSInternalInconsistencyException]
          || [[localException name] isEqual: @"NSWindowServerCommunicationException"])
        {
          SKIP("No GUI backend or display available")
        }
      else
        [localException raise];
    }
  NS_ENDHANDLER

  NSString *path = [[[NSFileManager defaultManager] currentDirectoryPath]
    stringByAppendingPathComponent: @"Fixtures.bundle"];
  NSBundle *bundle = [NSBundle bundleWithPath: path];
  NSStoryboard *storyboard = [NSStoryboard storyboardWithName: @"Main" bundle: bundle];
  PASS(storyboard != nil, "storyboards load through the public bundle API");
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSUInteger deaths = controllerDeaths;
  StructureWindowController *window = RETAIN([storyboard instantiateInitialController]);
  PASS(window->ready && window->shows == 1, "window outlets and content relationship are installed before awakening");
  NSWindow *firstWindow = RETAIN([window window]);
  StructureView *view = (StructureView *)[firstWindow contentView];
  [pool drain];
  PASS(controllerDeaths == deaths && [firstWindow contentView] == view,
       "a window relationship keeps its content controller alive after the loading pool drains");
  StructureWindowController *another = [storyboard instantiateControllerWithIdentifier: @"Window"];
  PASS([another window] != firstWindow && [[another window] contentView] != view,
       "repeated window scene loads do not share windows or content");
  RELEASE(window);
  PASS(controllerDeaths == deaths + 1, "releasing the window controller releases its relationship destination");
  RELEASE(firstWindow);
  StructureViewController *content = [storyboard instantiateControllerWithIdentifier: @"Content"];
  PASS(content->resourceFound, "document-level resources are available while decoding a scene");
  NSArray *objects = [content valueForKey: @"topLevelObjects"];
  NSMenu *menu = nil;
  for (id object in objects)
    if ([object isKindOfClass: [NSMenu class]]) menu = object;
  PASS(menu != nil && [[menu itemAtIndex: 0] target] == nil,
       "each scene's first-responder ID resolves to a responder-chain action");
  StructureViewController *named = [storyboard instantiateControllerWithIdentifier: @"Reference"];
  PASS([named isKindOfClass: [StructureNamedController class]] && named->awakes == 1,
       "references resolve a named controller in the originating bundle and awaken it once");
  PASS([named valueForKey: @"storyboard"] != storyboard,
       "a referenced controller keeps its own storyboard context");
  StructureViewController *initial = [storyboard instantiateControllerWithIdentifier: @"InitialReference"];
  PASS([initial class] == [StructureViewController class] && initial->awakes == 1,
       "references without an identifier instantiate the referenced initial controller");
  NSSplitViewController *split = [storyboard instantiateControllerWithIdentifier: @"Split"];
  PASS([[split splitViewItems] count] == 2 && [[[split splitView] subviews] count] == 2,
       "split relationships create and attach independent split items");
  NSTabViewController *tabs = [storyboard instantiateControllerWithIdentifier: @"Tabs"];
  PASS([[tabs tabViewItems] count] == 2, "tab relationships attach their controllers");
  id oldDelegate = [NSApp delegate];
  NSMenu *oldMenu = RETAIN([NSApp mainMenu]);
  [storyboard _instantiateApplicationScene];
  PASS([[NSApp delegate] isKindOfClass: [StructureDelegate class]] && delegateAwakes == 1,
       "the application scene binds outlets to NSApp and awakens its delegate");
  PASS([NSApp mainMenu] != oldMenu && [[[NSApp mainMenu] itemAtIndex: 0] target] == nil,
       "the application menu retains responder-chain actions");
  [NSApp setDelegate: oldDelegate];
  [NSApp setMainMenu: oldMenu];
  RELEASE(oldMenu);
  NSStoryboard *cycle = [NSStoryboard storyboardWithName: @"CycleA" bundle: bundle];
  PASS_EXCEPTION([cycle instantiateInitialController], NSInvalidUnarchiveOperationException,
    "cyclic storyboard references fail without recursing indefinitely");
  NSStoryboard *relationshipCycle = [NSStoryboard storyboardWithName: @"RelationshipCycle" bundle: bundle];
  PASS_EXCEPTION([relationshipCycle instantiateInitialController], NSInvalidUnarchiveOperationException,
    "cyclic relationships fail without recursing indefinitely");
  PASS([storyboard instantiateControllerWithIdentifier: @"Content"] != nil,
       "failed loads do not poison subsequent scene instantiation");
#if __has_feature(blocks)
  __block BOOL referenceCreatorCalled = NO;
  StructureViewController *createdReference = [storyboard instantiateControllerWithIdentifier: @"Reference"
    creator: ^id(NSCoder *coder) {
      referenceCreatorCalled = YES;
      return AUTORELEASE([[StructureNamedController alloc] initWithCoder: coder]);
    }];
  PASS(referenceCreatorCalled && createdReference->awakes == 1,
       "creator blocks are forwarded through storyboard references");
#endif
  PASS_EXCEPTION([NSStoryboard storyboardWithName: @"Missing" bundle: bundle],
    NSInvalidArgumentException, "missing storyboard resources raise a clear exception");
  pool = [NSAutoreleasePool new];
  NSUInteger windowDeaths = windowControllerDeaths;
  StructureWindowController *presented = [storyboard instantiateControllerWithIdentifier: @"Window"];
  NSWindow *presentedWindow = RETAIN([presented window]);
  NSStoryboardSegue *show = AUTORELEASE([[NSStoryboardSegue alloc]
    initWithIdentifier: @"show" source: nil destination: presented]);
  [show _setKind: @"show"];
  [show perform];
  [pool drain];
  PASS(windowControllerDeaths == windowDeaths && [presentedWindow windowController] != nil,
       "shown controllers outlive their temporary segue and autorelease pool");
  pool = [NSAutoreleasePool new];
  [presentedWindow close];
  [pool drain];
  PASS(windowControllerDeaths == windowDeaths + 1,
       "closing a presented window releases its controller");
  RELEASE(presentedWindow);
  END_SET("NSStoryboard relationships and references")
  return 0;
}
