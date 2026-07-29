/* The rule editor asks its delegate for the criteria a row can hold, keeps
   the rows in a tree, and builds a predicate out of the parts the delegate
   gives for each criterion.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSExpression.h>
#include <Foundation/NSIndexSet.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPredicate.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSRuleEditor.h>
#include <AppKit/NSTextField.h>

static int notifications = 0;

@interface Delegate : NSObject
@end

@implementation Delegate

- (NSInteger) ruleEditor: (NSRuleEditor *)editor
numberOfChildrenForCriterion: (id)criterion
             withRowType: (NSRuleEditorRowType)rowType
{
  if (rowType == NSRuleEditorRowTypeCompound)
    {
      return criterion == nil ? 2 : 0;
    }
  if (criterion == nil || [criterion isEqual: @"name"]
    || [criterion isEqual: @"is"])
    {
      return 1;
    }
  return 0;
}

- (id) ruleEditor: (NSRuleEditor *)editor
            child: (NSInteger)index
     forCriterion: (id)criterion
      withRowType: (NSRuleEditorRowType)rowType
{
  if (rowType == NSRuleEditorRowTypeCompound)
    {
      return index == 0 ? @"All" : @"Any";
    }
  if (criterion == nil)
    {
      return @"name";
    }
  if ([criterion isEqual: @"name"])
    {
      return @"is";
    }
  return @"value";
}

- (id) ruleEditor: (NSRuleEditor *)editor
displayValueForCriterion: (id)criterion
            inRow: (NSInteger)row
{
  if ([criterion isEqual: @"value"])
    {
      NSTextField *field;

      field = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(0.0, 0.0, 100.0, 22.0)]);
      [field setStringValue: [NSString stringWithFormat: @"v%ld", (long)row]];
      return field;
    }
  return criterion;
}

- (NSDictionary *) ruleEditor: (NSRuleEditor *)editor
   predicatePartsForCriterion: (id)criterion
             withDisplayValue: (id)value
                        inRow: (NSInteger)row
{
  if ([criterion isEqual: @"All"])
    {
      return [NSDictionary dictionaryWithObject:
        [NSNumber numberWithUnsignedInteger: NSAndPredicateType]
                                         forKey: NSRuleEditorPredicateCompoundType];
    }
  if ([criterion isEqual: @"Any"])
    {
      return [NSDictionary dictionaryWithObject:
        [NSNumber numberWithUnsignedInteger: NSOrPredicateType]
                                         forKey: NSRuleEditorPredicateCompoundType];
    }
  if ([criterion isEqual: @"name"])
    {
      return [NSDictionary dictionaryWithObject:
        [NSExpression expressionForKeyPath: @"name"]
                                         forKey: NSRuleEditorPredicateLeftExpression];
    }
  if ([criterion isEqual: @"is"])
    {
      return [NSDictionary dictionaryWithObject:
        [NSNumber numberWithUnsignedInteger: NSEqualToPredicateOperatorType]
                                         forKey: NSRuleEditorPredicateOperatorType];
    }
  return [NSDictionary dictionaryWithObject:
    [NSExpression expressionForConstantValue: [value stringValue]]
                                     forKey: NSRuleEditorPredicateRightExpression];
}

- (void) ruleEditorRowsDidChange: (NSNotification *)notification
{
  notifications++;
}

@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSRuleEditor")

  NSRuleEditor *editor;
  Delegate *delegate;

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      SKIP("no GUI backend available")
    }
  NS_ENDHANDLER

  editor = AUTORELEASE([[NSRuleEditor alloc]
    initWithFrame: NSMakeRect(0.0, 0.0, 400.0, 200.0)]);

  /* Defaults. */
  PASS([editor numberOfRows] == 0, "a fresh editor has no rows");
  PASS([editor nestingMode] == NSRuleEditorNestingModeCompound,
       "the nesting mode is compound to start with");
  PASS([editor rowHeight] == 32.0, "the row height is 32 to start with");
  PASS([editor isEditable], "a fresh editor is editable");
  PASS([editor canRemoveAllRows], "all rows can be removed to start with");
  PASS([editor delegate] == nil, "a fresh editor has no delegate");
  PASS([editor rowClass] == [NSMutableDictionary class],
       "rows are dictionaries to start with");
  PASS_EQUAL([editor criteriaKeyPath], @"criteria", "the criteria key path");
  PASS_EQUAL([editor displayValuesKeyPath], @"displayValues",
             "the display values key path");
  PASS_EQUAL([editor rowTypeKeyPath], @"rowType", "the row type key path");
  PASS_EQUAL([editor subrowsKeyPath], @"subrows", "the subrows key path");
  PASS([editor formattingDictionary] == nil,
       "a fresh editor has no formatting dictionary");
  PASS([editor predicate] == nil, "an editor with no rows has no predicate");
  PASS([[editor selectedRowIndexes] count] == 0,
       "a fresh editor has nothing selected");

  delegate = AUTORELEASE([[Delegate alloc] init]);
  [editor setDelegate: delegate];
  PASS([editor delegate] == delegate, "the delegate is the one that was set");
  PASS([editor numberOfRows] == 0,
       "setting a delegate does not add a row by itself");

  /* Compound nesting: the first row brings a compound row with it. */
  notifications = 0;
  [editor addRow: nil];
  PASS([editor numberOfRows] == 2,
       "the first row of a compound editor comes with a row to hold it");
  PASS([editor rowTypeForRow: 0] == NSRuleEditorRowTypeCompound,
       "the holding row is a compound row");
  PASS([editor rowTypeForRow: 1] == NSRuleEditorRowTypeSimple,
       "the row that was added is a simple row");
  PASS([editor parentRowForRow: 0] == -1, "the holding row has no parent");
  PASS([editor parentRowForRow: 1] == 0, "the added row sits under it");
  PASS([[editor subrowIndexesForRow: 0] containsIndex: 1],
       "the holding row counts the added row among its subrows");
  PASS(notifications > 0, "the delegate hears that the rows changed");

  PASS_EQUAL([editor criteriaForRow: 1],
             ([NSArray arrayWithObjects: @"name", @"is", @"value", nil]),
             "the criteria of a row are walked from the delegate");
  PASS([[editor displayValuesForRow: 1] count] == 3,
       "a display value is kept for each criterion");
  PASS([[[editor displayValuesForRow: 1] objectAtIndex: 2]
         isKindOfClass: [NSTextField class]],
       "the display value the delegate made a view for is that view");
  PASS([editor rowForDisplayValue:
         [[editor displayValuesForRow: 1] objectAtIndex: 0]] == 1,
       "a display value is found in the row that holds it");

  PASS_EQUAL([[editor predicateForRow: 1] predicateFormat],
             [[NSPredicate predicateWithFormat: @"name == 'v1'"] predicateFormat],
             "the parts of a row are put together into a comparison");
  PASS_EQUAL([[editor predicate] predicateFormat],
             [[NSPredicate predicateWithFormat: @"name == 'v1'"] predicateFormat],
             "one row under a compound row gives that row's predicate");

  [editor addRow: nil];
  PASS([editor numberOfRows] == 3, "a second row is added under the same row");
  PASS_EQUAL([[editor predicate] predicateFormat],
             [[NSPredicate predicateWithFormat: @"name == 'v1' AND name == 'v2'"]
               predicateFormat],
             "the compound row joins its subrows with the type it was given");

  /* Setting a row from outside. */
  {
    NSArray *criteria = [editor criteriaForRow: 1];
    NSMutableArray *values = [[[editor displayValuesForRow: 1] mutableCopy]
                               autorelease];

    [[values objectAtIndex: 2] setStringValue: @"changed"];
    [editor setCriteria: criteria
       andDisplayValues: values
          forRowAtIndex: 1];
    PASS_EQUAL([[editor predicateForRow: 1] predicateFormat],
               [[NSPredicate predicateWithFormat: @"name == 'changed'"]
                 predicateFormat],
               "the predicate follows what the row was set to");
  }

  /* Selection. */
  [editor selectRowIndexes: [NSIndexSet indexSetWithIndex: 1]
      byExtendingSelection: NO];
  PASS([[editor selectedRowIndexes] containsIndex: 1],
       "a selected row is reported as selected");
  [editor selectRowIndexes: [NSIndexSet indexSetWithIndex: 2]
      byExtendingSelection: YES];
  PASS([[editor selectedRowIndexes] count] == 2,
       "extending the selection keeps what was selected");

  /* Removing the compound row takes its subrows with it. */
  [editor removeRowsAtIndexes: [NSIndexSet indexSetWithIndex: 0]
               includeSubrows: YES];
  PASS([editor numberOfRows] == 0,
       "removing the holding row removes the rows under it");
  PASS([editor predicate] == nil, "an emptied editor has no predicate");

  /* A list of rows, joined with OR. */
  {
    NSRuleEditor *list = AUTORELEASE([[NSRuleEditor alloc]
      initWithFrame: NSMakeRect(0.0, 0.0, 400.0, 200.0)]);

    [list setNestingMode: NSRuleEditorNestingModeList];
    [list setDelegate: delegate];
    [list addRow: nil];
    [list addRow: nil];
    PASS([list numberOfRows] == 2, "a list holds the rows it is given");
    PASS([list rowTypeForRow: 0] == NSRuleEditorRowTypeSimple,
         "a list holds simple rows");
    PASS([list parentRowForRow: 0] == -1, "a list row has no parent");
    PASS_EQUAL([[list predicate] predicateFormat],
               [[NSPredicate predicateWithFormat: @"name == 'v0' OR name == 'v1'"]
                 predicateFormat],
               "the rows of a list are joined with or");
  }

  /* A single row, and no more. */
  {
    NSRuleEditor *single = AUTORELEASE([[NSRuleEditor alloc]
      initWithFrame: NSMakeRect(0.0, 0.0, 400.0, 200.0)]);

    [single setNestingMode: NSRuleEditorNestingModeSingle];
    [single setDelegate: delegate];
    [single addRow: nil];
    [single addRow: nil];
    PASS([single numberOfRows] == 1, "a single editor holds one row only");
    PASS_EQUAL([[single predicate] predicateFormat],
               [[NSPredicate predicateWithFormat: @"name == 'v0'"]
                 predicateFormat],
               "the predicate of a single editor is that row's");
  }

  END_SET("NSRuleEditor")

  DESTROY(arp);
  return 0;
}
