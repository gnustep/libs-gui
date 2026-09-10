/** <title>NSRuleEditor</title>

   <abstract>The rule editor class</abstract>

   Copyright (C) 2020 Free Software Foundation, Inc.

   Created by Fabian Spillner on 03.12.07.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSButton.h"
#import "AppKit/NSRuleEditor.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSView.h"
#import "GSGuiPrivate.h"

static const CGFloat defaultRowHeight = 32.0;
static const CGFloat rowInset = 4.0;
static const CGFloat viewGap = 4.0;
static const CGFloat indentPerLevel = 20.0;
static const CGFloat buttonWidth = 24.0;

/* One row of the editor: what it was built from, what it shows, and where it
 * sits in the tree.
 */
@interface GSRuleEditorRow : NSObject
{
@public
  NSMutableArray         *criteria;
  NSMutableArray         *displayValues;
  NSRuleEditorRowType     rowType;
  GSRuleEditorRow        *parent;	// not retained
}
@end

@implementation GSRuleEditorRow

- (id) init
{
  if ((self = [super init]) != nil)
    {
      criteria = [NSMutableArray new];
      displayValues = [NSMutableArray new];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(criteria);
  RELEASE(displayValues);
  [super dealloc];
}

@end

@interface NSRuleEditor (Private)
- (GSRuleEditorRow *) _rowAtIndex: (NSInteger)index;
- (GSRuleEditorRow *) _rootRow;
- (void) _populateRow: (GSRuleEditorRow *)row;
- (NSPredicate *) _predicateForRow: (GSRuleEditorRow *)row;
- (NSDictionary *) _partsForRow: (GSRuleEditorRow *)row;
- (NSArray *) _childRowsOf: (GSRuleEditorRow *)row;
- (void) _rowsDidChange;
- (void) _reloadRowViews;
@end

@implementation NSRuleEditor

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self == nil)
    {
      return nil;
    }

  _rows = [[NSMutableArray alloc] init];
  _selectedRows = [[NSMutableIndexSet alloc] init];
  ASSIGN(_criteriaKeyPath, @"criteria");
  ASSIGN(_displayValuesKeyPath, @"displayValues");
  ASSIGN(_rowTypeKeyPath, @"rowType");
  ASSIGN(_subrowsKeyPath, @"subrows");
  _rowClass = [NSMutableDictionary class];
  _rowHeight = defaultRowHeight;
  _nestingMode = NSRuleEditorNestingModeCompound;
  _editable = YES;
  _canRemoveAllRows = YES;

  return self;
}

- (void) dealloc
{
  RELEASE(_rows);
  RELEASE(_selectedRows);
  RELEASE(_criteriaKeyPath);
  RELEASE(_displayValuesKeyPath);
  RELEASE(_rowTypeKeyPath);
  RELEASE(_subrowsKeyPath);
  RELEASE(_formattingDictionary);
  RELEASE(_formattingStringsFilename);
  [super dealloc];
}

//
// Configuring
//
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)delegate
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  if (_delegate == delegate)
    {
      return;
    }

  /* The delegate hears about the rows through the notification. */
  if (_delegate != nil)
    {
      [center removeObserver: _delegate
                        name: NSRuleEditorRowsDidChangeNotification
                      object: self];
    }

  _delegate = delegate;

  if (_delegate != nil
    && [_delegate respondsToSelector: @selector(ruleEditorRowsDidChange:)])
    {
      [center addObserver: _delegate
                 selector: @selector(ruleEditorRowsDidChange:)
                     name: NSRuleEditorRowsDidChangeNotification
                   object: self];
    }
}

- (BOOL) isEditable
{
  return _editable;
}

- (void) setEditable: (BOOL)flag
{
  _editable = flag;
}

- (BOOL) canRemoveAllRows
{
  return _canRemoveAllRows;
}

- (void) setCanRemoveAllRows: (BOOL)flag
{
  _canRemoveAllRows = flag;
}

- (NSRuleEditorNestingMode) nestingMode
{
  return _nestingMode;
}

- (void) setNestingMode: (NSRuleEditorNestingMode)mode
{
  _nestingMode = mode;
}

- (CGFloat) rowHeight
{
  return _rowHeight;
}

- (void) setRowHeight: (CGFloat)height
{
  _rowHeight = height;
  [self _reloadRowViews];
}

