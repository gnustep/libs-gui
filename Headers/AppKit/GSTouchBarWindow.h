/** <title>GSTouchBarWindow</title>

   <abstract>Touch Bar fallback window class for systems without Touch Bar hardware</abstract>

    GSTouchBarWindow provides a way to display NSTouchBar items in a regular
    window on systems that don't have physical Touch Bar hardware, such as
    Linux systems. This allows applications using Touch Bar APIs to still
    function and provide their touch controls through a standard window interface.

    The fallback window system provides:
    * Automatic detection of Touch Bar hardware availability
    * Graceful fallback to windowed display mode
    * Proper layout and presentation of Touch Bar items
    * Integration with the existing NSTouchBar API

    Copyright (C) 2025 Free Software Foundation, Inc.

    By: GNUstep Contributors
    Date: Sep 30 2025

    This file is part of the GNUstep Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110 USA.
*/

#ifndef _GSTouchBarWindow_h_GNUSTEP_GUI_INCLUDE
#define _GSTouchBarWindow_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSWindow.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSTouchBar;

/**
 * GSTouchBarWindow displays NSTouchBar items in a regular window
 * for systems without physical Touch Bar hardware.
 */
APPKIT_EXPORT_CLASS
@interface GSTouchBarWindow : NSWindow
{
    NSTouchBar *_touchBar;
    NSView *_itemContainerView;
    NSMutableArray *_itemViews;
    BOOL _autoHidesOnDeactivate;
}

/**
 * The touch bar whose items are displayed in this window.
 */
- (NSTouchBar *) touchBar;
- (void) setTouchBar: (NSTouchBar *)touchBar;

/**
 * Whether the window automatically hides when the application becomes inactive.
 */
- (BOOL) autoHidesOnDeactivate;
- (void) setAutoHidesOnDeactivate: (BOOL)autoHides;

/**
 * Creates a new touch bar window for the specified touch bar.
 */
- (id) initWithTouchBar: (NSTouchBar *)touchBar;

/**
 * Updates the window's content to reflect the current touch bar items.
 */
- (void) updateContent;

/**
 * Positions the window appropriately relative to the main window.
 */
- (void) positionRelativeToMainWindow;

@end

/**
 * GSTouchBarFallbackManager manages the fallback display system
 * for Touch Bars on systems without hardware support.
 */
APPKIT_EXPORT_CLASS
@interface GSTouchBarFallbackManager : NSObject
{
    NSMutableDictionary *_fallbackWindows;
    BOOL _touchBarHardwareAvailable;
}

/**
 * Returns the shared fallback manager instance.
 */
+ (GSTouchBarFallbackManager *) sharedManager;

/**
 * Whether Touch Bar hardware is available on this system.
 */
- (BOOL) isTouchBarHardwareAvailable;

/**
 * Shows a fallback window for the specified touch bar.
 */
- (void) showFallbackWindowForTouchBar: (NSTouchBar *)touchBar;

/**
 * Hides the fallback window for the specified touch bar.
 */
- (void) hideFallbackWindowForTouchBar: (NSTouchBar *)touchBar;

/**
 * Returns the fallback window for the specified touch bar, if any.
 */
- (GSTouchBarWindow *) fallbackWindowForTouchBar: (NSTouchBar *)touchBar;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _GSTouchBarWindow_h_GNUSTEP_GUI_INCLUDE */