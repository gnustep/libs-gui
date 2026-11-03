/* NSDictionaryController.h is self-contained: including it on its own declares
   the dictionary types its interface uses, so this compiles without including
   NSDictionary.h. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSDictionaryController.h>

int main()
{
  START_SET("NSDictionaryController headeronly")

  PASS([NSDictionaryController class] != Nil,
       "the NSDictionaryController class is available");

  END_SET("NSDictionaryController headeronly")
  return 0;
}
