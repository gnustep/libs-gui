#import "ObjectTesting.h"
#import <Foundation/NSArchiver.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTable.h>

/*
 * Regression test for -[GSTable initWithCoder:].
 *
 * The row/column counts were decoded from the (untrusted) archive and used to
 * size several NSZoneMalloc allocations with no validation.  A negative count
 * made the allocation size wrap to a huge value (NSZoneMalloc returned NULL)
 * and the unconditional origin write (_columnXOrigin[0] = ...) then
 * dereferenced NULL.  The counts are now validated (and the product checked
 * for overflow) before use.
 */

/* A keyed unarchiver that poisons the decoded GSTable column count. */
@interface GSNegCountUnarchiver : NSKeyedUnarchiver
@end
@implementation GSNegCountUnarchiver
- (int) decodeIntForKey: (NSString *)key
{
  if ([key isEqualToString: @"GSNumberOfColumns"])
    return -1;
  return [super decodeIntForKey: key];
}
@end

int main(void)
{
  ENTER_POOL
  GSTable *t;
  GSTable *t2;
  NSData *d;
  GSNegCountUnarchiver *u;

  t = [[GSTable alloc] initWithNumberOfRows: 2 numberOfColumns: 3];
  d = [NSKeyedArchiver archivedDataWithRootObject: t];

  u = [[GSNegCountUnarchiver alloc] initForReadingWithData: d];
  NS_DURING
    [u decodeObjectForKey: @"root"];
  NS_HANDLER
  NS_ENDHANDLER
  PASS(YES,
    "decoding a GSTable with a negative column count does not crash");

  t2 = [NSKeyedUnarchiver unarchiveObjectWithData: d];
  PASS(t2 != nil && [t2 numberOfRows] == 2 && [t2 numberOfColumns] == 3,
    "a GSTable round-trips through a keyed archive");

  RELEASE(t);
  RELEASE(u);
  LEAVE_POOL
  return 0;
}
