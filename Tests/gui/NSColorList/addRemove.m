/* Tests editing an in-memory NSColorList: setColor:forKey: adding and updating
 * colours, insertColor:key:atIndex: controlling the key order,
 * removeColorWithKey:, colorWithKey:/allKeys, and the not-editable exception.
 * These are plain value operations.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSColorList.h>
#include <AppKit/NSColor.h>

static NSColor *
rgb(CGFloat r, CGFloat g, CGFloat b)
{
  return [NSColor colorWithDeviceRed: r green: g blue: b alpha: 1.0];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSColorList editing")

  NSColor *red = rgb(1, 0, 0);
  NSColor *green = rgb(0, 1, 0);
  NSColor *blue = rgb(0, 0, 1);

  /* A newly named list is empty and editable. */
  {
    NSColorList *list = [[[NSColorList alloc] initWithName: @"UnitTestList"] autorelease];

    pass([list isEditable] == YES, "a new named colour list is editable");
    pass([[list allKeys] count] == 0, "a new colour list has no keys");
    pass([list colorWithKey: @"missing"] == nil,
      "an unknown key has no colour");
  }

  /* setColor:forKey: adds a colour and its key. */
  {
    NSColorList *list = [[[NSColorList alloc] initWithName: @"UnitTestList"] autorelease];

    [list setColor: red forKey: @"red"];
    pass([[list colorWithKey: @"red"] isEqual: red]
      && [[list allKeys] containsObject: @"red"]
      && [[list allKeys] count] == 1,
      "setColor:forKey: adds the colour under its key");

    /* Setting the same key updates the colour without adding a second key. */
    [list setColor: blue forKey: @"red"];
    pass([[list colorWithKey: @"red"] isEqual: blue]
      && [[list allKeys] count] == 1,
      "setColor:forKey: on an existing key updates without duplicating it");
  }

  /* Keys keep their insertion order. */
  {
    NSColorList *list = [[[NSColorList alloc] initWithName: @"UnitTestList"] autorelease];

    [list setColor: red forKey: @"one"];
    [list setColor: green forKey: @"two"];
    [list setColor: blue forKey: @"three"];
    pass([[[list allKeys] objectAtIndex: 0] isEqual: @"one"]
      && [[[list allKeys] objectAtIndex: 1] isEqual: @"two"]
      && [[[list allKeys] objectAtIndex: 2] isEqual: @"three"],
      "setColor:forKey: appends keys in insertion order");
  }

  /* insertColor:key:atIndex: places a new key at the index and moves an
   * existing key to a new index. */
  {
    NSColorList *list = [[[NSColorList alloc] initWithName: @"UnitTestList"] autorelease];

    [list setColor: red forKey: @"one"];
    [list setColor: green forKey: @"two"];
    [list setColor: blue forKey: @"three"];

    [list insertColor: rgb(1, 1, 0) key: @"zero" atIndex: 0];
    pass([[[list allKeys] objectAtIndex: 0] isEqual: @"zero"]
      && [[list allKeys] count] == 4,
      "insertColor:key:atIndex: inserts a new key at the index");

    [list insertColor: blue key: @"three" atIndex: 0];
    pass([[[list allKeys] objectAtIndex: 0] isEqual: @"three"]
      && [[list allKeys] count] == 4,
      "insertColor:key:atIndex: moves an existing key without duplicating it");
  }

  /* removeColorWithKey: deletes the colour and its key. */
  {
    NSColorList *list = [[[NSColorList alloc] initWithName: @"UnitTestList"] autorelease];

    [list setColor: red forKey: @"red"];
    [list setColor: green forKey: @"green"];
    [list removeColorWithKey: @"red"];
    pass([list colorWithKey: @"red"] == nil
      && [[list allKeys] containsObject: @"red"] == NO
      && [[list allKeys] count] == 1,
      "removeColorWithKey: deletes the colour and its key");
  }

  END_SET("NSColorList editing")

  DESTROY(arp);
  return 0;
}
