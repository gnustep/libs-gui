/* Copyright (C) 2023 Free Software Foundation, Inc.

   By: Benjamin Johnson
   Date: 28-2-2023
   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "GSAutoLayoutEngine.h"
#import "AppKit/NSLayoutConstraint.h"
#import "GSCSConstraint.h"
#import "GSFastEnumeration.h"
#import "NSViewPrivate.h"

@interface GSAutoLayoutEngine (PrivateMethods)

- (GSCSConstraint *) solverConstraintForConstraint:
    (NSLayoutConstraint *)constraint;

- (void) mapLayoutConstraint: (NSLayoutConstraint *)layoutConstraint
          toSolverConstraint: (GSCSConstraint *)solverConstraint;

- (void) updateAlignmentRectsForTrackedViews;

- (void) updateAlignmentRectsForTrackedViewsForSolution:
    (GSCSSolution *)solution;

- (BOOL) hasConstraintsForView: (NSView *)view;

- (GSCSConstraint *) getExistingConstraintForAutolayoutConstraint:
    (NSLayoutConstraint *)constraint;

- (void) addConstraintAgainstViewConstraintsArray:
    (NSLayoutConstraint *)constraint;

- (void) removeConstraintAgainstViewConstraintsArray:
    (NSLayoutConstraint *)constraint;

- (void) addSupportingInternalConstraintsToView: (NSView *)view
                                   forAttribute: (NSLayoutAttribute)attribute
                                     constraint: (GSCSConstraint *)constraint;

- (void) removeInternalConstraintsForView: (NSView *)view;

- (void) addSolverConstraint: (GSCSConstraint *)constraint;

- (void) removeSolverConstraint: (GSCSConstraint *)constraint;

- (NSArray *) constraintsForView: (NSView *)view;

- (NSNumber *) indexForView: (NSView *)view;

- (void) notifyViewsOfAlignmentRectChange: (NSArray *)viewsWithChanges;

- (BOOL) solverCanSolveAlignmentRectForView: (NSView *)view
                                   solution: (GSCSSolution *)solution;

- (void) recordAlignmentRect: (NSRect)alignmentRect
                forViewIndex: (NSNumber *)viewIndex;

- (NSRect) solverAlignmentRectForView: (NSView *)view
                             solution: (GSCSSolution *)solution;

- (NSRect) currentAlignmentRectForViewAtIndex: (NSNumber *)viewIndex;

- (BOOL) updateViewAligmentRect: (GSCSSolution *)solution view: (NSView *)view;

@end

@implementation GSAutoLayoutEngine

- (instancetype) initWithSolver: (GSCassowarySolver *)cassowarySolver;
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_solver, cassowarySolver);

      ASSIGN(_variablesByKey, [NSMapTable strongToStrongObjectsMapTable]);

      ASSIGN(_constraintsByAutoLayoutConstaintHash, [NSMapTable strongToStrongObjectsMapTable]);

      ASSIGN(_layoutConstraintsBySolverConstraint, [NSMapTable strongToStrongObjectsMapTable]);

      ASSIGN(_solverConstraints, [NSMutableArray array]);

      ASSIGN(_trackedViews, [NSMutableArray array]);

      ASSIGN(_supportingConstraintsByConstraint, [NSMapTable strongToStrongObjectsMapTable]);

      ASSIGN(_viewAlignmentRectByViewIndex, [NSMutableDictionary dictionary]);

      ASSIGN(_viewIndexByViewHash, [NSMutableDictionary dictionary]);

      ASSIGN(_constraintsByViewIndex, [NSMutableDictionary dictionary]);

      ASSIGN(_internalConstraintsByViewIndex, [NSMapTable strongToStrongObjectsMapTable]);
    }
  return self;
}

- (instancetype) init
{
  GSCassowarySolver *solver = [[GSCassowarySolver alloc] init];
  self = [self initWithSolver: solver];
  RELEASE(solver);
  return self;
}

- (void) addConstraints: (NSArray *)constraints
{
  FOR_IN(NSLayoutConstraint *, constraint, constraints)
    [self addConstraint: constraint];
  END_FOR_IN(constraints);
}

- (void) addConstraint: (NSLayoutConstraint *)constraint
{
  GSCSConstraint *solverConstraint =
      [self solverConstraintForConstraint: constraint];

  [self mapLayoutConstraint: constraint toSolverConstraint: solverConstraint];

  [self addSupportingInternalConstraintsToView: [constraint firstItem]
                                  forAttribute: [constraint firstAttribute]
                                    constraint: solverConstraint];

  if ([constraint secondItem])
    {
      [self
          addSupportingInternalConstraintsToView: [constraint secondItem]
                                    forAttribute: [constraint secondAttribute]
                                      constraint: solverConstraint];
    }

  [self addSolverConstraint: solverConstraint];
  [self updateAlignmentRectsForTrackedViews];

  [self addConstraintAgainstViewConstraintsArray: constraint];
}

- (void) removeConstraint: (NSLayoutConstraint *)constraint
{
  GSCSConstraint *solverConstraint =
      [self getExistingConstraintForAutolayoutConstraint: constraint];
  if (solverConstraint == nil)
    {
      return;
    }

  [self removeSolverConstraint: solverConstraint];

  NSArray *internalConstraints =
      [_supportingConstraintsByConstraint objectForKey: solverConstraint];
  if (internalConstraints)
    {
      FOR_IN(GSCSConstraint *, internalConstraint, internalConstraints)
        [self removeSolverConstraint: internalConstraint];
      END_FOR_IN(internalConstraints);
    }

  [_supportingConstraintsByConstraint setObject: nil forKey: solverConstraint];

  [self updateAlignmentRectsForTrackedViews];
  [self removeConstraintAgainstViewConstraintsArray: constraint];

  if ([self hasConstraintsForView: [constraint firstItem]])
    {
      [self removeInternalConstraintsForView: [constraint firstItem]];
    }
  if ([constraint secondItem] != nil &&
      [self hasConstraintsForView: [constraint secondItem]])
    {
      [self removeInternalConstraintsForView: [constraint secondItem]];
    }
}

- (void) removeConstraints: (NSArray *)constraints
{
  FOR_IN(NSLayoutConstraint *, constraint, constraints)
    [self removeConstraint: constraint];
  END_FOR_IN(constraints);
}

- (GSCSConstraint *) solverConstraintForConstraint:
    (NSLayoutConstraint *)constraint
{
  // FIXME Map NSLayoutConstraint to GSCSConstraint
  return AUTORELEASE([[GSCSConstraint alloc] init]);
}

- (void) mapLayoutConstraint: (NSLayoutConstraint *)layoutConstraint
          toSolverConstraint: (GSCSConstraint *)solverConstraint
{
  [_constraintsByAutoLayoutConstaintHash setObject: solverConstraint
                                            forKey: layoutConstraint];
  [_layoutConstraintsBySolverConstraint setObject: layoutConstraint
                                           forKey: solverConstraint];
}

- (void) addSupportingInternalConstraintsToView: (NSView *)view
                                   forAttribute: (NSLayoutAttribute)attribute
                                     constraint: (GSCSConstraint *)constraint
{
  // FIXME addSupportingInternalConstraintsToView
}

- (void) removeInternalConstraintsForView: (NSView *)view
{
  NSArray *internalViewConstraints =
      [_internalConstraintsByViewIndex objectForKey: view];
  FOR_IN(GSCSConstraint *, constraint, internalViewConstraints)
    [self removeSolverConstraint: constraint];
  END_FOR_IN(internalViewConstraints);

  [_internalConstraintsByViewIndex setObject: nil forKey: view];
}

- (BOOL) hasConstraintsForView: (NSView *)view
{
  NSNumber *viewIndex = [self indexForView: view];
  return [[_constraintsByViewIndex objectForKey: viewIndex] count] > 0;
}

- (GSCSConstraint *) getExistingConstraintForAutolayoutConstraint:
    (NSLayoutConstraint *)constraint
{
  return [_constraintsByAutoLayoutConstaintHash objectForKey: constraint];
}

- (void) addConstraintAgainstViewConstraintsArray:
    (NSLayoutConstraint *)constraint
{
  NSNumber *firstItemViewIndex = [self indexForView: [constraint firstItem]];
  NSMutableArray *constraintsForView =
      [_constraintsByViewIndex objectForKey: firstItemViewIndex];
  if (!constraintsForView)
    {
      constraintsForView = [NSMutableArray array];
      [_constraintsByViewIndex setObject: constraintsForView
                                  forKey: firstItemViewIndex];
    }
  [constraintsForView addObject: constraint];

  if ([constraint secondItem] != nil)
    {
      NSNumber *secondItemViewIndex =
          [self indexForView: [constraint secondItem]];
      if ([_constraintsByViewIndex objectForKey: secondItemViewIndex])
        {
          [_constraintsByViewIndex setObject: [NSMutableArray array]
                                      forKey: secondItemViewIndex];
        }
      [[_constraintsByViewIndex objectForKey: secondItemViewIndex]
          addObject: constraint];
    }
}

- (void) removeConstraintAgainstViewConstraintsArray:
    (NSLayoutConstraint *)constraint
{
  NSNumber *firstItemViewIndex = [self indexForView: [constraint firstItem]];
  NSMutableArray *constraintsForFirstItem =
      [_constraintsByViewIndex objectForKey: firstItemViewIndex];

  NSUInteger indexOfConstraintInFirstItem =
      [constraintsForFirstItem indexOfObject: constraint];
  [constraintsForFirstItem removeObjectAtIndex: indexOfConstraintInFirstItem];

  if ([constraint secondItem] != nil)
    {
      NSNumber *secondItemViewIndexIndex =
          [self indexForView: [constraint secondItem]];
      NSMutableArray *constraintsForSecondItem =
          [_constraintsByViewIndex objectForKey: secondItemViewIndexIndex];

      NSUInteger indexOfConstraintInSecondItem =
          [constraintsForSecondItem indexOfObject: constraint];
      [constraintsForSecondItem
          removeObjectAtIndex: indexOfConstraintInSecondItem];
    }
}

- (void) updateAlignmentRectsForTrackedViews
{
  GSCSSolution *solution = [_solver solve];
  [self updateAlignmentRectsForTrackedViewsForSolution: solution];
}

- (void) updateAlignmentRectsForTrackedViewsForSolution:
    (GSCSSolution *)solution
{
  NSMutableArray *viewsWithChanges = [NSMutableArray array];
  FOR_IN(NSView *, view, _trackedViews)
    BOOL viewAlignmentRectUpdated = [self updateViewAligmentRect: solution
                                                            view: view];
    if (viewAlignmentRectUpdated)
      {
        [viewsWithChanges addObject: view];
      }
  END_FOR_IN(_trackedViews);

  [self notifyViewsOfAlignmentRectChange: viewsWithChanges];
}

- (BOOL) updateViewAligmentRect: (GSCSSolution *)solution view: (NSView *)view
{
  NSNumber *viewIndex = [self indexForView: view];
  if ([self solverCanSolveAlignmentRectForView: view solution: solution])
    {
      NSRect existingAlignmentRect =
          [self currentAlignmentRectForViewAtIndex: viewIndex];
      BOOL isExistingAlignmentRect = NSIsEmptyRect(existingAlignmentRect);
      NSRect solverAlignmentRect = [self solverAlignmentRectForView: view
                                                           solution: solution];
      [self recordAlignmentRect: solverAlignmentRect forViewIndex: viewIndex];

      if (isExistingAlignmentRect == NO
          || !NSEqualRects(solverAlignmentRect, existingAlignmentRect))
        {
          return YES;
        }
    }

  return NO;
}

- (BOOL) solverCanSolveAlignmentRectForView: (NSView *)view
                                   solution: (GSCSSolution *)solution
{
  // FIXME
  return NO;
}

- (void) recordAlignmentRect: (NSRect)alignmentRect
                forViewIndex: (NSNumber *)viewIndex
{
  NSValue *newRectValue = [NSValue valueWithRect: alignmentRect];
  [_viewAlignmentRectByViewIndex setObject: newRectValue forKey: viewIndex];
}

- (NSRect) currentAlignmentRectForViewAtIndex: (NSNumber *)viewIndex
{
  NSValue *existingRectValue =
      [_viewAlignmentRectByViewIndex objectForKey: viewIndex];
  if (existingRectValue == nil)
    {
      return NSZeroRect;
    }
  NSRect existingAlignmentRect;
  [existingRectValue getValue: &existingAlignmentRect];
  return existingAlignmentRect;
}

- (NSRect) solverAlignmentRectForView: (NSView *)view
                             solution: (GSCSSolution *)solution
{
  // FIXME Get view solution from solver
  return NSZeroRect;
}

- (void) notifyViewsOfAlignmentRectChange: (NSArray *)viewsWithChanges
{
  FOR_IN(NSView *, view, viewsWithChanges)
    [view _layoutEngineDidChangeAlignmentRect];
  END_FOR_IN(viewsWithChanges);
}

- (NSRect) alignmentRectForView: (NSView *)view
{
  // FIXME Get alignment rect for view from solver
  return NSZeroRect;
}

- (void) addSolverConstraint: (GSCSConstraint *)constraint
{
  [_solverConstraints addObject: constraint];
  [_solver addConstraint: constraint];
}

- (void) removeSolverConstraint: (GSCSConstraint *)constraint
{
  [_solver removeConstraint: constraint];
  [_solverConstraints removeObject: constraint];
}

- (NSNumber *) indexForView: (NSView *)view
{
  return [_viewIndexByViewHash
      objectForKey: [NSNumber numberWithUnsignedInteger: [view hash]]];
}

- (NSArray *) constraintsForView: (NSView *)view
{
  NSNumber *viewIndex = [self indexForView: view];
  if (!viewIndex)
    {
      return [NSArray array];
    }

  NSMutableArray *constraintsForView = [NSMutableArray array];
  NSArray *viewConstraints = [_constraintsByViewIndex objectForKey: viewIndex];
  FOR_IN(NSLayoutConstraint *, constraint, viewConstraints)
    if ([constraint firstItem] == view)
      {
        [constraintsForView addObject: constraint];
      }
  END_FOR_IN(viewConstraints);

  return constraintsForView;
}

 - (void) dealloc
 {
   RELEASE (_trackedViews);
   RELEASE (_viewAlignmentRectByViewIndex);
   RELEASE (_viewIndexByViewHash);
   RELEASE (_constraintsByViewIndex);
   RELEASE (_constraintsByViewIndex);
   RELEASE (_supportingConstraintsByConstraint);
   RELEASE (_constraintsByAutoLayoutConstaintHash);
   RELEASE (_internalConstraintsByViewIndex);
   RELEASE (_solverConstraints);
   RELEASE (_variablesByKey);
   RELEASE (_solver);

   [super dealloc];
 }

@end