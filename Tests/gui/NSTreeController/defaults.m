/* NSTreeController initial-state defaults: a new controller avoids an empty
   selection, preserves the selection, and selects inserted objects, as AppKit
   does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSTreeController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTreeController *tc;

  tc = AUTORELEASE([[NSTreeController alloc] init]);

  PASS([tc avoidsEmptySelection] == YES,
       "default avoidsEmptySelection is YES");
  PASS([tc preservesSelection] == YES,
       "default preservesSelection is YES");
  PASS([tc selectsInsertedObjects] == YES,
       "default selectsInsertedObjects is YES");

  DESTROY(arp);
  return 0;
}
