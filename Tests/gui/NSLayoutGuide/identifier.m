/* -[NSLayoutGuide setIdentifier:] copies its argument, matching AppKit (the
   NSUserInterfaceItemIdentification identifier property is copy): mutating the
   string passed in must not change the guide's identifier. */
#import "Testing.h"
#import <Foundation/NSString.h>
#import <AppKit/NSLayoutGuide.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSLayoutGuide *g = AUTORELEASE([[NSLayoutGuide alloc] init]);

  NSMutableString *ms = [NSMutableString stringWithString: @"id1"];
  [g setIdentifier: ms];
  PASS([[g identifier] isEqualToString: @"id1"], "setIdentifier: round-trips");

  [ms appendString: @"X"];
  PASS([[g identifier] isEqualToString: @"id1"],
       "identifier is copied, not shared with the argument");

  DESTROY(arp);
  return 0;
}
