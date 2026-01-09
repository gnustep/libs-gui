/* Implementation of class NSAccessibilityCustomRotor
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Mon 15 Jun 2020 03:18:59 AM EDT

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

#import "AppKit/NSAccessibilityCustomRotor.h"

@implementation NSAccessibilityCustomRotor

- (instancetype) initWithLabel: (NSString *)label
            itemSearchDelegate: (id<NSAccessibilityCustomRotorItemSearchDelegate>)delegate
{
  self = [super init];
  if (self != nil)
    {
      _type = NSAccessibilityCustomRotorTypeCustom; // default when label initializer used
      ASSIGNCOPY(_label, label);
      _itemSearchDelegate = delegate; // delegates not retained in Cocoa typically (weak)
    }
  return self;
}

- (instancetype) initWithRotorType: (NSAccessibilityCustomRotorType)rotorType
                itemSearchDelegate: (id<NSAccessibilityCustomRotorItemSearchDelegate>)delegate
{
  self = [super init];
  if (self != nil)
    {
      _type = rotorType;
      _itemSearchDelegate = delegate;
    }
  return self;
}

- (NSAccessibilityCustomRotorType) type
{
  return _type;
}

- (void) setType: (NSAccessibilityCustomRotorType)type
{
  _type = type;
}

- (NSString *) label
{
  return _label;
}

- (void) setLabel: (NSString *)label
{
  ASSIGNCOPY(_label, label);
}

- (id<NSAccessibilityCustomRotorItemSearchDelegate>) itemSearchDelegate
{
  return _itemSearchDelegate;
}

- (void) setItemSearchDelegate: (id<NSAccessibilityCustomRotorItemSearchDelegate>) delegate
{
  _itemSearchDelegate = delegate;
}

- (id<NSAccessibilityElementLoading>) itemLoadingDelegate
{
  return _itemLoadingDelegate;
}

- (void) setItemLoadingDelegate: (id<NSAccessibilityElementLoading>) delegate
{
  _itemLoadingDelegate = delegate;
}

- (void) dealloc
{
  RELEASE(_label);
  [super dealloc];
}

@end

// Results...
@implementation NSAccessibilityCustomRotorItemResult : NSObject

- (instancetype)initWithTargetElement:(id<NSAccessibilityElement>)targetElement
{
  self = [super init];
  if (self != nil)
    {
      _targetElement = targetElement;
      _targetRange = NSMakeRange(0, 0);
    }
  return self;
}

- (instancetype)initWithItemLoadingToken: (id<NSAccessibilityLoadingToken>)token
                             customLabel: (NSString *)customLabel
{
  self = [super init];
  if (self != nil)
    {
      _itemLoadingToken = token;
      ASSIGNCOPY(_customLabel, customLabel);
      _targetRange = NSMakeRange(0, 0);
    }
  return self;
}

- (id<NSAccessibilityElement>) targetElement
{
  return _targetElement;
}

- (id<NSAccessibilityLoadingToken>) itemLoadingToken
{
  return _itemLoadingToken;
}

- (NSRange) targetRange
{
  return _targetRange;
}

- (NSString *) customLabel
{
  return _customLabel;
}

- (void) dealloc
{
  RELEASE(_customLabel);
  [super dealloc];
}

@end

