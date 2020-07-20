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

#import "AppKit/NSSplitViewItem.h"

@implementation NSSplitViewItem
+ (instancetype)contentListWithViewController: (NSViewController *)viewController
{
  return nil;
}

+ (instancetype)sidebarWithViewController: (NSViewController *)viewController
{
  return nil;
}

+ (instancetype)splitViewItemWithViewController: (NSViewController *)viewController
{
  return nil;
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

- (BOOL) canCollapse
{
  return _canCollapse;
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
@end
