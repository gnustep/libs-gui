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

#import <Foundation/Foundation.h>
#import "AppKit/NSLayoutConstraint.h"
#import "GSCassowarySolver.h"

@class NSView;
@class NSLayoutConstraint;

#ifndef _GS_AUTO_LAYOUT_ENGINE_H
#define _GS_AUTO_LAYOUT_ENGINE_H

/* Set when the first layout engine is created.  It stays set for the life of
   the process, so a view path that only matters once constraints are in use
   can test it before doing any further work. */
extern BOOL GSAutoLayoutEngineExists;

@interface GSAutoLayoutEngine : NSObject
{
   GSCassowarySolver *_solver;
   NSMapTable *_variablesByKey;
   NSMutableArray *_solverConstraints;
   NSMapTable *_constraintsByAutoLayoutConstaintHash;
   NSMapTable *_layoutConstraintsBySolverConstraint;
   NSMutableArray *_trackedViews;
   NSMutableDictionary *_viewIndexByViewHash;
   NSMutableDictionary *_viewAlignmentRectByViewIndex;
   NSMutableDictionary *_constraintsByViewIndex;
   NSMapTable *_internalConstraintsByViewIndex;
   NSMapTable *_supportingConstraintsByConstraint;
   int _viewCounter;
   NSView *_contentView;
   NSLayoutConstraint *_contentWidthConstraint;
   NSLayoutConstraint *_contentHeightConstraint;
   /* While _batchDepth is above zero the solver constraints produced by a
      group of layout constraints collect here, to be added or removed in one
      call.  A group is either all additions or all removals. */
   NSMutableArray *_batchedSolverConstraints;
   int _batchDepth;
}

- (instancetype) initWithSolver: (GSCassowarySolver*)solver;

- (void) addConstraint: (NSLayoutConstraint *)constraint;

- (void) addConstraints: (NSArray *)constraints;

- (void) removeConstraint: (NSLayoutConstraint *)constraint;

- (void) removeConstraints: (NSArray *)constraints;

- (NSRect) alignmentRectForView: (NSView *)view;

- (NSArray *) constraintsForView: (NSView *)view;

- (void) pinContentView: (NSView *)contentView;

- (BOOL) updateContentViewSize;

@end

#endif
