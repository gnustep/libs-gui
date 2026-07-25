/* Coverage for NSDictionaryController: the initial key and value, the included
   and excluded key lists, a new key-value pair and the pair's key and value
   round-trips.  The controller is created with a content dictionary.  Every
   assertion here matches AppKit (verified on a macOS runner) and passes on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSDictionaryController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDictionaryController *dc;
  NSDictionaryControllerKeyValuePair *kvp;

  dc = AUTORELEASE([[NSDictionaryController alloc]
    initWithContent: [NSMutableDictionary dictionary]]);

  PASS([[dc initialKey] isEqual: @"key"], "default initialKey is \"key\"");
  PASS([[dc initialValue] isEqual: @"value"],
       "default initialValue is \"value\"");
  PASS([[dc includedKeys] count] == 0, "default includedKeys is empty");
  PASS([[dc excludedKeys] count] == 0, "default excludedKeys is empty");

  kvp = [dc newObject];
  PASS(kvp != nil, "newObject returns a key-value pair");
  PASS([kvp localizedKey] == nil,
       "a new key-value pair has no localized key");

  [kvp setKey: @"myKey"];
  PASS([[kvp key] isEqual: @"myKey"], "the key-value pair key round-trips");
  [kvp setValue: @"myValue"];
  PASS([[kvp value] isEqual: @"myValue"], "the key-value pair value round-trips");

  [dc setInitialKey: @"otherKey"];
  PASS([[dc initialKey] isEqual: @"otherKey"], "initialKey round-trips");
  [dc setInitialValue: @"otherValue"];
  PASS([[dc initialValue] isEqual: @"otherValue"], "initialValue round-trips");
  [dc setIncludedKeys: [NSArray arrayWithObjects: @"a", @"b", nil]];
  PASS([[dc includedKeys] count] == 2, "includedKeys round-trips");
  [dc setExcludedKeys: [NSArray arrayWithObject: @"x"]];
  PASS([[dc excludedKeys] count] == 1, "excludedKeys round-trips");

  DESTROY(arp);
  return 0;
}
