/* Implementation of class NSStackView
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 08-08-2020

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

#import "AppKit/NSStackView.h"
#import "GSFastEnumeration.h"

@interface NSView (__NSViewPrivateMethods__)
- (void) _insertSubview: (NSView *)sv atIndex: (NSUInteger)idx;
@end

@implementation NSStackView

- (void) _refreshView
{
}

// Properties
- (void) setDelegate: (id<NSStackViewDelegate>)delegate
{
  _delegate = delegate;
}

- (id<NSStackViewDelegate>) delegate
{
  return _delegate;
}

- (void) setOrientation: (NSUserInterfaceLayoutOrientation)o
{
  _orientation = o;
  [self _refreshView];
}

- (NSUserInterfaceLayoutOrientation) orientation
{
  return _orientation;
}

- (void) setAlignment: (NSLayoutAttribute)alignment
{
  _alignment = alignment;
  [self _refreshView];
}

- (NSLayoutAttribute) alignment
{
  return _alignment;
}

- (void) setEdgeInsets: (NSEdgeInsets)insets
{
  _edgeInsets = insets;
  [self _refreshView];
}

- (NSEdgeInsets) edgeInsets
{
  return _edgeInsets;
}

- (void) setDistribution: (NSStackViewDistribution)d
{
  _distribution = d;
  [self _refreshView];
}

- (NSStackViewDistribution) distribution
{
  return _distribution;
}

- (void) setSpacing: (CGFloat)f
{
  _spacing = f;
  [self _refreshView];
}

- (CGFloat) spacing
{
  return _spacing;
}

- (void) setDetachesHiddenViews: (BOOL)f
{
  _detachesHiddenViews = f;
}

- (BOOL) detachesHiddenViews
{
  return _detachesHiddenViews;
}

- (void) setArrangedSubviews: (NSArray *)arrangedSubviews
{
  ASSIGN(_arrangedSubviews, arrangedSubviews);
}

- (NSArray *) arrangedSubviews
{
  return _arrangedSubviews;
}

- (void) setDetachedViews: (NSArray *)detachedViews
{
  ASSIGN(_detachedViews, detachedViews);
}

- (NSArray *) detachedViews
{
  return _detachedViews;
}

// Instance methods
// Manage views...
- (instancetype) initWithViews: (NSArray *)views
{
  self = [super init];
  if (self != nil)
    {
      _arrangedSubviews = [[NSMutableArray alloc] initWithArray: views];
      _detachedViews = [[NSMutableArray alloc] initWithCapacity: [views count]];
      ASSIGNCOPY(_views, views);
      _customSpacingMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);
      _visiblePriorityMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);

      // Gravity...
      _topGravity = [[NSView alloc] init];
      _leadingGravity = [[NSView alloc] init];
      _centerGravity = [[NSView alloc] init];
      _bottomGravity = [[NSView alloc] init];
      _trailingGravity = [[NSView alloc] init];

      [self _refreshView];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_arrangedSubviews);
  RELEASE(_detachedViews);
  RELEASE(_views);
  RELEASE(_customSpacingMap);
  RELEASE(_visiblePriorityMap);

  RELEASE(_topGravity);
  RELEASE(_leadingGravity);
  RELEASE(_centerGravity);
  RELEASE(_bottomGravity);
  RELEASE(_trailingGravity);
  
  _delegate = nil;
  [super dealloc];
}

+ (instancetype) stackViewWithViews: (NSArray *)views
{
  return AUTORELEASE([[self alloc] initWithViews: views]);
}

- (void) setCustomSpacing: (CGFloat)spacing afterView: (NSView *)v
{
  NSNumber *n = [NSNumber numberWithFloat: spacing];
  [_customSpacingMap setObject: n
                        forKey: v];
}

- (CGFloat) customSpacingAfterView: (NSView *)v
{
  return [[_customSpacingMap objectForKey: v] floatValue];
}

- (void) addArrangedSubview: (NSView *)v
{
  [_arrangedSubviews addObject: v];
}

- (void) insertArrangedSubview: (NSView *)v atIndex: (NSInteger)idx
{
  [_arrangedSubviews insertObject: v atIndex: idx];
}

- (void) removeArrangedSubview: (NSView *)v
{
  [_arrangedSubviews removeObject: v];
}

// Custom priorities
- (void)setVisibilityPriority: (NSStackViewVisibilityPriority)priority
                      forView: (NSView *)v
{
  NSNumber *n = [NSNumber numberWithInteger: priority];
  [_visiblePriorityMap setObject: n
                          forKey: v];
}

- (NSStackViewVisibilityPriority) visibilityPriorityForView: (NSView *)v
{
  NSNumber *n = [_visiblePriorityMap objectForKey: v];
  NSStackViewVisibilityPriority p = (NSStackViewVisibilityPriority)[n integerValue];
  return p;
}
 
- (NSLayoutPriority)clippingResistancePriorityForOrientation:(NSLayoutConstraintOrientation)o
{
  NSLayoutPriority p = 0L;
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      p = _horizontalResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      p = _verticalResistancePriority;
    }
  return p;
}

- (void) setClippingResistancePriority: (NSLayoutPriority)clippingResistancePriority
                        forOrientation: (NSLayoutConstraintOrientation)o
{
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      _horizontalResistancePriority = clippingResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      _verticalResistancePriority = clippingResistancePriority;
    }  
}

- (NSLayoutPriority) huggingPriorityForOrientation: (NSLayoutConstraintOrientation)o
{
  NSLayoutPriority p = 0L;
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      p = _horizontalHuggingPriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      p = _verticalHuggingPriority;
    }
  return p;
}

- (void) setHuggingPriority: (NSLayoutPriority)huggingPriority
             forOrientation: (NSLayoutConstraintOrientation)o
{
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      _horizontalHuggingPriority = huggingPriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      _verticalHuggingPriority = huggingPriority;
    }
}

- (void) setHasEqualSpacing: (BOOL)f
{
  // deprecated
}

- (BOOL) hasEqualSpacing
{
  // deprecated
  return NO;
}

- (void)addView: (NSView *)view inGravity: (NSStackViewGravity)gravity
{
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      [_topGravity addSubview: view];
      break;
    case NSStackViewGravityCenter:
      [_centerGravity addSubview: view];
      break;
    case NSStackViewGravityBottom:
      [_bottomGravity addSubview: view]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt to add view %@ to unknown gravity.", view];
      break;
    }
}

- (void)insertView: (NSView *)view atIndex: (NSUInteger)index inGravity: (NSStackViewGravity)gravity
{
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      [_topGravity _insertSubview: view atIndex: index];
      break;
    case NSStackViewGravityCenter:
      [_centerGravity _insertSubview: view atIndex: index];
      break;
    case NSStackViewGravityBottom:
      [_bottomGravity _insertSubview: view atIndex: index]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt insert view %@ to unknown gravity.", view];
      break;
    }
}

- (void)removeView: (NSView *)view
{
}

- (NSArray *) viewsInGravity: (NSStackViewGravity)gravity
{
  return nil;
}

- (void)setViews: (NSArray *)views inGravity: (NSStackViewGravity)gravity
{
}

- (void) setViews: (NSArray *)views
{
  ASSIGN(_arrangedSubviews, views);
}

- (NSArray *) views
{
  return _arrangedSubviews;
}

// Encoding...
- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSStackViewAlignment"])
            {
              _alignment = [coder decodeIntegerForKey: @"NSStackViewAlignment"];
            }
          if ([coder containsValueForKey: @"NSStackViewBeginningContainer"])
            {
              
            }
          if ([coder containsValueForKey: @"NSStackViewDetachesHiddenViews"])
            {
              _detachesHiddenViews = [coder decodeBoolForKey: @"NSStackViewDetachesHiddenViews"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.bottom"])
            {
              _edgeInsets.bottom = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.bottom"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.left"])
            {
              _edgeInsets.left = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.left"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.right"])
            {
              _edgeInsets.right = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.right"];              
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.top"])
            {
              _edgeInsets.top = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.top"];              
            }
          if ([coder containsValueForKey: @"NSStackViewHasFlagViewHierarchy"])
            {
              _hasFlagViewHierarchy = [coder decodeBoolForKey: @"NSStackViewHasFlagViewHierarchy"];
            }
          if ([coder containsValueForKey: @"NSStackViewHorizontalClippingResistance"])
            {
              _horizontalResistancePriority = [coder decodeFloatForKey: @"NSStackViewHorizontalClippingResistance"];
            }
          if ([coder containsValueForKey: @"NSStackViewHorizontalHugging"])
            {
              _horizontalHuggingPriority = [coder decodeFloatForKey: @"NSStackViewHorizontalHuggingPriority"];
            }
          if ([coder containsValueForKey: @"NSStackViewOrientation"])
            {
              _orientation = [coder decodeIntegerForKey: @"NSStackViewOrientation"];
            }
          if ([coder containsValueForKey: @"NSStackViewSecondaryAlignment"])
            {
              _secondaryAlignment = [coder decodeFloatForKey: @"NSStackViewSecondaryAlignment"];
            }
          if ([coder containsValueForKey: @"NSStackViewSpacing"])
            {
              _spacing = [coder decodeFloatForKey: @"NSStackViewSpacing"];
            }
          if ([coder containsValueForKey: @"NSStackViewVerticalClippingResistance"])
            {
              _verticalResistancePriority = [coder decodeFloatForKey: @"NSStackViewVerticalClippingResistance"];
            }
          if ([coder containsValueForKey: @"NSStackViewVerticalHugging"])
            {
              _verticalHuggingPriority = [coder decodeFloatForKey: @"NSStackViewVerticalHugging"];
            }
          if ([coder containsValueForKey: @"NSStackViewdistribution"])
            {
              _distribution = [coder decodeIntegerForKey: @"NSStackViewdistribution"];
            }        
        }
      else
        {
        }
    }
  return self;
}
  
@end


