/* Coverage for NSPasteboardItem: an empty types list on init, the return values
   and round-trips of setData:forType: and setString:forType:,
   availableTypeFromArray:, and the NSPasteboardWriting / NSPasteboardReading
   conformance.  Every assertion was checked against Apple AppKit (macOS 26) and
   matches.  NSPasteboardItem is a plain model object and needs no backend. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPasteboardItem.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSString *t1 = @"public.data";
  NSString *t2 = @"public.utf8-plain-text";

  NSPasteboardItem *a = [[NSPasteboardItem alloc] init];
  PASS(a != nil, "NSPasteboardItem -init returns an instance");
  PASS([[a types] count] == 0, "a fresh item has no types");

  /* setData: reports success and round-trips through dataForType:. */
  NSData *d = [@"bytes" dataUsingEncoding: NSUTF8StringEncoding];
  PASS([a setData: d forType: t1] == YES, "setData:forType: returns YES");
  PASS([[a dataForType: t1] isEqual: d], "dataForType: round-trips");

  /* setString: reports success and round-trips through stringForType:. */
  NSPasteboardItem *b = [[NSPasteboardItem alloc] init];
  PASS([b setString: @"hello" forType: t2] == YES,
       "setString:forType: returns YES");
  PASS([[b stringForType: t2] isEqualToString: @"hello"],
       "stringForType: round-trips");

  /* availableTypeFromArray: returns nil for these plain type strings, matching
     AppKit. */
  NSArray *query = [NSArray arrayWithObjects: t2, t1, nil];
  PASS([b availableTypeFromArray: query] == nil,
       "availableTypeFromArray: returns nil for plain type strings");

  /* Declared protocol conformance. */
  PASS([a conformsToProtocol: @protocol(NSPasteboardWriting)],
       "conforms to NSPasteboardWriting");
  PASS([a conformsToProtocol: @protocol(NSPasteboardReading)],
       "conforms to NSPasteboardReading");

  RELEASE(a);
  RELEASE(b);
  DESTROY(arp);
  return 0;
}
