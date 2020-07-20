/* Implementation of class NSSplitViewController
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Mon 20 Jul 2020 12:55:02 AM EDT

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

#import "AppKit/NSSplitView.h"
#import "AppKit/NSSplitViewController.h"
#import "AppKit/NSSplitViewItem.h"
#import "GSFastEnumeration.h"

@implementation NSSplitViewController
// return splitview...
- (NSSplitView *) splitView
{
  return _splitView;
}

- (NSSplitViewItem *) splitViewItemForViewController: (NSViewController *)vc
{
  FOR_IN (NSSplitViewItem*, svi, _splitViewItems)
    if ([svi viewController] == vc)
      {
        return svi;
      }
  END_FOR_IN (_splitViewItems);
  return nil;
}

- (CGFloat) minimumThicknessForInlineSidebars
{
  return _minimumThicknessForInlineSidebars;
}
  
// manage splitview items...
- (NSArray *) splitViewItems
{
  return _splitViewItems;
}

- (void) addSplitViewItem: (NSSplitViewItem *)item
{
  [_splitViewItems addObject: item];
}

- (void) insertSplitViewItem: (NSSplitViewItem *)item atIndex: (NSInteger)index
{
  [_splitViewItems insertObject: item atIndex: index];
}

- (void) removeSplitViewItem: (NSSplitViewItem *)item
{
  [_splitViewItems removeObject: item];
}

// instance methods...
- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
  
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
}

- (IBAction)toggleSidebar:(id)sender
{
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
}

- (void)viewDidLoad
{
}

// NSCoding
- (instancetype) initWithCoder: (NSCoder *)coder
{
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}

// NSCopying
- (id) copyWithZone: (NSZone *)z
{
}
@end

