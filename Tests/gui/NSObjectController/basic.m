/* Coverage for NSObjectController: the defaults, newObject, the content and
 * selected objects round-trip, add: and remove:, and how the editable flag
 * gates canAdd and canRemove.  These are plain controller operations and need
 * no backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSObjectController.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("defaults")
    NSObjectController	*oc = AUTORELEASE([[NSObjectController alloc] init]);

    PASS([oc content] == nil, "a new controller has no content");
    PASS([oc objectClass] == [NSMutableDictionary class],
      "the default object class is NSMutableDictionary");
    PASS([oc isEditable] == YES, "a new controller is editable");
    PASS([oc automaticallyPreparesContent] == NO,
      "a new controller does not automatically prepare content");
    PASS([[oc selectedObjects] count] == 0,
      "a new controller has no selected objects");
    PASS([oc canAdd] == YES, "an editable controller can add");
    PASS([oc canRemove] == NO, "a controller with no content cannot remove");
  END_SET("defaults")

  START_SET("newObject")
    NSObjectController	*oc = AUTORELEASE([[NSObjectController alloc] init]);

    PASS([AUTORELEASE([oc newObject]) isKindOfClass: [NSMutableDictionary class]],
      "newObject makes an instance of the object class");
  END_SET("newObject")

  START_SET("content and selection")
    NSObjectController	*oc = AUTORELEASE([[NSObjectController alloc] init]);
    NSMutableDictionary	*d = [NSMutableDictionary dictionary];

    [oc setContent: d];
    PASS([oc content] == d, "setContent: round trips");
    PASS([[oc selectedObjects] count] == 1
      && [[oc selectedObjects] objectAtIndex: 0] == d,
      "the content is the selected object");
    PASS([oc canRemove] == YES, "a controller with content can remove");

    oc = AUTORELEASE([[NSObjectController alloc] initWithContent: d]);
    PASS([oc content] == d, "initWithContent: stores the content");
  END_SET("content and selection")

  START_SET("the editable flag gates adding and removing")
    NSObjectController	*oc = AUTORELEASE([[NSObjectController alloc]
      initWithContent: [NSMutableDictionary dictionary]]);

    [oc setEditable: NO];
    PASS([oc canAdd] == NO, "a non-editable controller cannot add");
    PASS([oc canRemove] == NO, "a non-editable controller cannot remove");
  END_SET("the editable flag gates adding and removing")

  START_SET("addObject: and removeObject:")
    NSObjectController	*oc = AUTORELEASE([[NSObjectController alloc] init]);
    NSMutableDictionary	*d = [NSMutableDictionary dictionary];

    [oc addObject: d];
    PASS([oc content] == d, "addObject: sets the content");
    [oc removeObject: d];
    PASS([oc content] == nil, "removeObject: clears the content");
  END_SET("addObject: and removeObject:")

  DESTROY(arp);
  return 0;
}
