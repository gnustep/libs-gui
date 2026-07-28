/* -exposedBindings collects the bindings exposed by the class and by each of
   its superclasses, so a class that exposes a binding its superclass already
   exposes used to have that name reported twice.  AppKit reports each name
   once (verified on a macOS runner).  NSOutlineView is the case in tree: it
   exposes content, selectionIndexes and sortDescriptors, and NSTableView
   exposes the same three.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSOutlineView.h>

static unsigned
occurrences(NSArray *array, NSString *name)
{
  unsigned	count = 0;
  unsigned	i;

  for (i = 0; i < [array count]; i++)
    {
      if ([[array objectAtIndex: i] isEqual: name])
	{
	  count++;
	}
    }
  return count;
}

int main()
{
  NSOutlineView	*ov;
  NSArray	*exposed;

  START_SET("NSOutlineView exposed bindings are not repeated")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  ov = AUTORELEASE([[NSOutlineView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);
  exposed = [ov exposedBindings];

  PASS(occurrences(exposed, NSContentBinding) == 1,
       "the content binding is reported once");
  PASS(occurrences(exposed, NSSelectionIndexesBinding) == 1,
       "the selection indexes binding is reported once");
  PASS(occurrences(exposed, NSSortDescriptorsBinding) == 1,
       "the sort descriptors binding is reported once");
  PASS(occurrences(exposed, NSContentArrayBinding) == 1,
       "a binding exposed by only one class in the chain is still reported");
  PASS([exposed count] == [[NSSet setWithArray: exposed] count],
       "no binding is reported more than once");

  END_SET("NSOutlineView exposed bindings are not repeated")

  return 0;
}
