/** <title>NSPredicateEditorRowTemplate</title>

   <abstract>The template rows for the predicate editor</abstract>

   Copyright (C) 2020 Free Software Foundation, Inc.

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date:   January 2020

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSDatePicker.h"
#import "AppKit/NSPopUpButton.h"
#import "AppKit/NSPredicateEditorRowTemplate.h"
#import "AppKit/NSTextField.h"
#import "GSGuiPrivate.h"

/* The views are created at this size; the rule editor lays them out. */
static const CGFloat viewWidth = 100.0;
static const CGFloat viewHeight = 22.0;

/* How well a predicate fits this template.  A comparison the template can
   represent scores 0.81, one that differs only in its options 0.729, and a
   compound predicate of a type the template holds 0.5, which is what OS X
   reports for the same templates.
*/
static const double comparisonMatch = 0.81;
static const double comparisonMatchOtherOptions = 0.729;
static const double compoundMatch = 0.5;

@interface NSPredicateEditorRowTemplate (Private)
- (NSPopUpButton *) _popUpButtonWithTitles: (NSArray *)titles;
- (NSPopUpButton *) _popUpButtonAtIndex: (NSUInteger)index;
- (NSString *) _titleForExpression: (NSExpression *)expression;
- (NSString *) _titleForOperator: (NSPredicateOperatorType)type;
- (NSString *) _titleForCompoundType: (NSCompoundPredicateType)type;
- (NSView *) _rightView;
- (NSExpression *) _rightExpressionFromView;
- (void) _setRightViewToExpression: (NSExpression *)expression;
@end

@implementation NSPredicateEditorRowTemplate

+ (NSArray *) templatesWithAttributeKeyPaths: (NSArray *)paths
                         inEntityDescription: (NSEntityDescription *)entityDesc
{
  /* Entity descriptions belong to CoreData, which GNUstep does not have. */
  return nil;
}

- (id) initWithLeftExpressions: (NSArray *)leftExprs
              rightExpressions: (NSArray *)rightExprs
                      modifier: (NSComparisonPredicateModifier)modif
                     operators: (NSArray *)ops
                       options: (NSUInteger)opts
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  ASSIGNCOPY(_leftExpressions, leftExprs);
  ASSIGNCOPY(_rightExpressions, rightExprs);
  ASSIGNCOPY(_operators, ops);
  _compoundTypes = nil;
  _views = nil;
  _rightExpressionAttributeType = NSUndefinedAttributeType;
  _modifier = modif;
  _options = opts;

  return self;
}

- (id) initWithLeftExpressions: (NSArray *)leftExprs
  rightExpressionAttributeType: (NSAttributeType)attrType
                      modifier: (NSComparisonPredicateModifier)modif
                     operators: (NSArray *)ops
                       options: (NSUInteger)opts
{
  self = [self initWithLeftExpressions: leftExprs
                      rightExpressions: nil
                              modifier: modif
                             operators: ops
                               options: opts];
  if (self != nil)
    {
      _rightExpressionAttributeType = attrType;
    }

  return self;
}

- (id) initWithCompoundTypes: (NSArray *)types
{
  self = [self initWithLeftExpressions: nil
                      rightExpressions: nil
                              modifier: NSDirectPredicateModifier
                             operators: nil
                               options: 0];
  if (self != nil)
    {
      ASSIGNCOPY(_compoundTypes, types);
    }

  return self;
}

- (void) dealloc
{
  RELEASE(_leftExpressions);
  RELEASE(_rightExpressions);
  RELEASE(_operators);
  RELEASE(_compoundTypes);
  RELEASE(_views);
  [super dealloc];
}

- (NSArray *) compoundTypes
{
  return _compoundTypes;
}

- (NSArray *) leftExpressions
{
  return _leftExpressions;
}

- (NSArray *) rightExpressions
{
  return _rightExpressions;
}

- (NSAttributeType) rightExpressionAttributeType
{
  return _rightExpressionAttributeType;
}

- (NSComparisonPredicateModifier) modifier
{
  return _modifier;
}