- (Class) rowClass
{
  return _rowClass;
}

- (void) setRowClass: (Class)rowClass
{
  _rowClass = rowClass;
}

- (NSString *) criteriaKeyPath
{
  return _criteriaKeyPath;
}

- (void) setCriteriaKeyPath: (NSString *)path
{
  ASSIGN(_criteriaKeyPath, path);
}

- (NSString *) displayValuesKeyPath
{
  return _displayValuesKeyPath;
}

- (void) setDisplayValuesKeyPath: (NSString *)path
{
  ASSIGN(_displayValuesKeyPath, path);
}

- (NSString *) rowTypeKeyPath
{
  return _rowTypeKeyPath;
}

- (void) setRowTypeKeyPath: (NSString *)path
{
  ASSIGN(_rowTypeKeyPath, path);
}

- (NSString *) subrowsKeyPath
{
  return _subrowsKeyPath;
}

- (void) setSubrowsKeyPath: (NSString *)path
{
  ASSIGN(_subrowsKeyPath, path);
}

- (NSDictionary *) formattingDictionary
{
  return _formattingDictionary;
}

- (void) setFormattingDictionary: (NSDictionary *)dict
{
  ASSIGN(_formattingDictionary, dict);
}

- (NSString *) formattingStringsFilename
{
  return _formattingStringsFilename;
}

- (void) setFormattingStringsFilename: (NSString *)filename
{
  ASSIGN(_formattingStringsFilename, filename);
}

//
// Rows
//
- (NSInteger) numberOfRows
{
  return (NSInteger)[_rows count];
}

- (NSArray *) criteriaForRow: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];

  return row != nil ? AUTORELEASE([row->criteria copy]) : nil;
}

- (NSArray *) displayValuesForRow: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];

  return row != nil ? AUTORELEASE([row->displayValues copy]) : nil;
}

- (NSRuleEditorRowType) rowTypeForRow: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];

  return row != nil ? row->rowType : NSRuleEditorRowTypeSimple;
}

- (NSInteger) parentRowForRow: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];

  if (row == nil || row->parent == nil)
    {
      return -1;
    }

  return (NSInteger)[_rows indexOfObjectIdenticalTo: row->parent];
}

- (NSIndexSet *) subrowIndexesForRow: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];
  NSMutableIndexSet *result = [NSMutableIndexSet indexSet];
  NSUInteger i;
  NSUInteger count = [_rows count];

  if (row == nil)
    {
      return result;
    }

  for (i = 0; i < count; i++)
    {
      if (((GSRuleEditorRow *)[_rows objectAtIndex: i])->parent == row)
        {
          [result addIndex: i];
        }
    }

  return result;
}

- (NSInteger) rowForDisplayValue: (id)value
{
  NSUInteger i;
  NSUInteger count = [_rows count];

  for (i = 0; i < count; i++)
    {
      GSRuleEditorRow *row = [_rows objectAtIndex: i];

      if ([row->displayValues indexOfObjectIdenticalTo: value] != NSNotFound)
        {
          return (NSInteger)i;
        }
    }

  return -1;
}

- (void) addRow: (id)sender
{
  if (_nestingMode == NSRuleEditorNestingModeSingle && [_rows count] > 0)
    {
      return;
    }

  if (_nestingMode == NSRuleEditorNestingModeSingle
    || _nestingMode == NSRuleEditorNestingModeList)
    {
      [self insertRowAtIndex: [self numberOfRows]
                    withType: NSRuleEditorRowTypeSimple
               asSubrowOfRow: -1
                     animate: NO];
      return;
    }

  /* The nesting modes that hold their rows under a compound row make that
   * row first, so there is something for the new row to sit under.
   */
  if ([_rows count] == 0)
    {
      [self insertRowAtIndex: 0
                    withType: NSRuleEditorRowTypeCompound
               asSubrowOfRow: -1
                     animate: NO];
    }

  [self insertRowAtIndex: [self numberOfRows]
                withType: NSRuleEditorRowTypeSimple
           asSubrowOfRow: 0
                 animate: NO];
}

