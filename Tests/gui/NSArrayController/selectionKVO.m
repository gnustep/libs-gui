/* Coverage for the key-value observing that hangs off an array controller's
   selection: -setSelectionIndexes: is the mutation every click in a table
   funnels into, and the values a binding watches - selection, selectedObjects,
   canRemove, canSelectNext and canSelectPrevious - are all derived from it, so
   observers of those keys have to hear about the change or a Remove button
   bound to canRemove stays grey and a field bound through selection.<key>
   keeps showing the old row.  -selection itself answers the selected object
   when exactly one row is selected, rather than the whole content array, which
   is what makes selection.<key> read that row's value.  NSArrayController
   needs no display, but the set keeps the usual backend skip guard. */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSIndexSet.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSArrayController.h>

static NSMutableSet *fired;

@interface SelectionObserver : NSObject
@end

@implementation SelectionObserver
- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  [fired addObject: keyPath];
}
@end

int
main(int argc, const char **argv)
{
  SelectionObserver *observer;
  NSArrayController *ac;
  NSMutableDictionary *ada;
  NSMutableDictionary *grace;
  NSArray *keys;
  NSEnumerator *e;
  NSString *key;

  START_SET("NSArrayController selectionKVO")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      fired = [NSMutableSet set];
      observer = AUTORELEASE([[SelectionObserver alloc] init]);

      ada = [NSMutableDictionary dictionaryWithObject: @"Ada"
                                               forKey: @"name"];
      grace = [NSMutableDictionary dictionaryWithObject: @"Grace"
                                                 forKey: @"name"];

      ac = AUTORELEASE([[NSArrayController alloc] init]);
      [ac setContent: [NSMutableArray arrayWithObjects: ada, grace, nil]];
      [ac setSelectionIndexes: [NSIndexSet indexSetWithIndex: 0]];

      keys = [NSArray arrayWithObjects: @"selectionIndexes", @"selection",
        @"selectedObjects", @"canRemove", @"canSelectNext",
        @"canSelectPrevious", nil];
      e = [keys objectEnumerator];
      while ((key = [e nextObject]) != nil)
        {
          [ac addObserver: observer forKeyPath: key options: 0 context: NULL];
        }

      /* The mutation a click on another row funnels into. */
      [ac setSelectionIndexes: [NSIndexSet indexSetWithIndex: 1]];

      /* Control: the setter's own key notifies whether or not the dependent
         keys are declared, so a silent result here means the observation
         itself is broken rather than the dependencies. */
      PASS([fired containsObject: @"selectionIndexes"],
        "setSelectionIndexes: notifies observers of selectionIndexes");

      PASS([fired containsObject: @"selection"],
        "setSelectionIndexes: notifies observers of selection");
      PASS([fired containsObject: @"selectedObjects"],
        "setSelectionIndexes: notifies observers of selectedObjects");
      PASS([fired containsObject: @"canRemove"],
        "setSelectionIndexes: notifies observers of canRemove");
      PASS([fired containsObject: @"canSelectNext"],
        "setSelectionIndexes: notifies observers of canSelectNext");
      PASS([fired containsObject: @"canSelectPrevious"],
        "setSelectionIndexes: notifies observers of canSelectPrevious");

      e = [keys objectEnumerator];
      while ((key = [e nextObject]) != nil)
        {
          [ac removeObserver: observer forKeyPath: key];
        }

      /* One row selected: selection is that row, not the content array. */
      PASS([ac selection] == grace,
        "selection answers the single selected object");
      PASS([[ac valueForKeyPath: @"selection.name"] isEqual: @"Grace"],
        "selection.<key> reads the selected object's value");

      /* Nothing selected: nothing to answer with. */
      [ac setSelectionIndexes: [NSIndexSet indexSet]];
      PASS([ac selection] == nil, "an empty selection answers nil");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSArrayController selectionKVO")

  return 0;
}
