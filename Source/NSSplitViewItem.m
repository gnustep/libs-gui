/* Implementation of class NSSplitViewItem
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Mon 20 Jul 2020 12:56:20 AM EDT

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

#import <Foundation/NSArchiver.h>
#import "AppKit/NSSplitViewItem.h"
#import "AppKit/NSLayoutConstraint.h"
#import "AppKit/NSSplitView.h"
#import "AppKit/NSView.h"
#import "AppKit/NSViewController.h"

const CGFloat NSSplitViewItemUnspecifiedDimension = -1.0;

@implementation NSSplitViewItem
- (instancetype) initWithViewController: (NSViewController *)viewController
{
  self = [super init];
  if (self != nil)
    {
      _automaticMaximumThickness = NSSplitViewItemUnspecifiedDimension;
      _preferredThicknessFraction = NSSplitViewItemUnspecifiedDimension;
      _minimumThickness = NSSplitViewItemUnspecifiedDimension;
      _maximumThickness = NSSplitViewItemUnspecifiedDimension;
      _holdingPriority = NSLayoutPriorityDefaultLow;
      _allowsFullHeightLayout = YES;
      ASSIGN(_viewController, viewController);
    }
  return self;
}

+ (instancetype) contentListWithViewController: (NSViewController *)viewController
{
  NSSplitViewItem *item = AUTORELEASE([[NSSplitViewItem alloc]
    initWithViewController: viewController]);

  item->_behavior = NSSplitViewItemBehaviorContentList;
  item->_holdingPriority = 255;
  item->_automaticMaximumThickness = 576;
  return item;
}

+ (instancetype) sidebarWithViewController: (NSViewController *)viewController
{
  NSSplitViewItem *item = AUTORELEASE([[NSSplitViewItem alloc]
    initWithViewController: viewController]);

  item->_behavior = NSSplitViewItemBehaviorSidebar;
  item->_holdingPriority = 260;
  item->_canCollapse = YES;
  item->_springLoaded = YES;
  item->_automaticMaximumThickness = 250;
  return item;
}

+ (instancetype) splitViewItemWithViewController: (NSViewController *)viewController
{
  NSSplitViewItem *item = AUTORELEASE([[NSSplitViewItem alloc]
    initWithViewController: viewController]);

  item->_behavior = NSSplitViewItemBehaviorDefault;
  return item;
}

- (void) dealloc
{
  RELEASE(_viewController);
  [super dealloc];
}

- (CGFloat) automaticMaximumThickness
{
  return _automaticMaximumThickness;
}

- (void) setAutomaticMaximumThickness: (CGFloat)f
{
  _automaticMaximumThickness = f;
}

- (CGFloat) preferredThicknessFraction
{
  return _preferredThicknessFraction;
}

- (void) setPreferredThicknessFraction: (CGFloat)f
{
  _preferredThicknessFraction = f;
}

- (CGFloat) minimumThickness
{
  return _minimumThickness;
}

- (void) setMinimumThickness: (CGFloat)f
{
  _minimumThickness = f;
}

- (CGFloat) maximumThickness
{
  return _maximumThickness;
}

- (void) setMaximumThickness: (CGFloat)f
{
  _maximumThickness = f;
}

- (/* NSLayoutPriority */ CGFloat) holdingPriority
{
  return _holdingPriority;
}

- (void) setHoldingPriority: (/*NSLayoutPriority*/ CGFloat)hp
{
  _holdingPriority = hp;
}

- (NSSplitViewItemBehavior) behavior
{
  return _behavior;
}

- (BOOL) canCollapse
{
  return _canCollapse;
}

- (BOOL) isCollapsed
{
  NSView *view = [_viewController view];
  NSView *superview = [view superview];

  if ([superview isKindOfClass: [NSSplitView class]])
    {
      return [(NSSplitView *)superview isSubviewCollapsed: view];
    }
  return _collapsed;
}