- (NSArray *) operators
{
  return _operators;
}

- (NSUInteger) options
{
  return _options;
}

- (NSArray *) templateViews
{
  if (_views != nil)
    {
      return _views;
    }

  if (_compoundTypes != nil)
    {
      NSMutableArray *titles;
      NSEnumerator *enumerator;
      NSNumber *type;

      titles = [NSMutableArray arrayWithCapacity: [_compoundTypes count]];
      enumerator = [_compoundTypes objectEnumerator];
      while ((type = [enumerator nextObject]) != nil)
        {
          [titles addObject:
            [self _titleForCompoundType: [type unsignedIntegerValue]]];
        }

      _views = [[NSArray alloc] initWithObjects:
        [self _popUpButtonWithTitles: titles],
        [self _popUpButtonWithTitles:
          [NSArray arrayWithObject: _(@"of the following are true")]],
        nil];
    }
  else if (_leftExpressions != nil)
    {
      NSMutableArray *leftTitles;
      NSMutableArray *operatorTitles;
      NSEnumerator *enumerator;
      NSExpression *expression;
      NSNumber *type;

      leftTitles = [NSMutableArray arrayWithCapacity: [_leftExpressions count]];
      enumerator = [_leftExpressions objectEnumerator];
      while ((expression = [enumerator nextObject]) != nil)
        {
          [leftTitles addObject: [self _titleForExpression: expression]];
        }

      operatorTitles = [NSMutableArray arrayWithCapacity: [_operators count]];
      enumerator = [_operators objectEnumerator];
      while ((type = [enumerator nextObject]) != nil)
        {
          [operatorTitles addObject:
            [self _titleForOperator: [type unsignedIntegerValue]]];
        }

      _views = [[NSArray alloc] initWithObjects:
        [self _popUpButtonWithTitles: leftTitles],
        [self _popUpButtonWithTitles: operatorTitles],
        [self _rightView],
        nil];
    }
  else
    {
      _views = [[NSArray alloc] init];
    }

  return _views;
}

- (NSArray *) displayableSubpredicatesOfPredicate: (NSPredicate *)pred
{
  if ([pred isKindOfClass: [NSCompoundPredicate class]])
    {
      return [(NSCompoundPredicate *)pred subpredicates];
    }

  return nil;
}

- (double) matchForPredicate: (NSPredicate *)pred
{
  if (pred == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"%@ was passed a nil predicate",
        NSStringFromSelector(_cmd)];
    }

  if (_compoundTypes != nil)
    {
      NSCompoundPredicateType type;

      if (![pred isKindOfClass: [NSCompoundPredicate class]])
        {
          return 0.0;
        }

      type = [(NSCompoundPredicate *)pred compoundPredicateType];
      if ([_compoundTypes containsObject:
            [NSNumber numberWithUnsignedInteger: type]])
        {
          return compoundMatch;
        }

      return 0.0;
    }

  if ([pred isKindOfClass: [NSComparisonPredicate class]])
    {
      NSComparisonPredicate *comparison = (NSComparisonPredicate *)pred;
      NSExpression *right = [comparison rightExpression];

      if (![_leftExpressions containsObject: [comparison leftExpression]])
        {
          return 0.0;
        }

      if (![_operators containsObject: [NSNumber numberWithUnsignedInteger:
             [comparison predicateOperatorType]]])
        {
          return 0.0;
        }

      if (_rightExpressions != nil)
        {
          if (![_rightExpressions containsObject: right])
            {
              return 0.0;
            }
        }
      else if ([right expressionType] != NSConstantValueExpressionType)
        {
          return 0.0;
        }

      if ([comparison options] != _options)
        {
          return comparisonMatchOtherOptions;
        }

      return comparisonMatch;
    }

  return 0.0;
}

