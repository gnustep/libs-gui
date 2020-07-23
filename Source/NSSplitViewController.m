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
#import <Foundation/NSArchiver.h>

#import "AppKit/NSSplitView.h"
#import "AppKit/NSSplitViewController.h"
#import "AppKit/NSSplitViewItem.h"
#import "AppKit/NSView.h"

#import "GSFastEnumeration.h"

@interface NSView (__NSSplitViewController_Notifications__)
- (void) _viewWillMoveToWindow: (NSWindow *)w;
- (void) _viewWillMoveToSuperview: (NSView *)v;
- (void) _viewDidMoveToWindow;
@end

@interface NSView (__NSSplitViewController_Private__)
- (void) insertSubview: (NSView *)sv atIndex: (NSUInteger)idx;
@end

@implementation NSView (__NSSplitViewController_Private__)
- (void) insertSubview: (NSView *)sv atIndex: (NSUInteger)idx
{
  [sv _viewWillMoveToWindow: _window];
  [sv _viewWillMoveToSuperview: self];
  [sv setNextResponder: self];
  [_sub_views insertObject: sv atIndex: idx];
  _rFlags.has_subviews = 1;
  [sv resetCursorRects];
  [sv setNeedsDisplay: YES];
  [sv _viewDidMoveToWindow];
  [sv viewDidMoveToSuperview];
  [self didAddSubview: sv];
}
@end

@implementation NSSplitViewController
// return splitview...
- (NSSplitView *) splitView
{
  return (NSSplitView *)[self view];
}

- (void) setSplitView: (NSSplitView *)splitView
{
  [self setView: splitView];
  [splitView setDelegate: self];
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
  NSViewController *vc = [item viewController];
  [_splitViewItems addObject: item];
  if(vc != nil)
    {
      NSView *v = [vc view];
      if (v != nil)
        {
          [[self splitView] addSubview: v];
        }
    }
}

- (void) insertSplitViewItem: (NSSplitViewItem *)item atIndex: (NSInteger)index
{
  NSSplitView *sv = [self splitView];
  NSViewController *vc = [item viewController];

  if (vc != nil)
    {
      NSView *v = [vc view];
      if (v != nil)
        {
          [sv insertSubview: v atIndex: index];
        }
    }       
  [_splitViewItems insertObject: item atIndex: index];     
}

- (void) removeSplitViewItem: (NSSplitViewItem *)item
{
  NSViewController *vc = [item viewController];
  if (vc != nil)
    {
      NSView *v = [vc view];
      if (v != nil)
        {
          [[self splitView] removeSubview: v];  
        }
    }
  [_splitViewItems removeObject: item];
}

// instance methods...
- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
  return [splitView frame];
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
  return YES;
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect
   ofDividerAtIndex:(NSInteger)dividerIndex
{
  return proposedEffectiveRect;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
  return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
  return YES;
}

- (IBAction)toggleSidebar:(id)sender
{
  NSLog(@"Toggle");
}

// NSCoding
- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSSplitView"])
        {
          NSSplitView *sv = [coder decodeObjectForKey: @"NSSplitView"];
          [self setSplitView: sv];
        }
      if ([coder containsValueForKey: @"NSSplitViewItems"])
        {
          NSArray *items = [coder decodeObjectForKey: @"NSSplitViewItems"];
          [_splitViewItems addObjectsFromArray: items];
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}
@end

