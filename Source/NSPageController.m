/* Implementation of class NSPageController
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 27-07-2020

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
#import "AppKit/NSPageController.h"

@implementation NSPageController
  
// Set/Get properties
- (NSPageControllerTransitionStyle) transitionStyle
{
  return _transitionStyle;
}

- (void) setTransitionStyle: (NSPageControllerTransitionStyle)style
{
  _transitionStyle = style;
}

- (id<NSPageControllerDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSPageControllerDelegate>)delegate
{
  _delegate = delegate;
}

- (NSArray *) arrangedObjects
{
  return _arrangedObjects;
}

- (void) setArrangedObjects: (NSArray *)array
{
  [_arrangedObjects removeAllObjects];
  [_arrangedObjects addObjectsFromArray: array];
}

- (NSInteger) selectedIndex
{
  return _selectedIndex;
}

- (void) setSelectedIndex: (NSInteger)index
{
  _selectedIndex = index;
}

- (NSViewController *) selectedViewController
{
  return _selectedViewController;
}

// Handle page transitions
- (void) navigateForwardToObject: (id)object
{
}

- (void) completeTransition
{
}

- (IBAction) navigateBack: (id)sender
{
}

- (IBAction) navigateForward: (id)sender
{
}

- (IBAction) takeSelectedIndexFrom: (id)sender // uses integerValue from sender
{
}
@end