- (NSPredicate *) predicateWithSubpredicates: (NSArray *)subpred
{
  if (_compoundTypes != nil)
    {
      NSInteger index = [[self _popUpButtonAtIndex: 0] indexOfSelectedItem];
      NSCompoundPredicateType type;

      if (index < 0 || (NSUInteger)index >= [_compoundTypes count])
        {
          return nil;
        }

      type = [[_compoundTypes objectAtIndex: index] unsignedIntegerValue];

      switch (type)
        {
          case NSNotPredicateType:
            return [NSCompoundPredicate notPredicateWithSubpredicate:
              ([subpred count] > 0 ? [subpred objectAtIndex: 0] : nil)];
          case NSOrPredicateType:
            return [NSCompoundPredicate orPredicateWithSubpredicates: subpred];
          case NSAndPredicateType:
          default:
            return [NSCompoundPredicate andPredicateWithSubpredicates: subpred];
        }
    }

  if (_leftExpressions != nil)
    {
      NSInteger leftIndex = [[self _popUpButtonAtIndex: 0] indexOfSelectedItem];
      NSInteger operatorIndex
        = [[self _popUpButtonAtIndex: 1] indexOfSelectedItem];
      NSPredicateOperatorType type;

      if (leftIndex < 0 || (NSUInteger)leftIndex >= [_leftExpressions count]
        || operatorIndex < 0 || (NSUInteger)operatorIndex >= [_operators count])
        {
          return nil;
        }

      type = [[_operators objectAtIndex: operatorIndex] unsignedIntegerValue];

      return [NSComparisonPredicate
        predicateWithLeftExpression: [_leftExpressions objectAtIndex: leftIndex]
                    rightExpression: [self _rightExpressionFromView]
                           modifier: _modifier
                               type: type
                            options: _options];
    }

  return nil;
}

- (void) setPredicate: (NSPredicate *)pred
{
  if (_compoundTypes != nil)
    {
      NSUInteger index;

      if (![pred isKindOfClass: [NSCompoundPredicate class]])
        {
          return;
        }

      index = [_compoundTypes indexOfObject:
        [NSNumber numberWithUnsignedInteger:
          [(NSCompoundPredicate *)pred compoundPredicateType]]];
      if (index != NSNotFound)
        {
          [[self _popUpButtonAtIndex: 0] selectItemAtIndex: index];
        }

      return;
    }

  if ([pred isKindOfClass: [NSComparisonPredicate class]])
    {
      NSComparisonPredicate *comparison = (NSComparisonPredicate *)pred;
      NSUInteger index;

      index = [_leftExpressions indexOfObject: [comparison leftExpression]];
      if (index != NSNotFound)
        {
          [[self _popUpButtonAtIndex: 0] selectItemAtIndex: index];
        }

      index = [_operators indexOfObject: [NSNumber numberWithUnsignedInteger:
        [comparison predicateOperatorType]]];
      if (index != NSNotFound)
        {
          [[self _popUpButtonAtIndex: 1] selectItemAtIndex: index];
        }

      [self _setRightViewToExpression: [comparison rightExpression]];
    }
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _leftExpressions forKey: @"NSLeftExpressions"];
      [aCoder encodeObject: _rightExpressions forKey: @"NSRightExpressions"];
      [aCoder encodeObject: _operators forKey: @"NSOperators"];
      [aCoder encodeObject: _compoundTypes forKey: @"NSCompoundTypes"];
      [aCoder encodeInteger: _rightExpressionAttributeType
                     forKey: @"NSRightExpressionAttributeType"];
      [aCoder encodeInteger: _modifier forKey: @"NSModifier"];
      [aCoder encodeInteger: _options forKey: @"NSOptions"];
    }
  else
    {
      NSUInteger attributeType = _rightExpressionAttributeType;
      NSUInteger modifier = _modifier;

      [aCoder encodeObject: _leftExpressions];
      [aCoder encodeObject: _rightExpressions];
      [aCoder encodeObject: _operators];
      [aCoder encodeObject: _compoundTypes];
      [aCoder encodeValueOfObjCType: @encode(NSUInteger) at: &attributeType];
      [aCoder encodeValueOfObjCType: @encode(NSUInteger) at: &modifier];
      [aCoder encodeValueOfObjCType: @encode(NSUInteger) at: &_options];
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  if ([aDecoder allowsKeyedCoding])
    {
      ASSIGN(_leftExpressions,
        [aDecoder decodeObjectForKey: @"NSLeftExpressions"]);
      ASSIGN(_rightExpressions,
        [aDecoder decodeObjectForKey: @"NSRightExpressions"]);
      ASSIGN(_operators, [aDecoder decodeObjectForKey: @"NSOperators"]);
      ASSIGN(_compoundTypes, [aDecoder decodeObjectForKey: @"NSCompoundTypes"]);
      _rightExpressionAttributeType
        = [aDecoder decodeIntegerForKey: @"NSRightExpressionAttributeType"];
      _modifier = [aDecoder decodeIntegerForKey: @"NSModifier"];
      _options = [aDecoder decodeIntegerForKey: @"NSOptions"];
    }
  else
    {
      NSUInteger attributeType;
      NSUInteger modifier;

      ASSIGN(_leftExpressions, [aDecoder decodeObject]);
      ASSIGN(_rightExpressions, [aDecoder decodeObject]);
      ASSIGN(_operators, [aDecoder decodeObject]);
      ASSIGN(_compoundTypes, [aDecoder decodeObject]);
      [aDecoder decodeValueOfObjCType: @encode(NSUInteger) at: &attributeType];
      [aDecoder decodeValueOfObjCType: @encode(NSUInteger) at: &modifier];
      [aDecoder decodeValueOfObjCType: @encode(NSUInteger) at: &_options];
      _rightExpressionAttributeType = attributeType;
      _modifier = modifier;
    }

  return self;
}

