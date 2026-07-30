/* The row templates hold the expressions, operators and options a row of the
   predicate editor can take, build the views for such a row, read a predicate
   out of those views and set them from a predicate.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSExpression.h>
#include <Foundation/NSKeyedArchiver.h>
#include <Foundation/NSPredicate.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPredicateEditorRowTemplate.h>
#include <AppKit/NSTextField.h>

int
main(int argc, char **argv)
{
  START_SET("NSPredicateEditorRowTemplate")

  NSPredicateEditorRowTemplate *plain;
  NSPredicateEditorRowTemplate *template;
  NSPredicateEditorRowTemplate *compound;
  NSPredicateEditorRowTemplate *listed;
  NSArray *left;
  NSArray *operators;
  NSArray *views;
  NSPredicate *predicate;
  NSComparisonPredicate *comparison;

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      NSLog(@"guard caught %@: %@", [localException name],
            [localException reason]);
      SKIP("no GUI backend available")
    }
  NS_ENDHANDLER

  /* A template that was given nothing describes nothing. */
  plain = AUTORELEASE([[NSPredicateEditorRowTemplate alloc] init]);
  PASS([plain leftExpressions] == nil, "a plain template has no left expressions");
  PASS([plain rightExpressions] == nil, "a plain template has no right expressions");
  PASS([plain operators] == nil, "a plain template has no operators");
  PASS([plain compoundTypes] == nil, "a plain template has no compound types");
  PASS([plain modifier] == NSDirectPredicateModifier,
       "a plain template compares directly");
  PASS([plain options] == 0, "a plain template has no options");
  PASS([plain rightExpressionAttributeType] == NSUndefinedAttributeType,
       "a plain template has an undefined attribute type");
  PASS([[plain templateViews] count] == 0, "a plain template has no views");

  left = [NSArray arrayWithObjects:
    [NSExpression expressionForKeyPath: @"name"],
    [NSExpression expressionForKeyPath: @"title"], nil];
  operators = [NSArray arrayWithObjects:
    [NSNumber numberWithUnsignedInteger: NSEqualToPredicateOperatorType],
    [NSNumber numberWithUnsignedInteger: NSContainsPredicateOperatorType], nil];

  template = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
    initWithLeftExpressions: left
