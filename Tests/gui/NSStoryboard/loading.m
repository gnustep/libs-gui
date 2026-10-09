#import "Testing.h"
#import <AppKit/AppKit.h>
#import "../../../Source/GSStoryboardArchive.h"

static NSUInteger destroyedControllers;
static NSStoryboardSegue *performedSegue;
static id preparedSender;
static id checkedSender;

@interface StoryboardTrigger : NSObject
{
  id _target;
  SEL _action;
}
- (void) setTarget: (id)target;
- (void) setAction: (SEL)action;
- (void) fire;
@end
@implementation StoryboardTrigger

- (void) setTarget: (id)target { _target = target; }

- (void) setAction: (SEL)action { _action = action; }

- (void) fire { [_target performSelector: _action withObject: self]; }
@end

@interface StoryboardProbe : NSViewController
{
@public
  StoryboardTrigger *trigger;
  NSUInteger awakeCount;
  BOOL ready;
  BOOL veto;
  BOOL created;
}
@end
@implementation StoryboardProbe

- (void) awakeFromNib
{
  awakeCount++;
  ready = [self valueForKey: @"storyboard"] != nil && [self valueForKey: @"segueMap"] != nil && trigger != nil;
}

- (BOOL) shouldPerformSegueWithIdentifier: (NSString *)identifier sender: (id)sender
{
  checkedSender = sender;
  return !veto;
}

- (void) prepareForSegue: (NSStoryboardSegue *)segue sender: (id)sender
{
  preparedSender = sender;
}

- (void) dealloc
{
  destroyedControllers++;
  [super dealloc];
}
@end

@interface StoryboardTestSegue : NSStoryboardSegue
@end
@implementation StoryboardTestSegue

- (void) perform { ASSIGN(performedSegue, self); }
@end

@interface MemoryStoryboard : NSStoryboard
- (id) initWithXML: (NSString *)xml;
@end
@implementation MemoryStoryboard

- (id) initWithXML: (NSString *)xml
{
  if ((self = [super init]) != nil)
    _transform = [[GSStoryboardArchive alloc]
      initWithData: [xml dataUsingEncoding: NSUTF8StringEncoding]
      bundle: [NSBundle mainBundle]];
  return self;
}
@end

static NSString *xml =
@"<document initialViewController='source'><scenes>"
 "<scene sceneID='scene1'><objects>"
 "<viewController id='source' storyboardIdentifier='Main' customClass='StoryboardProbe' sceneMemberID='viewController'>"
 "<view key='view' id='view1'><rect key='frame' x='0' y='0' width='100' height='100'/></view>"
 "<connections><outlet property='trigger' destination='trigger1' id='outlet1'/>"
 "<segue destination='destination' kind='custom' identifier='programmatic' customClass='StoryboardTestSegue' id='segue1'/>"
 "<segue destination='destination' kind='popover' identifier='popover' customClass='StoryboardTestSegue' id='segue3' popoverAnchorView='view1' preferredEdge='maxY' popoverBehavior='t'/>"
 "</connections></viewController>"
 "<customObject id='trigger1' customClass='StoryboardTrigger'><connections>"
 "<segue destination='destination' kind='custom' identifier='clicked' customClass='StoryboardTestSegue' id='segue2'/>"
 "</connections></customObject>"
 "<customObject id='responder1' customClass='FirstResponder' sceneMemberID='firstResponder'/>"
 "</objects></scene>"
 "<scene sceneID='scene2'><objects>"
 "<viewController id='destination' storyboardIdentifier='Other' customClass='StoryboardProbe' sceneMemberID='viewController'>"
 "<view key='view' id='view2'><rect key='frame' x='0' y='0' width='50' height='50'/></view>"
 "</viewController>"
 "<customObject id='responder2' customClass='FirstResponder' sceneMemberID='firstResponder'/>"
 "</objects></scene></scenes></document>";