//
// NSCopying protocol
//
- (id) copyWithZone: (NSZone *)zone
{
  NSPredicateEditorRowTemplate *copy;

  copy = [[[self class] allocWithZone: zone]
    initWithLeftExpressions: _leftExpressions
           rightExpressions: _rightExpressions
                   modifier: _modifier
                  operators: _operators
                    options: _options];
  if (copy != nil)
    {
      copy->_rightExpressionAttributeType = _rightExpressionAttributeType;
      ASSIGNCOPY(copy->_compoundTypes, _compoundTypes);
    }

  return copy;
}

@end

@implementation NSPredicateEditorRowTemplate (Private)

- (NSPopUpButton *) _popUpButtonWithTitles: (NSArray *)titles
{
  NSPopUpButton *button;

  button = [[NSPopUpButton alloc]
    initWithFrame: NSMakeRect(0.0, 0.0, viewWidth, viewHeight)
        pullsDown: NO];
  [button addItemsWithTitles: titles];
  if ([titles count] > 0)
    {
      [button selectItemAtIndex: 0];
    }

  return AUTORELEASE(button);
}

- (NSPopUpButton *) _popUpButtonAtIndex: (NSUInteger)index
{
  NSArray *views = [self templateViews];

  if (index >= [views count])
    {
      return nil;
    }

  return [views objectAtIndex: index];
}

- (NSString *) _titleForExpression: (NSExpression *)expression
{
  if ([expression expressionType] == NSKeyPathExpressionType)
    {
      return [expression keyPath];
    }
  else if ([expression expressionType] == NSConstantValueExpressionType)
    {
      return [[expression constantValue] description];
    }

  return [expression description];
}

- (NSString *) _titleForOperator: (NSPredicateOperatorType)type
{
  switch (type)
    {
      case NSLessThanPredicateOperatorType:
        return _(@"is less than");
      case NSLessThanOrEqualToPredicateOperatorType:
        return _(@"is less than or equal to");
      case NSGreaterThanPredicateOperatorType:
        return _(@"is greater than");
      case NSGreaterThanOrEqualToPredicateOperatorType:
        return _(@"is greater than or equal to");
      case NSEqualToPredicateOperatorType:
        return _(@"is");
      case NSNotEqualToPredicateOperatorType:
        return _(@"is not");
      case NSMatchesPredicateOperatorType:
        return _(@"matches");
      case NSLikePredicateOperatorType:
        return _(@"is like");
      case NSBeginsWithPredicateOperatorType:
        return _(@"begins with");
      case NSEndsWithPredicateOperatorType:
        return _(@"ends with");
      case NSInPredicateOperatorType:
        return _(@"in");
      case NSContainsPredicateOperatorType:
        return _(@"contains");
      case NSBetweenPredicateOperatorType:
        return _(@"between");
      default:
        return _(@"is");
    }
}

