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
#include "AppKit/NSLayoutConstraint.h"

@implementation GSAutoLayoutEngine

- (void) addConstraint: (NSLayoutConstraint *)constraint
{
  // FIXME Add constraint to solver
}

- (void) addConstraints: (NSArray *)constraints
{
  // FIXME Add constraints to solver
}

- (void) removeConstraint: (NSLayoutConstraint *)constraint
{
  // FIXME Remove constraint from solver
}

- (void) removeConstraints: (NSArray *)constraints
{
  // FIXME Remove constraints from solver
}

- (NSRect) alignmentRectForView: (NSView *)view
{
  // FIXME Get alignment rect for view from solver
  return NSMakeRect (0, 0, 0, 0);
}

- (NSArray *) constraintsForView: (NSView *)view
{
  // FIXME Get constraints for view
  return [NSArray array];
}

@end