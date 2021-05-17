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
      NSUInteger c = [views count];
      
      _arrangedSubviews = [[NSMutableArray alloc] initWithArray: views];
      _detachedViews = [[NSMutableArray alloc] initWithCapacity: c];
      ASSIGNCOPY(_views, views);
      _customSpacingMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);
      _visiblePriorityMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);

      // Gravity...
      _topGravity = [[NSMutableArray alloc] init];
      _leadingGravity = [[NSMutableArray alloc] initWithCapacity: c];
      _centerGravity = [[NSMutableArray alloc] initWithCapacity: c];
      _bottomGravity = [[NSMutableArray alloc] initWithCapacity: c]; 
      _trailingGravity = [[NSMutableArray alloc] initWithCapacity: c];

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
  if (_hasEqualSpacing == NO)
    {
      NSNumber *n = [NSNumber numberWithFloat: spacing];
      [_customSpacingMap setObject: n
                            forKey: v];
      [self _refreshView];
    }
}

- (CGFloat) customSpacingAfterView: (NSView *)v
{
  return [[_customSpacingMap objectForKey: v] floatValue];
}

- (void) addArrangedSubview: (NSView *)v
{
  [_arrangedSubviews addObject: v];
  [self _refreshView];
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
  [self _refreshView];
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
      p = _horizontalClippingResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      p = _verticalClippingResistancePriority;
    }
  return p;
}

- (void) setClippingResistancePriority: (NSLayoutPriority)clippingResistancePriority
                        forOrientation: (NSLayoutConstraintOrientation)o
{
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      _horizontalClippingResistancePriority = clippingResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      _verticalClippingResistancePriority = clippingResistancePriority;
    }
  [self _refreshView];
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
  [self _refreshView];
}

- (void) setHasEqualSpacing: (BOOL)f
{
  _hasEqualSpacing = f;
}

- (BOOL) hasEqualSpacing
{
  return _hasEqualSpacing;
}

- (void)addView: (NSView *)view inGravity: (NSStackViewGravity)gravity
{
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      [_topGravity addObject: view];
      break;
    case NSStackViewGravityCenter:
      [_centerGravity addObject: view];
      break;
    case NSStackViewGravityBottom:
      [_bottomGravity addObject: view]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt to add view %@ to unknown gravity.", view];
      break;
    }
  [self _refreshView];
}

- (void)insertView: (NSView *)view atIndex: (NSUInteger)index inGravity: (NSStackViewGravity)gravity
{
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      [_topGravity insertObject: view atIndex: index];
      break;
    case NSStackViewGravityCenter:
      [_centerGravity insertObject: view atIndex: index];
      break;
    case NSStackViewGravityBottom:
      [_bottomGravity insertObject: view atIndex: index]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt insert view %@ at index %ld to unknown gravity.", view, index];
      break;
    }
  [self _refreshView];
}

- (void)removeView: (NSView *)view
{
  [view removeFromSuperview];
  [self _refreshView];
}

- (NSArray *) viewsInGravity: (NSStackViewGravity)gravity
{
  NSArray *result = nil;
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      result = [_topGravity copy];
      break;
    case NSStackViewGravityCenter:
      result = [_centerGravity copy];
      break;
    case NSStackViewGravityBottom:
      result = [_bottomGravity copy]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt get array of views from unknown gravity."];
      break;
    }
  return result;
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
      [coder encodeInteger: _alignment forKey: @"NSStackViewAlignment"];
      [coder encodeObject: _beginningContainer forKey: @"NSStackViewBeginningContainer"];
      [coder encodeBool: _detachesHiddenViews forKey: @"NSStackViewDetachesHiddenViews"];
      [coder encodeFloat: _edgeInsets.bottom forKey: @"NSStackViewEdgeInsets.bottom"];
      [coder encodeFloat: _edgeInsets.bottom forKey: @"NSStackViewEdgeInsets.left"];
      [coder encodeFloat: _edgeInsets.bottom forKey: @"NSStackViewEdgeInsets.right"];
      [coder encodeFloat: _edgeInsets.bottom forKey: @"NSStackViewEdgeInsets.top"];
      [coder encodeBool: _hasFlagViewHierarchy forKey: @"NSStackViewHasFlagViewHierarchy"];
      [coder encodeFloat: _horizontalClippingResistancePriority forKey: @"NSStackViewHorizontalClippingResistance"];
      [coder encodeFloat: _horizontalHuggingPriority forKey: @"NSStackViewHorizontalHuggingPriority"];
      [coder encodeInteger: _orientation forKey: @"NSStackViewOrientation"];
      [coder encodeInteger: _alignment forKey: @"NSStackViewSecondaryAlignment"];
      [coder encodeFloat: _spacing forKey: @"NSStackViewSpacing"];
      [coder encodeFloat: _verticalClippingResistancePriority forKey: @"NSStackViewVerticalClippingResistance"];
      [coder encodeFloat: _verticalHuggingPriority forKey: @"NSStackViewVerticalHuggingPriority"];
      [coder encodeInteger: _distribution forKey: @"NSStackViewdistribution"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_alignment];
      [coder encodeObject: _beginningContainer];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_detachesHiddenViews];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.bottom];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.left];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.right];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.top];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_hasFlagViewHierarchy];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_horizontalClippingResistancePriority];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_horizontalHuggingPriority];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_orientation];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_secondaryAlignment];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_spacing];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_verticalClippingResistancePriority];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_verticalHuggingPriority];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_distribution];
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
              _beginningContainer = [coder decodeObjectForKey: @"NSStackViewBeginningContainer"];
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
              _horizontalClippingResistancePriority = [coder decodeFloatForKey: @"NSStackViewHorizontalClippingResistance"];
            }
          if ([coder containsValueForKey: @"NSStackViewHorizontalHuggingPriority"])
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
              _verticalClippingResistancePriority = [coder decodeFloatForKey: @"NSStackViewVerticalClippingResistance"];
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
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_alignment];
          ASSIGN(_beginningContainer, [coder decodeObject]);
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_detachesHiddenViews];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.bottom];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.left];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.right];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.top];
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_hasFlagViewHierarchy];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_horizontalClippingResistancePriority];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_horizontalHuggingPriority];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_orientation];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_secondaryAlignment];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_spacing];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_verticalClippingResistancePriority];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_verticalHuggingPriority];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_distribution];
        }
      [self _refreshView];
    }
  return self;
}
  
@end