- (NSString *) _titleForCompoundType: (NSCompoundPredicateType)type
{
  switch (type)
    {
      case NSOrPredicateType:
        return _(@"Any");
      case NSNotPredicateType:
        return _(@"None");
      case NSAndPredicateType:
      default:
        return _(@"All");
    }
}

- (NSView *) _rightView
{
  if (_rightExpressions != nil)
    {
      NSMutableArray *titles;
      NSEnumerator *enumerator;
      NSExpression *expression;

      titles = [NSMutableArray arrayWithCapacity: [_rightExpressions count]];
      enumerator = [_rightExpressions objectEnumerator];
      while ((expression = [enumerator nextObject]) != nil)
        {
          [titles addObject: [self _titleForExpression: expression]];
        }

      return [self _popUpButtonWithTitles: titles];
    }

  if (_rightExpressionAttributeType == NSDateAttributeType)
    {
      return AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0.0, 0.0, viewWidth, viewHeight)]);
    }

  return AUTORELEASE([[NSTextField alloc]
    initWithFrame: NSMakeRect(0.0, 0.0, viewWidth, viewHeight)]);
}

- (NSExpression *) _rightExpressionFromView
{
  NSArray *views = [self templateViews];
  NSView *view;
  NSString *value;

  if ([views count] < 3)
    {
      return nil;
    }

  view = [views objectAtIndex: 2];

  if (_rightExpressions != nil)
    {
      NSInteger index = [(NSPopUpButton *)view indexOfSelectedItem];

      if (index < 0 || (NSUInteger)index >= [_rightExpressions count])
        {
          return nil;
        }

      return [_rightExpressions objectAtIndex: index];
    }

  if ([view isKindOfClass: [NSDatePicker class]])
    {
      return [NSExpression expressionForConstantValue:
        [(NSDatePicker *)view dateValue]];
    }

  value = [(NSTextField *)view stringValue];

  switch (_rightExpressionAttributeType)
    {
      case NSInteger16AttributeType:
      case NSInteger32AttributeType:
      case NSInteger64AttributeType:
      case NSBooleanAttributeType:
        return [NSExpression expressionForConstantValue:
          [NSNumber numberWithInteger: [value integerValue]]];
      case NSDoubleAttributeType:
      case NSFloatAttributeType:
        return [NSExpression expressionForConstantValue:
          [NSNumber numberWithDouble: [value doubleValue]]];
      case NSDecimalAttributeType:
        if ([value length] == 0)
          {
            return [NSExpression expressionForConstantValue:
              [NSDecimalNumber notANumber]];
          }
        return [NSExpression expressionForConstantValue:
          [NSDecimalNumber decimalNumberWithString: value]];
      default:
        return [NSExpression expressionForConstantValue: value];
    }
}

- (void) _setRightViewToExpression: (NSExpression *)expression
{
  NSArray *views = [self templateViews];
  NSView *view;
  id value;

  if ([views count] < 3 || expression == nil)
    {
      return;
    }

  view = [views objectAtIndex: 2];

  if (_rightExpressions != nil)
    {
      NSUInteger index = [_rightExpressions indexOfObject: expression];

      if (index != NSNotFound)
        {
          [(NSPopUpButton *)view selectItemAtIndex: index];
        }

      return;
    }

  if ([expression expressionType] != NSConstantValueExpressionType)
    {
      return;
    }

  value = [expression constantValue];

  if ([view isKindOfClass: [NSDatePicker class]])
    {
      if ([value isKindOfClass: [NSDate class]])
        {
          [(NSDatePicker *)view setDateValue: value];
        }

      return;
    }

  [(NSTextField *)view setStringValue: [value description]];
}

@end
