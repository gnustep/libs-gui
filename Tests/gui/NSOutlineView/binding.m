/* Coverage for the NSOutlineView content binding: which bindings are exposed,
   what -infoForBinding: reports before and after binding, and that content
   bound to a tree controller reaches the rows the view reports.  Every
   assertion here matches AppKit (verified on a macOS runner) and passes on
   unmodified GNUstep.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSObjectController.h>
#include <AppKit/NSOutlineView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTreeController.h>

@interface OutlineBindingNode : NSObject
{
  NSString	*name;
  NSMutableArray *children;
}
- (NSString *) name;
- (void) setName: (NSString *)aName;
- (NSMutableArray *) children;
- (BOOL) isLeaf;
@end

@implementation OutlineBindingNode
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

static OutlineBindingNode *
node(NSString *aName)
{
  OutlineBindingNode *n = AUTORELEASE([OutlineBindingNode new]);

  [n setName: aName];
  return n;
}

int main()
{
  NSOutlineView		*ov;
  NSTableColumn		*col;
  NSTreeController	*tc;
  NSObjectController	*oc;
  NSMutableDictionary	*model;
  NSArray		*exposed;

  START_SET("NSOutlineView content binding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  ov = AUTORELEASE([[NSOutlineView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);

  exposed = [ov exposedBindings];
  PASS([exposed containsObject: NSContentBinding],
       "the content binding is exposed");
  PASS([exposed containsObject: NSSortDescriptorsBinding],
       "the sort descriptors binding is exposed");

  PASS([ov infoForBinding: NSContentBinding] == nil,
       "an unbound outline view reports no content binding info");

  col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"name"]);
  [ov addTableColumn: col];
  [ov setOutlineTableColumn: col];

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

  [ov bind: NSContentBinding
   toObject: tc
withKeyPath: @"arrangedObjects"
    options: nil];

  PASS([ov infoForBinding: NSContentBinding] != nil,
       "binding the content records binding info");
  PASS([[ov infoForBinding: NSContentBinding] objectForKey: NSObservedObjectKey]
       == tc, "the binding info names the tree controller");

  [ov reloadData];
  PASS([ov numberOfRows] == 2,
       "the bound content gives the outline view a row for each root object");
  PASS([ov itemAtRow: 0] != nil,
       "the outline view has an item for a bound row");

  [ov unbind: NSContentBinding];
  PASS([ov infoForBinding: NSContentBinding] == nil,
       "unbinding clears the content binding info");

  [tc unbind: NSContentArrayBinding];
  [tc setContent: nil];

  END_SET("NSOutlineView content binding")

  return 0;
}
