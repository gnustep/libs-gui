/* [[NSDictionaryController alloc] init] creates a controller with a dictionary
   content, so it does not raise, and reports the default initial key, as AppKit
   does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSDictionaryController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDictionaryController *dc;

  dc = AUTORELEASE([[NSDictionaryController alloc] init]);
  PASS(dc != nil, "a dictionary controller can be created with -init");
  PASS([[dc initialKey] isEqual: @"key"], "its initial key is the default");

  DESTROY(arp);
  return 0;
}
