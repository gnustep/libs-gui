/* Implementation of class NSLayoutAnchor
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Sat May  9 16:30:52 EDT 2020

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

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

#import "AppKit/NSLayoutAnchor.h"
#import "AppKit/NSLayoutConstraint.h"

@implementation NSLayoutAnchor

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor
{
  return nil;
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
  return nil;
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
  return nil;
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c;
{
  return nil;
}

- (NSString *) name
{
  return nil;
}

- (id) item
{
  return nil;
}

- (BOOL) hasAmbiguousLayout
{
  return NO;
}

- (NSArray *) constraintsAffectingLayout
{
  return nil;
}
  
@end

@implementation NSLayoutDimension

- (NSLayoutConstraint *)constraintEqualToConstant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToConstant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m
{
  return nil;
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m
{
  return nil;
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m
{
  return nil;
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m constant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m constant:(CGFloat)c
{
  return nil;
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)m constant:(CGFloat)c
{
  return nil;
}

@end

@implementation NSLayoutXAxisAnchor

- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutXAxisAnchor *)anchor
{
  return nil;
}

@end

@implementation NSLayoutYAxisAnchor

- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutYAxisAnchor *)anchor
{
  return nil;
}
  
@end

