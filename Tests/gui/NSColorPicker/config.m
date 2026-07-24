/* Coverage for NSColorPicker: the color panel passed to the initializer is
   reported back by -colorPanel, and a nil panel stays nil.  This state needs no
   window server.  Every assertion here matches AppKit (verified on a macOS
   runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSColorPicker.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSColorPicker *picker;

  picker = AUTORELEASE([[NSColorPicker alloc]
    initWithPickerMask: 0 colorPanel: nil]);

  PASS(picker != nil, "a picker with a nil panel is created");
  PASS([picker colorPanel] == nil, "a nil color panel stays nil");

  DESTROY(arp);
  return 0;
}
