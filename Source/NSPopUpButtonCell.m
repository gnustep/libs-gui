#include <gnustep/gui/config.h>  
#include <AppKit/NSPopUpButtonCell.h>

@implementation NSPopUpButtonCell
+ (void) initialize
{
  if (self == [NSPopUpButtonCell class])
    [self setVersion: 1];
}


@end