rightExpressionAttributeType: NSStringAttributeType
                   modifier: NSDirectPredicateModifier
                  operators: operators
                    options: NSCaseInsensitivePredicateOption]);

  PASS_EQUAL([template leftExpressions], left,
             "the left expressions are the ones the template was given");
  PASS([template rightExpressions] == nil,
       "a template built with an attribute type has no right expressions");
  PASS([template rightExpressionAttributeType] == NSStringAttributeType,
       "the attribute type is the one the template was given");
  PASS([template options] == NSCaseInsensitivePredicateOption,
       "the options are the ones the template was given");

  views = [template templateViews];
  PASS([views count] == 3, "a comparison row has three views");
  PASS([[views objectAtIndex: 0] isKindOfClass: [NSPopUpButton class]],
       "the left expressions are shown in a pop up button");
  PASS([[views objectAtIndex: 1] isKindOfClass: [NSPopUpButton class]],
       "the operators are shown in a pop up button");
  PASS([[views objectAtIndex: 2] isKindOfClass: [NSTextField class]],
       "a string is typed into a text field");
  PASS_EQUAL([[views objectAtIndex: 0] itemTitles],
             ([NSArray arrayWithObjects: @"name", @"title", nil]),
             "the left pop up button lists the key paths");
  PASS_EQUAL([[views objectAtIndex: 1] itemTitles],
             ([NSArray arrayWithObjects: @"is", @"contains", nil]),
             "the operator pop up button names the operators");
  PASS([template templateViews] == views,
       "the same views are returned each time");

  /* The predicate is read out of the views. */
  predicate = [template predicateWithSubpredicates: nil];
  PASS([predicate isKindOfClass: [NSComparisonPredicate class]],
       "a comparison template builds a comparison predicate");
  comparison = (NSComparisonPredicate *)predicate;
  PASS_EQUAL([[comparison leftExpression] keyPath], @"name",
             "the first left expression is used");
  PASS([comparison predicateOperatorType] == NSEqualToPredicateOperatorType,
       "the first operator is used");
  PASS([comparison options] == NSCaseInsensitivePredicateOption,
       "the options of the template are used");
  PASS([comparison comparisonPredicateModifier] == NSDirectPredicateModifier,
       "the modifier of the template is used");
  PASS_EQUAL([[comparison rightExpression] constantValue], @"",
             "an empty text field gives an empty string");

  /* Matching. */
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"name CONTAINS[c] 'x'"]] == 0.81,
       "a predicate the template can hold matches");
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"name CONTAINS 'x'"]] == 0.729,
       "a predicate that differs only in its options matches less well");
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"other CONTAINS[c] 'x'"]] == 0.0,
       "a predicate on another key path does not match");
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"name BEGINSWITH[c] 'x'"]] == 0.0,
       "a predicate with an operator the template lacks does not match");
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"name ==[c] other"]] == 0.0,
       "a comparison of two key paths does not match");
  PASS([template matchForPredicate:
         [NSPredicate predicateWithFormat: @"name == 'a' AND title == 'b'"]] == 0.0,
       "a compound predicate does not match a comparison template");

  {
    BOOL raised = NO;

    NS_DURING
      {
        [template matchForPredicate: nil];
      }
    NS_HANDLER
      {
        raised = YES;
      }
    NS_ENDHANDLER
    PASS(raised == YES, "matching a nil predicate raises");
  }

  /* Setting the row from a predicate, then reading it back. */
  [template setPredicate:
    [NSPredicate predicateWithFormat: @"title CONTAINS[c] 'x'"]];
  PASS([[views objectAtIndex: 0] indexOfSelectedItem] == 1,
       "the left pop up button follows the predicate");
  PASS([[views objectAtIndex: 1] indexOfSelectedItem] == 1,
       "the operator pop up button follows the predicate");
  PASS_EQUAL([[views objectAtIndex: 2] stringValue], @"x",
             "the text field follows the predicate");

  comparison = (NSComparisonPredicate *)[template predicateWithSubpredicates: nil];
  PASS_EQUAL([[comparison leftExpression] keyPath], @"title",
             "the predicate read back uses the chosen left expression");
  PASS([comparison predicateOperatorType] == NSContainsPredicateOperatorType,
       "the predicate read back uses the chosen operator");
  PASS_EQUAL([[comparison rightExpression] constantValue], @"x",
             "the predicate read back uses the text that was set");

  /* Subpredicates are only displayable for a compound predicate. */
  PASS([template displayableSubpredicatesOfPredicate:
         [NSPredicate predicateWithFormat: @"name == 'a'"]] == nil,
       "a comparison predicate has no displayable subpredicates");
  PASS([[template displayableSubpredicatesOfPredicate:
          [NSPredicate predicateWithFormat: @"name == 'a' AND title == 'b'"]]
         count] == 2,
       "a compound predicate shows its subpredicates");

  /* A compound template. */
  compound = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
    initWithCompoundTypes: ([NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedInteger: NSAndPredicateType],
      [NSNumber numberWithUnsignedInteger: NSOrPredicateType], nil])]);

  PASS([[compound compoundTypes] count] == 2,
       "the compound types are the ones the template was given");
  PASS([compound leftExpressions] == nil,
       "a compound template has no left expressions");
  views = [compound templateViews];
  PASS([views count] == 2, "a compound row has two views");
  PASS_EQUAL([[views objectAtIndex: 0] itemTitles],
             ([NSArray arrayWithObjects: @"All", @"Any", nil]),
             "the compound types are named in a pop up button");

  predicate = [compound predicateWithSubpredicates:
    ([NSArray arrayWithObjects:
      [NSPredicate predicateWithFormat: @"a == 1"],
      [NSPredicate predicateWithFormat: @"b == 2"], nil])];
  PASS([predicate isKindOfClass: [NSCompoundPredicate class]],
       "a compound template builds a compound predicate");
  PASS([(NSCompoundPredicate *)predicate compoundPredicateType]
         == NSAndPredicateType,
       "the first compound type is used");
  PASS([[(NSCompoundPredicate *)predicate subpredicates] count] == 2,
       "the subpredicates are kept");
  PASS([compound matchForPredicate:
         [NSPredicate predicateWithFormat: @"a == 1 AND b == 2"]] == 0.5,
       "a compound predicate of a type the template holds matches");
  PASS([compound matchForPredicate:
         [NSPredicate predicateWithFormat: @"a == 1"]] == 0.0,
       "a comparison does not match a compound template");

  /* Right expressions given as a list are chosen from a pop up button. */
  listed = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
    initWithLeftExpressions: [NSArray arrayWithObject:
                               [NSExpression expressionForKeyPath: @"state"]]
           rightExpressions: ([NSArray arrayWithObjects:
                               [NSExpression expressionForConstantValue: @"open"],
                               [NSExpression expressionForConstantValue: @"shut"],
                               nil])
                   modifier: NSDirectPredicateModifier
                  operators: [NSArray arrayWithObject:
                               [NSNumber numberWithUnsignedInteger:
                                 NSEqualToPredicateOperatorType]]
                    options: 0]);

  views = [listed templateViews];
  PASS([[views objectAtIndex: 2] isKindOfClass: [NSPopUpButton class]],
       "listed right expressions are shown in a pop up button");
  PASS_EQUAL([[views objectAtIndex: 2] itemTitles],
             ([NSArray arrayWithObjects: @"open", @"shut", nil]),
             "the right pop up button lists the constants");
  comparison = (NSComparisonPredicate *)[listed predicateWithSubpredicates: nil];
  PASS_EQUAL([[comparison rightExpression] constantValue], @"open",
             "the chosen right expression is used");

  /* A date is edited in a date picker. */
  {
    NSPredicateEditorRowTemplate *dated;

    dated = AUTORELEASE([[NSPredicateEditorRowTemplate alloc]
      initWithLeftExpressions: [NSArray arrayWithObject:
                                 [NSExpression expressionForKeyPath: @"due"]]
 rightExpressionAttributeType: NSDateAttributeType
                     modifier: NSDirectPredicateModifier
                    operators: [NSArray arrayWithObject:
                                 [NSNumber numberWithUnsignedInteger:
                                   NSLessThanPredicateOperatorType]]
                      options: 0]);
    PASS([[[dated templateViews] objectAtIndex: 2]
           isKindOfClass: [NSDatePicker class]],
         "a date is edited in a date picker");
    PASS_EQUAL([[[dated templateViews] objectAtIndex: 1] itemTitles],
               [NSArray arrayWithObject: @"is less than"],
               "the operator is named");
  }

  /* Archiving a template is not tested here: an expression cannot be
     archived yet, so a template holding one cannot be either. */

  /* Copying. */
  {
    NSPredicateEditorRowTemplate *copy = AUTORELEASE([template copy]);

    PASS_EQUAL([copy leftExpressions], left, "a copy keeps the left expressions");
    PASS([copy options] == NSCaseInsensitivePredicateOption,
         "a copy keeps the options");
    PASS([[copy templateViews] count] == 3, "a copy builds its own views");
    PASS([copy templateViews] != [template templateViews],
         "a copy does not share the views of the original");
  }

  END_SET("NSPredicateEditorRowTemplate")

  return 0;
}
