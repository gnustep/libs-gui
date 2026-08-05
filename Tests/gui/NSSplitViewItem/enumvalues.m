/* The NSTitlebarSeparatorStyle values match AppKit: Automatic, None, Line,
   Shadow are 0, 1, 2, 3. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitViewItem.h>

int main()
{
  START_SET("NSSplitViewItem enumvalues")

  PASS(NSTitlebarSeparatorStyleAutomatic == 0,
       "NSTitlebarSeparatorStyleAutomatic is 0");
  PASS(NSTitlebarSeparatorStyleNone == 1,
       "NSTitlebarSeparatorStyleNone is 1");
  PASS(NSTitlebarSeparatorStyleLine == 2,
       "NSTitlebarSeparatorStyleLine is 2");
  PASS(NSTitlebarSeparatorStyleShadow == 3,
       "NSTitlebarSeparatorStyleShadow is 3");

  END_SET("NSSplitViewItem enumvalues")
  return 0;
}
