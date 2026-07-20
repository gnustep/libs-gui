/* Copyright (C) 2023 Free Software Foundation, Inc.

   By: Benjamin Johnson
   Date: 19-3-2023
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

#import "GSCassowarySolver.h"
#import "GSCSEditInfo.h"
#import "GSCSFloatComparator.h"
#import "GSCSLinearExpression.h"
#import "GSCSStrength.h"
#import "GSCSVariable.h"
#import "GSFastEnumeration.h"

@interface GSCassowarySolver (PrivateMethods)

- (GSCSLinearExpression *) expressionForNewConstraint: (GSCSConstraint *)constraint
                                               marker: (GSCSVariable **)marker
                                               errors: (NSArray **)errors;

- (void) addVariable: (GSCSVariable *)variable
         coefficient: (CGFloat)coefficient
        toExpression: (GSCSLinearExpression *)expression;

- (void) addExpression: (GSCSLinearExpression *)source
            multiplier: (CGFloat)multiplier
          toExpression: (GSCSLinearExpression *)destination;

- (void) addErrorVariable: (GSCSVariable *)variable
                 strength: (GSCSStrength *)strength;

- (BOOL) tryAddingDirectly: (GSCSLinearExpression *)expression;

- (GSCSVariable *) chooseSubject: (GSCSLinearExpression *)expression;

- (void) addWithArtificialVariable: (GSCSLinearExpression *)expression;

- (GSCSVariable *) exitVariableForMarker: (GSCSVariable *)marker;

- (void) optimize: (GSCSVariable *)objective;

- (GSCSEditInfo *) editInfoForVariable: (GSCSVariable *)variable;

- (GSCSEditInfo *) addEditVariable: (GSCSVariable *)variable
                          strength: (GSCSStrength *)strength;

- (void) deltaEditConstant: (CGFloat)delta
              plusVariable: (GSCSVariable *)plusVariable
             minusVariable: (GSCSVariable *)minusVariable;

- (void) dualOptimize;

- (void) setExternalVariables;

@end

@implementation GSCassowarySolver

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _tableau = [[GSCSTableau alloc] init];
      _editVariableManager = [[GSCSEditVariableManager alloc] init];
      ASSIGN(_markerVariables, [NSMapTable strongToStrongObjectsMapTable]);
      ASSIGN(_errorVariables, [NSMapTable strongToStrongObjectsMapTable]);
      _externalVariables = [[NSMutableSet alloc] init];
      _artificialCounter = 0;
      _slackCounter = 0;
      _dummyCounter = 0;
    }
  return self;
}

- (void) addConstraint: (GSCSConstraint *)constraint
{
  GSCSVariable *marker = nil;
  NSArray *errors = nil;
  GSCSLinearExpression *expression =
    [self expressionForNewConstraint: constraint marker: &marker errors: &errors];

  if (![self tryAddingDirectly: expression])
    {
      [self addWithArtificialVariable: expression];
    }

  if (marker != nil)
    {
      [_markerVariables setObject: marker forKey: constraint];
    }
  if (errors != nil)
    {
      [_errorVariables setObject: errors forKey: constraint];
    }

  [self optimize: [_tableau objective]];
  [self setExternalVariables];
}

- (void) addConstraints: (NSArray *)constraints
{
  FOR_IN(GSCSConstraint *, constraint, constraints)
    [self addConstraint: constraint];
  END_FOR_IN(constraints);
}

- (void) removeConstraint: (GSCSConstraint *)constraint
{
  GSCSVariable *marker = [_markerVariables objectForKey: constraint];
  if (marker == nil)
    {
      [[NSException
         exceptionWithName: NSInvalidArgumentException
                    reason: @"Constraint was not previously added to the solver"
                  userInfo: nil] raise];
      return;
    }

  GSCSVariable *objective = [_tableau objective];
  GSCSLinearExpression *objectiveRow =
    [_tableau rowExpressionForVariable: objective];

  // Take the error variables of this constraint back out of the objective.
  NSArray *errors = [_errorVariables objectForKey: constraint];
  if (errors != nil)
    {
      CGFloat weight = [[constraint strength] strength];
      FOR_IN(GSCSVariable *, errorVariable, errors)
        GSCSLinearExpression *errorRow =
          [_tableau rowExpressionForVariable: errorVariable];
        if (errorRow == nil)
          {
            [_tableau addVariable: errorVariable
                     toExpression: objectiveRow
                  withCoefficient: -weight
                          subject: objective];
          }
        else
          {
            [_tableau addNewExpression: errorRow
                          toExpression: objectiveRow
                                     n: -weight
                               subject: objective];
          }
      END_FOR_IN(errors);
    }

  RETAIN(marker);
  [_markerVariables removeObjectForKey: constraint];

  // If the marker is not basic, pivot it into the basis so its row can be
  // removed.
  if ([_tableau rowExpressionForVariable: marker] == nil)
    {
      GSCSVariable *exitVariable = [self exitVariableForMarker: marker];
      if (exitVariable != nil)
        {
          [_tableau pivotWithEntryVariable: marker exitVariable: exitVariable];
        }
    }

  if ([_tableau rowExpressionForVariable: marker] != nil)
    {
      [_tableau removeRowForVariable: marker];
    }
  if ([_tableau hasColumnForVariable: marker])
    {
      [_tableau removeColumn: marker];
    }

  if (errors != nil)
    {
      FOR_IN(GSCSVariable *, errorVariable, errors)
        if (errorVariable != marker)
          {
            [_tableau removeColumn: errorVariable];
          }
      END_FOR_IN(errors);
      [_errorVariables removeObjectForKey: constraint];
    }
  RELEASE(marker);

  [self optimize: objective];
  [self setExternalVariables];
}

- (void) removeConstraints: (NSArray *)constraints
{
  FOR_IN(GSCSConstraint *, constraint, constraints)
    [self removeConstraint: constraint];
  END_FOR_IN(constraints);
}

- (GSCSSolution *) solve
{
  [self setExternalVariables];

  GSCSSolution *solution = AUTORELEASE([[GSCSSolution alloc] init]);
  FOR_IN(GSCSVariable *, variable, _externalVariables)
    [solution setResult: [variable value] forVariable: variable];
  END_FOR_IN(_externalVariables);

  return solution;
}

- (void) suggestEditVariable: (GSCSVariable *)variable equals: (CGFloat)value
{
  GSCSEditInfo *editInfo = [self editInfoForVariable: variable];
  if (editInfo == nil)
    {
      editInfo = [self addEditVariable: variable
                              strength: [GSCSStrength strengthStrong]];
    }

  CGFloat delta = value - [editInfo previousConstant];
  [editInfo setPreviousConstant: value];

  // The edit constraint expression is (targetValue - variable), so the sign of
  // the change is the reverse of the classic (variable - targetValue) form.
  [self deltaEditConstant: -delta
             plusVariable: [editInfo plusVariable]
            minusVariable: [editInfo minusVariable]];

  [self dualOptimize];
  [self setExternalVariables];
  [[_tableau infeasibleRows] removeAllObjects];
}

// Build the augmented expression for a new constraint. Basic variables are
// replaced by their current row expressions; slack, dummy and error variables
// are introduced according to the constraint relation and strength. The marker
// variable (and error variables, if any) are returned so the constraint can be
// removed later.
- (GSCSLinearExpression *) expressionForNewConstraint: (GSCSConstraint *)constraint
                                               marker: (GSCSVariable **)markerOut
                                               errors: (NSArray **)errorsOut
{
  GSCSLinearExpression *constraintExpression = [constraint expression];
  GSCSLinearExpression *expression = AUTORELEASE([[GSCSLinearExpression alloc]
    initWithConstant: [constraintExpression constant]]);

  NSArray *termVariables = [constraintExpression termVariables];
  FOR_IN(GSCSVariable *, variable, termVariables)
    CGFloat coefficient = [constraintExpression coefficientForTerm: variable];
    GSCSLinearExpression *row = [_tableau rowExpressionForVariable: variable];
    if (row == nil)
      {
        [self addVariable: variable
              coefficient: coefficient
             toExpression: expression];
        if ([variable isExternal])
          {
            [_externalVariables addObject: variable];
          }
      }
    else
      {
        [self addExpression: row
                 multiplier: coefficient
               toExpression: expression];
      }
  END_FOR_IN(termVariables);

  GSCSVariable *marker = nil;
  NSMutableArray *errors = nil;
  GSCSStrength *strength = [constraint strength];

  if ([constraint isInequality])
    {
      _slackCounter++;
      GSCSVariable *slack = [GSCSVariable slackVariableWithName:
        [NSString stringWithFormat: @"s%ld", (long) _slackCounter]];
      [self addVariable: slack coefficient: -1.0 toExpression: expression];
      marker = slack;

      if (![constraint isRequired])
        {
          _slackCounter++;
          GSCSVariable *eMinus = [GSCSVariable slackVariableWithName:
            [NSString stringWithFormat: @"em%ld", (long) _slackCounter]];
          [self addVariable: eMinus coefficient: 1.0 toExpression: expression];
          [self addErrorVariable: eMinus strength: strength];
          errors = [NSMutableArray arrayWithObject: eMinus];
        }
    }
  else
    {
      if ([constraint isRequired])
        {
          _dummyCounter++;
          GSCSVariable *dummy = [GSCSVariable dummyVariableWithName:
            [NSString stringWithFormat: @"d%ld", (long) _dummyCounter]];
          [self addVariable: dummy coefficient: 1.0 toExpression: expression];
          marker = dummy;
        }
      else
        {
          _slackCounter++;
          GSCSVariable *ePlus = [GSCSVariable slackVariableWithName:
            [NSString stringWithFormat: @"ep%ld", (long) _slackCounter]];
          _slackCounter++;
          GSCSVariable *eMinus = [GSCSVariable slackVariableWithName:
            [NSString stringWithFormat: @"em%ld", (long) _slackCounter]];
          [self addVariable: ePlus coefficient: -1.0 toExpression: expression];
          [self addVariable: eMinus coefficient: 1.0 toExpression: expression];
          marker = ePlus;
          [self addErrorVariable: ePlus strength: strength];
          [self addErrorVariable: eMinus strength: strength];
          errors = [NSMutableArray arrayWithObjects: ePlus, eMinus, nil];
        }
    }

  if ([expression constant] < 0.0)
    {
      [expression normalize];
    }

  *markerOut = marker;
  *errorsOut = errors;
  return expression;
}

// Accumulating add of a single term into an expression that is not yet in the
// tableau. GSCSLinearExpression -addVariable:coefficient: overwrites an
// existing coefficient rather than summing, so the running total is computed
// here.
- (void) addVariable: (GSCSVariable *)variable
         coefficient: (CGFloat)coefficient
        toExpression: (GSCSLinearExpression *)expression
{
  CGFloat existing = [expression isTermForVariable: variable]
    ? [expression coefficientForTerm: variable] : 0.0;
  CGFloat updated = existing + coefficient;
  if ([GSCSFloatComparator isApproxiatelyZero: updated])
    {
      [expression removeVariable: variable];
    }
  else
    {
      [expression addVariable: variable coefficient: updated];
    }
}

- (void) addExpression: (GSCSLinearExpression *)source
            multiplier: (CGFloat)multiplier
          toExpression: (GSCSLinearExpression *)destination
{
  [destination setConstant:
    [destination constant] + multiplier * [source constant]];
  NSArray *termVariables = [source termVariables];
  FOR_IN(GSCSVariable *, variable, termVariables)
    [self addVariable: variable
          coefficient: multiplier * [source coefficientForTerm: variable]
         toExpression: destination];
  END_FOR_IN(termVariables);
}

- (void) addErrorVariable: (GSCSVariable *)variable
                 strength: (GSCSStrength *)strength
{
  GSCSVariable *objective = [_tableau objective];
  GSCSLinearExpression *objectiveRow =
    [_tableau rowExpressionForVariable: objective];
  [_tableau addVariable: variable
           toExpression: objectiveRow
        withCoefficient: [strength strength]
                subject: objective];
}

- (BOOL) tryAddingDirectly: (GSCSLinearExpression *)expression
{
  GSCSVariable *subject = [self chooseSubject: expression];
  if (subject == nil)
    {
      return NO;
    }

  [expression newSubject: subject];
  if ([_tableau hasColumnForVariable: subject])
    {
      [_tableau substituteOutVariable: subject forExpression: expression];
    }
  [_tableau addRowForVariable: subject equalsExpression: expression];
  return YES;
}

// Select the variable that will become basic for a new row, following the
// Cassowary chooseSubject procedure: prefer an unrestricted variable, then a
// restricted variable not yet used elsewhere, and finally handle the all-dummy
// case.
- (GSCSVariable *) chooseSubject: (GSCSLinearExpression *)expression
{
  GSCSVariable *subject = nil;
  BOOL foundUnrestricted = NO;
  BOOL foundNewRestricted = NO;
  GSCSVariable *objective = [_tableau objective];
  NSArray *termVariables = [expression termVariables];

  FOR_IN(GSCSVariable *, variable, termVariables)
    CGFloat coefficient = [expression coefficientForTerm: variable];
    if (foundUnrestricted)
      {
        if (![variable isRestricted])
          {
            if (![_tableau hasColumnForVariable: variable])
              {
                return variable;
              }
          }
      }
    else
      {
        if ([variable isRestricted])
          {
            if (!foundNewRestricted && ![variable isDummy] && coefficient < 0.0)
              {
                NSSet *column = [_tableau columnForVariable: variable];
                if (column == nil || [column count] == 0
                    || ([column count] == 1
                        && [column containsObject: objective]))
                  {
                    subject = variable;
                    foundNewRestricted = YES;
                  }
              }
          }
        else
          {
            subject = variable;
            foundUnrestricted = YES;
          }
      }
  END_FOR_IN(termVariables);

  if (subject != nil)
    {
      return subject;
    }

  CGFloat coefficient = 0.0;
  FOR_IN(GSCSVariable *, variable, termVariables)
    if (![variable isDummy])
      {
        return nil;
      }
    if (![_tableau hasColumnForVariable: variable])
      {
        subject = variable;
        coefficient = [expression coefficientForTerm: variable];
      }
  END_FOR_IN(termVariables);

  if (![GSCSFloatComparator isApproxiatelyZero: [expression constant]])
    {
      return nil;
    }
  if (coefficient > 0.0)
    {
      [expression normalize];
    }
  return subject;
}

// Add a row that has no valid subject by first minimising an artificial
// objective. If the artificial objective cannot reach zero the required
// constraints are unsatisfiable.
- (void) addWithArtificialVariable: (GSCSLinearExpression *)expression
{
  _artificialCounter++;
  GSCSVariable *artificial = [GSCSVariable slackVariableWithName:
    [NSString stringWithFormat: @"a%ld", (long) _artificialCounter]];
  GSCSVariable *artificialObjective =
    [GSCSVariable objectiveVariableWithName: @"az"];
  GSCSLinearExpression *artificialObjectiveRow = AUTORELEASE([expression copy]);

  [_tableau addRowForVariable: artificialObjective
             equalsExpression: artificialObjectiveRow];
  [_tableau addRowForVariable: artificial equalsExpression: expression];

  [self optimize: artificialObjective];

  GSCSLinearExpression *optimizedRow =
    [_tableau rowExpressionForVariable: artificialObjective];
  if (![GSCSFloatComparator isApproxiatelyZero: [optimizedRow constant]])
    {
      [_tableau removeRowForVariable: artificialObjective];
      [_tableau removeColumn: artificial];
      [[NSException
         exceptionWithName: NSInvalidArgumentException
                    reason: @"Cannot satisfy the required constraints"
                  userInfo: nil] raise];
      return;
    }

  GSCSLinearExpression *artificialRow =
    [_tableau rowExpressionForVariable: artificial];
  if (artificialRow != nil)
    {
      if ([artificialRow isConstant])
        {
          [_tableau removeRowForVariable: artificial];
          [_tableau removeRowForVariable: artificialObjective];
          return;
        }
      GSCSVariable *entryVariable = [artificialRow anyPivotableVariable];
      [_tableau pivotWithEntryVariable: entryVariable
                          exitVariable: artificial];
    }

  [_tableau removeRowForVariable: artificialObjective];
  [_tableau removeColumn: artificial];
}

// Choose the variable that leaves the basis when a marker is removed. Restricted
// rows in the marker's column are preferred (first by the -constant/coefficient
// ratio over negative coefficients, then by the constant/coefficient ratio);
// otherwise any non-objective row in the column is used.
- (GSCSVariable *) exitVariableForMarker: (GSCSVariable *)marker
{
  NSSet *column = [_tableau columnForVariable: marker];
  if (column == nil)
    {
      return nil;
    }

  GSCSVariable *exitVariable = nil;
  CGFloat minRatio = 0.0;

  FOR_IN(GSCSVariable *, variable, column)
    if ([variable isRestricted])
      {
        GSCSLinearExpression *row = [_tableau rowExpressionForVariable: variable];
        CGFloat coefficient = [row coefficientForTerm: marker];
        if (coefficient < 0.0)
          {
            CGFloat ratio = -[row constant] / coefficient;
            if (exitVariable == nil || ratio < minRatio)
              {
                minRatio = ratio;
                exitVariable = variable;
              }
          }
      }
  END_FOR_IN(column);
  if (exitVariable != nil)
    {
      return exitVariable;
    }

  FOR_IN(GSCSVariable *, variable, column)
    if ([variable isRestricted])
      {
        GSCSLinearExpression *row = [_tableau rowExpressionForVariable: variable];
        CGFloat coefficient = [row coefficientForTerm: marker];
        CGFloat ratio = [row constant] / coefficient;
        if (exitVariable == nil || ratio < minRatio)
          {
            minRatio = ratio;
            exitVariable = variable;
          }
      }
  END_FOR_IN(column);
  if (exitVariable != nil)
    {
      return exitVariable;
    }

  GSCSVariable *objective = [_tableau objective];
  FOR_IN(GSCSVariable *, variable, column)
    if (variable != objective)
      {
        exitVariable = variable;
      }
  END_FOR_IN(column);

  return exitVariable;
}

// Drive the objective row to its optimum by repeatedly pivoting in the
// pivotable column with the most negative coefficient.
- (void) optimize: (GSCSVariable *)objective
{
  GSCSLinearExpression *objectiveRow =
    [_tableau rowExpressionForVariable: objective];

  while (YES)
    {
      GSCSVariable *entryVariable = nil;
      CGFloat mostNegative = -1.0e-8;
      NSArray *termVariables = [objectiveRow termVariables];
      FOR_IN(GSCSVariable *, variable, termVariables)
        if ([variable isPivotable])
          {
            CGFloat coefficient = [objectiveRow coefficientForTerm: variable];
            if (coefficient < mostNegative)
              {
                mostNegative = coefficient;
                entryVariable = variable;
              }
          }
      END_FOR_IN(termVariables);

      if (entryVariable == nil)
        {
          return;
        }

      GSCSVariable *exitVariable =
        [_tableau findPivotableExitVariable: entryVariable];
      if (exitVariable == nil)
        {
          [[NSException
             exceptionWithName: NSInternalInconsistencyException
                        reason: @"Objective function is unbounded"
                      userInfo: nil] raise];
          return;
        }

      [_tableau pivotWithEntryVariable: entryVariable
                          exitVariable: exitVariable];
      objectiveRow = [_tableau rowExpressionForVariable: objective];
    }
}

- (GSCSEditInfo *) editInfoForVariable: (GSCSVariable *)variable
{
  NSArray *editInfos = [_editVariableManager editInfosForVariable: variable];
  if ([editInfos count] > 0)
    {
      return [editInfos lastObject];
    }
  return nil;
}

// Register a variable for editing by adding a non-required equality constraint
// pinning it to its current value. The constraint's error variables are used to
// nudge the value in -suggestEditVariable:equals:.
- (GSCSEditInfo *) addEditVariable: (GSCSVariable *)variable
                          strength: (GSCSStrength *)strength
{
  GSCSConstraint *editConstraint = AUTORELEASE([[GSCSConstraint alloc]
    initEditConstraintWithVariable: variable strength: strength]);
  [self addConstraint: editConstraint];

  GSCSVariable *plusVariable = [_markerVariables objectForKey: editConstraint];
  NSArray *errors = [_errorVariables objectForKey: editConstraint];
  GSCSVariable *minusVariable = nil;
  FOR_IN(GSCSVariable *, errorVariable, errors)
    if (errorVariable != plusVariable)
      {
        minusVariable = errorVariable;
      }
  END_FOR_IN(errors);

  GSCSEditInfo *editInfo = AUTORELEASE([[GSCSEditInfo alloc]
     initWithVariable: variable
           constraint: editConstraint
         plusVariable: plusVariable
        minusVariable: minusVariable
     previousConstant: [variable value]]);
  [_editVariableManager addEditInfo: editInfo];
  return editInfo;
}

// Apply a change to an edit constraint's constant by adjusting the constants of
// the rows that reference its error variables, recording any rows that become
// infeasible for the dual optimisation pass.
- (void) deltaEditConstant: (CGFloat)delta
              plusVariable: (GSCSVariable *)plusVariable
             minusVariable: (GSCSVariable *)minusVariable
{
  GSCSLinearExpression *plusRow =
    [_tableau rowExpressionForVariable: plusVariable];
  if (plusRow != nil)
    {
      [plusRow setConstant: [plusRow constant] + delta];
      if ([plusRow constant] < 0.0)
        {
          [[_tableau infeasibleRows] addObject: plusVariable];
        }
      return;
    }

  GSCSLinearExpression *minusRow =
    [_tableau rowExpressionForVariable: minusVariable];
  if (minusRow != nil)
    {
      [minusRow setConstant: [minusRow constant] - delta];
      if ([minusRow constant] < 0.0)
        {
          [[_tableau infeasibleRows] addObject: minusVariable];
        }
      return;
    }

  NSSet *column = [_tableau columnForVariable: plusVariable];
  FOR_IN(GSCSVariable *, basicVariable, column)
    GSCSLinearExpression *row =
      [_tableau rowExpressionForVariable: basicVariable];
    CGFloat coefficient = [row coefficientForTerm: plusVariable];
    [row setConstant: [row constant] + coefficient * delta];
    if ([basicVariable isRestricted] && [row constant] < 0.0)
      {
        [[_tableau infeasibleRows] addObject: basicVariable];
      }
  END_FOR_IN(column);
}

// Restore feasibility after an edit by pivoting each infeasible row out of the
// basis, choosing the entry variable that least degrades the objective.
- (void) dualOptimize
{
  GSCSVariable *objective = [_tableau objective];
  GSCSLinearExpression *objectiveRow =
    [_tableau rowExpressionForVariable: objective];
  NSMutableArray *infeasibleRows = [_tableau infeasibleRows];

  while ([infeasibleRows count] > 0)
    {
      GSCSVariable *exitVariable = [infeasibleRows objectAtIndex: 0];
      [infeasibleRows removeObjectAtIndex: 0];

      if (![_tableau isBasicVariable: exitVariable])
        {
          continue;
        }
      GSCSLinearExpression *expression =
        [_tableau rowExpressionForVariable: exitVariable];
      if ([expression constant] >= 0.0)
        {
          continue;
        }

      GSCSVariable *entryVariable = nil;
      CGFloat minRatio = DBL_MAX;
      NSArray *termVariables = [expression termVariables];
      FOR_IN(GSCSVariable *, variable, termVariables)
        CGFloat coefficient = [expression coefficientForTerm: variable];
        if (coefficient > 0.0 && [variable isPivotable])
          {
            CGFloat ratio =
              [objectiveRow coefficientForTerm: variable] / coefficient;
            if (ratio < minRatio)
              {
                minRatio = ratio;
                entryVariable = variable;
              }
          }
      END_FOR_IN(termVariables);

      if (entryVariable == nil)
        {
          [[NSException
             exceptionWithName: NSInternalInconsistencyException
                        reason: @"Unable to restore feasibility after an edit"
                      userInfo: nil] raise];
          return;
        }

      [_tableau pivotWithEntryVariable: entryVariable
                          exitVariable: exitVariable];
      objectiveRow = [_tableau rowExpressionForVariable: objective];
    }
}

- (void) setExternalVariables
{
  FOR_IN(GSCSVariable *, variable, _externalVariables)
    GSCSLinearExpression *row = [_tableau rowExpressionForVariable: variable];
    if (row != nil)
      {
        [variable setValue: [row constant]];
      }
    else
      {
        [variable setValue: 0.0];
      }
  END_FOR_IN(_externalVariables);
}

- (void) dealloc
{
  RELEASE(_tableau);
  RELEASE(_editVariableManager);
  RELEASE(_markerVariables);
  RELEASE(_errorVariables);
  RELEASE(_externalVariables);
  [super dealloc];
}

@end
