/* Setting data/string/property-list for a type registers that type in -types,
   matching AppKit, and does not duplicate a type set more than once. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPasteboardItem.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSString *t1 = @"public.utf8-plain-text";
  NSString *t2 = @"public.data";

  NSPasteboardItem *item = [[NSPasteboardItem alloc] init];

  [item setString: @"hi" forType: t1];
  PASS([[item types] containsObject: t1], "setString:forType: registers the type");
  PASS([[item types] count] == 1, "one type is registered");

  NSData *d = [@"x" dataUsingEncoding: NSUTF8StringEncoding];
  [item setData: d forType: t2];
  PASS([[item types] containsObject: t2], "setData:forType: registers the type");
  PASS([[item types] count] == 2, "a second type is registered");

  [item setData: d forType: t2];
  PASS([[item types] count] == 2,
       "setting the same type twice does not duplicate it");

  RELEASE(item);
  DESTROY(arp);
  return 0;
}