- (void) insertRowAtIndex: (NSInteger)index
                 withType: (NSRuleEditorRowType)type
            asSubrowOfRow: (NSInteger)parentIndex
                  animate: (BOOL)flag
{
  GSRuleEditorRow *row;

  if (index < 0 || index > [self numberOfRows])
    {
      [NSException raise: NSRangeException
                  format: @"%@ index %ld out of range",
        NSStringFromSelector(_cmd), (long)index];
    }

  row = AUTORELEASE([[GSRuleEditorRow alloc] init]);
  row->rowType = type;
  if (parentIndex >= 0)
    {
      row->parent = [self _rowAtIndex: parentIndex];
    }

  [_rows insertObject: row atIndex: (NSUInteger)index];
  [self _populateRow: row];
  [self _rowsDidChange];
}

- (void) removeRowAtIndex: (NSInteger)index
{
  if (index < 0 || index >= [self numberOfRows])
    {
      return;
    }

  [self removeRowsAtIndexes: [NSIndexSet indexSetWithIndex: (NSUInteger)index]
             includeSubrows: YES];
}

- (void) removeRowsAtIndexes: (NSIndexSet *)rowIds includeSubrows: (BOOL)flag
{
  NSMutableArray *doomed = [NSMutableArray array];
  NSUInteger index = [rowIds firstIndex];

  while (index != NSNotFound)
    {
      GSRuleEditorRow *row = [self _rowAtIndex: (NSInteger)index];

      if (row != nil)
        {
          [doomed addObject: row];
        }
      index = [rowIds indexGreaterThanIndex: index];
    }

  if (flag)
    {
      BOOL added = YES;

      /* A subrow may itself hold subrows, so keep going until nothing more
       * belongs to what is being removed.
       */
      while (added)
        {
          NSEnumerator *e = [_rows objectEnumerator];
          GSRuleEditorRow *row;

          added = NO;
          while ((row = [e nextObject]) != nil)
            {
              if (row->parent != nil
                && [doomed indexOfObjectIdenticalTo: row->parent] != NSNotFound
                && [doomed indexOfObjectIdenticalTo: row] == NSNotFound)
                {
                  [doomed addObject: row];
                  added = YES;
                }
            }
        }
    }
  else
    {
      NSEnumerator *e = [_rows objectEnumerator];
      GSRuleEditorRow *row;

      /* What is left behind has to belong to something that stays. */
      while ((row = [e nextObject]) != nil)
        {
          if (row->parent != nil
            && [doomed indexOfObjectIdenticalTo: row->parent] != NSNotFound)
            {
              row->parent = nil;
            }
        }
    }

  [_rows removeObjectsInArray: doomed];
  [_selectedRows removeAllIndexes];
  [self _rowsDidChange];
}

- (void) setCriteria: (NSArray *)crits
    andDisplayValues: (NSArray *)vals
       forRowAtIndex: (NSInteger)index
{
  GSRuleEditorRow *row = [self _rowAtIndex: index];

  if (row == nil)
    {
      return;
    }

  /* The arguments may be the arrays the row is already holding. */
  crits = AUTORELEASE([crits copy]);
  vals = AUTORELEASE([vals copy]);

  [row->criteria setArray: crits];
  [row->displayValues setArray: vals];
  [self _rowsDidChange];
}

//
// Selection
//
- (NSIndexSet *) selectedRowIndexes
{
  return AUTORELEASE([_selectedRows copy]);
}

- (void) selectRowIndexes: (NSIndexSet *)ids
     byExtendingSelection: (BOOL)flag
{
  if (!flag)
    {
      [_selectedRows removeAllIndexes];
    }
  [_selectedRows addIndexes: ids];
}

//
// Predicates
//
- (NSPredicate *) predicateForRow: (NSInteger)index
{
  return [self _predicateForRow: [self _rowAtIndex: index]];
}

- (NSPredicate *) predicate
{
  NSMutableArray *predicates;
  NSEnumerator *e;
  GSRuleEditorRow *row;

  if ([_rows count] == 0)
    {
      return nil;
    }

  /* The rows that sit at the top level carry the whole thing.  A compound
   * row gathers its own subrows, so a tree has just the one.
   */
  predicates = [NSMutableArray array];
  e = [_rows objectEnumerator];
  while ((row = [e nextObject]) != nil)
    {
      if (row->parent == nil)
        {
          NSPredicate *p = [self _predicateForRow: row];

          if (p != nil)
            {
              [predicates addObject: p];
            }
        }
    }

  if ([predicates count] == 0)
    {
      return nil;
    }
  if ([predicates count] == 1)
    {
      return [predicates objectAtIndex: 0];
    }

  return [NSCompoundPredicate orPredicateWithSubpredicates: predicates];
}

