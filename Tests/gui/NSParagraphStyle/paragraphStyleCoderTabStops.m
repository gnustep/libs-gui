#import "ObjectTesting.h"
#import <Foundation/NSArchiver.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSText.h>

/*
 * Regression test for a stack overflow in -[NSParagraphStyle initWithCoder:].
 *
 * The non-keyed decoding path read a tab-stop count from the (untrusted)
 * archive and then allocated two stack VLAs (float locations[count];
 * NSTextTabType types[count];) sized by that count, so a large count
 * overflowed the stack before any data was read.  The arrays are now
 * heap-allocated.
 */

/* A fake non-keyed coder that feeds a huge tab-stop count. */
@interface HugeTabCountCoder : NSCoder
@end
@implementation HugeTabCountCoder
- (BOOL) allowsKeyedCoding { return NO; }
- (void) decodeValueOfObjCType: (const char *)type at: (void *)data
{
  if (strcmp(type, @encode(NSUInteger)) == 0)
    *(NSUInteger *)data = 4000000;        /* huge tab-stop count */
  else if (strcmp(type, @encode(NSInteger)) == 0)
    *(NSInteger *)data = 0;
  else if (type[0] == 'f')
    *(float *)data = 0.0f;
  else
    memset(data, 0, 8);
}
- (void) decodeArrayOfObjCType: (const char *)type
                         count: (NSUInteger)count
                            at: (void *)array
{
  /* a real unarchiver raises when the archive lacks `count` elements */
  [NSException raise: NSRangeException format: @"not enough data"];
}
- (NSInteger) versionForClassName: (NSString *)className { return 1; }
@end

int main(void)
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  HugeTabCountCoder *fc = AUTORELEASE([HugeTabCountCoder new]);
  NSMutableParagraphStyle *p;
  NSParagraphStyle *p2;
  NSData *d;

  NS_DURING
    [[NSParagraphStyle alloc] initWithCoder: fc];
  NS_HANDLER
  NS_ENDHANDLER
  PASS(YES,
    "decoding a paragraph style with a huge tab-stop count does not overflow the stack");

  p = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  [p setTabStops: [NSArray arrayWithObjects:
    [[[NSTextTab alloc] initWithType: NSLeftTabStopType location: 72.0] autorelease],
    [[[NSTextTab alloc] initWithType: NSRightTabStopType location: 144.0] autorelease],
    nil]];
  d = [NSArchiver archivedDataWithRootObject: p];
  p2 = [NSUnarchiver unarchiveObjectWithData: d];
  PASS(p2 != nil && [[p2 tabStops] count] == 2,
    "a paragraph style with tab stops round-trips through a non-keyed archive");

  [arp release];
  return 0;
}
