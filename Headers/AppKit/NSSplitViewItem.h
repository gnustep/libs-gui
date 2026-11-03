/* Interface of class NSSplitViewItem
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

#ifndef _NSSplitViewItem_h_GNUSTEP_GUI_INCLUDE
#define _NSSplitViewItem_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

/** Describes the visual and layout role of a split view item. */
enum
{
 /** Standard split view item behavior. */
 NSSplitViewItemBehaviorDefault,
 /** Sidebar behavior, intended for a primary navigation pane. */
 NSSplitViewItemBehaviorSidebar,
 /** Content-list behavior, intended for a list pane next to detail content. */
 NSSplitViewItemBehaviorContentList
};
typedef NSInteger NSSplitViewItemBehavior;

/** Describes how a split view item chooses space when it collapses. */
enum
{
 /** Uses the default collapse behavior for the item's role. */
 NSSplitViewItemCollapseBehaviorDefault,
 /** Resizes sibling items while keeping the split view size fixed. */
 NSSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView,
 /** Resizes the split view while keeping sibling item sizes fixed. */
 NSSplitViewItemCollapseBehaviorPreferResizingSplitViewWithFixedSiblings,
 /** Uses constraints to determine the collapsed layout. */
 NSSplitViewItemCollapseBehaviorUseConstraints
};
typedef NSInteger NSSplitViewItemCollapseBehavior;

/** Describes the separator drawn below a window titlebar. */
enum
{
 /** Uses the default separator style for the window and item role. */
 NSTitlebarSeparatorStyleAutomatic,
 /** Draws no titlebar separator. */
 NSTitlebarSeparatorStyleNone,
 /** Draws a line separator. */
 NSTitlebarSeparatorStyleLine,
 /** Draws a shadow separator. */
 NSTitlebarSeparatorStyleShadow
};
typedef NSInteger NSTitlebarSeparatorStyle;

@class NSViewController;
  
APPKIT_EXPORT_CLASS
/**
 * NSSplitViewItem represents one child item managed by an
 * NSSplitViewController.  Each item owns a view controller and stores the
 * layout policy that the controller uses when arranging the corresponding
 * view in its split view.
 *
 * Split view items may be created for general content, sidebars, or
 * content-list panes.  The item records sizing limits, collapse state,
 * collapse behavior, and role-specific display options such as titlebar
 * separator style.
 */
@interface NSSplitViewItem : NSObject <NSCoding>
{
  CGFloat _automaticMaximumThickness;
  CGFloat _preferredThicknessFraction;
  CGFloat _minimumThickness;
  CGFloat _maximumThickness;
  BOOL _springLoaded;
  BOOL _allowsFullHeightLayout;
  BOOL _canCollapse;
  CGFloat /*NSLayoutPriority*/ _holdingPriority;
  NSSplitViewItemCollapseBehavior _collapseBehavior;
  NSViewController *_viewController;
  NSTitlebarSeparatorStyle _titlebarSeparatorStyle;
  NSSplitViewItemBehavior _behavior;
  BOOL _collapsed;
  CGFloat _uncollapsedThickness;
}

/** Returns a content-list split view item for viewController. */
+ (instancetype)contentListWithViewController:(NSViewController *)viewController;

/** Returns a sidebar split view item for viewController. */
+ (instancetype)sidebarWithViewController:(NSViewController *)viewController;

/** Returns a standard split view item for viewController. */
+ (instancetype)splitViewItemWithViewController:(NSViewController *)viewController;

/** Returns the automatic maximum thickness used by the receiver. */
- (CGFloat) automaticMaximumThickness;

/** Sets the automatic maximum thickness used by the receiver. */
- (void) setAutomaticMaximumThickness: (CGFloat)f;

/** Returns the preferred fraction of the split view occupied by the receiver. */
- (CGFloat) preferredThicknessFraction;

/** Sets the preferred fraction of the split view occupied by the receiver. */
- (void) setPreferredThicknessFraction: (CGFloat)f;

/** Returns the minimum thickness allowed for the receiver's view. */
- (CGFloat) minimumThickness;

/** Sets the minimum thickness allowed for the receiver's view. */
- (void) setMinimumThickness: (CGFloat)f;

/** Returns the maximum thickness allowed for the receiver's view. */
- (CGFloat) maximumThickness;

/** Sets the maximum thickness allowed for the receiver's view. */
- (void) setMaximumThickness: (CGFloat)f;

/** Returns the receiver's split view item behavior. */
- (NSSplitViewItemBehavior) behavior;

/** Returns the layout priority used to hold the receiver's size. */
- (/* NSLayoutPriority */ CGFloat) holdingPriority;

/** Returns whether the receiver can be collapsed. */
- (BOOL) canCollapse;

/** Returns whether the receiver is currently collapsed. */
- (BOOL) isCollapsed;

/** Sets whether the receiver is collapsed. */
- (void) setCollapsed: (BOOL)flag;

/** Returns the receiver's collapse behavior. */
- (NSSplitViewItemCollapseBehavior) collapseBehavior;

/** Returns whether the receiver supports spring-loaded expansion. */
- (BOOL) isSpringLoaded;

/** Sets whether the receiver supports spring-loaded expansion. */
- (void) setSpringLoaded: (BOOL)flag;

/** Returns whether the receiver's view may extend through the full window height. */
- (BOOL) allowsFullHeightLayout;

/** Sets whether the receiver's view may extend through the full window height. */
- (void) setAllowsFullHeightLayout: (BOOL)flag;

/** Returns the titlebar separator style associated with the receiver. */
- (NSTitlebarSeparatorStyle) titlebarSeparatorStyle;

/** Sets the titlebar separator style associated with the receiver. */
- (void) setTitlebarSeparatorStyle: (NSTitlebarSeparatorStyle)style;

/** Returns the view controller managed by the receiver. */
- (NSViewController *) viewController;

/** Sets the view controller managed by the receiver. */
- (void) setViewController: (NSViewController *)vc;
@end

/** Value used to indicate that a split view item dimension is unspecified. */
APPKIT_EXPORT const CGFloat NSSplitViewItemUnspecifiedDimension;
  
#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSSplitViewItem_h_GNUSTEP_GUI_INCLUDE */