- (void) reloadCriteria
{
  NSEnumerator *e = [_rows objectEnumerator];
  GSRuleEditorRow *row;

  while ((row = [e nextObject]) != nil)
    {
      [row->criteria removeAllObjects];
      [row->displayValues removeAllObjects];
      [self _populateRow: row];
    }

  [self _rowsDidChange];
}

- (void) reloadPredicate
{
  [self _rowsDidChange];
}

@end

@implementation NSRuleEditor (Private)

- (GSRuleEditorRow *) _rowAtIndex: (NSInteger)index
{
  if (index < 0 || index >= (NSInteger)[_rows count])
    {
      return nil;
    }

  return [_rows objectAtIndex: (NSUInteger)index];
}

- (GSRuleEditorRow *) _rootRow
{
  NSEnumerator *e = [_rows objectEnumerator];
  GSRuleEditorRow *row;

  while ((row = [e nextObject]) != nil)
    {
      if (row->parent == nil)
        {
          return row;
        }
    }

  return nil;
}

- (NSArray *) _childRowsOf: (GSRuleEditorRow *)row
{
  NSMutableArray *result = [NSMutableArray array];
  NSEnumerator *e = [_rows objectEnumerator];
  GSRuleEditorRow *other;

  while ((other = [e nextObject]) != nil)
    {
      if (other->parent == row)
        {
          [result addObject: other];
        }
    }

  return result;
}

/* Walk the delegate from the root of its criteria, taking the first child at
 * each step, until it offers no more.  That is the row as it starts out.
 */
- (void) _populateRow: (GSRuleEditorRow *)row
{
  id criterion = nil;
  NSInteger rowIndex;

  if (_delegate == nil)
    {
      return;
    }

  rowIndex = (NSInteger)[_rows indexOfObjectIdenticalTo: row];

  while (YES)
    {
      NSInteger count;
      id child;
      id displayValue;

      count = [_delegate ruleEditor: self
       numberOfChildrenForCriterion: criterion
                        withRowType: row->rowType];
      if (count <= 0)
        {
          break;
        }

      child = [_delegate ruleEditor: self
                             child: 0
                      forCriterion: criterion
                       withRowType: row->rowType];
      if (child == nil)
        {
          break;
        }

      displayValue = [_delegate ruleEditor: self
                 displayValueForCriterion: child
                                    inRow: rowIndex];

      [row->criteria addObject: child];
      [row->displayValues addObject:
        (displayValue != nil ? displayValue : (id)child)];

      criterion = child;
    }
}

/* Gather what the delegate says each criterion of the row contributes. */
- (NSDictionary *) _partsForRow: (GSRuleEditorRow *)row
{
  NSMutableDictionary *parts = [NSMutableDictionary dictionary];
  NSUInteger i;
  NSUInteger count = [row->criteria count];
  NSInteger rowIndex = (NSInteger)[_rows indexOfObjectIdenticalTo: row];

  if (_delegate == nil
    || ![_delegate respondsToSelector:
          @selector(ruleEditor:predicatePartsForCriterion:withDisplayValue:inRow:)])
    {
      return parts;
    }

  for (i = 0; i < count; i++)
    {
      NSDictionary *part;

      part = [_delegate ruleEditor: self
        predicatePartsForCriterion: [row->criteria objectAtIndex: i]
                  withDisplayValue: [row->displayValues objectAtIndex: i]
                             inRow: rowIndex];
      if (part != nil)
        {
          [parts addEntriesFromDictionary: part];
        }
    }

  return parts;
}

