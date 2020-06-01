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
#import <Foundation/NSKeyedArchiver.h>

#import "AppKit/NSControl.h"
#import "AppKit/NSView.h"
#import "AppKit/NSAnimation.h"
#import "AppKit/NSLayoutConstraint.h"

static NSMutableArray *activeConstraints;

@implementation NSLayoutConstraint

+ (void) initialize
{
  if (self == [NSLayoutConstraint class])
    {
      [self setVersion: 1];
      activeConstraints = [NSMutableArray arrayWithCapacity: 10];
    }
}

+ (NSString *) _attributeToString: (NSLayoutAttribute)attr
{
  NSString *name = nil;

  switch (attr)
    {
    case NSLayoutAttributeLeft:
      name = @"Left";
      break;
    case NSLayoutAttributeRight:
      name = @"Right";
      break;
    case NSLayoutAttributeTop:
      name = @"Top";
      break;
    case NSLayoutAttributeBottom:
      name = @"Bottom";
      break;
    case NSLayoutAttributeLeading:
      name = @"Leading";
      break;
    case NSLayoutAttributeTrailing:
      name = @"Trailing";
      break;
    case NSLayoutAttributeWidth:
      name = @"Width";
      break;
    case NSLayoutAttributeHeight:
      name = @"Height";
      break;
    case NSLayoutAttributeCenterX:
      name = @"CenterX";
      break;
    case NSLayoutAttributeCenterY:
      name = @"CenterY";
      break;
    //case NSLayoutAttributeLastBaseline:
      //name = @"LastBaseline";
      //break;
    case NSLayoutAttributeBaseline:
      name = @"Baseline";
      break;
    case NSLayoutAttributeFirstBaseline:
      name = @"FirstBaseline";
      break;
    case NSLayoutAttributeNotAnAttribute:
      name = @"NotAnAttribute";
      break;
    default:
      break;
    }
  
  return name;
}

+ (NSLayoutAttribute) _stringToAttribute: (NSString *)str
{
  NSLayoutAttribute a = 0;

  if ([@"Left" isEqualToString: str])
    {
      a = NSLayoutAttributeLeft;
    }
  else if ([@"Right" isEqualToString: str])
    {
      a = NSLayoutAttributeRight;  
    }
  else if ([@"Top" isEqualToString: str])
    {
      a = NSLayoutAttributeTop;
    }  
  else if ([@"Bottom" isEqualToString: str])
    {
      a = NSLayoutAttributeBottom;
    }
  else if ([@"Leading" isEqualToString: str])
    {
      a = NSLayoutAttributeLeading;
    }  
  else if ([@"Trailing" isEqualToString: str])
    {
      a = NSLayoutAttributeTrailing;
    }
  else if ([@"Width" isEqualToString: str])
    {
      a = NSLayoutAttributeWidth;
    }  
  else if ([@"Height" isEqualToString: str])
    {
      a = NSLayoutAttributeHeight;
    }
  else if ([@"CenterX" isEqualToString: str])
    {
      a = NSLayoutAttributeCenterX;
    }  
  else if ([@"CenterY" isEqualToString: str])
    {
      a = NSLayoutAttributeCenterY;
    }
  else if ([@"Baseline" isEqualToString: str])
    {
      a = NSLayoutAttributeBaseline;
    }  
  else if ([@"FirstBaseline" isEqualToString: str])
    {
      a = NSLayoutAttributeFirstBaseline;
    }
  else if ([@"NotAnAttribute" isEqualToString: str])
    {
      a = NSLayoutAttributeNotAnAttribute;
    }

  return a;
}

+ (NSString *) _relationToString: (NSLayoutRelation)rel
{
  NSString *relation = nil;

  switch (rel)
    {
    case NSLayoutRelationLessThanOrEqual:
      relation = @"<=";
      break;
    case NSLayoutRelationEqual:
      relation = @"=";
      break;
    case NSLayoutRelationGreaterThanOrEqual:
      relation = @">=";
      break;
    default:
      break;
    }

  return relation;
}

+ (NSLayoutRelation) _stringToRelation: (NSString *)str
{
  NSLayoutRelation r = 0;

  if ([@"<=" isEqualToString: str])
    {
      r = NSLayoutRelationLessThanOrEqual;
    }
  else if ([@"=" isEqualToString: str])
    {
      r = NSLayoutRelationEqual;
    }
  else if ([@">=" isEqualToString: str])
    {
      r = NSLayoutRelationGreaterThanOrEqual;
    }
  
  return r;
}

