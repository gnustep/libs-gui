#import "Controller.h"

@implementation Controller

- (void)buttonPressed:(id)sender
{
  NSString* text
      = [NSString stringWithFormat:@"\"%@\" button pressed", [sender title]];

  [textField setStringValue:text];
}

@end
