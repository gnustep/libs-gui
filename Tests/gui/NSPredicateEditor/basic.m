/* A predicate editor builds its rows from its row templates: each row shows
   the views of the template it was made from, and the predicate of the editor
   is read back out of those rows.  Setting a predicate on the editor makes
   the rows that display it.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSExpression.h>
#include <Foundation/NSPredicate.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPredicateEditor.h>
#include <AppKit/NSPredicateEditorRowTemplate.h>
#include <AppKit/NSTextField.h>

int
main(int argc, char **argv)
{
  START_SET("NSPredicateEditor")

  NSPredicateEditor *editor;
  NSPredicateEditorRowTemplate *comparison;
  NSPredicateEditorRowTemplate *compound;
  NSArray *templates;

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      SKIP("no GUI backend available")
    }
  NS_ENDHANDLER

  editor = AUTORELEASE([[NSPredicateEditor alloc]
    initWithFrame: NSMakeRect(0.0, 0.0, 500.0, 300.0)]);

  /* Defaults. */
  PASS([[editor rowTemplates] count] == 1,
       "an editor starts out with one row template");
  PASS([[[[editor rowTemplates] objectAtIndex: 0] compoundTypes] count] == 3,
       "that template holds the three compound types");
  PASS([editor numberOfRows] == 0, "a fresh editor has no rows");
  PASS([editor predicate] == nil, "a fresh editor has no predicate");
  PASS([editor objectValue] == nil, "the value of a fresh editor is nothing");
  PASS([editor delegate] == nil, "an editor needs no delegate");

  compound = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
    initWithCompoundTypes: ([NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedInteger: NSAndPredicateType],
      [NSNumber numberWithUnsignedInteger: NSOrPredicateType], nil])]);
  comparison = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
    initWithLeftExpressions: ([NSArray arrayWithObjects:
                               [NSExpression expressionForKeyPath: @"name"],
                               [NSExpression expressionForKeyPath: @"size"],
                               nil])
rightExpressionAttributeType: NSStringAttributeType
                   modifier: NSDirectPredicateModifier
                  operators: ([NSArray arrayWithObjects:
                               [NSNumber numberWithUnsignedInteger:
                                 NSEqualToPredicateOperatorType],
                               [NSNumber numberWithUnsignedInteger:
                                 NSContainsPredicateOperatorType], nil])
                    options: 0]);

  templates = [NSArray arrayWithObjects: compound, comparison, nil];
  [editor setRowTemplates: templates];
  PASS_EQUAL([editor rowTemplates], templates,
             "the row templates are the ones that were set");
  PASS([editor numberOfRows] == 0,
       "setting the row templates does not make a row");

  /* Adding a row uses the templates. */
  [editor addRow: nil];
  PASS([editor numberOfRows] == 2,
       "the first row comes with a row to hold it");
  PASS([editor rowTypeForRow: 0] == NSRuleEditorRowTypeCompound,
       "the holding row is a compound row");
  PASS([[editor displayValuesForRow: 0] count] == 2,
       "the holding row shows the views of the compound template");
  PASS([[editor displayValuesForRow: 1] count] == 3,
       "the row shows the views of the comparison template");
  PASS([[[editor displayValuesForRow: 1] objectAtIndex: 2]
         isKindOfClass: [NSTextField class]],
       "the right hand side of the row is a field");

  PASS_EQUAL([[editor predicateForRow: 1] predicateFormat],
             ([[NSPredicate predicateWithFormat: @"name == %@", @""]
                predicateFormat]),
             "the predicate of a row is read out of its views");
  PASS_EQUAL([[editor predicate] predicateFormat],
             ([[NSPredicate predicateWithFormat: @"name == %@", @""]
                predicateFormat]),
             "one row under the holding row gives that row's predicate");
  PASS_EQUAL([[editor objectValue] predicateFormat],
             [[editor predicate] predicateFormat],
             "the value of the editor is its predicate");

  /* Each row gets views of its own. */
  [editor addRow: nil];
  PASS([editor numberOfRows] == 3, "a second row is added");
  PASS([[editor displayValuesForRow: 1] objectAtIndex: 2]
         != [[editor displayValuesForRow: 2] objectAtIndex: 2],
       "each row has views of its own");

  {
    NSTextField *field = [[editor displayValuesForRow: 2] objectAtIndex: 2];

    [field setStringValue: @"typed"];
    PASS_EQUAL([[editor predicateForRow: 2] predicateFormat],
               [[NSPredicate predicateWithFormat: @"name == 'typed'"]
                 predicateFormat],
               "what is typed into a row shows up in its predicate");
    PASS_EQUAL([[editor predicate] predicateFormat],
               ([[NSPredicate predicateWithFormat:
                   @"name == %@ AND name == %@", @"", @"typed"]
                  predicateFormat]),
               "the holding row joins the rows under it");
  }

  /* Showing a predicate that already exists. */
  [editor setObjectValue:
    [NSPredicate predicateWithFormat: @"name == 'a' AND size CONTAINS 'b'"]];
  PASS([editor numberOfRows] == 3,
       "a compound predicate makes a row for itself and one for each part");
  PASS([editor rowTypeForRow: 0] == NSRuleEditorRowTypeCompound,
       "the predicate that holds the others is shown by a compound row");
  PASS_EQUAL([[editor predicate] predicateFormat],
             [[NSPredicate predicateWithFormat:
                @"name == 'a' AND size CONTAINS 'b'"] predicateFormat],
             "the predicate that was set is read back");

  [editor setObjectValue: nil];
  PASS([editor numberOfRows] == 0, "setting no predicate empties the editor");
  PASS([editor predicate] == nil, "an emptied editor has no predicate");

  END_SET("NSPredicateEditor")

  return 0;
}