- (void) setCollapsed: (BOOL)flag
{
  NSView *view = [_viewController view];
  NSView *superview = [view superview];

  _collapsed = flag;
  if ([superview isKindOfClass: [NSSplitView class]])
    {
      NSSplitView *sv = (NSSplitView *)superview;
      NSRect frame = [view frame];
      BOOL vertical = [sv isVertical];

      if (flag)
        {
          if (!NSIsEmptyRect(frame))
            {
              _uncollapsedThickness = vertical ? frame.size.width
                                               : frame.size.height;
            }
          if (vertical)
            frame.size.width = 0.0;
          else
            frame.size.height = 0.0;
        }
      else if (NSIsEmptyRect(frame))
        {
          CGFloat thickness = (_uncollapsedThickness > 0.0)
            ? _uncollapsedThickness : 100.0;

          if (vertical)
            frame.size.width = thickness;
          else
            frame.size.height = thickness;
        }
      [view setFrame: frame];
      [sv adjustSubviews];
    }
}

- (NSSplitViewItemCollapseBehavior) collapseBehavior
{
  return _collapseBehavior;
}

- (BOOL) isSpringLoaded
{
  return _springLoaded;
}

- (void) setSpringLoaded: (BOOL)flag
{
  _springLoaded = flag;
}

- (BOOL) allowsFullHeightLayout
{
  return _allowsFullHeightLayout;
}

- (void) setAllowsFullHeightLayout: (BOOL)flag
{
  _allowsFullHeightLayout = flag;
}

- (NSTitlebarSeparatorStyle) titlebarSeparatorStyle
{
  return _titlebarSeparatorStyle;
}

- (void) setTitlebarSeparatorStyle: (NSTitlebarSeparatorStyle)style
{
  _titlebarSeparatorStyle = style;
}

- (NSViewController *) viewController
{
  return _viewController;
}

- (void) setViewController: (NSViewController *)vc
{
  ASSIGN(_viewController, vc);
}

// NSCoding
- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSSplitViewItemViewController"])
        {
          ASSIGN(_viewController,
            [coder decodeObjectForKey: @"NSSplitViewItemViewController"]);
        }
      _automaticMaximumThickness =
        [coder decodeDoubleForKey: @"NSAutomaticMaximumThickness"];
      _preferredThicknessFraction =
        [coder decodeDoubleForKey: @"NSPreferredThicknessFraction"];
      _minimumThickness = [coder decodeDoubleForKey: @"NSMinimumThickness"];
      _maximumThickness = [coder decodeDoubleForKey: @"NSMaximumThickness"];
      _holdingPriority = [coder decodeDoubleForKey: @"NSHoldingPriority"];
      _collapseBehavior = [coder decodeIntegerForKey: @"NSCollapseBehavior"];
      _titlebarSeparatorStyle =
        [coder decodeIntegerForKey: @"NSTitlebarSeparatorStyle"];
      _springLoaded = [coder decodeBoolForKey: @"NSSpringLoaded"];
      _allowsFullHeightLayout =
        [coder decodeBoolForKey: @"NSAllowsFullHeightLayout"];
      _behavior = [coder decodeIntegerForKey: @"NSBehavior"];
      _collapsed = [coder decodeBoolForKey: @"NSCollapsed"];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _viewController
                   forKey: @"NSSplitViewItemViewController"];
      [coder encodeDouble: _automaticMaximumThickness
                   forKey: @"NSAutomaticMaximumThickness"];
      [coder encodeDouble: _preferredThicknessFraction
                   forKey: @"NSPreferredThicknessFraction"];
      [coder encodeDouble: _minimumThickness forKey: @"NSMinimumThickness"];
      [coder encodeDouble: _maximumThickness forKey: @"NSMaximumThickness"];
      [coder encodeDouble: _holdingPriority forKey: @"NSHoldingPriority"];
      [coder encodeInteger: _collapseBehavior forKey: @"NSCollapseBehavior"];
      [coder encodeInteger: _titlebarSeparatorStyle
                    forKey: @"NSTitlebarSeparatorStyle"];
      [coder encodeBool: _springLoaded forKey: @"NSSpringLoaded"];
      [coder encodeBool: _allowsFullHeightLayout
                 forKey: @"NSAllowsFullHeightLayout"];
      [coder encodeInteger: _behavior forKey: @"NSBehavior"];
      [coder encodeBool: _collapsed forKey: @"NSCollapsed"];
    }
}

@end
