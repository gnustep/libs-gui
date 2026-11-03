/** <title>NSPredicateEditor</title>

   <abstract>The predicate editor class</abstract>

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
#import <Foundation/NSDebug.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSPredicateEditor.h"
#import "AppKit/NSPredicateEditorRowTemplate.h"

@interface NSPredicateEditor (Private)
- (NSPredicateEditorRowTemplate *) _templateForRowType: (NSRuleEditorRowType)type;
- (NSPredicateEditorRowTemplate *) _templateForPredicate: (NSPredicate *)predicate;
- (NSPredicateEditorRowTemplate *) _templateOfRow: (NSInteger)index;
- (void) _fillRow: (NSInteger)index
     withTemplate: (NSPredicateEditorRowTemplate *)template;
- (void) _addRowsForPredicate: (NSPredicate *)predicate
                asSubrowOfRow: (NSInteger)parent;
@end

@implementation NSPredicateEditor

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self == nil)
    {
      return nil;
    }

  /* An editor starts out able to hold rows together, the way one made in a
   * nib does.
   */
  {
    NSPredicateEditorRowTemplate *compound;
    NSArray *types;

    types = [NSArray arrayWithObjects:
      [NSNumber numberWithUnsignedInteger: NSAndPredicateType],
      [NSNumber numberWithUnsignedInteger: NSOrPredicateType],
      [NSNumber numberWithUnsignedInteger: NSNotPredicateType], nil];
    compound = [[NSPredicateEditorRowTemplate alloc]
      initWithCompoundTypes: types];
    _rowTemplates = [[NSArray alloc] initWithObjects: compound, nil];
    RELEASE(compound);
  }

  return self;
}

- (void) dealloc
{
  RELEASE(_rowTemplates);
  [super dealloc];
}

- (NSArray *) rowTemplates
{
  return _rowTemplates;
}

- (void) setRowTemplates: (NSArray *)templates
{
  ASSIGN(_rowTemplates, templates);
}

/* A row of a predicate editor is made from one of its templates, so the row
 * carries the template it was made from and shows that template's views.
 */
- (void) insertRowAtIndex: (NSInteger)index
                 withType: (NSRuleEditorRowType)type
            asSubrowOfRow: (NSInteger)parentIndex
                  animate: (BOOL)flag
{
  [super insertRowAtIndex: index
                 withType: type
            asSubrowOfRow: parentIndex
                  animate: flag];

  [self _fillRow: index withTemplate: [self _templateForRowType: type]];
}

- (NSPredicate *) predicateForRow: (NSInteger)index
{
  NSPredicateEditorRowTemplate *template = [self _templateOfRow: index];
  NSIndexSet *subrows = [self subrowIndexesForRow: index];
  NSMutableArray *subpredicates = [NSMutableArray array];
  NSUInteger subrow = [subrows firstIndex];

  if (template == nil)
    {
      return nil;
    }

  while (subrow != NSNotFound)
    {
      NSPredicate *sub = [self predicateForRow: (NSInteger)subrow];

      if (sub != nil)
        {
          [subpredicates addObject: sub];
        }
      subrow = [subrows indexGreaterThanIndex: subrow];
    }

  if ([template compoundTypes] != nil && [subpredicates count] == 0)
    {
      return nil;
    }

  return [template predicateWithSubpredicates: subpredicates];
}

