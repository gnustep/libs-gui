/* Coverage for the NSBrowser content binding: which bindings are exposed, and
   what -infoForBinding: reports before binding, after binding to a tree
   controller, and after unbinding.  These assertions pass on unmodified
   GNUstep and describe the behaviour the class has now.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSObjectController.h>
#include <AppKit/NSTreeController.h>

@interface BrowserBindingNode : NSObject
{
  NSString	*name;
  NSMutableArray *children;
}
- (NSString *) name;
- (void) setName: (NSString *)aName;
- (NSMutableArray *) children;
- (BOOL) isLeaf;
@end

@implementation BrowserBindingNode
- (id) init
{
  self = [super init];
  if (self != nil)
    {
      children = [NSMutableArray new];
    }
  return self;
}
- (void) dealloc
{
  RELEASE(name);
  RELEASE(children);
  [super dealloc];
}
- (NSString *) name { return name; }
- (void) setName: (NSString *)aName { ASSIGN(name, aName); }
- (NSMutableArray *) children { return children; }
- (BOOL) isLeaf { return [children count] == 0; }
@end

static BrowserBindingNode *
node(NSString *aName)
{
  BrowserBindingNode *n = AUTORELEASE([BrowserBindingNode new]);

  [n setName: aName];
  return n;
}

int main()
{
  NSBrowser		*br;
  NSTreeController	*tc;
  NSObjectController	*oc;
  NSMutableDictionary	*model;
  NSArray		*exposed;

  START_SET("NSBrowser content binding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  br = AUTORELEASE([[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);

  exposed = [br exposedBindings];
  PASS([exposed containsObject: NSContentBinding],
       "the content binding is exposed");
  PASS([exposed containsObject: NSContentValuesBinding],
       "the content values binding is exposed");

  PASS([br infoForBinding: NSContentBinding] == nil,
       "an unbound browser reports no content binding info");

  model = [NSMutableDictionary dictionaryWithObject:
    [NSMutableArray arrayWithObjects: node(@"a"), node(@"b"), nil]
    forKey: @"roots"];
  oc = AUTORELEASE([[NSObjectController alloc] initWithContent: model]);

  tc = AUTORELEASE([[NSTreeController alloc] init]);
  [tc setChildrenKeyPath: @"children"];
  [tc setLeafKeyPath: @"isLeaf"];
  [tc bind: NSContentArrayBinding
   toObject: oc
withKeyPath: @"content.roots"
    options: nil];

  [br bind: NSContentBinding
   toObject: tc
withKeyPath: @"arrangedObjects"
    options: nil];

  PASS([br infoForBinding: NSContentBinding] != nil,
       "binding the content records binding info");
  PASS([[br infoForBinding: NSContentBinding] objectForKey: NSObservedObjectKey]
       == tc, "the binding info names the tree controller");
  PASS_EQUAL([[br infoForBinding: NSContentBinding]
    objectForKey: NSObservedKeyPathKey], @"arrangedObjects",
       "the binding info carries the observed key path");

  [br unbind: NSContentBinding];
  PASS([br infoForBinding: NSContentBinding] == nil,
       "unbinding clears the content binding info");

  [tc unbind: NSContentArrayBinding];
  [tc setContent: nil];

  END_SET("NSBrowser content binding")

  return 0;
}