- (NSPredicate *) _predicateForRow: (GSRuleEditorRow *)row
{
  NSDictionary *parts;
  NSExpression *left;
  NSExpression *right;
  NSNumber *operator;
  NSNumber *compound;

  if (row == nil)
    {
      return nil;
    }

  parts = [self _partsForRow: row];
  compound = [parts objectForKey: NSRuleEditorPredicateCompoundType];

  if (row->rowType == NSRuleEditorRowTypeCompound || compound != nil)
    {
      NSArray *children = [self _childRowsOf: row];
      NSMutableArray *subpredicates = [NSMutableArray array];
      NSEnumerator *e = [children objectEnumerator];
      GSRuleEditorRow *child;
      NSCompoundPredicateType type;

      while ((child = [e nextObject]) != nil)
        {
          NSPredicate *p = [self _predicateForRow: child];

          if (p != nil)
            {
              [subpredicates addObject: p];
            }
        }

      if ([subpredicates count] == 0)
        {
          return nil;
        }

      type = (compound != nil
        ? [compound unsignedIntegerValue] : NSAndPredicateType);

      if ([subpredicates count] == 1 && type != NSNotPredicateType)
        {
          return [subpredicates objectAtIndex: 0];
        }

      switch (type)
        {
          case NSNotPredicateType:
            return [NSCompoundPredicate notPredicateWithSubpredicate:
              [subpredicates objectAtIndex: 0]];
          case NSOrPredicateType:
            return [NSCompoundPredicate
              orPredicateWithSubpredicates: subpredicates];
          case NSAndPredicateType:
          default:
            return [NSCompoundPredicate
              andPredicateWithSubpredicates: subpredicates];
        }
    }

  left = [parts objectForKey: NSRuleEditorPredicateLeftExpression];
  right = [parts objectForKey: NSRuleEditorPredicateRightExpression];
  operator = [parts objectForKey: NSRuleEditorPredicateOperatorType];

  if (left == nil || right == nil || operator == nil)
    {
      return nil;
    }

  return [NSComparisonPredicate
    predicateWithLeftExpression: left
                rightExpression: right
                       modifier: [[parts objectForKey:
                         NSRuleEditorPredicateComparisonModifier]
                         unsignedIntegerValue]
                           type: [operator unsignedIntegerValue]
                        options: [[parts objectForKey:
                          NSRuleEditorPredicateOptions] unsignedIntegerValue]];
}

- (void) _rowsDidChange
{
  [self _reloadRowViews];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSRuleEditorRowsDidChangeNotification
                  object: self];
}

/* Lay the display values of each row out in a line, indented by how deep the
 * row sits.
 */
- (void) _reloadRowViews
{
  NSArray *subviews = AUTORELEASE([[self subviews] copy]);
  NSEnumerator *e = [subviews objectEnumerator];
  NSView *view;
  NSUInteger i;
  NSUInteger count = [_rows count];
  NSRect bounds = [self bounds];

  while ((view = [e nextObject]) != nil)
    {
      [view removeFromSuperview];
    }

  for (i = 0; i < count; i++)
    {
      GSRuleEditorRow *row = [_rows objectAtIndex: i];
      GSRuleEditorRow *ancestor = row->parent;
      CGFloat x = rowInset;
      CGFloat y;
      NSEnumerator *values;
      id value;

      while (ancestor != nil)
        {
          x += indentPerLevel;
          ancestor = ancestor->parent;
        }

      y = NSMaxY(bounds) - (CGFloat)(i + 1) * _rowHeight;

      values = [row->displayValues objectEnumerator];
      while ((value = [values nextObject]) != nil)
        {
          NSView *rowView;

          if ([value isKindOfClass: [NSView class]])
            {
              rowView = value;
            }
          else
            {
              NSTextField *field;

              field = AUTORELEASE([[NSTextField alloc] initWithFrame:
                NSMakeRect(0.0, 0.0, 80.0, _rowHeight - 2 * rowInset)]);
              [field setStringValue: [value description]];
              [field setEditable: NO];
              [field setBezeled: NO];
              [field setDrawsBackground: NO];
              rowView = field;
            }

          [rowView setFrameOrigin: NSMakePoint(x, y + rowInset)];
          [self addSubview: rowView];
          x += NSWidth([rowView frame]) + viewGap;
        }

      if (_editable)
        {
          NSButton *add;

          add = AUTORELEASE([[NSButton alloc] initWithFrame:
            NSMakeRect(NSMaxX(bounds) - buttonWidth - rowInset, y + rowInset,
              buttonWidth, _rowHeight - 2 * rowInset)]);
          [add setTitle: @"+"];
          [add setTarget: self];
          [add setAction: @selector(addRow:)];
          [self addSubview: add];
        }
    }

  [self setNeedsDisplay: YES];
}

@end
