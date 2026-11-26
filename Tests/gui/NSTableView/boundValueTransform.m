/* A column bound to an array controller takes each row from the bound
   array as it was, so a nil value showed as the NSNull the array holds for
   it, "<null>", and neither a placeholder nor a value transformer the
   binding names was applied.  A row is transformed as any bound value is. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSValueTransformer.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSArrayController.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

@interface NSTableView (Private)
- (id) _objectValueForTableColumn: (NSTableColumn *)tb row: (NSInteger)index;
@end

@interface Shout : NSValueTransformer
@end

@implementation Shout
+ (Class) transformedValueClass
{
  return [NSString class];
}
- (id) transformedValue: (id)value
{
  return [value isKindOfClass: [NSString class]] ? [value uppercaseString] : value;
}
@end

int
main(int argc, const char **argv)
{
  NSArrayController *rows;
  NSTableView *table;
  NSTableColumn *plain;
  NSTableColumn *placed;
  NSTableColumn *shouted;

  START_SET("NSTableView boundValueTransform")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  [NSValueTransformer setValueTransformer: AUTORELEASE([[Shout alloc] init])
				  forName: @"Shout"];
  rows = AUTORELEASE([[NSArrayController alloc] init]);
  [rows setContent: [NSArray arrayWithObjects:
    [NSDictionary dictionaryWithObject: @"ann" forKey: @"name"],
    [NSDictionary dictionary], nil]];

  table = AUTORELEASE([[NSTableView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)]);
  plain = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"plain"]);
  placed = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"placed"]);
  shouted = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"shouted"]);
  [table addTableColumn: plain];
  [table addTableColumn: placed];
  [table addTableColumn: shouted];
  [plain bind: NSValueBinding toObject: rows
  withKeyPath: @"arrangedObjects.name" options: nil];
  [placed bind: NSValueBinding toObject: rows
   withKeyPath: @"arrangedObjects.name"
       options: [NSDictionary dictionaryWithObject: @"nobody"
					    forKey: NSNullPlaceholderBindingOption]];
  [shouted bind: NSValueBinding toObject: rows
    withKeyPath: @"arrangedObjects.name"
	options: [NSDictionary dictionaryWithObject: @"Shout"
					     forKey: NSValueTransformerNameBindingOption]];

  PASS_EQUAL(([table _objectValueForTableColumn: plain row: 0]), @"ann",
	     "a bound row is the value");
  PASS(([table _objectValueForTableColumn: plain row: 1]) == nil,
       "a nil value is nil, not NSNull");
  PASS_EQUAL(([table _objectValueForTableColumn: placed row: 1]), @"nobody",
	     "a nil value is the null placeholder the binding names");
  PASS_EQUAL(([table _objectValueForTableColumn: shouted row: 0]), @"ANN",
	     "a value goes through the transformer the binding names");

  END_SET("NSTableView boundValueTransform")
  return 0;
}