- (NSPredicate *) predicate
{
  NSMutableArray *predicates = [NSMutableArray array];
  NSInteger i;
  NSInteger count = [self numberOfRows];

  for (i = 0; i < count; i++)
    {
      if ([self parentRowForRow: i] == -1)
        {
          NSPredicate *p = [self predicateForRow: i];

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

- (id) objectValue
{
  return [self predicate];
}

- (void) setObjectValue: (id)object
{
  NSIndexSet *all;

  if (object != nil && ![object isKindOfClass: [NSPredicate class]])
    {
      return;
    }

  all = [NSIndexSet indexSetWithIndexesInRange:
    NSMakeRange(0, (NSUInteger)[self numberOfRows])];
  [self removeRowsAtIndexes: all includeSubrows: YES];

  if (object != nil)
    {
      [self _addRowsForPredicate: (NSPredicate *)object asSubrowOfRow: -1];
    }
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _rowTemplates forKey: @"NSRowTemplates"];
    }
  else
    {
      [aCoder encodeObject: _rowTemplates];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (nil == self)
    {
      return nil;
    }

  if ([aDecoder allowsKeyedCoding])
    {
      NSArray *rowTemplates = [aDecoder decodeObjectForKey: @"NSRowTemplates"];

      [self setRowTemplates: rowTemplates];
    }
  else
    {
      NSArray *rowTemplates = [aDecoder decodeObject];

      [self setRowTemplates: rowTemplates];
    }

  return self;
}

@end

@implementation NSPredicateEditor (Private)

- (NSPredicateEditorRowTemplate *) _templateForRowType: (NSRuleEditorRowType)type
{
  NSEnumerator *e = [_rowTemplates objectEnumerator];
  NSPredicateEditorRowTemplate *template;
  BOOL wantCompound = (type == NSRuleEditorRowTypeCompound);

  while ((template = [e nextObject]) != nil)
    {
      BOOL isCompound = ([template compoundTypes] != nil);

      if (isCompound == wantCompound)
        {
          return template;
        }
    }

  return nil;
}

- (NSPredicateEditorRowTemplate *) _templateForPredicate: (NSPredicate *)predicate
{
  NSEnumerator *e = [_rowTemplates objectEnumerator];
  NSPredicateEditorRowTemplate *template;
  NSPredicateEditorRowTemplate *best = nil;
  double bestMatch = 0.0;

  if (predicate == nil)
    {
      return nil;
    }

  while ((template = [e nextObject]) != nil)
    {
      double match = [template matchForPredicate: predicate];

      if (match > bestMatch)
        {
          bestMatch = match;
          best = template;
        }
    }

  return best;
}

- (NSPredicateEditorRowTemplate *) _templateOfRow: (NSInteger)index
{
  NSArray *criteria = [self criteriaForRow: index];

  if ([criteria count] == 0)
    {
      return nil;
    }

  return [criteria objectAtIndex: 0];
}

/* Each row needs views of its own, so it is given a copy of the template it
 * was made from rather than the template itself.
 */
- (void) _fillRow: (NSInteger)index
     withTemplate: (NSPredicateEditorRowTemplate *)template
{
  NSPredicateEditorRowTemplate *copy;
  NSArray *views;
  NSMutableArray *criteria;
  NSUInteger i;

  if (template == nil)
    {
      return;
    }

  copy = AUTORELEASE([template copy]);
  views = [copy templateViews];
  criteria = [NSMutableArray arrayWithCapacity: [views count]];
  for (i = 0; i < [views count]; i++)
    {
      [criteria addObject: copy];
    }

  [self setCriteria: criteria andDisplayValues: views forRowAtIndex: index];
}

- (void) _addRowsForPredicate: (NSPredicate *)predicate
                asSubrowOfRow: (NSInteger)parent
{
  NSPredicateEditorRowTemplate *template;
  NSPredicateEditorRowTemplate *rowTemplate;
  NSInteger index;
  NSArray *subpredicates;

  template = [self _templateForPredicate: predicate];
  if (template == nil)
    {
      NSDebugMLLog(@"NSPredicateEditor",
        @"no row template holds the predicate %@", predicate);
      return;
    }

  index = [self numberOfRows];
  [super insertRowAtIndex: index
                 withType: ([template compoundTypes] != nil
                   ? NSRuleEditorRowTypeCompound : NSRuleEditorRowTypeSimple)
            asSubrowOfRow: parent
                  animate: NO];
  [self _fillRow: index withTemplate: template];

  rowTemplate = [self _templateOfRow: index];
  [rowTemplate setPredicate: predicate];

  subpredicates = [template displayableSubpredicatesOfPredicate: predicate];
  if (subpredicates != nil)
    {
      NSEnumerator *e = [subpredicates objectEnumerator];
      NSPredicate *sub;

      while ((sub = [e nextObject]) != nil)
        {
          [self _addRowsForPredicate: sub asSubrowOfRow: index];
        }
    }
}

@end