+ (NSArray *) constraintsWithVisualFormat: (NSString *)fmt 
                                  options: (NSLayoutFormatOptions)opt 
                                  metrics: (NSDictionary *)metrics 
                                    views: (NSDictionary *)views
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity: 10];
  return array;
}

- (instancetype) initWithItem: (id)firstItem 
                    attribute: (NSLayoutAttribute)firstAttribute 
                    relatedBy: (NSLayoutRelation)relation 
                       toItem: (id)secondItem
                    attribute: (NSLayoutAttribute)secondAttribute 
                   multiplier: (CGFloat)multiplier
                     constant: (CGFloat)constant;
{
  self = [super init];
  if (self != nil)
    { 
      _firstItem = firstItem;
      _secondItem = secondItem;
      _firstAttribute = firstAttribute;
      _secondAttribute = secondAttribute;
      _relation = relation;
      _multiplier = multiplier;
      _constant = constant;
    }
  return self;
}

// Designated initializer...
+ (instancetype) constraintWithItem: (id)view1 
                          attribute: (NSLayoutAttribute)attr1 
                          relatedBy: (NSLayoutRelation)relation 
                             toItem: (id)view2 
                          attribute: (NSLayoutAttribute)attr2 
                         multiplier: (CGFloat)mult 
                           constant: (CGFloat)c
{
  NSLayoutConstraint *constraint =
    [[NSLayoutConstraint alloc] initWithItem: view1
                                   attribute: attr1
                                   relatedBy: relation
                                      toItem: view2
                                   attribute: attr2
                                  multiplier: mult
                                    constant: c];
  AUTORELEASE(constraint);
  return constraint;
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

// Coding...
- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init]; 
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSConstant"])
            {
              _constant = [coder decodeFloatForKey: @"NSConstant"];
            }

          if ([coder containsValueForKey: @"NSFirstAttribute"])
            {
              _firstAttribute = [coder decodeIntegerForKey: @"NSFirstAttribute"];
            }

          if ([coder containsValueForKey: @"NSFirstItem"])
            {
              _firstItem = [coder decodeObjectForKey: @"NSFirstItem"];
            }

          if ([coder containsValueForKey: @"NSSecondAttribute"])
            {
              _secondAttribute = [coder decodeIntegerForKey: @"NSSecondAttribute"];
            }

          if ([coder containsValueForKey: @"NSSecondItem"])
            {
              _secondItem = [coder decodeObjectForKey: @"NSSecondItem"];
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(float)
                                    at: &_constant];
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_firstAttribute];
          _firstItem = [coder decodeObject];
          [coder decodeValueOfObjCType: @encode(float)
                                    at: &_secondAttribute];
          _secondItem = [coder decodeObject];
        }
    }

  [activeConstraints addObject: self];
  
  return self;
}


- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeFloat: _constant
                  forKey: @"NSConstant"];
      [coder encodeInteger: _firstAttribute
                    forKey: @"NSFirstAttribute"];
      [coder encodeObject: _firstItem
                   forKey: @"NSFirstItem"];
      [coder encodeInteger: _secondAttribute
                    forKey: @"NSSecondAttribute"];
      [coder encodeObject: _secondItem
                   forKey: @"NSSecondItem"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(float)
                                at: &_constant];
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_firstAttribute];
      [coder encodeObject: _firstItem];
      [coder encodeValueOfObjCType: @encode(float)
                                at: &_secondAttribute];
      [coder encodeObject: _secondItem];       
    }
}

- (id) copyWithZone: (NSZone *)z
{
  NSLayoutConstraint *constraint = [[NSLayoutConstraint allocWithZone: z]
                                     initWithItem: _firstItem
                                        attribute: _firstAttribute
                                        relatedBy: _relation
                                           toItem: _secondItem
                                        attribute: _secondAttribute
                                       multiplier: _multiplier
                                         constant: _constant];
  return constraint;
}

- (void) dealloc
{
  [activeConstraints removeObject: self];
  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@ <firstItem = %@, firstAttribute = %ld, relation = %ld, secondItem = %@, "
                   "secondAttribute = %ld, multiplier = %f, constant = %f>",
                   [super description],
                   _firstItem,
                   _firstAttribute,
                   _relation,
                   _secondItem,
                   _secondAttribute,
                   _multiplier,
                   _constant];
}

@end

