/* An NSColorPicker does not retain the color panel it is created with: the
   panel owns its pickers, so a retained back reference would be a retain cycle.
   Releasing the panel while the picker is alive therefore deallocates it. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSObject.h>

#include <AppKit/NSColorPicker.h>

static BOOL panelDeallocated;

@interface ColorPickerPanelStub : NSObject
@end

@implementation ColorPickerPanelStub
- (void) dealloc
{
  panelDeallocated = YES;
  [super dealloc];
}
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSColorPicker *picker;
  id panel;

  panelDeallocated = NO;
  panel = [[ColorPickerPanelStub alloc] init];
  picker = [[NSColorPicker alloc] initWithPickerMask: 0
                                          colorPanel: (NSColorPanel *)panel];
  RELEASE(panel);
  PASS(panelDeallocated == YES,
       "the picker does not retain its color panel");

  RELEASE(picker);

  DESTROY(arp);
  return 0;
}
