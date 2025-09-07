/* Definition of class NSDockTile
   Copyright (C) 2019 Free Software Foundation, Inc.

   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Sat Nov 16 21:11:06 EST 2019

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

/**
 * <title>NSDockTile</title>
 * <abstract>Application dock tile customization and badge management</abstract>
 *
 * NSDockTile provides an interface for customizing the appearance of an
 * application's icon in the dock or taskbar. The class allows applications
 * to overlay custom views, display badge labels with notification counts,
 * and control the visibility of application-specific indicators.
 *
 * Key features include:
 * - Custom content view overlay on the application icon
 * - Badge label display for notification counts or status indicators
 * - Application badge visibility control
 * - Size information for proper content scaling
 * - Owner-based tile management for multiple instances
 *
 * The dock tile serves as a visual communication channel between the
 * application and the user when the application is running but not in
 * the foreground. Common use cases include displaying unread message
 * counts, download progress indicators, or custom status information.
 *
 * Content views are overlaid on the application icon and should be
 * designed to be clearly visible at small dock icon sizes. The system
 * handles the compositing of custom content with the base application
 * icon image.
 */

#ifndef _NSDockTile_h_GNUSTEP_GUI_INCLUDE
#define _NSDockTile_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSView, NSString;
@class NSImageRep;

APPKIT_EXPORT_CLASS
@interface NSDockTile : NSObject
{
  NSView   *_contentView;
  NSSize    _size;
  id        _owner;
  BOOL      _showsApplicationBadge;
  NSString *_badgeLabel;
  NSImage  *_appIconImage;
  NSImage  *_dockTileImage;
}

/**
 * Returns the custom content view overlaid on the dock tile.
 * Returns: The current content view, or nil if none is set
 */
- (NSView *) contentView;

/**
 * Sets a custom content view to overlay on the dock tile.
 * contentView: The view to display on the dock tile, or nil to remove
 */
- (void) setContentView: (NSView *)contentView;

/**
 * Returns the size of the dock tile for content layout purposes.
 * Returns: The size of the dock tile in points
 */
- (NSSize) size;

/**
 * Returns the owner object associated with this dock tile.
 * Returns: The owner object, typically the application instance
 */
- (id) owner;

/**
 * Sets the owner object associated with this dock tile.
 * owner: The object that owns this dock tile instance
 */
- (void) setOwner: (id)owner;

/**
 * Returns whether the application badge is currently visible.
 * Returns: YES if the application badge is shown, NO otherwise
 */
- (BOOL) showsApplicationBadge;
/**
 * Sets whether the application badge should be visible on the dock tile.
 * flag: YES to show the application badge, NO to hide it
 */
- (void) setShowsApplicationBadge: (BOOL)flag;

/**
 * Returns the current badge label text displayed on the dock tile.
 * Returns: The badge label string, or nil if no badge is set
 */
- (NSString *) badgeLabel;

/**
 * Sets the badge label text to display on the dock tile.
 * label: The text to display as a badge, or nil to remove the badge
 */
- (void) setBadgeLabel: (NSString *)label;

/**
 * Forces the dock tile to redraw with current content and settings.
 * This method should be called after making changes to ensure the
 * dock tile reflects the updated state.
 */
- (void) display;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSDockTile_h_GNUSTEP_GUI_INCLUDE */

