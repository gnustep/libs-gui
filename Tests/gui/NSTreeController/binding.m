/* Coverage for the NSTreeController content array binding: which bindings are
   exposed, what -infoForBinding: reports before and after binding, that a new
   value at the observed key path reaches -content and the arranged tree, and
   that unbinding clears the binding and rebinding works.  Every assertion here
   matches AppKit (verified on a macOS runner) and passes on unmodified GNUstep.

   The controller needs no display, so everything here runs in any environment.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSObjectController.h>
#include <AppKit/NSTreeController.h>
#include <AppKit/NSTreeNode.h>

/* A minimal tree node: the controller reaches children and leaf state through
   the key paths set on it. */
@interface TreeBindingNode : NSObject
{
  NSString	*name;
  NSMutableArray *children;
}
- (NSString *) name;
- (void) setName: (NSString *)aName;
- (NSMutableArray *) children;
- (BOOL) isLeaf;
@end

@implementation TreeBindingNode
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

static TreeBindingNode *
node(NSString *aName)
{
  TreeBindingNode *n = AUTORELEASE([TreeBindingNode new]);

  [n setName: aName];
  return n;
}

int main()
{
  NSTreeController	*tc;
  NSObjectController	*oc;
  NSMutableDictionary	*model;
  NSMutableArray	*replacement;
  NSDictionary		*info;
  NSArray		*exposed;

  START_SET("NSTreeController content array binding")

  tc = AUTORELEASE([[NSTreeController alloc] init]);
  [tc setChildrenKeyPath: @"children"];
  [tc setLeafKeyPath: @"isLeaf"];

  exposed = [tc exposedBindings];
  PASS([exposed containsObject: NSContentArrayBinding],
       "the content array binding is exposed");
  PASS([exposed containsObject: NSSelectionIndexPathsBinding],
       "the selection index paths binding is exposed");

  PASS([tc infoForBinding: NSContentArrayBinding] == nil,
       "an unbound controller reports no binding info");

  /* Bind to a key path on a controller so the value can be replaced later
     without touching the array the controller was given. */
  model = [NSMutableDictionary dictionaryWithObject:
    [NSMutableArray arrayWithObject: node(@"first")] forKey: @"roots"];
  oc = AUTORELEASE([[NSObjectController alloc] initWithContent: model]);

  [tc bind: NSContentArrayBinding
   toObject: oc
withKeyPath: @"content.roots"
    options: nil];

  info = [tc infoForBinding: NSContentArrayBinding];
  PASS(info != nil, "binding the content array records binding info");
  PASS([info objectForKey: NSObservedObjectKey] == oc,
       "the binding info names the observed object");
  PASS_EQUAL([info objectForKey: NSObservedKeyPathKey], @"content.roots",
       "the binding info carries the observed key path");
  PASS([[tc content] count] == 1,
       "the bound value reaches the controller content");

  /* A different array at the observed key path, so this cannot pass by the
     controller and the test sharing one mutable array. */
  replacement = [NSMutableArray arrayWithObjects:
    node(@"a"), node(@"b"), node(@"c"), nil];
  [oc setValue: replacement forKeyPath: @"content.roots"];

  PASS([[tc content] count] == 3,
       "a new value at the observed key path reaches the controller content");
  PASS([tc arrangedObjects] != nil,
       "the controller arranges the bound content");
  PASS([[[tc arrangedObjects] childNodes] count] == 3,
       "the arranged tree has a node for each bound object");

  [tc unbind: NSContentArrayBinding];
  PASS([tc infoForBinding: NSContentArrayBinding] == nil,
       "unbinding clears the binding info");

  /* -bind:toObject:withKeyPath:options: unbinds first, so binding a second
     time has to work. */
  [tc bind: NSContentArrayBinding
   toObject: oc
withKeyPath: @"content.roots"
    options: nil];
  PASS([tc infoForBinding: NSContentArrayBinding] != nil,
       "the content array can be bound again after unbinding");

  [tc unbind: NSContentArrayBinding];

  /* Break the retain loop so the controller can be deallocated. */
  [tc setContent: nil];

  END_SET("NSTreeController content array binding")

  return 0;
}
