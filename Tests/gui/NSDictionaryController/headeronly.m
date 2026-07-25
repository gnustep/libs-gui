/* NSDictionaryController.h is self-contained: including it on its own declares
   the dictionary types its interface uses, so this compiles without including
   NSDictionary.h. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSDictionaryController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);

  PASS([NSDictionaryController class] != Nil,
       "the NSDictionaryController class is available");

  DESTROY(arp);
  return 0;
}
