
#include <Foundation/Foundation.h>
#include "AppKit/AppKit.h"

void __objc_gui_linking(void)
{
  [GSFontInfo class];
  [NSBezierPath class];
  [NSStepper class];
}