int main(void)
{
  START_SET("NSStoryboard direct scene loading")
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

  MemoryStoryboard *storyboard = AUTORELEASE([[MemoryStoryboard alloc] initWithXML: xml]);
  StoryboardProbe *first = [storyboard instantiateInitialController];
  StoryboardProbe *second = [storyboard instantiateControllerWithIdentifier: @"Main"];
  PASS(first != second && [first view] != [second view], "each instantiation has independent controllers and views");
  PASS(first->trigger != second->trigger, "top-level objects belong to their own scene instance");
  PASS(first->awakeCount == 1 && first->ready, "outlets and storyboard context exist before awakeFromNib");
  PASS(second->awakeCount == 1 && second->ready, "repeated instantiation awakens the new instance exactly once");
  PASS([storyboard instantiateControllerWithIdentifier: @"source"] != nil, "legacy XML controller identifiers remain accepted");
  [first performSegueWithIdentifier: @"programmatic" sender: second];
  PASS([performedSegue sourceController] == first && preparedSender == second, "programmatic segues resolve their source and preserve sender");
  id oldDestination = RETAIN([performedSegue destinationController]);
  [second performSegueWithIdentifier: @"programmatic" sender: first];
  PASS([performedSegue sourceController] == second && [performedSegue destinationController] != oldDestination, "segue destinations are fresh across scene instances");
  RELEASE(oldDestination);
  [first->trigger fire];
  PASS([performedSegue sourceController] == first && preparedSender == first->trigger
       && checkedSender == first->trigger, "control segues preserve the actual sender through veto and preparation");
  NSStoryboardSegue *previous = RETAIN(performedSegue);
  first->veto = YES;
  [first->trigger fire];
  PASS(performedSegue == previous, "a vetoed control segue is not performed");
  RELEASE(previous);
  DESTROY(performedSegue);
  [first performSegueWithIdentifier: @"popover" sender: first->trigger];
  PASS([performedSegue valueForKey: @"popoverAnchorView"] == [first view]
    && [[performedSegue valueForKey: @"popoverBehavior"] integerValue] == NSPopoverBehaviorTransient
    && [[performedSegue valueForKey: @"preferredEdge"] integerValue] == NSMaxYEdge,
    "popover segues resolve the instance's anchor and retain their metadata");
  DESTROY(performedSegue);
#if __has_feature(blocks)
  __block NSUInteger calls = 0;
  StoryboardProbe *custom = [storyboard instantiateControllerWithIdentifier: @"Main"
    creator: ^id(NSCoder *coder) {
      calls++;
      StoryboardProbe *controller = AUTORELEASE([[StoryboardProbe alloc] initWithCoder: coder]);
      controller->created = YES;
      return controller;
    }];
  PASS(calls == 1 && custom->created && custom->ready && custom->awakeCount == 1,
       "creator receives a coder and its returned controller is connected and awakened");
  StoryboardProbe *fallback = [storyboard instantiateInitialControllerWithCreator: ^id(NSCoder *coder) {
    return nil;
  }];
  PASS(fallback->ready, "nil creator result falls back to normal decoding");
#endif
  PASS_EXCEPTION([storyboard instantiateControllerWithIdentifier: @"missing"],
    NSInvalidArgumentException, "unknown identifiers raise an exception");
  PASS_EXCEPTION([storyboard instantiateControllerWithIdentifier: nil],
    NSInvalidArgumentException, "nil identifiers raise an exception");
  PASS_EXCEPTION([first performSegueWithIdentifier: @"missing" sender: nil],
    NSInvalidArgumentException, "unknown segue identifiers raise an exception");
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSUInteger before = destroyedControllers;
  StoryboardProbe *survivor = RETAIN([storyboard instantiateInitialController]);
  [pool drain];
  PASS(survivor->trigger != nil, "top-level objects survive the loading autorelease pool");
  RELEASE(survivor);
  PASS(destroyedControllers == before + 1, "scene ownership does not retain the root controller cyclically");
  PASS_EXCEPTION(AUTORELEASE([[GSStoryboardArchive alloc]
    initWithData: [@"<document><broken>" dataUsingEncoding: NSUTF8StringEncoding]
    bundle: nil]), NSInvalidUnarchiveOperationException, "malformed XML is rejected");
  PASS_EXCEPTION(AUTORELEASE([[GSStoryboardArchive alloc]
    initWithData: nil bundle: nil]), NSInvalidUnarchiveOperationException, "missing data is rejected");
  NSString *duplicate = [xml stringByReplacingOccurrencesOfString: @"storyboardIdentifier='Other'"
    withString: @"storyboardIdentifier='Main'"];
  PASS_EXCEPTION(AUTORELEASE([[GSStoryboardArchive alloc]
    initWithData: [duplicate dataUsingEncoding: NSUTF8StringEncoding] bundle: nil]),
    NSInvalidUnarchiveOperationException, "duplicate public identifiers are rejected");
  duplicate = [xml stringByReplacingOccurrencesOfString: @"id='responder2'" withString: @"id='responder1'"];
  PASS_EXCEPTION(AUTORELEASE([[GSStoryboardArchive alloc]
    initWithData: [duplicate dataUsingEncoding: NSUTF8StringEncoding] bundle: nil]),
    NSInvalidUnarchiveOperationException, "duplicate XML object IDs are rejected");
  MemoryStoryboard *empty = AUTORELEASE([[MemoryStoryboard alloc] initWithXML: @"<document><scenes/></document>"]);
  PASS([empty instantiateInitialController] == nil, "a storyboard with no initial controller returns nil");
#if __has_feature(blocks)
  PASS_EXCEPTION([storyboard instantiateInitialControllerWithCreator: ^id(NSCoder *coder) {
    [NSException raise: NSGenericException format: @"creator failed"];
    return nil;
  }], NSGenericException, "creator exceptions propagate");
  PASS([storyboard instantiateInitialController] != nil,
       "a creator failure clears the active scene context");
#endif
  // A retained controller owns the archive it needs for future transitions.
  pool = [NSAutoreleasePool new];
  MemoryStoryboard *temporary = AUTORELEASE([[MemoryStoryboard alloc] initWithXML: xml]);
  survivor = RETAIN([temporary instantiateInitialController]);
  [pool drain];
  pool = [NSAutoreleasePool new];
  [survivor performSegueWithIdentifier: @"programmatic" sender: nil];
  PASS([performedSegue sourceController] == survivor,
       "controllers can perform segues after the original storyboard pool drains");
  DESTROY(performedSegue);
  [pool drain];
  RELEASE(survivor);
  END_SET("NSStoryboard direct scene loading")
  return 0;
}
