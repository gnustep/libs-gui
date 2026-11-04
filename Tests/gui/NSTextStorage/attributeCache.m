/* Exercise collision growth and removal after a shallow-copied attribute
 * value changes its hash.  Comparison counts avoid timing-based assertions.
 * Retain the removed dictionary in the mutation test so a stale map key can
 * be detected by equality calls without dereferencing freed memory. */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSTextStorage.h>

static NSUInteger comparisons;
static NSUInteger watchedComparisons;
static NSUInteger liveValues;
static id watchedValue;

@interface CacheValue : NSObject
{
@public
  NSUInteger value;
}
- (id) initWithValue: (NSUInteger)v;
@end

@implementation CacheValue
- (id) initWithValue: (NSUInteger)v
{
  self = [super init];
  if (self != nil)
    {
      value = v;
      liveValues++;
    }
  return self;
}
- (NSUInteger) hash
{
  return value;
}
- (BOOL) isEqual: (id)other
{
  comparisons++;
  if (self == watchedValue || other == watchedValue)
    watchedComparisons++;
  return [other isKindOfClass: [CacheValue class]]
    && ((CacheValue *)other)->value == value;
}
- (void) dealloc
{
  liveValues--;
  [super dealloc];
}
@end

static NSUInteger
insertRuns(NSUInteger count, BOOL *valid)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSString *text = [@"" stringByPaddingToLength: count
    withString: @"x" startingAtIndex: 0];
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString: text];
  NSUInteger before = liveValues;
  NSUInteger result;
  NSUInteger i;

  *valid = YES;
  [storage beginEditing];
  comparisons = 0;
  for (i = 0; i < count; i++)
    {
      CacheValue *v = [[CacheValue alloc] initWithValue: i + 1];
      NSDictionary *attrs = [NSDictionary dictionaryWithObject: v
        forKey: @"CacheTestValue"];

      [storage setAttributes: attrs range: NSMakeRange(i, 1)];
      [v release];
    }
  result = comparisons;
  [storage endEditing];
  for (i = 0; i < count; i++)
    {
      NSRange range;
      CacheValue *v = [[storage attributesAtIndex: i effectiveRange: &range]
        objectForKey: @"CacheTestValue"];

      if (v == nil || v->value != i + 1
        || range.location != i || range.length != 1)
        *valid = NO;
    }
  [storage release];
  [pool drain];
  if (liveValues != before)
    *valid = NO;
  return result;
}

static BOOL
removeMutatedValue(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString: @"ab"];
  CacheValue *v = [[CacheValue alloc] initWithValue: 12345];
  NSDictionary *held;
  NSMutableDictionary *probeAttrs;
  NSTextStorage *probe;
  CacheValue *newValue;
  BOOL valid;

  [storage setAttributes: [NSDictionary dictionaryWithObject: v
    forKey: @"CacheTestValue"] range: NSMakeRange(0, 2)];
  held = [[storage attributesAtIndex: 0 effectiveRange: NULL] retain];
  v->value = 987654;
  [storage release];
  [v release];
  [pool drain];

  /* The dictionary remains alive here but no NSTextStorage owns its cache
   * entry.  Probe its original hash.  A hash-only removal change would leave
   * an entry pointing at this dictionary and compare against the old value. */
  pool = [NSAutoreleasePool new];
  watchedValue = [held objectForKey: @"CacheTestValue"];
  watchedComparisons = 0;
  newValue = [[CacheValue alloc] initWithValue: 12345];
  probeAttrs = [[NSMutableDictionary alloc] initWithDictionary: held];
  [probeAttrs setObject: newValue forKey: @"CacheTestValue"];
  probe = [[NSTextStorage alloc] initWithString: @"ab"];
  [probe beginEditing];
  [probe setAttributes: probeAttrs range: NSMakeRange(0, 2)];
  valid = watchedComparisons == 0;
  watchedValue = nil;
  [probe endEditing];
  [probe release];
  [probeAttrs release];
  [newValue release];
  [held release];
  [pool drain];
  return valid;
}

int
main(void)
{
  START_SET("NSTextStorage attribute cache")
    BOOL smallValid;
    BOOL largeValid;
    NSUInteger small;
    NSUInteger large;

    NS_DURING
      [NSApplication sharedApplication];
    NS_HANDLER
      if ([[localException name]
        isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    NS_ENDHANDLER

    /* Prime first-use font services before the counted workload. */
    insertRuns(1, &smallValid);
    small = insertRuns(400, &smallValid);
    large = insertRuns(800, &largeValid);
    fprintf(stderr, "attribute-cache comparisons: N=%lu 2N=%lu\n",
      (unsigned long)small, (unsigned long)large);
    PASS(smallValid, "400 distinct runs retain values/ranges and release values");
    PASS(largeValid, "800 distinct runs retain values/ranges and release values");
    PASS(large <= 3 * small + 100,
      "doubling distinct same-count runs avoids quadratic equality growth");
    PASS(removeMutatedValue(),
      "a removed mutable-hash dictionary is absent from its old bucket");
    PASS(liveValues == 0, "attribute values are released after cache removal");
  END_SET("NSTextStorage attribute cache")
  return 0;
}
