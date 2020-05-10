/* Implementation of class NSLayoutConstraint
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Sat May  9 16:30:22 EDT 2020

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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

#import "AppKit/NSControl.h"
#import "AppKit/NSView.h"
#import "AppKit/NSAnimation.h"
#import "AppKit/NSLayoutConstraint.h"

// @class NSControl, NSView, NSAnimation, NSArray, NSMutableArray, NSDictionary;

static NSMutableArray *activeConstraints;

@implementation NSLayoutConstraint
+ (NSArray *)constraintsWithVisualFormat: (NSString *)fmt 
                                 options: (NSLayoutFormatOptions)opt 
                                 metrics: (NSDictionary *)metrics 
                                   views: (NSDictionary *)views
{
  return nil;
}

+ (instancetype) constraintWithItem: (id)view1 
                          attribute: (NSLayoutAttribute)attr1 
                          relatedBy: (NSLayoutRelation)relation 
                             toItem: (id)view2 
                          attribute: (NSLayoutAttribute)attr2 
                         multiplier: (CGFloat)mult 
                           constant: (CGFloat)c
{
  return nil;
}

// Active  
- (BOOL) isActive
{
  return [activeConstraints containsObject: self];
}

- (void) setActive: (BOOL)flag
{
  if (flag)
    {
      [activeConstraints addObject: self];
    }
  else
    {
      [activeConstraints removeObject: self];
    }
}

+ (void) activateConstraints: (NSArray *)constraints
{
  [activeConstraints addObjectsFromArray: constraints];
}

+ (void) deactivateConstraints: (NSArray *)constraints
{
  [activeConstraints removeObjectsInArray: constraints];
}

// Items
- (id) firstItem
{
  return _firstItem;
}

- (NSLayoutAttribute) firstAttribute
{
  return _firstAttribute;
}

- (NSLayoutRelation) relation
{
  return _relation;
}

- (id) secondItem
{
  return _secondItem;
}

- (NSLayoutAttribute) secondAttribute
{
  return _secondAttribute;
}

- (CGFloat) multiplier
{
  return _multiplier;
}

- (CGFloat) constant
{
  return _constant;
}

- (NSLayoutAnchor *) firstAnchor
{
  return _firstAnchor;
}

- (NSLayoutAnchor *) secondAnchor
{
  return _secondAnchor;
}

- (NSLayoutPriority) priority
{
  return _priority;
}

@end

